package org.deenapp.mobile

import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.os.SystemClock
import android.os.VibrationEffect
import android.os.Vibrator
import android.util.Log
import androidx.core.app.ServiceCompat
import org.deenapp.mobile.generated.JournalEntry
import org.deenapp.mobile.generated.JournalState
import org.deenapp.mobile.generated.ScheduledAlert

/**
 * Plays the full Azaan with [MediaPlayer] as a foreground service of type `mediaPlayback`. No
 * Dart engine is involved.
 *
 * Order matters (research R-A3, R-A6): `startForeground` first (Android requires it within seconds
 * of `startForegroundService`), then the arbiter check, then audio focus (apps targeting Android 15
 * may request focus only while a foreground service runs), then playback.
 *
 * Audio attributes use `USAGE_ALARM` only in loud mode, `USAGE_NOTIFICATION` otherwise. The
 * service never changes a system stream volume; the optional gentle ramp moves only the player's
 * own volume. Losing audio focus (an incoming call) stops playback, vibrates instead, and journals
 * `suppressed:call_in_progress`. The notification's Stop action reaches [AlarmReceiver], which
 * stops this service (`onDestroy` releases the player and abandons focus) and journals
 * `acknowledged`.
 */
class AzaanPlaybackService : Service() {

    private val handler = Handler(Looper.getMainLooper())
    private lateinit var journal: AlertJournal
    private lateinit var audioManager: AudioManager

    private var player: MediaPlayer? = null
    private var focusRequest: AudioFocusRequest? = null
    private var alert: ScheduledAlert? = null
    private var playedRecorded = false
    private var finished = true
    private var rampStartedAt = 0L

    private val focusListener = AudioManager.OnAudioFocusChangeListener { change ->
        if (change == AudioManager.AUDIOFOCUS_LOSS || change == AudioManager.AUDIOFOCUS_LOSS_TRANSIENT) {
            onInterrupted()
        }
    }

    private val rampTick = object : Runnable {
        override fun run() {
            val current = player ?: return
            val elapsed = SystemClock.elapsedRealtime() - rampStartedAt
            val volume = PlaybackPolicy.rampVolume(elapsed)
            current.setVolume(volume, volume)
            if (elapsed < PlaybackPolicy.RAMP_DURATION_MS) {
                handler.postDelayed(this, PlaybackPolicy.RAMP_STEP_MS)
            }
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        journal = AlertJournal(this)
        audioManager = getSystemService(AudioManager::class.java)
        // The foreground notification needs its channel to exist before startForeground.
        Notifications.ensureChannels(this)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val requested = AlertCodec.fromJsonString(intent?.getStringExtra(AlarmReceiver.EXTRA_ALERT_JSON))
        if (requested == null) {
            // startForegroundService promises a notification; give one, then leave.
            enterForegroundWith(Notifications.playbackNotificationId("unknown")) { Notifications.buildMinimal(this) }
            finishPlayback()
            return START_NOT_STICKY
        }
        val duplicate = !finished && alert?.alertId == requested.alertId
        if (!enterForeground(requested)) return START_NOT_STICKY
        if (duplicate) return START_NOT_STICKY

        releasePlayer()
        alert = requested
        activeAlertId = requested.alertId
        finished = false
        playedRecorded = false
        if (Arbiter.decide(requested.alertId, journal.entriesFor(requested.alertId)) ==
            Arbiter.Verdict.ALREADY_PLAYED
        ) {
            finishPlayback()
            return START_NOT_STICKY
        }
        beginPlayback(requested)
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        finished = true
        releasePlayer()
        activeAlertId = null
        super.onDestroy()
    }

    /** Enters the foreground. On failure it journals `failed:fgs_blocked` and posts the fallback. */
    private fun enterForeground(alert: ScheduledAlert): Boolean {
        val ok = enterForegroundWith(Notifications.playbackNotificationId(alert.alertId)) {
            Notifications.buildPlayback(this, alert)
        }
        if (!ok) {
            record(alert, JournalState.FAILED, AlarmReceiver.CAUSE_FGS_BLOCKED)
            Notifications.post(this, alert, Notifications.ensureAzaanChannel(this, alert))
            finishPlayback()
        }
        return ok
    }

    private fun enterForegroundWith(id: Int, notification: () -> android.app.Notification): Boolean = try {
        ServiceCompat.startForeground(this, id, notification(), ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK)
        true
    } catch (e: Exception) {
        // ForegroundServiceStartNotAllowedException and SecurityException both land here.
        Log.w(TAG, "startForeground refused: ${e.javaClass.simpleName}")
        false
    }

    private fun beginPlayback(alert: ScheduledAlert) {
        val audioRef = alert.audioRef
        val resId = if (audioRef == null) 0 else AudioResources.find(this, audioRef)
        if (resId == 0) {
            // The recording is not bundled (yet): say so, and fall back to the channel sound.
            failWithFallback(alert)
            return
        }
        if (isCallActive() || !requestFocus(alert)) {
            suppressForCall(alert)
            return
        }
        try {
            startPlayer(alert, resId)
        } catch (e: Exception) {
            Log.w(TAG, "player setup failed: ${e.javaClass.simpleName}")
            releasePlayer()
            failWithFallback(alert)
        }
    }

    private fun isCallActive(): Boolean {
        val mode = audioManager.mode
        return mode == AudioManager.MODE_IN_CALL ||
            mode == AudioManager.MODE_RINGTONE ||
            mode == AudioManager.MODE_IN_COMMUNICATION
    }

    private fun requestFocus(alert: ScheduledAlert): Boolean {
        val request = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT)
            .setAudioAttributes(PlaybackPolicy.audioAttributes(alert.loudMode))
            .setOnAudioFocusChangeListener(focusListener, handler)
            .build()
        focusRequest = request
        return audioManager.requestAudioFocus(request) == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
    }

    private fun startPlayer(alert: ScheduledAlert, resId: Int) {
        val mp = MediaPlayer()
        player = mp
        mp.setAudioAttributes(PlaybackPolicy.audioAttributes(alert.loudMode))
        mp.setWakeMode(applicationContext, PowerManager.PARTIAL_WAKE_LOCK)
        resources.openRawResourceFd(resId).use { mp.setDataSource(it.fileDescriptor, it.startOffset, it.length) }
        AudioRouting.routePlayer(this, mp, AudioOutputChoice.from(alert.audioOutput))
        mp.setOnPreparedListener { onPrepared(it, alert) }
        mp.setOnCompletionListener { finishPlayback() }
        mp.setOnErrorListener { _, _, _ ->
            onPlayerError(alert)
            true
        }
        mp.prepareAsync()
    }

    private fun onPrepared(mp: MediaPlayer, alert: ScheduledAlert) {
        if (finished || player !== mp) return
        val volume = PlaybackPolicy.initialVolume(alert)
        mp.setVolume(volume, volume)
        mp.start()
        playedRecorded = true
        record(alert, JournalState.PLAYED, null)
        if (PlaybackPolicy.usesRamp(alert)) {
            rampStartedAt = SystemClock.elapsedRealtime()
            handler.post(rampTick)
        }
    }

    private fun onPlayerError(alert: ScheduledAlert) {
        if (finished) return
        if (playedRecorded) {
            record(alert, JournalState.FAILED, AlarmReceiver.CAUSE_UNKNOWN)
            finishPlayback()
        } else {
            releasePlayer()
            failWithFallback(alert)
        }
    }

    /** Nothing audible happened: journal `failed` and post the notification with the channel sound. */
    private fun failWithFallback(alert: ScheduledAlert) {
        record(alert, JournalState.FAILED, AlarmReceiver.CAUSE_UNKNOWN)
        Notifications.post(this, alert, Notifications.ensureAzaanChannel(this, alert))
        finishPlayback()
    }

    private fun onInterrupted() {
        val current = alert ?: return
        if (finished) return
        suppressForCall(current)
    }

    /** A call has the audio: do not play, vibrate instead, and record why. */
    private fun suppressForCall(alert: ScheduledAlert) {
        record(alert, JournalState.SUPPRESSED, AlarmReceiver.CAUSE_CALL_IN_PROGRESS)
        vibrate()
        finishPlayback()
    }

    private fun vibrate() {
        val vibrator = getSystemService(Vibrator::class.java) ?: return
        if (!vibrator.hasVibrator()) return
        vibrator.vibrate(VibrationEffect.createWaveform(VIBRATE_PATTERN, -1))
    }

    private fun record(alert: ScheduledAlert, state: JournalState, cause: String?) {
        journal.append(
            JournalEntry(
                alertId = alert.alertId,
                plannedAtEpochMs = alert.fireAtEpochMs,
                firedAtEpochMs = Clock.SYSTEM.nowMs(),
                state = state,
                cause = cause,
            ),
        )
    }

    private fun finishPlayback() {
        finished = true
        releasePlayer()
        ServiceCompat.stopForeground(this, ServiceCompat.STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    /** Stops the player and gives audio focus back. Safe to call repeatedly. */
    private fun releasePlayer() {
        handler.removeCallbacks(rampTick)
        player?.let {
            try {
                it.release()
            } catch (e: IllegalStateException) {
                Log.w(TAG, "player release failed")
            }
        }
        player = null
        focusRequest?.let { audioManager.abandonAudioFocusRequest(it) }
        focusRequest = null
    }

    companion object {
        private const val TAG = "AzaanPlaybackService"
        private val VIBRATE_PATTERN = longArrayOf(0, 500, 250, 500, 250, 500)

        /** The alert currently playing in this process, or null. */
        @Volatile
        var activeAlertId: String? = null
            private set

        /** Stops the service when it is playing [alertId]. */
        fun stopIfPlaying(context: Context, alertId: String) {
            if (activeAlertId == alertId) {
                context.stopService(Intent(context, AzaanPlaybackService::class.java))
            }
        }
    }
}
