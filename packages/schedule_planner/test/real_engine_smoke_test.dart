import 'package:prayer_engine/prayer_engine.dart';
import 'package:schedule_planner/schedule_planner.dart';
import 'package:test/test.dart';

import 'support/fakes.dart';

PlannerInput _input({
  required PlannerLocation location,
  required DateTime now,
  required PlatformBudget budget,
  HighLatitudeRule rule = HighLatitudeRule.middleOfNight,
}) => PlannerInput(
  location: location,
  prayerSettings: PlannerPrayerSettings(
    method: CalculationMethod.muslimWorldLeague,
    highLatitudeRule: rule,
  ),
  alertPreferences: allPrayers(),
  global: const PlannerGlobalSettings(),
  now: now,
  budget: budget,
  offsets: BundledOffsetResolver(),
  engine: AdhanDartEngine(),
);

void main() {
  test('London across the spring DST change: prayer instants are solar, ids stay per local date', () {
    const london = PlannerLocation(
      latitude: 51.5074,
      longitude: -0.1278,
      timeZoneId: 'Europe/London',
      countryCode: 'GB',
    );
    final alerts = plan(
      _input(
        location: london,
        now: DateTime.utc(2026, 3, 27, 23),
        budget: const PlatformBudget.android(
          snapshotDays: 4,
          renewalDaysBeforeEnd: 1,
        ),
      ),
    );
    final dhuhr28 = alerts.singleWhere((a) => a.alertId == 'dhuhr:2026-03-28');
    final dhuhr30 = alerts.singleWhere((a) => a.alertId == 'dhuhr:2026-03-30');

    int utcMinutes(DateTime t) => t.hour * 60 + t.minute;
    final shift = utcMinutes(dhuhr28.fireAt) - utcMinutes(dhuhr30.fireAt);
    // Dhuhr is a solar event: the clock change moves the wall clock, not the instant.
    expect(shift.abs(), lessThanOrEqualTo(3));
    expect(
      alerts.where((a) => a.kind == PlannedAlertKind.prayer),
      hasLength(15),
    );
  });

  test('Tromso in midsummer: missing events are skipped, nothing throws', () {
    const tromso = PlannerLocation(
      latitude: 69.6492,
      longitude: 18.9553,
      timeZoneId: 'Europe/Oslo',
      countryCode: 'NO',
    );
    final alerts = plan(
      _input(
        location: tromso,
        now: DateTime.utc(2026, 6, 20, 22),
        budget: const PlatformBudget.android(
          snapshotDays: 3,
          renewalDaysBeforeEnd: 1,
        ),
      ),
    );
    expect(alerts, isNotEmpty);
    for (var i = 1; i < alerts.length; i++) {
      expect(alerts[i].fireAt.isBefore(alerts[i - 1].fireAt), isFalse);
    }
    expect(alerts.every((a) => a.fireAt.isUtc), isTrue);
  });

  test('iOS with the real engine returns exactly 63 requests', () {
    const makkah = PlannerLocation(
      latitude: 21.4225,
      longitude: 39.8262,
      timeZoneId: 'Asia/Riyadh',
      countryCode: 'SA',
    );
    final alerts = plan(
      _input(
        location: makkah,
        now: DateTime.utc(2026, 10, 21, 3),
        budget: const PlatformBudget.ios(),
      ),
    );
    expect(alerts, hasLength(63));
    expect(alerts.last.kind, PlannedAlertKind.renewal);
  });
}
