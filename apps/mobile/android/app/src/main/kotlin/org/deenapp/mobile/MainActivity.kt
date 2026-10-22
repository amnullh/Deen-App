package org.deenapp.mobile

import android.content.Intent
import android.os.Build
import android.util.Log
import android.view.KeyEvent
import android.view.Surface
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import org.deenapp.mobile.generated.HeadingApi
import org.deenapp.mobile.generated.LocationApi
import org.deenapp.mobile.generated.SchedulerApi
import org.deenapp.mobile.generated.SchedulerEvents
import org.deenapp.mobile.generated.StreamHeadingsStreamHandler
import org.deenapp.mobile.generated.VolumeKeyApi
import org.deenapp.mobile.generated.VolumeKeyEvents

/**
 * Hosts the Flutter engine and registers the Pigeon handlers: scheduling, location, heading and
 * the volume keys. All of them are native (no plugin), so they work with no extra dependencies.
 */
class MainActivity : FlutterActivity() {
    private val scope = CoroutineScope(Dispatchers.Main)

    private var scheduler: SchedulerApiImpl? = null
    private var schedulerEvents: SchedulerEvents? = null
    private var location: LocationApiImpl? = null
    private var heading: HeadingApiImpl? = null
    private var volumeKeys: VolumeKeyApiImpl? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        val events = SchedulerEvents(messenger)
        val schedulerApi = SchedulerApiImpl(applicationContext)
        SchedulerApi.setUp(messenger, schedulerApi)
        schedulerEvents = events
        scheduler = schedulerApi

        val locationApi = LocationApiImpl(applicationContext) { this }
        LocationApi.setUp(messenger, locationApi)
        location = locationApi

        val headingApi = HeadingApiImpl(applicationContext, ::currentDisplayRotation)
        HeadingApi.setUp(messenger, headingApi)
        StreamHeadingsStreamHandler.register(messenger, headingApi.streamHandler)
        heading = headingApi

        val volumeKeyApi = VolumeKeyApiImpl(VolumeKeyEvents(messenger))
        VolumeKeyApi.setUp(messenger, volumeKeyApi)
        volumeKeys = volumeKeyApi

        reportNotificationTap(intent)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        SchedulerApi.setUp(messenger, null)
        LocationApi.setUp(messenger, null)
        HeadingApi.setUp(messenger, null)
        VolumeKeyApi.setUp(messenger, null)
        // The sensors must never keep running without a screen.
        heading?.stop()
        scheduler = null
        schedulerEvents = null
        location = null
        heading = null
        volumeKeys = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun onResume() {
        super.onResume()
        // A permission may have changed in system settings while the app was in the background.
        val api = scheduler
        val events = schedulerEvents
        if (api != null && events != null) api.notifyIfPermissionsChanged(events, scope)
    }

    override fun onDestroy() {
        scope.cancel()
        super.onDestroy()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        reportNotificationTap(intent)
    }

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        if (volumeKeys?.handleKeyEvent(event) == true) return true
        return super.dispatchKeyEvent(event)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        location?.onRequestPermissionsResult(requestCode)
    }

    /** Tells Dart which alert's notification was tapped (a cold start has no listener yet). */
    private fun reportNotificationTap(intent: Intent?) {
        if (intent == null) return
        val alertId = intent.getStringExtra(Notifications.EXTRA_ALERT_ID) ?: return
        intent.removeExtra(Notifications.EXTRA_ALERT_ID)
        val events = schedulerEvents ?: return
        scope.launch {
            try {
                events.onNotificationTapped(alertId)
            } catch (e: Exception) {
                Log.w(TAG, "notification tap not delivered: ${e.javaClass.simpleName}")
            }
        }
    }

    /** One of `Surface.ROTATION_*`, for the compass. */
    @Suppress("DEPRECATION")
    private fun currentDisplayRotation(): Int =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            display?.rotation ?: Surface.ROTATION_0
        } else {
            (getSystemService(WINDOW_SERVICE) as WindowManager).defaultDisplay.rotation
        }

    private companion object {
        const val TAG = "MainActivity"
    }
}
