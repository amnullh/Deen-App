import 'package:prayer_engine/prayer_engine.dart';
import 'package:test/test.dart';

void main() {
  group('defaultHighLatitudeRule', () {
    test('uses middle of the night up to and including 48 degrees', () {
      expect(defaultHighLatitudeRule(0), HighLatitudeRule.middleOfNight);
      expect(defaultHighLatitudeRule(48), HighLatitudeRule.middleOfNight);
      expect(defaultHighLatitudeRule(-48), HighLatitudeRule.middleOfNight);
    });

    test('uses seventh of the night above 48 degrees, either hemisphere', () {
      expect(defaultHighLatitudeRule(48.01), HighLatitudeRule.seventhOfNight);
      expect(defaultHighLatitudeRule(-55), HighLatitudeRule.seventhOfNight);
      expect(defaultHighLatitudeRule(69.65), HighLatitudeRule.seventhOfNight);
    });

    test('isHighLatitude matches the threshold', () {
      expect(isHighLatitude(48), isFalse);
      expect(isHighLatitude(48.5), isTrue);
    });
  });
}
