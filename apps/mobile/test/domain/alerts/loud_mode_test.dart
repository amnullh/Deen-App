import 'package:deen_mobile/data/db/app_database.dart';
import 'package:deen_mobile/data/repositories/drift_alert_preference_repository.dart';
import 'package:deen_mobile/domain/alerts/planner_plan_builder.dart';
import 'package:deen_mobile/domain/alerts/schedule_plan.dart';
import 'package:deen_mobile/domain/entities/enums.dart';
import 'package:deen_mobile/domain/entities/settings.dart';
import 'package:deen_mobile/platform/alert_scheduler.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prayer_engine/prayer_engine.dart';

PlanRequest _request(List<AlertPreference> preferences) {
  return PlanRequest(
    settings: const PrayerSettings(
      method: CalculationMethod.ummAlQura,
      asrMethod: AsrMethod.standard,
      highLatitudeRule: HighLatitudeRule.middleOfNight,
      language: AppLanguage.en,
    ),
    location: AppLocation(
      source: LocationSource.city,
      latitude: 21.4225,
      longitude: 39.8262,
      displayName: 'Mecca',
      timeZoneId: 'Asia/Riyadh',
      countryCode: 'SA',
      updatedAt: DateTime.utc(2026, 10, 21),
    ),
    preferences: preferences,
    global: const GlobalAlertSettings(),
    permissions: const AlertPermissions(
      platform: AlertPlatform.android,
      notificationsGranted: true,
    ),
    now: DateTime.utc(2026, 10, 22, 6),
  );
}

void main() {
  test('a new preference has loud mode off and keeps the current volume', () {
    const preference = AlertPreference(prayer: AlertPrayer.fajr);
    expect(preference.loudMode, isFalse);
    expect(preference.volumeChoice, VolumeChoice.keepCurrent);
  });

  test('prayers that were never saved come back with loud mode off', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final all = await DriftAlertPreferenceRepository(db).getAll();
    expect(all, hasLength(5));
    expect(all.every((p) => !p.loudMode), isTrue);
    expect(all.every((p) => p.type == AlertType.shortTone), isTrue);
  });

  final offsets = BundledOffsetResolver();
  final builder = PlannerPlanBuilder(
    engine: AdhanDartEngine(offsetResolver: offsets),
    offsets: offsets,
  );

  test(
    'with default preferences no planned alert asks for loud mode',
    () async {
      final plan = await builder.build(
        _request([
          for (final p in AlertPrayer.values) AlertPreference(prayer: p),
        ]),
      );
      expect(plan.alerts, isNotEmpty);
      expect(plan.alerts.every((a) => !a.loudMode), isTrue);
      expect(
        plan.alerts.every((a) => a.volumeChoice == VolumeChoiceDto.keepCurrent),
        isTrue,
      );
    },
  );

  test('loud mode reaches only the prayer that opted in', () async {
    final plan = await builder.build(
      _request([
        const AlertPreference(
          prayer: AlertPrayer.fajr,
          type: AlertType.fullAzaan,
          loudMode: true,
        ),
        for (final p in AlertPrayer.values.skip(1)) AlertPreference(prayer: p),
      ]),
    );
    final loud = plan.alerts.where((a) => a.loudMode);
    expect(loud, isNotEmpty);
    expect(loud.every((a) => a.alertId.startsWith('fajr:')), isTrue);
  });
}
