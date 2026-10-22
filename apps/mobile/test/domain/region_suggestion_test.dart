import 'package:deen_mobile/domain/entities/enums.dart';
import 'package:deen_mobile/domain/entities/settings.dart';
import 'package:deen_mobile/domain/prayer/region_suggestion.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prayer_engine/prayer_engine.dart';

AppLocation _in(String country) => AppLocation(
  source: LocationSource.city,
  latitude: 10,
  longitude: 10,
  displayName: 'x',
  timeZoneId: 'Asia/Riyadh',
  countryCode: country,
  updatedAt: DateTime.utc(2026),
);

PrayerSettings _settings(
  CalculationMethod method, {
  Set<Region> dismissed = const {},
}) => PrayerSettings(
  method: method,
  asrMethod: AsrMethod.standard,
  highLatitudeRule: HighLatitudeRule.middleOfNight,
  language: AppLanguage.en,
  dismissedSuggestionRegions: dismissed,
);

void main() {
  test('no suggestion when the region default is already chosen', () {
    expect(
      regionSuggestionFor(
        location: _in('SA'),
        settings: _settings(CalculationMethod.ummAlQura),
      ),
      isNull,
    );
  });

  test('suggests the region method and keeps the chosen one', () {
    final suggestion = regionSuggestionFor(
      location: _in('PK'),
      settings: _settings(CalculationMethod.ummAlQura),
    )!;
    expect(suggestion.region, Region.southAsia);
    expect(suggestion.suggested, CalculationMethod.karachi);
    expect(suggestion.current, CalculationMethod.ummAlQura);
    expect(suggestion.isGeneralDefault, isFalse);
  });

  test('a region without a default is explained as the general default', () {
    final suggestion = regionSuggestionFor(
      location: _in('BR'),
      settings: _settings(CalculationMethod.karachi),
    )!;
    expect(suggestion.suggested, CalculationMethod.muslimWorldLeague);
    expect(suggestion.isGeneralDefault, isTrue);
  });

  test('dismissal is stored per region and the method is kept', () {
    final settings = _settings(CalculationMethod.ummAlQura);
    final suggestion = regionSuggestionFor(
      location: _in('PK'),
      settings: settings,
    )!;
    final dismissed = dismissSuggestion(settings, suggestion);
    expect(dismissed.method, CalculationMethod.ummAlQura);
    expect(dismissed.dismissedSuggestionRegions, {Region.southAsia});
    expect(
      regionSuggestionFor(location: _in('PK'), settings: dismissed),
      isNull,
      reason: 'once per region',
    );
    // A different region is still offered.
    expect(
      regionSuggestionFor(location: _in('GB'), settings: dismissed),
      isNotNull,
    );
  });

  test('accepting switches the method and remembers the region', () {
    final settings = _settings(CalculationMethod.ummAlQura);
    final suggestion = regionSuggestionFor(
      location: _in('TR'),
      settings: settings,
    )!;
    final accepted = acceptSuggestion(settings, suggestion);
    expect(accepted.method, CalculationMethod.diyanet);
    expect(accepted.dismissedSuggestionRegions, {Region.turkey});
  });
}
