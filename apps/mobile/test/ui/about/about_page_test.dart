import 'package:deen_mobile/domain/entities/enums.dart';
import 'package:deen_mobile/ui/about/about_page.dart';
import 'package:deen_mobile/app/providers/data_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../adhkar/harness.dart';

void main() {
  testWidgets('states that no data is collected and shows the privacy '
      'placeholder', (tester) async {
    final db = await openTestDatabase();
    await pumpPage(tester, db, const AboutPage());
    expect(find.byKey(const Key('about-no-data')), findsOneWidget);
    expect(find.textContaining('Deen App collects no data'), findsOneWidget);
    expect(
      find.textContaining('privacy policy will be published'),
      findsOneWidget,
    );
    expect(find.text('Version 0.1.0'), findsOneWidget);
    await unmount(tester, db);
  });

  testWidgets('shows the policy address once it is known', (tester) async {
    final db = await openTestDatabase();
    await pumpPage(
      tester,
      db,
      const AboutPage(),
      overrides: [
        privacyPolicyUrlProvider.overrideWithValue('https://example.test/p'),
      ],
    );
    expect(find.textContaining('https://example.test/p'), findsOneWidget);
    await unmount(tester, db);
  });

  testWidgets('shows the GeoNames, font and Unicode attributions', (
    tester,
  ) async {
    final db = await openTestDatabase();
    await pumpPage(tester, db, const AboutPage());
    await tester.scrollUntilVisible(
      find.textContaining('Unicode License v3'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('Contains data from GeoNames'), findsOneWidget);
    expect(find.textContaining('licensed under CC BY 4.0'), findsOneWidget);
    expect(
      find.textContaining('https://creativecommons.org/licenses/by/4.0/'),
      findsOneWidget,
    );
    expect(find.textContaining('SIL Open Font License'), findsOneWidget);
    expect(find.textContaining('Amiri'), findsOneWidget);
    expect(find.textContaining('Unicode License v3'), findsOneWidget);
    await unmount(tester, db);
  });

  testWidgets('opens the open-source license page', (tester) async {
    final db = await openTestDatabase();
    await pumpPage(tester, db, const AboutPage());
    await tester.tap(find.byKey(const Key('about-licenses')));
    await settle(tester);
    expect(find.byType(LicensePage), findsOneWidget);
    await unmount(tester, db);
  });

  testWidgets('lists content credits and opens them', (tester) async {
    final db = await openTestDatabase();
    await pumpPage(tester, db, const AboutPage(), assets: fakePackAssets());
    await tester.scrollUntilVisible(
      find.byKey(const Key('about-content-credits')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Texts listed: 4'), findsOneWidget);
    await tester.tap(find.byKey(const Key('about-content-credits')));
    await settle(tester);
    expect(find.byKey(const Key('content-credits-page')), findsOneWidget);
    expect(find.byKey(const Key('credit-m1')), findsOneWidget);
    await unmount(tester, db);
  });

  testWidgets('shows zero listed texts for an empty pack', (tester) async {
    final db = await openTestDatabase();
    await pumpPage(tester, db, const AboutPage());
    await tester.scrollUntilVisible(
      find.byKey(const Key('about-content-credits')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Texts listed: 0'), findsOneWidget);
    await unmount(tester, db);
  });

  for (final language in AppLanguage.values) {
    testWidgets('lays out in ${language.name} at 2.0x text without overflow', (
      tester,
    ) async {
      useSmallPhone(tester);
      final db = await openTestDatabase(language: language, textScale: 2.0);
      await pumpPage(tester, db, const AboutPage(), assets: fakePackAssets());
      expect(tester.takeException(), isNull);
      final context = tester.element(find.byKey(const Key('about-page')));
      expect(
        Directionality.of(context),
        language.isRtl ? TextDirection.rtl : TextDirection.ltr,
      );
      // The English license wording keeps its own direction.
      await tester.scrollUntilVisible(
        find.textContaining('Contains data from GeoNames'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      final geo = tester.element(
        find.textContaining('Contains data from GeoNames'),
      );
      expect(Directionality.of(geo), TextDirection.ltr);
      expect(tester.takeException(), isNull);
      await unmount(tester, db);
    });
  }

  testWidgets('controls are labeled and large enough', (tester) async {
    final handle = tester.ensureSemantics();
    final db = await openTestDatabase();
    await pumpPage(tester, db, const AboutPage());
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await unmount(tester, db);
    handle.dispose();
  });
}
