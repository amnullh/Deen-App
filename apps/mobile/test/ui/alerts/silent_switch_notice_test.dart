import 'package:deen_mobile/data/repositories/drift_alert_preference_repository.dart';
import 'package:deen_mobile/domain/entities/enums.dart';
import 'package:deen_mobile/domain/entities/settings.dart';
import 'package:deen_mobile/platform/alert_scheduler.dart';
import 'package:deen_mobile/ui/alerts/silent_switch_notice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  testWidgets('shows on iPhone with the three facts', (tester) async {
    final db = await newDatabase();
    await pumpPage(
      tester,
      const Scaffold(body: SilentSwitchNotice()),
      db: db,
      scheduler: FakeAlertScheduler(platform: AlertPlatform.ios),
    );
    expect(find.byKey(const Key('silent-switch-notice')), findsOneWidget);
    expect(find.textContaining('muted'), findsOneWidget);
    expect(find.textContaining('plays the full Azaan'), findsOneWidget);
    expect(find.text('Use vibration for my alerts'), findsOneWidget);
    await unmount(tester, db);
  });

  testWidgets('never shows on Android', (tester) async {
    final db = await newDatabase();
    await pumpPage(tester, const Scaffold(body: SilentSwitchNotice()), db: db);
    expect(find.byKey(const Key('silent-switch-notice')), findsNothing);
    await unmount(tester, db);
  });

  testWidgets('is one-time: "Got it" hides it for good', (tester) async {
    final db = await newDatabase();
    await pumpPage(
      tester,
      const Scaffold(body: SilentSwitchNotice()),
      db: db,
      scheduler: FakeAlertScheduler(platform: AlertPlatform.ios),
    );
    await tester.tap(find.byKey(const Key('silent-switch-got-it')));
    await settle(tester);
    expect(find.byKey(const Key('silent-switch-notice')), findsNothing);
    final global = await tester.runAsync(
      DriftAlertPreferenceRepository(db).getGlobal,
    );
    expect(global!.silentSwitchExplained, isTrue);
    await unmount(tester, db);
  });

  testWidgets('"Use vibration" switches audible prayers only', (tester) async {
    final db = await newDatabase();
    await tester.runAsync(() async {
      final repo = DriftAlertPreferenceRepository(db);
      await repo.save(
        const AlertPreference(prayer: AlertPrayer.dhuhr, type: AlertType.off),
      );
      await repo.save(
        const AlertPreference(
          prayer: AlertPrayer.asr,
          type: AlertType.fullAzaan,
        ),
      );
    });
    await pumpPage(
      tester,
      const Scaffold(body: SilentSwitchNotice()),
      db: db,
      scheduler: FakeAlertScheduler(platform: AlertPlatform.ios),
    );
    await tester.tap(find.byKey(const Key('silent-switch-vibrate')));
    await settle(tester);
    final all = (await tester.runAsync(
      DriftAlertPreferenceRepository(db).getAll,
    ))!;
    final byPrayer = {for (final p in all) p.prayer: p.type};
    expect(byPrayer[AlertPrayer.fajr], AlertType.vibrate);
    expect(byPrayer[AlertPrayer.dhuhr], AlertType.off);
    expect(byPrayer[AlertPrayer.asr], AlertType.vibrate);
    expect(find.byKey(const Key('silent-switch-notice')), findsNothing);
    await unmount(tester, db);
  });
}
