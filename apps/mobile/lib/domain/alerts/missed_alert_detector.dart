import '../../platform/alert_scheduler.dart';
import '../entities/enums.dart';
import 'alert_log_entry.dart';

/// What [MissedAlertDetector.detect] decided.
class DetectionResult {
  const DetectionResult({
    required this.updates,
    required this.newlyMissed,
    this.scheduleEnded,
  });

  /// Rows to save: the judged rows, plus [scheduleEnded] when present.
  final List<AlertLogEntry> updates;

  /// Rows the user should be told about: missed or possibly missed. Alerts
  /// silenced by quiet hours are not here.
  final List<AlertLogEntry> newlyMissed;

  /// Present when the schedule ran out before the user opened the app. Its id
  /// is `schedule_ended:<end instant>`, so saving it twice is harmless.
  final AlertLogEntry? scheduleEnded;
}

/// Decides, at app open, which planned alerts did not happen and why
/// (spec Story 3, scenario 12; data-model state machine).
///
/// It is pure: callers pass the rows, the current permissions and the time.
class MissedAlertDetector {
  const MissedAlertDetector({
    this.grace = const Duration(minutes: 5),
    this.inexactGrace = const Duration(minutes: 30),
  });

  /// How long after its time an alert may still be on its way (an Azaan plays
  /// for a few minutes and the journal entry may not be imported yet).
  final Duration grace;

  /// Inexact alarms are allowed to run late by Android, so they get longer.
  final Duration inexactGrace;

  /// [pastPlanned] are the rows still `planned` whose time has passed.
  ///
  /// On Android an alert with no journal entry is `missed`. On iOS delivery
  /// cannot be confirmed (plan D-10), so the same case is `possiblyMissed`.
  /// An alert silenced by quiet hours is `suppressed` on both, never missed.
  DetectionResult detect({
    required DateTime now,
    required List<AlertLogEntry> pastPlanned,
    required AlertPermissions permissions,
    DateTime? scheduleRunsUntil,
  }) {
    final notConfirmable = permissions.platform == AlertPlatform.ios;
    final missedState = notConfirmable
        ? AlertLogState.possiblyMissed
        : AlertLogState.missed;

    final updates = <AlertLogEntry>[];
    final newlyMissed = <AlertLogEntry>[];
    for (final row in pastPlanned) {
      if (row.state != AlertLogState.planned) continue;
      final inexact = row.cause == AlertCause.exactAlarmDenied;
      final wait = inexact ? inexactGrace : grace;
      if (now.isBefore(row.plannedFireAt.add(wait))) continue;

      if (row.cause == AlertCause.quietHours) {
        updates.add(row.copyWith(state: AlertLogState.suppressed));
        continue;
      }
      final judged = row.copyWith(
        state: missedState,
        cause: _likelyCause(row, permissions),
      );
      updates.add(judged);
      newlyMissed.add(judged);
    }

    final ended = _scheduleEnded(now, scheduleRunsUntil, missedState);
    if (ended != null) {
      updates.add(ended);
      newlyMissed.add(ended);
    }
    return DetectionResult(
      updates: updates,
      newlyMissed: newlyMissed,
      scheduleEnded: ended,
    );
  }

  AlertLogEntry? _scheduleEnded(
    DateTime now,
    DateTime? runsUntil,
    AlertLogState missedState,
  ) {
    if (runsUntil == null || now.isBefore(runsUntil.add(grace))) return null;
    return AlertLogEntry(
      alertId: 'schedule_ended:${runsUntil.toUtc().toIso8601String()}',
      plannedFireAt: runsUntil,
      state: missedState,
      source: AlertLogSource.inApp,
      cause: AlertCause.scheduleEnded,
    );
  }

  /// The most likely reason an alert left no trace, most certain first.
  AlertCause _likelyCause(AlertLogEntry row, AlertPermissions permissions) {
    if (!permissions.notificationsGranted) return AlertCause.notificationDenied;
    if (permissions.platform == AlertPlatform.android) {
      if (row.cause == AlertCause.exactAlarmDenied ||
          !permissions.exactAlarmGranted) {
        return AlertCause.exactAlarmDenied;
      }
      if (!permissions.batteryOptimizationIgnored) {
        return AlertCause.batteryRestricted;
      }
    }
    return AlertCause.unknown;
  }
}
