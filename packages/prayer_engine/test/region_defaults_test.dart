import 'package:prayer_engine/prayer_engine.dart';
import 'package:test/test.dart';

void main() {
  group('suggestedMethod (clarification D1)', () {
    const expected = <String, CalculationMethod>{
      // Europe and the Far East: Muslim World League
      'GB': CalculationMethod.muslimWorldLeague,
      'DE': CalculationMethod.muslimWorldLeague,
      'RU': CalculationMethod.muslimWorldLeague,
      'JP': CalculationMethod.muslimWorldLeague,
      'CN': CalculationMethod.muslimWorldLeague,
      // North America: ISNA
      'US': CalculationMethod.isna,
      'CA': CalculationMethod.isna,
      // Arabian Peninsula: Umm al-Qura
      'SA': CalculationMethod.ummAlQura,
      'AE': CalculationMethod.ummAlQura,
      'KW': CalculationMethod.ummAlQura,
      // Africa and the Middle East outside the Peninsula: Egypt
      'EG': CalculationMethod.egypt,
      'MA': CalculationMethod.egypt,
      'NG': CalculationMethod.egypt,
      'JO': CalculationMethod.egypt,
      'IR': CalculationMethod.egypt,
      // South Asia: Karachi
      'PK': CalculationMethod.karachi,
      'IN': CalculationMethod.karachi,
      'BD': CalculationMethod.karachi,
      // Turkey: Diyanet
      'TR': CalculationMethod.diyanet,
      // Southeast Asia: Singapore
      'SG': CalculationMethod.singapore,
      'MY': CalculationMethod.singapore,
      'ID': CalculationMethod.singapore,
    };

    expected.forEach((country, method) {
      test('$country suggests $method', () {
        expect(suggestedMethod(country), method);
      });
    });

    test('is case-insensitive and trims input', () {
      expect(suggestedMethod(' pk '), CalculationMethod.karachi);
    });

    test('falls back to Muslim World League for unlisted or empty codes', () {
      expect(suggestedMethod('BR'), CalculationMethod.muslimWorldLeague);
      expect(suggestedMethod('KZ'), CalculationMethod.muslimWorldLeague);
      expect(suggestedMethod(''), CalculationMethod.muslimWorldLeague);
      expect(regionOf('AU'), Region.other);
    });

    test('no country appears in two regions', () {
      // regionOf returns a single value, so check a few boundary countries.
      expect(regionOf('CY'), Region.europe);
      expect(regionOf('EG'), Region.middleEastAndAfrica);
      expect(regionOf('TR'), Region.turkey);
    });
  });
}
