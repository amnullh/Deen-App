import 'package:deen_mobile/app/lifecycle_observer.dart';
import 'package:deen_mobile/app/providers/prayer_providers.dart';
import 'package:deen_mobile/data/repositories/drift_alert_preference_repository.dart';
import 'package:deen_mobile/domain/entities/city.dart';
import 'package:deen_mobile/domain/entities/enums.dart';
import 'package:deen_mobile/domain/entities/settings.dart';
import 'package:deen_mobile/domain/prayer/day_times_usecase.dart';
import 'package:deen_mobile/l10n/generated/app_localizations.dart';
import 'package:deen_mobile/ui/common/prayer_labels.dart';
import 'package:deen_mobile/ui/common/time_format.dart';
import 'package:deen_mobile/ui/home/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:prayer_engine/prayer_engine.dart';

import '../setup/setup_test_support.dart';
import 'home_test_support.dart';

AppLocalizations _l10n(String code) => lookupAppLocalizations(Locale(code));

final _mecca = testCities.first;

DayTimesUseCase _useCase() => DayTimesUseCase(
  engine: AdhanDartEngine(),
  offsets: BundledOffsetResolver(),
);

/// Wednesday 21 Oct 2026, 11:00 in Mecca: after sunrise, before Dhuhr.
final _wednesdayMorning = DateTime.utc(2026, 10, 21, 8);

Future<void> _pumpHome(
  WidgetTester tester,
  TestWorld world, {
  double textScale = 1.0,
  Size size = const Size(400, 900),
  List<Override> extra = const [],
}) {
  return pumpApp(
    tester,
    world,
    const LifecycleObserver(child: HomePage()),
    textScale: textScale,
    size: size,
    extraOverrides: extra,
  );
}

/// Moves the injected clock and lets the one-second tick deliver it.
Future<void> _advance(WidgetTester tester, TestWorld world, Duration by) async {
  world.clock = world.clock.add(by);
  await tester.pump(const Duration(seconds: 1));
  await tester.pump();
}

String _textOf(WidgetTester tester, String key) =>
    tester.widget<Text>(find.byKey(Key(key))).data!;

void main() {
  testWidgets('shows the six times in order, the next prayer and a countdown', (
    tester,
  ) async {
    final world = TestWorld(now: _wednesdayMorning);
    final seeded = await seedProfile(tester, world, city: _mecca);
    await _pumpHome(tester, world);

    final tops = [
      for (final p in Prayer.values)
        tester.getTopLeft(find.byKey(Key('row-${p.name}'))).dy,
    ];
    expect(tops, orderedEquals([...tops]..sort()));
    final l10n = _l10n('en');
    for (final p in Prayer.values) {
      expect(
        find.descendant(
          of: find.byKey(Key('row-${p.name}')),
          matching: find.text(l10n.prayerName(p)),
        ),
        findsOneWidget,
      );
    }

    final schedule = _useCase().scheduleFor(
      location: seeded.location!,
      settings: seeded.settings,
      localDate: '2026-10-21',
    );
    final expected = schedule
        .timeOf(Prayer.dhuhr)!
        .difference(_wednesdayMorning);
    expect(_textOf(tester, 'next-prayer-name'), l10n.prayerDhuhr);
    expect(_textOf(tester, 'countdown'), formatCountdown(expected, 'en'));
    expect(find.text(l10n.homeNextBadge), findsOneWidget);
    await unmount(tester, world.db);
  });

  testWidgets('the countdown ticks with the injected clock', (tester) async {
    final world = TestWorld(now: _wednesdayMorning);
    await seedProfile(tester, world, city: _mecca);
    await _pumpHome(tester, world);
    final before = _textOf(tester, 'countdown');
    await _advance(tester, world, const Duration(seconds: 5));
    final after = _textOf(tester, 'countdown');
    expect(after, isNot(before));
    expect(
      parseCountdown(before) - parseCountdown(after),
      const Duration(seconds: 5),
    );
    await unmount(tester, world.db);
  });

  testWidgets('after Isha the next prayer is tomorrow\'s Fajr', (tester) async {
    // 23:30 in Mecca.
    final world = TestWorld(now: DateTime.utc(2026, 10, 21, 20, 30));
    await seedProfile(tester, world, city: _mecca);
    await _pumpHome(tester, world);
    expect(_textOf(tester, 'next-prayer-name'), _l10n('en').prayerFajr);
    final remaining = parseCountdown(_textOf(tester, 'countdown'));
    expect(remaining, greaterThan(const Duration(hours: 4)));
    expect(remaining, lessThan(const Duration(hours: 8)));
    // No row of today is marked as next.
    expect(find.text(_l10n('en').homeNextBadge), findsNothing);
    await unmount(tester, world.db);
  });

  testWidgets('Dhuhr is Jumu\'ah on Fridays by the location\'s local date', (
    tester,
  ) async {
    // Thursday 22:00 UTC is already Friday 01:00 in Mecca.
    final world = TestWorld(now: DateTime.utc(2026, 10, 22, 22));
    await seedProfile(tester, world, city: _mecca);
    await _pumpHome(tester, world);
    final l10n = _l10n('en');
    expect(
      find.descendant(
        of: find.byKey(const Key('row-dhuhr')),
        matching: find.text(l10n.prayerJumuah),
      ),
      findsOneWidget,
    );
    expect(_textOf(tester, 'next-prayer-name'), l10n.prayerFajr);

    // The next day (Saturday) is plain Dhuhr again.
    await tester.tap(find.byKey(const Key('next-day')));
    await tester.pump();
    expect(
      find.descendant(
        of: find.byKey(const Key('row-dhuhr')),
        matching: find.text(l10n.prayerDhuhr),
      ),
      findsOneWidget,
    );
    await unmount(tester, world.db);
  });

  testWidgets('previous and next day change the date and the times', (
    tester,
  ) async {
    final world = TestWorld(now: _wednesdayMorning);
    await seedProfile(tester, world, city: _mecca);
    await _pumpHome(tester, world);
    final todayDate = tester
        .widget<Text>(find.byKey(const Key('home-date')))
        .data;
    final todayFajr = _rowTime(tester, 'row-fajr');

    await tester.tap(find.byKey(const Key('next-day')));
    await tester.pump();
    expect(
      tester.widget<Text>(find.byKey(const Key('home-date'))).data,
      isNot(todayDate),
    );
    expect(find.byKey(const Key('back-to-today')), findsOneWidget);
    // The next prayer card does not follow the browsing.
    expect(_textOf(tester, 'next-prayer-name'), _l10n('en').prayerDhuhr);

    await tester.tap(find.byKey(const Key('previous-day')));
    await tester.tap(find.byKey(const Key('previous-day')));
    await tester.pump();
    expect(find.byKey(const Key('back-to-today')), findsOneWidget);
    await tester.tap(find.byKey(const Key('back-to-today')));
    await tester.pump();
    expect(
      tester.widget<Text>(find.byKey(const Key('home-date'))).data,
      todayDate,
    );
    expect(_rowTime(tester, 'row-fajr'), todayFajr);
    expect(find.byKey(const Key('back-to-today')), findsNothing);
    await unmount(tester, world.db);
  });

  for (final language in [AppLanguage.ar, AppLanguage.ur]) {
    testWidgets(
      'home is right to left in ${language.name} with no overflow at 2.0x text',
      (tester) async {
        final world = TestWorld(now: _wednesdayMorning);
        await seedProfile(tester, world, city: _mecca, language: language);
        await _pumpHome(
          tester,
          world,
          textScale: 2.0,
          size: const Size(360, 640),
        );
        final context = tester.element(find.byKey(const Key('home-page')));
        expect(Directionality.of(context), TextDirection.rtl);
        final l10n = _l10n(language.name);
        expect(find.text(l10n.homeTitle), findsOneWidget);
        expect(find.text(l10n.nextPrayerLabel), findsOneWidget);
        expect(tester.takeException(), isNull);
        await unmount(tester, world.db);
      },
    );
  }

  for (final language in [AppLanguage.en, AppLanguage.id]) {
    testWidgets('home has no overflow at 2.0x text in ${language.name}', (
      tester,
    ) async {
      final world = TestWorld(now: _wednesdayMorning);
      await seedProfile(tester, world, city: _mecca, language: language);
      await _pumpHome(
        tester,
        world,
        textScale: 2.0,
        size: const Size(360, 640),
      );
      expect(tester.takeException(), isNull);
      await unmount(tester, world.db);
    });
  }

  testWidgets('without a location it asks for one', (tester) async {
    final world = TestWorld(now: _wednesdayMorning);
    await seedProfile(tester, world);
    await _pumpHome(tester, world);
    expect(find.text(_l10n('en').homeNoLocation), findsOneWidget);
    expect(find.byKey(const Key('home-choose-location')), findsOneWidget);
    expect(find.byKey(const Key('next-prayer-card')), findsNothing);
    await unmount(tester, world.db);
  });

  testWidgets('rows and the countdown have spoken labels', (tester) async {
    final handle = tester.ensureSemantics();
    final world = TestWorld(now: _wednesdayMorning);
    await seedProfile(tester, world, city: _mecca);
    await _pumpHome(tester, world);
    final l10n = _l10n('en');
    final fajr = tester.getSemantics(find.byKey(const Key('row-fajr')));
    expect(fajr.label, contains(l10n.prayerFajr));
    expect(fajr.label, contains(':'));
    final next = tester.getSemantics(find.byKey(const Key('row-dhuhr')));
    expect(next.label, startsWith(l10n.homeNextBadge));
    expect(
      find.bySemanticsLabel(RegExp('${l10n.nextPrayerLabel}: .* hour')),
      findsOneWidget,
    );
    handle.dispose();
    await unmount(tester, world.db);
  });

  group('notices', () {
    testWidgets('a clock before the build date warns', (tester) async {
      final world = TestWorld(now: DateTime.utc(2019, 1, 1, 8));
      await seedProfile(tester, world, city: _mecca);
      await _pumpHome(tester, world);
      expect(find.byKey(const Key('clock-warning-banner')), findsOneWidget);
      expect(find.text(_l10n('en').homeClockBeforeBuild), findsOneWidget);
      await unmount(tester, world.db);
    });

    testWidgets('a clock set back since the last visit warns', (tester) async {
      final world = TestWorld(now: _wednesdayMorning);
      await seedProfile(tester, world, city: _mecca);
      await tester.runAsync(() async {
        final repo = DriftAlertPreferenceRepository(world.db);
        final global = await repo.getGlobal();
        await repo.saveGlobal(
          global.copyWith(
            clockSample: ClockSample(
              wallClockMs: _wednesdayMorning
                  .add(const Duration(days: 2))
                  .millisecondsSinceEpoch,
              monotonicMs: 0,
              bootId: '',
            ),
          ),
        );
      });
      await _pumpHome(tester, world);
      expect(find.text(_l10n('en').homeClockMovedBack), findsOneWidget);
      await unmount(tester, world.db);
    });

    testWidgets('a sane clock shows no warning and stores a sample', (
      tester,
    ) async {
      final world = TestWorld(now: _wednesdayMorning);
      await seedProfile(tester, world, city: _mecca);
      await _pumpHome(tester, world);
      expect(find.byKey(const Key('clock-warning-banner')), findsNothing);
      final global = await tester.runAsync(
        () => DriftAlertPreferenceRepository(world.db).getGlobal(),
      );
      expect(
        global!.clockSample!.wallClockMs,
        _wednesdayMorning.millisecondsSinceEpoch,
      );
      await unmount(tester, world.db);
    });

    testWidgets(
      'time-zone rules that differ from the bundled ones are flagged',
      (tester) async {
        // The phone says Riyadh is UTC+4; the bundled data says UTC+3.
        final world = TestWorld(
          now: _wednesdayMorning,
          osOffset: (_) => const Duration(hours: 4),
        );
        await seedProfile(tester, world, city: _mecca);
        await _pumpHome(tester, world);
        expect(find.byKey(const Key('tz-rules-banner')), findsOneWidget);
        expect(find.text(_l10n('en').homeTzRulesNotice), findsOneWidget);
        await unmount(tester, world.db);
      },
    );

    testWidgets('no time-zone notice when the rules agree', (tester) async {
      final world = TestWorld(now: _wednesdayMorning);
      await seedProfile(tester, world, city: _mecca);
      await _pumpHome(tester, world);
      expect(find.byKey(const Key('tz-rules-banner')), findsNothing);
      await unmount(tester, world.db);
    });

    testWidgets('a high latitude explains the rule in use', (tester) async {
      final world = TestWorld(now: _wednesdayMorning);
      final tromso = testCities.firstWhere((c) => c.name == 'Tromsø');
      await seedProfile(
        tester,
        world,
        city: tromso,
        rule: HighLatitudeRule.seventhOfNight,
      );
      await _pumpHome(tester, world);
      final l10n = _l10n('en');
      expect(find.byKey(const Key('high-latitude-notice')), findsOneWidget);
      expect(
        find.text(l10n.highLatApplied(l10n.highLatSeventhTitle)),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await unmount(tester, world.db);
    });

    testWidgets('no high-latitude notice at Mecca', (tester) async {
      final world = TestWorld(now: _wednesdayMorning);
      await seedProfile(tester, world, city: _mecca);
      await _pumpHome(tester, world);
      expect(find.byKey(const Key('high-latitude-notice')), findsNothing);
      await unmount(tester, world.db);
    });
  });

  group('region suggestion banner', () {
    testWidgets('is shown once, keeps the method, and stays dismissed', (
      tester,
    ) async {
      final world = TestWorld(now: _wednesdayMorning);
      final karachi = testCities.firstWhere((c) => c.countryCode == 'PK');
      await seedProfile(
        tester,
        world,
        city: karachi,
        method: CalculationMethod.ummAlQura,
        dismissed: {Region.arabianPeninsula},
      );
      await _pumpHome(tester, world);
      final l10n = _l10n('en');
      expect(find.byKey(const Key('region-suggestion-banner')), findsOneWidget);
      expect(
        find.text(l10n.homeRegionSuggestion(l10n.methodKarachi)),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip(l10n.homeBannerDismiss));
      await settle(tester, rounds: 3);
      expect(find.byKey(const Key('region-suggestion-banner')), findsNothing);
      final saved = await tester.runAsync(
        () => world.db.select(world.db.prayerSettingsTable).getSingle(),
      );
      expect(saved!.method, CalculationMethod.ummAlQura);
      expect(
        saved.suggestionDismissedRegions.split(','),
        contains(Region.southAsia.name),
      );
      await unmount(tester, world.db);
    });

    testWidgets('accepting switches the method and every time updates', (
      tester,
    ) async {
      final world = TestWorld(now: _wednesdayMorning);
      final karachi = testCities.firstWhere((c) => c.countryCode == 'PK');
      await seedProfile(
        tester,
        world,
        city: karachi,
        method: CalculationMethod.egypt,
        dismissed: {Region.middleEastAndAfrica},
      );
      await _pumpHome(tester, world);
      final l10n = _l10n('en');
      final fajrBefore = _rowTime(tester, 'row-fajr');
      await tester.tap(
        find.text(l10n.homeRegionSuggestionSwitch(l10n.methodKarachi)),
      );
      await settle(tester, rounds: 3);
      expect(find.byKey(const Key('region-suggestion-banner')), findsNothing);
      expect(_rowTime(tester, 'row-fajr'), isNot(fajrBefore));
      await unmount(tester, world.db);
    });

    testWidgets('a region with no default says the suggestion is general', (
      tester,
    ) async {
      final world = TestWorld(now: _wednesdayMorning);
      await seedProfile(
        tester,
        world,
        city: const CityRecord(
          geonameId: 1,
          name: 'Test city',
          latitude: 21.4,
          longitude: 39.8,
          countryCode: 'BR',
          timeZoneId: 'Asia/Riyadh',
          population: 1,
        ),
        method: CalculationMethod.karachi,
      );
      await _pumpHome(tester, world);
      final l10n = _l10n('en');
      expect(
        find.text(
          l10n.homeRegionSuggestionGeneral(l10n.methodMuslimWorldLeague),
        ),
        findsOneWidget,
      );
      await unmount(tester, world.db);
    });
  });

  testWidgets('returning to the app recomputes without user action', (
    tester,
  ) async {
    final world = TestWorld(now: _wednesdayMorning);
    await seedProfile(tester, world, city: _mecca);
    await _pumpHome(tester, world);
    final container = ProviderScope.containerOf(
      tester.element(find.byKey(const Key('home-page'))),
    );
    final before = container.read(recomputeEpochProvider);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await settle(tester, rounds: 2);
    expect(container.read(recomputeEpochProvider), greaterThan(before));
    expect(find.byKey(const Key('next-prayer-card')), findsOneWidget);
    await unmount(tester, world.db);
  });

  testWidgets('permission banners show only what was refused', (tester) async {
    final world = TestWorld(now: _wednesdayMorning);
    await seedProfile(tester, world, city: _mecca);
    await tester.runAsync(() async {
      final repo = DriftAlertPreferenceRepository(world.db);
      await repo.saveGlobal(
        (await repo.getGlobal()).copyWith(
          setupCompleted: true,
          notificationPermissionState: PermissionState.denied,
          exactAlarmState: PermissionState.granted,
        ),
      );
    });
    await _pumpHome(tester, world);
    expect(find.byKey(const Key('permission-banner-alerts')), findsOneWidget);
    expect(
      find.byKey(const Key('permission-banner-exactTiming')),
      findsNothing,
    );
    await tester.tap(find.text(_l10n('en').permissionBannerAction));
    await tester.pump();
    expect(world.notificationGateway.settingsOpened, 1);
    await unmount(tester, world.db);
  });
}

/// The time shown in a prayer row.
String _rowTime(WidgetTester tester, String rowKey) {
  final texts = find.descendant(
    of: find.byKey(Key(rowKey)),
    matching: find.byType(Text),
  );
  return tester.widget<Text>(texts.last).data!;
}

/// Parses `HH:MM:SS`.
Duration parseCountdown(String text) {
  final parts = text.split(':').map(int.parse).toList();
  return Duration(hours: parts[0], minutes: parts[1], seconds: parts[2]);
}
