package org.deenapp.mobile

import android.content.Context
import android.util.Log
import org.deenapp.mobile.generated.JournalEntry
import org.deenapp.mobile.generated.JournalState
import org.json.JSONException
import org.json.JSONObject
import java.io.File
import java.io.FileOutputStream
import java.io.IOException

/**
 * Append-only record of what the native layer did for each alert, kept in device-protected
 * storage so it can be written before the first unlock and imported by the Dart app later.
 *
 * One JSON object per line:
 * `{"a":alertId,"p":plannedMs,"f":firedMs|null,"s":stateRaw,"c":cause|null,"t":recordedMs}`.
 * `t` is when the line was written; [read] filters on it. All instances in the process share one
 * lock, so the receiver, the service and the Pigeon API can write at the same time.
 *
 * [clear] only removes what the last [read] returned, so entries written between the app's read
 * and its clear are kept. If there was no read in this process, it clears everything.
 */
class AlertJournal(
    context: Context,
    fileName: String = DEFAULT_FILE_NAME,
    private val clock: Clock = Clock.SYSTEM,
) {
    private val file: File = DeviceStorage.file(context, fileName)

    /** Appends one entry. Returns false when the file could not be written; never throws. */
    fun append(entry: JournalEntry): Boolean = synchronized(LOCK) {
        try {
            file.parentFile?.mkdirs()
            if (file.length() > MAX_BYTES) compactLocked()
            FileOutputStream(file, true).use { it.write(encode(entry, clock.nowMs())) }
            true
        } catch (e: IOException) {
            Log.w(TAG, "append failed: ${e.javaClass.simpleName}")
            false
        }
    }

    /** Entries recorded at or after [sinceEpochMs]. Remembers how much was read for [clear]. */
    fun read(sinceEpochMs: Long): List<JournalEntry> = synchronized(LOCK) {
        val bytes = readBytesLocked()
        readMark[file.path] = bytes.size.toLong()
        decodeAll(bytes).filter { it.recordedMs >= sinceEpochMs }.map { it.entry }
    }

    /** All entries for one alert, oldest first. Does not affect [clear]. */
    fun entriesFor(alertId: String): List<JournalEntry> = synchronized(LOCK) {
        decodeAll(readBytesLocked()).map { it.entry }.filter { it.alertId == alertId }
    }

    /** Removes the entries returned by the last [read] (or everything if there was none). */
    fun clear() = synchronized(LOCK) {
        val bytes = readBytesLocked()
        val mark = readMark.remove(file.path)
        try {
            if (mark == null || mark >= bytes.size) {
                file.delete()
            } else {
                val rest = bytes.copyOfRange(mark.toInt(), bytes.size)
                file.writeBytes(rest)
            }
        } catch (e: IOException) {
            Log.w(TAG, "clear failed: ${e.javaClass.simpleName}")
        }
        Unit
    }

    private fun readBytesLocked(): ByteArray = try {
        if (file.exists()) file.readBytes() else ByteArray(0)
    } catch (e: IOException) {
        Log.w(TAG, "read failed: ${e.javaClass.simpleName}")
        ByteArray(0)
    }

    /** Keeps the newest half of the lines once the file grows past [MAX_BYTES]. */
    private fun compactLocked() {
        val lines = String(readBytesLocked(), Charsets.UTF_8).lines().filter { it.isNotBlank() }
        val kept = lines.drop(lines.size / 2)
        file.writeText(kept.joinToString(separator = "\n", postfix = "\n"), Charsets.UTF_8)
        readMark.remove(file.path)
    }

    private class Recorded(val entry: JournalEntry, val recordedMs: Long)

    private fun decodeAll(bytes: ByteArray): List<Recorded> {
        val result = ArrayList<Recorded>()
        for (line in String(bytes, Charsets.UTF_8).lineSequence()) {
            if (line.isBlank()) continue
            decode(line)?.let { result.add(it) }
        }
        return result
    }

    private fun encode(entry: JournalEntry, recordedMs: Long): ByteArray {
        val json = JSONObject()
            .put("a", entry.alertId)
            .put("p", entry.plannedAtEpochMs)
            .put("f", entry.firedAtEpochMs ?: JSONObject.NULL)
            .put("s", entry.state.raw)
            .put("c", entry.cause ?: JSONObject.NULL)
            .put("t", recordedMs)
        return (json.toString() + "\n").toByteArray(Charsets.UTF_8)
    }

    /** Returns null for a torn or unknown line, so one bad line never hides the others. */
    private fun decode(line: String): Recorded? = try {
        val json = JSONObject(line)
        val state = JournalState.ofRaw(json.getInt("s"))
        if (state == null) {
            null
        } else {
            Recorded(
                JournalEntry(
                    alertId = json.getString("a"),
                    plannedAtEpochMs = json.getLong("p"),
                    firedAtEpochMs = if (json.isNull("f")) null else json.getLong("f"),
                    state = state,
                    cause = if (json.isNull("c")) null else json.getString("c"),
                ),
                json.optLong("t", 0L),
            )
        }
    } catch (e: JSONException) {
        null
    }

    companion object {
        const val DEFAULT_FILE_NAME = "journal.log"
        private const val TAG = "AlertJournal"
        private const val MAX_BYTES = 1_000_000L
        private val LOCK = Any()

        /** Bytes returned by the last read, per journal file. Guarded by [LOCK]. */
        private val readMark = HashMap<String, Long>()
    }
}
