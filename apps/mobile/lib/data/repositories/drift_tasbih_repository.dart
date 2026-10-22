import 'package:drift/drift.dart';

import '../../domain/repositories/tasbih_repository.dart';
import '../../domain/result.dart';
import '../../domain/tasbih/tasbih_state.dart';
import '../db/app_database.dart';

/// [TasbihRepository] over `tasbih_state` (one row, id 1) and `tasbih_days`.
/// The row is created on the first change; until then the defaults are read.
class DriftTasbihRepository implements TasbihRepository {
  DriftTasbihRepository(this._db);

  final AppDatabase _db;

  @override
  Future<TasbihState> get() async {
    final row = await _db.select(_db.tasbihStateTable).getSingleOrNull();
    return row == null ? TasbihState.initial : _fromRow(row);
  }

  @override
  Stream<TasbihState> watch() {
    return _db
        .select(_db.tasbihStateTable)
        .watchSingleOrNull()
        .map((row) => row == null ? TasbihState.initial : _fromRow(row));
  }

  @override
  Future<TasbihState> increment(String localDate) {
    return _db.transaction(() async {
      final current = await get();
      final next = current.copyWith(count: current.count + 1);
      await _save(next);

      final day = await (_db.select(
        _db.tasbihDaysTable,
      )..where((t) => t.date.equals(localDate))).getSingleOrNull();
      await _db
          .into(_db.tasbihDaysTable)
          .insertOnConflictUpdate(
            TasbihDaysTableCompanion.insert(
              date: localDate,
              total: Value((day?.total ?? 0) + 1),
            ),
          );
      return next;
    });
  }

  @override
  Future<TasbihState> resetCount() {
    return _db.transaction(() async {
      final next = (await get()).copyWith(count: 0);
      await _save(next);
      return next;
    });
  }

  @override
  Future<Result<void>> setTarget(int target) async {
    if (!TasbihState.isValidTarget(target)) {
      return const Err(
        AppError(
          ErrorCode.invalidArgument,
          'The target must be a whole number from 1 to 100000.',
        ),
      );
    }
    await _db.transaction(() async {
      await _save((await get()).copyWith(target: target));
    });
    return const Ok(null);
  }

  @override
  Future<void> setOptions({
    bool? keepAwake,
    bool? volumeKeys,
    bool? lock,
    bool? haptics,
    bool? sound,
  }) {
    return _db.transaction(() async {
      await _save(
        (await get()).copyWith(
          keepAwake: keepAwake,
          volumeKeys: volumeKeys,
          lock: lock,
          haptics: haptics,
          sound: sound,
        ),
      );
    });
  }

  @override
  Stream<List<TasbihDay>> watchDays({int limit = 30}) {
    final query = _db.select(_db.tasbihDaysTable)
      ..orderBy([(t) => OrderingTerm.desc(t.date)])
      ..limit(limit);
    return query.watch().map(
      (rows) => [for (final row in rows) TasbihDay(row.date, row.total)],
    );
  }

  Future<void> _save(TasbihState state) {
    return _db
        .into(_db.tasbihStateTable)
        .insertOnConflictUpdate(
          TasbihStateTableCompanion.insert(
            id: const Value(1),
            count: Value(state.count),
            target: Value(state.target),
            keepAwake: Value(state.keepAwake),
            volumeKeys: Value(state.volumeKeys),
            lock: Value(state.lock),
            haptics: Value(state.haptics),
            sound: Value(state.sound),
          ),
        );
  }

  static TasbihState _fromRow(TasbihStateTableData row) {
    return TasbihState(
      count: row.count,
      target: row.target,
      keepAwake: row.keepAwake,
      volumeKeys: row.volumeKeys,
      lock: row.lock,
      haptics: row.haptics,
      sound: row.sound,
    );
  }
}
