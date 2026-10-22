package org.deenapp.mobile

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import org.deenapp.mobile.generated.AlertKind
import org.deenapp.mobile.generated.PendingSummary
import org.deenapp.mobile.generated.ScheduledAlert

/**
 * Plan R-A2 / spike S7: prayer-time alerts use `setAlarmClock`, reminders use
 * `setExactAndAllowWhileIdle`. If the status-bar alarm icon turns out to be unacceptable, set this
 * to false and every alert uses `setExactAndAllowWhileIdle`. This is the only place the choice is
 * made.
 */
const val PRAYER_ALERTS_USE_ALARM_CLOCK = true

/**
 * Registers alerts with [AlarmManager].
 *
 * The planner hands over a snapshot of about 60 days. It is persisted (device-protected storage),
 * and only the next [WINDOW_DAYS] days are registered with the system, so the registered count
 * stays far below any per-app alarm limit. [topUp] registers the days that came into range; it
 * runs each time an alarm fires and on every system event.
 *
 * Without the exact-alarm permission every alarm is registered inexactly
 * (`setAndAllowWhileIdle`) and the alarm intent carries `inexact=true` so the journal records
 * `exact_alarm_denied`. The system, not the alert's `preciseAllowed` field, is the authority:
 * `canScheduleExactAlarms()` is read on every pass, so a permission granted since the planner ran
 * is used immediately.
 */
class AlarmScheduler(
    context: Context,
    private val clock: Clock = Clock.SYSTEM,
    storePrefix: String = "",
) {
    private val appContext: Context = context.applicationContext ?: context
    private val alarmManager: AlarmManager = appContext.getSystemService(AlarmManager::class.java)
    private val store = ScheduleStore(appContext, storePrefix)

    /** Result of a registration pass. */
    data class Report(
        /** Alarms registered with the system after the pass (the 14-day window). */
        val registered: Int,
        /** Alarms registered in this pass without exact timing. */
        val registeredInexact: Int,
        /** False when the snapshot could not be written to disk. */
        val snapshotSaved: Boolean,
    )

    fun canScheduleExact(): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.S || alarmManager.canScheduleExactAlarms()

    /** Stores [alerts] as the new snapshot and registers its first [WINDOW_DAYS] days. */
    fun replaceSnapshot(alerts: List<ScheduledAlert>): Report = synchronized(LOCK) {
        val cleaned = alerts
            .filter { it.alertId.isNotEmpty() }
            .associateBy { it.alertId }
            .values
            .sortedBy { it.fireAtEpochMs }
        val now = clock.nowMs()
        cancelRegisteredLocked(now, store.loadSnapshot())
        val saved = store.saveSnapshot(cleaned)
        store.saveRegistry(emptyMap())
        fillWindowLocked(cleaned, LinkedHashMap(), now, saved)
    }

    /**
     * Cancels and registers again everything in the window. Used after boot, clock, time zone,
     * package and permission changes, when registered alarms may be gone or may need a different
     * exactness.
     */
    fun reregisterAll(): Report = synchronized(LOCK) {
        val now = clock.nowMs()
        val snapshot = store.loadSnapshot()
        cancelRegisteredLocked(now, snapshot)
        store.saveRegistry(emptyMap())
        fillWindowLocked(snapshot, LinkedHashMap(), now, true)
    }

    /** Registers the snapshot alerts that came into the window and forgets alarms that are past. */
    fun topUp(): Report = synchronized(LOCK) {
        val now = clock.nowMs()
        fillWindowLocked(store.loadSnapshot(), store.loadRegistry(), now, true)
    }

    /** Registers a single alert that is not part of the snapshot (the test alert). */
    fun scheduleOneOff(alert: ScheduledAlert): Boolean = synchronized(LOCK) {
        register(alert, canScheduleExact())
    }

    /** True when an alarm for [alertId] is registered with the system (used by tests). */
    fun isRegistered(alertId: String): Boolean = existingPending(alertId) != null

    fun summary(): PendingSummary = synchronized(LOCK) {
        val now = clock.nowMs()
        val snapshot = store.loadSnapshot()
        val registry = store.loadRegistry()
        PendingSummary(
            registeredCount = registry.values.count { it > now }.toLong(),
            snapshotCount = snapshot.size.toLong(),
            nextAlerts = snapshot.filter { it.fireAtEpochMs > now }.take(NEXT_ALERTS),
            runsUntilEpochMs = snapshot.lastOrNull()?.fireAtEpochMs,
        )
    }

    /** Deletes the snapshot and cancels every registered alarm ("delete all my data"). */
    fun clearAll() = synchronized(LOCK) {
        val now = clock.nowMs()
        cancelRegisteredLocked(now, store.loadSnapshot())
        store.clear()
    }

    private fun fillWindowLocked(
        snapshot: List<ScheduledAlert>,
        registry: MutableMap<String, Long>,
        now: Long,
        snapshotSaved: Boolean,
    ): Report {
        registry.values.removeAll { it <= now }
        val windowEnd = now + WINDOW_DAYS * DAY_MS
        val exactAllowed = canScheduleExact()
        var inexact = 0
        for (alert in snapshot) {
            val at = alert.fireAtEpochMs
            if (at <= now || at > windowEnd || registry.containsKey(alert.alertId)) continue
            if (register(alert, exactAllowed)) {
                registry[alert.alertId] = at
                if (!exactAllowed) inexact++
            }
        }
        store.saveRegistry(registry)
        return Report(registry.size, inexact, snapshotSaved)
    }

    /** Cancels every alarm that may be registered: the registry plus the snapshot's window. */
    private fun cancelRegisteredLocked(now: Long, snapshot: List<ScheduledAlert>) {
        val ids = LinkedHashSet<String>(store.loadRegistry().keys)
        val earliest = now - DAY_MS
        val latest = now + WINDOW_DAYS * DAY_MS
        for (alert in snapshot) {
            if (alert.fireAtEpochMs in earliest..latest) ids.add(alert.alertId)
        }
        for (id in ids) cancelAlarm(id)
    }

    private fun register(alert: ScheduledAlert, exactAllowed: Boolean): Boolean {
        val at = alert.fireAtEpochMs
        if (!exactAllowed) return registerInexact(alert)
        val pending = createPending(alert, inexact = false)
        return try {
            if (PRAYER_ALERTS_USE_ALARM_CLOCK && alert.kind == AlertKind.PRAYER) {
                alarmManager.setAlarmClock(AlarmManager.AlarmClockInfo(at, showAppIntent()), pending)
            } else {
                alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pending)
            }
            true
        } catch (e: SecurityException) {
            // The permission was revoked between the check and the call.
            Log.w(TAG, "exact alarm refused, registering inexactly")
            registerInexact(alert)
        }
    }

    private fun registerInexact(alert: ScheduledAlert): Boolean = try {
        alarmManager.setAndAllowWhileIdle(
            AlarmManager.RTC_WAKEUP,
            alert.fireAtEpochMs,
            createPending(alert, inexact = true),
        )
        true
    } catch (e: SecurityException) {
        Log.w(TAG, "alarm registration refused")
        false
    }

    private fun cancelAlarm(alertId: String) {
        val pending = existingPending(alertId) ?: return
        alarmManager.cancel(pending)
        pending.cancel()
    }

    private fun createPending(alert: ScheduledAlert, inexact: Boolean): PendingIntent =
        PendingIntent.getBroadcast(
            appContext,
            0,
            AlarmReceiver.alarmIntent(appContext, alert, inexact),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

    /** The existing PendingIntent for [alertId], or null when none is registered. */
    private fun existingPending(alertId: String): PendingIntent? =
        PendingIntent.getBroadcast(
            appContext,
            0,
            AlarmReceiver.probeIntent(appContext, alertId),
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE,
        )

    /** What the status-bar alarm icon opens (only used by `setAlarmClock`). */
    private fun showAppIntent(): PendingIntent = PendingIntent.getActivity(
        appContext,
        0,
        Intent(appContext, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

    companion object {
        /** How many days of the snapshot are registered with the system at any time. */
        const val WINDOW_DAYS = 14L
        const val DAY_MS = 24L * 60L * 60L * 1000L
        private const val NEXT_ALERTS = 5
        private const val TAG = "AlarmScheduler"
        private val LOCK = Any()
    }
}
