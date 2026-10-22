// Sunrise, sunset and twilight times against the JPL Horizons ephemeris
// (spike S9), independent of both the engine and the oracle.
//
// Source: NASA/JPL Horizons System (DE441), Sun (10), geodetic ground site,
// quantity 4 (apparent elevation, airless), 1-minute steps, queried 2026-10-21.
// Each expected instant is where the elevation crosses -50' (sunrise/sunset,
// the conventional refraction plus solar radius), -18 degrees or -17 degrees.
// Horizons data is NASA public information; only these derived instants are
// stored. The Tromso days are chosen where the Sun only grazes the horizon, the
// hardest case for any solver.
import 'package:prayer_engine/prayer_engine.dart';
import 'package:test/test.dart';

class _Place {
  const _Place(this.name, this.latitude, this.longitude, this.zone);

  final String name;
  final double latitude;
  final double longitude;
  final String zone;
}

const _makkah = _Place('Makkah', 21.4225, 39.8262, 'Asia/Riyadh');
const _london = _Place('London', 51.5074, -0.1278, 'Europe/London');
const _sydney = _Place('Sydney', -33.8688, 151.2093, 'Australia/Sydney');
const _newYork = _Place('New York', 40.7128, -74.006, 'America/New_York');
const _tromso = _Place('Tromso', 69.6492, 18.9553, 'Europe/Oslo');
const _reykjavik = _Place('Reykjavik', 64.1466, -21.9426, 'Atlantic/Reykjavik');

class _Case {
  const _Case(
    this.place,
    this.date,
    this.prayer,
    this.truthUtc, {
    this.rule,
    this.toleranceSeconds = 60,
  });

  final _Place place;
  final String date;
  final Prayer prayer;
  final String truthUtc;
  final HighLatitudeRule? rule;

  /// Allowed difference from the ephemeris, in seconds.
  final int toleranceSeconds;
}

const List<_Case> _cases = [
  _Case(_makkah, '2026-03-20', Prayer.sunrise, '2026-03-20T03:24:57Z'),
  _Case(_makkah, '2026-03-20', Prayer.maghrib, '2026-03-20T15:31:40Z'),
  _Case(_makkah, '2026-03-20', Prayer.fajr, '2026-03-20T02:11:03Z'),
  _Case(_makkah, '2026-03-20', Prayer.isha, '2026-03-20T16:41:20Z'),
  _Case(_london, '2026-06-21', Prayer.sunrise, '2026-06-21T03:43:05Z'),
  _Case(_london, '2026-06-21', Prayer.maghrib, '2026-06-21T20:21:33Z'),
  _Case(_sydney, '2026-12-20', Prayer.maghrib, '2026-12-20T09:04:52Z'),
  _Case(_sydney, '2026-12-20', Prayer.isha, '2026-12-20T10:42:23Z'),
  _Case(_newYork, '2026-01-15', Prayer.sunrise, '2026-01-15T12:17:53Z'),
  _Case(_newYork, '2026-01-15', Prayer.maghrib, '2026-01-15T21:53:23Z'),
  _Case(_newYork, '2026-01-15', Prayer.fajr, '2026-01-15T10:41:14Z'),
  _Case(_newYork, '2026-01-15', Prayer.isha, '2026-01-15T23:24:38Z'),
  // Sun barely above the horizon: adhan_dart alone is 7 minutes off here.
  _Case(_tromso, '2026-01-15', Prayer.sunrise, '2026-01-15T10:29:35Z'),
  _Case(_tromso, '2026-01-15', Prayer.maghrib, '2026-01-15T11:18:14Z'),
  // The first night of the midnight sun: the Sun dips 0.026 degrees below the
  // threshold, so sunrise exists at 00:52 local on 18 May.
  // The Sun's altitude changes by about 0.0003 degrees per minute there, so a
  // 0.001 degree model difference moves the event by minutes; two minutes is
  // the honest bound for this one grazing case.
  _Case(
    _tromso,
    '2026-05-18',
    Prayer.sunrise,
    '2026-05-17T22:52:07Z',
    toleranceSeconds: 120,
  ),
  _Case(
    _reykjavik,
    '2026-03-20',
    Prayer.sunrise,
    '2026-03-20T07:28:37Z',
    rule: HighLatitudeRule.angleBased,
  ),
  _Case(
    _reykjavik,
    '2026-03-20',
    Prayer.maghrib,
    '2026-03-20T19:43:24Z',
    rule: HighLatitudeRule.angleBased,
  ),
  _Case(
    _reykjavik,
    '2026-03-20',
    Prayer.fajr,
    '2026-03-20T04:36:46Z',
    rule: HighLatitudeRule.angleBased,
  ),
  _Case(
    _reykjavik,
    '2026-03-20',
    Prayer.isha,
    '2026-03-20T22:24:52Z',
    rule: HighLatitudeRule.angleBased,
  ),
];

void main() {
  final engine = AdhanDartEngine();

  group(
    'events against JPL Horizons (Muslim World League: 18 and 17 degrees)',
    () {
      for (final c in _cases) {
        test('${c.place.name} ${c.date} ${c.prayer.name}', () {
          final day = engine.timesFor(
            latitude: c.place.latitude,
            longitude: c.place.longitude,
            timeZoneId: c.place.zone,
            localDate: c.date,
            method: CalculationMethod.muslimWorldLeague,
            asr: AsrMethod.standard,
            highLatitudeRule:
                c.rule ?? defaultHighLatitudeRule(c.place.latitude),
            offsetsMinutes: const {},
            imsakMinutes: 10,
          );
          final got = day.times[c.prayer];
          expect(got, isNotNull);
          final truth = DateTime.parse(c.truthUtc);
          expect(
            got!.difference(truth).inSeconds.abs(),
            lessThanOrEqualTo(c.toleranceSeconds),
            reason: 'engine ${got.toIso8601String()} vs truth ${c.truthUtc}',
          );
        });
      }
    },
  );

  test('Tromso on 18 May 2026 has no sunset (the Sun stays up)', () {
    final day = engine.timesFor(
      latitude: _tromso.latitude,
      longitude: _tromso.longitude,
      timeZoneId: _tromso.zone,
      localDate: '2026-05-18',
      method: CalculationMethod.muslimWorldLeague,
      asr: AsrMethod.standard,
      highLatitudeRule: HighLatitudeRule.seventhOfNight,
      offsetsMinutes: const {},
      imsakMinutes: 10,
    );
    expect(day.times[Prayer.maghrib], isNull);
  });
}
