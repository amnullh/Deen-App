import 'dart:io';

import 'package:deen_mobile/data/db/app_database.dart';
import 'package:deen_mobile/data/repositories/drift_tasbih_repository.dart';
import 'package:deen_mobile/domain/result.dart';
import 'package:deen_mobile/domain/tasbih/tasbih_state.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late AppDatabase db;
  late DriftTasbihRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = DriftTasbihRepository(db);
  });

  tearDown(() => db.close());

  test('a fresh database reads as the defaults without writing', () async {
    expect((await repository.get()).count, 0);
    expect((await repository.get()).target, 33);
    expect((await repository.get()).haptics, isTrue);
    expect(await db.select(db.tasbihStateTable).get(), isEmpty);
  });

  test('increment adds one to the count and to the day', () async {
    await repository.increment('2026-10-21');
    final state = await repository.increment('2026-10-21');
    expect(state.count, 2);
    final days = await repository.watchDays().first;
    expect(days.single.date, '2026-10-21');
    expect(days.single.total, 2);
  });

  test('days are listed newest first and limited', () async {
    for (final date in ['2026-10-19', '2026-10-21', '2026-10-20']) {
      await repository.increment(date);
    }
    final days = await repository.watchDays(limit: 2).first;
    expect(days.map((d) => d.date), ['2026-10-21', '2026-10-20']);
  });

  test('resetCount zeroes the count and keeps totals and settings', () async {
    await repository.setTarget(99);
    await repository.setOptions(sound: true);
    await repository.increment('2026-10-21');
    final state = await repository.resetCount();
    expect(state.count, 0);
    expect(state.target, 99);
    expect(state.sound, isTrue);
    expect((await repository.watchDays().first).single.total, 1);
  });

  test('setTarget validates 1..100000', () async {
    expect((await repository.setTarget(1)).isOk, isTrue);
    expect((await repository.setTarget(100000)).isOk, isTrue);
    for (final bad in [0, -3, 100001]) {
      final result = await repository.setTarget(bad);
      expect(result.errorOrNull?.code, ErrorCode.invalidArgument);
    }
    expect((await repository.get()).target, 100000);
  });

  test('setOptions changes only the given options', () async {
    await repository.setOptions(keepAwake: true, volumeKeys: true);
    await repository.setOptions(lock: true);
    final state = await repository.get();
    expect(state.keepAwake, isTrue);
    expect(state.volumeKeys, isTrue);
    expect(state.lock, isTrue);
    expect(state.haptics, isTrue);
    expect(state.sound, isFalse);
  });

  test('watch emits the current state and then each change', () async {
    final seen = <int>[];
    final subscription = repository.watch().listen((s) => seen.add(s.count));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await repository.increment('2026-10-21');
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await subscription.cancel();
    expect(seen.first, 0);
    expect(seen.last, 1);
  });

  test('many quick increments are not lost', () async {
    await Future.wait([
      for (var i = 0; i < 50; i++) repository.increment('2026-10-21'),
    ]);
    expect((await repository.get()).count, 50);
    expect((await repository.watchDays().first).single.total, 50);
  });

  test('state values round-trip', () async {
    await repository.setTarget(250);
    await repository.setOptions(
      keepAwake: true,
      volumeKeys: true,
      lock: true,
      haptics: false,
      sound: true,
    );
    final state = await repository.get();
    expect(
      (
        state.target,
        state.keepAwake,
        state.volumeKeys,
        state.lock,
        state.haptics,
        state.sound,
      ),
      (250, true, true, true, false, true),
    );
    expect(state, isA<TasbihState>());
  });

  test('a counter on disk is intact after the database is reopened', () async {
    final directory = Directory.systemTemp.createTempSync('tasbih_repo');
    addTearDown(() => directory.deleteSync(recursive: true));
    final file = File(p.join(directory.path, 'app.db'));

    var disk = AppDatabase(NativeDatabase(file));
    final first = DriftTasbihRepository(disk);
    await first.setTarget(99);
    await first.increment('2026-10-21');
    await first.increment('2026-10-21');
    await disk.close();

    disk = AppDatabase(NativeDatabase(file));
    final reopened = DriftTasbihRepository(disk);
    expect((await reopened.get()).count, 2);
    expect((await reopened.get()).target, 99);
    expect((await reopened.watchDays().first).single.total, 2);
    await disk.close();
  });
}
