package org.deenapp.mobile

import android.content.Context
import android.hardware.GeomagneticField
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import org.deenapp.mobile.generated.HeadingAccuracy
import org.deenapp.mobile.generated.HeadingApi
import org.deenapp.mobile.generated.HeadingSample
import org.deenapp.mobile.generated.PigeonEventSink
import org.deenapp.mobile.generated.StreamHeadingsStreamHandler
import kotlin.math.cos
import kotlin.math.abs
import kotlin.math.atan2
import kotlin.math.sin
import kotlin.math.sqrt

/**
 * Android [HeadingApi]: the tilt-compensated rotation-vector sensor for the bearing, the
 * magnetometer's field strength for interference, sensor accuracy callbacks for calibration, and
 * the platform geomagnetic model for magnetic declination.
 *
 * Sensors run only between [start] and [stop] (the Qibla screen is visible) and when the event
 * channel is cancelled. Samples are low-pass filtered (on the unit vector, so 359 to 1 degree does
 * not average to 180) and sent about ten times per second. The thresholds are proposals to tune on
 * devices (spike S9).
 */
class HeadingApiImpl(
    context: Context,
    private val displayRotation: () -> Int,
    private val clock: Clock = Clock.SYSTEM,
) : HeadingApi, SensorEventListener {

    private val sensorManager: SensorManager = context.getSystemService(SensorManager::class.java)
    private val rotationSensor: Sensor? = sensorManager.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)
    private val magnetometer: Sensor? = sensorManager.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD)
    private val handler = Handler(Looper.getMainLooper())

    private var sink: PigeonEventSink<HeadingSample>? = null

    /** Register once with `StreamHeadingsStreamHandler.register(messenger, handler)`. */
    val streamHandler: StreamHeadingsStreamHandler = object : StreamHeadingsStreamHandler() {
        override fun onListen(p0: Any?, sink: PigeonEventSink<HeadingSample>) {
            this@HeadingApiImpl.sink = sink
        }

        override fun onCancel(p0: Any?) {
            this@HeadingApiImpl.sink = null
            stop()
        }
    }

    // Filter state. Only touched on the main thread.
    private val rotationMatrix = FloatArray(9)
    private var started = false
    private var declinationDegrees: Float? = null
    private var hasHeading = false
    private var smoothSin = 0.0
    private var smoothCos = 0.0
    private var fieldMicroTesla: Double? = null
    private var lastEmittedField: Double? = null
    private var interferenceUntil = 0L
    private var lastEmitAt = 0L
    private var rotationAccuracy: Int? = null
    private var magneticAccuracy: Int? = null

    override fun isAvailable(): Boolean = rotationSensor != null && magnetometer != null

    override fun start(latitude: Double, longitude: Double) {
        stop()
        if (!isAvailable()) return
        declinationDegrees = declinationFor(latitude, longitude)
        started = true
        sensorManager.registerListener(this, rotationSensor, SensorManager.SENSOR_DELAY_GAME, handler)
        sensorManager.registerListener(this, magnetometer, SensorManager.SENSOR_DELAY_GAME, handler)
    }

    override fun stop() {
        sensorManager.unregisterListener(this)
        started = false
        hasHeading = false
        fieldMicroTesla = null
        lastEmittedField = null
        interferenceUntil = 0L
        lastEmitAt = 0L
        rotationAccuracy = null
        magneticAccuracy = null
    }

    override fun onSensorChanged(event: SensorEvent) {
        if (!started) return
        when (event.sensor.type) {
            Sensor.TYPE_ROTATION_VECTOR -> {
                rotationAccuracy = event.accuracy
                onRotation(event.values)
            }
            Sensor.TYPE_MAGNETIC_FIELD -> {
                magneticAccuracy = event.accuracy
                onMagneticField(event.values)
            }
        }
        emitIfDue()
    }

    override fun onAccuracyChanged(sensor: Sensor, accuracy: Int) {
        when (sensor.type) {
            Sensor.TYPE_ROTATION_VECTOR -> rotationAccuracy = accuracy
            Sensor.TYPE_MAGNETIC_FIELD -> magneticAccuracy = accuracy
        }
    }

    private fun onRotation(values: FloatArray) {
        // Some devices report five values; the conversion accepts at most four.
        val vector = if (values.size > 4) values.copyOfRange(0, 4) else values
        SensorManager.getRotationMatrixFromVector(rotationMatrix, vector)
        val radians = Math.toRadians(HeadingMath.magneticHeading(rotationMatrix, displayRotation()))
        if (!hasHeading) {
            smoothSin = sin(radians)
            smoothCos = cos(radians)
            hasHeading = true
        } else {
            smoothSin += HEADING_ALPHA * (sin(radians) - smoothSin)
            smoothCos += HEADING_ALPHA * (cos(radians) - smoothCos)
        }
    }

    private fun onMagneticField(values: FloatArray) {
        val magnitude = sqrt(
            (values[0] * values[0] + values[1] * values[1] + values[2] * values[2]).toDouble(),
        )
        val previous = fieldMicroTesla
        fieldMicroTesla = if (previous == null) magnitude else previous + FIELD_ALPHA * (magnitude - previous)
    }

    private fun emitIfDue() {
        val target = sink ?: return
        val now = SystemClock.elapsedRealtime()
        if (!hasHeading || now - lastEmitAt < EMIT_INTERVAL_MS) return
        lastEmitAt = now

        val magnetic = HeadingMath.normalize(Math.toDegrees(atan2(smoothSin, smoothCos)))
        val declination = declinationDegrees
        val heading = if (declination != null) HeadingMath.toTrueNorth(magnetic, declination) else magnetic

        val field = fieldMicroTesla
        val previousField = lastEmittedField
        if (field != null && previousField != null &&
            abs(field - previousField) > HeadingMath.FIELD_JUMP_MICROTESLA
        ) {
            interferenceUntil = now + INTERFERENCE_HOLD_MS
        }
        lastEmittedField = field
        val interference = (field != null && HeadingMath.isFieldOutOfRange(field)) || now < interferenceUntil

        val accuracy = currentAccuracy()
        target.success(
            HeadingSample(
                headingDegrees = heading,
                isTrueNorth = declination != null,
                accuracy = accuracy,
                fieldStrengthMicroTesla = field,
                interferenceSuspected = interference,
                needsCalibration = HeadingMath.needsCalibration(accuracy),
            ),
        )
    }

    /** The worse of the two sensors' accuracy reports. */
    private fun currentAccuracy(): HeadingAccuracy {
        val reports = listOfNotNull(rotationAccuracy, magneticAccuracy)
        if (reports.isEmpty()) return HeadingAccuracy.UNRELIABLE
        return HeadingMath.mapAccuracy(reports.min())
    }

    /** Declination at the location, or null when the coordinates are not usable (magnetic north). */
    private fun declinationFor(latitude: Double, longitude: Double): Float? {
        if (latitude.isNaN() || longitude.isNaN() || latitude !in -90.0..90.0 || longitude !in -180.0..180.0) {
            return null
        }
        return GeomagneticField(latitude.toFloat(), longitude.toFloat(), 0f, clock.nowMs()).declination
    }

    private companion object {
        const val EMIT_INTERVAL_MS = 100L
        const val HEADING_ALPHA = 0.15
        const val FIELD_ALPHA = 0.1
        const val INTERFERENCE_HOLD_MS = 2_000L
    }
}
