import 'package:deen_mobile/domain/entities/enums.dart';
import 'package:deen_mobile/platform/alert_scheduler.dart';
import 'package:deen_mobile/ui/alerts/alert_options_page.dart';
import 'package:deen_mobile/ui/alerts/alert_settings_page.dart';
import 'package:deen_mobile/ui/alerts/voice_picker_page.dart';
import 'package:deen_mobile/ui/reliability/reliability_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../alerts/support/fakes.dart';

/// Golden images of the Story 3 screens in the four shipped languages (two
/// right to left), plus the largest text size. Screens that show a time are
/// left out on purpose: times follow the machine's time zone, so their
/// pictures would differ from one machine to another.
///
/// Regenerate after an intended change with
/// `flutter test --update-goldens test/ui/goldens/alerts`.
void main() {
  const phone = Size(360, 1400);

  void phoneView(WidgetTester tester, {Size size = phone}) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  final broken = FakeAlertScheduler(
    permissions: const AlertPermissions(
      platform: AlertPlatform.android,
      notificationsGranted: false,
      exactAlarmGranted: false,
      batteryOptimizationIgnored: false,
    ),
  );

  for (final language in AppLanguage.values) {
    testWidgets('Reliability check problems in ${language.name}', (
      tester,
    ) async {
      phoneView(tester);
      final db = await newDatabase(language: language);
      await pumpPage(
        tester,
        const ReliabilityPage(),
        db: db,
        scheduler: broken,
        language: language,
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/reliability_${language.name}.png'),
      );
      await unmount(tester, db);
    });

    testWidgets('Alert settings in ${language.name}', (tester) async {
      phoneView(tester, size: const Size(360, 2600));
      final db = await newDatabase(language: language);
      await pumpPage(
        tester,
        const AlertSettingsPage(),
        db: db,
        language: language,
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/alert_settings_${language.name}.png'),
      );
      await unmount(tester, db);
    });

    testWidgets('Voice picker in ${language.name}', (tester) async {
      phoneView(tester, size: const Size(360, 1600));
      final db = await newDatabase(language: language);
      await pumpPage(
        tester,
        const VoicePickerPage(prayer: AlertPrayer.fajr),
        db: db,
        language: language,
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/voice_picker_${language.name}.png'),
      );
      await unmount(tester, db);
    });
  }

  testWidgets('Alert options in Arabic', (tester) async {
    phoneView(tester, size: const Size(360, 3200));
    final db = await newDatabase(language: AppLanguage.ar);
    await pumpPage(
      tester,
      const AlertOptionsPage(),
      db: db,
      language: AppLanguage.ar,
    );
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/alert_options_ar.png'),
    );
    await unmount(tester, db);
  });

  testWidgets('Reliability check at 2.0x text in Urdu', (tester) async {
    phoneView(tester, size: const Size(360, 2400));
    final db = await newDatabase(language: AppLanguage.ur);
    await pumpPage(
      tester,
      const ReliabilityPage(),
      db: db,
      scheduler: broken,
      language: AppLanguage.ur,
      textScale: 2.0,
    );
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/reliability_ur_2x.png'),
    );
    await unmount(tester, db);
  });
}
