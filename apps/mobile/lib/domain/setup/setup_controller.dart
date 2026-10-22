import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prayer_engine/prayer_engine.dart';

import '../../app/providers.dart';
import '../../app/providers/setup_providers.dart';
import '../../platform/location_service.dart';
import '../entities/city.dart';
import '../entities/enums.dart';
import '../entities/settings.dart';
import '../permissions/permission_flow.dart';
import '../permissions/permission_gateways.dart';
import '../resolve_timezone.dart';
import '../result.dart';
import 'setup_state.dart';

/// The first-run setup state machine: language, location, method, permissions
/// (notifications, then Android exact alarms and battery) and privacy.
///
/// Every choice is saved as soon as it is made, so the app switches language at
/// once and a closed app resumes with what was already chosen. Refusing a
/// permission is recorded and explained but never blocks [finish] (FR-011).
class SetupController extends Notifier<SetupState> {
  @override
  SetupState build() => SetupState(isAndroid: ref.read(isAndroidProvider));

  /// Fills the state from anything already saved, for a setup that was
  /// interrupted or reopened.
  Future<void> load() async {
    final settings = await ref.read(settingsRepositoryProvider).get();
    final location = await ref.read(locationRepositoryProvider).get();
    final global = await ref
        .read(alertPreferenceRepositoryProvider)
        .getGlobal();
    state = state.copyWith(
      language: settings?.language,
      location: location,
      method: location == null ? null : settings?.method,
      asr: settings?.asrMethod,
      methodChosenByUser: settings != null && location != null,
      notifications: _outcomeOf(global.notificationPermissionState),
      exactAlarm: state.isAndroid
          ? _outcomeOf(global.exactAlarmState)
          : PermissionOutcome.notApplicable,
    );
  }

  static PermissionOutcome? _outcomeOf(PermissionState stored) {
    switch (stored) {
      case PermissionState.granted:
        return PermissionOutcome.granted;
      case PermissionState.denied:
        return PermissionOutcome.denied;
      case PermissionState.unknown:
        return null;
    }
  }

  // Navigation -------------------------------------------------------------

  void next() {
    if (!state.canContinue || state.isLast) return;
    final steps = state.steps;
    state = state.copyWith(
      step: steps[steps.indexOf(state.step) + 1],
      clearProblem: true,
    );
  }

  void back() {
    final steps = state.steps;
    final index = steps.indexOf(state.step);
    if (index == 0) return;
    state = state.copyWith(step: steps[index - 1], clearProblem: true);
  }

  // Language ---------------------------------------------------------------

  Future<void> chooseLanguage(AppLanguage language) async {
    state = state.copyWith(language: language);
    final result = await ref
        .read(profileServiceProvider)
        .saveLanguage(language);
    if (result is Err) state = state.copyWith(problem: SetupProblem.saveFailed);
  }

  // Location ---------------------------------------------------------------

  /// Reads the phone's position. [approximate] rounds it; [displayName] is the
  /// localized name stored for a place that has no city name.
  Future<void> useDeviceLocation({
    required bool approximate,
    required String displayName,
  }) async {
    state = state.copyWith(busy: true, clearProblem: true);
    final outcome = await ref.read(locationServiceProvider).locate();
    switch (outcome) {
      case LocationUnavailable(:final failure):
        state = state.copyWith(
          busy: false,
          locationRefused: failure == LocationFailure.permissionDenied
              ? true
              : null,
          problem: switch (failure) {
            LocationFailure.permissionDenied => SetupProblem.locationDenied,
            LocationFailure.timeout => SetupProblem.locationTimeout,
            LocationFailure.unavailable => SetupProblem.locationUnavailable,
          },
        );
      case LocationFound(:final reading):
        final resolved = await resolveGpsLocation(
          reading: reading,
          approximate: approximate,
          zones: ref.read(deviceZoneSourceProvider),
          displayName: displayName,
          fallbackCountry: ref.read(deviceRegionProvider),
          now: ref.read(clockProvider)(),
        );
        switch (resolved) {
          case Ok(:final value):
            await _saveLocation(value);
          case Err():
            state = state.copyWith(
              busy: false,
              problem: SetupProblem.zoneUnknown,
            );
        }
    }
  }

  /// Uses a city from the offline list. Works with no permission at all.
  Future<void> chooseCity(CityRecord city) async {
    state = state.copyWith(busy: true, clearProblem: true);
    await _saveLocation(locationFromCity(city, ref.read(clockProvider)()));
  }

  Future<void> _saveLocation(AppLocation location) async {
    final result = await ref
        .read(profileServiceProvider)
        .saveLocation(location, adoptRegionDefaults: !state.methodChosenByUser);
    switch (result) {
      case Ok(:final value):
        state = state.copyWith(
          busy: false,
          location: location,
          method: value.method,
          clearProblem: true,
        );
      case Err():
        state = state.copyWith(busy: false, problem: SetupProblem.saveFailed);
    }
  }

  // Method -----------------------------------------------------------------

  /// The method suggested for the chosen location's region.
  CalculationMethod? get suggestedMethodForLocation {
    final location = state.location;
    return location == null ? null : suggestedMethod(location.countryCode);
  }

  /// True when the location's region has no regional default, so the general
  /// Muslim World League suggestion needs that explained.
  bool get suggestionIsGeneral =>
      state.location != null && state.location!.region == Region.other;

  Future<void> chooseMethod(CalculationMethod method) async {
    state = state.copyWith(method: method, methodChosenByUser: true);
    await _updateSettings((s) => s.copyWith(method: method));
  }

  Future<void> chooseAsr(AsrMethod asr) async {
    state = state.copyWith(asr: asr);
    await _updateSettings((s) => s.copyWith(asrMethod: asr));
  }

  Future<void> _updateSettings(
    PrayerSettings Function(PrayerSettings) change,
  ) async {
    final result = await ref
        .read(profileServiceProvider)
        .updateSettings(change);
    if (result is Err) state = state.copyWith(problem: SetupProblem.saveFailed);
  }

  // Permissions ------------------------------------------------------------

  /// Shows the system prompt. Call only after the explanation is on screen.
  Future<void> requestNotifications() async {
    state = state.copyWith(busy: true);
    final outcome = await ref
        .read(notificationPermissionGatewayProvider)
        .request();
    state = state.copyWith(busy: false, notifications: outcome);
    await _savePermissionStates();
  }

  /// Re-reads both permissions, for example when the user comes back from the
  /// system settings.
  Future<void> refreshPermissions() async {
    final notifications = await ref
        .read(notificationPermissionGatewayProvider)
        .status();
    final exact = await ref.read(exactAlarmGatewayProvider).status();
    state = state.copyWith(notifications: notifications, exactAlarm: exact);
    await _savePermissionStates();
  }

  /// Opens the system exact-alarm page. The result is read on return through
  /// [refreshPermissions].
  Future<void> openExactAlarmSettings() =>
      ref.read(exactAlarmGatewayProvider).openSettings();

  /// The user continued without granting exact alarms: record the state.
  Future<void> declineExactAlarm() async {
    final status = await ref.read(exactAlarmGatewayProvider).status();
    state = state.copyWith(exactAlarm: status);
    await _savePermissionStates();
  }

  Future<void> openBatterySettings() =>
      ref.read(batterySettingsGatewayProvider).openBatterySettings();

  /// The way back to a refused location permission.
  Future<void> openLocationSettings() =>
      ref.read(locationServiceProvider).openSettings();

  /// The way back to a refused notification permission.
  Future<void> openAppSettings() =>
      ref.read(notificationPermissionGatewayProvider).openAppSettings();

  Future<void> _savePermissionStates() => ref
      .read(profileServiceProvider)
      .savePermissionStates(
        notifications: storedStateFor(state.notifications),
        exactAlarm: state.isAndroid ? storedStateFor(state.exactAlarm) : null,
      );

  // Finish -----------------------------------------------------------------

  /// Marks setup complete. Always allowed once a location exists; refused
  /// permissions are listed by [SetupState.report] but never stop this.
  Future<bool> finish() async {
    if (state.location == null) return false;
    state = state.copyWith(busy: true);
    final result = await ref.read(profileServiceProvider).completeSetup();
    state = state.copyWith(
      busy: false,
      problem: result.isOk ? null : SetupProblem.saveFailed,
    );
    return result.isOk;
  }
}
