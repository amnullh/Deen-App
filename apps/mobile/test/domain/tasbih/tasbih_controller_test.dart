import 'package:deen_mobile/domain/result.dart';
import 'package:deen_mobile/domain/tasbih/tasbih_controller.dart';
import 'package:deen_mobile/domain/tasbih/tasbih_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_tasbih_repository.dart';

class _Clock {
  DateTime now = DateTime(2026, 10, 21, 9, 30);
  DateTime call() => now;
}

void main() {
  late FakeTasbihRepository repository;
  late _Clock clock;
  late TasbihController controller;

  setUp(() {
    repository = FakeTasbihRepository();
    clock = _Clock();
    controller = TasbihController(repository: repository, clock: clock.call);
  });

  group('counting', () {
    test('starts at 0 of 33', () async {
      final state = await repository.get();
      expect(state.count, 0);
      expect(state.target, 33);
    });

    test('each tap adds one', () async {
      for (var i = 0; i < 5; i++) {
        await controller.tap();
      }
      expect((await repository.get()).count, 5);
    });

    test('a tap reports the new count', () async {
      final outcome = await controller.tap();
      expect(outcome.counted, isTrue);
      expect(outcome.count, 1);
      expect(outcome.roundCompleted, isFalse);
    });

    test('reaching the target completes a round', () async {
      await controller.setTarget(3);
      await controller.tap();
      await controller.tap();
      final third = await controller.tap();
      expect(third.roundCompleted, isTrue);
      expect(third.count, 3);
    });

    test(
      'counting continues past the target and completes later rounds',
      () async {
        await controller.setTarget(2);
        final outcomes = [for (var i = 0; i < 5; i++) await controller.tap()];
        expect(outcomes.map((o) => o.roundCompleted), [
          false,
          true,
          false,
          true,
          false,
        ]);
        final state = await repository.get();
        expect(state.count, 5);
        expect(state.roundsCompleted, 2);
      },
    );
  });

  group('targets', () {
    test('33, 99 and any value from 1 to 100000 are accepted', () async {
      for (final target in [33, 99, 1, 100000, 250]) {
        final result = await controller.setTarget(target);
        expect(result.isOk, isTrue, reason: '$target');
        expect((await repository.get()).target, target);
      }
    });

    test('values outside 1..100000 are refused and change nothing', () async {
      await controller.setTarget(99);
      for (final target in [0, -1, 100001, 5000000]) {
        final result = await controller.setTarget(target);
        expect(result.errorOrNull?.code, ErrorCode.invalidArgument);
        expect((await repository.get()).target, 99);
      }
    });

    test('changing the target keeps the count', () async {
      await controller.tap();
      await controller.tap();
      await controller.setTarget(99);
      expect((await repository.get()).count, 2);
    });
  });

  group('reset', () {
    test('without confirmation nothing happens', () async {
      await controller.tap();
      final done = await controller.reset(confirmed: false);
      expect(done, isFalse);
      expect((await repository.get()).count, 1);
    });

    test('with confirmation the count returns to 0', () async {
      await controller.tap();
      await controller.tap();
      final done = await controller.reset(confirmed: true);
      expect(done, isTrue);
      expect((await repository.get()).count, 0);
    });

    test('keeps the target and the daily totals', () async {
      await controller.setTarget(99);
      await controller.tap();
      await controller.reset(confirmed: true);
      expect((await repository.get()).target, 99);
      final days = await repository.watchDays().first;
      expect(days.single.total, 1);
    });
  });

  group('daily totals', () {
    test('taps are added to today\'s date', () async {
      await controller.tap();
      await controller.tap();
      final days = await repository.watchDays().first;
      expect(days.single.date, '2026-10-21');
      expect(days.single.total, 2);
    });

    test('a new local date starts a new total, even mid-count', () async {
      clock.now = DateTime(2026, 10, 21, 23, 59);
      await controller.tap();
      clock.now = DateTime(2026, 10, 22, 0, 1);
      await controller.tap();
      await controller.tap();

      final days = await repository.watchDays().first;
      expect(days.map((d) => (d.date, d.total)), [
        ('2026-10-22', 2),
        ('2026-10-21', 1),
      ]);
      expect((await repository.get()).count, 3);
    });

    test('the date is zero padded', () {
      expect(TasbihController.localDate(DateTime(2026, 1, 5)), '2026-01-05');
    });

    test('a UTC clock value is converted to the local date', () {
      final utc = DateTime.utc(2026, 10, 21, 12);
      expect(
        TasbihController.localDate(utc),
        TasbihController.localDate(utc.toLocal()),
      );
    });
  });

  group('tap lock', () {
    test('touch taps are ignored while locked', () async {
      await controller.setLock(true);
      final outcome = await controller.tap();
      expect(outcome.counted, isFalse);
      expect(outcome.ignoredByLock, isTrue);
      expect((await repository.get()).count, 0);
      expect(await repository.watchDays().first, isEmpty);
    });

    test('volume keys still count while locked', () async {
      await controller.setLock(true);
      final outcome = await controller.tap(source: TapSource.volumeKey);
      expect(outcome.counted, isTrue);
      expect((await repository.get()).count, 1);
    });

    test('unlocking restores touch counting', () async {
      await controller.setLock(true);
      await controller.setLock(false);
      expect((await controller.tap()).counted, isTrue);
    });
  });

  group('options', () {
    test('toggles are saved', () async {
      await controller.setHaptics(false);
      await controller.setSound(true);
      await controller.setKeepAwake(true);
      await controller.setVolumeKeys(true);
      final state = await repository.get();
      expect(state.haptics, isFalse);
      expect(state.sound, isTrue);
      expect(state.keepAwake, isTrue);
      expect(state.volumeKeys, isTrue);
    });
  });

  group('TasbihState', () {
    test('isValidTarget covers the 1..100000 range', () {
      expect(TasbihState.isValidTarget(1), isTrue);
      expect(TasbihState.isValidTarget(100000), isTrue);
      expect(TasbihState.isValidTarget(0), isFalse);
      expect(TasbihState.isValidTarget(100001), isFalse);
    });

    test('progress within the round', () {
      const state = TasbihState(
        count: 40,
        target: 33,
        keepAwake: false,
        volumeKeys: false,
        lock: false,
        haptics: true,
        sound: false,
      );
      expect(state.roundsCompleted, 1);
      expect(state.countInRound, 7);
    });

    test('a full round shows as full, not as empty', () {
      final state = TasbihState.initial.copyWith(count: 33);
      expect(state.countInRound, 33);
      expect(state.progress, 1.0);
      expect(TasbihState.initial.progress, 0.0);
    });
  });
}
