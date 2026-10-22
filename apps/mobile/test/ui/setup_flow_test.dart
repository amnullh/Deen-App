import 'package:deen_mobile/data/repositories/drift_settings_repository.dart';
import 'package:deen_mobile/domain/entities/enums.dart';
import 'package:deen_mobile/domain/entities/settings.dart';
import 'package:deen_mobile/domain/permissions/permission_gateways.dart';
import 'package:deen_mobile/l10n/generated/app_localizations.dart';
import 'package:deen_mobile/ui/setup/setup_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prayer_engine/prayer_engine.dart';

import 'setup/setup_test_support.dart';

const _phone = Size(360, 640);

Future<void> _saveLanguage(TestWorld world, AppLanguage language) {
  return DriftSettingsRepository(world.db).save(
    PrayerSettings(
      method: CalculationMethod.muslimWorldLeague,
      asrMethod: AsrMethod.standard,
      highLatitudeRule: HighLatitudeRule.middleOfNight,
      language: language,
    ),
  );
}

Future<void> _tapKey(WidgetTester tester, String key, {int rounds = 3}) async {
  final finder = find.byKey(Key(key));
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await settle(tester, rounds: rounds);
}

Future<void> _chooseMecca(WidgetTester tester) async {
  final field = find.byKey(const Key('city-search'));
  await tester.ensureVisible(field);
  await tester.enterText(field, 'Mec');
  await settle(tester, rounds: 3);
  await _tapKey(tester, 'city-104515');
}

void main() {
  for (final language in AppLanguage.values) {
    testWidgets(
      'every setup step in ${language.name} lays out with no overflow at 2.0x '
      'text on a small phone',
      (tester) async {
        final l10n = lookupAppLocalizations(Locale(language.name));
        final world = TestWorld();
        await _saveLanguage(world, language);
        await pumpApp(
          tester,
          world,
          const SetupFlow(),
          textScale: 2.0,
          size: _phone,
        );

        final context = tester.element(find.byKey(const Key('setup-flow')));
        expect(
          Directionality.of(context),
          language.isRtl ? TextDirection.rtl : TextDirection.ltr,
        );

        // 1 language
        expect(find.text(l10n.setupLanguageTitle), findsOneWidget);
        expect(tester.takeException(), isNull);
        await _tapKey(tester, 'setup-next');

        // 2 location: Next is disabled until a place is chosen
        expect(find.text(l10n.setupLocationTitle), findsOneWidget);
        expect(find.text(l10n.setupLocationPrivacy), findsOneWidget);
        expect(
          tester
              .widget<FilledButton>(find.byKey(const Key('setup-next')))
              .onPressed,
          isNull,
        );
        await _chooseMecca(tester);
        expect(tester.takeException(), isNull);
        await _tapKey(tester, 'setup-next');

        // 3 method and Asr
        expect(find.text(l10n.setupMethodTitle), findsOneWidget);
        expect(
          find.text(l10n.setupMethodSuggested(l10n.methodUmmAlQura)),
          findsOneWidget,
        );
        await tester.ensureVisible(find.text(l10n.asrHanafiBody));
        expect(find.text(l10n.asrStandardBody), findsOneWidget);
        expect(tester.takeException(), isNull);
        await _tapKey(tester, 'setup-next');

        // 4 notifications
        expect(find.text(l10n.setupNotificationsTitle), findsOneWidget);
        expect(find.text(l10n.setupNotificationsBody), findsOneWidget);
        await _tapKey(tester, 'notifications-allow');
        expect(find.text(l10n.setupNotificationsGranted), findsOneWidget);
        expect(tester.takeException(), isNull);
        await _tapKey(tester, 'setup-next');

        // 5 exact alarm (Android)
        expect(find.text(l10n.setupExactTitle), findsOneWidget);
        expect(tester.takeException(), isNull);
        await _tapKey(tester, 'setup-next');

        // 6 battery guide
        expect(find.text(l10n.setupBatteryTitle), findsOneWidget);
        expect(tester.takeException(), isNull);
        await _tapKey(tester, 'setup-next');

        // 7 privacy
        expect(find.text(l10n.setupPrivacyTitle), findsOneWidget);
        expect(find.text(l10n.setupPrivacyNoData), findsOneWidget);
        expect(tester.takeException(), isNull);
        expect(find.text(l10n.setupFinish), findsOneWidget);

        await unmount(tester, world.db);
      },
    );
  }

  testWidgets('Standard Asr is preselected and both schools are explained', (
    tester,
  ) async {
    final world = TestWorld();
    await _saveLanguage(world, AppLanguage.en);
    await pumpApp(tester, world, const SetupFlow(), size: const Size(400, 900));
    await _tapKey(tester, 'setup-next');
    await _chooseMecca(tester);
    await _tapKey(tester, 'setup-next');

    final l10n = lookupAppLocalizations(const Locale('en'));
    expect(find.text(l10n.asrStandardBody), findsOneWidget);
    expect(find.text(l10n.asrHanafiBody), findsOneWidget);
    final standard = tester.widget<RadioListTile<AsrMethod>>(
      find.byKey(const Key('asr-standard')),
    );
    expect(standard.value, AsrMethod.standard);
    expect(
      RadioGroup.maybeOf<AsrMethod>(
        tester.element(find.byKey(const Key('asr-standard'))),
      )!.groupValue,
      AsrMethod.standard,
    );
    await unmount(tester, world.db);
  });

  testWidgets('the suggested method can be changed in setup', (tester) async {
    final world = TestWorld();
    await _saveLanguage(world, AppLanguage.en);
    await pumpApp(tester, world, const SetupFlow(), size: const Size(400, 900));
    await _tapKey(tester, 'setup-next');
    await _chooseMecca(tester);
    await _tapKey(tester, 'setup-next');
    await _tapKey(tester, 'method-egypt');
    final saved = await tester.runAsync(
      () => DriftSettingsRepository(world.db).get(),
    );
    expect(saved!.method, CalculationMethod.egypt);
    await unmount(tester, world.db);
  });

  testWidgets(
    'refusing everything reaches the end, lists what will not work and offers '
    'a way back',
    (tester) async {
      final world = TestWorld(
        notifications: PermissionOutcome.permanentlyDenied,
        exactAlarm: PermissionOutcome.denied,
      );
      await _saveLanguage(world, AppLanguage.en);
      var finished = false;
      await pumpApp(
        tester,
        world,
        SetupFlow(onFinished: () => finished = true),
        size: const Size(400, 900),
      );
      final l10n = lookupAppLocalizations(const Locale('en'));
      await _tapKey(tester, 'setup-next');
      await _chooseMecca(tester);
      await _tapKey(tester, 'setup-next'); // method
      await _tapKey(tester, 'setup-next'); // notifications
      await _tapKey(tester, 'notifications-allow');
      expect(find.text(l10n.setupNotificationsDenied), findsOneWidget);
      expect(
        find.byKey(const Key('notifications-open-settings')),
        findsOneWidget,
      );
      await _tapKey(tester, 'setup-next'); // exact alarm
      await _tapKey(tester, 'exact-check');
      expect(find.text(l10n.setupExactDenied), findsOneWidget);
      await _tapKey(tester, 'setup-next'); // battery
      await _tapKey(tester, 'setup-next'); // privacy

      expect(find.text(l10n.setupSummaryAlerts), findsOneWidget);
      expect(find.text(l10n.setupSummaryExact), findsOneWidget);
      await _tapKey(tester, 'privacy-open-settings');
      expect(world.notificationGateway.settingsOpened, 1);

      await _tapKey(tester, 'setup-next', rounds: 5);
      expect(finished, isTrue);
      expect(tester.takeException(), isNull);
      await unmount(tester, world.db);
    },
  );

  testWidgets('iPhone setup has no exact-alarm or battery step', (
    tester,
  ) async {
    final world = TestWorld(isAndroid: false);
    await _saveLanguage(world, AppLanguage.en);
    await pumpApp(tester, world, const SetupFlow(), size: const Size(400, 900));
    final l10n = lookupAppLocalizations(const Locale('en'));
    expect(find.text(l10n.setupProgress(1, 5)), findsWidgets);
    await _tapKey(tester, 'setup-next');
    await _chooseMecca(tester);
    await _tapKey(tester, 'setup-next');
    await _tapKey(tester, 'setup-next');
    await _tapKey(tester, 'setup-next'); // skip notifications ("Not now")
    expect(find.text(l10n.setupPrivacyTitle), findsOneWidget);
    expect(find.text(l10n.setupSummaryAlerts), findsOneWidget);
    expect(find.text(l10n.setupSummaryExact), findsNothing);
    await unmount(tester, world.db);
  });

  testWidgets('searching an unknown city says so', (tester) async {
    final world = TestWorld();
    await _saveLanguage(world, AppLanguage.en);
    await pumpApp(tester, world, const SetupFlow(), size: const Size(400, 900));
    await _tapKey(tester, 'setup-next');
    await tester.enterText(find.byKey(const Key('city-search')), 'Zzzz');
    await settle(tester, rounds: 3);
    final l10n = lookupAppLocalizations(const Locale('en'));
    expect(find.text(l10n.setupLocationSearchEmpty), findsOneWidget);
    await unmount(tester, world.db);
  });

  testWidgets('the saved language applies at once when chosen', (tester) async {
    final world = TestWorld();
    await pumpApp(tester, world, const SetupFlow(), size: const Size(400, 900));
    final en = lookupAppLocalizations(const Locale('en'));
    final ur = lookupAppLocalizations(const Locale('ur'));
    expect(find.text(en.setupLanguageTitle), findsOneWidget);
    await _tapKey(tester, 'language-ur');
    expect(find.text(ur.setupLanguageTitle), findsOneWidget);
    final context = tester.element(find.byKey(const Key('setup-flow')));
    expect(Directionality.of(context), TextDirection.rtl);
    final saved = await tester.runAsync(
      () => world.db.select(world.db.prayerSettingsTable).getSingle(),
    );
    expect(saved!.language, AppLanguage.ur);
    await unmount(tester, world.db);
  });
}
