import 'package:drift/drift.dart';
import 'package:prayer_engine/prayer_engine.dart' as engine;

import '../../domain/entities/enums.dart';

part 'app_database.g.dart';

/// Single-row table (id is always 1): the saved location. Never leaves the device.
class LocationTable extends Table {
  @override
  String get tableName => 'location';

  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get source => textEnum<LocationSource>()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  IntColumn get cityId => integer().nullable()();
  TextColumn get displayName => text()();
  TextColumn get timeZoneId => text()();
  TextColumn get countryCode => text()();
  IntColumn get updatedAtMs => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Single-row table (id is always 1): calculation and appearance settings.
class PrayerSettingsTable extends Table {
  @override
  String get tableName => 'prayer_settings';

  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get method => textEnum<engine.CalculationMethod>()();
  TextColumn get asrMethod => textEnum<engine.AsrMethod>()();
  TextColumn get highLatitudeRule => textEnum<engine.HighLatitudeRule>()();
  IntColumn get offsetFajr => integer().withDefault(const Constant(0))();
  IntColumn get offsetSunrise => integer().withDefault(const Constant(0))();
  IntColumn get offsetDhuhr => integer().withDefault(const Constant(0))();
  IntColumn get offsetAsr => integer().withDefault(const Constant(0))();
  IntColumn get offsetMaghrib => integer().withDefault(const Constant(0))();
  IntColumn get offsetIsha => integer().withDefault(const Constant(0))();
  IntColumn get imsakMinutes => integer().withDefault(const Constant(10))();
  IntColumn get hijriAdjustment => integer().withDefault(const Constant(0))();

  /// Comma-separated region names whose method suggestion was dismissed.
  TextColumn get suggestionDismissedRegions =>
      text().withDefault(const Constant(''))();
  TextColumn get language => textEnum<AppLanguage>()();
  TextColumn get theme =>
      textEnum<ThemePreference>().withDefault(const Constant('system'))();
  RealColumn get textScale => real().withDefault(const Constant(1.0))();
  BoolColumn get highContrast => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// One row per prayer: the alert the user chose for it.
class AlertPreferenceTable extends Table {
  @override
  String get tableName => 'alert_preference';

  TextColumn get prayer => textEnum<AlertPrayer>()();
  TextColumn get type =>
      textEnum<AlertType>().withDefault(const Constant('shortTone'))();
  TextColumn get voiceId => text().withDefault(const Constant('voice-1'))();
  TextColumn get variant =>
      textEnum<AzaanVariant>().withDefault(const Constant('standard'))();
  BoolColumn get loudMode => boolean().withDefault(const Constant(false))();
  TextColumn get volumeChoice =>
      textEnum<VolumeChoice>().withDefault(const Constant('keepCurrent'))();
  IntColumn get preReminderMinutes => integer().nullable()();
  BoolColumn get ignoreQuietHours =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {prayer};
}

/// Single-row table (id is always 1): settings shared by all alerts.
class GlobalSettingsTable extends Table {
  @override
  String get tableName => 'global_settings';

  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get audioOutput =>
      textEnum<AudioOutput>().withDefault(const Constant('speaker'))();

  /// Local times as minutes after midnight; both null means no quiet hours.
  IntColumn get quietHoursStartMinutes => integer().nullable()();
  IntColumn get quietHoursEndMinutes => integer().nullable()();
  BoolColumn get suhoorReminderEnabled =>
      boolean().withDefault(const Constant(false))();
  IntColumn get suhoorReminderMinutes =>
      integer().withDefault(const Constant(30))();
  TextColumn get exactAlarmState =>
      textEnum<PermissionState>().withDefault(const Constant('unknown'))();
  TextColumn get notificationPermissionState =>
      textEnum<PermissionState>().withDefault(const Constant('unknown'))();
  BoolColumn get silentSwitchExplained =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get setupCompleted =>
      boolean().withDefault(const Constant(false))();

  /// Last clock sample used by the clock-sanity check.
  IntColumn get clockWallMs => integer().nullable()();
  IntColumn get clockMonotonicMs => integer().nullable()();
  TextColumn get clockBootId => text().nullable()();

  /// End of the last scheduled alert (epoch ms), shown in the Reliability check.
  IntColumn get scheduleRunsUntilMs => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// One row per alert occurrence: what was planned and what happened.
class AlertLogTable extends Table {
  @override
  String get tableName => 'alert_log';

  /// Stable id from the planner, for example `fajr:2026-10-22`.
  TextColumn get alertId => text()();

  /// Retry counter so a rebuilt alert never overwrites its history.
  IntColumn get attempt => integer().withDefault(const Constant(0))();
  IntColumn get plannedFireAtMs => integer()();
  TextColumn get state => textEnum<AlertLogState>()();
  IntColumn get firedAtMs => integer().nullable()();

  /// Milliseconds between planned and actual time (feeds SC-002).
  IntColumn get deviationMs => integer().nullable()();

  /// One of the causes in data-model.md.
  TextColumn get cause => text().nullable()();
  TextColumn get source => textEnum<AlertLogSource>()();

  @override
  Set<Column<Object>> get primaryKey => {alertId, attempt};
}

/// Single-row table (id is always 1): the active tasbih counter.
class TasbihStateTable extends Table {
  @override
  String get tableName => 'tasbih_state';

  IntColumn get id => integer().withDefault(const Constant(1))();
  IntColumn get count => integer().withDefault(const Constant(0))();
  IntColumn get target => integer().withDefault(const Constant(33))();
  BoolColumn get keepAwake => boolean().withDefault(const Constant(false))();
  BoolColumn get volumeKeys => boolean().withDefault(const Constant(false))();
  BoolColumn get lock => boolean().withDefault(const Constant(false))();
  BoolColumn get haptics => boolean().withDefault(const Constant(true))();
  BoolColumn get sound => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Daily tasbih totals for the history view.
class TasbihDaysTable extends Table {
  @override
  String get tableName => 'tasbih_days';

  /// Local date `YYYY-MM-DD`.
  TextColumn get date => text()();
  IntColumn get total => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {date};
}

/// How far a session through an adhkar collection has got.
class AdhkarProgressTable extends Table {
  @override
  String get tableName => 'adhkar_progress';

  TextColumn get sessionId => text()();
  TextColumn get collectionId => text()();
  TextColumn get entryId => text()();
  IntColumn get completedCount => integer().withDefault(const Constant(0))();
  IntColumn get startedAtMs => integer()();
  IntColumn get finishedAtMs => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {sessionId, entryId};
}

class AdhkarBookmarkTable extends Table {
  @override
  String get tableName => 'adhkar_bookmark';

  TextColumn get entryId => text()();
  IntColumn get createdAtMs => integer()();

  @override
  Set<Column<Object>> get primaryKey => {entryId};
}

class AdhkarReminderTable extends Table {
  @override
  String get tableName => 'adhkar_reminder';

  TextColumn get kind => textEnum<AdhkarReminderKind>()();
  TextColumn get anchor => textEnum<ReminderAnchor>()();

  /// Minutes after the anchor prayer (may be negative for "before").
  IntColumn get offsetMinutes => integer().withDefault(const Constant(0))();
  BoolColumn get enabled => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {kind};
}

/// Local SQLite database. All tables are on-device only.
@DriftDatabase(
  tables: [
    LocationTable,
    PrayerSettingsTable,
    AlertPreferenceTable,
    GlobalSettingsTable,
    AlertLogTable,
    TasbihStateTable,
    TasbihDaysTable,
    AdhkarProgressTable,
    AdhkarBookmarkTable,
    AdhkarReminderTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// Bump when a table changes and add a step to [migration].
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      // Each future schema change adds a step here. Existing data must
      // never be dropped on upgrade (constitution: versioned store).
    },
    beforeOpen: (OpeningDetails details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
