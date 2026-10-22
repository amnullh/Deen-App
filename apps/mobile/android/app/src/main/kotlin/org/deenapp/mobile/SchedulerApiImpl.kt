package org.deenapp.mobile

import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.util.Log
import androidx.core.app.NotificationManagerCompat
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.deenapp.mobile.generated.AlertKind
import org.deenapp.mobile.generated.DeliveryType
import org.deenapp.mobile.generated.JournalEntry
import org.deenapp.mobile.generated.PendingSummary
import org.deenapp.mobile.generated.PermissionSnapshot
import org.deenapp.mobile.generated.ScheduledAlert
import org.deenapp.mobile.generated.SchedulerApi
import org.deenapp.mobile.generated.SchedulerEvents
import org.deenapp.mobile.generated.SchedulerResult
import org.deenapp.mobile.generated.VolumeChoiceDto

/**
 * Android implementation of the Pigeon [SchedulerApi]: a thin layer over [AlarmScheduler],
 * [AlertJournal] and the settings screens. No method throws across the channel; failures come
 * back as a [SchedulerResult] with an error code.
 *
 * `replaceSchedule` returns `ok = true` with `errorCode = "exact_alarm_denied"` when the alerts
 * were registered but inexactly, so the Reliability check can explain the reduced precision.
 */
class SchedulerApiImpl(
    context: Context,
    private val clock: Clock = Clock.SYSTEM,
) : SchedulerApi {
    private val appContext: Context = context.applicationContext ?: context
    private val scheduler = AlarmScheduler(appContext, clock)
    private val journal = AlertJournal(appContext, clock = clock)

    /** Last permission state sent to Dart or seen on resume; null before the first look. */
    private var lastPermissions: PermissionSnapshot? = null

    override suspend fun replaceSchedule(alerts: List<ScheduledAlert>): SchedulerResult =
        withContext(Dispatchers.IO) {
            val invalid = alerts.firstOrNull { it.alertId.isEmpty() || it.fireAtEpochMs <= 0L }
            if (invalid != null) {
                return@withContext SchedulerResult(
                    ok = false,
                    errorCode = "invalid_argument",
                    message = "alert with an empty id or a non-positive time",
                )
            }
            if (alerts.size > MAX_ALERTS) {
                return@withContext SchedulerResult(
                    ok = false,
                    errorCode = "invalid_argument",
                    message = "more than $MAX_ALERTS alerts",
                )
            }
            try {
                val report = scheduler.replaceSnapshot(alerts)
                when {
                    !report.snapshotSaved -> SchedulerResult(
                        ok = false,
                        errorCode = "internal_error",
                        message = "the schedule snapshot could not be saved",
                    )
                    report.registeredInexact > 0 -> SchedulerResult(
                        ok = true,
                        errorCode = "exact_alarm_denied",
                        message = "registered without exact timing",
                    )
                    else -> SchedulerResult(ok = true)
                }
            } catch (e: Exception) {
                Log.w(TAG, "replaceSchedule failed: ${e.javaClass.simpleName}")
                SchedulerResult(ok = false, errorCode = "internal_error", message = e.javaClass.simpleName)
            }
        }

    override suspend fun scheduleTestAlert(delaySeconds: Long, delivery: DeliveryType): SchedulerResult =
        withContext(Dispatchers.IO) {
            if (delaySeconds < 0L || delaySeconds > MAX_TEST_DELAY_SECONDS) {
                return@withContext SchedulerResult(
                    ok = false,
                    errorCode = "invalid_argument",
                    message = "delay must be between 0 and $MAX_TEST_DELAY_SECONDS seconds",
                )
            }
            try {
                val registered = scheduler.scheduleOneOff(buildTestAlert(delaySeconds, delivery))
                when {
                    !registered -> SchedulerResult(
                        ok = false,
                        errorCode = "exact_alarm_denied",
                        message = "the system refused the alarm",
                    )
                    !scheduler.canScheduleExact() -> SchedulerResult(
                        ok = true,
                        errorCode = "exact_alarm_denied",
                        message = "registered without exact timing",
                    )
                    else -> SchedulerResult(ok = true)
                }
            } catch (e: Exception) {
                Log.w(TAG, "scheduleTestAlert failed: ${e.javaClass.simpleName}")
                SchedulerResult(ok = false, errorCode = "internal_error", message = e.javaClass.simpleName)
            }
        }

    override fun getPermissionState(): PermissionSnapshot {
        val power = appContext.getSystemService(PowerManager::class.java)
        val snapshot = PermissionSnapshot(
            notificationsGranted = NotificationManagerCompat.from(appContext).areNotificationsEnabled(),
            exactAlarmGranted = scheduler.canScheduleExact(),
            batteryOptimizationIgnored = power.isIgnoringBatteryOptimizations(appContext.packageName),
        )
        lastPermissions = snapshot
        return snapshot
    }

    override fun openExactAlarmSettings() {
        val packageUri = Uri.parse("package:${appContext.packageName}")
        val primary = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM, packageUri)
        } else {
            // Before Android 12 the permission is not user-controlled; show the app's own page.
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, packageUri)
        }
        openSettings(primary)
    }

    override fun openBatterySettings() {
        // Opens the system battery-optimization list. The direct "ignore" request is never made.
        openSettings(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
    }

    override fun openAppNotificationSettings() {
        openSettings(
            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                .putExtra(Settings.EXTRA_APP_PACKAGE, appContext.packageName),
        )
    }

    override fun readJournal(sinceEpochMs: Long): List<JournalEntry> = journal.read(sinceEpochMs)

    override fun clearJournal() = journal.clear()

    override fun getPendingSummary(): PendingSummary = scheduler.summary()

    /**
     * Called when the app comes to the foreground. If a permission changed while the app was away
     * (the user used the system settings), tells Dart so it refreshes the Reliability check and
     * rebuilds the schedule. The first call only records the baseline.
     */
    fun notifyIfPermissionsChanged(events: SchedulerEvents, scope: CoroutineScope) {
        val before = lastPermissions
        val now = getPermissionState()
        if (before == null || before == now) return
        scope.launch {
            try {
                events.onPermissionChanged(now)
            } catch (e: Exception) {
                Log.w(TAG, "onPermissionChanged not delivered: ${e.javaClass.simpleName}")
            }
        }
    }

    /**
     * The one-off alert for "send a test Azaan in 1 minute". The Pigeon call carries only the delay
     * and the delivery type, so the text, recording and loudness are borrowed from the next real
     * alert in the snapshot; with no snapshot it uses the module's own localized fallback text.
     */
    private fun buildTestAlert(delaySeconds: Long, delivery: DeliveryType): ScheduledAlert {
        val now = clock.nowMs()
        val summary = scheduler.summary()
        val template = summary.nextAlerts.firstOrNull { it.kind == AlertKind.PRAYER }
            ?: summary.nextAlerts.firstOrNull()
        val audioRef = summary.nextAlerts.firstOrNull { it.audioRef != null }?.audioRef
        return ScheduledAlert(
            alertId = AlertIds.TEST_PREFIX + now,
            fireAtEpochMs = now + delaySeconds * 1000L,
            kind = AlertKind.PRAYER,
            delivery = delivery,
            audioRef = audioRef,
            title = template?.title ?: appContext.getString(R.string.test_alert_title),
            body = template?.body ?: appContext.getString(R.string.test_alert_body),
            stopLabel = template?.stopLabel ?: appContext.getString(R.string.default_stop_label),
            loudMode = template?.loudMode ?: PlaybackPolicy.DEFAULT_LOUD_MODE,
            volumeChoice = template?.volumeChoice ?: VolumeChoiceDto.KEEP_CURRENT,
            preciseAllowed = true,
            audioOutput = template?.audioOutput,
        )
    }

    private fun openSettings(intent: Intent) {
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        try {
            appContext.startActivity(intent)
        } catch (e: ActivityNotFoundException) {
            // Some devices lack a given settings page; the app's own settings page always exists.
            val fallback = Intent(
                Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                Uri.parse("package:${appContext.packageName}"),
            ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            try {
                appContext.startActivity(fallback)
            } catch (e2: ActivityNotFoundException) {
                Log.w(TAG, "no settings screen could be opened")
            }
        }
    }

    private companion object {
        const val TAG = "SchedulerApiImpl"
        const val MAX_ALERTS = 5000
        const val MAX_TEST_DELAY_SECONDS = 3600L
    }
}
