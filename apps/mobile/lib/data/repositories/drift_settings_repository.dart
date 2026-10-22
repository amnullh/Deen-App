import 'package:drift/drift.dart';
import 'package:prayer_engine/prayer_engine.dart' as engine;

import '../../domain/entities/settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/result.dart';
import '../db/app_database.dart';

class DriftSettingsRepository implements SettingsRepository {
  DriftSettingsRepository(this._db);

  final AppDatabase _db;

  @override
  Future<PrayerSettings?> get() async {
    final row = await _db.select(_db.prayerSettingsTable).getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  @override
  Stream<PrayerSettings?> watch() {
    return _db
        .select(_db.prayerSettingsTable)
        .watchSingleOrNull()
        .map((row) => row == null ? null : _fromRow(row));
  }

  @override
  Future<Result<void>> save(PrayerSettings settings) async {
    final error = _validate(settings);
    if (error != null) return Err(error);
    await _db
        .into(_db.prayerSettingsTable)
        .insertOnConflictUpdate(
          PrayerSettingsTableCompanion.insert(
            id: const Value(1),
            method: settings.method,
            asrMethod: settings.asrMethod,
            highLatitudeRule: settings.highLatitudeRule,
            language: settings.language,
            offsetFajr: Value(settings.offsetsMinutes[engine.Prayer.fajr] ?? 0),
            offsetSunrise: Value(
              settings.offsetsMinutes[engine.Prayer.sunrise] ?? 0,
            ),
            offsetDhuhr: Value(
              settings.offsetsMinutes[engine.Prayer.dhuhr] ?? 0,
            ),
            offsetAsr: Value(settings.offsetsMinutes[engine.Prayer.asr] ?? 0),
            offsetMaghrib: Value(
              settings.offsetsMinutes[engine.Prayer.maghrib] ?? 0,
            ),
            offsetIsha: Value(settings.offsetsMinutes[engine.Prayer.isha] ?? 0),
            imsakMinutes: Value(settings.imsakMinutes),
            hijriAdjustment: Value(settings.hijriAdjustment),
            suggestionDismissedRegions: Value(
              (settings.dismissedSuggestionRegions.map((r) => r.name).toList()
                    ..sort())
                  .join(','),
            ),
            theme: Value(settings.theme),
            textScale: Value(settings.textScale),
            highContrast: Value(settings.highContrast),
          ),
        );
    return const Ok(null);
  }

  static AppError? _validate(PrayerSettings s) {
    for (final entry in s.offsetsMinutes.entries) {
      if (entry.value < PrayerSettings.minOffset ||
          entry.value > PrayerSettings.maxOffset) {
        return AppError(
          ErrorCode.invalidArgument,
          'Offset for ${entry.key.name} must be between '
          '${PrayerSettings.minOffset} and ${PrayerSettings.maxOffset} minutes.',
        );
      }
    }
    if (s.hijriAdjustment < PrayerSettings.minHijriAdjustment ||
        s.hijriAdjustment > PrayerSettings.maxHijriAdjustment) {
      return const AppError(
        ErrorCode.invalidArgument,
        'Hijri adjustment must be between -2 and +2 days.',
      );
    }
    if (s.imsakMinutes < 0 || s.imsakMinutes > 120) {
      return const AppError(
        ErrorCode.invalidArgument,
        'Imsak must be between 0 and 120 minutes before Fajr.',
      );
    }
    if (s.textScale < 0.8 || s.textScale > 2.0) {
      return const AppError(
        ErrorCode.invalidArgument,
        'Text scale must be between 0.8 and 2.0.',
      );
    }
    return null;
  }

  static PrayerSettings _fromRow(PrayerSettingsTableData row) {
    final dismissed = row.suggestionDismissedRegions
        .split(',')
        .where((name) => name.isNotEmpty)
        .map(
          (name) => engine.Region.values.firstWhere(
            (region) => region.name == name,
            orElse: () => engine.Region.other,
          ),
        )
        .toSet();
    return PrayerSettings(
      method: row.method,
      asrMethod: row.asrMethod,
      highLatitudeRule: row.highLatitudeRule,
      language: row.language,
      offsetsMinutes: {
        engine.Prayer.fajr: row.offsetFajr,
        engine.Prayer.sunrise: row.offsetSunrise,
        engine.Prayer.dhuhr: row.offsetDhuhr,
        engine.Prayer.asr: row.offsetAsr,
        engine.Prayer.maghrib: row.offsetMaghrib,
        engine.Prayer.isha: row.offsetIsha,
      },
      imsakMinutes: row.imsakMinutes,
      hijriAdjustment: row.hijriAdjustment,
      dismissedSuggestionRegions: dismissed,
      theme: row.theme,
      textScale: row.textScale,
      highContrast: row.highContrast,
    );
  }
}
