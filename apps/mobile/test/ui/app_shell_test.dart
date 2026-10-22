// The app shell: first-run setup until it is finished, then the home screen with
// the Reliability check one tap away (FR-004) and every feature in the menu.
import 'package:deen_mobile/app/app.dart';
import 'package:deen_mobile/app/providers/alerts_providers.dart';
import 'package:deen_mobile/data/repositories/drift_alert_preference_repository.dart';
import 'package:deen_mobile/data/repositories/drift_location_repository.dart';
import 'package:deen_mobile/data/repositories/drift_settings_repository.dart';
import 'package:deen_mobile/domain/entities/enums.dart';
import 'package:deen_mobile/domain/entities/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prayer_engine/prayer_engine.dart';

import 'alerts/support/fakes.dart' as alerts;
import 'setup/setup_test_support.dart';

/// A phone that has finished setup in [language].
Future<void> _finishSetup(
  TestWorld world, {
  AppLanguage language = AppLanguage.en,
  double textScale = 1.0,
}) async {
  await DriftSettingsRepository(world.db).save(
    PrayerSettings(
      method: CalculationMethod.ummAlQura,
      asrMethod: AsrMethod.standard,
      highLatitudeRule: HighLatitudeRule.middleOfNight,
      language: language,
      textScale: textScale,
    ),
  );
  await DriftLocationRepository(world.db).save(
    AppLocation(
      source: LocationSource.city,
      latitude: 21.4225,
      longitude: 39.8262,
      cityId: 104515,
      displayName: 'Mecca',
      timeZoneId: 'Asia/Riyadh',
      countryCode: 'SA',
      updatedAt: DateTime.utc(2026, 10, 21),
    ),
  );
  final alertsRepository = DriftAlertPreferenceRepository(world.db);
  await alertsRepository.saveGlobal(
    (await alertsRepository.getGlobal()).copyWith(setupCompleted: true),
  );
}

Future<void> _pumpShell(WidgetTester tester, TestWorld world) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...world.overrides,
        alertSchedulerProvider.overrideWithValue(alerts.FakeAlertScheduler()),
      ],
      child: const DeenApp(),
    ),
  );
  await settle(tester, rounds: 12);
}

void main() {
  testWidgets('a new install starts in first-run setup', (tester) async {
    final world = TestWorld();
    await _pumpShell(tester, world);
    expect(find.byKey(const Key('setup-next')), findsOneWidget);
    expect(find.byKey(const Key('home-page')), findsNothing);
    await unmount(tester, world.db);
  });

  testWidgets('after setup the home screen shows today in English', (
    tester,
  ) async {
    final world = TestWorld();
    await _finishSetup(world);
    await _pumpShell(tester, world);
    expect(find.byKey(const Key('home-page')), findsOneWidget);
    expect(find.text('Prayer times'), findsOneWidget);
    expect(find.byKey(const Key('next-prayer-card')), findsOneWidget);
    await unmount(tester, world.db);
  });

  testWidgets('the Reliability check is one tap from home', (tester) async {
    final world = TestWorld();
    await _finishSetup(world);
    await _pumpShell(tester, world);
    await tester.tap(find.byKey(const Key('reliability-entry')));
    await settle(tester, rounds: 8);
    expect(find.byKey(const Key('reliability-page')), findsOneWidget);
    await unmount(tester, world.db);
  });

  testWidgets('the menu opens every feature', (tester) async {
    final world = TestWorld();
    await _finishSetup(world);
    await _pumpShell(tester, world);

    for (final destination in const [
      'qibla',
      'tasbih',
      'adhkar',
      'alerts',
      'appearance',
      'data',
      'about',
    ]) {
      await tester.tap(find.byKey(const Key('more-menu')));
      await settle(tester, rounds: 12);
      expect(
        find.byKey(Key('menu-$destination')),
        findsOneWidget,
        reason: destination,
      );
      await tester.tap(find.byKey(Key('menu-$destination')));
      await settle(tester, rounds: 12);
      expect(tester.takeException(), isNull, reason: destination);
      Navigator.of(tester.element(find.byType(Scaffold).last)).pop();
      await settle(tester, rounds: 12);
      expect(find.byKey(const Key('home-page')), findsOneWidget);
    }
    await unmount(tester, world.db);
  });

  testWidgets('Arabic and Urdu are right to left, Indonesian is not', (
    tester,
  ) async {
    for (final entry in {
      AppLanguage.ar: TextDirection.rtl,
      AppLanguage.ur: TextDirection.rtl,
      AppLanguage.id: TextDirection.ltr,
    }.entries) {
      final world = TestWorld();
      await _finishSetup(world, language: entry.key);
      await _pumpShell(tester, world);
      final context = tester.element(find.byKey(const Key('home-page')));
      expect(Directionality.of(context), entry.value, reason: entry.key.name);
      await unmount(tester, world.db);
    }
  });

  testWidgets('does not overflow at the largest text size in Arabic', (
    tester,
  ) async {
    final world = TestWorld();
    await _finishSetup(world, language: AppLanguage.ar, textScale: 2.0);
    await _pumpShell(tester, world);
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('home-page')), findsOneWidget);
    await unmount(tester, world.db);
  });
}
