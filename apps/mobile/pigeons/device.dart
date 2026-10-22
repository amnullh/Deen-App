// Pigeon definition for location, heading and volume keys
// (contracts/platform-device.md). No Google Play Services on Android.
// Regenerate with:  dart run pigeon --input pigeons/device.dart
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/platform/generated/device.g.dart',
    kotlinOut:
        'android/app/src/main/kotlin/org/deenapp/mobile/generated/Device.g.kt',
    kotlinOptions: KotlinOptions(
      package: 'org.deenapp.mobile.generated',
      // Scheduling.g.kt already declares FlutterError in the same package.
      includeErrorClass: false,
    ),
    swiftOut: 'ios/Runner/Device.g.swift',
  ),
)
enum LocationPermission {
  notDetermined,
  denied,
  whenInUse,
  approximateOnly,
  restricted,
}

enum HeadingAccuracy { high, medium, low, unreliable }

class LocationFix {
  LocationFix({
    required this.latitude,
    required this.longitude,
    required this.timestampEpochMs,
    required this.approximate,
    this.accuracyMeters,
  });

  double latitude;
  double longitude;
  double? accuracyMeters;
  int timestampEpochMs;

  /// True when the user granted approximate location only.
  bool approximate;
}

class LocationResult {
  LocationResult({this.fix, this.errorCode});

  LocationFix? fix;

  /// `permission_denied`, `timeout`, `unavailable`.
  String? errorCode;
}

class HeadingSample {
  HeadingSample({
    required this.headingDegrees,
    required this.isTrueNorth,
    required this.accuracy,
    required this.interferenceSuspected,
    required this.needsCalibration,
    this.fieldStrengthMicroTesla,
  });

  /// 0..360, relative to true north when a location is known.
  double headingDegrees;
  bool isTrueNorth;
  HeadingAccuracy accuracy;

  /// Android magnetometer magnitude, if available.
  double? fieldStrengthMicroTesla;
  bool interferenceSuspected;
  bool needsCalibration;
}

@HostApi()
abstract class LocationApi {
  /// Current permission; never prompts.
  LocationPermission getPermission();

  /// One system prompt, shown after the app explained why.
  @async
  LocationPermission requestWhenInUse();

  /// Single fix; falls back to the last known location when the timeout passes.
  @async
  LocationResult getCurrentFix(int timeoutSeconds);

  void openLocationSettings();
}

@HostApi()
abstract class HeadingApi {
  bool isAvailable();

  /// Starts sensors. The location lets the platform apply magnetic declination.
  void start(double latitude, double longitude);

  void stop();
}

/// Heading samples, about ten per second while started.
@EventChannelApi()
abstract class HeadingEvents {
  HeadingSample streamHeadings();
}

/// Android only. Intercepts the volume keys while the Tasbih screen is visible.
@HostApi()
abstract class VolumeKeyApi {
  void setEnabled(bool enabled);
}

@FlutterApi()
abstract class VolumeKeyEvents {
  /// `up` or `down`.
  void onVolumeKey(String direction);
}
