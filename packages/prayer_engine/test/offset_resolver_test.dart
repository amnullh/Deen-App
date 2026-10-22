// OffsetResolver, FixedOffsetResolver, BundledOffsetResolver and solarDayShift
// (T072). The "operating-system offsets when the location zone equals the
// device zone" policy lives in the app, which supplies its own OffsetResolver;
// these tests cover the interface and the implementations of this package.
import 'package:prayer_engine/prayer_engine.dart';
import 'package:test/test.dart';

void main() {
  group('BundledOffsetResolver', () {
    final resolver = BundledOffsetResolver();

    test('returns standard and daylight offsets for Europe/London', () {
      expect(
        resolver.offsetAt('Europe/London', DateTime.utc(2026, 1, 15, 12)),
        Duration.zero,
      );
      expect(
        resolver.offsetAt('Europe/London', DateTime.utc(2026, 7, 15, 12)),
        const Duration(hours: 1),
      );
    });

    test('switches exactly at the transition instant', () {
      // Clocks in the UK went forward at 01:00 UTC on 2026-03-29.
      expect(
        resolver.offsetAt(
          'Europe/London',
          DateTime.utc(2026, 3, 29, 0, 59, 59),
        ),
        Duration.zero,
      );
      expect(
        resolver.offsetAt('Europe/London', DateTime.utc(2026, 3, 29, 1)),
        const Duration(hours: 1),
      );
    });

    test('handles half-hour and 45-minute zones', () {
      expect(
        resolver.offsetAt('Asia/Kolkata', DateTime.utc(2026, 6, 1)),
        const Duration(hours: 5, minutes: 30),
      );
      expect(
        resolver.offsetAt('Asia/Kathmandu', DateTime.utc(2026, 6, 1)),
        const Duration(hours: 5, minutes: 45),
      );
      // Lord Howe Island has a 30-minute DST shift.
      expect(
        resolver.offsetAt('Australia/Lord_Howe', DateTime.utc(2026, 1, 15)),
        const Duration(hours: 11),
      );
      expect(
        resolver.offsetAt('Australia/Lord_Howe', DateTime.utc(2026, 7, 15)),
        const Duration(hours: 10, minutes: 30),
      );
    });

    test('knows the date-line zones', () {
      final instant = DateTime.utc(2026, 7, 21, 12);
      expect(
        resolver.offsetAt('Pacific/Apia', instant),
        const Duration(hours: 13),
      );
      expect(
        resolver.offsetAt('Pacific/Kiritimati', instant),
        const Duration(hours: 14),
      );
      expect(
        resolver.offsetAt('Pacific/Pago_Pago', instant),
        const Duration(hours: -11),
      );
    });

    test('resolves link zones that latest.dart lacks (Europe/Oslo)', () {
      expect(
        resolver.offsetAt('Europe/Oslo', DateTime.utc(2026, 1, 15)),
        const Duration(hours: 1),
      );
    });

    test('is a pure function of zone and instant', () {
      final a = resolver.offsetAt(
        'America/New_York',
        DateTime.utc(2026, 3, 8, 7),
      );
      final b = BundledOffsetResolver().offsetAt(
        'America/New_York',
        DateTime.utc(2026, 3, 8, 7),
      );
      expect(a, b);
    });

    test(
      'throws ArgumentError for an unknown zone, with the id in the message',
      () {
        expect(
          () => resolver.offsetAt('Mars/Olympus_Mons', DateTime.utc(2026)),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.toString(),
              'message',
              contains('Mars/Olympus_Mons'),
            ),
          ),
        );
      },
    );

    test('accepts a non-UTC DateTime for the instant', () {
      final local = DateTime.utc(2026, 7, 15, 12).toLocal();
      expect(
        resolver.offsetAt('Europe/London', local),
        const Duration(hours: 1),
      );
    });
  });

  group('FixedOffsetResolver', () {
    test('returns its offset for any zone and instant, even unknown zones', () {
      const resolver = FixedOffsetResolver(Duration(hours: 3));
      expect(
        resolver.offsetAt('Asia/Riyadh', DateTime.utc(2026)),
        const Duration(hours: 3),
      );
      expect(
        resolver.offsetAt('Anything/Goes', DateTime.utc(1999)),
        const Duration(hours: 3),
      );
    });

    test(
      'drives the engine: the offset decides the solar day near the date line',
      () {
        DateTime dhuhr(OffsetResolver resolver) {
          return AdhanDartEngine(offsetResolver: resolver)
              .timesFor(
                latitude: -13.8333,
                longitude: -171.7667,
                timeZoneId: 'Pacific/Apia',
                localDate: '2026-07-21',
                method: CalculationMethod.muslimWorldLeague,
                asr: AsrMethod.standard,
                highLatitudeRule: HighLatitudeRule.middleOfNight,
                offsetsMinutes: const {},
                imsakMinutes: 10,
              )
              .times[Prayer.dhuhr]!;
        }

        final current = dhuhr(const FixedOffsetResolver(Duration(hours: 13)));
        final before2011 = dhuhr(
          const FixedOffsetResolver(Duration(hours: -11)),
        );
        // Under UTC+13 the civil 21 July is the solar day of 20 July, so its
        // Dhuhr is one day earlier than under UTC-11.
        final gap = before2011.difference(current);
        expect(gap.inMinutes, inInclusiveRange(24 * 60 - 2, 24 * 60 + 2));
        expect(current, dhuhr(BundledOffsetResolver()));
      },
    );
  });

  group('solarDayShift', () {
    int shift(int offsetHours, double longitude, {int minutes = 0}) =>
        solarDayShift(
          Duration(hours: offsetHours, minutes: minutes),
          longitude,
        );

    test('is zero where civil time follows the Sun', () {
      expect(shift(0, 0), 0);
      expect(shift(1, -0.13), 0); // London in summer
      expect(shift(-5, -74), 0); // New York
      expect(shift(3, 39.8), 0); // Makkah
      expect(shift(5, 67, minutes: 0), 0); // Karachi
      expect(shift(11, 151.2), 0); // Sydney in summer
      expect(shift(12, 174.8), 0); // Auckland
      expect(shift(-11, -170.7), 0); // Pago Pago
    });

    test('is one for zones ahead of the date line with western longitudes', () {
      expect(shift(13, -171.77), 1); // Apia
      expect(shift(14, -157.43), 1); // Kiritimati
      expect(shift(13, -172.0), 1); // Tonga-like
      expect(shift(12, -178.8), 1); // Wrangel Island
    });

    test('is minus one for the mirrored case', () {
      expect(shift(-11, 170), -1);
      expect(shift(-10, 175), -1);
    });

    test('Apia before it crossed the date line (UTC-11) has no shift', () {
      expect(shift(-11, -171.77), 0);
    });

    test('changes when civil and solar time differ by more than 12 hours', () {
      expect(solarDayShift(const Duration(hours: 11, minutes: 54), 0), 0);
      expect(solarDayShift(const Duration(hours: 12, minutes: 6), 0), 1);
      expect(solarDayShift(const Duration(hours: -12, minutes: -6), 0), -1);
      expect(solarDayShift(const Duration(hours: 36), 0), 2);
    });
  });
}
