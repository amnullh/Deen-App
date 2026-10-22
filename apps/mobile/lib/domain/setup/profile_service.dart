import 'package:prayer_engine/prayer_engine.dart';

import '../entities/enums.dart';
import '../entities/settings.dart';
import '../repositories/alert_preference_repository.dart';
import '../repositories/location_repository.dart';
import '../repositories/settings_repository.dart';
import '../result.dart';

/// Saves what the user chooses in setup and in the settings pages, and tells the
/// rest of the app (through [onChanged]) that the alert schedule must be rebuilt.
///
/// One place applies the rules about defaults so that setup and the later
/// language, location and prayer settings pages behave the same way.
class ProfileService {
  ProfileService({
    required this.settings,
    required this.locations,
    required this.alerts,
    required this.onChanged,
  });

  final SettingsRepository settings;
  final LocationRepository locations;
  final AlertPreferenceRepository alerts;
  final void Function() onChanged;

  /// Read-modify-write updates run one after another, so two quick taps on a
  /// plus button both count instead of one overwriting the other.
  Future<void> _lastUpdate = Future<void>.value();

  Future<T> _serial<T>(Future<T> Function() action) {
    final result = _lastUpdate.then((_) => action());
    _lastUpdate = result.then<void>((_) {}, onError: (_) {});
    return result;
  }

  /// Settings used before the user has chosen anything: the general Muslim World
  /// League method, Standard Asr (the clarified default) and the
  /// middle-of-the-night rule.
  static PrayerSettings defaultSettings({
    AppLanguage language = AppLanguage.en,
    AppLocation? location,
  }) {
    return PrayerSettings(
      method: location == null
          ? CalculationMethod.muslimWorldLeague
          : suggestedMethod(location.countryCode),
      asrMethod: AsrMethod.standard,
      highLatitudeRule: location == null
          ? HighLatitudeRule.middleOfNight
          : defaultHighLatitudeRule(location.latitude),
      language: language,
    );
  }

  /// The saved settings, or the defaults when nothing is saved yet.
  Future<PrayerSettings> currentSettings() async =>
      await settings.get() ?? defaultSettings();

  /// Saves the language. Creates the settings row on first use.
  Future<Result<PrayerSettings>> saveLanguage(AppLanguage language) async {
    final current = await settings.get();
    final next =
        current?.copyWith(language: language) ??
        defaultSettings(language: language);
    return _persistSettings(next);
  }

  /// Saves the location.
  ///
  /// With [adoptRegionDefaults] (first setup, before the user chose a method)
  /// the region's suggested method and the latitude's high-latitude rule are
  /// applied. Otherwise the chosen method is kept (spec Clarifications: the app
  /// only suggests, once per region) and the high-latitude rule follows the new
  /// latitude only if it was still the default for the old one.
  Future<Result<PrayerSettings>> saveLocation(
    AppLocation location, {
    required bool adoptRegionDefaults,
  }) async {
    final previous = await locations.get();
    final current = await settings.get() ?? defaultSettings(location: location);
    final saved = await locations.save(location);
    if (saved is Err<void>) return Err(saved.error);

    var next = current;
    if (adoptRegionDefaults) {
      next = next.copyWith(
        method: suggestedMethod(location.countryCode),
        highLatitudeRule: defaultHighLatitudeRule(location.latitude),
      );
    } else if (previous == null ||
        current.highLatitudeRule ==
            defaultHighLatitudeRule(previous.latitude)) {
      next = next.copyWith(
        highLatitudeRule: defaultHighLatitudeRule(location.latitude),
      );
    }
    return _persistSettings(next);
  }

  /// Applies [change] to the saved settings and saves them.
  Future<Result<PrayerSettings>> updateSettings(
    PrayerSettings Function(PrayerSettings current) change,
  ) async {
    return _serial(() async {
      final current = await settings.get() ?? defaultSettings();
      return _persistSettings(change(current));
    });
  }

  /// Records what the system said about the permissions. Returns true when a
  /// stored state changed, so callers can rebuild the alert schedule.
  Future<bool> savePermissionStates({
    PermissionState? notifications,
    PermissionState? exactAlarm,
  }) async {
    final global = await alerts.getGlobal();
    final next = global.copyWith(
      notificationPermissionState: notifications,
      exactAlarmState: exactAlarm,
    );
    final changed =
        next.notificationPermissionState !=
            global.notificationPermissionState ||
        next.exactAlarmState != global.exactAlarmState;
    if (changed) await alerts.saveGlobal(next);
    return changed;
  }

  /// Marks setup as done. The region of the saved location is marked as already
  /// suggested, because the user just confirmed a method there.
  Future<Result<void>> completeSetup() async {
    final location = await locations.get();
    if (location != null) {
      final current = await settings.get() ?? defaultSettings();
      await settings.save(
        current.copyWith(
          dismissedSuggestionRegions: {
            ...current.dismissedSuggestionRegions,
            location.region,
          },
        ),
      );
    }
    final global = await alerts.getGlobal();
    final result = await alerts.saveGlobal(
      global.copyWith(setupCompleted: true),
    );
    if (result.isOk) onChanged();
    return result;
  }

  Future<Result<PrayerSettings>> _persistSettings(PrayerSettings next) async {
    final result = await settings.save(next);
    if (result is Err<void>) return Err(result.error);
    onChanged();
    return Ok(next);
  }
}
