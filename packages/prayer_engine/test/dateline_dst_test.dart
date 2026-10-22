// Date-line zones and DST transitions (T069).
//
// Prayer instants are absolute UTC instants; the local date only chooses which
// solar day to compute. These tests check that the instants stay right and the
// local-date semantics hold where the civil date is not the solar date.
import 'package:prayer_engine/prayer_engine.dart';
import 'package:test/test.dart';

final _offsets = BundledOffsetResolver();
final _engine = AdhanDartEngine(offsetResolver: _offsets);

DayTimes _compute({
  required double latitude,
  required double longitude,
  required String zone,
  required String date,
  CalculationMethod method = CalculationMethod.muslimWorldLeague,
}) {
  return _engine.timesFor(
    latitude: latitude,
    longitude: longitude,
    timeZoneId: zone,
    localDate: date,
    method: method,
    asr: AsrMethod.standard,
    highLatitudeRule: defaultHighLatitudeRule(latitude),
    offsetsMinutes: const {},
    imsakMinutes: 10,
  );
}

/// The wall-clock time of [instant] in [zone].
DateTime _local(String zone, DateTime instant) =>
    instant.add(_offsets.offsetAt(zone, instant));

String _dateOf(DateTime local) =>
    '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';

String _plusDays(String date, int days) {
  final parsed = parseLocalDate(date);
  return _dateOf(DateTime.utc(parsed.year, parsed.month, parsed.day + days));
}

void _expectWholeDayOnLocalDate(String zone, DayTimes day) {
  for (final prayer in Prayer.values) {
    final time = day.times[prayer];
    expect(time, isNotNull, reason: '${day.localDate} ${prayer.name}');
    expect(
      _dateOf(_local(zone, time!)),
      day.localDate,
      reason: '${day.localDate} ${prayer.name} at ${time.toIso8601String()}',
    );
  }
  final ordered = Prayer.values.map((p) => day.times[p]!).toList();
  for (var i = 1; i < ordered.length; i++) {
    expect(ordered[i].isAfter(ordered[i - 1]), isTrue);
  }
}

void main() {
  group('Apia (UTC+13, east of 180 but longitude -171.8)', () {
    const zone = 'Pacific/Apia';
    const latitude = -13.8333;
    const longitude = -171.7667;

    test('uses a one-day solar shift', () {
      final noon = DateTime.utc(2026, 7, 21, 12);
      expect(solarDayShift(_offsets.offsetAt(zone, noon), longitude), 1);
    });

    test('every prayer of a civil date falls on that civil date', () {
      for (final date in [
        '2026-01-15',
        '2026-03-20',
        '2026-07-21',
        '2026-09-30',
        '2026-12-31',
      ]) {
        _expectWholeDayOnLocalDate(
          zone,
          _compute(
            latitude: latitude,
            longitude: longitude,
            zone: zone,
            date: date,
          ),
        );
      }
    });

    test('Dhuhr is near 12:00 on the wall clock, not near midnight', () {
      final day = _compute(
        latitude: latitude,
        longitude: longitude,
        zone: zone,
        date: '2026-07-21',
      );
      final local = _local(zone, day.times[Prayer.dhuhr]!);
      expect(local.hour, anyOf(11, 12), reason: local.toIso8601String());
    });

    test('consecutive civil dates are about one day apart', () {
      final a = _compute(
        latitude: latitude,
        longitude: longitude,
        zone: zone,
        date: '2026-07-21',
      );
      final b = _compute(
        latitude: latitude,
        longitude: longitude,
        zone: zone,
        date: '2026-07-22',
      );
      final gap = b.times[Prayer.dhuhr]!.difference(a.times[Prayer.dhuhr]!);
      expect(gap.inMinutes, inInclusiveRange(24 * 60 - 2, 24 * 60 + 2));
    });
  });

  group('Kiritimati (UTC+14)', () {
    const zone = 'Pacific/Kiritimati';
    const latitude = 1.8721;
    const longitude = -157.4278;

    test('uses a one-day solar shift', () {
      final noon = DateTime.utc(2026, 6, 1, 12);
      expect(solarDayShift(_offsets.offsetAt(zone, noon), longitude), 1);
    });

    test('every prayer of a civil date falls on that civil date', () {
      for (final date in ['2026-02-01', '2026-06-01', '2026-11-30']) {
        _expectWholeDayOnLocalDate(
          zone,
          _compute(
            latitude: latitude,
            longitude: longitude,
            zone: zone,
            date: date,
          ),
        );
      }
    });

    test('Dhuhr on the wall clock is within an hour of noon', () {
      final day = _compute(
        latitude: latitude,
        longitude: longitude,
        zone: zone,
        date: '2026-06-01',
      );
      final local = _local(zone, day.times[Prayer.dhuhr]!);
      expect(local.hour, anyOf(11, 12));
    });
  });

  group('A zone near its mean solar time needs no shift', () {
    test('London, New York and Makkah', () {
      final noon = DateTime.utc(2026, 7, 1, 12);
      expect(solarDayShift(_offsets.offsetAt('Europe/London', noon), -0.13), 0);
      expect(
        solarDayShift(_offsets.offsetAt('America/New_York', noon), -74.0),
        0,
      );
      expect(solarDayShift(_offsets.offsetAt('Asia/Riyadh', noon), 39.8), 0);
    });
  });

  group('DST transitions', () {
    // (zone, latitude, longitude, spring-forward date, fall-back date)
    final zones = [
      ('Europe/London', 51.5074, -0.1278, '2026-03-29', '2026-10-25'),
      ('Australia/Sydney', -33.8688, 151.2093, '2026-10-04', '2026-04-05'),
    ];

    for (final (zone, latitude, longitude, spring, fall) in zones) {
      for (final transition in [spring, fall]) {
        test('$zone on $transition: prayers stay on the civil date', () {
          for (final date in [
            _plusDays(transition, -1),
            transition,
            _plusDays(transition, 1),
          ]) {
            final day = _compute(
              latitude: latitude,
              longitude: longitude,
              zone: zone,
              date: date,
              method: CalculationMethod.egypt,
            );
            for (final prayer in Prayer.values) {
              final time = day.times[prayer]!;
              expect(
                _dateOf(_local(zone, time)),
                date,
                reason: '$zone $date ${prayer.name} ${time.toIso8601String()}',
              );
            }
          }
        });

        test('$zone on $transition: the UTC instants are continuous', () {
          // Astronomy does not know about the clock change: Dhuhr moves by
          // under two minutes per day in UTC, while the wall clock jumps by an
          // hour.
          final before = _compute(
            latitude: latitude,
            longitude: longitude,
            zone: zone,
            date: _plusDays(transition, -1),
          );
          final on = _compute(
            latitude: latitude,
            longitude: longitude,
            zone: zone,
            date: transition,
          );
          final after = _compute(
            latitude: latitude,
            longitude: longitude,
            zone: zone,
            date: _plusDays(transition, 1),
          );
          for (final pair in [(before, on), (on, after)]) {
            final gap = pair.$2.times[Prayer.dhuhr]!.difference(
              pair.$1.times[Prayer.dhuhr]!,
            );
            expect(gap.inMinutes, inInclusiveRange(24 * 60 - 3, 24 * 60 + 3));
          }
        });
      }
    }

    test('London Dhuhr wall clock moves by one hour across the change', () {
      final before = _compute(
        latitude: 51.5074,
        longitude: -0.1278,
        zone: 'Europe/London',
        date: '2026-03-28',
      );
      final after = _compute(
        latitude: 51.5074,
        longitude: -0.1278,
        zone: 'Europe/London',
        date: '2026-03-29',
      );
      final localBefore = _local('Europe/London', before.times[Prayer.dhuhr]!);
      final localAfter = _local('Europe/London', after.times[Prayer.dhuhr]!);
      // Clock time of Dhuhr jumps by about +1 h (BST starts), apart from the
      // few minutes the Sun itself moves.
      final jump =
          (localAfter.hour * 60 + localAfter.minute) -
          (localBefore.hour * 60 + localBefore.minute);
      expect(jump, inInclusiveRange(57, 63));
    });

    test('Sydney Dhuhr wall clock moves back by one hour when DST ends', () {
      final before = _compute(
        latitude: -33.8688,
        longitude: 151.2093,
        zone: 'Australia/Sydney',
        date: '2026-04-04',
      );
      final after = _compute(
        latitude: -33.8688,
        longitude: 151.2093,
        zone: 'Australia/Sydney',
        date: '2026-04-05',
      );
      final localBefore = _local(
        'Australia/Sydney',
        before.times[Prayer.dhuhr]!,
      );
      final localAfter = _local('Australia/Sydney', after.times[Prayer.dhuhr]!);
      final jump =
          (localAfter.hour * 60 + localAfter.minute) -
          (localBefore.hour * 60 + localBefore.minute);
      expect(jump, inInclusiveRange(-63, -57));
    });
  });

  group('Time-zone ids', () {
    test('an unknown zone is reported, not silently treated as UTC', () {
      expect(
        () => _compute(
          latitude: 0,
          longitude: 0,
          zone: 'Mars/Olympus_Mons',
          date: '2026-01-01',
        ),
        throwsArgumentError,
      );
    });

    test('link zones such as Europe/Oslo resolve', () {
      expect(
        _offsets.offsetAt('Europe/Oslo', DateTime.utc(2026, 7, 1)),
        const Duration(hours: 2),
      );
    });
  });
}
