import 'package:deen_mobile/app/app.dart';
import 'package:deen_mobile/app/providers.dart';
import 'package:deen_mobile/data/repositories/drift_settings_repository.dart';
import 'package:deen_mobile/domain/entities/enums.dart';
import 'package:deen_mobile/ui/settings/appearance_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../adhkar/harness.dart';

void main() {
  testWidgets('asks to finish setup when no settings exist', (tester) async {
    final db = await openTestDatabase();
    await pumpPage(tester, db, const AppearancePage());
    expect(find.byKey(const Key('appearance-needs-setup')), findsOneWidget);
    expect(find.byKey(const Key('appearance-theme')), findsNothing);
    await unmount(tester, db);
  });

  testWidgets('saves the theme choice through the settings repository', (
    tester,
  ) async {
    final db = await openTestDatabase(language: AppLanguage.en);
    await pumpPage(tester, db, const AppearancePage());
    await tester.tap(find.text('Dark'));
    await settle(tester);
    final saved = (await DriftSettingsRepository(db).get())!;
    expect(saved.theme, ThemePreference.dark);
    expect(saved.language, AppLanguage.en, reason: 'other fields untouched');
    await unmount(tester, db);
  });

  testWidgets('saves high contrast', (tester) async {
    final db = await openTestDatabase(language: AppLanguage.en);
    await pumpPage(tester, db, const AppearancePage());
    await tester.tap(find.byKey(const Key('appearance-high-contrast')));
    await settle(tester);
    expect((await DriftSettingsRepository(db).get())!.highContrast, isTrue);
    await unmount(tester, db);
  });

  testWidgets('larger and smaller text move in 10 percent steps and stop at '
      'the limits', (tester) async {
    final db = await openTestDatabase(language: AppLanguage.en);
    await pumpPage(tester, db, const AppearancePage());
    final repo = DriftSettingsRepository(db);

    await tester.tap(find.byKey(const Key('appearance-text-larger')));
    await settle(tester);
    expect((await repo.get())!.textScale, closeTo(1.1, 1e-9));
    expect(find.text('110%'), findsWidgets);

    for (var i = 0; i < 12; i++) {
      await tester.tap(find.byKey(const Key('appearance-text-larger')));
      await settle(tester);
    }
    expect((await repo.get())!.textScale, 2.0);
    expect(
      tester
          .widget<IconButton>(find.byKey(const Key('appearance-text-larger')))
          .onPressed,
      isNull,
    );

    for (var i = 0; i < 20; i++) {
      final smaller = tester.widget<IconButton>(
        find.byKey(const Key('appearance-text-smaller')),
      );
      if (smaller.onPressed == null) break;
      await tester.tap(find.byKey(const Key('appearance-text-smaller')));
      await settle(tester);
    }
    expect((await repo.get())!.textScale, closeTo(0.8, 1e-9));
    await unmount(tester, db);
  });

  testWidgets('dragging the slider saves a snapped size in range', (
    tester,
  ) async {
    final db = await openTestDatabase(language: AppLanguage.en);
    await pumpPage(tester, db, const AppearancePage());
    await tester.drag(
      find.byKey(const Key('appearance-text-size')),
      const Offset(80, 0),
    );
    await settle(tester);
    final scale = (await DriftSettingsRepository(db).get())!.textScale;
    expect(scale, greaterThan(1.0));
    expect(scale, lessThanOrEqualTo(2.0));
    expect((scale * 10 - (scale * 10).round()).abs(), lessThan(1e-9));
    await unmount(tester, db);
  });

  testWidgets('the whole app follows: theme, contrast and text size', (
    tester,
  ) async {
    final db = await openTestDatabase(language: AppLanguage.en);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const DeenApp(home: Scaffold(key: Key('home-page'))),
      ),
    );
    await settle(tester);
    final home = find.byKey(const Key('home-page'));
    Navigator.of(tester.element(home))
        .push(MaterialPageRoute<void>(builder: (_) => const AppearancePage()));
    await settle(tester);

    await tester.tap(find.text('Dark'));
    await settle(tester);
    await tester.tap(find.byKey(const Key('appearance-text-larger')));
    await settle(tester);

    final context = tester.element(find.byKey(const Key('appearance-page')));
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(MediaQuery.textScalerOf(context).scale(10), closeTo(11, 1e-9));
    await unmount(tester, db);
  });

  for (final language in AppLanguage.values) {
    testWidgets('lays out in ${language.name} at 2.0x text without overflow', (
      tester,
    ) async {
      useSmallPhone(tester);
      final db = await openTestDatabase(language: language, textScale: 2.0);
      await pumpPage(tester, db, const AppearancePage());
      expect(tester.takeException(), isNull);
      final context = tester.element(find.byKey(const Key('appearance-page')));
      expect(
        Directionality.of(context),
        language.isRtl ? TextDirection.rtl : TextDirection.ltr,
      );
      await unmount(tester, db);
    });
  }

  testWidgets('controls are labeled, large enough and not color-only', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final db = await openTestDatabase(language: AppLanguage.en);
    await pumpPage(tester, db, const AppearancePage());
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    expect(
      tester
          .getSemantics(find.byKey(const Key('appearance-text-larger')))
          .tooltip,
      'Larger text',
    );
    // The selected theme carries a check mark besides its fill.
    expect(find.byIcon(Icons.check), findsOneWidget);
    await unmount(tester, db);
    handle.dispose();
  });
}
