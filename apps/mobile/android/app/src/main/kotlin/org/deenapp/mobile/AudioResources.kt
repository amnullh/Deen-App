package org.deenapp.mobile

import android.content.Context

/**
 * Maps a `ScheduledAlert.audioRef` such as `voice-1/fajr` to a raw resource.
 *
 * The rule is the one `tools/sync_content/lib/sync_plan.dart` (`androidResourceName`) uses when it
 * copies recordings into `res/raw`: lower-case, every run of characters outside `[a-z0-9_]`
 * becomes `_`, repeated and edge underscores are trimmed, and a name that is empty or starts with
 * a digit gets the prefix `r_`. The recordings are not in the repository yet, so a missing
 * resource is a normal case that callers handle (journal `failed`, fall back to a channel sound).
 */
object AudioResources {
    private val NON_NAME = Regex("[^a-z0-9_]+")
    private val MANY_UNDERSCORES = Regex("_+")

    /** The resource name (without extension) for [audioRef]. */
    fun resourceName(audioRef: String): String {
        var cleaned = audioRef.lowercase().replace(NON_NAME, "_")
        cleaned = cleaned.replace(MANY_UNDERSCORES, "_").trim('_')
        if (cleaned.isEmpty() || cleaned[0].isDigit()) cleaned = "r_$cleaned"
        return cleaned
    }

    /** The raw resource id, or 0 when the recording is not bundled. */
    fun find(context: Context, audioRef: String): Int =
        context.resources.getIdentifier(resourceName(audioRef), "raw", context.packageName)

    /** `voice-1/fajr` becomes the channel-id part `voice_1_fajr`. */
    fun channelToken(audioRef: String): String = resourceName(audioRef)
}
