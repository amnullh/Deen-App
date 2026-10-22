package org.deenapp.mobile

import android.content.Context
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Build
import org.deenapp.mobile.generated.AudioOutputDto

/** Where the Azaan should be heard (spec Story 3, scenario 8). Mirrors the Dart `AudioOutput`. */
enum class AudioOutputChoice {
    SPEAKER,
    HEADPHONES,
    BLUETOOTH;

    companion object {
        /** The alert's `audioOutput`; null means the speaker. */
        fun from(dto: AudioOutputDto?): AudioOutputChoice = when (dto) {
            AudioOutputDto.HEADPHONES -> HEADPHONES
            AudioOutputDto.BLUETOOTH -> BLUETOOTH
            else -> SPEAKER
        }
    }
}

/**
 * Output routing for the Azaan: the phone speaker by default, headphones or Bluetooth only when
 * the alert says the user chose them (`ScheduledAlert.audioOutput`) and the device is connected. A chosen device that is not connected falls
 * back to the speaker. Routing is a MediaPlayer preference; it never touches system volume.
 *
 * `MediaPlayer.setPreferredDevice` exists from Android 9 (API 28). On Android 8 the system
 * default routing applies (headphones when plugged in).
 */
object AudioRouting {
    /** The AudioDeviceInfo types that satisfy [choice]. */
    fun typesFor(choice: AudioOutputChoice): Set<Int> = when (choice) {
        AudioOutputChoice.SPEAKER -> setOf(AudioDeviceInfo.TYPE_BUILTIN_SPEAKER)
        AudioOutputChoice.HEADPHONES -> setOf(
            AudioDeviceInfo.TYPE_WIRED_HEADPHONES,
            AudioDeviceInfo.TYPE_WIRED_HEADSET,
            AudioDeviceInfo.TYPE_USB_HEADSET,
        )
        AudioOutputChoice.BLUETOOTH -> setOf(
            AudioDeviceInfo.TYPE_BLUETOOTH_A2DP,
            AudioDeviceInfo.TYPE_BLE_HEADSET,
        )
    }

    /** The device for [choice], else the built-in speaker, else null (system default). */
    fun selectDevice(devices: List<AudioDeviceInfo>, choice: AudioOutputChoice): AudioDeviceInfo? {
        val sinks = devices.filter { it.isSink }
        val wanted = typesFor(choice)
        return sinks.firstOrNull { it.type in wanted }
            ?: sinks.firstOrNull { it.type in typesFor(AudioOutputChoice.SPEAKER) }
    }

    /** Applies [choice] to [player]. Returns true when a device preference was set. */
    fun routePlayer(context: Context, player: MediaPlayer, choice: AudioOutputChoice): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) return false
        val audioManager = context.getSystemService(AudioManager::class.java)
        val devices = audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS).toList()
        val device = selectDevice(devices, choice) ?: return false
        return player.setPreferredDevice(device)
    }
}
