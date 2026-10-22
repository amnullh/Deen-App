// The fixed conventions each method carries, pinned so a change is deliberate.
// They are relative checks (same place and day, two methods), so they do not
// depend on the astronomy.
import 'package:prayer_engine/prayer_engine.dart';
import 'package:test/test.dart';

final _engine = AdhanDartEngine();

DayTimes _makkah(CalculationMethod method, String date) {
  return _engine.timesFor(
    latitude: 21.4225,
    longitude: 39.8262,
    timeZoneId: 'Asia/Riyadh',
    localDate: date,
    method: method,
    asr: AsrMethod.standard,
    highLatitudeRule: HighLatitudeRule.middleOfNight,
    offsetsMinutes: const {},
    imsakMinutes: 10,
  );
}

int _gap(DateTime later, DateTime earlier) =>
    later.difference(earlier).inMinutes;

void main() {
  group('Umm al-Qura Isha interval', () {
    test('is 90 minutes after Maghrib outside Ramadan', () {
      for (final date in ['2026-01-20', '2026-04-10', '2026-09-01']) {
        final day = _makkah(CalculationMethod.ummAlQura, date);
        expect(
          _gap(day.times[Prayer.isha]!, day.times[Prayer.maghrib]!),
          90,
          reason: date,
        );
      }
    });

    test('is 120 minutes after Maghrib throughout Ramadan 1447 (2026-02-18 to 2026-03-19)', () {
      // Ramadan 1447 dates: see hijri_test.dart for their source.
      for (final date in ['2026-02-18', '2026-03-01', '2026-03-19']) {
        expect(isRamadan(date), isTrue, reason: date);
        final day = _makkah(CalculationMethod.ummAlQura, date);
        expect(
          _gap(day.times[Prayer.isha]!, day.times[Prayer.maghrib]!),
          120,
          reason: date,
        );
      }
      for (final date in ['2026-02-17', '2026-03-20']) {
        expect(isRamadan(date), isFalse, reason: date);
        final day = _makkah(CalculationMethod.ummAlQura, date);
        expect(
          _gap(day.times[Prayer.isha]!, day.times[Prayer.maghrib]!),
          90,
          reason: date,
        );
      }
    });

    test(
      'is not extended for Gulf or Qatar, which are fixed at 90 minutes',
      () {
        for (final method in [
          CalculationMethod.gulf,
          CalculationMethod.qatar,
        ]) {
          final day = _makkah(method, '2026-03-01');
          expect(
            _gap(day.times[Prayer.isha]!, day.times[Prayer.maghrib]!),
            90,
            reason: method.name,
          );
        }
      },
    );
  });

  group(
    'fixed margins and adjustments relative to Umm al-Qura (which has none)',
    () {
      final base = _makkah(CalculationMethod.ummAlQura, '2026-03-20');

      test('Muslim World League, ISNA, Egypt and Karachi: Dhuhr one minute after transit', () {
        for (final method in [
          CalculationMethod.muslimWorldLeague,
          CalculationMethod.isna,
          CalculationMethod.egypt,
          CalculationMethod.karachi,
        ]) {
          final day = _makkah(method, '2026-03-20');
          expect(
            _gap(day.times[Prayer.dhuhr]!, base.times[Prayer.dhuhr]!),
            1,
            reason: method.name,
          );
        }
      });

      test(
        'Singapore: Dhuhr one minute after transit, every time rounded up',
        () {
          final day = _makkah(CalculationMethod.singapore, '2026-03-20');
          // Rounding up instead of to the nearest minute adds 0 or 1 minute.
          expect(
            _gap(day.times[Prayer.dhuhr]!, base.times[Prayer.dhuhr]!),
            inInclusiveRange(1, 2),
          );
          for (final prayer in Prayer.values) {
            expect(day.times[prayer]!.second, 0);
          }
        },
      );

      test(
        'Singapore: Dhuhr one minute after transit, every time rounded up',
        () {
          final day = _makkah(CalculationMethod.singapore, '2026-03-20');
          // Rounding up instead of to the nearest minute adds 0 or 1 minute.
          expect(
            _gap(day.times[Prayer.dhuhr]!, base.times[Prayer.dhuhr]!),
            inInclusiveRange(1, 2),
          );
          for (final prayer in Prayer.values) {
            expect(day.times[prayer]!.second, 0);
          }
        },
      );

      test('Diyanet: sunrise -7, Dhuhr +5, Asr +4, Maghrib +7 minutes', () {
        final day = _makkah(CalculationMethod.diyanet, '2026-03-20');
        expect(
          _gap(day.times[Prayer.sunrise]!, base.times[Prayer.sunrise]!),
          -7,
        );
        expect(_gap(day.times[Prayer.dhuhr]!, base.times[Prayer.dhuhr]!), 5);
        expect(_gap(day.times[Prayer.asr]!, base.times[Prayer.asr]!), 4);
        expect(
          _gap(day.times[Prayer.maghrib]!, base.times[Prayer.maghrib]!),
          7,
        );
      });

      test('Kuwait, Qatar, Gulf, France, Tehran, Jafari: no Dhuhr margin', () {
        for (final method in [
          CalculationMethod.kuwait,
          CalculationMethod.qatar,
          CalculationMethod.gulf,
          CalculationMethod.franceUoif,
          CalculationMethod.tehran,
          CalculationMethod.jafari,
        ]) {
          final day = _makkah(method, '2026-03-20');
          expect(
            day.times[Prayer.dhuhr],
            base.times[Prayer.dhuhr],
            reason: method.name,
          );
        }
      });
    },
  );

  group('twilight angles order the methods at Makkah', () {
    test('a larger Fajr angle gives an earlier Fajr', () {
      final fajr = {
        for (final m in [
          CalculationMethod.isna, // 15
          CalculationMethod.franceUoif, // 12
          CalculationMethod.muslimWorldLeague, // 18
          CalculationMethod.egypt, // 19.5
          CalculationMethod.singapore, // 20
        ])
          m: _makkah(m, '2026-03-20').times[Prayer.fajr]!,
      };
      expect(
        fajr[CalculationMethod.franceUoif]!.isAfter(
          fajr[CalculationMethod.isna]!,
        ),
        isTrue,
      );
      expect(
        fajr[CalculationMethod.isna]!.isAfter(
          fajr[CalculationMethod.muslimWorldLeague]!,
        ),
        isTrue,
      );
      expect(
        fajr[CalculationMethod.muslimWorldLeague]!.isAfter(
          fajr[CalculationMethod.egypt]!,
        ),
        isTrue,
      );
      expect(
        fajr[CalculationMethod.egypt]!.isAfter(
          fajr[CalculationMethod.singapore]!,
        ),
        isTrue,
      );
    });
  });
}
