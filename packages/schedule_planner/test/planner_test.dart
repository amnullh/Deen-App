import 'package:prayer_engine/prayer_engine.dart';
import 'package:schedule_planner/schedule_planner.dart';
import 'package:test/test.dart';

import 'support/expect_alert.dart';
import 'support/fakes.dart';

final _now = DateTime.utc(2026, 10, 21);

List<PlannedAlert> _only(List<PlannedAlert> alerts, PlannedAlertKind kind) =>
    alerts.where((a) => a.kind == kind).toList();

PlannedAlert _byId(List<PlannedAlert> alerts, String id) =>
    alerts.singleWhere((a) => a.alertId == id);

void _runPlanningVectors(String file) {
  final vectors = loadVector(file);
  for (final c in vectors['cases']! as List<Object?>) {
    final json = c! as Map<String, Object?>;
    test('${json['name']}', () {
      final alerts = plan(
        inputFromVector(json['input']! as Map<String, Object?>),
      );
      final expected = json['expected'] as Map<String, Object?>?;
      if (expected != null) {
        final items = expected['alerts']! as List<Object?>;
        expect(alerts, hasLength(items.length), reason: alerts.toString());
        for (var i = 0; i < items.length; i++) {
          expectAlertMatches(alerts[i], items[i]! as Map<String, Object?>);
        }
        return;
      }
      final summary = json['expectedSummary']! as Map<String, Object?>;
      expect(alerts, hasLength(summary['count']! as int));
      final counts = <String, int>{};
      for (final a in alerts) {
        counts.update(a.kind.name, (n) => n + 1, ifAbsent: () => 1);
      }
      expect(counts, summary['kindCounts']);
      expectAlertMatches(
        alerts.first,
        summary['first']! as Map<String, Object?>,
      );
      expectAlertMatches(alerts.last, summary['last']! as Map<String, Object?>);
      final renewal = _only(alerts, PlannedAlertKind.renewal).single;
      expectAlertMatches(renewal, summary['renewal']! as Map<String, Object?>);
    });
  }
}

void main() {
  group('shared vectors', () {
    group('android 60-day snapshot', () {
      _runPlanningVectors('planning_android_60day.json');
    });
    group('ios 63-request budget', () {
      _runPlanningVectors('planning_ios_budget.json');
    });
    group('DST and time-zone changes', () {
      _runPlanningVectors('planning_dst.json');
    });
  });

  group('basics', () {
    test('only alerts after now, sorted by fireAt, with index priority', () {
      final alerts = plan(buildInput(now: DateTime.utc(2026, 10, 21, 13)));
      expect(alerts.first.alertId, 'asr:2026-10-21');
      for (var i = 0; i < alerts.length; i++) {
        expect(
          alerts[i].fireAt.isAfter(DateTime.utc(2026, 10, 21, 13)),
          isTrue,
        );
        expect(alerts[i].priority, i);
        if (i > 0) {
          expect(alerts[i].fireAt.isBefore(alerts[i - 1].fireAt), isFalse);
        }
      }
    });

    test('an alert exactly at now is not returned', () {
      final alerts = plan(buildInput(now: DateTime.utc(2026, 10, 21, 12)));
      expect(alerts.first.alertId, 'asr:2026-10-21');
    });

    test('is deterministic: the same input gives equal output', () {
      final a = plan(buildInput(now: _now));
      final b = plan(buildInput(now: _now));
      expect(a, b);
    });

    test('stable ids: a later rebuild keeps the ids of the same prayers', () {
      final early = plan(buildInput(now: _now));
      final later = plan(buildInput(now: DateTime.utc(2026, 10, 21, 11)));
      final laterIds = later.map((a) => a.alertId).toSet();
      final shared = early.where((a) => laterIds.contains(a.alertId));
      for (final a in shared) {
        expect(_byId(later, a.alertId).fireAt, a.fireAt);
      }
      expect(later.map((a) => a.alertId).toSet().length, later.length);
    });

    test('ids follow the data-model format', () {
      final alerts = plan(
        buildInput(now: _now, prefs: allPrayers(preReminderMinutes: 10)),
      );
      expect(alerts.take(4).map((a) => a.alertId), [
        'fajr:2026-10-21:pre',
        'fajr:2026-10-21',
        'dhuhr:2026-10-21:pre',
        'dhuhr:2026-10-21',
      ]);
    });

    test('prayer alerts carry kind, prayer, date and message key', () {
      final a = plan(buildInput(now: _now)).first;
      expect(a.kind, PlannedAlertKind.prayer);
      expect(a.prayer, Prayer.fajr);
      expect(a.localDate, '2026-10-21');
      expect(a.messageKey, 'alert.prayer.fajr');
      expect(a.fireAt, DateTime.utc(2026, 10, 21, 5));
      expect(a.fireAt.isUtc, isTrue);
    });

    test('prayers set to off, missing prayers and sunrise give no alerts', () {
      final alerts = plan(
        buildInput(
          now: _now,
          prefs: [
            pref(Prayer.fajr, type: PlannerAlertType.off),
            pref(Prayer.sunrise),
            pref(Prayer.asr),
          ],
        ),
      );
      final ids = alerts
          .where((a) => a.kind == PlannedAlertKind.prayer)
          .map((a) => a.prayer);
      expect(ids.toSet(), {Prayer.asr});
    });

    test('nothing to plan gives an empty list (no lone renewal)', () {
      final alerts = plan(
        buildInput(
          now: _now,
          prefs: [pref(Prayer.fajr, type: PlannerAlertType.off)],
          budget: const PlatformBudget.android(),
        ),
      );
      expect(alerts, isEmpty);
      final ios = plan(
        buildInput(now: _now, prefs: [], budget: const PlatformBudget.ios()),
      );
      expect(ios, isEmpty);
    });

    test('JSON round trip keeps every field', () {
      final alerts = plan(
        buildInput(
          now: _now,
          prefs: [
            pref(
              Prayer.fajr,
              type: PlannerAlertType.fullAzaan,
              variant: PlannerAzaanVariant.shia,
              loudMode: true,
              volumeChoice: PlannerVolumeChoice.gentleRamp,
              preReminderMinutes: 15,
            ),
          ],
          permissions: const PlannerPermissions(
            exactAlarm: PlannerPermission.denied,
          ),
        ),
      );
      expect(alerts, isNotEmpty);
      for (final a in alerts) {
        expect(PlannedAlert.fromJson(a.toJson()), a);
      }
    });
  });

  group('android budget', () {
    test('plans snapshotDays local days and a renewal at 09:00 local', () {
      final zone = StepOffsetResolver(180);
      final alerts = plan(
        buildInput(
          now: _now,
          zone: zone,
          prefs: [pref(Prayer.fajr)],
          budget: const PlatformBudget.android(
            snapshotDays: 10,
            renewalDaysBeforeEnd: 3,
          ),
        ),
      );
      final prayers = _only(alerts, PlannedAlertKind.prayer);
      expect(prayers, hasLength(10));
      // Today in UTC+3 is still 2026-10-21 (03:00 local); fajr 05:00 local.
      expect(prayers.first.alertId, 'fajr:2026-10-21');
      expect(prayers.first.fireAt, DateTime.utc(2026, 10, 21, 2));
      expect(prayers.last.alertId, 'fajr:2026-10-30');
      final renewal = _only(alerts, PlannedAlertKind.renewal).single;
      expect(renewal.alertId, 'renewal:2026-10-28');
      expect(renewal.fireAt, DateTime.utc(2026, 10, 28, 6));
      expect(renewal.deliveryType, PlannedDelivery.renewal);
      expect(renewal.audioRef, isNull);
      expect(renewal.messageKey, 'alert.renewal');
      expect(renewal.prayer, isNull);
    });

    test('the renewal is skipped if its time has already passed', () {
      final alerts = plan(
        buildInput(
          now: DateTime.utc(2026, 10, 21, 10),
          prefs: [pref(Prayer.dhuhr)],
          budget: const PlatformBudget.android(
            snapshotDays: 5,
            renewalDaysBeforeEnd: 5,
          ),
        ),
      );
      expect(_only(alerts, PlannedAlertKind.renewal), isEmpty);
    });

    test('renewal sorts into the list by time', () {
      final alerts = plan(
        buildInput(
          now: _now,
          prefs: [pref(Prayer.fajr)],
          budget: const PlatformBudget.android(
            snapshotDays: 5,
            renewalDaysBeforeEnd: 2,
          ),
        ),
      );
      // renewal on d0+3 = 2026-10-24 09:00Z, after fajr of the 24th.
      expect(alerts.map((a) => a.alertId).toList(), [
        'fajr:2026-10-21',
        'fajr:2026-10-22',
        'fajr:2026-10-23',
        'fajr:2026-10-24',
        'renewal:2026-10-24',
        'fajr:2026-10-25',
      ]);
    });
  });

  group('ios budget', () {
    test('nearest first with reminders: 62 alerts then the renewal', () {
      final alerts = plan(
        buildInput(
          now: _now,
          prefs: allPrayers(preReminderMinutes: 10),
          budget: const PlatformBudget.ios(),
        ),
      );
      expect(alerts, hasLength(63));
      // 10 alerts a day: 6 days = 60, then fajr:pre and fajr of 2026-10-27.
      expect(alerts[61].alertId, 'fajr:2026-10-27');
      expect(alerts.last.alertId, 'renewal:2026-10-27');
      expect(alerts.last.fireAt, DateTime.utc(2026, 10, 27, 5, 1));
      expect(alerts.last.priority, 62);
      expect(
        alerts.map((a) => a.fireAt).toList(),
        orderedEquals([...alerts.map((a) => a.fireAt)]..sort()),
      );
    });

    test('a smaller maxRequests keeps maxRequests - 1 alerts', () {
      final alerts = plan(
        buildInput(now: _now, budget: const PlatformBudget.ios(maxRequests: 6)),
      );
      expect(alerts.map((a) => a.alertId), [
        'fajr:2026-10-21',
        'dhuhr:2026-10-21',
        'asr:2026-10-21',
        'maghrib:2026-10-21',
        'isha:2026-10-21',
        'renewal:2026-10-21',
      ]);
    });

    test('fewer alerts than the budget are all kept, plus the renewal', () {
      final engine = FakeDayEngine(StepOffsetResolver(0));
      final alerts = plan(
        buildInput(
          now: _now,
          prefs: [pref(Prayer.isha)],
          budget: const PlatformBudget.ios(),
          engine: engine,
        ),
      );
      final prayers = _only(alerts, PlannedAlertKind.prayer);
      expect(prayers, hasLength(62));
      expect(alerts, hasLength(63));
      expect(alerts.last.alertId, 'renewal:${prayers.last.localDate}');
    });

    test('begins from now: past alerts of today do not use budget', () {
      final alerts = plan(
        buildInput(
          now: DateTime.utc(2026, 10, 21, 16),
          budget: const PlatformBudget.ios(maxRequests: 4),
        ),
      );
      expect(alerts.map((a) => a.alertId), [
        'maghrib:2026-10-21',
        'isha:2026-10-21',
        'fajr:2026-10-22',
        'renewal:2026-10-22',
      ]);
    });
  });

  group('quiet hours', () {
    const night = PlannerQuietHours(startMinutes: 1320, endMinutes: 300);
    PlannerGlobalSettings quiet(PlannerQuietHours q) =>
        PlannerGlobalSettings(quietHours: q);

    List<PlannedAlert> run({
      required List<PlannerAlertPreference> prefs,
      PlannerGlobalSettings? global,
      StepOffsetResolver? zone,
      FakeDayEngine? engine,
    }) => plan(
      buildInput(
        now: _now,
        prefs: prefs,
        global: global ?? quiet(night),
        zone: zone,
        engine: engine,
        budget: const PlatformBudget.android(
          snapshotDays: 1,
          renewalDaysBeforeEnd: 0,
        ),
      ),
    ).where((a) => a.kind != PlannedAlertKind.renewal).toList();

    test('audible alerts inside quiet hours are silenced with a reason', () {
      // Fajr at 04:00 and Isha at 22:30 are both inside 22:00-05:00.
      final engine = FakeDayEngine(
        StepOffsetResolver(0),
        localTimes: {Prayer.fajr: '04:00', Prayer.isha: '22:30'},
      );
      final alerts = run(
        prefs: [
          pref(Prayer.fajr, type: PlannerAlertType.fullAzaan),
          pref(Prayer.isha, type: PlannerAlertType.shortTone),
        ],
        engine: engine,
      );
      for (final a in alerts) {
        expect(a.deliveryType, PlannedDelivery.silent, reason: a.alertId);
        expect(a.reasons, [PlannedReason.silencedByQuietHours]);
        expect(a.audioRef, isNull);
        expect(a.voiceId, isNull);
      }
    });

    test('ignoreQuietHours keeps the audible type', () {
      final engine = FakeDayEngine(
        StepOffsetResolver(0),
        localTimes: {Prayer.fajr: '04:00'},
      );
      final alerts = run(
        prefs: [
          pref(
            Prayer.fajr,
            type: PlannerAlertType.fullAzaan,
            ignoreQuietHours: true,
          ),
        ],
        engine: engine,
      );
      expect(alerts.single.deliveryType, PlannedDelivery.fullAzaan);
      expect(alerts.single.reasons, isEmpty);
    });

    test('silent and vibrate are not changed by quiet hours', () {
      final engine = FakeDayEngine(
        StepOffsetResolver(0),
        localTimes: {Prayer.fajr: '04:00', Prayer.isha: '23:00'},
      );
      final alerts = run(
        prefs: [
          pref(Prayer.fajr, type: PlannerAlertType.vibrate),
          pref(Prayer.isha, type: PlannerAlertType.silent),
        ],
        engine: engine,
      );
      expect(alerts.map((a) => a.deliveryType), [
        PlannedDelivery.vibrate,
        PlannedDelivery.silent,
      ]);
      expect(alerts.every((a) => a.reasons.isEmpty), isTrue);
    });

    test('start is inclusive and end is exclusive', () {
      final engine = FakeDayEngine(
        StepOffsetResolver(0),
        localTimes: {Prayer.fajr: '05:00', Prayer.isha: '22:00'},
      );
      final alerts = run(
        prefs: [pref(Prayer.fajr), pref(Prayer.isha)],
        engine: engine,
      );
      expect(
        _byId(alerts, 'fajr:2026-10-21').deliveryType,
        PlannedDelivery.shortTone,
      );
      expect(
        _byId(alerts, 'isha:2026-10-21').deliveryType,
        PlannedDelivery.silent,
      );
    });

    test('a range that does not cross midnight', () {
      final engine = FakeDayEngine(StepOffsetResolver(0));
      final alerts = run(
        prefs: [pref(Prayer.dhuhr), pref(Prayer.asr)],
        global: quiet(
          const PlannerQuietHours(startMinutes: 690, endMinutes: 840),
        ),
        engine: engine,
      );
      expect(
        _byId(alerts, 'dhuhr:2026-10-21').deliveryType,
        PlannedDelivery.silent,
      );
      expect(
        _byId(alerts, 'asr:2026-10-21').deliveryType,
        PlannedDelivery.shortTone,
      );
    });

    test('evaluated in the location zone, not UTC', () {
      // UTC+3: dhuhr is 12:00 local (09:00Z). Quiet hours 11:30-12:30 are local
      // clock time, so dhuhr is silenced although 09:00Z is outside them.
      final zone = StepOffsetResolver(180);
      final alerts = run(
        prefs: [pref(Prayer.dhuhr), pref(Prayer.asr)],
        global: quiet(
          const PlannerQuietHours(startMinutes: 690, endMinutes: 750),
        ),
        zone: zone,
      );
      expect(
        _byId(alerts, 'dhuhr:2026-10-21').deliveryType,
        PlannedDelivery.silent,
      );
      expect(
        _byId(alerts, 'asr:2026-10-21').deliveryType,
        PlannedDelivery.shortTone,
      );
    });

    test('equal start and end means no quiet hours', () {
      final alerts = run(
        prefs: [pref(Prayer.dhuhr)],
        global: quiet(
          const PlannerQuietHours(startMinutes: 720, endMinutes: 720),
        ),
      );
      expect(alerts.single.deliveryType, PlannedDelivery.shortTone);
    });

    test('a pre-reminder follows its own time and its prayer ignore flag', () {
      // Quiet range 04:00-05:00: Fajr at 05:00 is outside (end exclusive),
      // its reminder at 04:45 is inside.
      final alerts = plan(
        buildInput(
          now: _now,
          prefs: [
            pref(Prayer.fajr, preReminderMinutes: 15),
            pref(Prayer.dhuhr, preReminderMinutes: 600, ignoreQuietHours: true),
          ],
          global: quiet(
            const PlannerQuietHours(startMinutes: 240, endMinutes: 300),
          ),
          budget: const PlatformBudget.android(
            snapshotDays: 1,
            renewalDaysBeforeEnd: 0,
          ),
        ),
      );
      final fajrPre = _byId(alerts, 'fajr:2026-10-21:pre');
      expect(fajrPre.fireAt, DateTime.utc(2026, 10, 21, 4, 45));
      expect(fajrPre.deliveryType, PlannedDelivery.silent);
      expect(fajrPre.reasons, [PlannedReason.silencedByQuietHours]);
      expect(
        _byId(alerts, 'fajr:2026-10-21').deliveryType,
        PlannedDelivery.shortTone,
      );
      // dhuhr pre-reminder 600 minutes before 12:00 = 02:00, inside, ignored.
      expect(
        _byId(alerts, 'dhuhr:2026-10-21:pre').deliveryType,
        PlannedDelivery.shortTone,
      );
    });

    test('loud mode is dropped when the alert is silenced', () {
      final engine = FakeDayEngine(
        StepOffsetResolver(0),
        localTimes: {Prayer.fajr: '04:00'},
      );
      final alerts = run(
        prefs: [
          pref(Prayer.fajr, type: PlannerAlertType.shortTone, loudMode: true),
        ],
        engine: engine,
      );
      expect(alerts.single.loudMode, isFalse);
    });
  });

  group('permissions', () {
    PlannerInput withPermissions(
      PlannerPermissions p, {
      PlatformBudget budget = const PlatformBudget.android(
        snapshotDays: 3,
        renewalDaysBeforeEnd: 1,
      ),
    }) => buildInput(now: _now, permissions: p, budget: budget);

    test(
      'exact alarm denied on Android: preciseAllowed false with a reason',
      () {
        final alerts = plan(
          withPermissions(
            const PlannerPermissions(exactAlarm: PlannerPermission.denied),
          ),
        );
        expect(alerts, isNotEmpty);
        for (final a in alerts) {
          expect(a.preciseAllowed, isFalse, reason: a.alertId);
          expect(a.reasons, contains(PlannedReason.inexactAlarm));
        }
      },
    );

    test('exact alarm granted or unknown: precise', () {
      for (final state in [
        PlannerPermission.granted,
        PlannerPermission.unknown,
      ]) {
        final alerts = plan(
          withPermissions(PlannerPermissions(exactAlarm: state)),
        );
        expect(alerts.every((a) => a.preciseAllowed), isTrue);
        expect(alerts.every((a) => a.reasons.isEmpty), isTrue);
      }
    });

    test('exact alarm state does not matter on iOS', () {
      final alerts = plan(
        withPermissions(
          const PlannerPermissions(exactAlarm: PlannerPermission.denied),
          budget: const PlatformBudget.ios(maxRequests: 10),
        ),
      );
      expect(alerts.every((a) => a.preciseAllowed), isTrue);
      expect(alerts.every((a) => a.reasons.isEmpty), isTrue);
    });

    test('notifications denied: alerts are still planned and marked', () {
      final granted = plan(withPermissions(const PlannerPermissions()));
      final denied = plan(
        withPermissions(
          const PlannerPermissions(notifications: PlannerPermission.denied),
        ),
      );
      expect(denied.map((a) => a.alertId), granted.map((a) => a.alertId));
      for (final a in denied) {
        expect(a.reasons, contains(PlannedReason.notificationsDenied));
        expect(a.preciseAllowed, isTrue);
      }
    });

    test('both denied lists reasons in enum order', () {
      final alerts = plan(
        withPermissions(
          const PlannerPermissions(
            exactAlarm: PlannerPermission.denied,
            notifications: PlannerPermission.denied,
          ),
        ),
      );
      expect(alerts.first.reasons, [
        PlannedReason.inexactAlarm,
        PlannedReason.notificationsDenied,
      ]);
    });
  });

  group('pre-prayer reminders', () {
    test('fire the requested minutes before the prayer', () {
      final alerts = plan(
        buildInput(
          now: _now,
          prefs: [pref(Prayer.maghrib, preReminderMinutes: 20)],
          budget: const PlatformBudget.android(
            snapshotDays: 1,
            renewalDaysBeforeEnd: 0,
          ),
        ),
      );
      final pre = _byId(alerts, 'maghrib:2026-10-21:pre');
      expect(pre.kind, PlannedAlertKind.preReminder);
      expect(pre.fireAt, DateTime.utc(2026, 10, 21, 17, 40));
      expect(pre.leadMinutes, 20);
      expect(pre.prayer, Prayer.maghrib);
      expect(pre.messageKey, 'alert.preReminder.maghrib');
    });

    test('use the prayer type; silent and vibrate stay as they are', () {
      final alerts = plan(
        buildInput(
          now: _now,
          prefs: [
            pref(
              Prayer.fajr,
              type: PlannerAlertType.silent,
              preReminderMinutes: 10,
            ),
            pref(
              Prayer.dhuhr,
              type: PlannerAlertType.vibrate,
              preReminderMinutes: 10,
            ),
            pref(
              Prayer.asr,
              type: PlannerAlertType.shortTone,
              preReminderMinutes: 10,
            ),
          ],
          budget: const PlatformBudget.android(
            snapshotDays: 1,
            renewalDaysBeforeEnd: 0,
          ),
        ),
      );
      expect(
        _byId(alerts, 'fajr:2026-10-21:pre').deliveryType,
        PlannedDelivery.silent,
      );
      expect(
        _byId(alerts, 'dhuhr:2026-10-21:pre').deliveryType,
        PlannedDelivery.vibrate,
      );
      final asr = _byId(alerts, 'asr:2026-10-21:pre');
      expect(asr.deliveryType, PlannedDelivery.shortTone);
      expect(asr.audioRef, shortToneId);
      expect(asr.reasons, isEmpty);
    });

    test('a prayer set to off has no reminder either', () {
      final alerts = plan(
        buildInput(
          now: _now,
          prefs: [
            pref(
              Prayer.fajr,
              type: PlannerAlertType.off,
              preReminderMinutes: 10,
            ),
          ],
        ),
      );
      expect(alerts, isEmpty);
    });

    test('a reminder whose time has passed is dropped, the prayer stays', () {
      final alerts = plan(
        buildInput(
          now: DateTime.utc(2026, 10, 21, 11, 50),
          prefs: [pref(Prayer.dhuhr, preReminderMinutes: 30)],
          budget: const PlatformBudget.android(
            snapshotDays: 1,
            renewalDaysBeforeEnd: 0,
          ),
        ),
      );
      expect(alerts.map((a) => a.alertId), ['dhuhr:2026-10-21']);
    });

    test('are computed from the same day times as the prayer', () {
      final engine = FakeDayEngine(StepOffsetResolver(0));
      plan(
        buildInput(
          now: _now,
          prefs: allPrayers(preReminderMinutes: 10),
          engine: engine,
          budget: const PlatformBudget.android(
            snapshotDays: 2,
            renewalDaysBeforeEnd: 0,
          ),
        ),
      );
      // one engine call per local date (d0-1, d0, d0+1), not per alert
      expect(engine.calls, 3);
    });
  });

  group('suhoor', () {
    PlannerGlobalSettings suhoor({bool enabled = true, int minutes = 45}) =>
        PlannerGlobalSettings(
          suhoorReminderEnabled: enabled,
          suhoorReminderMinutes: minutes,
        );

    List<PlannedAlert> run({
      required bool Function(String) isRamadan,
      PlannerGlobalSettings? global,
      List<PlannerAlertPreference>? prefs,
    }) => plan(
      buildInput(
        now: _now,
        prefs: prefs ?? [pref(Prayer.fajr)],
        global: global ?? suhoor(),
        isRamadan: isRamadan,
        budget: const PlatformBudget.android(
          snapshotDays: 3,
          renewalDaysBeforeEnd: 0,
        ),
      ),
    );

    test('only on Ramadan dates, minutes before Fajr', () {
      final alerts = run(
        isRamadan: (d) => d == '2026-10-22' || d == '2026-10-23',
      );
      final suhoors = _only(alerts, PlannedAlertKind.suhoor);
      expect(suhoors.map((a) => a.alertId), [
        'suhoor:2026-10-22',
        'suhoor:2026-10-23',
      ]);
      expect(suhoors.first.fireAt, DateTime.utc(2026, 10, 22, 4, 15));
      expect(suhoors.first.leadMinutes, 45);
      expect(suhoors.first.prayer, Prayer.fajr);
      expect(suhoors.first.messageKey, 'alert.suhoor');
      expect(suhoors.first.deliveryType, PlannedDelivery.shortTone);
    });

    test('nothing when disabled or outside Ramadan', () {
      expect(
        _only(
          run(isRamadan: (_) => true, global: suhoor(enabled: false)),
          PlannedAlertKind.suhoor,
        ),
        isEmpty,
      );
      expect(
        _only(run(isRamadan: (_) => false), PlannedAlertKind.suhoor),
        isEmpty,
      );
    });

    test('a full Azaan at Fajr becomes a short tone for suhoor', () {
      final alerts = run(
        isRamadan: (_) => true,
        prefs: [pref(Prayer.fajr, type: PlannerAlertType.fullAzaan)],
      );
      final s = _only(alerts, PlannedAlertKind.suhoor).first;
      expect(s.deliveryType, PlannedDelivery.shortTone);
      expect(s.reasons, [PlannedReason.reminderUsesShortTone]);
    });

    test(
      'suhoor is its own opt-in: Fajr set to off still gets a short tone',
      () {
        final alerts = run(
          isRamadan: (_) => true,
          prefs: [pref(Prayer.fajr, type: PlannerAlertType.off)],
        );
        expect(_only(alerts, PlannedAlertKind.prayer), isEmpty);
        final s = _only(alerts, PlannedAlertKind.suhoor);
        expect(s, isNotEmpty);
        expect(s.first.deliveryType, PlannedDelivery.shortTone);
      },
    );

    test('quiet hours silence suhoor unless Fajr ignores them', () {
      const q = PlannerGlobalSettings(
        suhoorReminderEnabled: true,
        suhoorReminderMinutes: 60,
        quietHours: PlannerQuietHours(startMinutes: 1320, endMinutes: 300),
      );
      final silenced = run(isRamadan: (_) => true, global: q);
      expect(
        _only(silenced, PlannedAlertKind.suhoor).first.deliveryType,
        PlannedDelivery.silent,
      );
      final ignored = run(
        isRamadan: (_) => true,
        global: q,
        prefs: [pref(Prayer.fajr, ignoreQuietHours: true)],
      );
      expect(
        _only(ignored, PlannedAlertKind.suhoor).first.deliveryType,
        PlannedDelivery.shortTone,
      );
    });

    test('is asked about the Fajr local date', () {
      final asked = <String>[];
      run(
        isRamadan: (d) {
          asked.add(d);
          return false;
        },
      );
      expect(
        asked.toSet(),
        containsAll(['2026-10-21', '2026-10-22', '2026-10-23']),
      );
    });
  });

  group('polar and missing events', () {
    test('events that do not occur are skipped with their reminders', () {
      final zone = StepOffsetResolver(0);
      final engine = FakeDayEngine(
        zone,
        overrides: {
          '2026-10-22': {Prayer.fajr: null, Prayer.isha: null},
        },
      );
      final alerts = plan(
        buildInput(
          now: _now,
          zone: zone,
          engine: engine,
          prefs: allPrayers(preReminderMinutes: 10),
          global: const PlannerGlobalSettings(
            suhoorReminderEnabled: true,
            adhkarReminders: [
              PlannerAdhkarReminder(
                kind: PlannerAdhkarKind.morning,
                anchor: PlannerAdhkarAnchor.fajr,
                offsetMinutes: 20,
              ),
            ],
          ),
          isRamadan: (_) => true,
          budget: const PlatformBudget.android(
            snapshotDays: 3,
            renewalDaysBeforeEnd: 0,
          ),
        ),
      );
      final ids = alerts.map((a) => a.alertId).toSet();
      expect(ids, isNot(contains('fajr:2026-10-22')));
      expect(ids, isNot(contains('fajr:2026-10-22:pre')));
      expect(ids, isNot(contains('suhoor:2026-10-22')));
      expect(ids, isNot(contains('adhkar-morning:2026-10-22')));
      expect(ids, isNot(contains('isha:2026-10-22')));
      expect(
        ids,
        containsAll(['dhuhr:2026-10-22', 'fajr:2026-10-23', 'isha:2026-10-21']),
      );
    });

    test('a whole polar day with no events gives no alerts for that date', () {
      final zone = StepOffsetResolver(0);
      final engine = FakeDayEngine(
        zone,
        overrides: {
          '2026-10-22': {for (final p in Prayer.values) p: null},
        },
      );
      final alerts = plan(
        buildInput(
          now: _now,
          zone: zone,
          engine: engine,
          budget: const PlatformBudget.android(
            snapshotDays: 3,
            renewalDaysBeforeEnd: 0,
          ),
        ),
      );
      expect(alerts.where((a) => a.localDate == '2026-10-22'), isEmpty);
      expect(alerts.where((a) => a.localDate == '2026-10-23'), isNotEmpty);
    });

    test('iOS keeps counting past days with no events', () {
      final zone = StepOffsetResolver(0);
      final engine = FakeDayEngine(
        zone,
        overrides: {
          for (var d = 22; d <= 31; d++)
            '2026-10-$d': {for (final p in Prayer.values) p: null},
        },
      );
      final alerts = plan(
        buildInput(
          now: _now,
          zone: zone,
          engine: engine,
          budget: const PlatformBudget.ios(maxRequests: 10),
        ),
      );
      expect(alerts, hasLength(10));
      expect(alerts.where((a) => a.localDate == '2026-10-21'), hasLength(5));
    });
  });

  group('loud mode and audio', () {
    test(
      'loud mode and volume choice are carried for audible prayer alerts',
      () {
        final alerts = plan(
          buildInput(
            now: _now,
            prefs: [
              pref(
                Prayer.fajr,
                type: PlannerAlertType.fullAzaan,
                loudMode: true,
                volumeChoice: PlannerVolumeChoice.gentleRamp,
                preReminderMinutes: 10,
              ),
            ],
            budget: const PlatformBudget.android(
              snapshotDays: 1,
              renewalDaysBeforeEnd: 0,
            ),
          ),
        );
        final prayer = _byId(alerts, 'fajr:2026-10-21');
        expect(prayer.loudMode, isTrue);
        expect(prayer.volumeChoice, PlannerVolumeChoice.gentleRamp);
        final pre = _byId(alerts, 'fajr:2026-10-21:pre');
        expect(pre.loudMode, isFalse);
      },
    );

    test('silent and vibrate carry no audio', () {
      final alerts = plan(
        buildInput(
          now: _now,
          prefs: [
            pref(Prayer.fajr, type: PlannerAlertType.silent),
            pref(Prayer.dhuhr, type: PlannerAlertType.vibrate),
          ],
          budget: const PlatformBudget.android(
            snapshotDays: 1,
            renewalDaysBeforeEnd: 0,
          ),
        ),
      );
      expect(alerts.every((a) => a.audioRef == null), isTrue);
    });
  });
}
