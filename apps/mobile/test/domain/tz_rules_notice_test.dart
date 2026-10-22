import 'package:deen_mobile/domain/os_offset_resolver.dart';
import 'package:deen_mobile/domain/tz_rules_notice.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prayer_engine/prayer_engine.dart';

void main() {
  final bundled = BundledOffsetResolver();
  // Just before the 2026 European summer-time change (29 March).
  final now = DateTime.utc(2026, 3, 1);

  OsOffsetResolver os(Duration Function(DateTime) reader, {String? zone}) =>
      OsOffsetResolver(deviceZoneId: zone, bundled: bundled, osOffset: reader);

  test('no notice when the phone agrees with the bundled data', () {
    final resolver = os(
      (utc) => bundled.offsetAt('Europe/Berlin', utc),
      zone: 'Europe/Berlin',
    );
    expect(
      timeZoneRulesDisagree(
        zoneId: 'Europe/Berlin',
        os: resolver,
        bundled: bundled,
        now: now,
      ),
      isFalse,
    );
  });

  test('a rule change the bundled data does not know raises the notice', () {
    // The phone has dropped summer time; the bundled data has not.
    final resolver = os((_) => const Duration(hours: 1), zone: 'Europe/Berlin');
    expect(
      timeZoneRulesDisagree(
        zoneId: 'Europe/Berlin',
        os: resolver,
        bundled: bundled,
        now: now,
      ),
      isTrue,
    );
  });

  test('a change beyond the 60-day look-ahead is not reported', () {
    final resolver = os(
      (utc) => utc.isAfter(DateTime.utc(2026, 8, 1))
          ? const Duration(hours: 5)
          : bundled.offsetAt('Europe/Berlin', utc),
      zone: 'Europe/Berlin',
    );
    expect(
      timeZoneRulesDisagree(
        zoneId: 'Europe/Berlin',
        os: resolver,
        bundled: bundled,
        now: now,
      ),
      isFalse,
    );
  });

  test('a city in another zone has nothing to compare', () {
    final resolver = os((_) => const Duration(hours: 9), zone: 'Asia/Tokyo');
    expect(
      timeZoneRulesDisagree(
        zoneId: 'Europe/Berlin',
        os: resolver,
        bundled: bundled,
        now: now,
      ),
      isFalse,
    );
  });

  test('an unknown device zone never raises the notice', () {
    final resolver = os((_) => const Duration(hours: 9));
    expect(
      timeZoneRulesDisagree(
        zoneId: 'Asia/Tokyo',
        os: resolver,
        bundled: bundled,
        now: now,
      ),
      isFalse,
    );
  });

  group('OsOffsetResolver', () {
    test(
      'answers the device zone from the OS and others from bundled data',
      () {
        final resolver = os(
          (_) => const Duration(hours: 7),
          zone: 'Asia/Bangkok',
        );
        expect(
          resolver.offsetAt('Asia/Bangkok', now),
          const Duration(hours: 7),
        );
        expect(resolver.offsetAt('Asia/Tokyo', now), const Duration(hours: 9));
      },
    );
  });
}
