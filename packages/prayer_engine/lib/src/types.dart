/// Calculation methods supported by the app (clarification D1, spec Story 2).
enum CalculationMethod {
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
  moonsightingCommittee,
}

/// Asr juristic method.
enum AsrMethod { standard, hanafi }

/// Rule used when twilight does not occur or is unreliable at high latitudes.
enum HighLatitudeRule { middleOfNight, seventhOfNight, angleBased }

/// The six daily events the app displays and plans alerts for.
enum Prayer { fajr, sunrise, dhuhr, asr, maghrib, isha }

/// Machine-readable reasons attached to a [DayTimes].
enum NoticeCode {
  /// A high-latitude rule changed at least one time for this day.
  highLatitudeRuleApplied,

  /// The sun does not rise or set at this location on this day.
  polarNoEvent,
}

/// A note about how a day's times were produced.
class Notice {
  const Notice(this.code, [this.prayer]);

  final NoticeCode code;
  final Prayer? prayer;

  @override
  bool operator ==(Object other) =>
      other is Notice && other.code == code && other.prayer == prayer;

  @override
  int get hashCode => Object.hash(code, prayer);

  @override
  String toString() => 'Notice($code${prayer == null ? '' : ', $prayer'})';
}

/// Prayer times for one local date.
class DayTimes {
  const DayTimes({
    required this.localDate,
    required this.times,
    this.imsak,
    this.midnight,
    this.lastThirdOfNight,
    this.notices = const [],
  });

  /// `YYYY-MM-DD` in the location's time zone.
  final String localDate;

  /// UTC instants. A value is null when the event does not occur (polar cases).
  final Map<Prayer, DateTime?> times;

  final DateTime? imsak;
  final DateTime? midnight;
  final DateTime? lastThirdOfNight;
  final List<Notice> notices;
}

/// Computes prayer times. Implementations are pure: the same inputs always
/// give the same output and nothing reads the system clock.
abstract interface class PrayerTimeEngine {
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
  });
}

/// Parses `YYYY-MM-DD` and returns its components, or throws [FormatException].
({int year, int month, int day}) parseLocalDate(String localDate) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(localDate);
  if (match == null) {
    throw FormatException('Expected YYYY-MM-DD', localDate);
  }
  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  final check = DateTime.utc(year, month, day);
  if (check.year != year || check.month != month || check.day != day) {
    throw FormatException('Not a real calendar date', localDate);
  }
  return (year: year, month: month, day: day);
}
