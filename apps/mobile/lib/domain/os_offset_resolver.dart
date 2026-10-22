import 'package:prayer_engine/prayer_engine.dart';

/// The operating system's UTC offset at [utc] for the device's own zone.
typedef OsOffsetReader = Duration Function(DateTime utc);

Duration _localOffset(DateTime utc) => utc.toLocal().timeZoneOffset;

/// Offsets from the operating system for the device's zone, bundled data for any
/// other zone (research R-T1).
///
/// The operating system gets government time-zone rule changes by update; the
/// bundled database is only as new as the app build. So when the saved
/// location is in the zone the phone is in, the phone's own rules win. A city
/// chosen while travelling is in another zone, and only bundled data can answer
/// for it.
class OsOffsetResolver implements OffsetResolver {
  /// [deviceZoneId] is the zone the phone is in now, or null when unknown (then
  /// everything uses bundled data). [osOffset] defaults to the platform's local
  /// offset and is replaceable for tests.
  OsOffsetResolver({
    required this.deviceZoneId,
    required this.bundled,
    this.osOffset = _localOffset,
  });

  final String? deviceZoneId;

  /// Offsets from the time-zone data bundled with the app.
  final OffsetResolver bundled;
  final OsOffsetReader osOffset;

  /// Whether [timeZoneId] is answered by the operating system.
  bool usesOsFor(String timeZoneId) =>
      deviceZoneId != null && deviceZoneId == timeZoneId;

  @override
  Duration offsetAt(String timeZoneId, DateTime utcInstant) {
    if (usesOsFor(timeZoneId)) return osOffset(utcInstant.toUtc());
    return bundled.offsetAt(timeZoneId, utcInstant);
  }
}
