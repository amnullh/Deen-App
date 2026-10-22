import '../types.dart';
import 'umm_al_qura_table.dart';

/// A date in the Umm al-Qura Hijri calendar.
class HijriDate {
  const HijriDate(this.year, this.month, this.day);

  /// Hijri year (anno Hegirae).
  final int year;

  /// 1 (Muharram) to 12 (Dhu al-Hijjah); 9 is Ramadan.
  final int month;

  /// 1 to 30.
  final int day;

  @override
  bool operator ==(Object other) =>
      other is HijriDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() =>
      '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')} AH';
}

/// The largest user adjustment, in days, either way (spec Story 2).
const int maxHijriAdjustmentDays = 2;

/// The Hijri month number of Ramadan.
const int ramadanMonth = 9;

int _epochDay(int year, int month, int day) =>
    DateTime.utc(year, month, day).millisecondsSinceEpoch ~/
    Duration.millisecondsPerDay;

String _formatEpochDay(int epochDay) {
  final date = DateTime.fromMillisecondsSinceEpoch(
    epochDay * Duration.millisecondsPerDay,
    isUtc: true,
  );
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

void _checkAdjustment(int adjustmentDays) {
  if (adjustmentDays.abs() > maxHijriAdjustmentDays) {
    throw ArgumentError.value(
      adjustmentDays,
      'adjustmentDays',
      'Must be between -$maxHijriAdjustmentDays and +$maxHijriAdjustmentDays',
    );
  }
}

void _checkYear(int year) {
  if (year < ummAlQuraFirstYear || year > ummAlQuraLastYear) {
    throw RangeError.range(
      year,
      ummAlQuraFirstYear,
      ummAlQuraLastYear,
      'year',
      'The Umm al-Qura table covers $ummAlQuraFirstYear to '
          '$ummAlQuraLastYear AH',
    );
  }
}

/// The number of days (29 or 30) in [month] of Hijri [year].
///
/// Throws [RangeError] for a year outside 1300 to 1600 AH and [ArgumentError]
/// for a month outside 1 to 12.
int hijriMonthLength(int year, int month) {
  _checkYear(year);
  if (month < 1 || month > 12) {
    throw ArgumentError.value(month, 'month', 'Must be between 1 and 12');
  }
  final mask = ummAlQuraMonthMasks[year - ummAlQuraFirstYear];
  return (mask >> (month - 1)) & 1 == 1 ? 30 : 29;
}

int _yearStart(int year) => ummAlQuraYearStartDays[year - ummAlQuraFirstYear];

int _yearLength(int year) {
  var days = 0;
  for (var month = 1; month <= 12; month++) {
    days += hijriMonthLength(year, month);
  }
  return days;
}

/// Converts the civil date [localDate] (`YYYY-MM-DD`) to the Umm al-Qura Hijri
/// date.
///
/// [adjustmentDays] (-2 to +2) is the user's correction for local moon
/// sighting: +1 gives the Hijri date of the next civil day. The table covers
/// 1 Muharram 1300 AH (1882-11-12) to the last day of 1600 AH (2174-11-25);
/// dates outside it throw a [RangeError]. A malformed date throws a
/// [FormatException].
///
/// The Umm al-Qura calendar is computed in advance; the start of Ramadan,
/// Shawwal and Dhu al-Hijjah in practice follows moon sighting and can differ
/// by a day, which is what [adjustmentDays] is for.
HijriDate toHijri(String localDate, {int adjustmentDays = 0}) {
  _checkAdjustment(adjustmentDays);
  final civil = parseLocalDate(localDate);
  final day = _epochDay(civil.year, civil.month, civil.day) + adjustmentDays;

  final first = _yearStart(ummAlQuraFirstYear);
  final end = _yearStart(ummAlQuraLastYear) + _yearLength(ummAlQuraLastYear);
  if (day < first || day >= end) {
    throw RangeError.value(
      day,
      'localDate',
      'Outside the Umm al-Qura table ($ummAlQuraFirstYear to '
          '$ummAlQuraLastYear AH)',
    );
  }

  // Binary search for the last year that starts on or before [day].
  var low = ummAlQuraFirstYear;
  var high = ummAlQuraLastYear;
  while (low < high) {
    final mid = (low + high + 1) ~/ 2;
    if (_yearStart(mid) <= day) {
      low = mid;
    } else {
      high = mid - 1;
    }
  }

  var remaining = day - _yearStart(low);
  for (var month = 1; month <= 12; month++) {
    final length = hijriMonthLength(low, month);
    if (remaining < length) return HijriDate(low, month, remaining + 1);
    remaining -= length;
  }
  throw StateError('Unreachable: day $day is inside year $low');
}

/// The civil date (`YYYY-MM-DD`) of a Hijri date, the reverse of [toHijri]:
/// `fromHijri(h.year, h.month, h.day, adjustmentDays: a)` returns the date
/// that `toHijri(date, adjustmentDays: a)` maps to `h`.
String fromHijri(int year, int month, int day, {int adjustmentDays = 0}) {
  _checkAdjustment(adjustmentDays);
  final length = hijriMonthLength(year, month);
  if (day < 1 || day > length) {
    throw ArgumentError.value(
      day,
      'day',
      'Month $month of $year AH has $length days',
    );
  }
  var offset = day - 1;
  for (var m = 1; m < month; m++) {
    offset += hijriMonthLength(year, m);
  }
  return _formatEpochDay(_yearStart(year) + offset - adjustmentDays);
}

/// Whether [localDate] falls in Ramadan by the Umm al-Qura calendar (with the
/// user's [adjustmentDays]). Dates outside the table are reported as not
/// Ramadan rather than as an error, so callers can ask about any date.
bool isRamadan(String localDate, {int adjustmentDays = 0}) {
  try {
    return toHijri(localDate, adjustmentDays: adjustmentDays).month ==
        ramadanMonth;
  } on RangeError {
    return false;
  }
}
