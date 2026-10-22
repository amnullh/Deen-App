package org.deenapp.mobile

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.util.Log
import androidx.core.content.ContextCompat
import org.deenapp.mobile.generated.DeliveryType
import org.deenapp.mobile.generated.JournalEntry
import org.deenapp.mobile.generated.JournalState
import org.deenapp.mobile.generated.ScheduledAlert

/**
 * Receives the alarm for one alert, and the Stop / Acknowledge notification action.
 *
 * At alarm time, with the app not running and no Dart code, it: asks the [Arbiter] whether this
 * alert was already played, journals `fired`, then either starts [AzaanPlaybackService] (full
 * Azaan) or posts a notification (every other delivery type). If the service cannot start, it posts
 * a notification on a channel whose sound is the Azaan and journals `failed:fgs_blocked`. Last, it
 * tops up the registered window from the snapshot.
 */
class AlarmReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        // Journal and notification work is small, but file access on the main thread is avoided.
        val pending: BroadcastReceiver.PendingResult? = goAsync()
        Thread {
            try {
                handle(context, intent, Clock.SYSTEM)
            } catch (e: Exception) {
                Log.w(TAG, "alarm handling failed: ${e.javaClass.simpleName}")
            } finally {
                pending?.finish()
            }
        }.start()
    }

    /** The receiver's work, separate from [onReceive] so tests can run it synchronously. */
    fun handle(context: Context, intent: Intent, clock: Clock) {
        when (intent.action) {
            ACTION_ALARM -> handleAlarm(context, intent, clock)
            ACTION_ACKNOWLEDGE -> handleAcknowledge(context, intent, clock)
        }
    }

    private fun handleAlarm(context: Context, intent: Intent, clock: Clock) {
        val alert = AlertCodec.fromJsonString(intent.getStringExtra(EXTRA_ALERT_JSON))
        if (alert != null) {
            deliver(context, alert, intent.getBooleanExtra(EXTRA_INEXACT, false), clock)
        }
        // Even a malformed alarm must not stop the window from being topped up.
        AlarmScheduler(context, clock).topUp()
    }

    private fun deliver(context: Context, alert: ScheduledAlert, inexact: Boolean, clock: Clock) {
        val journal = AlertJournal(context, clock = clock)
        if (Arbiter.decide(alert.alertId, journal.entriesFor(alert.alertId)) == Arbiter.Verdict.ALREADY_PLAYED) {
            return
        }
        journal.append(
            JournalEntry(
                alertId = alert.alertId,
                plannedAtEpochMs = alert.fireAtEpochMs,
                firedAtEpochMs = clock.nowMs(),
                state = JournalState.FIRED,
                cause = if (inexact) CAUSE_EXACT_ALARM_DENIED else null,
            ),
        )
        if (alert.delivery == DeliveryType.FULL_AZAAN) {
            startPlayback(context, alert, inexact, journal, clock)
        } else {
            postNotification(context, alert, journal, clock)
        }
    }

    private fun startPlayback(
        context: Context,
        alert: ScheduledAlert,
        inexact: Boolean,
        journal: AlertJournal,
        clock: Clock,
    ) {
        try {
            ContextCompat.startForegroundService(context, playbackIntent(context, alert, inexact))
        } catch (e: Exception) {
            // ForegroundServiceStartNotAllowedException (Android 12+), SecurityException, and
            // IllegalStateException all end up here: fall back to a channel-sound notification.
            Log.w(TAG, "playback service start blocked: ${e.javaClass.simpleName}")
            journalFailure(journal, alert, clock, CAUSE_FGS_BLOCKED)
            Notifications.post(context, alert, Notifications.ensureAzaanChannel(context, alert))
        }
    }

    private fun postNotification(context: Context, alert: ScheduledAlert, journal: AlertJournal, clock: Clock) {
        if (!Notifications.post(context, alert, Notifications.channelFor(context, alert))) {
            journalFailure(journal, alert, clock, CAUSE_NOTIFICATION_DENIED)
        }
    }

    private fun handleAcknowledge(context: Context, intent: Intent, clock: Clock) {
        val alert = AlertCodec.fromJsonString(intent.getStringExtra(EXTRA_ALERT_JSON)) ?: return
        Notifications.cancel(context, alert.alertId)
        AzaanPlaybackService.stopIfPlaying(context, alert.alertId)
        AlertJournal(context, clock = clock).append(
            JournalEntry(
                alertId = alert.alertId,
                plannedAtEpochMs = alert.fireAtEpochMs,
                firedAtEpochMs = clock.nowMs(),
                state = JournalState.ACKNOWLEDGED,
                cause = null,
            ),
        )
    }

    private fun journalFailure(journal: AlertJournal, alert: ScheduledAlert, clock: Clock, cause: String) {
        journal.append(
            JournalEntry(
                alertId = alert.alertId,
                plannedAtEpochMs = alert.fireAtEpochMs,
                firedAtEpochMs = clock.nowMs(),
                state = JournalState.FAILED,
                cause = cause,
            ),
        )
    }

    companion object {
        const val ACTION_ALARM = "org.deenapp.mobile.action.ALARM"
        const val ACTION_ACKNOWLEDGE = "org.deenapp.mobile.action.ACKNOWLEDGE"
        const val EXTRA_ALERT_JSON = "org.deenapp.mobile.extra.ALERT_JSON"
        const val EXTRA_INEXACT = "org.deenapp.mobile.extra.INEXACT"

        /** Journal causes from data-model.md. */
        const val CAUSE_EXACT_ALARM_DENIED = "exact_alarm_denied"
        const val CAUSE_NOTIFICATION_DENIED = "notification_denied"
        const val CAUSE_FGS_BLOCKED = "fgs_blocked"
        const val CAUSE_CALL_IN_PROGRESS = "call_in_progress"
        const val CAUSE_UNKNOWN = "unknown"

        private const val TAG = "AlarmReceiver"

        /**
         * A distinct data URI per alert makes each alert's PendingIntent unique (extras are not
         * part of PendingIntent identity), so alarms can be cancelled one by one.
         */
        fun alarmData(alertId: String): Uri =
            Uri.Builder().scheme("deen-alert").authority("alarm").appendPath(alertId).build()

        /** Same identity as the registered alarm, without extras; for cancelling and lookups. */
        fun probeIntent(context: Context, alertId: String): Intent =
            Intent(context, AlarmReceiver::class.java).setAction(ACTION_ALARM).setData(alarmData(alertId))

        /** The intent an alarm delivers: the whole alert travels in it, so no lookup is needed. */
        fun alarmIntent(context: Context, alert: ScheduledAlert, inexact: Boolean): Intent =
            probeIntent(context, alert.alertId)
                .putExtra(EXTRA_ALERT_JSON, AlertCodec.toJsonString(alert))
                .putExtra(EXTRA_INEXACT, inexact)

        /** The Stop / Acknowledge notification action. */
        fun acknowledgeIntent(context: Context, alert: ScheduledAlert): Intent =
            Intent(context, AlarmReceiver::class.java)
                .setAction(ACTION_ACKNOWLEDGE)
                .setData(alarmData(alert.alertId))
                .putExtra(EXTRA_ALERT_JSON, AlertCodec.toJsonString(alert))

        /** Intent that starts [AzaanPlaybackService] for [alert]. */
        fun playbackIntent(context: Context, alert: ScheduledAlert, inexact: Boolean): Intent =
            Intent(context, AzaanPlaybackService::class.java)
                .putExtra(EXTRA_ALERT_JSON, AlertCodec.toJsonString(alert))
                .putExtra(EXTRA_INEXACT, inexact)
    }
}
