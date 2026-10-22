import 'dart:math' as math;

import 'package:deen_mobile/domain/qibla/heading_filter.dart';
import 'package:flutter_test/flutter_test.dart';

HeadingReading _reading(
  double heading, {
  CompassAccuracy accuracy = CompassAccuracy.high,
  double? field = 45,
  bool interference = false,
  bool needsCalibration = false,
}) {
  return HeadingReading(
    headingDegrees: heading,
    isTrueNorth: true,
    accuracy: accuracy,
    fieldStrengthMicroTesla: field,
    interferenceSuspected: interference,
    needsCalibration: needsCalibration,
  );
}

/// Feeds [readings] to a fresh tracker and returns every snapshot.
List<CompassSnapshot> _run(Iterable<HeadingReading> readings) {
  final tracker = HeadingTracker();
  return [for (final r in readings) tracker.add(r)!];
}

void main() {
  group('angle helpers', () {
    test('normalizeDegrees maps any angle into 0..360', () {
      expect(normalizeDegrees(0), 0);
      expect(normalizeDegrees(360), 0);
      expect(normalizeDegrees(-10), closeTo(350, 1e-9));
      expect(normalizeDegrees(725), closeTo(5, 1e-9));
    });

    test('angleDelta takes the short way round the circle', () {
      expect(angleDelta(359, 1), closeTo(2, 1e-9));
      expect(angleDelta(1, 359), closeTo(-2, 1e-9));
      expect(angleDelta(10, 100), closeTo(90, 1e-9));
      expect(angleDelta(100, 10), closeTo(-90, 1e-9));
      expect(angleDelta(0, 180).abs(), closeTo(180, 1e-9));
    });

    test('unwrapAngle never jumps by more than half a turn', () {
      // 350 -> 10 degrees is +20 degrees, not -340.
      expect(unwrapAngle(350, 10), closeTo(370, 1e-9));
      expect(unwrapAngle(370, 350), closeTo(350, 1e-9));
      expect(unwrapAngle(0, 359), closeTo(-1, 1e-9));
    });
  });

  group('smoothing', () {
    test('the first reading passes through unchanged', () {
      final out = _run([_reading(123)]);
      expect(out.single.headingDegrees, closeTo(123, 1e-9));
    });

    test('359 -> 1 wraps without swinging through 180', () {
      final stream = [358, 359, 0, 1, 2, 1, 0, 359, 358, 359, 0, 1];
      final out = _run(stream.map((d) => _reading(d.toDouble())));
      for (final snapshot in out) {
        expect(
          angleDelta(0, snapshot.headingDegrees).abs(),
          lessThan(4),
          reason: 'smoothed heading ${snapshot.headingDegrees}',
        );
      }
    });

    test('alternating 359 and 1 settles near north, not near south', () {
      final stream = List.generate(40, (i) => i.isEven ? 359.0 : 1.0);
      final out = _run(stream.map(_reading));
      expect(angleDelta(0, out.last.headingDegrees).abs(), lessThan(2));
    });

    test('output stays within 0..360', () {
      final stream = List.generate(100, (i) => 350.0 + i * 0.4);
      final out = _run(stream.map(_reading));
      for (final s in out) {
        expect(s.headingDegrees, inInclusiveRange(0, 360));
        expect(s.headingDegrees, lessThan(360));
      }
    });

    test('noise is reduced but a real turn is followed', () {
      final random = math.Random(7);
      // 40 samples of noisy 90 degrees, then a turn to 180 with the same noise.
      final raw = <double>[
        for (var i = 0; i < 40; i++) 90 + (random.nextDouble() - 0.5) * 10,
        for (var i = 0; i < 40; i++) 180 + (random.nextDouble() - 0.5) * 10,
      ];
      final out = _run(raw.map(_reading)).map((s) => s.headingDegrees).toList();

      double spread(List<double> xs) =>
          xs.reduce(math.max) - xs.reduce(math.min);
      expect(
        spread(out.sublist(20, 40)),
        lessThan(spread(raw.sublist(20, 40))),
      );
      expect(angleDelta(180, out.last).abs(), lessThan(3));
    });

    test('a step change converges within about a second at 10 Hz', () {
      final stream = [
        for (var i = 0; i < 5; i++) 0.0,
        for (var i = 0; i < 12; i++) 90.0,
      ];
      final out = _run(stream.map(_reading));
      expect(angleDelta(90, out.last.headingDegrees).abs(), lessThan(3));
    });

    test('invalid readings are ignored', () {
      final tracker = HeadingTracker();
      final first = tracker.add(_reading(40))!;
      expect(tracker.add(_reading(double.nan)), isNull);
      expect(tracker.add(_reading(double.infinity)), isNull);
      final next = tracker.add(_reading(40))!;
      expect(next.headingDegrees, closeTo(first.headingDegrees, 1e-9));
    });

    test('reset forgets the previous heading', () {
      final tracker = HeadingTracker()..add(_reading(10));
      tracker.reset();
      expect(tracker.add(_reading(200))!.headingDegrees, closeTo(200, 1e-9));
    });
  });

  group('interference', () {
    test('normal field strength is not interference', () {
      final out = _run(List.generate(30, (_) => _reading(10, field: 48)));
      expect(out.any((s) => s.interference), isFalse);
    });

    test('a field outside 25..65 microtesla for half a second is', () {
      final out = _run(List.generate(10, (_) => _reading(10, field: 120)));
      expect(out.last.interference, isTrue);
      final weak = _run(List.generate(10, (_) => _reading(10, field: 12)));
      expect(weak.last.interference, isTrue);
    });

    test('one noisy sample is not enough', () {
      final stream = [
        for (var i = 0; i < 10; i++) _reading(10),
        _reading(10, field: 140),
        for (var i = 0; i < 10; i++) _reading(10),
      ];
      expect(_run(stream).any((s) => s.interference), isFalse);
    });

    test('no field reading (iOS) does not count as interference', () {
      final out = _run(List.generate(20, (_) => _reading(10, field: null)));
      expect(out.any((s) => s.interference), isFalse);
    });

    test('the platform flag is honoured once it persists', () {
      final out = _run(
        List.generate(10, (_) => _reading(10, interference: true)),
      );
      expect(out.last.interference, isTrue);
    });

    test('a heading that flips back and forth by large angles is flagged', () {
      final stream = List.generate(30, (i) => i.isEven ? 20.0 : 110.0);
      final out = _run(stream.map(_reading));
      expect(out.last.interference, isTrue);
    });

    test('a steady turn is not mistaken for interference', () {
      final stream = List.generate(60, (i) => (i * 15.0) % 360);
      final out = _run(stream.map(_reading));
      expect(out.any((s) => s.interference), isFalse);
    });

    test('the warning clears after the field has been normal for a while', () {
      final stream = [
        for (var i = 0; i < 10; i++) _reading(10, field: 120),
        for (var i = 0; i < 30; i++) _reading(10, field: 45),
      ];
      final out = _run(stream);
      expect(out[9].interference, isTrue);
      expect(out.last.interference, isFalse);
    });

    test('the warning does not flicker off on a single clean sample', () {
      final stream = [
        for (var i = 0; i < 10; i++) _reading(10, field: 120),
        _reading(10, field: 45),
        _reading(10, field: 45),
      ];
      expect(_run(stream).last.interference, isTrue);
    });
  });

  group('calibration prompt', () {
    test('high and medium accuracy never prompt', () {
      final out = _run([
        for (var i = 0; i < 20; i++)
          _reading(10, accuracy: CompassAccuracy.medium),
      ]);
      expect(out.any((s) => s.needsCalibration), isFalse);
    });

    test('sustained low accuracy prompts', () {
      final out = _run([
        for (var i = 0; i < 10; i++)
          _reading(10, accuracy: CompassAccuracy.low),
      ]);
      expect(out.last.needsCalibration, isTrue);
    });

    test('unreliable accuracy prompts', () {
      final out = _run([
        for (var i = 0; i < 10; i++)
          _reading(10, accuracy: CompassAccuracy.unreliable),
      ]);
      expect(out.last.needsCalibration, isTrue);
    });

    test('the platform needsCalibration flag prompts', () {
      final out = _run([
        for (var i = 0; i < 10; i++) _reading(10, needsCalibration: true),
      ]);
      expect(out.last.needsCalibration, isTrue);
    });

    test('a brief dip in accuracy does not prompt', () {
      final out = _run([
        for (var i = 0; i < 10; i++) _reading(10),
        for (var i = 0; i < 2; i++) _reading(10, accuracy: CompassAccuracy.low),
        for (var i = 0; i < 10; i++) _reading(10),
      ]);
      expect(out.any((s) => s.needsCalibration), isFalse);
    });

    test('the prompt stays until accuracy has recovered for a while', () {
      final out = _run([
        for (var i = 0; i < 10; i++)
          _reading(10, accuracy: CompassAccuracy.low),
        _reading(10),
        _reading(10),
      ]);
      expect(out.last.needsCalibration, isTrue);

      final recovered = _run([
        for (var i = 0; i < 10; i++)
          _reading(10, accuracy: CompassAccuracy.low),
        for (var i = 0; i < 30; i++) _reading(10),
      ]);
      expect(recovered.last.needsCalibration, isFalse);
    });
  });

  group('snapshot', () {
    test('carries accuracy and north reference from the latest reading', () {
      final tracker = HeadingTracker();
      final snapshot = tracker.add(
        HeadingReading(
          headingDegrees: 10,
          isTrueNorth: false,
          accuracy: CompassAccuracy.medium,
          interferenceSuspected: false,
          needsCalibration: false,
        ),
      )!;
      expect(snapshot.accuracy, CompassAccuracy.medium);
      expect(snapshot.isTrueNorth, isFalse);
    });
  });
}
