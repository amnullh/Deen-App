import 'dart:async';

import 'package:deen_mobile/app/providers.dart';
import 'package:deen_mobile/app/providers/alerts_providers.dart';
import 'package:deen_mobile/data/db/app_database.dart';
import 'package:deen_mobile/data/repositories/drift_settings_repository.dart';
import 'package:deen_mobile/domain/entities/enums.dart';
import 'package:deen_mobile/domain/entities/settings.dart';
import 'package:deen_mobile/l10n/generated/app_localizations.dart';
import 'package:deen_mobile/platform/alert_scheduler.dart';
import 'package:deen_mobile/platform/playback_service.dart';
import 'package:deen_mobile/ui/theme/app_theme.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:prayer_engine/prayer_engine.dart';

/// A scheduler that records what the screens ask of it.
class FakeAlertScheduler implements AlertScheduler {
  FakeAlertScheduler({
    this.platform = AlertPlatform.android,
    AlertPermissions? permissions,
    PendingSummary? summary,
  }) : permissions =
           permissions ??
           AlertPermissions(platform: platform, notificationsGranted: true),
       summary =
           summary ??
           PendingSummary(registeredCount: 0, snapshotCount: 0, nextAlerts: []);

  @override
  AlertPlatform platform;
  AlertPermissions permissions;
  PendingSummary summary;
  final List<String> calls = [];
  final List<List<ScheduledAlert>> replaced = [];
  SchedulerResult testResult = SchedulerResult(ok: true);

  /// What the permissions become after the settings page was opened.
  AlertPermissions? afterOpeningExactSettings;
  bool grantOnRequest = true;
  final StreamController<AlertPlatformEvent> events_ =
      StreamController<AlertPlatformEvent>.broadcast();

  @override
  Stream<AlertPlatformEvent> get events => events_.stream;

  @override
  Future<SchedulerResult> replaceSchedule(List<ScheduledAlert> alerts) async {
    replaced.add(alerts);
    return SchedulerResult(ok: true);
  }

  @override
  Future<SchedulerResult> scheduleTestAlert({
    required int delaySeconds,
    required DeliveryType delivery,
  }) async {
    calls.add('test:$delaySeconds:${delivery.name}');
    return testResult;
  }

  @override
  Future<AlertPermissions> getPermissionState() async => permissions;

  @override
  Future<bool> requestNotificationPermission() async {
    calls.add('requestNotifications');
    if (grantOnRequest) {
      permissions = AlertPermissions(
        platform: platform,
        notificationsGranted: true,
        exactAlarmGranted: permissions.exactAlarmGranted,
        batteryOptimizationIgnored: permissions.batteryOptimizationIgnored,
        soundEnabled: permissions.soundEnabled,
      );
    }
    return grantOnRequest;
  }

  @override
  Future<void> openExactAlarmSettings() async {
    calls.add('openExact');
    final next = afterOpeningExactSettings;
    if (next != null) permissions = next;
  }

  @override
  Future<void> openBatterySettings() async => calls.add('openBattery');

  @override
  Future<void> openAppNotificationSettings() async =>
      calls.add('openNotificationSettings');

  @override
  Future<List<JournalEntry>> readJournal(int sinceEpochMs) async => const [];

  @override
  Future<void> clearJournal() async {}

  @override
  Future<PendingSummary> getPendingSummary() async => summary;
}

/// Records previews instead of playing them.
class FakePlayer implements AzaanPlayer {
  final List<String> loaded = [];
  bool failLoad = false;

  @override
  Stream<void> get completed => const Stream.empty();

  @override
  Future<void> load(String asset) async {
    if (failLoad) throw StateError('missing');
    loaded.add(asset);
  }

  @override
  Future<void> play() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> setVolume(double value) async {}

  @override
  Future<void> dispose() async {}
}

class FakeSession implements PlaybackSession {
  @override
  Stream<void> get becomingNoisy => const Stream.empty();

  @override
  Stream<PlaybackInterruption> get interruptions => const Stream.empty();

  @override
  Future<void> activate() async {}

  @override
  Future<void> deactivate() async {}
}

class Harness {
  Harness({required this.db, required this.scheduler, required this.player});

  final AppDatabase db;
  final FakeAlertScheduler scheduler;
  final FakePlayer player;
}

Future<AppDatabase> newDatabase({AppLanguage language = AppLanguage.en}) async {
  final db = AppDatabase(NativeDatabase.memory());
  await DriftSettingsRepository(db).save(
    PrayerSettings(
      method: CalculationMethod.ummAlQura,
      asrMethod: AsrMethod.standard,
      highLatitudeRule: HighLatitudeRule.middleOfNight,
      language: language,
    ),
  );
  return db;
}

/// Shows [page] in the real app theme and localizations with fake platform
/// parts. Pass the same [scheduler] and [player] you want to inspect later.
Future<Harness> pumpPage(
  WidgetTester tester,
  Widget page, {
  required AppDatabase db,
  FakeAlertScheduler? scheduler,
  FakePlayer? player,
  AppLanguage language = AppLanguage.en,
  double textScale = 1.0,
  List<Override> overrides = const [],
}) async {
  final fakeScheduler = scheduler ?? FakeAlertScheduler();
  final fakePlayer = player ?? FakePlayer();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        alertSchedulerProvider.overrideWithValue(fakeScheduler),
        alertPlatformProvider.overrideWithValue(fakeScheduler.platform),
        playbackServiceProvider.overrideWith(
          (ref) => PlaybackService(
            player: fakePlayer,
            session: FakeSession(),
            log: ref.watch(alertLogRepositoryProvider),
            clock: ref.watch(clockProvider),
          ),
        ),
        ...overrides,
      ],
      child: MaterialApp(
        locale: localeFor(language),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: buildTheme(brightness: Brightness.light, language: language),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: page,
      ),
    ),
  );
  await settle(tester);
  return Harness(db: db, scheduler: fakeScheduler, player: fakePlayer);
}

/// Drift streams keep timers alive, so pumpAndSettle would never return.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Unmounts and closes the database inside the test body.
Future<void> unmount(WidgetTester tester, AppDatabase db) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 10));
  await tester.runAsync(db.close);
  await tester.pump(const Duration(seconds: 1));
}

ScheduledAlert upcoming(
  String id, {
  String title = 'Asr prayer',
  DeliveryType delivery = DeliveryType.shortTone,
  AlertKind kind = AlertKind.prayer,
  bool precise = true,
  DateTime? at,
}) => ScheduledAlert(
  alertId: id,
  fireAtEpochMs: (at ?? DateTime.utc(2026, 10, 22, 12)).millisecondsSinceEpoch,
  kind: kind,
  delivery: delivery,
  title: title,
  body: '',
  stopLabel: 'Stop',
  loudMode: false,
  volumeChoice: VolumeChoiceDto.keepCurrent,
  preciseAllowed: precise,
);
