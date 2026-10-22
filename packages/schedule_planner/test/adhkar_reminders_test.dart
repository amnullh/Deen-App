import 'package:prayer_engine/prayer_engine.dart';
import 'package:schedule_planner/schedule_planner.dart';
import 'package:test/test.dart';

import 'support/fakes.dart';

final _now = DateTime.utc(2026, 10, 21);

const _oneDay = PlatformBudget.android(
  snapshotDays: 1,
  renewalDaysBeforeEnd: 0,
);

List<PlannedAlert> _adhkar(
  List<PlannerAdhkarReminder> reminders, {
  List<PlannerAlertPreference>? prefs,
  PlannerQuietHours? quiet,
  PlatformBudget budget = _oneDay,
  DateTime? now,
  FakeDayEngine? engine,
}) => plan(
  buildInput(
    now: now ?? _now,
    prefs: prefs ?? allPrayers(),
    global: PlannerGlobalSettings(
      adhkarReminders: reminders,
      quietHours: quiet,
    ),
    budget: budget,
    engine: engine,
  ),
).where((a) => a.kind == PlannedAlertKind.adhkarReminder).toList();

void main() {
  group('morning reminders are anchored to Fajr', () {
    test('fire the offset after Fajr with the morning id', () {
      final alerts = _adhkar([
        const PlannerAdhkarReminder(
          kind: PlannerAdhkarKind.morning,
          anchor: PlannerAdhkarAnchor.fajr,
          offsetMinutes: 30,
        ),
      ]);
      final a = alerts.single;
      expect(a.alertId, 'adhkar-morning:2026-10-21');
      expect(a.fireAt, DateTime.utc(2026, 10, 21, 5, 30));
      expect(a.prayer, Prayer.fajr);
      expect(a.messageKey, 'alert.adhkar.morning');
      expect(a.localDate, '2026-10-21');
    });

    test(
      'follow a moved Fajr (offsets and seasons) because they use its time',
      () {
        final zone = StepOffsetResolver(0);
        final engine = FakeDayEngine(
          zone,
          localTimes: {Prayer.fajr: '04:10', Prayer.dhuhr: '12:00'},
        );
        final alerts = _adhkar([
          const PlannerAdhkarReminder(
            kind: PlannerAdhkarKind.morning,
            anchor: PlannerAdhkarAnchor.fajr,
            offsetMinutes: 15,
          ),
        ], engine: engine);
        expect(alerts.single.fireAt, DateTime.utc(2026, 10, 21, 4, 25));
      },
    );

    test('a negative offset fires before Fajr', () {
      final alerts = _adhkar([
        const PlannerAdhkarReminder(
          kind: PlannerAdhkarKind.morning,
          anchor: PlannerAdhkarAnchor.fajr,
          offsetMinutes: -10,
        ),
      ]);
      expect(alerts.single.fireAt, DateTime.utc(2026, 10, 21, 4, 50));
    });
  });

  group('evening reminders are anchored to Asr or Maghrib', () {
    test('Asr anchor', () {
      final alerts = _adhkar([
        const PlannerAdhkarReminder(
          kind: PlannerAdhkarKind.evening,
          anchor: PlannerAdhkarAnchor.asr,
          offsetMinutes: 20,
        ),
      ]);
      final a = alerts.single;
      expect(a.alertId, 'adhkar-evening:2026-10-21');
      expect(a.fireAt, DateTime.utc(2026, 10, 21, 15, 50));
      expect(a.prayer, Prayer.asr);
      expect(a.messageKey, 'alert.adhkar.evening');
    });

    test('Maghrib anchor', () {
      final alerts = _adhkar([
        const PlannerAdhkarReminder(
          kind: PlannerAdhkarKind.evening,
          anchor: PlannerAdhkarAnchor.maghrib,
          offsetMinutes: 5,
        ),
      ]);
      expect(alerts.single.fireAt, DateTime.utc(2026, 10, 21, 18, 5));
      expect(alerts.single.prayer, Prayer.maghrib);
    });
  });

  group('rules', () {
    const morning = PlannerAdhkarReminder(
      kind: PlannerAdhkarKind.morning,
      anchor: PlannerAdhkarAnchor.fajr,
      offsetMinutes: 30,
    );
    const evening = PlannerAdhkarReminder(
      kind: PlannerAdhkarKind.evening,
      anchor: PlannerAdhkarAnchor.asr,
      offsetMinutes: 20,
    );

    test('both reminders on the same day sort by time', () {
      final alerts = _adhkar([evening, morning]);
      expect(alerts.map((a) => a.alertId), [
        'adhkar-morning:2026-10-21',
        'adhkar-evening:2026-10-21',
      ]);
    });

    test('disabled reminders are not planned', () {
      final alerts = _adhkar([
        const PlannerAdhkarReminder(
          kind: PlannerAdhkarKind.morning,
          anchor: PlannerAdhkarAnchor.fajr,
          offsetMinutes: 30,
          enabled: false,
        ),
      ]);
      expect(alerts, isEmpty);
    });

    test('one per local day across the snapshot', () {
      final alerts = _adhkar(
        [morning],
        budget: const PlatformBudget.android(
          snapshotDays: 4,
          renewalDaysBeforeEnd: 0,
        ),
      );
      expect(alerts.map((a) => a.localDate), [
        '2026-10-21',
        '2026-10-22',
        '2026-10-23',
        '2026-10-24',
      ]);
    });

    test('only reminders after now are planned', () {
      final alerts = _adhkar([morning], now: DateTime.utc(2026, 10, 21, 5, 31));
      expect(alerts, isEmpty);
    });

    test('use the anchor prayer type; a full Azaan becomes a short tone', () {
      final alerts = _adhkar(
        [morning, evening],
        prefs: [
          pref(Prayer.fajr, type: PlannerAlertType.fullAzaan),
          pref(Prayer.asr, type: PlannerAlertType.vibrate),
        ],
      );
      expect(alerts[0].deliveryType, PlannedDelivery.shortTone);
      expect(alerts[0].audioRef, shortToneId);
      expect(alerts[0].reasons, [PlannedReason.reminderUsesShortTone]);
      expect(alerts[1].deliveryType, PlannedDelivery.vibrate);
      expect(alerts[1].reasons, isEmpty);
    });

    test(
      'an anchor prayer set to off still gets a short tone (own opt-in)',
      () {
        final alerts = _adhkar(
          [morning],
          prefs: [pref(Prayer.fajr, type: PlannerAlertType.off)],
        );
        expect(alerts.single.deliveryType, PlannedDelivery.shortTone);
      },
    );

    test('quiet hours silence a reminder unless its anchor ignores them', () {
      const quiet = PlannerQuietHours(startMinutes: 330, endMinutes: 360);
      final silenced = _adhkar([morning], quiet: quiet);
      expect(silenced.single.deliveryType, PlannedDelivery.silent);
      expect(silenced.single.reasons, [PlannedReason.silencedByQuietHours]);
      final ignored = _adhkar(
        [morning],
        quiet: quiet,
        prefs: [pref(Prayer.fajr, ignoreQuietHours: true)],
      );
      expect(ignored.single.deliveryType, PlannedDelivery.shortTone);
    });

    test('an anchor that does not occur skips the reminder', () {
      final engine = FakeDayEngine(
        StepOffsetResolver(0),
        overrides: {
          '2026-10-21': {Prayer.fajr: null},
        },
      );
      final alerts = _adhkar([morning], engine: engine);
      expect(alerts, isEmpty);
    });

    test('exact alarm denied marks adhkar reminders inexact', () {
      final alerts = plan(
        buildInput(
          now: _now,
          global: const PlannerGlobalSettings(adhkarReminders: [morning]),
          budget: _oneDay,
          permissions: const PlannerPermissions(
            exactAlarm: PlannerPermission.denied,
          ),
        ),
      ).where((a) => a.kind == PlannedAlertKind.adhkarReminder);
      expect(a(alerts).preciseAllowed, isFalse);
    });
  });
}

PlannedAlert a(Iterable<PlannedAlert> alerts) => alerts.single;
