import '../../platform/alert_scheduler.dart';
import '../adhkar/adhkar_reminder.dart';
import '../entities/settings.dart';
import 'alert_log_entry.dart';

/// Everything needed to plan the alerts. Nothing here is read from the system:
/// [now] is injected, so planning is repeatable.
class PlanRequest {
  const PlanRequest({
    required this.settings,
    required this.location,
    required this.preferences,
    required this.global,
    required this.permissions,
    required this.now,
    this.adhkarReminders = const [],
  });

  final PrayerSettings settings;
  final AppLocation location;
  final List<AlertPreference> preferences;
  final GlobalAlertSettings global;
  final AlertPermissions permissions;
  final DateTime now;
  final List<AdhkarReminder> adhkarReminders;

  AlertPlatform get platform => permissions.platform;
}

/// The result of planning: what to hand to the platform, what to remember in
/// the log, and when the schedule ends.
class AlertPlan {
  const AlertPlan({
    required this.alerts,
    required this.records,
    required this.runsUntil,
  });

  /// Localized alerts for [AlertScheduler.replaceSchedule].
  final List<ScheduledAlert> alerts;

  /// The same alerts as the alert log needs them.
  final List<PlannedAlertRecord> records;

  /// The end of the last alert, or null when nothing was planned.
  final DateTime? runsUntil;
}

/// Turns settings into an [AlertPlan]. The real one wraps the pure-Dart
/// `schedule_planner` package; tests use a fake.
abstract interface class PlanBuilder {
  Future<AlertPlan> build(PlanRequest request);
}
