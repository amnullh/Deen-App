/// Solar position and sun-event solver used where `adhan_dart` is not enough:
/// the Asr shadow rule, polar-day detection and the natural (unclamped)
/// twilight times.
///
/// The solar coordinates follow Meeus, *Astronomical Algorithms*, chapters 12
/// and 25 (apparent position, about 0.01 degree). Unlike `adhan_dart` this
/// solver evaluates the Sun at the moment of each event instead of at
/// midnight UT, which matters for Asr at high latitudes (spike S9).
library;

import 'dart:math' as math;

const double _degToRad = math.pi / 180;
const double _radToDeg = 180 / math.pi;

double _sin(double degrees) => math.sin(degrees * _degToRad);
double _cos(double degrees) => math.cos(degrees * _degToRad);
double _tan(double degrees) => math.tan(degrees * _degToRad);

double _unwind(double degrees) =>
    degrees - 360 * (degrees / 360).floorToDouble();

/// Wraps an angle to the range -180 up to 180 degrees.
double _shift(double degrees) =>
    degrees - 360 * (degrees / 360).roundToDouble();

/// Altitude of the Sun's centre at sunrise and sunset: refraction (34') plus
/// the solar radius (16'), the value the oracle and `adhan_dart` also use.
const double sunriseSunsetAltitude = -50 / 60;

/// The Sun's apparent equatorial position and the sidereal time at one instant.
class SunPosition {
  const SunPosition({
    required this.declination,
    required this.rightAscension,
    required this.siderealTime,
  });

  /// Degrees, -23.44 to +23.44.
  final double declination;

  /// Degrees, 0 up to 360.
  final double rightAscension;

  /// Apparent sidereal time at Greenwich, degrees.
  final double siderealTime;
}

/// The Julian day number of 00:00 UT on a Gregorian calendar date.
double julianDayAtMidnight(int year, int month, int day) {
  final y = month > 2 ? year : year - 1;
  final m = month > 2 ? month : month + 12;
  final a = (y / 100).truncate();
  final b = 2 - a + (a / 4).truncate();
  return (365.25 * (y + 4716)).truncate() +
      (30.6001 * (m + 1)).truncate() +
      day +
      b -
      1524.5;
}

/// The Sun's apparent position at Julian day [jd] (UT is used for ET; the
/// difference is below 0.001 degree).
SunPosition sunPosition(double jd) {
  final t = (jd - 2451545.0) / 36525;
  final meanLongitude = _unwind(
    280.46646 + 36000.76983 * t + 0.0003032 * t * t,
  );
  final meanAnomaly = _unwind(357.52911 + 35999.05029 * t - 0.0001537 * t * t);
  final center =
      (1.914602 - 0.004817 * t - 0.000014 * t * t) * _sin(meanAnomaly) +
      (0.019993 - 0.000101 * t) * _sin(2 * meanAnomaly) +
      0.000289 * _sin(3 * meanAnomaly);
  final omega = 125.04 - 1934.136 * t;
  final apparentLongitude =
      meanLongitude + center - 0.00569 - 0.00478 * _sin(omega);
  final meanObliquity =
      23.439291 - 0.0130042 * t - 0.00000016 * t * t + 0.000000504 * t * t * t;
  final obliquity = meanObliquity + 0.00256 * _cos(omega);

  final declination =
      math.asin(_sin(obliquity) * _sin(apparentLongitude)) * _radToDeg;
  final rightAscension = _unwind(
    math.atan2(
          _cos(obliquity) * _sin(apparentLongitude),
          _cos(apparentLongitude),
        ) *
        _radToDeg,
  );

  final d = jd - 2451545.0;
  final meanSidereal = _unwind(
    280.46061837 + 360.98564736629 * d + 0.000387933 * t * t,
  );
  // Nutation in longitude times cos(obliquity): the equation of the equinoxes.
  final nutation = -0.00478 * _sin(omega);
  final siderealTime = _unwind(meanSidereal + nutation * _cos(obliquity));

  return SunPosition(
    declination: declination,
    rightAscension: rightAscension,
    siderealTime: siderealTime,
  );
}

/// Solves sun events for one place on one UT day.
///
/// All results are fractions of the UT day that starts at [dayStartJd]
/// (00:00 UT); they may fall outside 0 up to 1 near the date line. A null
/// result means the event does not occur (the Sun never reaches the altitude).
class SunSolver {
  SunSolver({
    required this.latitude,
    required this.longitude,
    required this.dayStartJd,
  });

  final double latitude;

  /// Degrees east.
  final double longitude;
  final double dayStartJd;

  /// Local hour angle of the Sun in degrees (0 at transit, positive after it).
  double _hourAngle(double m) {
    final sun = sunPosition(dayStartJd + m);
    return _shift(sun.siderealTime + longitude - sun.rightAscension);
  }

  /// Solar noon, as a fraction of the UT day starting at [dayStartJd].
  double transit() {
    var m = 0.5 - longitude / 360;
    for (var i = 0; i < 6; i++) {
      m -= _hourAngle(m) / 360;
    }
    return m;
  }

  /// Declination of the Sun at fraction [m] of the day.
  double declinationAt(double m) => sunPosition(dayStartJd + m).declination;

  /// The moment, before or after transit, when the Sun's centre is at
  /// [altitude] degrees (negative below the horizon); null if it never is.
  ///
  /// The hour angle of the event depends on the declination at the event, so
  /// the solution is iterated. While the iteration is still far from the
  /// answer an out-of-range cosine is clamped (the declination used then is
  /// only a guess); a cosine out of range at the end means the Sun really does
  /// not reach [altitude].
  double? eventAt(double altitude, {required bool afterTransit}) {
    final noon = transit();
    var m = noon + (afterTransit ? 0.25 : -0.25);
    for (var i = 0; i < 16; i++) {
      final cosH0 = _cosHourAngle(altitude, m);
      final h0 = math.acos(cosH0.clamp(-1.0, 1.0)) * _radToDeg;
      final target = afterTransit ? h0 : -h0;
      final step = _shift(_hourAngle(m) - target) / 360;
      m -= step;
      if (step.abs() < 1e-10) break;
    }
    final cosH0 = _cosHourAngle(altitude, m);
    if (cosH0.isNaN ||
        cosH0 < -1 - _edgeTolerance ||
        cosH0 > 1 + _edgeTolerance) {
      return null;
    }
    return m;
  }

  double _cosHourAngle(double altitude, double m) {
    final declination = declinationAt(m);
    return (_sin(altitude) - _sin(latitude) * _sin(declination)) /
        (_cos(latitude) * _cos(declination));
  }

  /// How far past +-1 the cosine may land and still count as reached. It
  /// absorbs the rounding of the iteration, about 0.001 degree of altitude.
  static const double _edgeTolerance = 2e-5;

  /// Sunrise (before transit) or sunset (after transit); null when the Sun
  /// does not cross the horizon that day.
  double? horizonEvent({required bool afterTransit}) =>
      eventAt(sunriseSunsetAltitude, afterTransit: afterTransit);

  /// The start of Asr: the afternoon moment when an object's shadow is
  /// [shadowFactor] times its height plus the length it had at noon (factor 1
  /// standard, 2 Hanafi). Null when the Sun is below the horizon at noon.
  ///
  /// The noon shadow uses the Sun's declination at transit, as defined; the
  /// moment itself is solved with the declination at that moment.
  double? asr(double shadowFactor) {
    final noon = transit();
    final zenithAtNoon = (latitude - declinationAt(noon)).abs();
    if (zenithAtNoon >= 90) return null;
    final altitude =
        math.atan(1 / (shadowFactor + _tan(zenithAtNoon))) * _radToDeg;
    return eventAt(altitude, afterTransit: true);
  }
}
