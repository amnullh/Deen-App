// Moonsighting Committee Worldwide has no independent oracle in this project:
// its seasonal twilight tables (Khalid Shaukat) are not part of the PrayTimes
// method the oracle follows. These are STRUCTURAL tests only: order of events,
// season behaviour and the rule above 55 degrees. They would not catch a wrong
// coefficient; an official sample table is needed for that (task T065, open).
import 'package:prayer_engine/prayer_engine.dart';
import 'package:test/test.dart';

final _engine = AdhanDartEngine();

DayTimes _day(
  double latitude,
  double longitude,
  String zone,
  String date, {
  Map<Prayer, int> offsets = const {},
}) {
  return _engine.timesFor(
    latitude: latitude,
    longitude: longitude,
    timeZoneId: zone,
    localDate: date,
    method: CalculationMethod.moonsightingCommittee,
    asr: AsrMethod.standard,
    highLatitudeRule: defaultHighLatitudeRule(latitude),
    offsetsMinutes: offsets,
    imsakMinutes: 10,
  );
}

int _minutes(DateTime later, DateTime earlier) =>
    later.difference(earlier).inMinutes;

void main() {
  const places = <(String, double, double, String)>[
    ('Makkah', 21.4225, 39.8262, 'Asia/Riyadh'),
    ('Karachi', 24.8607, 67.0011, 'Asia/Karachi'),
    ('London', 51.5074, -0.1278, 'Europe/London'),
    ('New York', 40.7128, -74.006, 'America/New_York'),
    ('Sydney', -33.8688, 151.2093, 'Australia/Sydney'),
    ('Jakarta', -6.2088, 106.8456, 'Asia/Jakarta'),
  ];
  const dates = [
    '2026-01-10',
    '2026-03-20',
    '2026-06-21',
    '2026-09-23',
    '2026-12-21',
  ];

  group('daily order below 55 degrees', () {
    for (final (name, lat, lon, zone) in places) {
      for (final date in dates) {
        test('$name $date: Fajr < sunrise < Dhuhr < Asr < Maghrib < Isha', () {
          final day = _day(lat, lon, zone, date);
          final ordered = Prayer.values.map((p) => day.times[p]).toList();
          expect(ordered, everyElement(isNotNull));
          for (var i = 1; i < ordered.length; i++) {
            expect(
              ordered[i]!.isAfter(ordered[i - 1]!),
              isTrue,
              reason:
                  '${Prayer.values[i].name} after ${Prayer.values[i - 1].name}',
            );
          }
          expect(day.notices, isEmpty);
        });
      }
    }
  });

  group('season behaviour', () {
    test(
      'at the equator Fajr is never more than 75 minutes before sunrise',
      () {
        // The seasonal figure is a limit: Fajr is the later of the 18 degree
        // twilight and sunrise minus 75 minutes (minus 76 at 1 degree).
        for (final date in dates) {
          final day = _day(0, 100, 'Asia/Jakarta', date);
          expect(
            _minutes(day.times[Prayer.sunrise]!, day.times[Prayer.fajr]!),
            inInclusiveRange(65, 76),
            reason: date,
          );
        }
      },
    );

    test('at 51.5 N the dawn interval is longest at midsummer and shortest at the equinox', () {
      int dawn(String date) {
        final day = _day(51.5074, -0.1278, 'Europe/London', date);
        return _minutes(day.times[Prayer.sunrise]!, day.times[Prayer.fajr]!);
      }

      final winter = dawn('2026-12-21');
      final spring = dawn('2026-03-20');
      final summer = dawn('2026-06-21');
      expect(summer, greaterThan(winter));
      expect(winter, greaterThan(spring));
      for (final minutes in [winter, spring, summer]) {
        expect(minutes, inInclusiveRange(75, 135));
      }
    });

    test('the seasons are mirrored in the southern hemisphere', () {
      int dawn(String date) {
        final day = _day(-33.8688, 151.2093, 'Australia/Sydney', date);
        return _minutes(day.times[Prayer.sunrise]!, day.times[Prayer.fajr]!);
      }

      // Southern midsummer is December, so the longest dawn is then.
      expect(dawn('2026-12-21'), greaterThan(dawn('2026-06-21')));
    });

    test('Isha follows sunset by a season-dependent interval within 60 to 150 minutes', () {
      for (final date in dates) {
        final day = _day(51.5074, -0.1278, 'Europe/London', date);
        final minutes = _minutes(
          day.times[Prayer.isha]!,
          day.times[Prayer.maghrib]!,
        );
        expect(minutes, inInclusiveRange(60, 150), reason: date);
      }
    });

    test('method adjustments: Dhuhr 5 minutes and Maghrib 3 minutes after the astronomical times', () {
      final mwl = _engine.timesFor(
        latitude: 21.4225,
        longitude: 39.8262,
        timeZoneId: 'Asia/Riyadh',
        localDate: '2026-03-20',
        method: CalculationMethod.ummAlQura,
        asr: AsrMethod.standard,
        highLatitudeRule: HighLatitudeRule.middleOfNight,
        offsetsMinutes: const {},
        imsakMinutes: 10,
      );
      final moon = _day(21.4225, 39.8262, 'Asia/Riyadh', '2026-03-20');
      // Umm al-Qura adds nothing to Dhuhr or Maghrib.
      expect(_minutes(moon.times[Prayer.dhuhr]!, mwl.times[Prayer.dhuhr]!), 5);
      expect(
        _minutes(moon.times[Prayer.maghrib]!, mwl.times[Prayer.maghrib]!),
        3,
      );
    });
  });

  group('above 55 degrees (a seventh of the night)', () {
    test('Oslo in June: Fajr and Isha are a seventh of the night from sunrise and sunset', () {
      final day = _day(59.9139, 10.7522, 'Europe/Oslo', '2026-06-21');
      final sunrise = day.times[Prayer.sunrise]!;
      final maghrib = day.times[Prayer.maghrib]!;
      final nextDay = _day(59.9139, 10.7522, 'Europe/Oslo', '2026-06-22');
      // Moonsighting Maghrib is sunset + 3 minutes.
      final night = nextDay.times[Prayer.sunrise]!.difference(
        maghrib.subtract(const Duration(minutes: 3)),
      );
      final seventh = night.inMinutes / 7;
      expect(_minutes(sunrise, day.times[Prayer.fajr]!), closeTo(seventh, 2));
      expect(
        _minutes(
          day.times[Prayer.isha]!,
          maghrib.subtract(const Duration(minutes: 3)),
        ),
        closeTo(seventh, 2),
      );
    });

    test('Fajr is never earlier than a seventh of the night before sunrise, in any season', () {
      for (final date in dates) {
        final day = _day(59.9139, 10.7522, 'Europe/Oslo', date);
        final next = _day(
          59.9139,
          10.7522,
          'Europe/Oslo',
          DateTime.parse(date)
              .add(const Duration(days: 1))
              .toIso8601String()
              .substring(0, 10),
        );
        final night = next.times[Prayer.sunrise]!.difference(
          day.times[Prayer.maghrib]!.subtract(const Duration(minutes: 3)),
        );
        expect(
          _minutes(day.times[Prayer.sunrise]!, day.times[Prayer.fajr]!),
          lessThanOrEqualTo(night.inMinutes / 7 + 2),
          reason: date,
        );
      }
    });

    test('reports the high-latitude rule for Fajr and Isha', () {
      final day = _day(59.9139, 10.7522, 'Europe/Oslo', '2026-06-21');
      expect(
        day.notices,
        containsAll([
          const Notice(NoticeCode.highLatitudeRuleApplied, Prayer.fajr),
          const Notice(NoticeCode.highLatitudeRuleApplied, Prayer.isha),
        ]),
      );
    });
  });

  group('polar days', () {
    test(
      'Tromso in June has no Fajr, sunrise, Maghrib or Isha, and says so',
      () {
        final day = _day(69.6492, 18.9553, 'Europe/Oslo', '2026-06-21');
        for (final prayer in [
          Prayer.fajr,
          Prayer.sunrise,
          Prayer.maghrib,
          Prayer.isha,
        ]) {
          expect(day.times[prayer], isNull, reason: prayer.name);
          expect(
            day.notices,
            contains(Notice(NoticeCode.polarNoEvent, prayer)),
          );
        }
        expect(day.times[Prayer.dhuhr], isNotNull);
      },
    );
  });
}
