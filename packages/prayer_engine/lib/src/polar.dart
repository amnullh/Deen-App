/// Prayer times computed from the sun solver alone: polar day and night, the
/// days around them, and very high latitudes.
///
/// `adhan_dart` does not detect polar days: it clamps the failed trigonometry
/// and returns times that are hours or a day away from the truth. Here each
/// event is solved on its own and an event that does not occur is null with a
/// [Notice]. Fajr and Isha by twilight angle still occur in polar night, so
/// they are returned; the high-latitude night rules are not applied because
/// there is no night to take a portion of.
library;

import 'package:adhan_dart/adhan_dart.dart' as adhan;

import 'solar.dart';
import 'types.dart';

/// Rounds an exact instant the way `adhan_dart` does: whole seconds first,
/// then to the nearest minute (or up when [rounding] is `Rounding.up`).
DateTime roundLikeAdhan(DateTime exact, adhan.Rounding rounding) {
  final floored = DateTime.fromMillisecondsSinceEpoch(
    (exact.millisecondsSinceEpoch ~/ 1000) * 1000,
    isUtc: true,
  );
  if (rounding == adhan.Rounding.none) return floored;
  final seconds = floored.second;
  final int offset;
  if (rounding == adhan.Rounding.up) {
    offset = seconds > 0 ? 60 - seconds : 0;
  } else {
    offset = seconds >= 30 ? 60 - seconds : -seconds;
  }
  return floored.add(Duration(seconds: offset));
}

/// The UTC instant at fraction [m] of the UT day that starts at [dayStart].
DateTime instantAt(DateTime dayStart, double m) => dayStart.add(
  Duration(microseconds: (m * Duration.microsecondsPerDay).round()),
);

/// The six events of one solar day, with a notice for each that is missing.
class SolarDayTimes {
  const SolarDayTimes(this.times, this.notices);

  final Map<Prayer, DateTime?> times;
  final List<Notice> notices;
}

/// Computes the day from the sun solver alone.
///
/// Used for polar and near-polar days and for latitudes where the single
/// correction step of `adhan_dart` is not accurate enough (sunrise and sunset
/// can be minutes off when the Sun only grazes the horizon).
///
/// [adjustments] are the total minutes (method plus user) added to each
/// prayer; [params] supplies the method's angles, interval and night rule.
/// [nextSolver] is the next day's solver, whose sunrise ends the night. When
/// the Sun does not both rise and set, or tomorrow has no sunrise, there is no
/// night to take a portion of: Fajr and Isha are then only the twilight times
/// when the angle is reached, and null with a notice otherwise.
///
/// Moonsighting Committee twilight is defined from sunrise and sunset by
/// seasonal tables and is not offered without a night.
SolarDayTimes resolveWithSolver({
  required SunSolver solver,
  required SunSolver nextSolver,
  required DateTime dayStart,
  required adhan.CalculationParameters params,
  required double asrShadowFactor,
  required Map<Prayer, int> adjustments,
}) {
  DateTime? finish(Prayer prayer, double? m) {
    if (m == null) return null;
    return roundLikeAdhan(
      instantAt(dayStart, m).add(Duration(minutes: adjustments[prayer] ?? 0)),
      params.rounding,
    );
  }

  final sunrise = solver.horizonEvent(afterTransit: false);
  final sunset = solver.horizonEvent(afterTransit: true);
  final nextSunrise = nextSolver.horizonEvent(afterTransit: false);
  final night = sunrise != null && sunset != null && nextSunrise != null
      ? 1 + nextSunrise - sunset
      : null;
  final moonsighting =
      params.method == adhan.CalculationMethod.moonsightingCommittee;
  final portions = params.nightPortions();
  final notices = <Notice>[];

  double? fajr;
  if (!moonsighting && params.fajrAngle > 0) {
    fajr = solver.eventAt(-params.fajrAngle, afterTransit: false);
    if (night != null) {
      final limit = sunrise! - portions[adhan.Prayer.fajr]! * night;
      if (fajr == null || fajr < limit) {
        fajr = limit;
        notices.add(
          const Notice(NoticeCode.highLatitudeRuleApplied, Prayer.fajr),
        );
      }
    }
  }

  double? isha;
  final interval = params.ishaInterval ?? 0;
  if (interval > 0) {
    isha = sunset == null ? null : sunset + interval / Duration.minutesPerDay;
  } else if (!moonsighting && params.ishaAngle > 0) {
    isha = solver.eventAt(-params.ishaAngle, afterTransit: true);
    if (night != null) {
      final limit = sunset! + portions[adhan.Prayer.isha]! * night;
      if (isha == null || isha > limit) {
        isha = limit;
        notices.add(
          const Notice(NoticeCode.highLatitudeRuleApplied, Prayer.isha),
        );
      }
    }
  }

  // Shia methods: Maghrib by angle only when it falls between sunset and Isha.
  var maghrib = sunset;
  final maghribAngle = params.maghribAngle;
  if (maghribAngle != null) {
    final byAngle = solver.eventAt(-maghribAngle, afterTransit: true);
    if (byAngle != null &&
        (sunset == null || byAngle > sunset) &&
        (isha == null || byAngle < isha)) {
      maghrib = byAngle;
    }
  }

  final times = <Prayer, DateTime?>{
    Prayer.fajr: finish(Prayer.fajr, fajr),
    Prayer.sunrise: finish(Prayer.sunrise, sunrise),
    Prayer.dhuhr: finish(Prayer.dhuhr, solver.transit()),
    Prayer.asr: finish(Prayer.asr, solver.asr(asrShadowFactor)),
    Prayer.maghrib: finish(Prayer.maghrib, maghrib),
    Prayer.isha: finish(Prayer.isha, isha),
  };
  return SolarDayTimes(times, [...notices, ...noEventNotices(times)]);
}

/// A [NoticeCode.polarNoEvent] notice for every prayer that has no time.
List<Notice> noEventNotices(Map<Prayer, DateTime?> times) => [
  for (final prayer in Prayer.values)
    if (times[prayer] == null) Notice(NoticeCode.polarNoEvent, prayer),
];
