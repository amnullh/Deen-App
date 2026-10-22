import 'package:prayer_engine/prayer_engine.dart';
import 'package:schedule_planner/schedule_planner.dart';
import 'package:test/test.dart';

import 'support/fakes.dart';

void main() {
  final vectors = loadVector('recording_mapping.json');
  final now = DateTime.utc(2026, 10, 21);

  group('recordingId (shared vectors)', () {
    for (final c in vectors['recordings']! as List<Object?>) {
      final json = c! as Map<String, Object?>;
      final voice = json['voiceId']! as String;
      final variant = PlannerAzaanVariant.values.byName(
        json['variant']! as String,
      );
      final prayer = Prayer.values.byName(json['prayer']! as String);
      test('$voice ${variant.name} ${prayer.name}', () {
        expect(
          recordingId(voiceId: voice, variant: variant, prayer: prayer),
          json['expected'],
        );
      });
    }
  });

  group('reminderType (shared vectors)', () {
    for (final c in vectors['reminderTypes']! as List<Object?>) {
      final json = c! as Map<String, Object?>;
      final type = PlannerAlertType.values.byName(
        json['prayerType']! as String,
      );
      test(type.name, () {
        expect(reminderType(type).name, json['expected']);
        expect(standaloneReminderType(type).name, json['expectedStandalone']);
      });
    }
  });

  group('the planner applies the mapping', () {
    List<PlannedAlert> fullAzaanDay(PlannerAzaanVariant variant) => plan(
      buildInput(
        now: now,
        prefs: [
          for (final p in alertPrayers)
            pref(p, type: PlannerAlertType.fullAzaan, variant: variant),
        ],
        budget: const PlatformBudget.android(
          snapshotDays: 1,
          renewalDaysBeforeEnd: 0,
        ),
      ),
    ).where((a) => a.kind == PlannedAlertKind.prayer).toList();

    test('standard wording: Fajr recording at Fajr, standard at the rest', () {
      final alerts = fullAzaanDay(PlannerAzaanVariant.standard);
      expect(alerts.map((a) => a.audioRef), [
        'voice-1-fajr',
        'voice-1-standard',
        'voice-1-standard',
        'voice-1-standard',
        'voice-1-standard',
      ]);
    });

    test('Shia wording: the Shia recording at every prayer', () {
      final alerts = fullAzaanDay(PlannerAzaanVariant.shia);
      expect(alerts.map((a) => a.audioRef).toSet(), {'voice-1-shia'});
      expect(alerts, hasLength(5));
      expect(
        alerts.every((a) => a.variant == PlannerAzaanVariant.shia),
        isTrue,
      );
    });

    test('the chosen voice is used', () {
      final alerts = plan(
        buildInput(
          now: now,
          prefs: [
            pref(
              Prayer.fajr,
              type: PlannerAlertType.fullAzaan,
              voiceId: 'voice-2',
            ),
          ],
          budget: const PlatformBudget.android(
            snapshotDays: 1,
            renewalDaysBeforeEnd: 0,
          ),
        ),
      );
      expect(alerts.single.audioRef, 'voice-2-fajr');
      expect(alerts.single.voiceId, 'voice-2');
    });

    test('a reminder never plays a full Azaan', () {
      final alerts = plan(
        buildInput(
          now: now,
          prefs: [
            for (final p in alertPrayers)
              pref(p, type: PlannerAlertType.fullAzaan, preReminderMinutes: 15),
          ],
          budget: const PlatformBudget.android(
            snapshotDays: 2,
            renewalDaysBeforeEnd: 0,
          ),
        ),
      );
      final reminders = alerts.where(
        (a) => a.kind == PlannedAlertKind.preReminder,
      );
      expect(reminders, hasLength(10));
      for (final r in reminders) {
        expect(r.deliveryType, PlannedDelivery.shortTone);
        expect(r.audioRef, shortToneId);
        expect(r.voiceId, isNull);
        expect(r.reasons, contains(PlannedReason.reminderUsesShortTone));
      }
      final prayers = alerts.where((a) => a.kind == PlannedAlertKind.prayer);
      expect(
        prayers.every((a) => a.deliveryType == PlannedDelivery.fullAzaan),
        isTrue,
      );
    });
  });
}
