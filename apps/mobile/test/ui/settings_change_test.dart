import 'package:deen_mobile/app/providers/setup_providers.dart';
import 'package:deen_mobile/domain/entities/enums.dart';
import 'package:deen_mobile/l10n/generated/app_localizations.dart';
import 'package:deen_mobile/platform/location_service.dart';
import 'package:deen_mobile/ui/settings/language_settings_page.dart';
import 'package:deen_mobile/ui/settings/location_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prayer_engine/prayer_engine.dart';

import 'home/home_test_support.dart';
import 'setup/setup_test_support.dart';

AppLocalizations _l10n(String code) => lookupAppLocalizations(Locale(code));

int _invalidations(WidgetTester tester, Finder from) =>
    ProviderScope.containerOf(tester.element(from))
        .read(scheduleInvalidationProvider);

Future<void> _tap(WidgetTester tester, String key, {int rounds = 8}) async {
  final finder = find.byKey(Key(key));
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await settle(tester, rounds: rounds);
}

void main() {
  group('language', () {
    testWidgets('can be changed after setup and rebuilds the schedule', (
      tester,
    ) async {
      final world = TestWorld();
      await seedProfile(tester, world, city: testCities.first);
      await pumpApp(
        tester,
        world,
        const LanguageSettingsPage(),
        size: const Size(400, 900),
      );
      final page = find.byKey(const Key('language-settings-page'));
      expect(find.text(_l10n('en').languageSettingsTitle), findsOneWidget);
      final before = _invalidations(tester, page);

      await _tap(tester, 'language-ar');

      expect(find.text(_l10n('ar').languageSettingsTitle), findsOneWidget);
      expect(
        Directionality.of(tester.element(page)),
        TextDirection.rtl,
        reason: 'the whole app switches at once',
      );
      final saved = await tester.runAsync(
        () => world.db.select(world.db.prayerSettingsTable).getSingle(),
      );
      expect(saved!.language, AppLanguage.ar);
      expect(
        saved.method,
        CalculationMethod.ummAlQura,
        reason: 'other settings are kept',
      );
      expect(_invalidations(tester, page), greaterThan(before));
      await unmount(tester, world.db);
    });

    testWidgets('the current language is selected', (tester) async {
      final world = TestWorld();
      await seedProfile(
        tester,
        world,
        city: testCities.first,
        language: AppLanguage.id,
      );
      await pumpApp(tester, world, const LanguageSettingsPage());
      final group = RadioGroup.maybeOf<AppLanguage>(
        tester.element(find.byKey(const Key('language-id'))),
      );
      expect(group!.groupValue, AppLanguage.id);
      await unmount(tester, world.db);
    });
  });

  group('location', () {
    testWidgets('a city can be chosen, the method is kept and the schedule '
        'is rebuilt', (tester) async {
      final world = TestWorld();
      await seedProfile(
        tester,
        world,
        city: testCities.first,
        method: CalculationMethod.egypt,
      );
      await pumpApp(
        tester,
        world,
        const LocationSettingsPage(),
        size: const Size(400, 1200),
      );
      final page = find.byKey(const Key('location-settings-page'));
      final l10n = _l10n('en');
      expect(find.text(l10n.locationSettingsCurrent('Mecca')), findsOneWidget);
      final before = _invalidations(tester, page);

      await tester.enterText(find.byKey(const Key('city-search')), 'Kar');
      await settle(tester, rounds: 3);
      await _tap(tester, 'city-1174872');

      expect(
        find.text(l10n.locationSettingsCurrent('Karachi')),
        findsOneWidget,
      );
      expect(find.text(l10n.locationSettingsSaved), findsOneWidget);
      final settings = await tester.runAsync(
        () => world.db.select(world.db.prayerSettingsTable).getSingle(),
      );
      final location = await tester.runAsync(
        () => world.db.select(world.db.locationTable).getSingle(),
      );
      expect(location!.timeZoneId, 'Asia/Karachi');
      expect(location.countryCode, 'PK');
      expect(
        settings!.method,
        CalculationMethod.egypt,
        reason: 'the chosen method is kept; the home screen only suggests',
      );
      expect(_invalidations(tester, page), greaterThan(before));
      await unmount(tester, world.db);
    });

    testWidgets('the phone position can be used, precise or approximate', (
      tester,
    ) async {
      final world = TestWorld();
      await seedProfile(tester, world, city: testCities.first);
      await pumpApp(
        tester,
        world,
        const LocationSettingsPage(),
        size: const Size(400, 1200),
      );
      await _tap(tester, 'location-precise');
      var location = await tester.runAsync(
        () => world.db.select(world.db.locationTable).getSingle(),
      );
      expect(location!.source, LocationSource.precise);
      expect(location.latitude, 24.7136);
      expect(location.displayName, _l10n('en').setupLocationCurrentName);

      await _tap(tester, 'location-approximate');
      location = await tester.runAsync(
        () => world.db.select(world.db.locationTable).getSingle(),
      );
      expect(location!.source, LocationSource.approximate);
      expect(location.latitude, 24.7);
      expect(location.longitude, 46.7);
      expect(world.locationService.located, 2);
      await unmount(tester, world.db);
    });

    testWidgets('a refusal is explained and the way back opens settings', (
      tester,
    ) async {
      final world = TestWorld(
        location: const LocationUnavailable(LocationFailure.permissionDenied),
      );
      await seedProfile(tester, world, city: testCities.first);
      await pumpApp(
        tester,
        world,
        const LocationSettingsPage(),
        size: const Size(400, 1200),
      );
      await _tap(tester, 'location-precise');
      expect(find.text(_l10n('en').setupProblemLocationDenied), findsOneWidget);
      await _tap(tester, 'location-open-settings');
      expect(world.locationService.settingsOpened, 1);
      // The saved city is untouched.
      final location = await tester.runAsync(
        () => world.db.select(world.db.locationTable).getSingle(),
      );
      expect(location!.displayName, 'Mecca');
      await unmount(tester, world.db);
    });

    testWidgets('lays out in Urdu at 2.0x text with no overflow', (
      tester,
    ) async {
      final world = TestWorld();
      await seedProfile(
        tester,
        world,
        city: testCities.first,
        language: AppLanguage.ur,
      );
      await pumpApp(
        tester,
        world,
        const LocationSettingsPage(),
        textScale: 2.0,
        size: const Size(360, 640),
      );
      expect(
        Directionality.of(
          tester.element(find.byKey(const Key('location-settings-page'))),
        ),
        TextDirection.rtl,
      );
      expect(tester.takeException(), isNull);
      await unmount(tester, world.db);
    });
  });
}
