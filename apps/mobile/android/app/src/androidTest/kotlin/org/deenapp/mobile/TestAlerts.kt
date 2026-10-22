package org.deenapp.mobile

import org.deenapp.mobile.generated.AlertKind
import org.deenapp.mobile.generated.AudioOutputDto
import org.deenapp.mobile.generated.DeliveryType
import org.deenapp.mobile.generated.ScheduledAlert
import org.deenapp.mobile.generated.VolumeChoiceDto
import java.util.UUID

/** Builders shared by the instrumented tests. */
object TestAlerts {
    /** An id that cannot collide with real alerts or with other test runs. */
    fun uniqueId(prefix: String): String = "$prefix:${UUID.randomUUID()}"

    fun alert(
        id: String,
        fireAtEpochMs: Long,
        kind: AlertKind = AlertKind.SUHOOR,
        delivery: DeliveryType = DeliveryType.SILENT,
        audioRef: String? = null,
        loudMode: Boolean = false,
        volumeChoice: VolumeChoiceDto = VolumeChoiceDto.KEEP_CURRENT,
        audioOutput: AudioOutputDto? = null,
    ) = ScheduledAlert(
        alertId = id,
        fireAtEpochMs = fireAtEpochMs,
        kind = kind,
        delivery = delivery,
        audioRef = audioRef,
        title = "Test",
        body = "Test body",
        stopLabel = "Stop",
        loudMode = loudMode,
        volumeChoice = volumeChoice,
        preciseAllowed = true,
        audioOutput = audioOutput,
    )

    /** Polls [condition] until it holds or [timeoutMs] passes. */
    fun waitFor(timeoutMs: Long, condition: () -> Boolean): Boolean {
        val deadline = System.currentTimeMillis() + timeoutMs
        while (System.currentTimeMillis() < deadline) {
            if (condition()) return true
            Thread.sleep(100)
        }
        return condition()
    }
}
