import 'dart:convert';

import 'package:deen_mobile/app/providers/data_providers.dart';
import 'package:deen_mobile/data/db/app_database.dart';
import 'package:deen_mobile/data/export/export_file_io.dart';
import 'package:deen_mobile/data/repositories/drift_settings_repository.dart';
import 'package:deen_mobile/domain/delete_all_data.dart';
import 'package:deen_mobile/domain/entities/enums.dart';
import 'package:deen_mobile/ui/settings/data_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../adhkar/harness.dart';

class _FakeSink implements ExportFileSink {
  final List<(String, String, String)> written = [];
  bool dismiss = false;
  bool fail = false;
  int deleteCalls = 0;

  @override
  Future<bool> share(String fileName, String content, {Rect? origin}) async {
    if (fail) throw StateError('no share sheet');
    written.add(('share', fileName, content));
    return !dismiss;
  }

  @override
  Future<bool> saveToDevice(String fileName, String content) async {
    written.add(('save', fileName, content));
    return !dismiss;
  }

  @override
  Future<void> deleteExportFiles() async => deleteCalls++;
}

class _FakeSource implements ImportFileSource {
  _FakeSource(this.text);
  String? text;
  bool throws = false;

  @override
  Future<String?> pickSettingsFile() async {
    if (throws) throw const FormatException('bad');
    return text;
  }
}

class _Native implements NativeAlertFiles {
  int calls = 0;
  @override
  Future<void> deleteSnapshotAndJournal() async => calls++;
}

class _Setup {
  final sink = _FakeSink();
  final source = _FakeSource(null);
  final native = _Native();
  int cancelCalls = 0;
  int rebuildCalls = 0;

  List<dynamic> overrides() => [
    exportFileSinkProvider.overrideWithValue(sink),
    importFileSourceProvider.overrideWithValue(source),
    nativeAlertFilesProvider.overrideWithValue(native),
    cancelAllScheduledAlertsProvider.overrideWithValue(
      () async => cancelCalls++,
    ),
    afterSettingsImportProvider.overrideWithValue(() async => rebuildCalls++),
  ];
}

Future<_Setup> _pump(WidgetTester tester, AppDatabase db) async {
  final setup = _Setup();
  await pumpPage(
    tester,
    db,
    const DataPage(),
    overrides: setup.overrides().cast(),
  );
  return setup;
}

/// Taps a control after scrolling it into view; a status banner above it may
/// have pushed it off screen.
Future<void> _tapVisible(WidgetTester tester, String key) async {
  await tester.ensureVisible(find.byKey(Key(key)));
  await tester.pump();
  await tester.tap(find.byKey(Key(key)));
  await settle(tester);
}

void main() {
  testWidgets('warns in plain words that the file contains the location', (
    tester,
  ) async {
    final db = await openTestDatabase(language: AppLanguage.en);
    await _pump(tester, db);
    expect(find.byKey(const Key('data-export-warning')), findsOneWidget);
    expect(find.textContaining('contains your saved location'), findsOneWidget);
    await unmount(tester, db);
  });

  testWidgets('exports through the share sheet with a dated file name', (
    tester,
  ) async {
    final db = await openTestDatabase(language: AppLanguage.en);
    final setup = await _pump(tester, db);
    await tester.tap(find.byKey(const Key('data-export-share')));
    await settle(tester);
    final (kind, name, content) = setup.sink.written.single;
    expect(kind, 'share');
    expect(name, 'deen-settings-20261021.json');
    final json = jsonDecode(content) as Map<String, Object?>;
    expect(json['format'], 'deen-app-settings');
    expect(find.text('The settings file is ready.'), findsOneWidget);
    await unmount(tester, db);
  });

  testWidgets('saves to the device and reports a cancelled dialog', (
    tester,
  ) async {
    final db = await openTestDatabase(language: AppLanguage.en);
    final setup = await _pump(tester, db);
    setup.sink.dismiss = true;
    await tester.tap(find.byKey(const Key('data-export-save')));
    await settle(tester);
    expect(setup.sink.written.single.$1, 'save');
    expect(find.text('Export cancelled.'), findsOneWidget);
    await unmount(tester, db);
  });

  testWidgets('a failing share sheet is a plain message, not a crash', (
    tester,
  ) async {
    final db = await openTestDatabase(language: AppLanguage.en);
    final setup = await _pump(tester, db);
    setup.sink.fail = true;
    await tester.tap(find.byKey(const Key('data-export-share')));
    await settle(tester);
    expect(
      find.text('The settings file could not be created.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await unmount(tester, db);
  });

  testWidgets('imports a valid file and rebuilds the schedule', (tester) async {
    final db = await openTestDatabase(language: AppLanguage.en);
    final setup = await _pump(tester, db);
    setup.source.text = jsonEncode({
      'format': 'deen-app-settings',
      'version': 1,
      'appearance': {'theme': 'dark', 'textScale': 1.4},
    });
    await tester.tap(find.byKey(const Key('data-import')));
    await settle(tester);
    expect(find.text('Settings imported.'), findsOneWidget);
    expect(setup.rebuildCalls, 1);
    final saved = (await DriftSettingsRepository(db).get())!;
    expect(saved.theme, ThemePreference.dark);
    expect(saved.textScale, 1.4);
    await unmount(tester, db);
  });

  testWidgets('says plainly when an import is refused and changes nothing', (
    tester,
  ) async {
    final db = await openTestDatabase(language: AppLanguage.en);
    final setup = await _pump(tester, db);

    Future<void> tryImport(Object? file) async {
      setup.source.text = file is String ? file : jsonEncode(file);
      await _tapVisible(tester, 'data-import');
    }

    await tryImport({'format': 'other', 'version': 1});
    expect(find.text('This is not a Deen App settings file.'), findsOneWidget);

    await tryImport({'format': 'deen-app-settings', 'version': 9});
    expect(
      find.textContaining('made by a newer version of the app'),
      findsOneWidget,
    );

    await tryImport('not json');
    expect(find.text('The file could not be read.'), findsOneWidget);

    await tryImport({
      'format': 'deen-app-settings',
      'version': 1,
      'appearance': {'textScale': 5.0},
    });
    expect(
      find.textContaining('missing or out of range (appearance.textScale)'),
      findsOneWidget,
    );

    setup.source.throws = true;
    await _tapVisible(tester, 'data-import');
    expect(find.text('The file could not be read.'), findsOneWidget);

    expect((await DriftSettingsRepository(db).get())!.textScale, 1.0);
    expect(setup.rebuildCalls, 0);
    expect(tester.takeException(), isNull);
    await unmount(tester, db);
  });

  testWidgets('choosing no file changes nothing', (tester) async {
    final db = await openTestDatabase(language: AppLanguage.en);
    final setup = await _pump(tester, db);
    await tester.tap(find.byKey(const Key('data-import')));
    await settle(tester);
    expect(find.byKey(const Key('data-status')), findsNothing);
    expect(setup.rebuildCalls, 0);
    await unmount(tester, db);
  });

  group('delete all my data', () {
    testWidgets(
      'asks first, says exported files remain, and can be cancelled',
      (tester) async {
        final db = await openTestDatabase(language: AppLanguage.en);
        final setup = await _pump(tester, db);
        await tester.scrollUntilVisible(
          find.byKey(const Key('data-delete-all')),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.byKey(const Key('data-delete-all')));
        await settle(tester);
        expect(find.byKey(const Key('delete-all-dialog')), findsOneWidget);
        expect(
          find.textContaining(
            'saved or shared outside the app are not deleted',
          ),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const Key('delete-all-cancel')));
        await settle(tester);
        expect(await DriftSettingsRepository(db).get(), isNotNull);
        expect(setup.cancelCalls, 0);
        await unmount(tester, db);
      },
    );

    testWidgets('confirming clears the database, alerts and native files', (
      tester,
    ) async {
      final db = await openTestDatabase(language: AppLanguage.en);
      final setup = await _pump(tester, db);
      await tester.scrollUntilVisible(
        find.byKey(const Key('data-delete-all')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('data-delete-all')));
      await settle(tester);
      await tester.tap(find.byKey(const Key('delete-all-confirm')));
      await settle(tester);
      expect(find.text('All data was deleted.'), findsOneWidget);
      expect(await DriftSettingsRepository(db).get(), isNull);
      expect(setup.cancelCalls, 1);
      expect(setup.native.calls, 1);
      expect(setup.sink.deleteCalls, 1);
      await unmount(tester, db);
    });
  });

  for (final language in AppLanguage.values) {
    testWidgets('lays out in ${language.name} at 2.0x text without overflow', (
      tester,
    ) async {
      useSmallPhone(tester);
      final db = await openTestDatabase(language: language, textScale: 2.0);
      await _pump(tester, db);
      expect(tester.takeException(), isNull);
      final context = tester.element(find.byKey(const Key('data-page')));
      expect(
        Directionality.of(context),
        language.isRtl ? TextDirection.rtl : TextDirection.ltr,
      );
      await unmount(tester, db);
    });
  }

  testWidgets('controls are labeled and large enough', (tester) async {
    final handle = tester.ensureSemantics();
    final db = await openTestDatabase(language: AppLanguage.en);
    await _pump(tester, db);
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await unmount(tester, db);
    handle.dispose();
  });
}
