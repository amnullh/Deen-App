import '../entities/enums.dart';
import 'permission_gateways.dart';

/// A feature that does not work (or works less well) because of a refused
/// permission. Setup lists these in plain words and never blocks on them.
enum DegradedFeature {
  /// Notifications refused: alerts will not appear.
  alerts,

  /// Exact alarms refused (Android): alerts arrive a few minutes late.
  exactTiming,

  /// Location refused: the saved city is used and is not updated by the phone.
  automaticLocation,
}

/// The state of every permission the app asks for.
class PermissionReport {
  const PermissionReport({
    this.notifications,
    this.exactAlarm,
    this.exactAlarmApplicable = false,
    this.locationRefused = false,
  });

  /// Null means the question was never asked or answered.
  final PermissionOutcome? notifications;
  final PermissionOutcome? exactAlarm;

  /// True on Android, where exact alarms are a permission.
  final bool exactAlarmApplicable;
  final bool locationRefused;

  /// Features that will not work, in the order they matter.
  ///
  /// A permission that was skipped without an answer counts as not granted:
  /// from the user's point of view it is the same.
  List<DegradedFeature> get degraded => [
    if (!(notifications?.isSatisfied ?? false)) DegradedFeature.alerts,
    if (exactAlarmApplicable && !(exactAlarm?.isSatisfied ?? false))
      DegradedFeature.exactTiming,
    if (locationRefused) DegradedFeature.automaticLocation,
  ];

  /// Setup can always be finished. Refusals only change what the app tells the
  /// user afterwards (FR-011).
  bool get canFinishSetup => true;
}

/// Maps an outcome to what is stored in the global settings.
PermissionState storedStateFor(PermissionOutcome? outcome) {
  switch (outcome) {
    case PermissionOutcome.granted:
      return PermissionState.granted;
    case PermissionOutcome.denied:
    case PermissionOutcome.permanentlyDenied:
      return PermissionState.denied;
    case PermissionOutcome.notApplicable:
    case null:
      return PermissionState.unknown;
  }
}
