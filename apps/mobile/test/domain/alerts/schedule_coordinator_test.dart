import 'dart:async';

import 'package:deen_mobile/data/db/app_database.dart';
import 'package:deen_mobile/data/repositories/drift_alert_log_repository.dart';
import 'package:deen_mobile/data/repositories/drift_alert_preference_repository.dart';
import 'package:deen_mobile/data/repositories/drift_location_repository.dart';
import 'package:deen_mobile/data/repositories/drift_settings_repository.dart';
import 'package:deen_mobile/domain/alerts/alert_log_entry.dart';
import 'package:deen_mobile/domain/alerts/alert_reconciler.dart';
import 'package:deen_mobile/domain/alerts/schedule_coordinator.dart';
import 'package:deen_mobile/domain/alerts/schedule_plan.dart';
import 'package:deen_mobile/domain/entities/enums.dart';
import 'package:deen_mobile/domain/entities/settings.dart';
import 'package:deen_mobile/platform/alert_scheduler.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prayer_engine/prayer_engine.dart';

DateTime _clockValue = DateTime.utc(2026, 10, 22, 6);

AppLocation _location({String zone = 'Asia/Riyadh', double lat = 21.4225}) =>
    AppLocation(
      source: LocationSource.city,
      latitude: lat,
      longitude: 39.8262,
      displayName: 'Mecca',
      timeZoneId: zone,
      countryCode: 'SA',
      updatedAt: DateTime.utc(2026, 10, 21),
    );

PrayerSettings _settings({
  CalculationMethod method = CalculationMethod.ummAlQura,
  AppLanguage language = AppLanguage.en,
  double textScale = 1.0,
}) => PrayerSettings(
  method: method,
  asrMethod: AsrMethod.standard,
  highLatitudeRule: HighLatitudeRule.middleOfNight,
  language: language,
  textScale: textScale,
);

void main() {
  late AppDatabase db;
  late DriftSettingsRepository settings;
  late DriftLocationRepository locations;
  late DriftAlertPreferenceRepository alerts;
  late DriftAlertLogRepository log;
  late _FakeScheduler scheduler;
  late _FakeBuilder builder;
  late ScheduleCoordinator coordinator;
  late String? zone;
  late bool clockMoved;
  late List<List<AlertLogEntry>> missedReports;

  ScheduleCoordinator make({AlertPlatform platform = AlertPlatform.android}) {
    scheduler = _FakeScheduler(platform);
    return ScheduleCoordinator(
      scheduler: scheduler,
      planBuilder: builder,
      settings: settings,
      locations: locations,
      alerts: alerts,
      log: log,
      clock: () => _clockValue,
      reconciler: AlertReconciler(scheduler: scheduler, log: log),
      deviceZone: () async => zone,
      clockChanged: () async => clockMoved,
      onMissed: missedReports.add,
    );
  }

  setUp(() async {
    _clockValue = DateTime.utc(2026, 10, 22, 6);
    db = AppDatabase(NativeDatabase.memory());
    settings = DriftSettingsRepository(db);
    locations = DriftLocationRepository(db);
    alerts = DriftAlertPreferenceRepository(db);
    log = DriftAlertLogRepository(db);
    builder = _FakeBuilder();
    zone = 'Asia/Riyadh';
    clockMoved = false;
    missedReports = [];
    await settings.save(_settings());
    await locations.save(_location());
    coordinator = make();
  });

  tearDown(() async {
    await coordinator.dispose();
    await db.close();
  });

  group('launch', () {
    test('plans, hands the schedule to the platform and records it', () async {
      final report = await coordinator.onLaunch();
      expect(report.status, RebuildStatus.rebuilt);
      expect(scheduler.replaced, hasLength(1));
      expect(scheduler.replaced.single.map((a) => a.alertId), [
        'asr:2026-10-22',
        'maghrib:2026-10-22',
      ]);
      final rows = await log.recent();
      expect(rows.map((r) => r.state).toSet(), {AlertLogState.planned});
      expect(rows, hasLength(2));
    });

    test('updates scheduleRunsUntil from the plan', () async {
      await coordinator.onLaunch();
      final global = await alerts.getGlobal();
      expect(global.scheduleRunsUntil, builder.runsUntil);
    });

    test('always rebuilds, even when nothing changed', () async {
      await coordinator.onLaunch();
      await coordinator.onLaunch();
      expect(scheduler.replaced, hasLength(2));
    });

    test(
      'without a location it plans nothing and does not touch alerts',
      () async {
        await locations.clear();
        final report = await coordinator.onLaunch();
        expect(report.status, RebuildStatus.skippedNoLocation);
        expect(scheduler.replaced, isEmpty);
      },
    );

    test('reports alerts that were missed while the app was closed', () async {
      final past = _clockValue.subtract(const Duration(hours: 5));
      await log.syncPlanned([
        PlannedAlertRecord(alertId: 'fajr:2026-10-22', fireAt: past),
      ], now: past.subtract(const Duration(days: 1)));
      await coordinator.onLaunch();
      expect(missedReports, hasLength(1));
      expect(missedReports.single.single.alertId, 'fajr:2026-10-22');
    });

    test('saves the permission states the platform reported', () async {
      scheduler.permissions = const AlertPermissions(
        platform: AlertPlatform.android,
        notificationsGranted: true,
        exactAlarmGranted: false,
      );
      await coordinator.onLaunch();
      final global = await alerts.getGlobal();
      expect(global.notificationPermissionState, PermissionState.granted);
      expect(global.exactAlarmState, PermissionState.denied);
    });
  });

  group('settings, location and language changes', () {
    test('a settings change rebuilds with the new settings', () async {
      await coordinator.onLaunch();
      await settings.save(_settings(method: CalculationMethod.karachi));
      final report = await coordinator.rebuild(RebuildTrigger.settingsChanged);
      expect(report.status, RebuildStatus.rebuilt);
      expect(builder.requests.last.settings.method, CalculationMethod.karachi);
    });

    test('a change that does not affect alerts is skipped', () async {
      await coordinator.onLaunch();
      await settings.save(_settings(textScale: 1.5));
      final report = await coordinator.rebuild(RebuildTrigger.settingsChanged);
      expect(report.status, RebuildStatus.skippedUnchanged);
      expect(scheduler.replaced, hasLength(1));
    });

    test('a location change rebuilds for the new place', () async {
      await coordinator.onLaunch();
      await locations.save(_location(lat: 24.7));
      final report = await coordinator.rebuild(RebuildTrigger.locationChanged);
      expect(report.status, RebuildStatus.rebuilt);
      expect(builder.requests.last.location.latitude, 24.7);
    });

    test(
      'a language change rebuilds so notification text follows it',
      () async {
        await coordinator.onLaunch();
        await settings.save(_settings(language: AppLanguage.ar));
        final report = await coordinator.rebuild(
          RebuildTrigger.languageChanged,
        );
        expect(report.status, RebuildStatus.rebuilt);
        expect(builder.requests.last.settings.language, AppLanguage.ar);
      },
    );

    test('an alert preference change rebuilds', () async {
      await coordinator.onLaunch();
      await alerts.save(
        const AlertPreference(
          prayer: AlertPrayer.fajr,
          type: AlertType.fullAzaan,
        ),
      );
      final report = await coordinator.rebuild(RebuildTrigger.settingsChanged);
      expect(report.status, RebuildStatus.rebuilt);
    });

    test(
      'saving permission bookkeeping does not cause another rebuild',
      () async {
        await coordinator.onLaunch();
        final report = await coordinator.rebuild(
          RebuildTrigger.settingsChanged,
        );
        expect(report.status, RebuildStatus.skippedUnchanged);
      },
    );
  });

  group('permission, zone and clock changes', () {
    test('a permission change rebuilds with the new permissions', () async {
      await coordinator.onLaunch();
      scheduler.permissions = const AlertPermissions(
        platform: AlertPlatform.android,
        notificationsGranted: false,
      );
      final report = await coordinator.rebuild(
        RebuildTrigger.permissionChanged,
      );
      expect(report.status, RebuildStatus.rebuilt);
      expect(builder.requests.last.permissions.notificationsGranted, isFalse);
    });

    test('a permission event from the platform triggers a rebuild', () async {
      await coordinator.onLaunch();
      coordinator.start();
      scheduler.permissions = const AlertPermissions(
        platform: AlertPlatform.android,
        notificationsGranted: false,
      );
      scheduler.emit(PermissionChangedEvent(scheduler.permissions));
      await _idle(coordinator);
      expect(scheduler.replaced, hasLength(2));
    });

    test('a new device time zone rebuilds on foreground', () async {
      await coordinator.onForeground();
      zone = 'Asia/Jakarta';
      final report = await coordinator.onForeground();
      expect(report.trigger, RebuildTrigger.timeZoneChanged);
      expect(report.status, RebuildStatus.rebuilt);
    });

    test('a changed clock rebuilds on foreground', () async {
      await coordinator.onForeground();
      clockMoved = true;
      final report = await coordinator.onForeground();
      expect(report.trigger, RebuildTrigger.clockChanged);
      expect(report.status, RebuildStatus.rebuilt);
    });

    test('a schedule running low rebuilds on foreground', () async {
      await coordinator.onLaunch();
      _clockValue = builder.runsUntil.subtract(const Duration(days: 10));
      builder.runsUntil = _clockValue.add(const Duration(days: 60));
      // Same local day as the previous build is not required: running low wins.
      final report = await coordinator.onForeground();
      expect(report.trigger, RebuildTrigger.windowRunningLow);
      expect(report.status, RebuildStatus.rebuilt);
    });

    test('iOS rebuilds on every foreground', () async {
      await coordinator.dispose();
      coordinator = make(platform: AlertPlatform.ios);
      await coordinator.onLaunch();
      final report = await coordinator.onForeground();
      expect(report.status, RebuildStatus.rebuilt);
    });

    test('iOS treats three days of schedule as running low', () async {
      await coordinator.dispose();
      coordinator = make(platform: AlertPlatform.ios);
      builder.runsUntil = _clockValue.add(const Duration(days: 2));
      await coordinator.onLaunch();
      final report = await coordinator.onForeground();
      expect(report.trigger, RebuildTrigger.windowRunningLow);
    });

    test(
      'Android foreground on the same day with nothing new is skipped',
      () async {
        await coordinator.onLaunch();
        _clockValue = _clockValue.add(const Duration(hours: 2));
        final report = await coordinator.onForeground();
        expect(report.status, RebuildStatus.skippedUnchanged);
      },
    );

    test('Android foreground on a new day rebuilds', () async {
      await coordinator.onLaunch();
      _clockValue = _clockValue.add(const Duration(days: 1));
      final report = await coordinator.onForeground();
      expect(report.status, RebuildStatus.rebuilt);
    });

    test(
      'the iOS refresh event rebuilds and then completes the task',
      () async {
        await coordinator.dispose();
        coordinator = make(platform: AlertPlatform.ios);
        coordinator.start();
        final event = RefreshWindowEvent();
        scheduler.emit(event);
        await event.done.future.timeout(const Duration(seconds: 2));
        expect(scheduler.replaced, hasLength(1));
      },
    );

    test('tapping the renewal notice rebuilds', () async {
      await coordinator.onLaunch();
      final report = await coordinator.rebuild(RebuildTrigger.renewalTapped);
      expect(report.status, RebuildStatus.rebuilt);
    });
  });

  group('robustness', () {
    test('a platform refusal is reported and keeps the old end date', () async {
      await coordinator.onLaunch();
      final before = (await alerts.getGlobal()).scheduleRunsUntil;
      scheduler.nextError = 'budget_exceeded';
      builder.runsUntil = builder.runsUntil.add(const Duration(days: 9));
      final report = await coordinator.rebuild(RebuildTrigger.launch);
      expect(report.status, RebuildStatus.failed);
      expect(report.errorCode, 'budget_exceeded');
      expect((await alerts.getGlobal()).scheduleRunsUntil, before);
    });

    test('a planner that throws is reported, not rethrown', () async {
      builder.throwOnBuild = true;
      final report = await coordinator.onLaunch();
      expect(report.status, RebuildStatus.failed);
      expect(report.errorCode, 'planning_failed');
    });

    test(
      'rebuild requests that pile up run once more, not once each',
      () async {
        scheduler.gate = Completer<void>();
        final first = coordinator.rebuild(RebuildTrigger.launch);
        await scheduler.entered.future;
        await settings.save(_settings(method: CalculationMethod.karachi));
        final second = coordinator.rebuild(RebuildTrigger.settingsChanged);
        final third = coordinator.rebuild(RebuildTrigger.languageChanged);
        scheduler.gate!.complete();
        await Future.wait([first, second, third]);
        expect(builder.requests, hasLength(2));
        expect(
          builder.requests.last.settings.method,
          CalculationMethod.karachi,
        );
      },
    );

    test('rebuilds never overlap', () async {
      await Future.wait([
        coordinator.rebuild(RebuildTrigger.launch),
        coordinator.rebuild(RebuildTrigger.permissionChanged),
        coordinator.rebuild(RebuildTrigger.timeZoneChanged),
      ]);
      expect(scheduler.maxConcurrent, 1);
    });
  });
}

Future<void> _idle(ScheduleCoordinator c) async {
  // Gives queued rebuilds a chance to finish.
  await c.rebuild(RebuildTrigger.manual);
}

class _FakeBuilder implements PlanBuilder {
  final List<PlanRequest> requests = [];
  bool throwOnBuild = false;
  DateTime runsUntil = DateTime.utc(2026, 12, 20);

  @override
  Future<AlertPlan> build(PlanRequest request) async {
    if (throwOnBuild) throw StateError('planner broke');
    requests.add(request);
    final at = request.now;
    final records = [
      PlannedAlertRecord(
        alertId: 'asr:2026-10-22',
        fireAt: at.add(const Duration(hours: 9)),
      ),
      PlannedAlertRecord(
        alertId: 'maghrib:2026-10-22',
        fireAt: at.add(const Duration(hours: 12)),
      ),
    ];
    return AlertPlan(
      alerts: [
        for (final r in records)
          ScheduledAlert(
            alertId: r.alertId,
            fireAtEpochMs: r.fireAt.millisecondsSinceEpoch,
            kind: AlertKind.prayer,
            delivery: DeliveryType.shortTone,
            title: 't',
            body: 'b',
            stopLabel: 's',
            loudMode: false,
            volumeChoice: VolumeChoiceDto.keepCurrent,
            preciseAllowed: true,
          ),
      ],
      records: records,
      runsUntil: runsUntil,
    );
  }
}

class _FakeScheduler implements AlertScheduler {
  _FakeScheduler(this.platform)
    : permissions = AlertPermissions(
        platform: platform,
        notificationsGranted: true,
      );

  @override
  final AlertPlatform platform;
  AlertPermissions permissions;
  final List<List<ScheduledAlert>> replaced = [];
  final StreamController<AlertPlatformEvent> _events =
      StreamController<AlertPlatformEvent>.broadcast();
  String? nextError;
  Completer<void>? gate;
  final Completer<void> entered = Completer<void>();
  int _running = 0;
  int maxConcurrent = 0;

  void emit(AlertPlatformEvent event) => _events.add(event);

  @override
  Stream<AlertPlatformEvent> get events => _events.stream;

  @override
  Future<AlertPermissions> getPermissionState() async => permissions;

  @override
  Future<SchedulerResult> replaceSchedule(List<ScheduledAlert> alerts) async {
    _running++;
    if (!entered.isCompleted) entered.complete();
    if (_running > maxConcurrent) maxConcurrent = _running;
    await gate?.future;
    await Future<void>.delayed(const Duration(milliseconds: 1));
    _running--;
    final error = nextError;
    if (error != null) {
      nextError = null;
      return SchedulerResult(ok: false, errorCode: error);
    }
    replaced.add(alerts);
    return SchedulerResult(ok: true);
  }

  @override
  Future<List<JournalEntry>> readJournal(int sinceEpochMs) async => const [];

  @override
  Future<void> clearJournal() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
