import 'package:deen_mobile/domain/clock_sanity.dart';
import 'package:deen_mobile/domain/entities/settings.dart';
import 'package:flutter_test/flutter_test.dart';

final _build = DateTime.utc(2026, 10, 21);

ClockSanityCheck _check() => ClockSanityCheck(buildDate: _build);

ClockSample _sample(
  DateTime wall, {
  int mono = 1000000,
  String boot = 'boot-1',
}) => ClockSample(
  wallClockMs: wall.millisecondsSinceEpoch,
  monotonicMs: mono,
  bootId: boot,
);

void main() {
  final now = DateTime.utc(2026, 11, 2, 10);

  test('a first run with a sane clock has no warning and stores a sample', () {
    final result = _check().evaluate(
      wallNow: now,
      monotonic: const MonotonicReading(milliseconds: 5000, bootId: 'boot-1'),
      previous: null,
    );
    expect(result.warning, isNull);
    expect(result.sampleToStore!.wallClockMs, now.millisecondsSinceEpoch);
    expect(result.sampleToStore!.bootId, 'boot-1');
  });

  group('clock before the app build date', () {
    test('warns and keeps the last good sample', () {
      final previous = _sample(now);
      final result = _check().evaluate(
        wallNow: DateTime.utc(2020, 1, 1),
        monotonic: null,
        previous: previous,
      );
      expect(result.warning, ClockWarning.beforeBuildDate);
      expect(result.sampleToStore, isNull);
    });

    test('the build moment itself is accepted', () {
      final result = _check().evaluate(
        wallNow: _build,
        monotonic: null,
        previous: null,
      );
      expect(result.warning, isNull);
    });
  });

  group('backward jump', () {
    test('warns when the clock went back by more than the tolerance', () {
      final previous = _sample(now);
      final result = _check().evaluate(
        wallNow: now.subtract(const Duration(hours: 3)),
        monotonic: null,
        previous: previous,
      );
      expect(result.warning, ClockWarning.movedBackward);
      expect(result.sampleToStore, isNotNull);
    });

    test('ignores a small step back such as a network time correction', () {
      final previous = _sample(now);
      final result = _check().evaluate(
        wallNow: now.subtract(const Duration(seconds: 30)),
        monotonic: null,
        previous: previous,
      );
      expect(result.warning, isNull);
    });
  });

  group('drift against the monotonic clock', () {
    test('warns when the wall clock moved far more than the monotonic one', () {
      final previous = _sample(now, mono: 1000000);
      final result = _check().evaluate(
        wallNow: now.add(const Duration(hours: 5)),
        // Only ten minutes passed on the monotonic clock.
        monotonic: const MonotonicReading(
          milliseconds: 1000000 + 600000,
          bootId: 'boot-1',
        ),
        previous: previous,
      );
      expect(result.warning, ClockWarning.drifted);
    });

    test('is quiet when both clocks advance together', () {
      final previous = _sample(now, mono: 1000000);
      final result = _check().evaluate(
        wallNow: now.add(const Duration(hours: 5)),
        monotonic: const MonotonicReading(
          milliseconds: 1000000 + 5 * 3600 * 1000 + 20000,
          bootId: 'boot-1',
        ),
        previous: previous,
      );
      expect(result.warning, isNull);
    });

    test('does not compare readings from different boots', () {
      final previous = _sample(now, mono: 1000000, boot: 'boot-1');
      final result = _check().evaluate(
        wallNow: now.add(const Duration(days: 2)),
        monotonic: const MonotonicReading(milliseconds: 4000, bootId: 'boot-2'),
        previous: previous,
      );
      expect(result.warning, isNull);
    });

    test('is skipped when no monotonic source is available', () {
      final previous = _sample(now);
      final result = _check().evaluate(
        wallNow: now.add(const Duration(days: 2)),
        monotonic: null,
        previous: previous,
      );
      expect(result.warning, isNull);
      expect(result.sampleToStore!.bootId, '');
    });
  });
}
