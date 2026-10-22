// Qibla bearing and Haram detection (T142).
//
// The bearing is checked against an independent implementation written
// differently (3-D vectors: project the direction to the Kaaba onto the local
// horizontal plane and measure it from north towards east), not the
// spherical-trigonometry formula the production code uses. adhan-js published
// values are used only as a sanity check (tolerance 0.05 degrees; the
// coordinates of the quoted cities may differ slightly from ours).
import 'dart:math' as math;

import 'package:prayer_engine/prayer_engine.dart';
import 'package:test/test.dart';

/// Independent implementation: vector math on the unit sphere.
double _vectorBearing(double latitude, double longitude) {
  List<double> unit(double lat, double lon) {
    final a = lat * math.pi / 180;
    final b = lon * math.pi / 180;
    return [math.cos(a) * math.cos(b), math.cos(a) * math.sin(b), math.sin(a)];
  }

  double dot(List<double> x, List<double> y) =>
      x[0] * y[0] + x[1] * y[1] + x[2] * y[2];

  final here = unit(latitude, longitude);
  final kaaba = unit(kaabaLatitude, kaabaLongitude);
  final a = latitude * math.pi / 180;
  final b = longitude * math.pi / 180;
  final north = [
    -math.sin(a) * math.cos(b),
    -math.sin(a) * math.sin(b),
    math.cos(a),
  ];
  final east = [-math.sin(b), math.cos(b), 0.0];
  final along = dot(kaaba, here);
  final tangent = [for (var i = 0; i < 3; i++) kaaba[i] - along * here[i]];
  final degrees =
      math.atan2(dot(tangent, east), dot(tangent, north)) * 180 / math.pi;
  return (degrees + 360) % 360;
}

/// Smallest difference between two bearings, in degrees.
double _angularGap(double a, double b) {
  final d = (a - b).abs() % 360;
  return d > 180 ? 360 - d : d;
}

const _cities = <(String, double, double)>[
  ('Washington', 38.9072, -77.0369),
  ('New York', 40.7128, -74.006),
  ('London', 51.5074, -0.1278),
  ('Islamabad', 33.7294, 73.0931),
  ('Tokyo', 35.6762, 139.6503),
  ('Sydney', -33.8688, 151.2093),
  ('Jakarta', -6.2088, 106.8456),
  ('Cairo', 30.0444, 31.2357),
  ('Johannesburg', -26.2041, 28.0473),
  ('Reykjavik', 64.1466, -21.9426),
  ('Lima', -12.0464, -77.0428),
  ('Auckland', -36.8485, 174.7633),
];

void main() {
  group('qiblaBearing against an independent vector implementation', () {
    for (final (name, lat, lon) in _cities) {
      test(name, () {
        expect(
          _angularGap(qiblaBearing(lat, lon), _vectorBearing(lat, lon)),
          lessThan(1e-6),
        );
      });
    }

    test('agrees on a dense grid of positions', () {
      for (var lat = -85.0; lat <= 85; lat += 17) {
        for (var lon = -180.0; lon < 180; lon += 20) {
          if (_angularGap(lat, kaabaLatitude) < 1 &&
              _angularGap(lon, kaabaLongitude) < 1) {
            continue;
          }
          expect(
            _angularGap(qiblaBearing(lat, lon), _vectorBearing(lat, lon)),
            lessThan(1e-6),
            reason: '$lat, $lon',
          );
        }
      }
    });
  });

  group('adhan-js published values (sanity check only)', () {
    const published = <(String, double, double, double)>[
      ('Washington', 38.9072, -77.0369, 56.56),
      ('New York', 40.7128, -74.006, 58.4817),
      ('London', 51.5074, -0.1278, 118.987),
      ('Islamabad', 33.7294, 73.0931, 255.882),
      ('Tokyo', 35.6762, 139.6503, 293.021),
    ];
    for (final (name, lat, lon, expected) in published) {
      test('$name is about $expected degrees', () {
        expect(qiblaBearing(lat, lon), closeTo(expected, 0.05));
      });
    }
  });

  group('qiblaBearing properties', () {
    test('is always at least 0 and below 360', () {
      for (var lat = -90.0; lat <= 90; lat += 7.5) {
        for (var lon = -180.0; lon <= 180; lon += 7.5) {
          final b = qiblaBearing(lat, lon);
          expect(b, greaterThanOrEqualTo(0), reason: '$lat, $lon');
          expect(b, lessThan(360), reason: '$lat, $lon');
          expect(b.isFinite, isTrue, reason: '$lat, $lon');
        }
      }
    });

    test('on the Makkah meridian points north from the south and south from the north', () {
      // At the North Pole every direction is south; measured from the 0 meridian
      // the Kaaba lies at 180 - longitude.
      expect(qiblaBearing(90, 0), closeTo(180 - kaabaLongitude, 1e-9));
      expect(qiblaBearing(-30, kaabaLongitude), closeTo(0, 1e-9));
      expect(qiblaBearing(60, kaabaLongitude), closeTo(180, 1e-9));
    });

    test('points east from the west and west from the east on the same latitude band', () {
      expect(qiblaBearing(21.4, -60), inInclusiveRange(45, 135));
      expect(qiblaBearing(21.4, 120), inInclusiveRange(225, 315));
    });

    test('nearby positions give a stable direction', () {
      final a = qiblaBearing(51.5074, -0.1278);
      final b = qiblaBearing(51.5075, -0.1277);
      expect(_angularGap(a, b), lessThan(0.001));
    });

    test('does not return NaN at the Kaaba itself', () {
      final b = qiblaBearing(kaabaLatitude, kaabaLongitude);
      expect(b.isNaN, isFalse);
      expect(b, inInclusiveRange(0, 360));
    });
  });

  group('distanceToKaabaMeters', () {
    test('is zero at the Kaaba', () {
      expect(
        distanceToKaabaMeters(kaabaLatitude, kaabaLongitude),
        closeTo(0, 1e-6),
      );
    });

    test(
      '0.1 degree of latitude is 11119.5 metres on the mean-radius sphere',
      () {
        // 6371008.8 m * 0.1 degrees in radians.
        final expected = 6371008.8 * 0.1 * math.pi / 180;
        expect(
          distanceToKaabaMeters(kaabaLatitude + 0.1, kaabaLongitude),
          closeTo(expected, 0.5),
        );
      },
    );

    test('Makkah to Madinah is about 340 km', () {
      // Madinah, Al-Masjid an-Nabawi: 24.4672 N, 39.6111 E.
      final km = distanceToKaabaMeters(24.4672, 39.6111) / 1000;
      expect(km, inInclusiveRange(335, 345));
    });
  });

  group('isAtHaram', () {
    // 1 degree of latitude on the model sphere, in metres.
    const metresPerDegree = 6371008.8 * math.pi / 180;

    test('is true at the Kaaba', () {
      expect(isAtHaram(kaabaLatitude, kaabaLongitude), isTrue);
    });

    test('is true 400 m away in any direction', () {
      final d = 400 / metresPerDegree;
      expect(isAtHaram(kaabaLatitude + d, kaabaLongitude), isTrue);
      expect(isAtHaram(kaabaLatitude - d, kaabaLongitude), isTrue);
      final dLon = d / math.cos(kaabaLatitude * math.pi / 180);
      expect(isAtHaram(kaabaLatitude, kaabaLongitude + dLon), isTrue);
      expect(isAtHaram(kaabaLatitude, kaabaLongitude - dLon), isTrue);
    });

    test('is false 600 m away', () {
      final d = 600 / metresPerDegree;
      expect(isAtHaram(kaabaLatitude + d, kaabaLongitude), isFalse);
    });

    test('is false in Madinah, Jeddah and London', () {
      expect(isAtHaram(24.4672, 39.6111), isFalse);
      expect(isAtHaram(21.5433, 39.1728), isFalse);
      expect(isAtHaram(51.5074, -0.1278), isFalse);
    });

    test('the radius is 500 metres', () {
      expect(haramRadiusMeters, 500);
      final inside = 499 / metresPerDegree;
      final outside = 501 / metresPerDegree;
      expect(isAtHaram(kaabaLatitude + inside, kaabaLongitude), isTrue);
      expect(isAtHaram(kaabaLatitude + outside, kaabaLongitude), isFalse);
    });
  });
}
