package org.deenapp.mobile

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.Settings
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import org.deenapp.mobile.generated.AlertKind
import org.deenapp.mobile.generated.DeliveryType
import org.deenapp.mobile.generated.ScheduledAlert

/**
 * Notification channels and the localized notification builder.
 *
 * Channels are immutable once created (sound and importance), so each has a versioned id and a
 * changed sound gets a new version suffix; a channel is never edited. Titles, bodies and the
 * Stop / Acknowledge label are already localized in the [ScheduledAlert]; only the channel names
 * (shown in system settings) come from this module's string resources.
 */
object Notifications {
    const val CHANNEL_TONE = "tone_v1"
    const val CHANNEL_SILENT = "silent_v1"
    const val CHANNEL_VIBRATE = "vibrate_v1"
    const val CHANNEL_REMINDER = "reminder_v1"
    const val CHANNEL_RENEWAL = "renewal_v1"
    const val CHANNEL_PLAYBACK = "playback_v1"
    private const val AZAAN_PREFIX = "azaan_v1_"
    private const val LOUD_SUFFIX = "_loud"

    /** Extra on the content intent: which alert's notification was tapped. */
    const val EXTRA_ALERT_ID = "org.deenapp.mobile.ALERT_ID"

    private val VIBRATE_PATTERN = longArrayOf(0, 400, 200, 400)

    /**
     * Creates the fixed channels. Safe to call repeatedly: creating an existing channel is a
     * no-op. The tone channel uses the bundled `tone_v1` clip when it exists, else the system
     * default notification sound.
     */
    fun ensureChannels(context: Context) {
        val manager = context.getSystemService(NotificationManager::class.java)
        val attributes = PlaybackPolicy.audioAttributes(loudMode = false)

        val tone = NotificationChannel(
            CHANNEL_TONE, context.getString(R.string.channel_tone), NotificationManager.IMPORTANCE_HIGH,
        ).apply { setSound(toneSound(context), attributes) }

        val silent = NotificationChannel(
            CHANNEL_SILENT, context.getString(R.string.channel_silent), NotificationManager.IMPORTANCE_LOW,
        ).apply {
            setSound(null, null)
            enableVibration(false)
        }

        val vibrate = NotificationChannel(
            CHANNEL_VIBRATE, context.getString(R.string.channel_vibrate), NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            setSound(null, null)
            enableVibration(true)
            vibrationPattern = VIBRATE_PATTERN
        }

        val reminder = NotificationChannel(
            CHANNEL_REMINDER, context.getString(R.string.channel_reminder), NotificationManager.IMPORTANCE_DEFAULT,
        )

        val renewal = NotificationChannel(
            CHANNEL_RENEWAL, context.getString(R.string.channel_renewal), NotificationManager.IMPORTANCE_DEFAULT,
        )

        val playback = NotificationChannel(
            CHANNEL_PLAYBACK, context.getString(R.string.channel_playback), NotificationManager.IMPORTANCE_LOW,
        ).apply {
            setSound(null, null)
            enableVibration(false)
            setShowBadge(false)
        }

        manager.createNotificationChannels(listOf(tone, silent, vibrate, reminder, renewal, playback))
    }

    /** `azaan_v1_<voice>_<variant>` (plus `_loud`), derived from the audioRef `<voice>/<variant>`. */
    fun azaanChannelId(audioRef: String, loudMode: Boolean): String =
        AZAAN_PREFIX + AudioResources.channelToken(audioRef) + if (loudMode) LOUD_SUFFIX else ""

    /**
     * The channel for a full-Azaan notification (the fallback when the playback service cannot
     * run). Its sound is the recording. If the alert has no recording, or it is not bundled, the
     * tone channel is returned instead; no Azaan channel is created with a placeholder sound,
     * because a channel's sound can never be changed afterwards.
     */
    fun ensureAzaanChannel(context: Context, alert: ScheduledAlert): String {
        ensureChannels(context)
        val audioRef = alert.audioRef ?: return CHANNEL_TONE
        val resId = AudioResources.find(context, audioRef)
        if (resId == 0) return CHANNEL_TONE
        val id = azaanChannelId(audioRef, alert.loudMode)
        val channel = NotificationChannel(
            id,
            context.getString(R.string.channel_azaan, AudioResources.channelToken(audioRef)),
            NotificationManager.IMPORTANCE_HIGH,
        ).apply { setSound(rawUri(context, resId), PlaybackPolicy.audioAttributes(alert.loudMode)) }
        context.getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        return id
    }

    /** The channel for [alert] when it is delivered as a plain notification. */
    fun channelFor(context: Context, alert: ScheduledAlert): String = when {
        alert.kind == AlertKind.RENEWAL -> CHANNEL_RENEWAL
        alert.delivery == DeliveryType.SILENT -> CHANNEL_SILENT
        alert.delivery == DeliveryType.VIBRATE -> CHANNEL_VIBRATE
        // Reminders never play a full Azaan; they use the reminder channel's sound.
        alert.kind != AlertKind.PRAYER -> CHANNEL_REMINDER
        alert.delivery == DeliveryType.FULL_AZAAN -> ensureAzaanChannel(context, alert)
        else -> CHANNEL_TONE
    }

    /** Stable notification id for an alert, so a repeat replaces instead of stacking. */
    fun notificationId(alertId: String): Int {
        val id = alertId.hashCode() and 0x7fffffff
        return if (id == 0) 1 else id
    }

    /**
     * Id of the service's ongoing notification. It differs from [notificationId] so that a
     * fallback notification posted for the same alert is not removed when the service stops.
     */
    fun playbackNotificationId(alertId: String): Int = notificationId(alertId) or 0x40000000

    fun areEnabled(context: Context): Boolean =
        NotificationManagerCompat.from(context).areNotificationsEnabled()

    /** Posts [alert] on [channelId]. Returns false when notifications are off or refused. */
    fun post(context: Context, alert: ScheduledAlert, channelId: String): Boolean {
        val manager = NotificationManagerCompat.from(context)
        if (!manager.areNotificationsEnabled()) return false
        ensureChannels(context)
        return try {
            manager.notify(notificationId(alert.alertId), build(context, alert, channelId))
            true
        } catch (e: SecurityException) {
            false
        }
    }

    fun cancel(context: Context, alertId: String) {
        val manager = NotificationManagerCompat.from(context)
        manager.cancel(notificationId(alertId))
        manager.cancel(playbackNotificationId(alertId))
    }

    /** The visible notification for an alert, with the Stop / Acknowledge action. */
    fun build(context: Context, alert: ScheduledAlert, channelId: String): Notification {
        val builder = base(context, alert, channelId)
            .setCategory(
                if (alert.kind == AlertKind.PRAYER) NotificationCompat.CATEGORY_EVENT
                else NotificationCompat.CATEGORY_REMINDER,
            )
            .setAutoCancel(true)
        if (alert.kind != AlertKind.RENEWAL) addStopAction(context, builder, alert)
        return builder.build()
    }

    /** The ongoing notification of [AzaanPlaybackService], silent, with the Stop action. */
    fun buildPlayback(context: Context, alert: ScheduledAlert): Notification {
        val builder = base(context, alert, CHANNEL_PLAYBACK)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setOngoing(true)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
        addStopAction(context, builder, alert)
        return builder.build()
    }

    /** Placeholder foreground notification for a service start whose alert could not be read. */
    fun buildMinimal(context: Context): Notification {
        val label = context.applicationInfo.loadLabel(context.packageManager)
        return NotificationCompat.Builder(context, CHANNEL_PLAYBACK)
            .setSmallIcon(R.drawable.ic_stat_azaan)
            .setContentTitle(label)
            .setOngoing(true)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            .build()
    }

    private fun base(context: Context, alert: ScheduledAlert, channelId: String): NotificationCompat.Builder {
        val id = notificationId(alert.alertId)
        val open = Intent(context, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            .putExtra(EXTRA_ALERT_ID, alert.alertId)
        return NotificationCompat.Builder(context, channelId)
            .setSmallIcon(R.drawable.ic_stat_azaan)
            .setContentTitle(alert.title)
            .setContentText(alert.body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(alert.body))
            .setWhen(alert.fireAtEpochMs)
            .setShowWhen(true)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setContentIntent(
                PendingIntent.getActivity(
                    context,
                    id,
                    open,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                ),
            )
    }

    private fun addStopAction(context: Context, builder: NotificationCompat.Builder, alert: ScheduledAlert) {
        val label = alert.stopLabel.ifBlank { context.getString(R.string.default_stop_label) }
        val pending = PendingIntent.getBroadcast(
            context,
            notificationId(alert.alertId),
            AlarmReceiver.acknowledgeIntent(context, alert),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        builder.addAction(0, label, pending)
    }

    private fun toneSound(context: Context): Uri {
        val resId = AudioResources.find(context, CHANNEL_TONE)
        return if (resId != 0) rawUri(context, resId) else Settings.System.DEFAULT_NOTIFICATION_URI
    }

    private fun rawUri(context: Context, resId: Int): Uri =
        Uri.parse("android.resource://${context.packageName}/$resId")
}
