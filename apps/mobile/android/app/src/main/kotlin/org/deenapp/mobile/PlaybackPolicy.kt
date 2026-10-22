package org.deenapp.mobile

import android.media.AudioAttributes
import org.deenapp.mobile.generated.ScheduledAlert
import org.deenapp.mobile.generated.VolumeChoiceDto

/**
 * The rules for how the Azaan is played, kept apart from the service so they can be tested.
 *
 * Nothing here, and nothing in the service, changes a system stream volume (spec D7). The
 * "gentle ramp" moves only the MediaPlayer's own volume.
 */
object PlaybackPolicy {
    /** Proposed values (contracts/platform-scheduling.md); tune on devices. */
    const val RAMP_START_VOLUME = 0.2f
    const val RAMP_END_VOLUME = 1.0f
    const val RAMP_DURATION_MS = 8_000L
    const val RAMP_STEP_MS = 250L

    /** Loud mode is off unless the alert says so (clarification D7). */
    const val DEFAULT_LOUD_MODE = false

    /** `USAGE_ALARM` only in loud mode; otherwise the Azaan behaves like a notification. */
    fun usageFor(loudMode: Boolean): Int =
        if (loudMode) AudioAttributes.USAGE_ALARM else AudioAttributes.USAGE_NOTIFICATION

    fun audioAttributes(loudMode: Boolean): AudioAttributes = AudioAttributes.Builder()
        .setUsage(usageFor(loudMode))
        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
        .build()

    fun usesRamp(alert: ScheduledAlert): Boolean = alert.volumeChoice == VolumeChoiceDto.GENTLE_RAMP

    /** Player volume when playback starts: low for a ramp, full otherwise. */
    fun initialVolume(alert: ScheduledAlert): Float =
        if (usesRamp(alert)) RAMP_START_VOLUME else RAMP_END_VOLUME

    /** Player volume [elapsedMs] after playback started, rising linearly from start to end. */
    fun rampVolume(elapsedMs: Long): Float {
        val fraction = (elapsedMs.toFloat() / RAMP_DURATION_MS).coerceIn(0f, 1f)
        return RAMP_START_VOLUME + (RAMP_END_VOLUME - RAMP_START_VOLUME) * fraction
    }
}
