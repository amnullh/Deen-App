import 'dart:async';

import 'package:deen_mobile/data/db/app_database.dart';
import 'package:deen_mobile/data/repositories/drift_alert_log_repository.dart';
import 'package:deen_mobile/data/repositories/drift_alert_preference_repository.dart';
import 'package:deen_mobile/data/repositories/drift_location_repository.dart';
import 'package:deen_mobile/data/repositories/drift_settings_repository.dart';
import 'package:deen_mobile/domain/alerts/alert_event_router.dart';
import 'package:deen_mobile/domain/alerts/alert_reconciler.dart';
import 'package:deen_mobile/domain/alerts/renewal_handler.dart';
import 'package:deen_mobile/domain/alerts/schedule_coordinator.dart';
import 'package:deen_mobile/domain/alerts/schedule_plan.dart';
import 'package:deen_mobile/domain/entities/enums.dart';
import 'package:deen_mobile/domain/entities/settings.dart';
import 'package:deen_mobile/platform/alert_scheduler.dart';
import 'package:deen_mobile/platform/playback_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prayer_engine/prayer_engine.dart';

final _now = DateTime.utc(2026, 10, 22, 6);

void main() {
  late AppDatabase db;
  late _Scheduler scheduler;
  late _Builder builder;
  late _Player player;
  late ScheduleCoordinator coordinator;
  late PlaybackService playback;
  late AlertEventRouter router;
  late List<PlayOutcome> outcomes;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await DriftSettingsRepository(db).save(
      const PrayerSettings(
        method: CalculationMethod.ummAlQura,
        asrMethod: AsrMethod.standard,
        highLatitudeRule: HighLatitudeRule.middleOfNight,
        language: AppLanguage.en,
      ),
    );
    await DriftLocationRepository(db).save(
      AppLocation(
        source: LocationSource.city,
        latitude: 21.4,
        longitude: 39.8,
        displayName: 'Mecca',
        timeZoneId: 'Asia/Riyadh',
        countryCode: 'SA',
        updatedAt: _now,
      ),
    );
    final log = DriftAlertLogRepository(db);
    scheduler = _Scheduler();
    builder = _Builder();
    player = _Player();
    coordinator = ScheduleCoordinator(
      scheduler: scheduler,
      planBuilder: builder,
      settings: DriftSettingsRepository(db),
      locations: DriftLocationRepository(db),
      alerts: DriftAlertPreferenceRepository(db),
      log: log,
      clock: () => _now,
      reconciler: AlertReconciler(scheduler: scheduler, log: log),
    );
    playback = PlaybackService(
      player: player,
      session: _Session(),
      log: log,
      clock: () => _now,
    );
    outcomes = [];
    router = AlertEventRouter(
      scheduler: scheduler,
      playback: () => playback,
      renewal: RenewalHandler(coordinator),
      onPlayOutcome: outcomes.add,
    )..start();
  });

  tearDown(() async {
    await router.dispose();
    await playback.dispose();
    await db.close();
  });

  Future<void> tap(String id, {String? audioRef}) async {
    scheduler.events_.add(NotificationTappedEvent(id, audioRef: audioRef));
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }

  group('RenewalHandler', () {
    test('recognises renewal ids only', () {
      expect(RenewalHandler.isRenewal('renewal:2026-12-14'), isTrue);
      expect(RenewalHandler.isRenewal('fajr:2026-12-14'), isFalse);
    });

    test('a tap on the renewal notice rebuilds the schedule', () async {
      final handled = await RenewalHandler(coordinator)
          .onTapped('renewal:2026-12-14');
      expect(handled, isTrue);
      expect(builder.builds, 1);
    });

    test('other ids are left alone', () async {
      final handled = await RenewalHandler(coordinator).onTapped('fajr:x');
      expect(handled, isFalse);
      expect(builder.builds, 0);
    });
  });

  group('AlertEventRouter', () {
    test('a renewal tap rebuilds and plays nothing', () async {
      await tap('renewal:2026-12-14');
      expect(builder.builds, 1);
      expect(player.loaded, isEmpty);
    });

    test('a full-Azaan tap plays that recording', () async {
      await tap('fajr:2026-10-23', audioRef: 'voice-1-fajr');
      expect(player.loaded, ['assets/audio/voice-1-fajr.m4a']);
      expect(outcomes, [PlayOutcome.started]);
    });

    test('tapping the same alert twice plays one Azaan', () async {
      await tap('fajr:2026-10-23', audioRef: 'voice-1-fajr');
      await playback.stop();
      await tap('fajr:2026-10-23', audioRef: 'voice-1-fajr');
      expect(player.loaded, hasLength(1));
      expect(outcomes, [PlayOutcome.started, PlayOutcome.alreadyPlayed]);
    });

    test('a tap with no recording just opens the app', () async {
      await tap('asr:2026-10-23');
      expect(player.loaded, isEmpty);
      expect(outcomes, isEmpty);
      expect(builder.builds, 0);
    });

    test('a recording that cannot load is reported', () async {
      player.failLoad = true;
      await tap('fajr:2026-10-23', audioRef: 'voice-1-fajr');
      expect(outcomes, [PlayOutcome.failed]);
    });
  });
}

class _Builder implements PlanBuilder {
  int builds = 0;

  @override
  Future<AlertPlan> build(PlanRequest request) async {
    builds++;
    return const AlertPlan(alerts: [], records: [], runsUntil: null);
  }
}

class _Scheduler implements AlertScheduler {
  @override
  AlertPlatform get platform => AlertPlatform.ios;
  final StreamController<AlertPlatformEvent> events_ =
      StreamController<AlertPlatformEvent>.broadcast();

  @override
  Stream<AlertPlatformEvent> get events => events_.stream;

  @override
  Future<AlertPermissions> getPermissionState() async => const AlertPermissions(
    platform: AlertPlatform.ios,
    notificationsGranted: true,
  );

  @override
  Future<SchedulerResult> replaceSchedule(List<ScheduledAlert> alerts) async =>
      SchedulerResult(ok: true);

  @override
  Future<List<JournalEntry>> readJournal(int sinceEpochMs) async => const [];

  @override
  Future<void> clearJournal() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Player implements AzaanPlayer {
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

class _Session implements PlaybackSession {
  @override
  Stream<void> get becomingNoisy => const Stream.empty();

  @override
  Stream<PlaybackInterruption> get interruptions => const Stream.empty();

  @override
  Future<void> activate() async {}

  @override
  Future<void> deactivate() async {}
}
