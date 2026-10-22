import 'dart:math' as math;

/// Latitude of the Kaaba in degrees north.
const double kaabaLatitude = 21.4225241;

/// Longitude of the Kaaba in degrees east.
const double kaabaLongitude = 39.8261818;

/// Radius within which the app tells the user they are at the Haram, in metres.
const double haramRadiusMeters = 500;

double _rad(double degrees) => degrees * math.pi / 180;

/// The initial great-circle bearing from ([latitude], [longitude]) to the Kaaba,
/// in degrees clockwise from true north, 0 up to (but not including) 360.
double qiblaBearing(double latitude, double longitude) {
  final phi = _rad(latitude);
  final phiK = _rad(kaabaLatitude);
  final deltaLambda = _rad(kaabaLongitude - longitude);
  final y = math.sin(deltaLambda);
  final x =
      math.cos(phi) * math.tan(phiK) - math.sin(phi) * math.cos(deltaLambda);
  final degrees = math.atan2(y, x) * 180 / math.pi;
  return (degrees + 360) % 360;
}

/// Great-circle distance to the Kaaba in metres (haversine, mean Earth radius).
double distanceToKaabaMeters(double latitude, double longitude) {
  const earthRadius = 6371008.8;
  final dPhi = _rad(kaabaLatitude - latitude);
  final dLambda = _rad(kaabaLongitude - longitude);
  final a =
      math.pow(math.sin(dPhi / 2), 2) +
      math.cos(_rad(latitude)) *
          math.cos(_rad(kaabaLatitude)) *
          math.pow(math.sin(dLambda / 2), 2);
  return 2 * earthRadius * math.asin(math.min(1, math.sqrt(a)));
}

/// Whether the position is within [haramRadiusMeters] of the Kaaba.
bool isAtHaram(double latitude, double longitude) =>
    distanceToKaabaMeters(latitude, longitude) <= haramRadiusMeters;
