import 'package:adhan_dart/adhan_dart.dart' as adhan;

import 'hijri/hijri.dart';
import 'night_times.dart';
import 'offset_resolver.dart';
import 'polar.dart';
import 'solar.dart';
import 'types.dart';

/// [PrayerTimeEngine] backed by `adhan_dart` (MIT), with three corrections
/// found by spike S9 (see `specs/001-offline-worship-app/spike-results-engine.md`):
///
/// * Asr is solved with the Sun's declination at noon for the shadow length
///   and at the moment itself for the angle (`adhan_dart` uses the declination
///   at 00:00 UT, which is up to 5 minutes off at high latitudes in winter).
/// * Days on which the Sun does not rise or set (or the night has no length)
///   are resolved event by event in `polar.dart`; `adhan_dart` returns
///   meaningless times there.
/// * Umm al-Qura Isha is 120 minutes after Maghrib during Ramadan (90 otherwise).
///
/// Everything else (Fajr, sunrise, Dhuhr, Maghrib, Isha on ordinary days and the
/// high-latitude night rules) is `adhan_dart`'s result, which agrees with the
/// independent oracle within one minute.
class AdhanDartEngine implements PrayerTimeEngine {
  /// [offsetResolver] decides which solar day a civil date belongs to near the
  /// date line. It defaults to the bundled time-zone database.
  AdhanDartEngine({OffsetResolver? offsetResolver})
    : _offsets = offsetResolver ?? BundledOffsetResolver();

  final OffsetResolver _offsets;

  /// From this latitude (either hemisphere) the day is computed by the sun
  /// solver alone: `adhan_dart` takes a single correction step, which leaves
  /// sunrise and sunset up to 7 minutes off in Tromso when the Sun only grazes
  /// the horizon. Below it the two agree within a minute (spike S9).
  static const double _solverOnlyLatitudeDegrees = 62;

  /// Two minutes: how far the final Fajr or Isha may sit from the natural
  /// twilight time before a high-latitude rule is reported as applied.
  static const Duration _ruleTolerance = Duration(minutes: 2);

  @override
  DayTimes timesFor({
    required double latitude,
    required double longitude,
    required String timeZoneId,
    required String localDate,
    required CalculationMethod method,
    required AsrMethod asr,
    required HighLatitudeRule highLatitudeRule,
    required Map<Prayer, int> offsetsMinutes,
    required int imsakMinutes,
  }) {
    DayTimes day(String date) => _dayFor(
      latitude: latitude,
      longitude: longitude,
      timeZoneId: timeZoneId,
      localDate: date,
      method: method,
      asr: asr,
      highLatitudeRule: highLatitudeRule,
      offsetsMinutes: offsetsMinutes,
    );

    final today = day(localDate);
    final imsak = imsakFor(today.times[Prayer.fajr], imsakMinutes);

    // The night needs tomorrow's Fajr; skip the work when there is no Maghrib.
    final maghrib = today.times[Prayer.maghrib];
    final night = maghrib == null
        ? null
        : nightTimes(maghrib, day(_addDays(localDate, 1)).times[Prayer.fajr]);

    return DayTimes(
      localDate: localDate,
      times: today.times,
      imsak: imsak,
      midnight: night?.midnight,
      lastThirdOfNight: night?.lastThird,
      notices: today.notices,
    );
  }

  DayTimes _dayFor({
    required double latitude,
    required double longitude,
    required String timeZoneId,
    required String localDate,
    required CalculationMethod method,
    required AsrMethod asr,
    required HighLatitudeRule highLatitudeRule,
    required Map<Prayer, int> offsetsMinutes,
  }) {
    final civil = parseLocalDate(localDate);

    // Near the date line the civil date is a day ahead of (or behind) the solar
    // day the calculation uses; shift by whole days so the times returned are
    // those of the requested civil date.
    final probe = DateTime.utc(
      civil.year,
      civil.month,
      civil.day,
      12,
    ).subtract(Duration(minutes: (longitude * 4).round()));
    final shift = solarDayShift(
      _offsets.offsetAt(timeZoneId, probe),
      longitude,
    );
    final dayStart = DateTime.utc(
      civil.year,
      civil.month,
      civil.day,
    ).subtract(Duration(days: shift));
    final nextDayStart = DateTime.utc(
      dayStart.year,
      dayStart.month,
      dayStart.day + 1,
    );

    final params = _parametersFor(method)
      ..madhab = asr == AsrMethod.hanafi
          ? adhan.Madhab.hanafi
          : adhan.Madhab.shafi
      ..highLatitudeRule = _mapHighLatitudeRule(highLatitudeRule)
      ..adjustments = _mapOffsets(offsetsMinutes);
    if (method == CalculationMethod.ummAlQura && isRamadan(localDate)) {
      params.ishaInterval = _ummAlQuraRamadanIshaMinutes;
    }

    final adjustments = {
      for (final prayer in Prayer.values)
        prayer:
            (offsetsMinutes[prayer] ?? 0) +
            (params.methodAdjustments[_adhanPrayer(prayer)] ?? 0),
    };

    final solver = SunSolver(
      latitude: latitude,
      longitude: longitude,
      dayStartJd: julianDayAtMidnight(
        dayStart.year,
        dayStart.month,
        dayStart.day,
      ),
    );
    final nextSolver = SunSolver(
      latitude: latitude,
      longitude: longitude,
      dayStartJd: julianDayAtMidnight(
        nextDayStart.year,
        nextDayStart.month,
        nextDayStart.day,
      ),
    );
    final asrFactor = asr == AsrMethod.hanafi ? 2.0 : 1.0;

    SolarDayTimes bySolver() => resolveWithSolver(
      solver: solver,
      nextSolver: nextSolver,
      dayStart: dayStart,
      params: params,
      asrShadowFactor: asrFactor,
      adjustments: adjustments,
    );

    final hasNight =
        solver.horizonEvent(afterTransit: false) != null &&
        solver.horizonEvent(afterTransit: true) != null &&
        nextSolver.horizonEvent(afterTransit: false) != null;
    final moonsighting = method == CalculationMethod.moonsightingCommittee;
    final useSolver =
        !hasNight ||
        (!moonsighting && latitude.abs() >= _solverOnlyLatitudeDegrees);

    SolarDayTimes resolved;
    if (useSolver) {
      resolved = bySolver();
    } else {
      try {
        resolved = _ordinaryDay(
          solver: solver,
          dayStart: dayStart,
          params: params,
          latitude: latitude,
          longitude: longitude,
          asrFactor: asrFactor,
          adjustments: adjustments,
        );
      } on UnsupportedError {
        // adhan_dart converts NaN solar times with floor(), which throws at
        // the poles. Resolve every event on its own instead.
        resolved = bySolver();
      }
    }
    return DayTimes(
      localDate: localDate,
      times: resolved.times,
      notices: resolved.notices,
    );
  }

  /// A day with a sunrise, a sunset and a night: `adhan_dart` for everything
  /// except Asr, plus a notice where a high-latitude rule changed a time.
  SolarDayTimes _ordinaryDay({
    required SunSolver solver,
    required DateTime dayStart,
    required adhan.CalculationParameters params,
    required double latitude,
    required double longitude,
    required double asrFactor,
    required Map<Prayer, int> adjustments,
  }) {
    final computed = adhan.PrayerTimes(
      date: dayStart,
      coordinates: adhan.Coordinates(latitude, longitude),
      calculationParameters: params,
    );

    final asrMoment = solver.asr(asrFactor);
    final times = <Prayer, DateTime?>{
      Prayer.fajr: computed.fajr,
      Prayer.sunrise: computed.sunrise,
      Prayer.dhuhr: computed.dhuhr,
      Prayer.asr: asrMoment == null
          ? null
          : roundLikeAdhan(
              instantAt(
                dayStart,
                asrMoment,
              ).add(Duration(minutes: adjustments[Prayer.asr] ?? 0)),
              params.rounding,
            ),
      Prayer.maghrib: computed.maghrib,
      Prayer.isha: computed.isha,
    };

    final notices = <Notice>[
      ..._ruleNotices(
        solver: solver,
        dayStart: dayStart,
        params: params,
        latitude: latitude,
        times: times,
        adjustments: adjustments,
      ),
      ...noEventNotices(times),
    ];
    return SolarDayTimes(times, notices);
  }

  /// Notices for Fajr and Isha when a high-latitude rule moved them away from
  /// the time the twilight angle gives (or the angle is never reached).
  List<Notice> _ruleNotices({
    required SunSolver solver,
    required DateTime dayStart,
    required adhan.CalculationParameters params,
    required double latitude,
    required Map<Prayer, DateTime?> times,
    required Map<Prayer, int> adjustments,
  }) {
    if (params.method == adhan.CalculationMethod.moonsightingCommittee) {
      // Its twilight is seasonal; adhan_dart switches to a seventh of the night
      // from 55 degrees north.
      return latitude >= 55
          ? const [
              Notice(NoticeCode.highLatitudeRuleApplied, Prayer.fajr),
              Notice(NoticeCode.highLatitudeRuleApplied, Prayer.isha),
            ]
          : const [];
    }

    bool moved(Prayer prayer, double? natural) {
      final result = times[prayer];
      if (natural == null || result == null) return true;
      final unadjusted = result.subtract(
        Duration(minutes: adjustments[prayer] ?? 0),
      );
      return unadjusted.difference(instantAt(dayStart, natural)).abs() >
          _ruleTolerance;
    }

    return [
      if (params.fajrAngle > 0 &&
          moved(
            Prayer.fajr,
            solver.eventAt(-params.fajrAngle, afterTransit: false),
          ))
        const Notice(NoticeCode.highLatitudeRuleApplied, Prayer.fajr),
      if ((params.ishaInterval ?? 0) == 0 &&
          params.ishaAngle > 0 &&
          moved(
            Prayer.isha,
            solver.eventAt(-params.ishaAngle, afterTransit: true),
          ))
        const Notice(NoticeCode.highLatitudeRuleApplied, Prayer.isha),
    ];
  }

  /// Umm al-Qura prescribes 120 minutes between Maghrib and Isha in Ramadan.
  static const int _ummAlQuraRamadanIshaMinutes = 120;

  static String _addDays(String localDate, int days) {
    final civil = parseLocalDate(localDate);
    final date = DateTime.utc(civil.year, civil.month, civil.day + days);
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  static adhan.Prayer _adhanPrayer(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return adhan.Prayer.fajr;
      case Prayer.sunrise:
        return adhan.Prayer.sunrise;
      case Prayer.dhuhr:
        return adhan.Prayer.dhuhr;
      case Prayer.asr:
        return adhan.Prayer.asr;
      case Prayer.maghrib:
        return adhan.Prayer.maghrib;
      case Prayer.isha:
        return adhan.Prayer.isha;
    }
  }

  static adhan.CalculationParameters _parametersFor(CalculationMethod method) {
    switch (method) {
      case CalculationMethod.muslimWorldLeague:
        return adhan.CalculationMethodParameters.muslimWorldLeague();
      case CalculationMethod.isna:
        return adhan.CalculationMethodParameters.northAmerica();
      case CalculationMethod.egypt:
        return adhan.CalculationMethodParameters.egyptian();
      case CalculationMethod.ummAlQura:
        return adhan.CalculationMethodParameters.ummAlQura();
      case CalculationMethod.karachi:
        return adhan.CalculationMethodParameters.karachi();
      case CalculationMethod.tehran:
        return adhan.CalculationMethodParameters.tehran();
      case CalculationMethod.jafari:
        return adhan.CalculationMethodParameters.jafari();
      case CalculationMethod.gulf:
        return adhan.CalculationMethodParameters.gulfRegion();
      case CalculationMethod.kuwait:
        return adhan.CalculationMethodParameters.kuwait();
      case CalculationMethod.qatar:
        return adhan.CalculationMethodParameters.qatar();
      case CalculationMethod.singapore:
        return adhan.CalculationMethodParameters.singapore();
      case CalculationMethod.diyanet:
        return adhan.CalculationMethodParameters.turkiye();
      case CalculationMethod.franceUoif:
        return adhan.CalculationMethodParameters.france();
      case CalculationMethod.moonsightingCommittee:
        return adhan.CalculationMethodParameters.moonsightingCommittee();
    }
  }

  static adhan.HighLatitudeRule _mapHighLatitudeRule(HighLatitudeRule rule) {
    switch (rule) {
      case HighLatitudeRule.middleOfNight:
        return adhan.HighLatitudeRule.middleOfTheNight;
      case HighLatitudeRule.seventhOfNight:
        return adhan.HighLatitudeRule.seventhOfTheNight;
      case HighLatitudeRule.angleBased:
        return adhan.HighLatitudeRule.twilightAngle;
    }
  }

  static Map<adhan.Prayer, int> _mapOffsets(Map<Prayer, int> offsets) {
    return {
      adhan.Prayer.fajr: offsets[Prayer.fajr] ?? 0,
      adhan.Prayer.sunrise: offsets[Prayer.sunrise] ?? 0,
      adhan.Prayer.dhuhr: offsets[Prayer.dhuhr] ?? 0,
      adhan.Prayer.asr: offsets[Prayer.asr] ?? 0,
      adhan.Prayer.maghrib: offsets[Prayer.maghrib] ?? 0,
      adhan.Prayer.isha: offsets[Prayer.isha] ?? 0,
    };
  }
}
