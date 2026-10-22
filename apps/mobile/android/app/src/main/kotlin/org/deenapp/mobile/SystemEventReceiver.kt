package org.deenapp.mobile

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Re-registers the alarms after events that can drop or invalidate them: boot (locked and
 * unlocked), clock or time zone changes, an app update, and a change of the exact-alarm
 * permission. It only re-registers and tops up from the stored snapshot.
 *
 * It never starts [AzaanPlaybackService]: Android 15 forbids starting a media-playback foreground
 * service from a boot receiver, and an Azaan that is already past must not play late anyway.
 */
class SystemEventReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        if (action !in HANDLED_ACTIONS) return
        val pending: BroadcastReceiver.PendingResult? = goAsync()
        Thread {
            try {
                AlarmScheduler(context).reregisterAll()
            } catch (e: Exception) {
                Log.w(TAG, "re-registration after $action failed: ${e.javaClass.simpleName}")
            } finally {
                pending?.finish()
            }
        }.start()
    }

    companion object {
        private const val TAG = "SystemEventReceiver"

        /** `AlarmManager.ACTION_SCHEDULE_EXACT_ALARM_PERMISSION_STATE_CHANGED` (API 31). */
        const val ACTION_EXACT_ALARM_PERMISSION_CHANGED =
            "android.app.action.SCHEDULE_EXACT_ALARM_PERMISSION_STATE_CHANGED"

        val HANDLED_ACTIONS: Set<String> = setOf(
            Intent.ACTION_LOCKED_BOOT_COMPLETED,
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            ACTION_EXACT_ALARM_PERMISSION_CHANGED,
        )
    }
}
