import 'package:deen_mobile/data/repositories/drift_adhkar_repository.dart';
import 'package:deen_mobile/domain/adhkar/adhkar_reminder.dart';
import 'package:deen_mobile/domain/entities/enums.dart';
import 'package:deen_mobile/ui/adhkar/bookmarks_page.dart';
import 'package:deen_mobile/ui/adhkar/collections_page.dart';
import 'package:deen_mobile/ui/adhkar/content_credits_page.dart';
import 'package:deen_mobile/ui/adhkar/entry_page.dart';
import 'package:deen_mobile/ui/adhkar/reminder_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

Finder _text(String text) => find.text(text);

Text _arabicText(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('adhkar-arabic')));

void main() {
  group('collections', () {
    testWidgets('an empty pack shows a friendly empty state', (tester) async {
      final db = await openTestDatabase();
      await pumpPage(tester, db, const AdhkarCollectionsPage());
      expect(find.byKey(const Key('adhkar-empty')), findsOneWidget);
      expect(_text('Adhkar are not available yet'), findsOneWidget);
      expect(find.byKey(const Key('adhkar-bookmarks-entry')), findsOneWidget);
      expect(find.byKey(const Key('adhkar-reminders-entry')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await unmount(tester, db);
    });

    testWidgets('a broken pack shows an error message, not a crash', (
      tester,
    ) async {
      final db = await openTestDatabase();
      await pumpPage(
        tester,
        db,
        const AdhkarCollectionsPage(),
        assets: FakeAssets({'assets/adhkar/bad.json': '{ nope'}),
      );
      expect(find.byKey(const Key('adhkar-empty')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await unmount(tester, db);
    });

    testWidgets('lists collections with their entry counts', (tester) async {
      final db = await openTestDatabase();
      await pumpPage(
        tester,
        db,
        const AdhkarCollectionsPage(),
        assets: fakePackAssets(),
      );
      expect(_text('Morning adhkar'), findsOneWidget);
      expect(_text('Evening adhkar'), findsOneWidget);
      expect(_text('Entries: 3'), findsOneWidget);
      expect(_text('Entries: 1'), findsOneWidget);
      await tester.tap(find.byKey(const Key('adhkar-collection-morning')));
      await settle(tester);
      expect(find.byKey(const Key('adhkar-entry-page')), findsOneWidget);
      await unmount(tester, db);
    });
  });

  group('entry page', () {
    testWidgets('shows Arabic in Amiri, transliteration, translation, repeat '
        'count and source', (tester) async {
      final db = await openTestDatabase();
      await pumpPage(
        tester,
        db,
        const AdhkarEntryPage(collectionId: 'morning'),
        assets: fakePackAssets(),
      );
      final arabic = _arabicText(tester);
      expect(arabic.data, 'FAKE ARABIC m1');
      expect(arabic.style?.fontFamily, 'Amiri');
      expect(arabic.textDirection, TextDirection.rtl);
      expect(_text('FAKE TRANSLIT m1'), findsOneWidget);
      expect(_text('FAKE ENGLISH m1'), findsOneWidget);
      expect(_text('Translation'), findsOneWidget);
      expect(_text('Repetitions: 3'), findsOneWidget);
      expect(_text('Source: FAKE REF m1'), findsOneWidget);
      expect(_text('Entry 1 of 3'), findsOneWidget);
      await unmount(tester, db);
    });

    testWidgets('omits sections the pack does not provide', (tester) async {
      final db = await openTestDatabase();
      await pumpPage(
        tester,
        db,
        const AdhkarEntryPage(collectionId: 'evening'),
        assets: FakeAssets({
          'assets/adhkar/a.json': '''
{"collections":[{"id":"evening","entries":[{"id":"v1","arabic":"FAKE ARABIC v1",
"repeatCount":1,"reference":"r","sourceId":"s","licenseId":"l","reviewer":"x","reviewedOn":"d"}]}]}''',
        }),
      );
      expect(find.byKey(const Key('adhkar-transliteration')), findsNothing);
      expect(find.byKey(const Key('adhkar-translation')), findsNothing);
      expect(find.byKey(const Key('adhkar-arabic')), findsOneWidget);
      await unmount(tester, db);
    });

    testWidgets('counts taps, shows progress and finishes a session', (
      tester,
    ) async {
      final db = await openTestDatabase();
      await pumpPage(
        tester,
        db,
        const AdhkarEntryPage(collectionId: 'morning'),
        assets: fakePackAssets(),
      );
      expect(_text('0 of 3 entries complete'), findsOneWidget);
      expect(_text('Tap to count: 0 of 3'), findsOneWidget);

      Future<void> tapCount() async {
        await tester.tap(find.byKey(const Key('adhkar-count')));
        await settle(tester);
      }

      await tapCount();
      expect(_text('Tap to count: 1 of 3'), findsOneWidget);
      await tapCount();
      await tapCount();
      expect(_text('Done'), findsOneWidget);
      expect(_text('1 of 3 entries complete'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('adhkar-count')))
            .onPressed,
        isNull,
        reason: 'a finished entry cannot be counted further',
      );

      await tester.tap(find.byKey(const Key('adhkar-next')));
      await settle(tester);
      expect(_text('Entry 2 of 3'), findsOneWidget);
      await tapCount();
      await tester.tap(find.byKey(const Key('adhkar-next')));
      await settle(tester);
      await tapCount();
      await tapCount();

      expect(_text('3 of 3 entries complete'), findsOneWidget);
      expect(find.byKey(const Key('adhkar-session-complete')), findsOneWidget);
      expect(find.byKey(const Key('adhkar-count')), findsNothing);

      await tester.tap(find.byKey(const Key('adhkar-restart')));
      await settle(tester);
      expect(_text('0 of 3 entries complete'), findsOneWidget);
      expect(find.byKey(const Key('adhkar-session-complete')), findsNothing);
      await unmount(tester, db);
    });

    testWidgets('undo takes back the last count', (tester) async {
      final db = await openTestDatabase();
      await pumpPage(
        tester,
        db,
        const AdhkarEntryPage(collectionId: 'morning'),
        assets: fakePackAssets(),
      );
      expect(
        tester
            .widget<IconButton>(find.byKey(const Key('adhkar-undo')))
            .onPressed,
        isNull,
      );
      await tester.tap(find.byKey(const Key('adhkar-count')));
      await settle(tester);
      await tester.tap(find.byKey(const Key('adhkar-undo')));
      await settle(tester);
      expect(_text('Tap to count: 0 of 3'), findsOneWidget);
      await unmount(tester, db);
    });

    testWidgets('progress is saved and resumed when the page is reopened', (
      tester,
    ) async {
      final db = await openTestDatabase();
      final assets = fakePackAssets();
      await pumpPage(
        tester,
        db,
        const AdhkarEntryPage(collectionId: 'morning'),
        assets: assets,
      );
      await tester.tap(find.byKey(const Key('adhkar-count')));
      await settle(tester);
      await tester.tap(find.byKey(const Key('adhkar-count')));
      await settle(tester);

      // Reopen with a fresh widget tree over the same database.
      await tester.pumpWidget(const SizedBox());
      await pumpPage(
        tester,
        db,
        const AdhkarEntryPage(collectionId: 'morning'),
        assets: assets,
      );
      expect(_text('Tap to count: 2 of 3'), findsOneWidget);
      await unmount(tester, db);
    });

    testWidgets('bookmarks an entry and lists it on the bookmarks page', (
      tester,
    ) async {
      final db = await openTestDatabase();
      final assets = fakePackAssets();
      await pumpPage(
        tester,
        db,
        const AdhkarEntryPage(collectionId: 'morning'),
        assets: assets,
      );
      expect(find.byTooltip('Add bookmark'), findsOneWidget);
      await tester.tap(find.byKey(const Key('adhkar-bookmark')));
      await settle(tester);
      expect(find.byTooltip('Remove bookmark'), findsOneWidget);
      expect(
        (await DriftAdhkarBookmarkRepository(db).getAll()).single.entryId,
        'm1',
      );

      await tester.pumpWidget(const SizedBox());
      await pumpPage(tester, db, const AdhkarBookmarksPage(), assets: assets);
      expect(find.byKey(const Key('adhkar-bookmark-m1')), findsOneWidget);
      await tester.tap(find.byKey(const Key('adhkar-bookmark-m1')));
      await settle(tester);
      expect(find.byKey(const Key('adhkar-entry-page')), findsOneWidget);
      expect(_arabicText(tester).data, 'FAKE ARABIC m1');
      await unmount(tester, db);
    });

    testWidgets('bookmarks page has a friendly empty state', (tester) async {
      final db = await openTestDatabase();
      await pumpPage(
        tester,
        db,
        const AdhkarBookmarksPage(),
        assets: fakePackAssets(),
      );
      expect(find.byKey(const Key('adhkar-bookmarks-empty')), findsOneWidget);
      await unmount(tester, db);
    });

    testWidgets('an unknown collection is a plain message', (tester) async {
      final db = await openTestDatabase();
      await pumpPage(
        tester,
        db,
        const AdhkarEntryPage(collectionId: 'nope'),
        assets: fakePackAssets(),
      );
      expect(_text('This collection is not available.'), findsOneWidget);
      await unmount(tester, db);
    });
  });

  group('reminder settings', () {
    testWidgets('enables, retimes and re-anchors, saving each change', (
      tester,
    ) async {
      final db = await openTestDatabase();
      await pumpPage(tester, db, const AdhkarReminderSettingsPage());
      final repo = DriftAdhkarReminderRepository(db);

      expect(_text('30 min after Fajr'), findsOneWidget);
      expect(_text('At Asr time'), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('adhkar-reminder-morning-enabled')),
      );
      await settle(tester);
      expect((await repo.getAll())[0].enabled, isTrue);

      await tester.tap(
        find.byKey(const Key('adhkar-reminder-morning-earlier')),
      );
      await settle(tester);
      expect(_text('25 min after Fajr'), findsOneWidget);
      expect((await repo.getAll())[0].offsetMinutes, 25);

      await tester.tap(find.text('Maghrib'));
      await settle(tester);
      final evening = (await repo.getAll())[1];
      expect(evening.anchor, ReminderAnchor.maghrib);

      await tester.tap(
        find.byKey(const Key('adhkar-reminder-evening-earlier')),
      );
      await settle(tester);
      expect(_text('5 min before Maghrib'), findsOneWidget);
      expect((await repo.getAll())[1].offsetMinutes, -5);
      await unmount(tester, db);
    });

    testWidgets('the morning reminder offers only Fajr', (tester) async {
      final db = await openTestDatabase();
      await pumpPage(tester, db, const AdhkarReminderSettingsPage());
      expect(_text('Morning reminders follow Fajr.'), findsOneWidget);
      expect(
        find.byKey(const Key('adhkar-reminder-morning-anchor')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('adhkar-reminder-evening-anchor')),
        findsOneWidget,
      );
      await unmount(tester, db);
    });

    testWidgets('stops at the offset limits', (tester) async {
      final db = await openTestDatabase();
      await DriftAdhkarReminderRepository(db).save(
        AdhkarReminder.defaultFor(AdhkarReminderKind.morning)
            .copyWith(offsetMinutes: AdhkarReminder.maxOffsetMinutes),
      );
      await pumpPage(tester, db, const AdhkarReminderSettingsPage());
      expect(
        tester
            .widget<IconButton>(
              find.byKey(const Key('adhkar-reminder-morning-later')),
            )
            .onPressed,
        isNull,
      );
      await unmount(tester, db);
    });
  });

  group('credits', () {
    testWidgets('lists the source, license and reviewer of every text', (
      tester,
    ) async {
      final db = await openTestDatabase();
      await pumpPage(
        tester,
        db,
        const ContentCreditsPage(),
        assets: fakePackAssets(),
      );
      expect(find.byKey(const Key('credit-m1')), findsOneWidget);
      expect(find.byKey(const Key('credit-v1')), findsOneWidget);
      expect(_text('Entry 1: FAKE REF m1'), findsOneWidget);
      expect(
        find.text('Source: fake-source. License: fake-license.'),
        findsNWidgets(4),
      );
      expect(
        find.text('Reviewed by Fake Reviewer on 2000-01-01.'),
        findsNWidgets(4),
      );
      await unmount(tester, db);
    });

    testWidgets('an empty pack says so plainly', (tester) async {
      final db = await openTestDatabase();
      await pumpPage(tester, db, const ContentCreditsPage());
      expect(find.byKey(const Key('content-credits-empty')), findsOneWidget);
      await unmount(tester, db);
    });
  });

  group('languages, direction and text size', () {
    testWidgets('Arabic and Urdu lay out right to left, Indonesian left to '
        'right, each with its own strings', (tester) async {
      final expected = {
        AppLanguage.ar: (TextDirection.rtl, 'الذكر 1 من 3'),
        AppLanguage.ur: (TextDirection.rtl, '3 میں سے ذکر 1'),
        AppLanguage.id: (TextDirection.ltr, 'Zikir 1 dari 3'),
        AppLanguage.en: (TextDirection.ltr, 'Entry 1 of 3'),
      };
      for (final entry in expected.entries) {
        final db = await openTestDatabase(language: entry.key);
        await pumpPage(
          tester,
          db,
          const AdhkarEntryPage(collectionId: 'morning'),
          assets: fakePackAssets(),
        );
        final context = tester.element(
          find.byKey(const Key('adhkar-entry-page')),
        );
        expect(
          Directionality.of(context),
          entry.value.$1,
          reason: '${entry.key}',
        );
        expect(_text(entry.value.$2), findsOneWidget, reason: '${entry.key}');
        await unmount(tester, db);
      }
    });

    testWidgets('shows the English translation with a note when the language '
        'has none', (tester) async {
      final db = await openTestDatabase(language: AppLanguage.ur);
      await pumpPage(
        tester,
        db,
        const AdhkarEntryPage(collectionId: 'morning'),
        assets: fakePackAssets(),
      );
      expect(_text('FAKE ENGLISH m1'), findsOneWidget);
      expect(
        _text('ترجمہ (انگریزی؛ آپ کی زبان میں ابھی دستیاب نہیں)'),
        findsOneWidget,
      );
      await unmount(tester, db);
    });

    for (final language in AppLanguage.values) {
      testWidgets('no overflow at 2.0x text on a small phone in '
          '${language.name}', (tester) async {
        useSmallPhone(tester);
        final db = await openTestDatabase(language: language, textScale: 2.0);
        final assets = fakePackAssets();
        for (final page in <Widget>[
          const AdhkarCollectionsPage(),
          const AdhkarEntryPage(collectionId: 'morning'),
          const AdhkarBookmarksPage(),
          const AdhkarReminderSettingsPage(),
          const ContentCreditsPage(),
        ]) {
          await pumpPage(tester, db, page, assets: assets);
          expect(tester.takeException(), isNull, reason: '${page.runtimeType}');
          await tester.pumpWidget(const SizedBox());
        }
        await unmount(tester, db);
      });
    }
  });

  group('accessibility', () {
    testWidgets('controls are labeled and reachable by touch', (tester) async {
      final handle = tester.ensureSemantics();
      final db = await openTestDatabase();
      final assets = fakePackAssets();
      for (final page in <Widget>[
        const AdhkarCollectionsPage(),
        const AdhkarEntryPage(collectionId: 'morning'),
        const AdhkarReminderSettingsPage(),
      ]) {
        await pumpPage(tester, db, page, assets: assets);
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await tester.pumpWidget(const SizedBox());
      }
      await unmount(tester, db);
      handle.dispose();
    });

    testWidgets('the counting button and progress are read aloud', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final db = await openTestDatabase();
      await pumpPage(
        tester,
        db,
        const AdhkarEntryPage(collectionId: 'morning'),
        assets: fakePackAssets(),
      );
      expect(
        find.bySemanticsLabel(RegExp('Tap to count: 0 of 3')),
        findsWidgets,
      );
      expect(find.bySemanticsLabel('0 of 3 entries complete'), findsOneWidget);
      String tooltipOf(String key) =>
          tester.getSemantics(find.byKey(Key(key))).tooltip;
      expect(tooltipOf('adhkar-bookmark'), 'Add bookmark');
      expect(tooltipOf('adhkar-undo'), 'Undo last count');
      expect(tooltipOf('adhkar-next'), 'Next entry');
      await unmount(tester, db);
      handle.dispose();
    });
  });
}
