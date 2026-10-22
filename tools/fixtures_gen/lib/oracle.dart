/// An independent prayer-time calculation used to test the engine.
///
/// It follows the published method of PrayTimes.org (Hamid Zarrabi-Zadeh):
/// solar position from the Julian date, the event time from the sun's hour
/// angle, Asr from the shadow factor, and the high-latitude night portions.
/// It does not use `adhan_dart`, so agreement between the two is meaningful.
/// Method angles are the published definitions, not copied from `adhan_dart`.
///
/// The Moonsighting Committee method needs seasonal twilight tables that this
/// oracle does not implement; it is checked against official samples instead.
library;

import 'dart:math' as math;

/// Calculation methods the oracle supports (all of the app's except
/// Moonsighting Committee).
enum OracleMethod {
  muslimWorldLeague,
  isna,
  egypt,
  ummAlQura,
  karachi,
  tehran,
  jafari,
  gulf,
  kuwait,
  qatar,
  singapore,
  diyanet,
  franceUoif,
}

enum OracleHighLatitude { middleOfNight, seventhOfNight, angleBased }

/// Published parameters of one method.
class MethodDefinition {
  const MethodDefinition({
    required this.fajrAngle,
    this.ishaAngle,
    this.ishaMinutesAfterMaghrib,
    this.maghribAngle,
    this.adjustmentsMinutes = const {},
    this.roundsUp = false,
  });

  final double fajrAngle;

  /// Isha as an angle below the horizon, or null when [ishaMinutesAfterMaghrib]
  /// is used.
  final double? ishaAngle;
  final int? ishaMinutesAfterMaghrib;

  /// Maghrib as an angle below the horizon (Shia methods), or null for sunset.
  final double? maghribAngle;

  /// Fixed minute offsets the method prescribes per event
  /// (`sunrise`, `dhuhr`, `asr`, `maghrib`).
  final Map<String, int> adjustmentsMinutes;

  /// Whether the method's published timetables round every time up to the next
  /// whole minute (Singapore, MUIS) instead of to the nearest minute.
  final bool roundsUp;
}

const Map<OracleMethod, MethodDefinition> methodDefinitions = {
  // Dhuhr +1 minute: the safety margin after the sun's transit that the
  // reference timetables of these methods include (it is a convention, not
  // astronomy; the engine keeps the same margin, see spike-results-engine.md).
  OracleMethod.muslimWorldLeague: MethodDefinition(
    fajrAngle: 18,
    ishaAngle: 17,
    adjustmentsMinutes: {'dhuhr': 1},
  ),
  OracleMethod.isna: MethodDefinition(
    fajrAngle: 15,
    ishaAngle: 15,
    adjustmentsMinutes: {'dhuhr': 1},
  ),
  OracleMethod.egypt: MethodDefinition(
    fajrAngle: 19.5,
    ishaAngle: 17.5,
    adjustmentsMinutes: {'dhuhr': 1},
  ),
  OracleMethod.ummAlQura: MethodDefinition(
    fajrAngle: 18.5,
    ishaMinutesAfterMaghrib: 90,
  ),
  OracleMethod.karachi: MethodDefinition(
    fajrAngle: 18,
    ishaAngle: 18,
    adjustmentsMinutes: {'dhuhr': 1},
  ),
  OracleMethod.tehran: MethodDefinition(
    fajrAngle: 17.7,
    ishaAngle: 14,
    maghribAngle: 4.5,
  ),
  OracleMethod.jafari: MethodDefinition(
    fajrAngle: 16,
    ishaAngle: 14,
    maghribAngle: 4,
  ),
  OracleMethod.gulf: MethodDefinition(
    fajrAngle: 19.5,
    ishaMinutesAfterMaghrib: 90,
  ),
  OracleMethod.kuwait: MethodDefinition(fajrAngle: 18, ishaAngle: 17.5),
  OracleMethod.qatar: MethodDefinition(
    fajrAngle: 18,
    ishaMinutesAfterMaghrib: 90,
  ),
  OracleMethod.singapore: MethodDefinition(
    fajrAngle: 20,
    ishaAngle: 18,
    adjustmentsMinutes: {'dhuhr': 1},
    roundsUp: true,
  ),
  OracleMethod.diyanet: MethodDefinition(
    fajrAngle: 18,
    ishaAngle: 17,
    adjustmentsMinutes: {'sunrise': -7, 'dhuhr': 5, 'asr': 4, 'maghrib': 7},
  ),
  OracleMethod.franceUoif: MethodDefinition(fajrAngle: 12, ishaAngle: 12),
};

/// One day's events as UTC instants; null when the event does not occur.
class OracleDay {
  const OracleDay({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });

  final DateTime? fajr;
  final DateTime? sunrise;
  final DateTime? dhuhr;
  final DateTime? asr;
  final DateTime? maghrib;
  final DateTime? isha;

  List<DateTime?> get all => [fajr, sunrise, dhuhr, asr, maghrib, isha];
}

/// Reduces an exact instant to whole minutes the way a printed timetable does:
/// to the nearest minute, or up to the next minute when [roundsUp].
DateTime toWholeMinute(DateTime t, {bool roundsUp = false}) {
  final minutes = t.millisecondsSinceEpoch / 60000;
  final whole = roundsUp ? minutes.ceil() : minutes.round();
  return DateTime.fromMillisecondsSinceEpoch(whole * 60000, isUtc: true);
}

/// Fixed-point iterations of the event times (PrayTimes uses a few; more only
/// matter where the Sun barely reaches the angle).
const int _iterations = 8;

const double _sunriseSunsetAngle = 0.8333; // refraction plus solar radius

double _rad(double degrees) => degrees * math.pi / 180;
double _deg(double radians) => radians * 180 / math.pi;
double _sin(double d) => math.sin(_rad(d));
double _cos(double d) => math.cos(_rad(d));
double _tan(double d) => math.tan(_rad(d));
double _arcsin(double x) => _deg(math.asin(x));
double _arccos(double x) => _deg(math.acos(x));
double _arccot(double x) => _deg(math.atan(1 / x));
double _arctan2(double y, double x) => _deg(math.atan2(y, x));

double _fixAngle(double a) => (a - 360 * (a / 360).floorToDouble());
double _fixHour(double h) => (h - 24 * (h / 24).floorToDouble());

double _julian(int year, int month, int day) {
  var y = year;
  var m = month;
  if (m <= 2) {
    y -= 1;
    m += 12;
  }
  final a = (y / 100).floor();
  final b = 2 - a + (a / 4).floor();
  return (365.25 * (y + 4716)).floorToDouble() +
      (30.6001 * (m + 1)).floorToDouble() +
      day +
      b -
      1524.5;
}

class _Sun {
  const _Sun(this.declination, this.equation);

  final double declination;

  /// Equation of time in hours.
  final double equation;
}

_Sun _sunPosition(double jd) {
  final d = jd - 2451545.0;
  final g = _fixAngle(357.529 + 0.98560028 * d);
  final q = _fixAngle(280.459 + 0.98564736 * d);
  final l = _fixAngle(q + 1.915 * _sin(g) + 0.020 * _sin(2 * g));
  final e = 23.439 - 0.00000036 * d;
  final ra = _arctan2(_cos(e) * _sin(l), _cos(l)) / 15;
  final eqt = q / 15 - _fixHour(ra);
  final decl = _arcsin(_sin(e) * _sin(l));
  return _Sun(decl, eqt);
}

/// Calculates one day for [latitude], [longitude] (degrees, east positive) and
/// the calendar date [year]-[month]-[day].
///
/// The returned instants are UTC. `asrShadowFactor` is 1 (standard) or 2
/// (Hanafi). [isRamadan] applies the published longer Isha interval of Umm
/// al-Qura (120 minutes after Maghrib).
OracleDay calculateDay({
  required double latitude,
  required double longitude,
  required int year,
  required int month,
  required int day,
  required OracleMethod method,
  required int asrShadowFactor,
  required OracleHighLatitude highLatitude,
  bool isRamadan = false,
}) {
  final definition = methodDefinitions[method]!;
  final jd0 = _julian(year, month, day) - longitude / (15 * 24);

  // Event times in hours, solving iteratively because the sun moves.
  var fajr = 5.0, sunrise = 6.0, dhuhr = 12.0, asr = 13.0, sunset = 18.0;
  var maghrib = 18.0, isha = 18.0;

  double midDay(double t, [double dayOffset = 0]) =>
      _fixHour(12 - _sunPosition(jd0 + dayOffset + t).equation);

  double angleTime(
    double angle,
    double t, {
    bool ccw = false,
    double dayOffset = 0,
    bool strict = true,
  }) {
    final decl = _sunPosition(jd0 + dayOffset + t).declination;
    final noon = midDay(t, dayOffset);
    final value =
        (-_sin(angle) - _sin(decl) * _sin(latitude)) /
        (_cos(decl) * _cos(latitude));
    if (value.isNaN) return double.nan;
    // Early iterations use a rough declination, so a cosine just out of range
    // is clamped; only the last iteration decides whether the event exists.
    if (value < -1 || value > 1) {
      if (strict) return double.nan;
      return noon + (ccw ? -1 : 1) * _arccos(value.clamp(-1.0, 1.0)) / 15;
    }
    return noon + (ccw ? -1 : 1) * _arccos(value) / 15;
  }

  // The noon shadow length uses the Sun's declination at noon (the shadow at
  // transit is the base of the definition); the moment itself is solved with
  // the declination at that moment.
  double asrTime(double factor, double t, double tNoon, {bool strict = true}) {
    final noonDecl = _sunPosition(jd0 + tNoon).declination;
    final zenith = (latitude - noonDecl).abs();
    if (zenith >= 90) return double.nan;
    final angle = -_arccot(factor + _tan(zenith));
    return angleTime(angle, t, strict: strict);
  }

  /// Tomorrow's sunrise in solar hours of tomorrow, or NaN if none.
  double tomorrowSunrise() {
    var rise = 6.0;
    for (var i = 0; i < _iterations; i++) {
      final t = rise / 24;
      rise = angleTime(
        _sunriseSunsetAngle,
        t.isNaN ? 0.25 : t,
        ccw: true,
        dayOffset: 1,
        strict: i == _iterations - 1,
      );
    }
    return rise;
  }

  for (var i = 0; i < _iterations; i++) {
    final strict = i == _iterations - 1;
    final tFajr = fajr / 24;
    final tSunrise = sunrise / 24;
    final tDhuhr = dhuhr / 24;
    final tAsr = asr / 24;
    final tSunset = sunset / 24;
    final tMaghrib = maghrib / 24;
    final tIsha = isha / 24;

    fajr = angleTime(
      definition.fajrAngle,
      tFajr.isNaN ? 0.2 : tFajr,
      ccw: true,
      strict: strict,
    );
    sunrise = angleTime(
      _sunriseSunsetAngle,
      tSunrise.isNaN ? 0.25 : tSunrise,
      ccw: true,
      strict: strict,
    );
    dhuhr = midDay(tDhuhr);
    asr = asrTime(
      asrShadowFactor.toDouble(),
      tAsr.isNaN ? 0.55 : tAsr,
      tDhuhr,
      strict: strict,
    );
    sunset = angleTime(
      _sunriseSunsetAngle,
      tSunset.isNaN ? 0.75 : tSunset,
      strict: strict,
    );
    maghrib = definition.maghribAngle != null
        ? angleTime(
            definition.maghribAngle!,
            tMaghrib.isNaN ? 0.75 : tMaghrib,
            strict: strict,
          )
        : sunset;
    if (definition.ishaAngle != null) {
      isha = angleTime(
        definition.ishaAngle!,
        tIsha.isNaN ? 0.8 : tIsha,
        strict: strict,
      );
    }
  }

  final maghribByAngle = definition.maghribAngle != null ? maghrib : double.nan;
  maghrib = sunset;
  if (definition.ishaMinutesAfterMaghrib != null) {
    final minutes = (method == OracleMethod.ummAlQura && isRamadan)
        ? 120
        : definition.ishaMinutesAfterMaghrib!;
    isha = maghrib + minutes / 60;
  }

  // High latitudes: limit Fajr and Isha to a portion of the night. The night
  // runs from today's sunset to tomorrow's sunrise (the Islamic definition of
  // the night); when either does not exist the night has no length and Fajr
  // and Isha stay at their natural twilight times, or at none.
  final nextSunrise = tomorrowSunrise();
  if (!sunrise.isNaN && !sunset.isNaN && !nextSunrise.isNaN) {
    final night = 24 + nextSunrise - sunset;
    double portion(double angle) {
      switch (highLatitude) {
        case OracleHighLatitude.middleOfNight:
          return 0.5;
        case OracleHighLatitude.seventhOfNight:
          return 1 / 7;
        case OracleHighLatitude.angleBased:
          return angle / 60;
      }
    }

    final fajrPortion = portion(definition.fajrAngle) * night;
    final fajrDiff = _fixHour(sunrise - fajr);
    if (fajr.isNaN || fajrDiff > fajrPortion) {
      fajr = sunrise - fajrPortion;
    }
    if (definition.ishaAngle != null) {
      final ishaPortion = portion(definition.ishaAngle!) * night;
      final ishaDiff = _fixHour(isha - sunset);
      if (isha.isNaN || ishaDiff > ishaPortion) {
        isha = sunset + ishaPortion;
      }
    }
  }

  // Shia methods place Maghrib at its angle only when that falls after sunset
  // and before Isha (a Maghrib after Isha would be nonsense, which happens at
  // high latitudes when Isha is limited by the night rule).
  if (!maghribByAngle.isNaN &&
      (sunset.isNaN || maghribByAngle > sunset) &&
      (isha.isNaN || maghribByAngle < isha)) {
    maghrib = maghribByAngle;
  }

  final adjust = definition.adjustmentsMinutes;
  sunrise += (adjust['sunrise'] ?? 0) / 60;
  dhuhr += (adjust['dhuhr'] ?? 0) / 60;
  asr += (adjust['asr'] ?? 0) / 60;
  maghrib += (adjust['maghrib'] ?? 0) / 60;

  final base = DateTime.utc(year, month, day);
  DateTime? instant(double hours) {
    if (hours.isNaN || hours.isInfinite) return null;
    // Local solar hours to UTC: remove the longitude offset.
    final utcHours = hours - longitude / 15;
    return base.add(Duration(milliseconds: (utcHours * 3600 * 1000).round()));
  }

  return OracleDay(
    fajr: instant(fajr),
    sunrise: instant(sunrise),
    dhuhr: instant(dhuhr),
    asr: instant(asr),
    maghrib: instant(maghrib),
    isha: instant(isha),
  );
}

/// Calculates the events of the civil date [year]-[month]-[day] in a zone whose
/// offset is given by [offsetAt].
///
/// The calculation is per solar day. For the civil date, this picks the solar
/// day (yesterday, today or tomorrow) whose solar noon falls on that civil
/// date, so places on the far side of the date line get the right day.
OracleDay calculateCivilDay({
  required double latitude,
  required double longitude,
  required int year,
  required int month,
  required int day,
  required OracleMethod method,
  required int asrShadowFactor,
  required OracleHighLatitude highLatitude,
  required Duration Function(DateTime utcInstant) offsetAt,
  bool isRamadan = false,
}) {
  for (final shift in const [0, -1, 1]) {
    final solar = DateTime.utc(year, month, day + shift);
    final candidate = calculateDay(
      latitude: latitude,
      longitude: longitude,
      year: solar.year,
      month: solar.month,
      day: solar.day,
      method: method,
      asrShadowFactor: asrShadowFactor,
      highLatitude: highLatitude,
      isRamadan: isRamadan,
    );
    final noon = candidate.dhuhr;
    if (noon == null) continue;
    final local = noon.add(offsetAt(noon));
    if (local.year == year && local.month == month && local.day == day) {
      return candidate;
    }
  }
  return const OracleDay(
    fajr: null,
    sunrise: null,
    dhuhr: null,
    asr: null,
    maghrib: null,
    isha: null,
  );
}
