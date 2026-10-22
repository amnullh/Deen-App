import 'package:deen_mobile/platform/generated/device.g.dart' as device;
import 'package:deen_mobile/platform/location_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// A [device.LocationApi] that answers from fields instead of a channel.
class _FakeApi extends device.LocationApi {
  _FakeApi({
    this.permission = device.LocationPermission.whenInUse,
    this.afterRequest = device.LocationPermission.whenInUse,
    this.result,
    this.throws = false,
  });

  device.LocationPermission permission;
  final device.LocationPermission afterRequest;
  final device.LocationResult? result;
  final bool throws;
  int requested = 0;
  int fixes = 0;
  int settings = 0;

  @override
  Future<device.LocationPermission> getPermission() async => permission;

  @override
  Future<device.LocationPermission> requestWhenInUse() async {
    requested++;
    return permission = afterRequest;
  }

  @override
  Future<device.LocationResult> getCurrentFix(int timeoutSeconds) async {
    fixes++;
    if (throws) throw PlatformException(code: 'boom');
    return result!;
  }

  @override
  Future<void> openLocationSettings() async => settings++;
}

device.LocationFix _fix({bool approximate = false}) => device.LocationFix(
  latitude: 24.7,
  longitude: 46.7,
  timestampEpochMs: 1,
  approximate: approximate,
);

void main() {
  test('returns the fix when permission is already granted', () async {
    final api = _FakeApi(result: device.LocationResult(fix: _fix()));
    final outcome = await PigeonLocationService(api: api).locate();
    expect(outcome, isA<LocationFound>());
    final reading = (outcome as LocationFound).reading;
    expect(reading.latitude, 24.7);
    expect(reading.systemApproximate, isFalse);
    expect(api.requested, 0);
  });

  test('asks once when permission was never asked', () async {
    final api = _FakeApi(
      permission: device.LocationPermission.notDetermined,
      result: device.LocationResult(fix: _fix()),
    );
    final outcome = await PigeonLocationService(api: api).locate();
    expect(outcome, isA<LocationFound>());
    expect(api.requested, 1);
  });

  test('approximate-only permission marks the reading approximate', () async {
    final api = _FakeApi(
      permission: device.LocationPermission.approximateOnly,
      result: device.LocationResult(fix: _fix()),
    );
    final outcome =
        await PigeonLocationService(api: api).locate() as LocationFound;
    expect(outcome.reading.systemApproximate, isTrue);
  });

  test('a fix flagged approximate is approximate', () async {
    final api = _FakeApi(
      result: device.LocationResult(fix: _fix(approximate: true)),
    );
    final outcome =
        await PigeonLocationService(api: api).locate() as LocationFound;
    expect(outcome.reading.systemApproximate, isTrue);
  });

  for (final denied in [
    device.LocationPermission.denied,
    device.LocationPermission.restricted,
  ]) {
    test('$denied is a refusal and no fix is requested', () async {
      final api = _FakeApi(permission: denied);
      final outcome = await PigeonLocationService(api: api).locate();
      expect(
        (outcome as LocationUnavailable).failure,
        LocationFailure.permissionDenied,
      );
      expect(api.fixes, 0);
    });
  }

  test('a refusal at the prompt is a refusal', () async {
    final api = _FakeApi(
      permission: device.LocationPermission.notDetermined,
      afterRequest: device.LocationPermission.denied,
    );
    final outcome = await PigeonLocationService(api: api).locate();
    expect(
      (outcome as LocationUnavailable).failure,
      LocationFailure.permissionDenied,
    );
  });

  test('platform error codes map to failures', () async {
    for (final entry in {
      'timeout': LocationFailure.timeout,
      'permission_denied': LocationFailure.permissionDenied,
      'unavailable': LocationFailure.unavailable,
      'something_else': LocationFailure.unavailable,
      null: LocationFailure.unavailable,
    }.entries) {
      final api = _FakeApi(result: device.LocationResult(errorCode: entry.key));
      final outcome = await PigeonLocationService(api: api).locate();
      expect((outcome as LocationUnavailable).failure, entry.value);
    }
  });

  test('a channel error never escapes', () async {
    final outcome = await PigeonLocationService(api: _FakeApi(throws: true))
        .locate();
    expect(
      (outcome as LocationUnavailable).failure,
      LocationFailure.unavailable,
    );
  });

  test('opens the app settings', () async {
    final api = _FakeApi();
    await PigeonLocationService(api: api).openSettings();
    expect(api.settings, 1);
  });
}
