import '../../platform/alert_scheduler.dart';
import 'alert_log_entry.dart';

/// Something the user can fix to make alerts more reliable.
enum ReliabilityProblem {
  notificationsOff,

  /// Android: exact alarms refused, so alerts may be minutes late.
  exactAlarmOff,

  /// Android: battery optimization may stop alerts on some phones.
  batteryRestricted,

  /// iPhone: sound is off in notification settings.
  soundOff,

  /// Nothing is scheduled although setup is done, or the schedule has ended.
  nothingScheduled,
}

/// One upcoming alert with what the log knows about it.
class UpcomingAlert {
  const UpcomingAlert({required this.alert, this.cause});

  final ScheduledAlert alert;

  /// [AlertCause.quietHours] or [AlertCause.exactAlarmDenied] from planning.
  final AlertCause? cause;

  bool get silencedByQuietHours => cause == AlertCause.quietHours;

  /// True when the alert is registered inexactly (timing may be late).
  bool get inexact => !alert.preciseAllowed;
}

/// Everything the Reliability check screen shows (spec Story 3, scenario 11).
class ReliabilitySnapshot {
  const ReliabilitySnapshot({
    required this.permissions,
    required this.registeredCount,
    required this.next,
    required this.runsUntil,
    required this.lastResult,
    required this.now,
  });

  final AlertPermissions permissions;
  final int registeredCount;

  /// The next five alerts, soonest first.
  final List<UpcomingAlert> next;

  /// Where the schedule ends, or null when nothing is scheduled.
  final DateTime? runsUntil;
  final AlertLogEntry? lastResult;
  final DateTime now;

  /// Problems in the order the screen lists them. Empty means all good.
  List<ReliabilityProblem> get problems {
    if (permissions.platform == AlertPlatform.unsupported) return const [];
    final android = permissions.platform == AlertPlatform.android;
    return [
      if (!permissions.notificationsGranted)
        ReliabilityProblem.notificationsOff,
      if (android && !permissions.exactAlarmGranted)
        ReliabilityProblem.exactAlarmOff,
      if (android && !permissions.batteryOptimizationIgnored)
        ReliabilityProblem.batteryRestricted,
      if (!android && !permissions.soundEnabled) ReliabilityProblem.soundOff,
      if (next.isEmpty || (runsUntil != null && !runsUntil!.isAfter(now)))
        ReliabilityProblem.nothingScheduled,
    ];
  }

  bool get allGood => problems.isEmpty;

  /// Builds a snapshot from the platform's summary and the log's flags.
  factory ReliabilitySnapshot.from({
    required AlertPermissions permissions,
    required PendingSummary summary,
    required Map<String, AlertCause?> causes,
    required DateTime? runsUntil,
    required AlertLogEntry? lastResult,
    required DateTime now,
  }) {
    return ReliabilitySnapshot(
      permissions: permissions,
      registeredCount: summary.registeredCount,
      next: [
        for (final alert in summary.nextAlerts.take(5))
          UpcomingAlert(alert: alert, cause: causes[alert.alertId]),
      ],
      runsUntil:
          runsUntil ??
          (summary.runsUntilEpochMs == null
              ? null
              : DateTime.fromMillisecondsSinceEpoch(
                  summary.runsUntilEpochMs!,
                  isUtc: true,
                )),
      lastResult: lastResult,
      now: now,
    );
  }
}
