package org.deenapp.mobile

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.deenapp.mobile.generated.AlertKind
import org.deenapp.mobile.generated.JournalEntry
import org.deenapp.mobile.generated.JournalState
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Runs the Kotlin [Arbiter] and [AlertIds] against vector files, so the Kotlin and Dart arbiters
 * cannot diverge (plan: shared vectors).
 *
 * Two sources: a small local file (`arbiter_cases_local.json`) and the shared vectors
 * (`arbiter.json`, `alert_ids.json`) from `packages/schedule_planner/test_vectors/`, which Gradle
 * adds to the test assets. Their formats are documented in that folder's README.md.
 */
@RunWith(AndroidJUnit4::class)
class ArbiterVectorsTest {
    private val assets get() = InstrumentationRegistry.getInstrumentation().context.assets

    @Test
    fun localArbiterCases() = checkArbiterCases(readJson(LOCAL_FILE).getJSONArray("arbiter"), LOCAL_FILE)

    @Test
    fun localAlertIdCases() = checkAlertIdCases(readJson(LOCAL_FILE).getJSONArray("alertIds"), LOCAL_FILE)

    /**
     * `arbiter.json` (schema `arbiter/1`) from the planner package: `cases` (a fixed ledger and one
     * decision) and `sequences` (steps replayed against one ledger). The Kotlin arbiter only
     * answers "has this alert already played?"; whether a call suppresses the Azaan is decided by
     * the playback service, so the expected `skipSuppressed` and `play` both mean "not already
     * played" here.
     */
    @Test
    fun sharedArbiterVectors() {
        val json = readJson(SHARED_ARBITER)
        assertEquals("arbiter/1", json.getString("schema"))
        val cases = json.getJSONArray("cases")
        for (i in 0 until cases.length()) {
            val case = cases.getJSONObject(i)
            val ledger = playedLedger(case.getJSONArray("ledger"))
            val verdict = Arbiter.decide(case.getString("alertId"), ledger)
            assertEquals(
                "$SHARED_ARBITER: ${case.optString("name")}",
                case.getString("expected") == "skipAlreadyPlayed",
                verdict == Arbiter.Verdict.ALREADY_PLAYED,
            )
        }
        val sequences = json.getJSONArray("sequences")
        for (i in 0 until sequences.length()) {
            val sequence = sequences.getJSONObject(i)
            val ledger = mutableListOf<JournalEntry>()
            val steps = sequence.getJSONArray("steps")
            for (j in 0 until steps.length()) {
                val step = steps.getJSONObject(j)
                val alertId = step.getString("alertId")
                val verdict = Arbiter.decide(alertId, ledger)
                assertEquals(
                    "$SHARED_ARBITER: ${sequence.optString("name")}, step ${j + 1}",
                    step.getString("expected") == "skipAlreadyPlayed",
                    verdict == Arbiter.Verdict.ALREADY_PLAYED,
                )
                if (step.optBoolean("markPlayed")) ledger.add(playedEntry(alertId))
            }
        }
    }

    /** `alert_ids.json` (schema `alert_ids/1`): the Kotlin ID builders and parser against the Dart ones. */
    @Test
    fun sharedAlertIdVectors() {
        val json = readJson(SHARED_ALERT_IDS)
        assertEquals("alert_ids/1", json.getString("schema"))
        val prayers = setOf("fajr", "dhuhr", "asr", "maghrib", "isha")

        val build = json.getJSONArray("build")
        for (i in 0 until build.length()) {
            val case = build.getJSONObject(i)
            if (case.isNull("expected")) continue // Kotlin builders take already valid input
            val kind = case.getString("kind")
            val date = case.getString("localDate")
            val made = when {
                kind in prayers && case.getBoolean("pre") -> AlertIds.pre(kind, date)
                kind in prayers -> AlertIds.prayer(kind, date)
                kind == "suhoor" -> AlertIds.suhoor(date)
                kind == "adhkar-morning" -> AlertIds.adhkarMorning(date)
                kind == "adhkar-evening" -> AlertIds.adhkarEvening(date)
                kind == "renewal" -> AlertIds.renewal(date)
                else -> throw AssertionError("unknown kind '$kind' in $SHARED_ALERT_IDS")
            }
            assertEquals("$SHARED_ALERT_IDS: build $kind $date", case.getString("expected"), made)
        }

        val parse = json.getJSONArray("parse")
        for (i in 0 until parse.length()) {
            val case = parse.getJSONObject(i)
            val id = case.getString("id")
            val parsed = AlertIds.parse(id)
            if (case.isNull("expected")) {
                assertEquals("$SHARED_ALERT_IDS: '$id' must be rejected", null, parsed)
                continue
            }
            val expected = case.getJSONObject("expected")
            assertNotNull("$SHARED_ALERT_IDS: '$id' must parse", parsed)
            val kind = expected.getString("kind")
            val expectedKind = when {
                kind in prayers && expected.getBoolean("pre") -> AlertKind.PRE_REMINDER
                kind in prayers -> AlertKind.PRAYER
                kind == "suhoor" -> AlertKind.SUHOOR
                kind == "renewal" -> AlertKind.RENEWAL
                else -> AlertKind.ADHKAR_REMINDER
            }
            assertEquals("$SHARED_ALERT_IDS: kind of '$id'", expectedKind, parsed!!.kind)
            assertEquals("$SHARED_ALERT_IDS: date of '$id'", expected.getString("localDate"), parsed.localDate)
            if (kind in prayers) assertEquals("$SHARED_ALERT_IDS: prayer of '$id'", kind, parsed.prayer)
        }
    }

    private fun playedEntry(alertId: String) =
        JournalEntry(alertId = alertId, plannedAtEpochMs = 0L, state = JournalState.PLAYED)

    private fun playedLedger(ids: JSONArray): List<JournalEntry> =
        (0 until ids.length()).map { playedEntry(ids.getString(it)) }

    private fun checkArbiterCases(cases: JSONArray, source: String) {
        for (i in 0 until cases.length()) {
            val case = cases.getJSONObject(i)
            val ledger = case.getJSONArray("ledger").let { array ->
                (0 until array.length()).map { index ->
                    val row = array.getJSONObject(index)
                    JournalEntry(
                        alertId = row.getString("alertId"),
                        plannedAtEpochMs = 0L,
                        state = JournalState.valueOf(row.getString("state").uppercase()),
                    )
                }
            }
            val verdict = Arbiter.decide(case.getString("alertId"), ledger)
            val expected = if (case.getBoolean("expectPlay")) Arbiter.Verdict.PLAY else Arbiter.Verdict.ALREADY_PLAYED
            assertEquals("$source: ${case.optString("name")}", expected, verdict)
        }
    }

    private fun checkAlertIdCases(cases: JSONArray, source: String) {
        for (i in 0 until cases.length()) {
            val case = cases.getJSONObject(i)
            val id = case.getString("id")
            val parsed = AlertIds.parse(id)
            if (!case.getBoolean("valid")) {
                assertEquals("$source: '$id' must be rejected", null, parsed)
                continue
            }
            assertNotNull("$source: '$id' must parse", parsed)
            assertEquals("$source: kind of '$id'", kindFromName(case.getString("kind")), parsed!!.kind)
            assertEquals("$source: date of '$id'", case.getString("date"), parsed.localDate)
            assertEquals("$source: prayer of '$id'", case.optString("prayer", "").ifEmpty { null }, parsed.prayer)
        }
    }

    private fun kindFromName(name: String): AlertKind = when (name) {
        "prayer" -> AlertKind.PRAYER
        "preReminder" -> AlertKind.PRE_REMINDER
        "suhoor" -> AlertKind.SUHOOR
        "adhkarReminder" -> AlertKind.ADHKAR_REMINDER
        "renewal" -> AlertKind.RENEWAL
        else -> throw AssertionError("unknown alert kind '$name' in the vectors")
    }

    private fun readJson(name: String): JSONObject =
        JSONObject(assets.open(name).bufferedReader(Charsets.UTF_8).use { it.readText() })

    private companion object {
        const val LOCAL_FILE = "arbiter_cases_local.json"
        const val SHARED_ARBITER = "arbiter.json"
        const val SHARED_ALERT_IDS = "alert_ids.json"
    }
}
