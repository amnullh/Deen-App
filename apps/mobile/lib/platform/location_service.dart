import 'package:flutter/services.dart';

import '../domain/resolve_timezone.dart';
import 'generated/device.g.dart' as device;

/// Why a position could not be read.
enum LocationFailure {
  /// The user refused, or the system restricts location for this app.
  permissionDenied,

  /// No fix arrived within the time limit.
  timeout,

  /// Location services are off, or the platform could not answer.
  unavailable,
}

/// The result of asking the phone where it is.
sealed class LocationOutcome {
  const LocationOutcome();
}

class LocationFound extends LocationOutcome {
  const LocationFound(this.reading);

  final GpsReading reading;
}

class LocationUnavailable extends LocationOutcome {
  const LocationUnavailable(this.failure);

  final LocationFailure failure;
}

/// Reads the device position in the foreground only (plan D-6). Coordinates are
/// returned to the caller and never logged here.
abstract interface class LocationService {
  /// Asks for permission if it was never asked, then reads one fix. Never
  /// throws: every problem is a [LocationUnavailable].
  Future<LocationOutcome> locate({int timeoutSeconds = 15});

  /// Opens the app's system settings, the way back after a refusal.
  Future<void> openSettings();
}

/// [LocationService] over the generated Pigeon [device.LocationApi].
class PigeonLocationService implements LocationService {
  PigeonLocationService({device.LocationApi? api})
    : _api = api ?? device.LocationApi();

  final device.LocationApi _api;

  @override
  Future<LocationOutcome> locate({int timeoutSeconds = 15}) async {
    try {
      var permission = await _api.getPermission();
      if (permission == device.LocationPermission.notDetermined) {
        permission = await _api.requestWhenInUse();
      }
      switch (permission) {
        case device.LocationPermission.denied:
        case device.LocationPermission.restricted:
        case device.LocationPermission.notDetermined:
          return const LocationUnavailable(LocationFailure.permissionDenied);
        case device.LocationPermission.whenInUse:
        case device.LocationPermission.approximateOnly:
          break;
      }
      final result = await _api.getCurrentFix(timeoutSeconds);
      final fix = result.fix;
      if (fix != null) {
        return LocationFound(
          GpsReading(
            latitude: fix.latitude,
            longitude: fix.longitude,
            systemApproximate:
                fix.approximate ||
                permission == device.LocationPermission.approximateOnly,
          ),
        );
      }
      return LocationUnavailable(_failureFor(result.errorCode));
    } on PlatformException {
      return const LocationUnavailable(LocationFailure.unavailable);
    } on MissingPluginException {
      return const LocationUnavailable(LocationFailure.unavailable);
    }
  }

  @override
  Future<void> openSettings() async {
    try {
      await _api.openLocationSettings();
    } on PlatformException {
      // Nothing more can be done if settings cannot open.
    } on MissingPluginException {
      // Same as above.
    }
  }

  static LocationFailure _failureFor(String? code) {
    switch (code) {
      case 'permission_denied':
        return LocationFailure.permissionDenied;
      case 'timeout':
        return LocationFailure.timeout;
      default:
        return LocationFailure.unavailable;
    }
  }
}
