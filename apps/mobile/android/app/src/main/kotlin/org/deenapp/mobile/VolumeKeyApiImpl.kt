package org.deenapp.mobile

import android.util.Log
import android.view.KeyEvent
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import org.deenapp.mobile.generated.VolumeKeyApi
import org.deenapp.mobile.generated.VolumeKeyEvents

/**
 * Android [VolumeKeyApi]: while enabled (the Tasbih screen is visible and the user opted in),
 * the hardware volume keys count a bead instead of changing the volume.
 *
 * `MainActivity.dispatchKeyEvent` calls [handleKeyEvent] first. When disabled it returns false and
 * the system handles the key as usual, so system volume is never changed or blocked without the
 * user's opt-in.
 */
class VolumeKeyApiImpl(
    private val events: VolumeKeyEvents,
    private val scope: CoroutineScope = CoroutineScope(Dispatchers.Main),
) : VolumeKeyApi {

    @Volatile
    private var enabled = false

    override fun setEnabled(enabled: Boolean) {
        this.enabled = enabled
    }

    /**
     * Returns true when the key was consumed. Both the down and the up event of a volume key are
     * consumed while enabled; only the first down event (not an auto-repeat) is reported.
     */
    fun handleKeyEvent(event: KeyEvent): Boolean {
        if (!enabled) return false
        val direction = when (event.keyCode) {
            KeyEvent.KEYCODE_VOLUME_UP -> "up"
            KeyEvent.KEYCODE_VOLUME_DOWN -> "down"
            else -> return false
        }
        if (event.action == KeyEvent.ACTION_DOWN && event.repeatCount == 0) emit(direction)
        return true
    }

    private fun emit(direction: String) {
        scope.launch {
            try {
                events.onVolumeKey(direction)
            } catch (e: Exception) {
                Log.w(TAG, "volume key not delivered: ${e.javaClass.simpleName}")
            }
        }
    }

    private companion object {
        const val TAG = "VolumeKeyApiImpl"
    }
}
