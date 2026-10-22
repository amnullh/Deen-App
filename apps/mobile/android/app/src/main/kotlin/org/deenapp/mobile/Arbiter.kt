package org.deenapp.mobile

import org.deenapp.mobile.generated.AlertKind
import org.deenapp.mobile.generated.JournalEntry
import org.deenapp.mobile.generated.JournalState
import java.time.DateTimeException
import java.time.LocalDate

/**
 * The alert arbiter: at most one `played` per alert ID (FR-005). Same rule as the Dart arbiter in
 * `packages/schedule_planner`; both are tested against one shared vector file.
 *
 * The ledger is the journal. A second request for an ID that already has a `played` entry is
 * refused; every other state (fired, acknowledged, suppressed, failed) leaves the ID playable,
 * because a failed or suppressed attempt did not produce an Azaan.
 */
object Arbiter {
    enum class Verdict { PLAY, ALREADY_PLAYED }

    fun decide(alertId: String, ledger: Iterable<JournalEntry>): Verdict =
        if (ledger.any { it.alertId == alertId && it.state == JournalState.PLAYED }) {
            Verdict.ALREADY_PLAYED
        } else {
            Verdict.PLAY
        }

    /** The IDs that already have a `played` entry. */
    fun playedIds(ledger: Iterable<JournalEntry>): Set<String> =
        ledger.filter { it.state == JournalState.PLAYED }.map { it.alertId }.toSet()
}

/** A planner alert ID split into its parts. */
data class ParsedAlertId(
    val kind: AlertKind,
    /** `fajr`, `dhuhr`, `asr`, `maghrib` or `isha`; null for suhoor, adhkar and renewal. */
    val prayer: String?,
    /** Local date `YYYY-MM-DD`. */
    val localDate: String,
)

/**
 * Alert ID rules from data-model.md: `{prayer}:{localDate}`, `{prayer}:{localDate}:pre`,
 * `suhoor:{localDate}`, `adhkar-morning:{localDate}`, `adhkar-evening:{localDate}` and
 * `renewal:{localDate}`. IDs created natively for the test alert start with `test:`.
 */
object AlertIds {
    private const val DATE = "\\d{4}-\\d{2}-\\d{2}"
    private val PRAYERS = listOf("fajr", "dhuhr", "asr", "maghrib", "isha")
    private val PRAYER_RE = Regex("^(${PRAYERS.joinToString("|")}):($DATE)$")
    private val PRE_RE = Regex("^(${PRAYERS.joinToString("|")}):($DATE):pre$")
    private val DAILY_RE = Regex("^(suhoor|adhkar-morning|adhkar-evening|renewal):($DATE)$")

    const val TEST_PREFIX = "test:"

    fun prayer(prayer: String, localDate: String) = "$prayer:$localDate"
    fun pre(prayer: String, localDate: String) = "$prayer:$localDate:pre"
    fun suhoor(localDate: String) = "suhoor:$localDate"
    fun adhkarMorning(localDate: String) = "adhkar-morning:$localDate"
    fun adhkarEvening(localDate: String) = "adhkar-evening:$localDate"
    fun renewal(localDate: String) = "renewal:$localDate"

    fun isTest(alertId: String) = alertId.startsWith(TEST_PREFIX)

    /** Returns null when [alertId] does not follow the planner's rules or its date is not a real date. */
    fun parse(alertId: String): ParsedAlertId? {
        val parsed = parseShape(alertId) ?: return null
        return if (isRealDate(parsed.localDate)) parsed else null
    }

    private fun isRealDate(date: String): Boolean =
        try {
            LocalDate.parse(date)
            true
        } catch (e: DateTimeException) {
            false
        }

    private fun parseShape(alertId: String): ParsedAlertId? {
        PRAYER_RE.matchEntire(alertId)?.let {
            return ParsedAlertId(AlertKind.PRAYER, it.groupValues[1], it.groupValues[2])
        }
        PRE_RE.matchEntire(alertId)?.let {
            return ParsedAlertId(AlertKind.PRE_REMINDER, it.groupValues[1], it.groupValues[2])
        }
        DAILY_RE.matchEntire(alertId)?.let {
            val kind = when (it.groupValues[1]) {
                "suhoor" -> AlertKind.SUHOOR
                "renewal" -> AlertKind.RENEWAL
                else -> AlertKind.ADHKAR_REMINDER
            }
            return ParsedAlertId(kind, null, it.groupValues[2])
        }
        return null
    }

    fun isValid(alertId: String) = parse(alertId) != null
}
