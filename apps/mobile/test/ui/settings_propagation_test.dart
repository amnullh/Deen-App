import 'package:deen_mobile/app/providers/prayer_providers.dart';
import 'package:deen_mobile/domain/entities/enums.dart';
import 'package:deen_mobile/domain/prayer/hijri_source.dart';
import 'package:deen_mobile/l10n/generated/app_localizations.dart';
import 'package:deen_mobile/ui/common/prayer_labels.dart';
import 'package:deen_mobile/ui/home/detail_page.dart';
import 'package:deen_mobile/ui/home/home_page.dart';
import 'package:deen_mobile/ui/settings/prayer_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prayer_engine/prayer_engine.dart';

import 'home/home_test_support.dart';
import 'setup/setup_test_support.dart';

AppLocalizations _en() => lookupAppLocalizations(const Locale('en'));

/// A Hijri source that moves one day per adjustment day, so the test can see the
/// adjustment reach the detail page.
class _FakeHijri implements HijriSource {
  const _FakeHijri();

  @override
  HijriDateInfo? convert(String localDate, {int adjustmentDays = 0}) =>
      HijriDateInfo(year: 1448, month: 4, day: 10 + adjustmentDays);
}

/// Minutes after midnight from a time such as "4:32 AM".
int _minutes(String text) {
  final match = RegExp(r'(\d+):(\d+)\s*(AM|PM)').firstMatch(text)!;
  var hour = int.parse(match.group(1)!) % 12;
  if (match.group(3) == 'PM') hour += 12;
  return hour * 60 + int.parse(match.group(2)!);
}

String _rowTime(WidgetTester tester, String key) {
  final texts = find.descendant(
    of: find.byKey(Key(key)),
    matching: find.byType(Text),
  );
  return tester.widget<Text>(texts.last).data!;
}

Future<void> _tapVisible(WidgetTester tester, String key) async {
  final finder = find.byKey(Key(key));
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await settle(tester, rounds: 8);
}

void main() {
  /// Home, the detail page and prayer settings visible side by side, so that
  /// every one of them has a live listener (a covered route is paused by
  /// Riverpod until it is shown again).
  Future<TestWorld> pumpStack(WidgetTester tester) async {
    final world = TestWorld(now: DateTime.utc(2026, 10, 21, 8));
    await seedProfile(tester, world, city: testCities.first);
    await pumpApp(
      tester,
      world,
      const Row(
        children: [
          Expanded(child: HomePage()),
          Expanded(child: DetailPage()),
          Expanded(child: PrayerSettingsPage()),
        ],
      ),
      size: const Size(1800, 1800),
      extraOverrides: [
        hijriSourceProvider.overrideWithValue(const _FakeHijri()),
      ],
    );
    return world;
  }

  testWidgets('changing the method updates every screen at once', (
    tester,
  ) async {
    final world = await pumpStack(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(PrayerSettingsPage)),
    );
    final before = _rowTime(tester, 'row-fajr');
    final scheduleBefore = container
        .read(selectedScheduleProvider)
        .value!
        .timeOf(Prayer.fajr);

    await _tapVisible(tester, 'method-egypt');

    expect(_rowTime(tester, 'row-fajr'), isNot(before));
    final scheduleAfter = container
        .read(selectedScheduleProvider)
        .value!
        .timeOf(Prayer.fajr);
    expect(scheduleAfter, isNot(scheduleBefore));
    final saved = await tester.runAsync(
      () => world.db.select(world.db.prayerSettingsTable).getSingle(),
    );
    expect(saved!.method, CalculationMethod.egypt);
    await unmount(tester, world.db);
  });

  testWidgets('Asr changes only Asr everywhere', (tester) async {
    final world = await pumpStack(tester);
    final fajr = _rowTime(tester, 'row-fajr');
    final asr = _rowTime(tester, 'row-asr');
    await _tapVisible(tester, 'asr-hanafi');
    expect(_rowTime(tester, 'row-asr'), isNot(asr));
    expect(_rowTime(tester, 'row-fajr'), fajr);
    await unmount(tester, world.db);
  });

  testWidgets('a prayer offset shifts that time by exactly that many minutes', (
    tester,
  ) async {
    final world = await pumpStack(tester);
    final before = _minutes(_rowTime(tester, 'row-maghrib'));
    for (var i = 0; i < 4; i++) {
      await tester.ensureVisible(find.byKey(const Key('offset-more-maghrib')));
      await tester.tap(find.byKey(const Key('offset-more-maghrib')));
      await settle(tester, rounds: 8);
    }
    expect(_minutes(_rowTime(tester, 'row-maghrib')), before + 4);
    expect(find.text('+4 min'), findsOneWidget);
    final saved = await tester.runAsync(
      () => world.db.select(world.db.prayerSettingsTable).getSingle(),
    );
    expect(saved!.offsetMaghrib, 4);

    await tester.ensureVisible(find.byKey(const Key('offset-less-maghrib')));
    await tester.tap(find.byKey(const Key('offset-less-maghrib')));
    await settle(tester, rounds: 8);
    expect(_minutes(_rowTime(tester, 'row-maghrib')), before + 3);
    await unmount(tester, world.db);
  });

  testWidgets('offsets stop at 60 minutes either way', (tester) async {
    final world = TestWorld(now: DateTime.utc(2026, 10, 21, 8));
    await seedProfile(
      tester,
      world,
      city: testCities.first,
      offsets: {Prayer.fajr: 60, Prayer.isha: -60},
    );
    await pumpApp(
      tester,
      world,
      const PrayerSettingsPage(),
      size: const Size(400, 1400),
    );
    expect(
      tester
          .widget<IconButton>(find.byKey(const Key('offset-more-fajr')))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<IconButton>(find.byKey(const Key('offset-less-isha')))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<IconButton>(find.byKey(const Key('offset-less-fajr')))
          .onPressed,
      isNotNull,
    );
    await unmount(tester, world.db);
  });

  testWidgets('the Hijri adjustment reaches the detail page and stops at 2', (
    tester,
  ) async {
    final world = await pumpStack(tester);
    final l10n = _en();
    String hijri() =>
        tester.widget<Text>(find.byKey(const Key('hijri-date'))).data!;
    expect(hijri(), '10 ${l10n.hijriMonth4} 1448 AH');

    await _tapVisible(tester, 'hijri-more');
    await _tapVisible(tester, 'hijri-more');
    expect(hijri(), '12 ${l10n.hijriMonth4} 1448 AH');
    expect(
      tester.widget<IconButton>(find.byKey(const Key('hijri-more'))).onPressed,
      isNull,
    );
    expect(find.text(l10n.prayerSettingsHijriValue('+2')), findsOneWidget);

    await _tapVisible(tester, 'hijri-less');
    await _tapVisible(tester, 'hijri-less');
    await _tapVisible(tester, 'hijri-less');
    await _tapVisible(tester, 'hijri-less');
    expect(hijri(), '8 ${l10n.hijriMonth4} 1448 AH');
    expect(
      tester.widget<IconButton>(find.byKey(const Key('hijri-less'))).onPressed,
      isNull,
    );
    await unmount(tester, world.db);
  });

  testWidgets('the high-latitude rule is saved and named in its explanation', (
    tester,
  ) async {
    final world = TestWorld(now: DateTime.utc(2026, 10, 21, 8));
    final tromso = testCities.firstWhere((c) => c.name == 'Tromsø');
    await seedProfile(tester, world, city: tromso);
    await pumpApp(
      tester,
      world,
      const PrayerSettingsPage(),
      size: const Size(400, 1400),
    );
    final l10n = _en();
    expect(
      find.text(l10n.highLatApplied(l10n.highLatMiddleTitle)),
      findsOneWidget,
    );
    await _tapVisible(tester, 'high-lat-angleBased');
    expect(
      find.text(l10n.highLatApplied(l10n.highLatAngleTitle)),
      findsOneWidget,
    );
    final saved = await tester.runAsync(
      () => world.db.select(world.db.prayerSettingsTable).getSingle(),
    );
    expect(saved!.highLatitudeRule, HighLatitudeRule.angleBased);
    await unmount(tester, world.db);
  });

  testWidgets('prayer settings lay out in Arabic at 2.0x text', (tester) async {
    final world = TestWorld(now: DateTime.utc(2026, 10, 21, 8));
    await seedProfile(
      tester,
      world,
      city: testCities.first,
      language: AppLanguage.ar,
    );
    await pumpApp(
      tester,
      world,
      const PrayerSettingsPage(),
      textScale: 2.0,
      size: const Size(360, 640),
    );
    final context = tester.element(
      find.byKey(const Key('prayer-settings-page')),
    );
    expect(Directionality.of(context), TextDirection.rtl);
    expect(
      find.text(lookupAppLocalizations(const Locale('ar')).prayerSettingsTitle),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    // Scroll to the end to lay out every section.
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -20000),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    await unmount(tester, world.db);
  });

  testWidgets('the detail page shows the Umm al-Qura date and the night times', (
    tester,
  ) async {
    final world = TestWorld(now: DateTime.utc(2026, 10, 21, 8));
    await seedProfile(tester, world, city: testCities.first);
    await pumpApp(
      tester,
      world,
      const DetailPage(),
      size: const Size(400, 900),
    );
    final l10n = _en();
    final expected = toHijri('2026-10-21');
    expect(
      tester.widget<Text>(find.byKey(const Key('hijri-date'))).data,
      '${expected.day} ${l10n.hijriMonthName(expected.month)} ${expected.year} AH',
    );
    expect(find.text(l10n.detailHijriDefault), findsOneWidget);
    for (final label in [
      l10n.detailImsak,
      l10n.detailMidnight,
      l10n.detailLastThird,
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text(l10n.homeTimeNotAvailable), findsNothing);
    await unmount(tester, world.db);
  });

  testWidgets('without a Hijri source the detail page says so', (tester) async {
    final world = TestWorld(now: DateTime.utc(2026, 10, 21, 8));
    await seedProfile(tester, world, city: testCities.first);
    await pumpApp(
      tester,
      world,
      const DetailPage(),
      size: const Size(400, 900),
      extraOverrides: [hijriSourceProvider.overrideWithValue(null)],
    );
    expect(find.text(_en().detailHijriUnavailable), findsOneWidget);
    await unmount(tester, world.db);
  });
}
