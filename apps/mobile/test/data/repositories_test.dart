import 'package:deen_mobile/data/db/app_database.dart';
import 'package:deen_mobile/data/repositories/drift_alert_preference_repository.dart';
import 'package:deen_mobile/data/repositories/drift_location_repository.dart';
import 'package:deen_mobile/data/repositories/drift_settings_repository.dart';
import 'package:deen_mobile/domain/entities/enums.dart';
import 'package:deen_mobile/domain/entities/settings.dart';
import 'package:deen_mobile/domain/result.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prayer_engine/prayer_engine.dart';

AppLocation _location({double latitude = 21.4225, double longitude = 39.8262}) {
  return AppLocation(
    source: LocationSource.city,
    latitude: latitude,
    longitude: longitude,
    cityId: 104515,
    displayName: 'Mecca',
    timeZoneId: 'Asia/Riyadh',
    countryCode: 'SA',
    updatedAt: DateTime.utc(2026, 10, 21, 8),
  );
}

PrayerSettings _settings({
  Map<Prayer, int> offsets = const {},
  int hijri = 0,
  int imsak = 10,
  double textScale = 1.0,
}) {
  return PrayerSettings(
    method: CalculationMethod.ummAlQura,
    asrMethod: AsrMethod.standard,
    highLatitudeRule: HighLatitudeRule.middleOfNight,
    language: AppLanguage.en,
    offsetsMinutes: offsets,
    hijriAdjustment: hijri,
    imsakMinutes: imsak,
    textScale: textScale,
  );
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('SettingsRepository', () {
    test('returns null before setup has saved anything', () async {
      expect(await DriftSettingsRepository(db).get(), isNull);
    });

    test('round-trips every field', () async {
      final repo = DriftSettingsRepository(db);
      final saved =
          _settings(
            offsets: {Prayer.fajr: -5, Prayer.isha: 12},
            hijri: -1,
            imsak: 15,
            textScale: 1.3,
          ).copyWith(
            method: CalculationMethod.karachi,
            asrMethod: AsrMethod.hanafi,
            highLatitudeRule: HighLatitudeRule.seventhOfNight,
            language: AppLanguage.ur,
            dismissedSuggestionRegions: {Region.europe, Region.southAsia},
            theme: ThemePreference.dark,
            highContrast: true,
          );
      expect((await repo.save(saved)).isOk, isTrue);

      final loaded = (await repo.get())!;
      expect(loaded.method, CalculationMethod.karachi);
      expect(loaded.asrMethod, AsrMethod.hanafi);
      expect(loaded.highLatitudeRule, HighLatitudeRule.seventhOfNight);
      expect(loaded.language, AppLanguage.ur);
      expect(loaded.offsetsMinutes[Prayer.fajr], -5);
      expect(loaded.offsetsMinutes[Prayer.isha], 12);
      expect(loaded.offsetsMinutes[Prayer.dhuhr] ?? 0, 0);
      expect(loaded.hijriAdjustment, -1);
      expect(loaded.imsakMinutes, 15);
      expect(loaded.dismissedSuggestionRegions, {
        Region.europe,
        Region.southAsia,
      });
      expect(loaded.theme, ThemePreference.dark);
      expect(loaded.textScale, closeTo(1.3, 1e-9));
      expect(loaded.highContrast, isTrue);
    });

    test('overwrites the single row on a second save', () async {
      final repo = DriftSettingsRepository(db);
      await repo.save(_settings());
      await repo.save(_settings().copyWith(method: CalculationMethod.egypt));
      expect((await repo.get())!.method, CalculationMethod.egypt);
    });

    test('rejects offsets outside -60..60 and changes nothing', () async {
      final repo = DriftSettingsRepository(db);
      await repo.save(_settings());
      final result = await repo.save(_settings(offsets: {Prayer.asr: 61}));
      expect(result.errorOrNull?.code, ErrorCode.invalidArgument);
      expect(
        await repo.save(_settings(offsets: {Prayer.asr: -61})),
        isA<Err<void>>(),
      );
      expect((await repo.get())!.offsetsMinutes[Prayer.asr] ?? 0, 0);
    });

    test('accepts the offset boundaries', () async {
      final repo = DriftSettingsRepository(db);
      expect(
        (await repo.save(
          _settings(offsets: {Prayer.asr: 60, Prayer.fajr: -60}),
        )).isOk,
        isTrue,
      );
    });

    test('rejects a Hijri adjustment outside -2..2', () async {
      final repo = DriftSettingsRepository(db);
      expect(await repo.save(_settings(hijri: 3)), isA<Err<void>>());
      expect(await repo.save(_settings(hijri: -3)), isA<Err<void>>());
      expect((await repo.save(_settings(hijri: 2))).isOk, isTrue);
      expect((await repo.save(_settings(hijri: -2))).isOk, isTrue);
    });

    test('rejects an unreasonable Imsak or text scale', () async {
      final repo = DriftSettingsRepository(db);
      expect(await repo.save(_settings(imsak: -1)), isA<Err<void>>());
      expect(await repo.save(_settings(imsak: 121)), isA<Err<void>>());
      expect(await repo.save(_settings(textScale: 0.5)), isA<Err<void>>());
      expect(await repo.save(_settings(textScale: 2.5)), isA<Err<void>>());
    });

    test('watch emits the saved value', () async {
      final repo = DriftSettingsRepository(db);
      final future = repo.watch().firstWhere((s) => s != null);
      await repo.save(_settings());
      expect((await future)!.method, CalculationMethod.ummAlQura);
    });
  });

  group('LocationRepository', () {
    test('round-trips a location', () async {
      final repo = DriftLocationRepository(db);
      expect(await repo.get(), isNull);
      expect((await repo.save(_location())).isOk, isTrue);
      final loaded = (await repo.get())!;
      expect(loaded.displayName, 'Mecca');
      expect(loaded.countryCode, 'SA');
      expect(loaded.cityId, 104515);
      expect(loaded.updatedAt, DateTime.utc(2026, 10, 21, 8));
      expect(loaded.region, Region.arabianPeninsula);
    });

    test('rejects impossible coordinates', () async {
      final repo = DriftLocationRepository(db);
      expect(await repo.save(_location(latitude: 91)), isA<Err<void>>());
      expect(await repo.save(_location(longitude: -181)), isA<Err<void>>());
      expect(await repo.get(), isNull);
    });

    test('upper-cases the country code and clears on request', () async {
      final repo = DriftLocationRepository(db);
      await repo.save(
        AppLocation(
          source: LocationSource.precise,
          latitude: 51.5,
          longitude: -0.12,
          displayName: 'London',
          timeZoneId: 'Europe/London',
          countryCode: 'gb',
          updatedAt: DateTime.utc(2026, 1, 1),
        ),
      );
      expect((await repo.get())!.countryCode, 'GB');
      await repo.clear();
      expect(await repo.get(), isNull);
    });
  });

  group('AlertPreferenceRepository', () {
    test(
      'returns the five prayers with defaults when nothing is saved',
      () async {
        final prefs = await DriftAlertPreferenceRepository(db).getAll();
        expect(prefs.map((p) => p.prayer), AlertPrayer.values);
        for (final pref in prefs) {
          expect(pref.type, AlertType.shortTone);
          expect(pref.loudMode, isFalse);
          expect(pref.preReminderMinutes, isNull);
          expect(pref.ignoreQuietHours, isFalse);
        }
      },
    );

    test('saves and reloads one prayer without touching the others', () async {
      final repo = DriftAlertPreferenceRepository(db);
      final result = await repo.save(
        const AlertPreference(
          prayer: AlertPrayer.fajr,
          type: AlertType.fullAzaan,
          variant: AzaanVariant.shia,
          loudMode: true,
          volumeChoice: VolumeChoice.gentleRamp,
          preReminderMinutes: 15,
          ignoreQuietHours: true,
        ),
      );
      expect(result.isOk, isTrue);
      final prefs = await repo.getAll();
      final fajr = prefs.first;
      expect(fajr.type, AlertType.fullAzaan);
      expect(fajr.variant, AzaanVariant.shia);
      expect(fajr.loudMode, isTrue);
      expect(fajr.volumeChoice, VolumeChoice.gentleRamp);
      expect(fajr.preReminderMinutes, 15);
      expect(fajr.ignoreQuietHours, isTrue);
      expect(prefs[1].type, AlertType.shortTone);
    });

    test('validates the reminder range 5..60', () async {
      final repo = DriftAlertPreferenceRepository(db);
      Future<Result<void>> withReminder(int m) => repo.save(
        AlertPreference(prayer: AlertPrayer.asr, preReminderMinutes: m),
      );
      expect(await withReminder(4), isA<Err<void>>());
      expect(await withReminder(61), isA<Err<void>>());
      expect((await withReminder(5)).isOk, isTrue);
      expect((await withReminder(60)).isOk, isTrue);
    });

    test('clears a reminder', () async {
      final repo = DriftAlertPreferenceRepository(db);
      await repo.save(
        const AlertPreference(prayer: AlertPrayer.isha, preReminderMinutes: 10),
      );
      await repo.save(
        const AlertPreference(
          prayer: AlertPrayer.isha,
          preReminderMinutes: 10,
        ).copyWith(clearPreReminder: true),
      );
      expect((await repo.getAll()).last.preReminderMinutes, isNull);
    });

    test('global settings default and round-trip', () async {
      final repo = DriftAlertPreferenceRepository(db);
      final defaults = await repo.getGlobal();
      expect(defaults.audioOutput, AudioOutput.speaker);
      expect(defaults.quietHours, isNull);
      expect(defaults.setupCompleted, isFalse);
      expect(defaults.exactAlarmState, PermissionState.unknown);

      final saved = defaults.copyWith(
        audioOutput: AudioOutput.bluetooth,
        quietHours: const QuietHours(startMinutes: 22 * 60, endMinutes: 5 * 60),
        suhoorReminderEnabled: true,
        suhoorReminderMinutes: 45,
        exactAlarmState: PermissionState.denied,
        setupCompleted: true,
        clockSample: const ClockSample(
          wallClockMs: 1000,
          monotonicMs: 500,
          bootId: 'boot-1',
        ),
        scheduleRunsUntil: DateTime.utc(2026, 12, 20),
      );
      expect((await repo.saveGlobal(saved)).isOk, isTrue);

      final loaded = await repo.getGlobal();
      expect(loaded.audioOutput, AudioOutput.bluetooth);
      expect(loaded.quietHours!.startMinutes, 22 * 60);
      expect(loaded.quietHours!.endMinutes, 5 * 60);
      expect(loaded.suhoorReminderEnabled, isTrue);
      expect(loaded.suhoorReminderMinutes, 45);
      expect(loaded.exactAlarmState, PermissionState.denied);
      expect(loaded.setupCompleted, isTrue);
      expect(loaded.clockSample!.bootId, 'boot-1');
      expect(loaded.scheduleRunsUntil, DateTime.utc(2026, 12, 20));
    });

    test('rejects invalid quiet hours and suhoor minutes', () async {
      final repo = DriftAlertPreferenceRepository(db);
      final base = await repo.getGlobal();
      expect(
        await repo.saveGlobal(
          base.copyWith(
            quietHours: const QuietHours(startMinutes: -1, endMinutes: 60),
          ),
        ),
        isA<Err<void>>(),
      );
      expect(
        await repo.saveGlobal(
          base.copyWith(
            quietHours: const QuietHours(startMinutes: 0, endMinutes: 1440),
          ),
        ),
        isA<Err<void>>(),
      );
      expect(
        await repo.saveGlobal(base.copyWith(suhoorReminderMinutes: 4)),
        isA<Err<void>>(),
      );
    });

    test('clears quiet hours', () async {
      final repo = DriftAlertPreferenceRepository(db);
      final base = await repo.getGlobal();
      await repo.saveGlobal(
        base.copyWith(
          quietHours: const QuietHours(startMinutes: 60, endMinutes: 120),
        ),
      );
      await repo.saveGlobal(
        (await repo.getGlobal()).copyWith(clearQuietHours: true),
      );
      expect((await repo.getGlobal()).quietHours, isNull);
    });
  });

  group('QuietHours.contains', () {
    test('handles a range that crosses midnight', () {
      const q = QuietHours(startMinutes: 22 * 60, endMinutes: 5 * 60);
      expect(q.contains(23 * 60), isTrue);
      expect(q.contains(2 * 60), isTrue);
      expect(q.contains(5 * 60), isFalse);
      expect(q.contains(12 * 60), isFalse);
      expect(q.contains(22 * 60), isTrue);
    });

    test('handles a same-day range and an empty range', () {
      const day = QuietHours(startMinutes: 13 * 60, endMinutes: 15 * 60);
      expect(day.contains(14 * 60), isTrue);
      expect(day.contains(15 * 60), isFalse);
      const empty = QuietHours(startMinutes: 100, endMinutes: 100);
      expect(empty.contains(100), isFalse);
    });
  });
}
