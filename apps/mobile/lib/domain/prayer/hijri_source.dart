import 'package:prayer_engine/prayer_engine.dart' as engine;

/// A Hijri calendar date.
class HijriDateInfo {
  const HijriDateInfo({
    required this.year,
    required this.month,
    required this.day,
  });

  final int year;

  /// 1 (Muharram) to 12 (Dhu al-Hijjah).
  final int month;
  final int day;

  @override
  bool operator ==(Object other) =>
      other is HijriDateInfo &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);
}

/// Converts a civil date to the Umm al-Qura Hijri date. Returns null when the
/// date is outside the supported range.
abstract interface class HijriSource {
  HijriDateInfo? convert(String localDate, {int adjustmentDays = 0});
}

/// The Umm al-Qura table of `prayer_engine` (1300 to 1600 AH).
class EngineHijriSource implements HijriSource {
  const EngineHijriSource();

  @override
  HijriDateInfo? convert(String localDate, {int adjustmentDays = 0}) {
    try {
      final date = engine.toHijri(localDate, adjustmentDays: adjustmentDays);
      return HijriDateInfo(year: date.year, month: date.month, day: date.day);
    } on RangeError {
      return null;
    }
  }
}
