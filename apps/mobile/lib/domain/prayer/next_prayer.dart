import 'package:prayer_engine/prayer_engine.dart';

/// The five prayers a countdown can point at. Sunrise is listed on screen but is
/// not a prayer, so it is never "next".
const List<Prayer> countdownPrayers = [
  Prayer.fajr,
  Prayer.dhuhr,
  Prayer.asr,
  Prayer.maghrib,
  Prayer.isha,
];

/// The next prayer after a given instant.
class NextPrayer {
  const NextPrayer({required this.prayer, required this.time});

  final Prayer prayer;

  /// UTC instant the prayer begins.
  final DateTime time;

  // Equality lets a provider holding the next prayer stay quiet on every
  // one-second tick until the answer actually changes.
  @override
  bool operator ==(Object other) =>
      other is NextPrayer && other.prayer == prayer && other.time == time;

  @override
  int get hashCode => Object.hash(prayer, time);

  /// Time left at [now]; never negative.
  Duration remaining(DateTime now) {
    final left = time.difference(now);
    return left.isNegative ? Duration.zero : left;
  }
}

/// The first prayer in [today] or [tomorrow] that begins after [now].
///
/// A prayer that begins exactly at [now] has begun, so the one after it is
/// returned. Events that do not occur (polar days) are skipped. Returns null only
/// when neither day has a prayer left.
NextPrayer? findNextPrayer({
  required DayTimes today,
  required DayTimes tomorrow,
  required DateTime now,
}) {
  for (final day in [today, tomorrow]) {
    for (final prayer in countdownPrayers) {
      final time = day.times[prayer];
      if (time != null && time.isAfter(now)) {
        return NextPrayer(prayer: prayer, time: time);
      }
    }
  }
  return null;
}
