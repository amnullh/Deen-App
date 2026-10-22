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
import org.junit.Assume.assumeTrue
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Runs the Kotlin [Arbiter] and [AlertIds] against vector files, so the Kotlin and Dart arbiters
 * cannot diverge (plan: shared vectors).
 *
 * Two sources: a small local file (`arbiter_cases_local.json`) that always runs, and the shared
 * vectors from `packages/schedule_planner/test_vectors/` (workstream W2), which Gradle adds to
 * the test assets. The shared file's exact shape was not known when this was written; the test
 * assumes the shape of the local file and fails with a clear message if the shared file differs.
 */
@RunWith(AndroidJUnit4::class)
class ArbiterVectorsTest {
    private val assets get() = InstrumentationRegistry.getInstrumentation().context.assets

    @Test
    fun localArbiterCases() = checkArbiterCases(readJson(LOCAL_FILE).getJSONArray("arbiter"), LOCAL_FILE)

    @Test
    fun localAlertIdCases() = checkAlertIdCases(readJson(LOCAL_FILE).getJSONArray("alertIds"), LOCAL_FILE)

    @Test
    fun sharedVectors() {
        val name = assets.list("")?.firstOrNull {
            it.endsWith(".json") && it.contains("arbiter") && it != LOCAL_FILE
        }
        assumeTrue("shared arbiter vectors are not in packages/schedule_planner/test_vectors yet", name != null)
        val json = readJson(name!!)
        val arbiter = json.optJSONArray("arbiter")
            ?: throw AssertionError("$name has no \"arbiter\" array; reconcile it with arbiter_cases_local.json")
        checkArbiterCases(arbiter, name)
        json.optJSONArray("alertIds")?.let { checkAlertIdCases(it, name) }
    }

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
    }
}
