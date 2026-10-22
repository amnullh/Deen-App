package org.deenapp.mobile

import android.content.Context
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.deenapp.mobile.generated.AlertKind
import org.deenapp.mobile.generated.AudioOutputDto
import org.deenapp.mobile.generated.DeliveryType
import org.deenapp.mobile.generated.JournalEntry
import org.deenapp.mobile.generated.JournalState
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith

/**
 * The alarm path with no Dart code: journal, arbiter, receiver, service start and window top-up.
 * It uses real AlarmManager and the real journal file, but with unique alert ids and, for the
 * scheduler, a separate snapshot/registry file prefix, so it does not disturb a developer's real
 * schedule. Written, not run: there was no Android toolchain where this was authored.
 */
@RunWith(AndroidJUnit4::class)
class AlarmFlowTest {
    private lateinit var context: Context
    private lateinit var scheduler: AlarmScheduler
    private val idsToCancel = mutableListOf<String>()

    @Before
    fun setUp() {
        context = InstrumentationRegistry.getInstrumentation().targetContext
        scheduler = AlarmScheduler(context, Clock.SYSTEM, storePrefix = STORE_PREFIX)
    }

    @After
    fun tearDown() {
        scheduler.clearAll()
        idsToCancel.forEach { Notifications.cancel(context, it) }
        context.stopService(android.content.Intent(context, AzaanPlaybackService::class.java))
    }

    @Test
    fun journalLivesInDeviceProtectedStorage() {
        val protectedDir = context.createDeviceProtectedStorageContext().filesDir.absolutePath
        val file = DeviceStorage.file(context, AlertJournal.DEFAULT_FILE_NAME)
        assertTrue(file.absolutePath.startsWith(protectedDir))
    }

    @Test
    fun clearRemovesOnlyWhatWasRead() {
        val journal = AlertJournal(context, fileName = "journal_test_roundtrip.log")
        journal.clear()
        journal.append(entry("a", JournalState.FIRED))
        journal.append(entry("b", JournalState.PLAYED))

        val first = journal.read(0L)
        assertEquals(listOf("a", "b"), first.map { it.alertId })

        journal.append(entry("c", JournalState.FIRED)) // written after the app's read
        journal.clear()

        assertEquals(listOf("c"), journal.read(0L).map { it.alertId })
        journal.clear()
        assertTrue(journal.read(0L).isEmpty())
    }

    @Test
    fun arbiterRefusesSecondPlayFromTheJournal() {
        val id = TestAlerts.uniqueId("flow-arbiter")
        val journal = AlertJournal(context)
        assertEquals(Arbiter.Verdict.PLAY, Arbiter.decide(id, journal.entriesFor(id)))
        journal.append(entry(id, JournalState.PLAYED))
        assertEquals(Arbiter.Verdict.ALREADY_PLAYED, Arbiter.decide(id, journal.entriesFor(id)))
    }

    @Test
    fun windowKeepsFourteenDaysAndTopsUpFromTheSnapshot() {
        val day = AlarmScheduler.DAY_MS
        var now = FIXED_NOW
        val clock = Clock { now }
        val flowScheduler = AlarmScheduler(context, clock, storePrefix = STORE_PREFIX)
        val runId = TestAlerts.uniqueId("flow-window")
        val alerts = (1..60).map { TestAlerts.alert("$runId:$it", FIXED_NOW + it * day) }

        val report = flowScheduler.replaceSnapshot(alerts)
        assertTrue(report.snapshotSaved)
        assertEquals(14, report.registered)
        assertTrue(flowScheduler.isRegistered("$runId:14"))
        assertFalse(flowScheduler.isRegistered("$runId:15"))
        val summary = flowScheduler.summary()
        assertEquals(60L, summary.snapshotCount)
        assertEquals(14L, summary.registeredCount)
        assertEquals(alerts.last().fireAtEpochMs, summary.runsUntilEpochMs)

        now = FIXED_NOW + 7 * day // seven days later: days 1..7 are past, 15..21 come into range
        val toppedUp = flowScheduler.topUp()
        assertEquals(14, toppedUp.registered)
        assertTrue(flowScheduler.isRegistered("$runId:21"))
        assertFalse(flowScheduler.isRegistered("$runId:22"))

        flowScheduler.clearAll()
        assertFalse(flowScheduler.isRegistered("$runId:21"))
    }

    @Test
    fun replacingTheScheduleCancelsAlarmsThatAreNoLongerPlanned() {
        val runId = TestAlerts.uniqueId("flow-replace")
        val old = TestAlerts.alert("$runId:old", FIXED_NOW + AlarmScheduler.DAY_MS)
        val fresh = TestAlerts.alert("$runId:new", FIXED_NOW + 2 * AlarmScheduler.DAY_MS)
        val clock = Clock { FIXED_NOW }
        val flowScheduler = AlarmScheduler(context, clock, storePrefix = STORE_PREFIX)

        flowScheduler.replaceSnapshot(listOf(old))
        assertTrue(flowScheduler.isRegistered(old.alertId))
        flowScheduler.replaceSnapshot(listOf(fresh))
        assertFalse(flowScheduler.isRegistered(old.alertId))
        assertTrue(flowScheduler.isRegistered(fresh.alertId))
    }

    @Test
    fun receiverJournalsFiredAndFlagsInexactAlarms() {
        val id = TestAlerts.uniqueId("flow-fired")
        idsToCancel.add(id)
        val alert = TestAlerts.alert(id, System.currentTimeMillis(), delivery = DeliveryType.SILENT)

        AlarmReceiver().handle(context, AlarmReceiver.alarmIntent(context, alert, inexact = true), Clock.SYSTEM)

        val fired = AlertJournal(context).entriesFor(id).first { it.state == JournalState.FIRED }
        assertEquals(alert.fireAtEpochMs, fired.plannedAtEpochMs)
        assertEquals(AlarmReceiver.CAUSE_EXACT_ALARM_DENIED, fired.cause)
    }

    @Test
    fun receiverDoesNotPlayAnAlertThatWasAlreadyPlayed() {
        val id = TestAlerts.uniqueId("flow-duplicate")
        idsToCancel.add(id)
        val journal = AlertJournal(context)
        journal.append(entry(id, JournalState.PLAYED))
        val alert = TestAlerts.alert(
            id, System.currentTimeMillis(), kind = AlertKind.PRAYER,
            delivery = DeliveryType.FULL_AZAAN, audioRef = "no-such/recording",
        )

        AlarmReceiver().handle(context, AlarmReceiver.alarmIntent(context, alert, inexact = false), Clock.SYSTEM)

        assertEquals(listOf(JournalState.PLAYED), journal.entriesFor(id).map { it.state })
    }

    @Test
    fun fullAzaanWithoutARecordingFallsBackAndJournalsFailed() {
        val id = TestAlerts.uniqueId("flow-service")
        idsToCancel.add(id)
        val alert = TestAlerts.alert(
            id, System.currentTimeMillis(), kind = AlertKind.PRAYER,
            delivery = DeliveryType.FULL_AZAAN, audioRef = "no-such/recording",
        )

        AlarmReceiver().handle(context, AlarmReceiver.alarmIntent(context, alert, inexact = false), Clock.SYSTEM)

        // Either the service ran and found no recording, or the start was blocked: both end as
        // a journaled failure plus a notification fallback, never as silence without a record.
        val journal = AlertJournal(context)
        assertTrue(
            TestAlerts.waitFor(10_000) { journal.entriesFor(id).any { it.state == JournalState.FAILED } },
        )
        val states = journal.entriesFor(id).map { it.state }
        assertTrue(states.contains(JournalState.FIRED))
        assertFalse(states.contains(JournalState.PLAYED))
    }

    @Test
    fun acknowledgeActionIsJournaled() {
        val id = TestAlerts.uniqueId("flow-ack")
        idsToCancel.add(id)
        val alert = TestAlerts.alert(id, System.currentTimeMillis())

        AlarmReceiver().handle(context, AlarmReceiver.acknowledgeIntent(context, alert), Clock.SYSTEM)

        val states = AlertJournal(context).entriesFor(id).map { it.state }
        assertEquals(listOf(JournalState.ACKNOWLEDGED), states)
    }

    @Test
    fun alertCodecRoundTrips() {
        val alert = TestAlerts.alert(
            "codec:1", 1_234L, kind = AlertKind.PRAYER, delivery = DeliveryType.FULL_AZAAN,
            audioRef = "voice-1/fajr", loudMode = true, audioOutput = AudioOutputDto.BLUETOOTH,
        )
        assertEquals(alert, AlertCodec.fromJsonString(AlertCodec.toJsonString(alert)))
        assertNull(AlertCodec.fromJsonString("{not json"))
    }

    private fun entry(id: String, state: JournalState) = JournalEntry(
        alertId = id,
        plannedAtEpochMs = 1L,
        firedAtEpochMs = 2L,
        state = state,
    )

    private companion object {
        const val STORE_PREFIX = "test_flow_"

        /** January 2027: far enough ahead that every registered test alarm is in the future. */
        const val FIXED_NOW = 1_800_000_000_000L
    }
}
