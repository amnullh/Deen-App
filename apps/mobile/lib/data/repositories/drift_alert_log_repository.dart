import 'package:drift/drift.dart';

import '../../domain/alerts/alert_log_entry.dart';
import '../../domain/entities/enums.dart';
import '../../domain/repositories/alert_log_repository.dart';
import '../db/app_database.dart';

/// [AlertLogRepository] over the `alert_log` table.
class DriftAlertLogRepository implements AlertLogRepository {
  DriftAlertLogRepository(this._db);

  final AppDatabase _db;

  $AlertLogTableTable get _table => _db.alertLogTable;

  /// An acknowledged alert was played first, so it still counts as played for
  /// the arbiter.
  static const _playedStates = [
    AlertLogState.played,
    AlertLogState.acknowledged,
  ];

  @override
  Future<void> syncPlanned(
    List<PlannedAlertRecord> plan, {
    required DateTime now,
  }) {
    return _db.transaction(() async {
      final nowMs = now.millisecondsSinceEpoch;
      final existing = await (_db.select(
        _table,
      )..where((t) => t.attempt.equals(0))).get();
      final byId = {for (final row in existing) row.alertId: row};
      final planIds = {for (final record in plan) record.alertId};

      for (final row in existing) {
        final gone = !planIds.contains(row.alertId);
        if (gone &&
            row.state == AlertLogState.planned &&
            row.plannedFireAtMs > nowMs) {
          await (_db.delete(_table)..where(
                (t) => t.alertId.equals(row.alertId) & t.attempt.equals(0),
              ))
              .go();
        }
      }

      await _db.batch((batch) {
        for (final record in plan) {
          final row = byId[record.alertId];
          if (row != null && row.state != AlertLogState.planned) continue;
          batch.insert(
            _table,
            AlertLogTableCompanion.insert(
              alertId: record.alertId,
              plannedFireAtMs: record.fireAt.millisecondsSinceEpoch,
              state: AlertLogState.planned,
              source: AlertLogSource.inApp,
              cause: Value(record.cause?.wire),
            ),
            mode: InsertMode.insertOrReplace,
          );
        }
      });
    });
  }

  @override
  Future<void> upsertAll(List<AlertLogEntry> entries) {
    return _db.batch((batch) {
      for (final entry in entries) {
        batch.insert(
          _table,
          AlertLogTableCompanion.insert(
            alertId: entry.alertId,
            attempt: Value(entry.attempt),
            plannedFireAtMs: entry.plannedFireAt.millisecondsSinceEpoch,
            state: entry.state,
            firedAtMs: Value(entry.firedAt?.millisecondsSinceEpoch),
            deviationMs: Value(entry.deviation?.inMilliseconds),
            cause: Value(entry.cause?.wire),
            source: entry.source,
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  @override
  Future<List<AlertLogEntry>> plannedUpTo(DateTime instant) async {
    final rows =
        await (_db.select(_table)
              ..where(
                (t) =>
                    t.state.equalsValue(AlertLogState.planned) &
                    t.plannedFireAtMs.isSmallerOrEqualValue(
                      instant.millisecondsSinceEpoch,
                    ),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.plannedFireAtMs)]))
            .get();
    return rows.map(_fromRow).toList();
  }

  @override
  Future<List<AlertLogEntry>> forAlertIds(Iterable<String> alertIds) async {
    final ids = alertIds.toList();
    if (ids.isEmpty) return const [];
    final rows = await (_db.select(
      _table,
    )..where((t) => t.alertId.isIn(ids))).get();
    return rows.map(_fromRow).toList();
  }

  @override
  Future<AlertLogEntry?> lastResult({required DateTime instant}) async {
    final row =
        await (_db.select(_table)
              ..where(
                (t) =>
                    t.state.equalsValue(AlertLogState.planned).not() &
                    t.plannedFireAtMs.isSmallerOrEqualValue(
                      instant.millisecondsSinceEpoch,
                    ),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.plannedFireAtMs)])
              ..limit(1))
            .getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  SimpleSelectStatement<$AlertLogTableTable, AlertLogTableData> _recentQuery(
    int limit,
  ) {
    return _db.select(_table)
      ..orderBy([(t) => OrderingTerm.desc(t.plannedFireAtMs)])
      ..limit(limit);
  }

  @override
  Future<List<AlertLogEntry>> recent({int limit = 50}) async {
    final rows = await _recentQuery(limit).get();
    return rows.map(_fromRow).toList();
  }

  @override
  Stream<List<AlertLogEntry>> watchRecent({int limit = 50}) {
    return _recentQuery(limit)
        .watch()
        .map((rows) => rows.map(_fromRow).toList());
  }

  @override
  Future<bool> hasPlayed(String alertId) async {
    final row =
        await (_db.select(_table)
              ..where(
                (t) =>
                    t.alertId.equals(alertId) &
                    t.state.isInValues(_playedStates),
              )
              ..limit(1))
            .getSingleOrNull();
    return row != null;
  }

  @override
  Future<Set<String>> playedAlertIds() async {
    final rows = await (_db.select(
      _table,
    )..where((t) => t.state.isInValues(_playedStates))).get();
    return {for (final row in rows) row.alertId};
  }

  @override
  Future<void> pruneBefore(DateTime instant) async {
    await (_db.delete(_table)..where(
          (t) => t.plannedFireAtMs.isSmallerThanValue(
            instant.millisecondsSinceEpoch,
          ),
        ))
        .go();
  }

  @override
  Future<void> clear() async {
    await _db.delete(_table).go();
  }

  static AlertLogEntry _fromRow(AlertLogTableData row) {
    final firedAtMs = row.firedAtMs;
    return AlertLogEntry(
      alertId: row.alertId,
      attempt: row.attempt,
      plannedFireAt: DateTime.fromMillisecondsSinceEpoch(
        row.plannedFireAtMs,
        isUtc: true,
      ),
      state: row.state,
      source: row.source,
      firedAt: firedAtMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(firedAtMs, isUtc: true),
      cause: AlertCause.fromWire(row.cause),
    );
  }
}
