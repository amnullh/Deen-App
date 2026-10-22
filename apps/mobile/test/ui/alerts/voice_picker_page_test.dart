import 'package:deen_mobile/data/repositories/drift_alert_log_repository.dart';
import 'package:deen_mobile/data/repositories/drift_alert_preference_repository.dart';
import 'package:deen_mobile/domain/entities/enums.dart';
import 'package:deen_mobile/ui/alerts/voice_picker_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  void tall(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  testWidgets('shows both voices with all three recordings each', (
    tester,
  ) async {
    tall(tester);
    final db = await newDatabase();
    await pumpPage(
      tester,
      const VoicePickerPage(prayer: AlertPrayer.fajr),
      db: db,
    );
    for (final voice in ['voice-1', 'voice-2']) {
      expect(find.byKey(Key('voice-card-$voice')), findsOneWidget);
      for (final version in ['standard', 'fajr', 'shia']) {
        expect(find.byKey(Key('recording-$voice-$version')), findsOneWidget);
        expect(find.byKey(Key('preview-$voice-$version')), findsOneWidget);
      }
    }
    await unmount(tester, db);
  });

  testWidgets('the Shia wording is visible and clearly labelled', (
    tester,
  ) async {
    tall(tester);
    final db = await newDatabase();
    await pumpPage(
      tester,
      const VoicePickerPage(prayer: AlertPrayer.dhuhr),
      db: db,
    );
    expect(find.text('Shia wording'), findsNWidgets(2));
    expect(find.textContaining('Shia wording'), findsWidgets);
    expect(find.byKey(const Key('select-voice-1-shia')), findsOneWidget);
    await unmount(tester, db);
  });

  testWidgets('the Fajr version says it includes the Fajr phrase', (
    tester,
  ) async {
    tall(tester);
    final db = await newDatabase();
    await pumpPage(
      tester,
      const VoicePickerPage(prayer: AlertPrayer.fajr),
      db: db,
    );
    expect(find.textContaining('as-salatu khayrun min an-nawm'), findsWidgets);
    await unmount(tester, db);
  });

  testWidgets('each preview plays its own recording', (tester) async {
    tall(tester);
    final db = await newDatabase();
    final harness = await pumpPage(
      tester,
      const VoicePickerPage(prayer: AlertPrayer.fajr),
      db: db,
    );
    for (final key in [
      'preview-voice-1-standard',
      'preview-voice-1-fajr',
      'preview-voice-2-shia',
    ]) {
      await tester.tap(find.byKey(Key(key)));
      await settle(tester);
    }
    expect(harness.player.loaded, [
      'assets/audio/voice-1-standard.m4a',
      'assets/audio/voice-1-fajr.m4a',
      'assets/audio/voice-2-shia.m4a',
    ]);
    await unmount(tester, db);
  });

  testWidgets('a preview does not count as an alert being played', (
    tester,
  ) async {
    tall(tester);
    final db = await newDatabase();
    await pumpPage(
      tester,
      const VoicePickerPage(prayer: AlertPrayer.fajr),
      db: db,
    );
    await tester.tap(find.byKey(const Key('preview-voice-1-standard')));
    await settle(tester);
    final rows = await tester.runAsync(DriftAlertLogRepository(db).recent);
    expect(rows, isEmpty);
    await unmount(tester, db);
  });

  testWidgets('a recording that cannot play shows a plain message', (
    tester,
  ) async {
    tall(tester);
    final db = await newDatabase();
    final player = FakePlayer()..failLoad = true;
    await pumpPage(
      tester,
      const VoicePickerPage(prayer: AlertPrayer.fajr),
      db: db,
      player: player,
    );
    await tester.tap(find.byKey(const Key('preview-voice-1-standard')));
    await settle(tester);
    expect(find.text('This recording could not be played.'), findsOneWidget);
    await unmount(tester, db);
  });

  testWidgets('choosing a voice and the Shia wording saves both', (
    tester,
  ) async {
    tall(tester);
    final db = await newDatabase();
    await pumpPage(
      tester,
      const VoicePickerPage(prayer: AlertPrayer.maghrib),
      db: db,
    );
    await tester.tap(find.byKey(const Key('select-voice-2-shia')));
    await settle(tester);
    final all = await tester.runAsync(
      DriftAlertPreferenceRepository(db).getAll,
    );
    final maghrib = all!.firstWhere((p) => p.prayer == AlertPrayer.maghrib);
    expect(maghrib.voiceId, 'voice-2');
    expect(maghrib.variant, AzaanVariant.shia);
    final fajr = all.firstWhere((p) => p.prayer == AlertPrayer.fajr);
    expect(fajr.variant, AzaanVariant.standard);
    await unmount(tester, db);
  });

  testWidgets('survives the largest text size in Urdu', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final db = await newDatabase(language: AppLanguage.ur);
    await pumpPage(
      tester,
      const VoicePickerPage(prayer: AlertPrayer.fajr),
      db: db,
      language: AppLanguage.ur,
      textScale: 2.0,
    );
    expect(tester.takeException(), isNull);
    await unmount(tester, db);
  });
}
