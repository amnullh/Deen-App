import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Supplies the UTC offset a time zone has at an instant.
///
/// The engine needs it only to decide which solar day a civil date belongs to
/// (relevant near the date line); prayer instants themselves are absolute.
/// The app prefers the operating system's offsets when the location's zone is
/// the device zone, and bundled data otherwise (research R-T1).
abstract interface class OffsetResolver {
  /// The UTC offset of [timeZoneId] at [utcInstant]. Throws
  /// [ArgumentError] for an unknown zone id.
  Duration offsetAt(String timeZoneId, DateTime utcInstant);
}

/// Resolves offsets from the time-zone database bundled with the app.
class BundledOffsetResolver implements OffsetResolver {
  BundledOffsetResolver() {
    if (!_initialised) {
      tzdata.initializeTimeZones();
      _initialised = true;
    }
  }

  static bool _initialised = false;

  @override
  Duration offsetAt(String timeZoneId, DateTime utcInstant) {
    final tz.Location location;
    try {
      location = tz.getLocation(timeZoneId);
    } on tz.LocationNotFoundException {
      throw ArgumentError.value(timeZoneId, 'timeZoneId', 'Unknown time zone');
    }
    final instant = tz.TZDateTime.from(utcInstant.toUtc(), location);
    return instant.timeZoneOffset;
  }
}

/// A fixed offset, for tests and for zones resolved by the platform.
class FixedOffsetResolver implements OffsetResolver {
  const FixedOffsetResolver(this.offset);

  final Duration offset;

  @override
  Duration offsetAt(String timeZoneId, DateTime utcInstant) => offset;
}

/// The whole-day shift between a civil date and the solar day that the
/// calculation uses, for a place at [longitude] whose zone has [offset].
///
/// Civil time is UTC + [offset]; mean solar time is UTC + longitude / 15 hours.
/// Their difference is within about +-3 hours for almost every place, so the
/// shift is 0. Where a zone sits on the far side of the date line (for example
/// Samoa, UTC+13 at longitude -171.8), the difference exceeds 12 hours and the
/// civil date is one day ahead of the solar date.
int solarDayShift(Duration offset, double longitude) {
  final differenceHours = offset.inMinutes / 60 - longitude / 15;
  return (differenceHours / 24).round();
}
