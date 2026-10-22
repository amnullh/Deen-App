import 'package:deen_mobile/domain/entities/city.dart';
import 'package:deen_mobile/domain/entities/enums.dart';
import 'package:deen_mobile/domain/resolve_timezone.dart';
import 'package:deen_mobile/domain/result.dart';
import 'package:deen_mobile/domain/setup/zone_countries.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prayer_engine/prayer_engine.dart';

class _Zone implements DeviceZoneSource {
  _Zone(this.id);
  final String? id;
  @override
  Future<String?> deviceZoneId() async => id;
}

final _now = DateTime.utc(2026, 10, 21, 8);

void main() {
  group('precise fix', () {
    test(
      'keeps coordinates and takes the device zone and its country',
      () async {
        final result = await resolveGpsLocation(
          reading: const GpsReading(latitude: 24.7136, longitude: 46.6753),
          approximate: false,
          zones: _Zone('Asia/Riyadh'),
          displayName: 'Current location',
          now: _now,
        );
        final location = (result as Ok).value;
        expect(location.source, LocationSource.precise);
        expect(location.latitude, 24.7136);
        expect(location.longitude, 46.6753);
        expect(location.timeZoneId, 'Asia/Riyadh');
        expect(location.countryCode, 'SA');
        expect(location.cityId, isNull);
        expect(location.updatedAt, _now);
      },
    );
  });

  group('approximate', () {
    test('rounds to about 11 km when the user chose approximate', () async {
      final result = await resolveGpsLocation(
        reading: const GpsReading(latitude: 24.7136, longitude: 46.6753),
        approximate: true,
        zones: _Zone('Asia/Riyadh'),
        displayName: 'Approximate location',
        now: _now,
      );
      final location = (result as Ok).value;
      expect(location.source, LocationSource.approximate);
      expect(location.latitude, 24.7);
      expect(location.longitude, 46.7);
    });

    test('is approximate when the system only granted approximate', () async {
      final result = await resolveGpsLocation(
        reading: const GpsReading(
          latitude: 24.7136,
          longitude: 46.6753,
          systemApproximate: true,
        ),
        approximate: false,
        zones: _Zone('Asia/Riyadh'),
        displayName: 'Current location',
        now: _now,
      );
      expect((result as Ok).value.source, LocationSource.approximate);
    });
  });

  group('zone problems', () {
    test('an unknown device zone is an error, never a guess', () async {
      for (final id in [null, '', 'UTC', 'Etc/Unknown']) {
        final result = await resolveGpsLocation(
          reading: const GpsReading(latitude: 1, longitude: 2),
          approximate: false,
          zones: _Zone(id),
          displayName: 'x',
          now: _now,
        );
        expect(result, isA<Err>(), reason: 'zone $id');
        expect(result.errorOrNull!.code, ErrorCode.platform);
      }
    });

    test('a zone with no country uses the fallback country', () async {
      final result = await resolveGpsLocation(
        reading: const GpsReading(latitude: 1, longitude: 2),
        approximate: false,
        zones: _Zone('Pacific/Fakaofo'),
        displayName: 'x',
        fallbackCountry: 'NZ',
        now: _now,
      );
      expect((result as Ok).value.countryCode, 'NZ');
    });

    test(
      'with no country at all a neutral code gives the general default',
      () async {
        final result = await resolveGpsLocation(
          reading: const GpsReading(latitude: 1, longitude: 2),
          approximate: false,
          zones: _Zone('Pacific/Fakaofo'),
          displayName: 'x',
          now: _now,
        );
        final code = (result as Ok).value.countryCode;
        expect(code, unknownCountryCode);
        expect(regionOf(code), Region.other);
      },
    );
  });

  test('a city keeps the zone and country of its record', () {
    const city = CityRecord(
      geonameId: 1275339,
      name: 'Mumbai',
      latitude: 19.07283,
      longitude: 72.88261,
      countryCode: 'IN',
      timeZoneId: 'Asia/Kolkata',
      population: 12691836,
    );
    final location = locationFromCity(city, _now);
    expect(location.source, LocationSource.city);
    expect(location.cityId, 1275339);
    expect(location.displayName, 'Mumbai');
    expect(location.timeZoneId, 'Asia/Kolkata');
    expect(location.countryCode, 'IN');
  });

  group('zone to country table', () {
    test('knows common zones, including renamed ones', () {
      expect(countryForTimeZone('Asia/Kolkata'), 'IN');
      expect(countryForTimeZone('Asia/Calcutta'), 'IN');
      expect(countryForTimeZone('Europe/London'), 'GB');
      expect(countryForTimeZone('America/Argentina/Buenos_Aires'), 'AR');
      expect(countryForTimeZone('Asia/Jakarta'), 'ID');
      expect(countryForTimeZone('Nowhere/City'), isNull);
    });

    test('every entry is an upper-case two-letter code', () {
      for (final entry in zoneCountries.entries) {
        expect(entry.value, matches(RegExp(r'^[A-Z]{2}$')), reason: entry.key);
      }
    });

    test('every entry names a zone the bundled data knows', () {
      final resolver = BundledOffsetResolver();
      final unknown = <String>[];
      for (final zone in zoneCountries.keys) {
        try {
          resolver.offsetAt(zone, _now);
        } on ArgumentError {
          unknown.add(zone);
        }
      }
      expect(unknown, isEmpty);
    });
  });
}
