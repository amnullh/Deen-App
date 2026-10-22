import 'package:deen_mobile/data/db/app_database.dart';
import 'package:deen_mobile/data/repositories/drift_alert_preference_repository.dart';
import 'package:deen_mobile/domain/entities/enums.dart';
import 'package:deen_mobile/domain/entities/settings.dart';
import 'package:deen_mobile/platform/alert_scheduler.dart';
import 'package:deen_mobile/ui/alerts/alert_options_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  void tall(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 6000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Future<List<AlertPreference>> prefs(
    WidgetTester tester,
    AppDatabase db,
  ) async =>
      (await tester.runAsync(DriftAlertPreferenceRepository(db).getAll))!;

  testWidgets('Android: loud mode is per prayer and off by default', (
    tester,
  ) async {
    tall(tester);
    final db = await newDatabase();
    await pumpPage(tester, const AlertOptionsPage(), db: db);
    for (final prayer in AlertPrayer.values) {
      final tile = tester.widget<SwitchListTile>(
        find.byKey(Key('loud-${prayer.name}')),
      );
      expect(tile.value, isFalse);
    }
    // No volume choice is shown until loud mode is on.
    expect(find.byKey(const Key('volume-fajr-keep')), findsNothing);
    await unmount(tester, db);
  });

  testWidgets('turning loud mode on offers keep-volume and gentle ramp', (
    tester,
  ) async {
    tall(tester);
    final db = await newDatabase();
    await pumpPage(tester, const AlertOptionsPage(), db: db);
    await tester.tap(find.byKey(const Key('loud-fajr')));
    await settle(tester);
    expect(find.text('Keep my current volume'), findsOneWidget);
    expect(find.text('Gentle ramp'), findsOneWidget);
    var fajr = (await prefs(tester, db)).first;
    expect(fajr.loudMode, isTrue);
    expect(fajr.volumeChoice, VolumeChoice.keepCurrent);

    await tester.tap(find.byKey(const Key('volume-fajr-ramp')));
    await settle(tester);
    fajr = (await prefs(tester, db)).first;
    expect(fajr.volumeChoice, VolumeChoice.gentleRamp);
    // Other prayers are untouched.
    expect((await prefs(tester, db)).skip(1).every((p) => !p.loudMode), isTrue);
    await unmount(tester, db);
  });

  testWidgets('iPhone has no loud mode and says why', (tester) async {
    tall(tester);
    final db = await newDatabase();
    await pumpPage(
      tester,
      const AlertOptionsPage(),
      db: db,
      scheduler: FakeAlertScheduler(platform: AlertPlatform.ios),
    );
    expect(find.byKey(const Key('loud-fajr')), findsNothing);
    expect(find.textContaining('Android only'), findsOneWidget);
    await unmount(tester, db);
  });

  testWidgets('quiet hours start unset and take a default range when enabled', (
    tester,
  ) async {
    tall(tester);
    final db = await newDatabase();
    await pumpPage(tester, const AlertOptionsPage(), db: db);
    expect(find.byKey(const Key('quiet-start')), findsNothing);
    await tester.tap(find.byKey(const Key('quiet-switch')));
    await settle(tester);
    expect(find.byKey(const Key('quiet-start')), findsOneWidget);
    final global = await tester.runAsync(
      DriftAlertPreferenceRepository(db).getGlobal,
    );
    expect(global!.quietHours!.startMinutes, 22 * 60);
    expect(global.quietHours!.endMinutes, 5 * 60);

    await tester.tap(find.byKey(const Key('quiet-switch')));
    await settle(tester);
    final cleared = await tester.runAsync(
      DriftAlertPreferenceRepository(db).getGlobal,
    );
    expect(cleared!.quietHours, isNull);
    await unmount(tester, db);
  });

  testWidgets('audio output defaults to speaker and can be changed', (
    tester,
  ) async {
    tall(tester);
    final db = await newDatabase();
    await pumpPage(tester, const AlertOptionsPage(), db: db);
    await tester.tap(find.byKey(const Key('output-bluetooth')));
    await settle(tester);
    final global = await tester.runAsync(
      DriftAlertPreferenceRepository(db).getGlobal,
    );
    expect(global!.audioOutput, AudioOutput.bluetooth);
    await unmount(tester, db);
  });

  testWidgets('a reminder of 15 minutes saves for that prayer only', (
    tester,
  ) async {
    tall(tester);
    final db = await newDatabase();
    await pumpPage(
      tester,
      const AlertOptionsPage(),
      db: db,
      scheduler: FakeAlertScheduler(platform: AlertPlatform.ios),
    );
    await tester.tap(find.byKey(const Key('reminder-menu-asr')));
    await settle(tester);
    await tester.tap(find.text('15 min before').last);
    await settle(tester);
    final all = await prefs(tester, db);
    expect(
      all.firstWhere((p) => p.prayer == AlertPrayer.asr).preReminderMinutes,
      15,
    );
    expect(
      all
          .where((p) => p.prayer != AlertPrayer.asr)
          .every((p) => p.preReminderMinutes == null),
      isTrue,
    );
    await unmount(tester, db);
  });

  testWidgets('a reminder on Android without exact alarms asks first', (
    tester,
  ) async {
    tall(tester);
    final db = await newDatabase();
    await pumpPage(
      tester,
      const AlertOptionsPage(),
      db: db,
      scheduler: FakeAlertScheduler(
        permissions: const AlertPermissions(
          platform: AlertPlatform.android,
          notificationsGranted: true,
          exactAlarmGranted: false,
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('reminder-menu-asr')));
    await settle(tester);
    await tester.tap(find.text('10 min before').last);
    await settle(tester);
    expect(find.byKey(const Key('exact-alarm-dialog')), findsOneWidget);
    await tester.tap(find.byKey(const Key('exact-alarm-skip')));
    await settle(tester);
    final asr = (await prefs(
      tester,
      db,
    )).firstWhere((p) => p.prayer == AlertPrayer.asr);
    expect(asr.preReminderMinutes, 10);
    await unmount(tester, db);
  });

  testWidgets('the suhoor reminder is off until chosen, then saves minutes', (
    tester,
  ) async {
    tall(tester);
    final db = await newDatabase();
    await pumpPage(
      tester,
      const AlertOptionsPage(),
      db: db,
      scheduler: FakeAlertScheduler(platform: AlertPlatform.ios),
    );
    expect(find.byKey(const Key('suhoor-minutes')), findsNothing);
    await tester.tap(find.byKey(const Key('suhoor-switch')));
    await settle(tester);
    expect(find.byKey(const Key('suhoor-minutes')), findsOneWidget);
    final global = await tester.runAsync(
      DriftAlertPreferenceRepository(db).getGlobal,
    );
    expect(global!.suhoorReminderEnabled, isTrue);
    expect(global.suhoorReminderMinutes, 30);
    await unmount(tester, db);
  });

  testWidgets('survives the largest text size in Indonesian', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final db = await newDatabase(language: AppLanguage.id);
    await pumpPage(
      tester,
      const AlertOptionsPage(),
      db: db,
      language: AppLanguage.id,
      textScale: 2.0,
    );
    expect(tester.takeException(), isNull);
    await unmount(tester, db);
  });
}
