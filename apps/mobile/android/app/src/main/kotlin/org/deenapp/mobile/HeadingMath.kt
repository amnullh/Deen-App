package org.deenapp.mobile

import android.hardware.SensorManager
import android.view.Surface
import org.deenapp.mobile.generated.HeadingAccuracy
import kotlin.math.abs
import kotlin.math.atan2

/** Pure helpers for [HeadingApiImpl], kept separate so they read (and can be tested) on their own. */
object HeadingMath {
    /** Expected geomagnetic field strength on Earth; outside it, interference is suspected. */
    const val FIELD_MIN_MICROTESLA = 25.0
    const val FIELD_MAX_MICROTESLA = 65.0

    /** A change in field strength between two samples larger than this counts as a rapid jump. */
    const val FIELD_JUMP_MICROTESLA = 10.0

    /** Below this |z| of the device's up component the phone counts as upright, not flat. */
    private const val FLAT_THRESHOLD = 0.7f

    fun normalize(degrees: Double): Double = ((degrees % 360.0) + 360.0) % 360.0

    /**
     * Compass bearing (degrees clockwise from magnetic north) of the direction the user is facing,
     * from a rotation matrix [r] (row-major 3x3, device to world, as produced by
     * `SensorManager.getRotationMatrixFromVector`).
     *
     * Flat on a table or held level: the top edge of the screen, corrected for the display
     * rotation. Held upright: the direction the back of the phone faces. The switch is at about
     * 45 degrees of tilt so the heading never goes unstable at either extreme.
     */
    fun magneticHeading(r: FloatArray, displayRotation: Int): Double {
        val flat = abs(r[8]) >= FLAT_THRESHOLD
        val east: Float
        val north: Float
        if (flat) {
            // Screen "up" expressed in device axes for each display rotation.
            val ux: Float
            val uy: Float
            when (displayRotation) {
                Surface.ROTATION_90 -> { ux = -1f; uy = 0f }
                Surface.ROTATION_180 -> { ux = 0f; uy = -1f }
                Surface.ROTATION_270 -> { ux = 1f; uy = 0f }
                else -> { ux = 0f; uy = 1f }
            }
            east = r[0] * ux + r[1] * uy
            north = r[3] * ux + r[4] * uy
        } else {
            east = -r[2]
            north = -r[5]
        }
        return normalize(Math.toDegrees(atan2(east.toDouble(), north.toDouble())))
    }

    fun toTrueNorth(magneticDegrees: Double, declinationDegrees: Float): Double =
        normalize(magneticDegrees + declinationDegrees)

    fun isFieldOutOfRange(microTesla: Double): Boolean =
        microTesla < FIELD_MIN_MICROTESLA || microTesla > FIELD_MAX_MICROTESLA

    fun mapAccuracy(sensorAccuracy: Int): HeadingAccuracy = when (sensorAccuracy) {
        SensorManager.SENSOR_STATUS_ACCURACY_HIGH -> HeadingAccuracy.HIGH
        SensorManager.SENSOR_STATUS_ACCURACY_MEDIUM -> HeadingAccuracy.MEDIUM
        SensorManager.SENSOR_STATUS_ACCURACY_LOW -> HeadingAccuracy.LOW
        else -> HeadingAccuracy.UNRELIABLE
    }

    /** The calibration prompt is wanted when the platform reports low or unreliable accuracy. */
    fun needsCalibration(accuracy: HeadingAccuracy): Boolean =
        accuracy == HeadingAccuracy.LOW || accuracy == HeadingAccuracy.UNRELIABLE
}
