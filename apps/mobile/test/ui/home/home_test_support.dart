import 'package:deen_mobile/data/repositories/drift_location_repository.dart';
import 'package:deen_mobile/data/repositories/drift_settings_repository.dart';
import 'package:deen_mobile/domain/entities/city.dart';
import 'package:deen_mobile/domain/entities/enums.dart';
import 'package:deen_mobile/domain/entities/settings.dart';
import 'package:deen_mobile/domain/resolve_timezone.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prayer_engine/prayer_engine.dart';

import '../setup/setup_test_support.dart';

/// Saves a city and settings, as setup would have.
Future<({AppLocation? location, PrayerSettings settings})> seedProfile(
  WidgetTester tester,
  TestWorld world, {
  CityRecord? city,
  CalculationMethod method = CalculationMethod.ummAlQura,
  AppLanguage language = AppLanguage.en,
  Set<Region> dismissed = const {},
  Map<Prayer, int> offsets = const {},
  int hijriAdjustment = 0,
  HighLatitudeRule rule = HighLatitudeRule.middleOfNight,
}) async {
  final settings = PrayerSettings(
    method: method,
    asrMethod: AsrMethod.standard,
    highLatitudeRule: rule,
    language: language,
    dismissedSuggestionRegions: dismissed,
    offsetsMinutes: offsets,
    hijriAdjustment: hijriAdjustment,
  );
  final location = city == null ? null : locationFromCity(city, world.clock);
  await tester.runAsync(() async {
    await DriftSettingsRepository(world.db).save(settings);
    if (location != null) {
      await DriftLocationRepository(world.db).save(location);
    }
  });
  return (location: location, settings: settings);
}
