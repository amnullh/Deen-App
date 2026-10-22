# Contract: Location and Heading (Pigeon)

**Definitions live in**: `apps/mobile/pigeons/device.dart`. Replaces `geolocator` and `flutter_compass` (see
[research.md](../research.md) section 4). Each platform has one small implementation: Android `LocationManager`
and `SensorManager`, iOS `CLLocationManager`.

## LocationApi

```dart
class LocationFix {
  double latitude; double longitude;
  double? accuracyMeters;
  int timestampEpochMs;
  bool approximate;          // user granted approximate permission only
}

enum LocationPermission { notDetermined, denied, whenInUse, approximateOnly, restricted }
```

| Method | Behavior |
|--------|----------|
| `getPermission()` | Current permission state; never prompts |
| `requestWhenInUse()` | One system prompt after the app explained that location stays on the device |
| `getCurrentFix(timeoutSeconds)` | Single fix; falls back to last known location if the timeout elapses; returns an error code, never throws |
| `openLocationSettings()` | Opens app settings |

Rules:
- Foreground use only. No background or "Always" location permission is requested (plan D-6).
- No Google Play Services APIs. The Android build MUST contain no `com.google.android.gms` dependency (spike S4).
- iOS declares `NSLocationWhenInUseUsageDescription` with plain wording; the app works fully if declined (manual
  city list), as required by App Review 5.1.1(iv) and 5.1.2(i).
- Coordinates are never logged or written anywhere except the local `Location` row.

## HeadingApi

```dart
class HeadingSample {
  double headingDegrees;       // 0..360 relative to true north when a location is known, else magnetic
  bool isTrueNorth;
  HeadingAccuracy accuracy;    // high, medium, low, unreliable
  double? fieldStrengthMicroTesla;   // Android magnetometer magnitude
  bool interferenceSuspected;  // field outside the expected 25..65 microtesla range, or rapid jumps
  bool needsCalibration;       // platform reports low accuracy
}
```

| Method / stream | Behavior |
|-----------------|----------|
| `isAvailable()` | False when the device has no usable compass: UI shows the bearing in degrees with instructions |
| `start(latitude, longitude)` / `stop()` | Starts and stops sensor listening; stopping is mandatory when the screen is not visible (battery) |
| `headings` (event stream) | About 10 samples per second, low-pass filtered |

Rules:
- Android: use the rotation-vector sensor (tilt-compensated) plus sensor accuracy callbacks and the raw
  magnetometer magnitude for interference; apply magnetic declination with the platform geomagnetic model for the
  given location.
- iOS: use `CLHeading` (true heading when location is known) with `headingAccuracy`; set the heading
  orientation to the device orientation. Show the system calibration prompt only when the app decides
  `needsCalibration`.
- The sensors run only while the Qibla screen is visible.
- Device flat versus upright is handled by the platform fusion; a device test covers both (plan testing section).

## Android-only: VolumeKeyApi

| Method / stream | Behavior |
|-----------------|----------|
| `setEnabled(bool)` | Enables interception of volume keys while the Tasbih screen is in the foreground |
| `presses` (event stream) | Emits `up` or `down` and consumes the key so system volume does not change |

Disabled whenever the Tasbih screen is not visible, so system volume is never changed without the user's
opt-in (clarification D7 applies the same principle to audio).

## Battery and settings helpers

Use `android_intent_plus` (BSD-3) for opening OEM and system settings pages; the intents and per-brand
screens are listed in the Reliability screen's content file, written by the project and verified on our
devices.
