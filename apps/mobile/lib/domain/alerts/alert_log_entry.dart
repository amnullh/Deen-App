import '../entities/enums.dart';

/// Why an alert did not do what the user asked for (data-model.md, AlertLogEntry).
///
/// [quietHours] is not a failure: the alert was delivered as a silent
/// notification because the user set quiet hours, and the Reliability check
/// lists it as "silenced by quiet hours", never as missed.
enum AlertCause {
  exactAlarmDenied('exact_alarm_denied'),
  notificationDenied('notification_denied'),
  fgsBlocked('fgs_blocked'),
  callInProgress('call_in_progress'),
  quietHours('quiet_hours'),
  silentMode('silent_mode'),
  batteryRestricted('battery_restricted'),
  appNotRun('app_not_run'),
  scheduleEnded('schedule_ended'),
  unknown('unknown');

  const AlertCause(this.wire);

  /// The text stored in the database and written by the native journal.
  final String wire;

  /// Parses a stored or native cause. Native entries may carry a state prefix
  /// (`suppressed:call_in_progress`); the part after the colon is the cause.
  /// Null stays null; text that is not a known cause becomes [unknown].
  static AlertCause? fromWire(String? text) {
    if (text == null || text.isEmpty) return null;
    final cause = text.contains(':') ? text.split(':').last : text;
    for (final value in values) {
      if (value.wire == cause) return value;
    }
    return AlertCause.unknown;
  }
}

/// One row of the alert log: what was planned and what happened.
class AlertLogEntry {
  const AlertLogEntry({
    required this.alertId,
    required this.plannedFireAt,
    required this.state,
    required this.source,
    this.attempt = 0,
    this.firedAt,
    this.cause,
  });

  final String alertId;

  /// Retry counter so a rebuilt alert never overwrites its history.
  final int attempt;

  /// UTC instant.
  final DateTime plannedFireAt;
  final AlertLogState state;
  final AlertLogSource source;

  /// Actual delivery or start time, when the platform recorded one.
  final DateTime? firedAt;
  final AlertCause? cause;

  /// Time between the planned and the actual instant (feeds SC-002).
  Duration? get deviation => firedAt?.difference(plannedFireAt);

  /// Whether the user got, or was knowingly spared, this alert, so nothing
  /// needs reporting.
  bool get isResolved =>
      state != AlertLogState.planned &&
      state != AlertLogState.missed &&
      state != AlertLogState.possiblyMissed;

  AlertLogEntry copyWith({
    DateTime? plannedFireAt,
    AlertLogState? state,
    AlertLogSource? source,
    DateTime? firedAt,
    AlertCause? cause,
    bool clearCause = false,
  }) {
    return AlertLogEntry(
      alertId: alertId,
      attempt: attempt,
      plannedFireAt: plannedFireAt ?? this.plannedFireAt,
      state: state ?? this.state,
      source: source ?? this.source,
      firedAt: firedAt ?? this.firedAt,
      cause: clearCause ? null : (cause ?? this.cause),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AlertLogEntry &&
      other.alertId == alertId &&
      other.attempt == attempt &&
      other.plannedFireAt == plannedFireAt &&
      other.state == state &&
      other.source == source &&
      other.firedAt == firedAt &&
      other.cause == cause;

  @override
  int get hashCode => Object.hash(
    alertId,
    attempt,
    plannedFireAt,
    state,
    source,
    firedAt,
    cause,
  );

  @override
  String toString() =>
      'AlertLogEntry($alertId ${state.name}${cause == null ? '' : ' ${cause!.wire}'})';
}

/// An alert the planner produced, as the log needs to know it: its id, when
/// it should fire, and any known reason it will not be delivered as asked.
class PlannedAlertRecord {
  const PlannedAlertRecord({
    required this.alertId,
    required this.fireAt,
    this.cause,
  });

  final String alertId;
  final DateTime fireAt;

  /// [AlertCause.quietHours] for an alert silenced by quiet hours,
  /// [AlertCause.exactAlarmDenied] for an inexact one, or null.
  final AlertCause? cause;
}
