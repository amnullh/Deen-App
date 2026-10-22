// Asr start, checked against the JPL Horizons ephemeris (spike S9).
//
// Source: NASA/JPL Horizons System (DE441), observer table, target Sun (10),
// geodetic site on the ground, quantity 4 (apparent azimuth and elevation),
// airless, 1-minute steps. NASA ephemeris data is public information; only
// these derived instants are stored here. For each case the noon shadow was
// taken from the maximum elevation, the Asr elevation is
// atan(1 / (factor + tan(zenith distance at noon))) and the instant is where
// the elevation falls to it after noon. Horizons was queried on 2026-10-21.
//
// `adhan_dart` evaluates the Sun's declination at 00:00 UT instead of at noon,
// which moves Asr by up to 5 minutes at high latitudes in winter. These cases
// pin the corrected behaviour.
import 'package:prayer_engine/prayer_engine.dart';
import 'package:test/test.dart';

class _Case {
  const _Case(
    this.name,
    this.latitude,
    this.longitude,
    this.zone,
    this.date,
    this.asr,
    this.truthUtc,
  );

  final String name;
  final double latitude;
  final double longitude;
  final String zone;
  final String date;
  final AsrMethod asr;
  final String truthUtc;
}

const List<_Case> _cases = [
  _Case(
    'Reykjavik',
    64.1466,
    -21.9426,
    'Atlantic/Reykjavik',
    '2026-01-01',
    AsrMethod.standard,
    '2026-01-01T13:56:35Z',
  ),
  _Case(
    'London',
    51.5074,
    -0.1278,
    'Europe/London',
    '2026-01-26',
    AsrMethod.standard,
    '2026-01-26T14:16:32Z',
  ),
  _Case(
    'New York',
    40.7128,
    -74.006,
    'America/New_York',
    '2026-02-11',
    AsrMethod.standard,
    '2026-02-11T20:01:35Z',
  ),
  _Case(
    'Los Angeles',
    34.0522,
    -118.2437,
    'America/Los_Angeles',
    '2026-10-03',
    AsrMethod.standard,
    '2026-10-03T23:02:24Z',
  ),
  _Case(
    'Oslo',
    59.9139,
    10.7522,
    'Europe/Oslo',
    '2026-01-02',
    AsrMethod.standard,
    '2026-01-02T12:17:25Z',
  ),
  _Case(
    'Sydney',
    -33.8688,
    151.2093,
    'Australia/Sydney',
    '2026-06-21',
    AsrMethod.standard,
    '2026-06-21T04:35:53Z',
  ),
  _Case(
    'Makkah',
    21.4225,
    39.8262,
    'Asia/Riyadh',
    '2026-10-20',
    AsrMethod.standard,
    '2026-10-20T12:24:32Z',
  ),
  _Case(
    'Tromso',
    69.6492,
    18.9553,
    'Europe/Oslo',
    '2026-05-10',
    AsrMethod.standard,
    '2026-05-10T15:18:18Z',
  ),
  _Case(
    'Oslo Hanafi',
    59.9139,
    10.7522,
    'Europe/Oslo',
    '2026-06-21',
    AsrMethod.hanafi,
    '2026-06-21T17:19:27Z',
  ),
];

void main() {
  final engine = AdhanDartEngine();

  group('Asr against JPL Horizons', () {
    for (final c in _cases) {
      test('${c.name} ${c.date} ${c.asr.name}', () {
        final day = engine.timesFor(
          latitude: c.latitude,
          longitude: c.longitude,
          timeZoneId: c.zone,
          localDate: c.date,
          method: CalculationMethod.muslimWorldLeague,
          asr: c.asr,
          highLatitudeRule: defaultHighLatitudeRule(c.latitude),
          offsetsMinutes: const {},
          imsakMinutes: 10,
        );
        final truth = DateTime.parse(c.truthUtc);
        final got = day.times[Prayer.asr]!;
        // Whole-minute output: within 60 seconds of the exact instant.
        expect(
          got.difference(truth).inSeconds.abs(),
          lessThanOrEqualTo(60),
          reason: 'engine ${got.toIso8601String()} vs truth ${c.truthUtc}',
        );
      });
    }
  });
}
