package org.deenapp.mobile

import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import java.io.File
import java.io.IOException

/**
 * Device-protected storage helpers. The snapshot, registry and journal live here so that alarms
 * can be re-registered and fired after a reboot, before the user unlocks the device (direct
 * boot). Nothing stored here is personal data beyond prayer times and localized alert text.
 */
object DeviceStorage {
    private const val TAG = "DeviceStorage"

    /** A context whose files and preferences are readable before the first unlock. */
    fun context(base: Context): Context {
        val app = base.applicationContext ?: base
        return if (app.isDeviceProtectedStorage) app else app.createDeviceProtectedStorageContext()
    }

    fun file(base: Context, name: String): File = File(context(base).filesDir, name)

    fun prefs(base: Context, name: String): SharedPreferences =
        context(base).getSharedPreferences(name, Context.MODE_PRIVATE)

    /** Writes [text] to [target] through a temporary file so a crash never leaves half a file. */
    fun writeAtomically(target: File, text: String): Boolean {
        val temp = File(target.parentFile, target.name + ".tmp")
        return try {
            target.parentFile?.mkdirs()
            temp.writeText(text, Charsets.UTF_8)
            // rename(2) replaces an existing target in one step.
            temp.renameTo(target)
        } catch (e: IOException) {
            Log.w(TAG, "write failed for ${target.name}: ${e.javaClass.simpleName}")
            false
        }
    }
}
