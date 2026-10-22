import 'package:deen_mobile/data/db/app_database.dart';
import 'package:deen_mobile/data/repositories/drift_alert_log_repository.dart';
import 'package:deen_mobile/domain/alerts/alert_log_entry.dart';
import 'package:deen_mobile/domain/entities/enums.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime.utc(2026, 10, 22, 12);

PlannedAlertRecord _planned(String id, DateTime at, {AlertCause? cause}) =>
    PlannedAlertRecord(alertId: id, fireAt: at, cause: cause);

AlertLogEntry _entry(
  String id,
  DateTime at,
  AlertLogState state, {
  AlertLogSource source = AlertLogSource.androidJournal,
  DateTime? firedAt,
  AlertCause? cause,
}) => AlertLogEntry(
  alertId: id,
  plannedFireAt: at,
  state: state,
  source: source,
  firedAt: firedAt,
  cause: cause,
);

void main() {
  late AppDatabase db;
  late DriftAlertLogRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = DriftAlertLogRepository(db);
  });

  tearDown(() => db.close());

  group('syncPlanned', () {
    test('inserts planned rows for new ids', () async {
      final at = _now.add(const Duration(hours: 3));
      await repo.syncPlanned([_planned('asr:2026-10-22', at)], now: _now);
      final rows = await repo.recent();
      expect(rows, hasLength(1));
      expect(rows.single.state, AlertLogState.planned);
      expect(rows.single.plannedFireAt, at);
      expect(rows.single.source, AlertLogSource.inApp);
    });

    test('updates time and cause of a planned row', () async {
      final first = _now.add(const Duration(hours: 3));
      final second = _now.add(const Duration(hours: 4));
      await repo.syncPlanned([_planned('asr:2026-10-22', first)], now: _now);
      await repo.syncPlanned([
        _planned('asr:2026-10-22', second, cause: AlertCause.quietHours),
      ], now: _now);
      final row = (await repo.recent()).single;
      expect(row.plannedFireAt, second);
      expect(row.cause, AlertCause.quietHours);
    });

    test('removes future planned rows that left the plan', () async {
      final at = _now.add(const Duration(hours: 3));
      await repo.syncPlanned([
        _planned('asr:2026-10-22', at),
        _planned('maghrib:2026-10-22', at.add(const Duration(hours: 3))),
      ], now: _now);
      await repo.syncPlanned([_planned('asr:2026-10-22', at)], now: _now);
      final ids = (await repo.recent()).map((e) => e.alertId);
      expect(ids, ['asr:2026-10-22']);
    });

    test('keeps past planned rows so they can be judged missed', () async {
      final past = _now.subtract(const Duration(hours: 5));
      await repo.syncPlanned([_planned('fajr:2026-10-22', past)], now: past);
      await repo.syncPlanned([], now: _now);
      expect(await repo.plannedUpTo(_now), hasLength(1));
    });

    test('never rewrites a row that already has a result', () async {
      final at = _now.subtract(const Duration(hours: 1));
      await repo.upsertAll([
        _entry('dhuhr:2026-10-22', at, AlertLogState.played),
      ]);
      await repo.syncPlanned([
        _planned('dhuhr:2026-10-22', _now.add(const Duration(hours: 2))),
      ], now: _now);
      final row = (await repo.recent()).single;
      expect(row.state, AlertLogState.played);
      expect(row.plannedFireAt, at);
    });
  });

  group('queries', () {
    test(
      'plannedUpTo returns only planned rows at or before the instant',
      () async {
        await repo.upsertAll([
          _entry(
            'a',
            _now.subtract(const Duration(hours: 2)),
            AlertLogState.planned,
            source: AlertLogSource.inApp,
          ),
          _entry(
            'b',
            _now.add(const Duration(hours: 2)),
            AlertLogState.planned,
            source: AlertLogSource.inApp,
          ),
          _entry(
            'c',
            _now.subtract(const Duration(hours: 3)),
            AlertLogState.fired,
          ),
        ]);
        final ids = (await repo.plannedUpTo(_now)).map((e) => e.alertId);
        expect(ids, ['a']);
      },
    );

    test('lastResult skips planned rows and future rows', () async {
      await repo.upsertAll([
        _entry(
          'old',
          _now.subtract(const Duration(hours: 9)),
          AlertLogState.fired,
        ),
        _entry(
          'new',
          _now.subtract(const Duration(hours: 2)),
          AlertLogState.missed,
        ),
        _entry(
          'pending',
          _now.subtract(const Duration(hours: 1)),
          AlertLogState.planned,
          source: AlertLogSource.inApp,
        ),
        _entry(
          'future',
          _now.add(const Duration(hours: 1)),
          AlertLogState.fired,
        ),
      ]);
      final last = await repo.lastResult(instant: _now);
      expect(last?.alertId, 'new');
    });

    test('lastResult is null when nothing has happened yet', () async {
      expect(await repo.lastResult(instant: _now), isNull);
    });

    test('deviation is the gap between planned and fired time', () async {
      final at = _now.subtract(const Duration(hours: 1));
      await repo.upsertAll([
        _entry(
          'x',
          at,
          AlertLogState.fired,
          firedAt: at.add(const Duration(milliseconds: 1800)),
        ),
      ]);
      final row = (await repo.recent()).single;
      expect(row.deviation, const Duration(milliseconds: 1800));
      expect(row.firedAt, at.add(const Duration(milliseconds: 1800)));
    });

    test(
      'hasPlayed and playedAlertIds reflect played and acknowledged rows',
      () async {
        await repo.upsertAll([
          _entry('p', _now, AlertLogState.played),
          _entry('q', _now, AlertLogState.fired),
          _entry('r', _now, AlertLogState.acknowledged),
        ]);
        expect(await repo.hasPlayed('p'), isTrue);
        expect(await repo.hasPlayed('q'), isFalse);
        expect(await repo.hasPlayed('r'), isTrue);
        expect(await repo.playedAlertIds(), {'p', 'r'});
      },
    );

    test('forAlertIds returns the matching rows', () async {
      await repo.upsertAll([
        _entry('a', _now, AlertLogState.fired),
        _entry('b', _now, AlertLogState.fired),
      ]);
      final rows = await repo.forAlertIds(['b', 'zzz']);
      expect(rows.map((e) => e.alertId), ['b']);
    });

    test('upsertAll replaces a row with the same id and attempt', () async {
      await repo.upsertAll([_entry('a', _now, AlertLogState.fired)]);
      await repo.upsertAll([_entry('a', _now, AlertLogState.acknowledged)]);
      final rows = await repo.recent();
      expect(rows, hasLength(1));
      expect(rows.single.state, AlertLogState.acknowledged);
    });

    test('recent is newest first and respects the limit', () async {
      await repo.upsertAll([
        for (var i = 0; i < 5; i++)
          _entry('e$i', _now.add(Duration(hours: i)), AlertLogState.fired),
      ]);
      final rows = await repo.recent(limit: 2);
      expect(rows.map((e) => e.alertId), ['e4', 'e3']);
    });

    test('causes survive a round trip', () async {
      await repo.upsertAll([
        _entry('a', _now, AlertLogState.failed, cause: AlertCause.fgsBlocked),
      ]);
      expect((await repo.recent()).single.cause, AlertCause.fgsBlocked);
    });

    test('watchRecent emits when rows change', () async {
      final emissions = <int>[];
      final sub = repo.watchRecent().listen(
        (rows) => emissions.add(rows.length),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await repo.upsertAll([_entry('a', _now, AlertLogState.fired)]);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await sub.cancel();
      expect(emissions.first, 0);
      expect(emissions.last, 1);
    });
  });

  group('housekeeping', () {
    test('pruneBefore drops old rows only', () async {
      await repo.upsertAll([
        _entry(
          'old',
          _now.subtract(const Duration(days: 100)),
          AlertLogState.fired,
        ),
        _entry(
          'new',
          _now.subtract(const Duration(days: 1)),
          AlertLogState.fired,
        ),
      ]);
      await repo.pruneBefore(_now.subtract(const Duration(days: 90)));
      expect((await repo.recent()).map((e) => e.alertId), ['new']);
    });

    test('clear removes everything', () async {
      await repo.upsertAll([_entry('a', _now, AlertLogState.fired)]);
      await repo.clear();
      expect(await repo.recent(), isEmpty);
    });
  });
}
