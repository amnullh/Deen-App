import 'package:deen_mobile/data/db/app_database.dart';
import 'package:deen_mobile/data/repositories/drift_alert_log_repository.dart';
import 'package:deen_mobile/domain/alerts/alert_log_entry.dart';
import 'package:deen_mobile/domain/alerts/alert_reconciler.dart';
import 'package:deen_mobile/domain/alerts/journal_importer.dart';
import 'package:deen_mobile/domain/alerts/missed_alert_detector.dart';
import 'package:deen_mobile/domain/entities/enums.dart';
import 'package:deen_mobile/platform/alert_scheduler.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime.utc(2026, 10, 22, 12);

int _ms(DateTime t) => t.millisecondsSinceEpoch;

JournalEntry _journal(
  String id,
  DateTime planned,
  JournalState state, {
  DateTime? firedAt,
  String? cause,
}) => JournalEntry(
  alertId: id,
  plannedAtEpochMs: _ms(planned),
  firedAtEpochMs: firedAt == null ? null : _ms(firedAt),
  state: state,
  cause: cause,
);

AlertLogEntry _planned(String id, DateTime at, {AlertCause? cause}) =>
    AlertLogEntry(
      alertId: id,
      plannedFireAt: at,
      state: AlertLogState.planned,
      source: AlertLogSource.inApp,
      cause: cause,
    );

AlertPermissions _androidOk({
  bool notifications = true,
  bool exact = true,
  bool battery = true,
}) => AlertPermissions(
  platform: AlertPlatform.android,
  notificationsGranted: notifications,
  exactAlarmGranted: exact,
  batteryOptimizationIgnored: battery,
);

AlertPermissions _iosPermissions({bool notifications = true}) =>
    AlertPermissions(
      platform: AlertPlatform.ios,
      notificationsGranted: notifications,
    );

void main() {
  reconcilerTests();
  group('JournalImporter.fold', () {
    final planned = _now.subtract(const Duration(hours: 3));

    test('a fired entry becomes a fired row with its deviation', () {
      final rows = JournalImporter.fold(
        [
          _journal(
            'fajr:2026-10-22',
            planned,
            JournalState.fired,
            firedAt: planned.add(const Duration(seconds: 2)),
          ),
        ],
        source: AlertLogSource.androidJournal,
        existing: const {},
      );
      expect(rows, hasLength(1));
      expect(rows.single.state, AlertLogState.fired);
      expect(rows.single.source, AlertLogSource.androidJournal);
      expect(rows.single.deviation, const Duration(seconds: 2));
    });

    test('the furthest state wins and the first fire time is kept', () {
      final first = planned.add(const Duration(seconds: 1));
      final rows = JournalImporter.fold(
        [
          _journal(
            'a',
            planned,
            JournalState.acknowledged,
            firedAt: first.add(const Duration(minutes: 3)),
          ),
          _journal('a', planned, JournalState.fired, firedAt: first),
          _journal(
            'a',
            planned,
            JournalState.played,
            firedAt: first.add(const Duration(seconds: 1)),
          ),
        ],
        source: AlertLogSource.androidJournal,
        existing: const {},
      );
      expect(rows.single.state, AlertLogState.acknowledged);
      expect(rows.single.firedAt, first);
    });

    test('a failed service start keeps its cause', () {
      final rows = JournalImporter.fold(
        [
          _journal(
            'a',
            planned,
            JournalState.failed,
            firedAt: planned,
            cause: 'fgs_blocked',
          ),
          _journal('a', planned, JournalState.fired, firedAt: planned),
        ],
        source: AlertLogSource.androidJournal,
        existing: const {},
      );
      expect(rows.single.state, AlertLogState.failed);
      expect(rows.single.cause, AlertCause.fgsBlocked);
    });

    test('a suppressed entry with a state prefix maps to its cause', () {
      final rows = JournalImporter.fold(
        [
          _journal(
            'a',
            planned,
            JournalState.suppressed,
            cause: 'suppressed:call_in_progress',
          ),
        ],
        source: AlertLogSource.androidJournal,
        existing: const {},
      );
      expect(rows.single.state, AlertLogState.suppressed);
      expect(rows.single.cause, AlertCause.callInProgress);
    });

    test('an unrecognised cause becomes unknown, never an exception', () {
      final rows = JournalImporter.fold(
        [_journal('a', planned, JournalState.failed, cause: 'weird')],
        source: AlertLogSource.androidJournal,
        existing: const {},
      );
      expect(rows.single.cause, AlertCause.unknown);
    });

    test('keeps the planned time and cause of the existing row', () {
      final existing = _planned(
        'a',
        planned,
        cause: AlertCause.exactAlarmDenied,
      );
      final rows = JournalImporter.fold(
        [
          _journal(
            'a',
            planned.add(const Duration(minutes: 9)),
            JournalState.fired,
            firedAt: planned.add(const Duration(minutes: 9)),
          ),
        ],
        source: AlertLogSource.androidJournal,
        existing: {'a': existing},
      );
      expect(rows.single.plannedFireAt, planned);
      expect(rows.single.cause, AlertCause.exactAlarmDenied);
    });

    test('never downgrades a row that is already further along', () {
      final existing = AlertLogEntry(
        alertId: 'a',
        plannedFireAt: planned,
        state: AlertLogState.played,
        source: AlertLogSource.inApp,
        firedAt: planned,
      );
      final rows = JournalImporter.fold(
        [_journal('a', planned, JournalState.fired, firedAt: planned)],
        source: AlertLogSource.iosInferred,
        existing: {'a': existing},
      );
      expect(rows.single.state, AlertLogState.played);
    });
  });

  group('JournalImportService', () {
    late AppDatabase db;
    late DriftAlertLogRepository log;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      log = DriftAlertLogRepository(db);
    });
    tearDown(() => db.close());

    test('imports entries then clears the native journal', () async {
      final scheduler = _FakeScheduler(
        platform: AlertPlatform.android,
        journal: [
          _journal(
            'a',
            _now.subtract(const Duration(hours: 2)),
            JournalState.fired,
            firedAt: _now.subtract(const Duration(hours: 2)),
          ),
        ],
      );
      final imported = await JournalImportService(
        scheduler: scheduler,
        log: log,
      ).importNew();
      expect(imported, 1);
      expect(scheduler.cleared, isTrue);
      expect((await log.recent()).single.state, AlertLogState.fired);
    });

    test('does not clear an empty journal', () async {
      final scheduler = _FakeScheduler(platform: AlertPlatform.android);
      expect(
        await JournalImportService(scheduler: scheduler, log: log).importNew(),
        0,
      );
      expect(scheduler.cleared, isFalse);
    });

    test('iOS entries are logged as iosInferred', () async {
      final scheduler = _FakeScheduler(
        platform: AlertPlatform.ios,
        journal: [_journal('a', _now, JournalState.fired)],
      );
      await JournalImportService(scheduler: scheduler, log: log).importNew();
      expect((await log.recent()).single.source, AlertLogSource.iosInferred);
    });
  });

  group('MissedAlertDetector on Android', () {
    const detector = MissedAlertDetector();
    final longAgo = _now.subtract(const Duration(hours: 4));

    DetectionResult detect(
      List<AlertLogEntry> rows, {
      AlertPermissions? permissions,
      DateTime? runsUntil,
    }) => detector.detect(
      now: _now,
      pastPlanned: rows,
      permissions: permissions ?? _androidOk(),
      scheduleRunsUntil: runsUntil,
    );

    test('a planned alert with no journal entry is missed', () {
      final result = detect([_planned('fajr:2026-10-22', longAgo)]);
      final row = result.updates.single;
      expect(row.state, AlertLogState.missed);
      expect(row.cause, AlertCause.unknown);
      expect(result.newlyMissed, [row]);
    });

    test('an alert still inside the grace period is left alone', () {
      final result = detect([
        _planned('a', _now.subtract(const Duration(minutes: 2))),
      ]);
      expect(result.updates, isEmpty);
    });

    test('an inexact alert gets a longer grace period', () {
      final at = _now.subtract(const Duration(minutes: 15));
      expect(detect([_planned('a', at)]).updates, hasLength(1));
      expect(
        detect([_planned('a', at, cause: AlertCause.exactAlarmDenied)]).updates,
        isEmpty,
      );
    });

    test('quiet-hours alerts are silenced, not missed', () {
      final result = detect([
        _planned('isha:2026-10-21', longAgo, cause: AlertCause.quietHours),
      ]);
      final row = result.updates.single;
      expect(row.state, AlertLogState.suppressed);
      expect(row.cause, AlertCause.quietHours);
      expect(result.newlyMissed, isEmpty);
    });

    test('denied notifications explain the miss', () {
      final result = detect([
        _planned('a', longAgo),
      ], permissions: _androidOk(notifications: false));
      expect(result.updates.single.cause, AlertCause.notificationDenied);
    });

    test('an inexact alert that never fired points at exact alarms', () {
      final result = detect([
        _planned('a', longAgo, cause: AlertCause.exactAlarmDenied),
      ]);
      expect(result.updates.single.state, AlertLogState.missed);
      expect(result.updates.single.cause, AlertCause.exactAlarmDenied);
    });

    test('exact alarms denied now explains the miss', () {
      final result = detect([
        _planned('a', longAgo),
      ], permissions: _androidOk(exact: false));
      expect(result.updates.single.cause, AlertCause.exactAlarmDenied);
    });

    test('battery optimization is the next suspect', () {
      final result = detect([
        _planned('a', longAgo),
      ], permissions: _androidOk(battery: false));
      expect(result.updates.single.cause, AlertCause.batteryRestricted);
    });

    test('notifications outrank exact alarms and battery', () {
      final result = detect(
        [_planned('a', longAgo)],
        permissions: _androidOk(
          notifications: false,
          exact: false,
          battery: false,
        ),
      );
      expect(result.updates.single.cause, AlertCause.notificationDenied);
    });

    test(
      'alerts after the end of the schedule are reported as schedule_ended',
      () {
        final ended = _now.subtract(const Duration(hours: 6));
        final result = detect(const [], runsUntil: ended);
        expect(result.scheduleEnded, isNotNull);
        expect(result.scheduleEnded!.state, AlertLogState.missed);
        expect(result.scheduleEnded!.cause, AlertCause.scheduleEnded);
        expect(result.scheduleEnded!.plannedFireAt, ended);
        expect(result.newlyMissed, contains(result.scheduleEnded));
      },
    );

    test('a schedule that has not ended reports nothing', () {
      final result = detect(
        const [],
        runsUntil: _now.add(const Duration(days: 3)),
      );
      expect(result.scheduleEnded, isNull);
    });

    test('with no schedule end known nothing is reported', () {
      expect(detect(const []).scheduleEnded, isNull);
    });

    test('a schedule that ended minutes ago is not yet reported', () {
      final result = detect(
        const [],
        runsUntil: _now.subtract(const Duration(minutes: 1)),
      );
      expect(result.scheduleEnded, isNull);
    });

    test('rows that already have a result are ignored', () {
      final fired = _planned('a', longAgo).copyWith(state: AlertLogState.fired);
      expect(detect([fired]).updates, isEmpty);
    });
  });

  group('MissedAlertDetector on iOS', () {
    const detector = MissedAlertDetector();
    final longAgo = _now.subtract(const Duration(hours: 4));

    DetectionResult detect(
      List<AlertLogEntry> rows, {
      AlertPermissions? permissions,
      DateTime? runsUntil,
    }) => detector.detect(
      now: _now,
      pastPlanned: rows,
      permissions: permissions ?? _iosPermissions(),
      scheduleRunsUntil: runsUntil,
    );

    test('an alert with no trace is possibly missed, never missed', () {
      final result = detect([_planned('a', longAgo)]);
      expect(result.updates.single.state, AlertLogState.possiblyMissed);
      expect(result.newlyMissed, hasLength(1));
    });

    test('denied notifications are named as the likely cause', () {
      final result = detect([
        _planned('a', longAgo),
      ], permissions: _iosPermissions(notifications: false));
      expect(result.updates.single.cause, AlertCause.notificationDenied);
    });

    test('quiet-hours alerts are silenced, not possibly missed', () {
      final result = detect([
        _planned('a', longAgo, cause: AlertCause.quietHours),
      ]);
      expect(result.updates.single.state, AlertLogState.suppressed);
    });

    test('a finished schedule is possibly missed with schedule_ended', () {
      final result = detect(
        const [],
        runsUntil: _now.subtract(const Duration(hours: 5)),
      );
      expect(result.scheduleEnded!.state, AlertLogState.possiblyMissed);
      expect(result.scheduleEnded!.cause, AlertCause.scheduleEnded);
    });
  });
}

class _FakeScheduler implements AlertScheduler {
  _FakeScheduler({required this.platform, this.journal = const []});

  @override
  final AlertPlatform platform;
  final List<JournalEntry> journal;
  bool cleared = false;

  @override
  Future<List<JournalEntry>> readJournal(int sinceEpochMs) async => journal;

  @override
  Future<void> clearJournal() async => cleared = true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void reconcilerTests() {
  group('AlertReconciler', () {
    late AppDatabase db;
    late DriftAlertLogRepository log;
    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      log = DriftAlertLogRepository(db);
    });
    tearDown(() => db.close());

    test(
      'imports the journal before judging, so fired alerts are not missed',
      () async {
        final at = _now.subtract(const Duration(hours: 3));
        await log.syncPlanned([
          PlannedAlertRecord(alertId: 'a', fireAt: at),
          PlannedAlertRecord(alertId: 'b', fireAt: at),
        ], now: at.subtract(const Duration(days: 1)));
        final scheduler = _FakeScheduler(
          platform: AlertPlatform.android,
          journal: [_journal('a', at, JournalState.fired, firedAt: at)],
        );
        final missed = await AlertReconciler(
          scheduler: scheduler,
          log: log,
        ).reconcile(now: _now, permissions: _androidOk());
        expect(missed.map((e) => e.alertId), ['b']);
        final rows = {for (final r in await log.recent()) r.alertId: r.state};
        expect(rows['a'], AlertLogState.fired);
        expect(rows['b'], AlertLogState.missed);
      },
    );

    test('a schedule that ended is reported once', () async {
      final scheduler = _FakeScheduler(platform: AlertPlatform.android);
      final reconciler = AlertReconciler(scheduler: scheduler, log: log);
      final ended = _now.subtract(const Duration(days: 2));
      final first = await reconciler.reconcile(
        now: _now,
        permissions: _androidOk(),
        scheduleRunsUntil: ended,
      );
      final second = await reconciler.reconcile(
        now: _now,
        permissions: _androidOk(),
        scheduleRunsUntil: ended,
      );
      expect(first.single.cause, AlertCause.scheduleEnded);
      expect(second, isEmpty);
    });
  });
}
