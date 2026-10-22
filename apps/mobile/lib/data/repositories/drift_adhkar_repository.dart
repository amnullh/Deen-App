import 'package:drift/drift.dart';

import '../../domain/adhkar/adhkar_bookmark.dart';
import '../../domain/adhkar/adhkar_progress.dart';
import '../../domain/adhkar/adhkar_reminder.dart';
import '../../domain/entities/enums.dart';
import '../../domain/repositories/adhkar_repository.dart';
import '../../domain/result.dart';
import '../db/app_database.dart';

DateTime _fromMs(int ms) =>
    DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);

class DriftAdhkarProgressRepository implements AdhkarProgressRepository {
  DriftAdhkarProgressRepository(this._db);

  final AppDatabase _db;

  @override
  Future<Result<void>> saveAll(List<AdhkarProgressRecord> records) async {
    if (records.any((r) => r.completedCount < 0)) {
      return const Err(
        AppError(ErrorCode.invalidArgument, 'A count cannot be negative.'),
      );
    }
    await _db.transaction(() async {
      for (final r in records) {
        await _db
            .into(_db.adhkarProgressTable)
            .insertOnConflictUpdate(
              AdhkarProgressTableCompanion.insert(
                sessionId: r.sessionId,
                collectionId: r.collectionId,
                entryId: r.entryId,
                completedCount: Value(r.completedCount),
                startedAtMs: r.startedAt.millisecondsSinceEpoch,
                finishedAtMs: Value(r.finishedAt?.millisecondsSinceEpoch),
              ),
            );
      }
    });
    return const Ok(null);
  }

  @override
  Future<List<AdhkarProgressRecord>> recordsForSession(String sessionId) async {
    final rows =
        await (_db.select(_db.adhkarProgressTable)
              ..where((t) => t.sessionId.equals(sessionId))
              ..orderBy([(t) => OrderingTerm.asc(t.entryId)]))
            .get();
    return rows.map(_fromRow).toList();
  }

  @override
  Future<List<AdhkarProgressRecord>> unfinishedSession(
    String collectionId,
  ) async {
    final open =
        await (_db.select(_db.adhkarProgressTable)
              ..where(
                (t) =>
                    t.collectionId.equals(collectionId) &
                    t.finishedAtMs.isNull(),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.startedAtMs)])
              ..limit(1))
            .getSingleOrNull();
    return open == null ? const [] : recordsForSession(open.sessionId);
  }

  @override
  Future<void> clear() => _db.delete(_db.adhkarProgressTable).go();

  static AdhkarProgressRecord _fromRow(AdhkarProgressTableData row) {
    final finished = row.finishedAtMs;
    return AdhkarProgressRecord(
      sessionId: row.sessionId,
      collectionId: row.collectionId,
      entryId: row.entryId,
      completedCount: row.completedCount,
      startedAt: _fromMs(row.startedAtMs),
      finishedAt: finished == null ? null : _fromMs(finished),
    );
  }
}

class DriftAdhkarBookmarkRepository implements AdhkarBookmarkRepository {
  DriftAdhkarBookmarkRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<AdhkarBookmark>> getAll() async {
    return _query().get().then((rows) => rows.map(_fromRow).toList());
  }

  @override
  Stream<List<AdhkarBookmark>> watchAll() {
    return _query().watch().map((rows) => rows.map(_fromRow).toList());
  }

  SimpleSelectStatement<$AdhkarBookmarkTableTable, AdhkarBookmarkTableData>
  _query() => _db.select(_db.adhkarBookmarkTable)
    ..orderBy([
      (t) => OrderingTerm.asc(t.createdAtMs),
      (t) => OrderingTerm.asc(t.entryId),
    ]);

  @override
  Future<bool> toggle(String entryId, {required DateTime now}) {
    return _db.transaction(() async {
      final removed = await (_db.delete(
        _db.adhkarBookmarkTable,
      )..where((t) => t.entryId.equals(entryId))).go();
      if (removed > 0) return false;
      await _db
          .into(_db.adhkarBookmarkTable)
          .insert(
            AdhkarBookmarkTableCompanion.insert(
              entryId: entryId,
              createdAtMs: now.millisecondsSinceEpoch,
            ),
          );
      return true;
    });
  }

  @override
  Future<void> replaceAll(List<AdhkarBookmark> bookmarks) {
    return _db.transaction(() async {
      await _db.delete(_db.adhkarBookmarkTable).go();
      for (final b in bookmarks) {
        await _db
            .into(_db.adhkarBookmarkTable)
            .insertOnConflictUpdate(
              AdhkarBookmarkTableCompanion.insert(
                entryId: b.entryId,
                createdAtMs: b.createdAt.millisecondsSinceEpoch,
              ),
            );
      }
    });
  }

  @override
  Future<void> clear() => _db.delete(_db.adhkarBookmarkTable).go();

  static AdhkarBookmark _fromRow(AdhkarBookmarkTableData row) =>
      AdhkarBookmark(entryId: row.entryId, createdAt: _fromMs(row.createdAtMs));
}

class DriftAdhkarReminderRepository implements AdhkarReminderRepository {
  DriftAdhkarReminderRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<AdhkarReminder>> getAll() async {
    return _withDefaults(await _db.select(_db.adhkarReminderTable).get());
  }

  @override
  Stream<List<AdhkarReminder>> watchAll() {
    return _db.select(_db.adhkarReminderTable).watch().map(_withDefaults);
  }

  @override
  Future<Result<void>> save(AdhkarReminder reminder) => saveAll([reminder]);

  @override
  Future<Result<void>> saveAll(List<AdhkarReminder> reminders) async {
    for (final reminder in reminders) {
      final error = reminder.validate();
      if (error != null) return Err(error);
    }
    await _db.transaction(() async {
      for (final r in reminders) {
        await _db
            .into(_db.adhkarReminderTable)
            .insertOnConflictUpdate(
              AdhkarReminderTableCompanion.insert(
                kind: r.kind,
                anchor: r.anchor,
                offsetMinutes: Value(r.offsetMinutes),
                enabled: Value(r.enabled),
              ),
            );
      }
    });
    return const Ok(null);
  }

  @override
  Future<void> clear() => _db.delete(_db.adhkarReminderTable).go();

  static List<AdhkarReminder> _withDefaults(
    List<AdhkarReminderTableData> rows,
  ) {
    final byKind = {for (final row in rows) row.kind: row};
    return [
      for (final kind in AdhkarReminderKind.values)
        if (byKind[kind] case final row?)
          AdhkarReminder(
            kind: kind,
            anchor: row.anchor,
            offsetMinutes: row.offsetMinutes,
            enabled: row.enabled,
          )
        else
          AdhkarReminder.defaultFor(kind),
    ];
  }
}
