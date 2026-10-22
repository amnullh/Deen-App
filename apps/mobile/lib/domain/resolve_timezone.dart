import 'package:flutter_timezone/flutter_timezone.dart';

import 'entities/city.dart';
import 'entities/enums.dart';
import 'entities/settings.dart';
import 'result.dart';
import 'setup/zone_countries.dart';

/// A position from the device, before it becomes a saved [AppLocation].
class GpsReading {
  const GpsReading({
    required this.latitude,
    required this.longitude,
    this.systemApproximate = false,
  });

  final double latitude;
  final double longitude;

  /// True when the operating system only granted approximate location.
  final bool systemApproximate;
}

/// The device's current IANA time zone.
abstract interface class DeviceZoneSource {
  /// The zone id, for example `Asia/Riyadh`, or null when it cannot be read.
  Future<String?> deviceZoneId();
}

/// Reads the zone through `flutter_timezone`.
class FlutterDeviceZoneSource implements DeviceZoneSource {
  const FlutterDeviceZoneSource();

  @override
  Future<String?> deviceZoneId() async {
    try {
      return (await FlutterTimezone.getLocalTimezone()).identifier;
    } on Object {
      // A missing plugin or an unreadable zone must not break setup; the
      // caller then asks the user for a city.
      return null;
    }
  }
}

/// Zone ids that name "no real place". A device on one of these cannot give a
/// location's civil date, so the user picks a city instead.
bool _isPlaceholderZone(String id) =>
    id.isEmpty || id == 'UTC' || id == 'GMT' || id.startsWith('Etc/');

/// Rounds a coordinate to 0.1 degree (about 11 km), which changes prayer times
/// by well under a minute and keeps the saved position coarse.
double roundToApproximate(double degrees) => (degrees * 10).round() / 10;

/// Builds the saved location for a position from the device.
///
/// The time zone is the device's zone (the offline city list cannot be searched
/// by position, and a person standing somewhere is almost always in the zone
/// their phone shows). When [approximate] is true, or the system only granted
/// approximate location, coordinates are rounded and the source is
/// [LocationSource.approximate].
///
/// Fails with [ErrorCode.platform] when the zone cannot be determined; the app
/// then asks for a city. [fallbackCountry] (for example the device region) is
/// used when the zone is not in the zone-country table.
Future<Result<AppLocation>> resolveGpsLocation({
  required GpsReading reading,
  required bool approximate,
  required DeviceZoneSource zones,
  required String displayName,
  required DateTime now,
  String? fallbackCountry,
}) async {
  final zoneId = await zones.deviceZoneId();
  if (zoneId == null || _isPlaceholderZone(zoneId)) {
    return const Err(
      AppError(
        ErrorCode.platform,
        'The phone did not report a time zone for this position.',
      ),
    );
  }
  final coarse = approximate || reading.systemApproximate;
  return Ok(
    AppLocation(
      source: coarse ? LocationSource.approximate : LocationSource.precise,
      latitude: coarse
          ? roundToApproximate(reading.latitude)
          : reading.latitude,
      longitude: coarse
          ? roundToApproximate(reading.longitude)
          : reading.longitude,
      displayName: displayName,
      timeZoneId: zoneId,
      countryCode:
          countryForTimeZone(zoneId) ?? fallbackCountry ?? unknownCountryCode,
      updatedAt: now,
    ),
  );
}

/// The saved location for a city from the offline list; the zone and country
/// come from the record.
AppLocation locationFromCity(CityRecord city, DateTime now) {
  return AppLocation(
    source: LocationSource.city,
    latitude: city.latitude,
    longitude: city.longitude,
    cityId: city.geonameId,
    displayName: city.name,
    timeZoneId: city.timeZoneId,
    countryCode: city.countryCode,
    updatedAt: now,
  );
}
