import 'package:prayer_engine/prayer_engine.dart';

import '../entities/settings.dart';
import 'hijri_source.dart';
import 'next_prayer.dart';

/// One row of the day's list.
class PrayerEntry {
  const PrayerEntry({
    required this.prayer,
    required this.time,
    required this.isJumuah,
  });

  final Prayer prayer;

  /// UTC instant, or null when the event does not occur (polar day or night).
  final DateTime? time;

  /// True for Dhuhr on a Friday, which is shown as Jumu'ah.
  final bool isJumuah;
}

/// Everything shown for one local date.
class DaySchedule {
  const DaySchedule({
    required this.localDate,
    required this.entries,
    required this.isFriday,
    required this.raw,
    this.hijri,
  });

  /// `YYYY-MM-DD` in the location's zone.
  final String localDate;

  /// The six events in display order.
  final List<PrayerEntry> entries;
  final bool isFriday;
  final DayTimes raw;
  final HijriDateInfo? hijri;

  DateTime? timeOf(Prayer prayer) => raw.times[prayer];
  DateTime? get imsak => raw.imsak;
  DateTime? get midnight => raw.midnight;
  DateTime? get lastThirdOfNight => raw.lastThirdOfNight;
  List<Notice> get notices => raw.notices;
}

/// Turns the engine's output into what the screens show: the six times, the
/// Friday label, the next prayer and day navigation.
///
/// Nothing here reads the system clock; callers pass `now`.
class DayTimesUseCase {
  const DayTimesUseCase({
    required this.engine,
    required this.offsets,
    this.hijri,
  });

  final PrayerTimeEngine engine;
  final OffsetResolver offsets;
  final HijriSource? hijri;

  /// The civil date (`YYYY-MM-DD`) at [instant] in [timeZoneId].
  String localDateOf(DateTime instant, String timeZoneId) {
    final utc = instant.toUtc();
    final local = utc.add(offsets.offsetAt(timeZoneId, utc));
    return _format(local);
  }

  /// [localDate] moved by [days] (negative goes back).
  String shiftDate(String localDate, int days) {
    final parts = parseLocalDate(localDate);
    final shifted = DateTime.utc(
      parts.year,
      parts.month,
      parts.day,
    ).add(Duration(days: days));
    return _format(shifted);
  }

  /// The six events for [localDate] at [location] with [settings] applied.
  DaySchedule scheduleFor({
    required AppLocation location,
    required PrayerSettings settings,
    required String localDate,
  }) {
    final raw = engine.timesFor(
      latitude: location.latitude,
      longitude: location.longitude,
      timeZoneId: location.timeZoneId,
      localDate: localDate,
      method: settings.method,
      asr: settings.asrMethod,
      highLatitudeRule: settings.highLatitudeRule,
      offsetsMinutes: settings.offsetsMinutes,
      imsakMinutes: settings.imsakMinutes,
    );
    final isFriday = this.isFriday(localDate);
    return DaySchedule(
      localDate: localDate,
      isFriday: isFriday,
      raw: raw,
      hijri: hijri?.convert(
        localDate,
        adjustmentDays: settings.hijriAdjustment,
      ),
      entries: [
        for (final prayer in Prayer.values)
          PrayerEntry(
            prayer: prayer,
            time: raw.times[prayer],
            isJumuah: isFriday && prayer == Prayer.dhuhr,
          ),
      ],
    );
  }

  /// The next prayer after [now], looking at the location's today and tomorrow
  /// so that it works across local midnight.
  NextPrayer? nextPrayer({
    required AppLocation location,
    required PrayerSettings settings,
    required DateTime now,
  }) {
    final today = localDateOf(now, location.timeZoneId);
    return findNextPrayer(
      today: scheduleFor(
        location: location,
        settings: settings,
        localDate: today,
      ).raw,
      tomorrow: scheduleFor(
        location: location,
        settings: settings,
        localDate: shiftDate(today, 1),
      ).raw,
      now: now,
    );
  }

  /// Whether the civil date [localDate] is a Friday.
  bool isFriday(String localDate) {
    final parts = parseLocalDate(localDate);
    return DateTime.utc(parts.year, parts.month, parts.day).weekday ==
        DateTime.friday;
  }

  /// The UTC offset of [timeZoneId] at [instant], for formatting local times.
  Duration offsetAt(String timeZoneId, DateTime instant) =>
      offsets.offsetAt(timeZoneId, instant.toUtc());

  static String _format(DateTime date) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${date.year.toString().padLeft(4, '0')}-${two(date.month)}-${two(date.day)}';
  }
}
