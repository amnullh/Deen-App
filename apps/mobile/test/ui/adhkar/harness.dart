import 'dart:convert';

import 'package:deen_mobile/app/providers.dart';
import 'package:deen_mobile/app/providers/adhkar_providers.dart';
import 'package:deen_mobile/data/adhkar/adhkar_content_loader.dart';
import 'package:deen_mobile/data/db/app_database.dart';
import 'package:deen_mobile/data/repositories/drift_settings_repository.dart';
import 'package:deen_mobile/domain/entities/enums.dart';
import 'package:deen_mobile/domain/entities/settings.dart';
import 'package:deen_mobile/l10n/generated/app_localizations.dart';
import 'package:deen_mobile/ui/theme/app_theme.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:prayer_engine/prayer_engine.dart';

/// Shared by the adhkar, about and settings widget tests. Test text is clearly
/// fake: no real adhkar, Quran or hadith text may appear in this repository
/// until the content gate (plan D-4) is cleared.

/// Fixed "now" for tests.
final DateTime testNow = DateTime.utc(2026, 10, 21, 8);

class FakeAssets implements AdhkarAssetSource {
  FakeAssets(this.files);

  final Map<String, String> files;

  @override
  Future<List<String>> listPackFiles() async => files.keys.toList();

  @override
  Future<String> read(String path) async => files[path]!;
}

Map<String, Object?> fakeEntryJson(
  String id, {
  int order = 1,
  int repeat = 3,
  bool withTranslation = true,
}) => {
  'id': id,
  'order': order,
  'arabic': 'FAKE ARABIC $id',
  'transliteration': 'FAKE TRANSLIT $id',
  'translations': withTranslation
      ? {'en': 'FAKE ENGLISH $id', 'id': 'FAKE INDONESIAN $id'}
      : <String, Object?>{},
  'repeatCount': repeat,
  'reference': 'FAKE REF $id',
  'sourceId': 'fake-source',
  'licenseId': 'fake-license',
  'reviewer': 'Fake Reviewer',
  'reviewedOn': '2000-01-01',
};

/// A pack with a morning collection (3, 1 and 2 repeats) and an evening one.
FakeAssets fakePackAssets() => FakeAssets({
  'assets/adhkar/fake.json': jsonEncode({
    'collections': [
      {
        'id': 'morning',
        'kind': 'morning',
        'entries': [
          fakeEntryJson('m1', order: 1, repeat: 3),
          fakeEntryJson('m2', order: 2, repeat: 1),
          fakeEntryJson('m3', order: 3, repeat: 2),
        ],
      },
      {
        'id': 'evening',
        'kind': 'evening',
        'entries': [fakeEntryJson('v1', order: 1, repeat: 1)],
      },
    ],
  }),
});

PrayerSettings testSettings({
  AppLanguage language = AppLanguage.en,
  double textScale = 1.0,
  ThemePreference theme = ThemePreference.system,
  bool highContrast = false,
}) {
  return PrayerSettings(
    method: CalculationMethod.ummAlQura,
    asrMethod: AsrMethod.standard,
    highLatitudeRule: HighLatitudeRule.middleOfNight,
    language: language,
    textScale: textScale,
    theme: theme,
    highContrast: highContrast,
  );
}

/// An in-memory database, with settings saved when [language] is given.
Future<AppDatabase> openTestDatabase({
  AppLanguage? language,
  double textScale = 1.0,
}) async {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final db = AppDatabase(NativeDatabase.memory());
  if (language != null) {
    await DriftSettingsRepository(db)
        .save(testSettings(language: language, textScale: textScale));
  }
  return db;
}

/// Pumps [page] in an app with the same localization, theme and text scale
/// rules as the real one, reading language and scale from the saved settings.
Future<void> pumpPage(
  WidgetTester tester,
  AppDatabase db,
  Widget page, {
  AdhkarAssetSource? assets,
  List<Override> overrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(() => testNow),
        adhkarAssetSourceProvider.overrideWithValue(assets ?? FakeAssets({})),
        ...overrides,
      ],
      child: _TestApp(page: page),
    ),
  );
  await settle(tester);
}

class _TestApp extends ConsumerWidget {
  const _TestApp({required this.page});

  final Widget page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(prayerSettingsProvider).value;
    final language = settings?.language ?? AppLanguage.en;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: localeFor(language),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: buildTheme(
        brightness: Brightness.light,
        language: language,
        highContrast: settings?.highContrast ?? false,
      ),
      darkTheme: buildTheme(
        brightness: Brightness.dark,
        language: language,
        highContrast: settings?.highContrast ?? false,
      ),
      themeMode: themeModeFor(settings?.theme ?? ThemePreference.system),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(settings?.textScale ?? 1.0)),
        child: child ?? const SizedBox.shrink(),
      ),
      home: page,
    );
  }
}

/// Drift streams keep timers alive, so pumpAndSettle would never return. Pump a
/// bounded number of frames instead (same helper as app_shell_test.dart).
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Unmounts the app and closes the database inside the test body, so drift's
/// stream clean-up timer fires before the framework checks for pending timers.
Future<void> unmount(WidgetTester tester, AppDatabase db) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 10));
  await tester.runAsync(db.close);
  await tester.pump(const Duration(seconds: 1));
}

/// A phone-sized screen so large text has to fit.
void useSmallPhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 640);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}
