import 'package:deen_mobile/data/repositories/drift_alert_preference_repository.dart';
import 'package:deen_mobile/domain/entities/enums.dart';
import 'package:deen_mobile/domain/entities/settings.dart';
import 'package:deen_mobile/platform/alert_scheduler.dart';
import 'package:deen_mobile/ui/alerts/alert_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

AlertPermissions _androidPermissions({bool exact = true}) => AlertPermissions(
  platform: AlertPlatform.android,
  notificationsGranted: true,
  exactAlarmGranted: exact,
);

void main() {
  testWidgets('lists the five prayers, each with the five choices', (
    tester,
  ) async {
    // A tall screen builds the whole lazy list.
    tester.view.physicalSize = const Size(800, 6000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final db = await newDatabase();
    await pumpPage(tester, const AlertSettingsPage(), db: db);
    for (final prayer in ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha']) {
      expect(find.byKey(Key('prayer-card-$prayer')), findsOneWidget);
      for (final type in AlertType.values) {
        expect(
          find.byKey(Key('type-$prayer-${type.name}'), skipOffstage: false),
          findsOneWidget,
        );
      }
    }
    await unmount(tester, db);
  });

  testWidgets('every prayer starts as a short tone', (tester) async {
    final db = await newDatabase();
    await pumpPage(tester, const AlertSettingsPage(), db: db);
    final repo = DriftAlertPreferenceRepository(db);
    final all = await tester.runAsync(repo.getAll);
    expect(all!.every((p) => p.type == AlertType.shortTone), isTrue);
    final tile = tester.widget<RadioListTile<AlertType>>(
      find.byKey(const Key('type-fajr-shortTone')),
    );
    expect(tile.value, AlertType.shortTone);
    await unmount(tester, db);
  });

  testWidgets('choosing a type saves it', (tester) async {
    final db = await newDatabase();
    await pumpPage(
      tester,
      const AlertSettingsPage(),
      db: db,
      scheduler: FakeAlertScheduler(platform: AlertPlatform.ios),
    );
    await tester.ensureVisible(find.byKey(const Key('type-fajr-vibrate')));
    await tester.tap(find.byKey(const Key('type-fajr-vibrate')));
    await settle(tester);
    final all = await tester.runAsync(
      DriftAlertPreferenceRepository(db).getAll,
    );
    expect(all!.first.type, AlertType.vibrate);
    await unmount(tester, db);
  });

  testWidgets('a full Azaan offers its voice; others do not', (tester) async {
    final db = await newDatabase();
    await pumpPage(
      tester,
      const AlertSettingsPage(),
      db: db,
      scheduler: FakeAlertScheduler(platform: AlertPlatform.ios),
    );
    expect(find.byKey(const Key('voice-tile-fajr')), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('type-fajr-fullAzaan')));
    await tester.tap(find.byKey(const Key('type-fajr-fullAzaan')));
    await settle(tester);
    expect(find.byKey(const Key('voice-tile-fajr')), findsOneWidget);
    expect(find.text('Voice 1, Standard'), findsOneWidget);
    await unmount(tester, db);
  });

  testWidgets('ignore quiet hours is only offered for audible alerts', (
    tester,
  ) async {
    final db = await newDatabase();
    await tester.runAsync(
      () => DriftAlertPreferenceRepository(db).save(
        const AlertPreference(prayer: AlertPrayer.dhuhr, type: AlertType.off),
      ),
    );
    await pumpPage(tester, const AlertSettingsPage(), db: db);
    expect(find.byKey(const Key('ignore-quiet-fajr')), findsOneWidget);
    expect(find.byKey(const Key('ignore-quiet-dhuhr')), findsNothing);
    await unmount(tester, db);
  });

  testWidgets('the ignore quiet hours switch is off by default and saves', (
    tester,
  ) async {
    final db = await newDatabase();
    await pumpPage(tester, const AlertSettingsPage(), db: db);
    final switchTile = tester.widget<SwitchListTile>(
      find.byKey(const Key('ignore-quiet-fajr')),
    );
    expect(switchTile.value, isFalse);
    await tester.tap(find.byKey(const Key('ignore-quiet-fajr')));
    await settle(tester);
    final all = await tester.runAsync(
      DriftAlertPreferenceRepository(db).getAll,
    );
    expect(all!.first.ignoreQuietHours, isTrue);
    await unmount(tester, db);
  });

  testWidgets('on Android without exact alarms, an audible choice asks first', (
    tester,
  ) async {
    final db = await newDatabase();
    final scheduler = FakeAlertScheduler(
      permissions: _androidPermissions(exact: false),
    );
    await tester.runAsync(
      () => DriftAlertPreferenceRepository(db).save(
        const AlertPreference(prayer: AlertPrayer.fajr, type: AlertType.off),
      ),
    );
    await pumpPage(
      tester,
      const AlertSettingsPage(),
      db: db,
      scheduler: scheduler,
    );
    await tester.ensureVisible(find.byKey(const Key('type-fajr-fullAzaan')));
    await tester.tap(find.byKey(const Key('type-fajr-fullAzaan')));
    await settle(tester);
    expect(find.byKey(const Key('exact-alarm-dialog')), findsOneWidget);

    // Refusing still saves the choice, and the user is told timing may vary.
    await tester.tap(find.byKey(const Key('exact-alarm-skip')));
    await settle(tester);
    expect(find.byKey(const Key('exact-alarm-dialog')), findsNothing);
    expect(find.textContaining('timing may be less precise'), findsOneWidget);
    final all = await tester.runAsync(
      DriftAlertPreferenceRepository(db).getAll,
    );
    expect(all!.first.type, AlertType.fullAzaan);
    await unmount(tester, db);
  });

  testWidgets('choosing silent never asks about exact alarms', (tester) async {
    final db = await newDatabase();
    await pumpPage(
      tester,
      const AlertSettingsPage(),
      db: db,
      scheduler: FakeAlertScheduler(
        permissions: _androidPermissions(exact: false),
      ),
    );
    await tester.ensureVisible(find.byKey(const Key('type-fajr-silent')));
    await tester.tap(find.byKey(const Key('type-fajr-silent')));
    await settle(tester);
    expect(find.byKey(const Key('exact-alarm-dialog')), findsNothing);
    await unmount(tester, db);
  });

  testWidgets('survives the largest text size in Arabic', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final db = await newDatabase(language: AppLanguage.ar);
    await pumpPage(
      tester,
      const AlertSettingsPage(),
      db: db,
      language: AppLanguage.ar,
      textScale: 2.0,
    );
    expect(tester.takeException(), isNull);
    expect(find.text('تنبيهات الصلاة'), findsOneWidget);
    await unmount(tester, db);
  });
}
