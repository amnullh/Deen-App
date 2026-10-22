// Tests of the oracle itself. It must be right on its own, so these compare it
// with the JPL Horizons ephemeris (see packages/prayer_engine/test/
// asr_shadow_test.dart and horizons_events_test.dart for the query) and check
// the rules it encodes, never with the engine under test.
import 'package:fixtures_gen/fixtures_gen.dart';
import 'package:test/test.dart';

OracleDay _day(
  double lat,
  double lon,
  int y,
  int m,
  int d, {
  OracleMethod method = OracleMethod.muslimWorldLeague,
  int asrFactor = 1,
  OracleHighLatitude rule = OracleHighLatitude.middleOfNight,
  bool isRamadan = false,
}) {
  return calculateDay(
    latitude: lat,
    longitude: lon,
    year: y,
    month: m,
    day: d,
    method: method,
    asrShadowFactor: asrFactor,
    highLatitude: rule,
    isRamadan: isRamadan,
  );
}

void _near(DateTime? got, String truth, {int seconds = 60}) {
  expect(got, isNotNull);
  expect(
    got!.difference(DateTime.parse(truth)).inSeconds.abs(),
    lessThanOrEqualTo(seconds),
    reason: '${got.toIso8601String()} vs $truth',
  );
}

void main() {
  group('Asr against JPL Horizons', () {
    test('Reykjavik 2026-01-01 (Sun 2.9 degrees high at noon)', () {
      _near(_day(64.1466, -21.9426, 2026, 1, 1).asr, '2026-01-01T13:56:35Z');
    });
    test('New York 2026-02-11', () {
      _near(_day(40.7128, -74.006, 2026, 2, 11).asr, '2026-02-11T20:01:35Z');
    });
    test('Oslo Hanafi 2026-06-21', () {
      _near(
        _day(59.9139, 10.7522, 2026, 6, 21, asrFactor: 2).asr,
        '2026-06-21T17:19:27Z',
      );
    });
    test('Tromso 2026-11-20: Asr exists although the Sun is barely up', () {
      _near(_day(69.6492, 18.9553, 2026, 11, 20).asr, '2026-11-20T10:35:20Z');
    });
  });

  group('sunrise and sunset against JPL Horizons', () {
    test('Tromso 2026-01-15, Sun grazing the horizon', () {
      final day = _day(69.6492, 18.9553, 2026, 1, 15);
      _near(day.sunrise, '2026-01-15T10:29:35Z');
      _near(day.maghrib, '2026-01-15T11:18:14Z');
    });
    test('Tromso 2026-05-18 has a sunrise (the Sun dipped 0.026 degrees below -50 arcmin)', () {
      _near(
        _day(69.6492, 18.9553, 2026, 5, 18).sunrise,
        '2026-05-17T22:52:07Z',
        seconds: 120,
      );
    });
    test('Tromso 2026-05-20 has none', () {
      expect(_day(69.6492, 18.9553, 2026, 5, 20).sunrise, isNull);
    });
  });

  group('rules the oracle encodes', () {
    test('Maghrib by angle (Tehran) is never later than Isha', () {
      for (final month in [5, 6, 7]) {
        final day = _day(
          59.9139,
          10.7522,
          2026,
          month,
          15,
          method: OracleMethod.tehran,
          rule: OracleHighLatitude.seventhOfNight,
        );
        expect(
          day.maghrib!.isBefore(day.isha!),
          isTrue,
          reason: 'month $month',
        );
      }
    });

    test('Umm al-Qura Isha is 90 minutes after Maghrib, 120 in Ramadan', () {
      final normal = _day(
        21.4225,
        39.8262,
        2026,
        4,
        10,
        method: OracleMethod.ummAlQura,
      );
      final ramadan = _day(
        21.4225,
        39.8262,
        2026,
        3,
        1,
        method: OracleMethod.ummAlQura,
        isRamadan: true,
      );
      expect(
        normal.isha!.difference(normal.maghrib!),
        const Duration(minutes: 90),
      );
      expect(
        ramadan.isha!.difference(ramadan.maghrib!),
        const Duration(minutes: 120),
      );
    });

    test(
      'the night for the high-latitude rule runs to tomorrow\'s sunrise',
      () {
        // Oslo, 21 June: seventh of the night after sunset is about 44 minutes.
        final day = _day(
          59.9139,
          10.7522,
          2026,
          6,
          21,
          rule: OracleHighLatitude.seventhOfNight,
        );
        final minutes = day.isha!.difference(day.maghrib!).inMinutes;
        expect(minutes, inInclusiveRange(42, 47));
      },
    );

    test(
      'Dhuhr margin: Muslim World League is one minute after Umm al-Qura',
      () {
        final a = _day(21.4225, 39.8262, 2026, 3, 20);
        final b = _day(
          21.4225,
          39.8262,
          2026,
          3,
          20,
          method: OracleMethod.ummAlQura,
        );
        expect(a.dhuhr!.difference(b.dhuhr!), const Duration(minutes: 1));
      },
    );

    test('polar night has no sunrise or sunset but still has twilight', () {
      final day = _day(69.6492, 18.9553, 2026, 12, 21);
      expect(day.sunrise, isNull);
      expect(day.maghrib, isNull);
      expect(day.fajr, isNotNull);
      expect(day.isha, isNotNull);
    });
  });

  group('toWholeMinute', () {
    test('rounds to the nearest minute, or up when asked', () {
      final t = DateTime.utc(2026, 1, 1, 10, 5, 31);
      expect(toWholeMinute(t), DateTime.utc(2026, 1, 1, 10, 6));
      expect(
        toWholeMinute(DateTime.utc(2026, 1, 1, 10, 5, 29)),
        DateTime.utc(2026, 1, 1, 10, 5),
      );
      expect(
        toWholeMinute(DateTime.utc(2026, 1, 1, 10, 5, 1), roundsUp: true),
        DateTime.utc(2026, 1, 1, 10, 6),
      );
      expect(
        toWholeMinute(DateTime.utc(2026, 1, 1, 10, 5), roundsUp: true),
        DateTime.utc(2026, 1, 1, 10, 5),
      );
    });
  });
}
