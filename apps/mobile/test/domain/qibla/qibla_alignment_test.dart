import 'package:deen_mobile/domain/qibla/qibla_alignment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('relativeQiblaAngle', () {
    test('is the bearing minus the heading, the short way round', () {
      expect(relativeQiblaAngle(bearing: 90, heading: 0), closeTo(90, 1e-9));
      expect(relativeQiblaAngle(bearing: 90, heading: 180), closeTo(-90, 1e-9));
      expect(relativeQiblaAngle(bearing: 10, heading: 350), closeTo(20, 1e-9));
      expect(relativeQiblaAngle(bearing: 350, heading: 10), closeTo(-20, 1e-9));
    });

    test('is zero when the phone points at the Qibla', () {
      expect(relativeQiblaAngle(bearing: 212, heading: 212), 0);
    });
  });

  group('isAligned', () {
    test('enters at 3 degrees', () {
      expect(isAligned(2.9, wasAligned: false), isTrue);
      expect(isAligned(-2.9, wasAligned: false), isTrue);
      expect(isAligned(3.5, wasAligned: false), isFalse);
    });

    test('leaves only beyond 6 degrees so it does not flicker', () {
      expect(isAligned(5, wasAligned: true), isTrue);
      expect(isAligned(-5, wasAligned: true), isTrue);
      expect(isAligned(6.5, wasAligned: true), isFalse);
    });
  });

  group('turnDegrees', () {
    test('is the whole number of degrees to turn', () {
      expect(turnDegrees(20.4), 20);
      expect(turnDegrees(-179.6), 180);
    });
  });
}
