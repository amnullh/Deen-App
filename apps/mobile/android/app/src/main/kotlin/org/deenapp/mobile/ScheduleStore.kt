package org.deenapp.mobile

import android.content.Context
import org.deenapp.mobile.generated.ScheduledAlert
import org.json.JSONException
import org.json.JSONObject

/**
 * The persisted half of [AlarmScheduler], in device-protected storage:
 *  - the snapshot: the full (about 60 day) alert list from the last `replaceSchedule`;
 *  - the registry: which alerts are currently registered with AlarmManager, and for when.
 *
 * AlarmManager cannot list its alarms, so the registry is how the scheduler knows what to cancel
 * and how many are registered. [namePrefix] lets tests use separate files.
 */
class ScheduleStore(context: Context, namePrefix: String = "") {
    private val snapshotFile = DeviceStorage.file(context, "${namePrefix}snapshot.json")
    private val registryFile = DeviceStorage.file(context, "${namePrefix}registered.json")

    fun loadSnapshot(): List<ScheduledAlert> =
        if (snapshotFile.exists()) {
            AlertCodec.listFromJsonString(snapshotFile.readText(Charsets.UTF_8))
                .sortedBy { it.fireAtEpochMs }
        } else {
            emptyList()
        }

    fun saveSnapshot(alerts: List<ScheduledAlert>): Boolean =
        DeviceStorage.writeAtomically(snapshotFile, AlertCodec.listToJsonString(alerts))

    /** Alert id to the instant it was registered for. */
    fun loadRegistry(): MutableMap<String, Long> {
        val result = LinkedHashMap<String, Long>()
        if (!registryFile.exists()) return result
        try {
            val json = JSONObject(registryFile.readText(Charsets.UTF_8))
            for (key in json.keys()) result[key] = json.getLong(key)
        } catch (e: JSONException) {
            result.clear()
        }
        return result
    }

    fun saveRegistry(registry: Map<String, Long>): Boolean {
        val json = JSONObject()
        for ((id, at) in registry) json.put(id, at)
        return DeviceStorage.writeAtomically(registryFile, json.toString())
    }

    fun clear() {
        snapshotFile.delete()
        registryFile.delete()
    }
}
