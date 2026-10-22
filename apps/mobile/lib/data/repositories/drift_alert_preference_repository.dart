import 'package:drift/drift.dart';

import '../../domain/entities/enums.dart';
import '../../domain/entities/settings.dart';
import '../../domain/repositories/alert_preference_repository.dart';
import '../../domain/result.dart';
import '../db/app_database.dart';

class DriftAlertPreferenceRepository implements AlertPreferenceRepository {
  DriftAlertPreferenceRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<AlertPreference>> getAll() async {
    final rows = await _db.select(_db.alertPreferenceTable).get();
    return _withDefaults(rows);
  }

  @override
  Stream<List<AlertPreference>> watchAll() {
    return _db.select(_db.alertPreferenceTable).watch().map(_withDefaults);
  }

  @override
  Future<Result<void>> save(AlertPreference preference) async {
    final minutes = preference.preReminderMinutes;
    if (minutes != null &&
        (minutes < AlertPreference.minReminderMinutes ||
            minutes > AlertPreference.maxReminderMinutes)) {
      return const Err(
        AppError(
          ErrorCode.invalidArgument,
          'A reminder must be between 5 and 60 minutes before the prayer.',
        ),
      );
    }
    await _db
        .into(_db.alertPreferenceTable)
        .insertOnConflictUpdate(
          AlertPreferenceTableCompanion.insert(
            prayer: preference.prayer,
            type: Value(preference.type),
            voiceId: Value(preference.voiceId),
            variant: Value(preference.variant),
            loudMode: Value(preference.loudMode),
            volumeChoice: Value(preference.volumeChoice),
            preReminderMinutes: Value(minutes),
            ignoreQuietHours: Value(preference.ignoreQuietHours),
          ),
        );
    return const Ok(null);
  }

  @override
  Future<GlobalAlertSettings> getGlobal() async {
    final row = await _db.select(_db.globalSettingsTable).getSingleOrNull();
    return row == null ? const GlobalAlertSettings() : _globalFromRow(row);
  }

  @override
  Stream<GlobalAlertSettings> watchGlobal() {
    return _db
        .select(_db.globalSettingsTable)
        .watchSingleOrNull()
        .map(
          (row) =>
              row == null ? const GlobalAlertSettings() : _globalFromRow(row),
        );
  }

  @override
  Future<Result<void>> saveGlobal(GlobalAlertSettings settings) async {
    final quiet = settings.quietHours;
    if (quiet != null) {
      bool bad(int m) => m < 0 || m > 1439;
      if (bad(quiet.startMinutes) || bad(quiet.endMinutes)) {
        return const Err(
          AppError(
            ErrorCode.invalidArgument,
            'Quiet hours must be times of day.',
          ),
        );
      }
    }
    if (settings.suhoorReminderMinutes < 5 ||
        settings.suhoorReminderMinutes > 180) {
      return const Err(
        AppError(
          ErrorCode.invalidArgument,
          'The suhoor reminder must be between 5 and 180 minutes before Fajr.',
        ),
      );
    }
    final clock = settings.clockSample;
    await _db
        .into(_db.globalSettingsTable)
        .insertOnConflictUpdate(
          GlobalSettingsTableCompanion(
            id: const Value(1),
            audioOutput: Value(settings.audioOutput),
            quietHoursStartMinutes: Value(quiet?.startMinutes),
            quietHoursEndMinutes: Value(quiet?.endMinutes),
            suhoorReminderEnabled: Value(settings.suhoorReminderEnabled),
            suhoorReminderMinutes: Value(settings.suhoorReminderMinutes),
            exactAlarmState: Value(settings.exactAlarmState),
            notificationPermissionState: Value(
              settings.notificationPermissionState,
            ),
            silentSwitchExplained: Value(settings.silentSwitchExplained),
            setupCompleted: Value(settings.setupCompleted),
            clockWallMs: Value(clock?.wallClockMs),
            clockMonotonicMs: Value(clock?.monotonicMs),
            clockBootId: Value(clock?.bootId),
            scheduleRunsUntilMs: Value(
              settings.scheduleRunsUntil?.millisecondsSinceEpoch,
            ),
          ),
        );
    return const Ok(null);
  }

  static List<AlertPreference> _withDefaults(
    List<AlertPreferenceTableData> rows,
  ) {
    final byPrayer = {for (final row in rows) row.prayer: row};
    return [
      for (final prayer in AlertPrayer.values)
        if (byPrayer[prayer] case final row?)
          AlertPreference(
            prayer: prayer,
            type: row.type,
            voiceId: row.voiceId,
            variant: row.variant,
            loudMode: row.loudMode,
            volumeChoice: row.volumeChoice,
            preReminderMinutes: row.preReminderMinutes,
            ignoreQuietHours: row.ignoreQuietHours,
          )
        else
          AlertPreference(prayer: prayer),
    ];
  }

  static GlobalAlertSettings _globalFromRow(GlobalSettingsTableData row) {
    final start = row.quietHoursStartMinutes;
    final end = row.quietHoursEndMinutes;
    final wall = row.clockWallMs;
    final mono = row.clockMonotonicMs;
    final boot = row.clockBootId;
    final runsUntil = row.scheduleRunsUntilMs;
    return GlobalAlertSettings(
      audioOutput: row.audioOutput,
      quietHours: (start != null && end != null)
          ? QuietHours(startMinutes: start, endMinutes: end)
          : null,
      suhoorReminderEnabled: row.suhoorReminderEnabled,
      suhoorReminderMinutes: row.suhoorReminderMinutes,
      exactAlarmState: row.exactAlarmState,
      notificationPermissionState: row.notificationPermissionState,
      silentSwitchExplained: row.silentSwitchExplained,
      setupCompleted: row.setupCompleted,
      clockSample: (wall != null && mono != null && boot != null)
          ? ClockSample(wallClockMs: wall, monotonicMs: mono, bootId: boot)
          : null,
      scheduleRunsUntil: runsUntil == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(runsUntil, isUtc: true),
    );
  }
}
