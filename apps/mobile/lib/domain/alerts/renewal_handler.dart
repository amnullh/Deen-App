import 'schedule_coordinator.dart';

/// The "open the app" notice (spec Story 3, scenario 10a): about a week before
/// the schedule ends on Android, or as the last pending request on iPhone.
/// Tapping it opens the app, and the app rebuilds the schedule so alerts run
/// on. The notice's localized text is `alertNotifRenewalTitle` and
/// `alertNotifRenewalBody`, produced by the plan builder.
class RenewalHandler {
  const RenewalHandler(this._coordinator);

  final ScheduleCoordinator _coordinator;

  /// Whether [alertId] is a renewal notice (ids look like `renewal:2026-12-14`).
  static bool isRenewal(String alertId) => alertId.startsWith('renewal:');

  /// Handles a tap on [alertId]. Returns true when it was a renewal notice and
  /// the schedule was rebuilt for it.
  Future<bool> onTapped(String alertId) async {
    if (!isRenewal(alertId)) return false;
    await _coordinator.rebuild(RebuildTrigger.renewalTapped);
    return true;
  }
}
