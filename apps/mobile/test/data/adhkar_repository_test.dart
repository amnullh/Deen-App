import 'package:deen_mobile/data/db/app_database.dart';
import 'package:deen_mobile/data/repositories/drift_adhkar_repository.dart';
import 'package:deen_mobile/domain/adhkar/adhkar_bookmark.dart';
import 'package:deen_mobile/domain/adhkar/adhkar_progress.dart';
import 'package:deen_mobile/domain/adhkar/adhkar_reminder.dart';
import 'package:deen_mobile/domain/entities/enums.dart';
import 'package:deen_mobile/domain/result.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

AdhkarProgressRecord _record(
  String session,
  String entry,
  int count, {
  String collection = 'morning',
  DateTime? started,
  DateTime? finished,
}) {
  return AdhkarProgressRecord(
    sessionId: session,
    collectionId: collection,
    entryId: entry,
    completedCount: count,
    startedAt: started ?? DateTime.utc(2026, 10, 21, 5),
    finishedAt: finished,
  );
}

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  group('AdhkarProgressRepository', () {
    test('saves and reads back a session, updating in place', () async {
      final repo = DriftAdhkarProgressRepository(db);
      expect((await repo.saveAll([_record('s1', 'e1', 1)])).isOk, isTrue);
      expect(
        (await repo.saveAll([_record('s1', 'e1', 2), _record('s1', 'e2', 1)]))
            .isOk,
        isTrue,
      );
      final rows = await repo.recordsForSession('s1');
      expect(rows.map((r) => (r.entryId, r.completedCount)), [
        ('e1', 2),
        ('e2', 1),
      ]);
      expect(rows.first.startedAt, DateTime.utc(2026, 10, 21, 5));
    });

    test('rejects a negative count and saves nothing', () async {
      final repo = DriftAdhkarProgressRepository(db);
      final result = await repo.saveAll([
        _record('s1', 'e1', 1),
        _record('s1', 'e2', -1),
      ]);
      expect(result.errorOrNull?.code, ErrorCode.invalidArgument);
      expect(await repo.recordsForSession('s1'), isEmpty);
    });

    test('finds the newest unfinished session of a collection', () async {
      final repo = DriftAdhkarProgressRepository(db);
      await repo.saveAll([
        _record('old', 'e1', 1, started: DateTime.utc(2026, 10, 20)),
        _record(
          'done',
          'e1',
          1,
          started: DateTime.utc(2026, 10, 21),
          finished: DateTime.utc(2026, 10, 21, 1),
        ),
        _record('new', 'e1', 1, started: DateTime.utc(2026, 10, 22)),
        _record(
          'other',
          'x1',
          1,
          collection: 'evening',
          started: DateTime.utc(2026, 10, 23),
        ),
      ]);
      final open = await repo.unfinishedSession('morning');
      expect(open.map((r) => r.sessionId).toSet(), {'new'});
      expect(await repo.unfinishedSession('waking'), isEmpty);
    });

    test('clear removes everything', () async {
      final repo = DriftAdhkarProgressRepository(db);
      await repo.saveAll([_record('s1', 'e1', 1)]);
      await repo.clear();
      expect(await repo.recordsForSession('s1'), isEmpty);
    });
  });

  group('AdhkarBookmarkRepository', () {
    test('toggle adds then removes', () async {
      final repo = DriftAdhkarBookmarkRepository(db);
      final t = DateTime.utc(2026, 10, 21, 8);
      expect(await repo.toggle('e1', now: t), isTrue);
      expect((await repo.getAll()).single.entryId, 'e1');
      expect((await repo.getAll()).single.createdAt, t);
      expect(await repo.toggle('e1', now: t), isFalse);
      expect(await repo.getAll(), isEmpty);
    });

    test('watchAll emits changes', () async {
      final repo = DriftAdhkarBookmarkRepository(db);
      final emitted = <List<String>>[];
      final sub = repo.watchAll().listen(
        (list) => emitted.add(list.map((b) => b.entryId).toList()),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await repo.toggle('e1', now: DateTime.utc(2026));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await sub.cancel();
      expect(emitted.first, isEmpty);
      expect(emitted.last, ['e1']);
    });

    test('replaceAll swaps the whole set', () async {
      final repo = DriftAdhkarBookmarkRepository(db);
      await repo.toggle('old', now: DateTime.utc(2026));
      await repo.replaceAll([
        AdhkarBookmark(entryId: 'a', createdAt: DateTime.utc(2026, 1, 1)),
        AdhkarBookmark(entryId: 'b', createdAt: DateTime.utc(2026, 1, 2)),
      ]);
      expect((await repo.getAll()).map((b) => b.entryId).toSet(), {'a', 'b'});
    });
  });

  group('AdhkarReminderRepository', () {
    test('returns defaults, switched off, before anything is saved', () async {
      final all = await DriftAdhkarReminderRepository(db).getAll();
      expect(all.map((r) => r.kind), AdhkarReminderKind.values);
      expect(all.every((r) => !r.enabled), isTrue);
      expect(all[0].anchor, ReminderAnchor.fajr);
      expect(all[1].anchor, ReminderAnchor.asr);
    });

    test('round-trips an evening reminder after Maghrib', () async {
      final repo = DriftAdhkarReminderRepository(db);
      const saved = AdhkarReminder(
        kind: AdhkarReminderKind.evening,
        anchor: ReminderAnchor.maghrib,
        offsetMinutes: -15,
        enabled: true,
      );
      expect((await repo.save(saved)).isOk, isTrue);
      final evening = (await repo.getAll())[1];
      expect(evening.anchor, ReminderAnchor.maghrib);
      expect(evening.offsetMinutes, -15);
      expect(evening.enabled, isTrue);
    });

    test('rejects a morning reminder anchored to Asr', () async {
      final repo = DriftAdhkarReminderRepository(db);
      final result = await repo.save(
        const AdhkarReminder(
          kind: AdhkarReminderKind.morning,
          anchor: ReminderAnchor.asr,
          offsetMinutes: 0,
        ),
      );
      expect(result.errorOrNull?.code, ErrorCode.invalidArgument);
    });

    test('rejects an offset out of range', () async {
      final repo = DriftAdhkarReminderRepository(db);
      final result = await repo.save(
        AdhkarReminder.defaultFor(AdhkarReminderKind.morning)
            .copyWith(offsetMinutes: 121),
      );
      expect(result.errorOrNull?.code, ErrorCode.invalidArgument);
    });

    test('saveAll is all-or-nothing', () async {
      final repo = DriftAdhkarReminderRepository(db);
      final good = AdhkarReminder.defaultFor(AdhkarReminderKind.morning)
          .copyWith(enabled: true, offsetMinutes: 45);
      final bad = AdhkarReminder.defaultFor(AdhkarReminderKind.evening)
          .copyWith(offsetMinutes: 999);
      expect((await repo.saveAll([good, bad])).isOk, isFalse);
      expect((await repo.getAll())[0].enabled, isFalse);
      expect((await repo.saveAll([good])).isOk, isTrue);
      expect((await repo.getAll())[0].offsetMinutes, 45);
    });
  });
}
