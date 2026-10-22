import 'package:deen_mobile/domain/alerts/alert_log_entry.dart';
import 'package:deen_mobile/domain/alerts/planner_plan_builder.dart';
import 'package:deen_mobile/domain/alerts/schedule_plan.dart';
import 'package:deen_mobile/domain/entities/enums.dart';
import 'package:deen_mobile/domain/entities/settings.dart';
import 'package:deen_mobile/platform/alert_scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prayer_engine/prayer_engine.dart';

final _now = DateTime.utc(2026, 10, 22, 6);

PlanRequest _request({
  AlertPlatform platform = AlertPlatform.android,
  AppLanguage language = AppLanguage.en,
  List<AlertPreference>? preferences,
  GlobalAlertSettings global = const GlobalAlertSettings(),
  bool exact = true,
}) {
  return PlanRequest(
    settings: PrayerSettings(
      method: CalculationMethod.ummAlQura,
      asrMethod: AsrMethod.standard,
      highLatitudeRule: HighLatitudeRule.middleOfNight,
      language: language,
    ),
    location: AppLocation(
      source: LocationSource.city,
      latitude: 21.4225,
      longitude: 39.8262,
      displayName: 'Mecca',
      timeZoneId: 'Asia/Riyadh',
      countryCode: 'SA',
      updatedAt: _now,
    ),
    preferences:
        preferences ??
        [for (final p in AlertPrayer.values) AlertPreference(prayer: p)],
    global: global,
    permissions: AlertPermissions(
      platform: platform,
      notificationsGranted: true,
      exactAlarmGranted: exact,
    ),
    now: _now,
  );
}

void main() {
  final offsets = BundledOffsetResolver();
  final builder = PlannerPlanBuilder(
    engine: AdhanDartEngine(offsetResolver: offsets),
    offsets: offsets,
  );

  test('Android: about 60 days of five alerts and a renewal notice', () async {
    final plan = await builder.build(_request());
    expect(plan.alerts.length, inInclusiveRange(290, 302));
    final renewal = plan.alerts.where((a) => a.kind == AlertKind.renewal);
    expect(renewal, hasLength(1));
    expect(plan.runsUntil, isNotNull);
    expect(
      plan.runsUntil!.millisecondsSinceEpoch,
      plan.alerts.map((a) => a.fireAtEpochMs).reduce((a, b) => a > b ? a : b),
    );
    expect(
      plan.records.map((r) => r.alertId),
      plan.alerts.map((a) => a.alertId),
    );
  });

  test('alerts are sorted by time and start in the future', () async {
    final plan = await builder.build(_request());
    final times = plan.alerts.map((a) => a.fireAtEpochMs).toList();
    expect(times, orderedEquals([...times]..sort()));
    expect(times.first, greaterThan(_now.millisecondsSinceEpoch));
  });

  test('text is localized: Arabic title uses the Arabic prayer name', () async {
    final plan = await builder.build(_request(language: AppLanguage.ar));
    final fajr = plan.alerts.firstWhere((a) => a.alertId.startsWith('fajr:'));
    expect(fajr.title, contains('الفجر'));
    expect(fajr.stopLabel, 'إيقاف');
  });

  test('English text names the prayer', () async {
    final plan = await builder.build(_request());
    final asr = plan.alerts.firstWhere((a) => a.alertId.startsWith('asr:'));
    expect(asr.title, 'Asr prayer');
    expect(asr.body, 'It is time for Asr.');
  });

  test('full Azaan carries its recording and loud mode settings', () async {
    final plan = await builder.build(
      _request(
        preferences: [
          const AlertPreference(
            prayer: AlertPrayer.fajr,
            type: AlertType.fullAzaan,
            loudMode: true,
            volumeChoice: VolumeChoice.gentleRamp,
          ),
          for (final p in AlertPrayer.values.skip(1))
            AlertPreference(prayer: p, type: AlertType.off),
        ],
      ),
    );
    final fajr = plan.alerts.firstWhere((a) => a.alertId.startsWith('fajr:'));
    expect(fajr.delivery, DeliveryType.fullAzaan);
    expect(fajr.audioRef, 'voice-1-fajr');
    expect(fajr.loudMode, isTrue);
    expect(fajr.volumeChoice, VolumeChoiceDto.gentleRamp);
  });

  test('Shia wording uses the Shia recording', () async {
    final plan = await builder.build(
      _request(
        preferences: [
          const AlertPreference(
            prayer: AlertPrayer.fajr,
            type: AlertType.fullAzaan,
            variant: AzaanVariant.shia,
            voiceId: 'voice-2',
          ),
          for (final p in AlertPrayer.values.skip(1))
            AlertPreference(prayer: p, type: AlertType.off),
        ],
      ),
    );
    final fajr = plan.alerts.firstWhere((a) => a.alertId.startsWith('fajr:'));
    expect(fajr.audioRef, 'voice-2-shia');
  });

  test(
    'quiet hours are recorded so the detector lists them as silenced',
    () async {
      // Every time of day is inside 00:00 to 23:59, so every alert is silenced.
      final plan = await builder.build(
        _request(
          global: const GlobalAlertSettings(
            quietHours: QuietHours(startMinutes: 0, endMinutes: 1439),
          ),
        ),
      );
      final prayerRecords = plan.records.where(
        (r) => !r.alertId.startsWith('renewal'),
      );
      expect(
        prayerRecords.where((r) => r.cause == AlertCause.quietHours).length,
        greaterThan(250),
      );
      final silenced = plan.alerts.firstWhere(
        (a) => a.alertId.startsWith('asr:'),
      );
      expect(silenced.delivery, DeliveryType.silent);
    },
  );

  test(
    'exact alarms refused: alerts are inexact and recorded as such',
    () async {
      final plan = await builder.build(_request(exact: false));
      expect(plan.alerts.every((a) => !a.preciseAllowed), isTrue);
      expect(
        plan.records.every((r) => r.cause == AlertCause.exactAlarmDenied),
        isTrue,
      );
    },
  );

  test(
    'iOS stays within 63 requests and ends with the renewal notice',
    () async {
      final plan = await builder.build(_request(platform: AlertPlatform.ios));
      expect(plan.alerts.length, lessThanOrEqualTo(63));
      expect(plan.alerts.last.kind, AlertKind.renewal);
    },
  );

  test('a host that cannot schedule plans nothing', () async {
    final plan = await builder.build(
      _request(platform: AlertPlatform.unsupported),
    );
    expect(plan.alerts, isEmpty);
    expect(plan.runsUntil, isNull);
  });

  test(
    'a pre-prayer reminder is its own alert with minutes in the text',
    () async {
      final plan = await builder.build(
        _request(
          preferences: [
            const AlertPreference(
              prayer: AlertPrayer.dhuhr,
              preReminderMinutes: 15,
            ),
            for (final p in AlertPrayer.values.where(
              (p) => p != AlertPrayer.dhuhr,
            ))
              AlertPreference(prayer: p, type: AlertType.off),
          ],
        ),
      );
      final pre = plan.alerts.firstWhere(
        (a) => a.kind == AlertKind.preReminder,
      );
      expect(pre.alertId, startsWith('dhuhr:'));
      expect(pre.title, 'Dhuhr in 15 min');
    },
  );
}
