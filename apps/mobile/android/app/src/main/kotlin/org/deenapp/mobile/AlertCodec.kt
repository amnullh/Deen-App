package org.deenapp.mobile

import org.deenapp.mobile.generated.AlertKind
import org.deenapp.mobile.generated.AudioOutputDto
import org.deenapp.mobile.generated.DeliveryType
import org.deenapp.mobile.generated.ScheduledAlert
import org.deenapp.mobile.generated.VolumeChoiceDto
import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject

/**
 * JSON form of [ScheduledAlert] used for the on-disk snapshot and for the extras of alarm
 * intents. Enums are stored by their stable `raw` value. Malformed input yields null instead
 * of an exception, because receivers must never crash.
 */
object AlertCodec {
    fun toJson(alert: ScheduledAlert): JSONObject = JSONObject()
        .put("id", alert.alertId)
        .put("at", alert.fireAtEpochMs)
        .put("kind", alert.kind.raw)
        .put("delivery", alert.delivery.raw)
        .put("audio", alert.audioRef ?: JSONObject.NULL)
        .put("title", alert.title)
        .put("body", alert.body)
        .put("stop", alert.stopLabel)
        .put("loud", alert.loudMode)
        .put("volume", alert.volumeChoice.raw)
        .put("precise", alert.preciseAllowed)
        .put("output", alert.audioOutput?.raw ?: JSONObject.NULL)

    fun fromJson(json: JSONObject): ScheduledAlert? = try {
        val kind = AlertKind.ofRaw(json.getInt("kind"))
        val delivery = DeliveryType.ofRaw(json.getInt("delivery"))
        val volume = VolumeChoiceDto.ofRaw(json.getInt("volume"))
        if (kind == null || delivery == null || volume == null) {
            null
        } else {
            ScheduledAlert(
                alertId = json.getString("id"),
                fireAtEpochMs = json.getLong("at"),
                kind = kind,
                delivery = delivery,
                audioRef = if (json.isNull("audio")) null else json.getString("audio"),
                title = json.getString("title"),
                body = json.getString("body"),
                stopLabel = json.getString("stop"),
                loudMode = json.getBoolean("loud"),
                volumeChoice = volume,
                preciseAllowed = json.getBoolean("precise"),
                // Absent in snapshots saved before the field existed: null means the speaker.
                audioOutput = if (json.isNull("output")) null else AudioOutputDto.ofRaw(json.getInt("output")),
            )
        }
    } catch (e: JSONException) {
        null
    }

    fun toJsonString(alert: ScheduledAlert): String = toJson(alert).toString()

    fun fromJsonString(text: String?): ScheduledAlert? {
        if (text.isNullOrEmpty()) return null
        return try {
            fromJson(JSONObject(text))
        } catch (e: JSONException) {
            null
        }
    }

    fun listToJsonString(alerts: List<ScheduledAlert>): String {
        val array = JSONArray()
        for (alert in alerts) array.put(toJson(alert))
        return array.toString()
    }

    /** Parses a JSON array, skipping entries that are malformed. */
    fun listFromJsonString(text: String): List<ScheduledAlert> {
        return try {
            val array = JSONArray(text)
            val result = ArrayList<ScheduledAlert>(array.length())
            for (i in 0 until array.length()) {
                val alert = array.optJSONObject(i)?.let { fromJson(it) }
                if (alert != null) result.add(alert)
            }
            result
        } catch (e: JSONException) {
            emptyList()
        }
    }
}
