import 'package:prayer_engine/prayer_engine.dart';

/// Civil-time helpers over an [OffsetResolver]. Everything here treats instants
/// as absolute and uses the resolver only to name local dates and clock times.
class LocalClock {
  const LocalClock(this.timeZoneId, this.offsets);

  final String timeZoneId;
  final OffsetResolver offsets;

  DateTime _shifted(DateTime utc) =>
      utc.toUtc().add(offsets.offsetAt(timeZoneId, utc.toUtc()));

  /// The local date (`YYYY-MM-DD`) at [utc].
  String dateOf(DateTime utc) => formatDate(_shifted(utc));

  /// Local minutes after midnight at [utc].
  int minutesOfDay(DateTime utc) {
    final local = _shifted(utc);
    return local.hour * 60 + local.minute;
  }

  /// The UTC instant at which the local clock shows [minutes] after midnight on
  /// [localDate]. In the repeated hour of a clock change it picks the first
  /// occurrence; in a skipped hour it picks the instant using the offset in
  /// force after the change.
  DateTime toUtc(String localDate, int minutes) {
    final d = parseLocalDate(localDate);
    final naive = DateTime.utc(d.year, d.month, d.day, 0, minutes);
    final guess = offsets.offsetAt(timeZoneId, naive);
    final first = naive.subtract(guess);
    final actual = offsets.offsetAt(timeZoneId, first);
    return actual == guess ? first : naive.subtract(actual);
  }
}

/// `YYYY-MM-DD` of a date held in a UTC [DateTime].
String formatDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// [localDate] plus [days] calendar days (negative allowed).
String addDays(String localDate, int days) {
  final d = parseLocalDate(localDate);
  return formatDate(DateTime.utc(d.year, d.month, d.day + days));
}
