import 'package:deen_mobile/data/db/app_database.dart';
import 'package:deen_mobile/data/export/drift_app_data_store.dart';
import 'package:deen_mobile/data/repositories/drift_adhkar_repository.dart';
import 'package:deen_mobile/data/repositories/drift_alert_preference_repository.dart';
import 'package:deen_mobile/data/repositories/drift_location_repository.dart';
import 'package:deen_mobile/data/repositories/drift_settings_repository.dart';
import 'package:deen_mobile/domain/adhkar/adhkar_progress.dart';
import 'package:deen_mobile/domain/adhkar/adhkar_reminder.dart';
import 'package:deen_mobile/domain/delete_all_data.dart';
import 'package:deen_mobile/domain/entities/enums.dart';
import 'package:deen_mobile/domain/entities/settings.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prayer_engine/prayer_engine.dart';

class _Recorder {
  final List<String> calls = [];
  String? failOn;

  Future<void> record(String name) async {
    calls.add(name);
    if (failOn == name) throw StateError('$name failed');
  }
}

class _Native implements NativeAlertFiles {
  _Native(this.r);
  final _Recorder r;
  @override
  Future<void> deleteSnapshotAndJournal() => r.record('native');
}

class _Exports implements ExportFileCleaner {
  _Exports(this.r);
  final _Recorder r;
  @override
  Future<void> deleteExportFiles() => r.record('exports');
}

class _Store implements AppDataStore {
  _Store(this.r);
  final _Recorder r;
  @override
  Future<void> deleteAll() => r.record('database');
}

DeleteAllData _build(_Recorder r) => DeleteAllData(
  appData: _Store(r),
  cancelAlerts: () => r.record('alerts'),
  nativeFiles: _Native(r),
  exportFiles: _Exports(r),
);

Future<int> _rows(AppDatabase db) async {
  var total = 0;
  for (final table in db.allTables) {
    total += (await db.select(table).get()).length;
  }
  return total;
}

void main() {
  group('DeleteAllData', () {
    test(
      'cancels alerts first, then native files, database, exports',
      () async {
        final r = _Recorder();
        final result = await _build(r)();
        expect(result.isOk, isTrue);
        expect(r.calls, ['alerts', 'native', 'database', 'exports']);
      },
    );

    test('keeps going after a failure and names what failed', () async {
      final r = _Recorder()..failOn = 'native';
      final result = await _build(r)();
      expect(r.calls, ['alerts', 'native', 'database', 'exports']);
      final error = result.errorOrNull;
      expect(error, isA<DeleteAllFailure>());
      expect((error! as DeleteAllFailure).failedSteps, [
        DeleteStep.nativeAlertFiles,
      ]);
    });

    test('reports every failed step', () async {
      final r = _Recorder()..failOn = 'alerts';
      final result = await DeleteAllData(
        appData: _Store(r),
        cancelAlerts: () => r.record('alerts'),
        nativeFiles: _Native(r),
        exportFiles: _FailingExports(),
      )();
      expect((result.errorOrNull! as DeleteAllFailure).failedSteps, [
        DeleteStep.scheduledAlerts,
        DeleteStep.exportFiles,
      ]);
    });
  });

  group('DriftAppDataStore', () {
    test('empties every table and the database stays usable', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await _fill(db);
      expect(await _rows(db), greaterThan(9));

      await DriftAppDataStore(db).deleteAll();

      expect(await _rows(db), 0);
      expect(await DriftSettingsRepository(db).get(), isNull);
      expect(await DriftLocationRepository(db).get(), isNull);
      // Setup can run again.
      expect(
        (await DriftLocationRepository(db).save(
          AppLocation(
            source: LocationSource.city,
            latitude: 1,
            longitude: 2,
            displayName: 'Again',
            timeZoneId: 'UTC',
            countryCode: 'GB',
            updatedAt: DateTime.utc(2026),
          ),
        )).isOk,
        isTrue,
      );
    });

    test('with the database emptied, the whole flow reports success', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await _fill(db);
      final r = _Recorder();
      final result = await DeleteAllData(
        appData: DriftAppDataStore(db),
        cancelAlerts: () => r.record('alerts'),
        nativeFiles: _Native(r),
        exportFiles: _Exports(r),
      )();
      expect(result.isOk, isTrue);
      expect(await _rows(db), 0);
      expect(r.calls, ['alerts', 'native', 'exports']);
    });
  });
}

class _FailingExports implements ExportFileCleaner {
  @override
  Future<void> deleteExportFiles() async => throw StateError('locked');
}

/// Puts at least one row in every table.
Future<void> _fill(AppDatabase db) async {
  await DriftLocationRepository(db).save(
    AppLocation(
      source: LocationSource.city,
      latitude: 21.4,
      longitude: 39.8,
      displayName: 'Mecca',
      timeZoneId: 'Asia/Riyadh',
      countryCode: 'SA',
      updatedAt: DateTime.utc(2026),
    ),
  );
  await DriftSettingsRepository(db).save(
    const PrayerSettings(
      method: CalculationMethod.ummAlQura,
      asrMethod: AsrMethod.standard,
      highLatitudeRule: HighLatitudeRule.middleOfNight,
      language: AppLanguage.en,
    ),
  );
  final alerts = DriftAlertPreferenceRepository(db);
  await alerts.save(const AlertPreference(prayer: AlertPrayer.fajr));
  await alerts.saveGlobal(const GlobalAlertSettings(setupCompleted: true));
  await db
      .into(db.alertLogTable)
      .insert(
        AlertLogTableCompanion.insert(
          alertId: 'fajr:2026-10-21',
          plannedFireAtMs: 1,
          state: AlertLogState.played,
          source: AlertLogSource.inApp,
        ),
      );
  await db
      .into(db.tasbihStateTable)
      .insert(
        TasbihStateTableCompanion(id: const Value(1), count: const Value(5)),
      );
  await db
      .into(db.tasbihDaysTable)
      .insert(TasbihDaysTableCompanion.insert(date: '2026-10-21'));
  await DriftAdhkarProgressRepository(db).saveAll([
    AdhkarProgressRecord(
      sessionId: 's',
      collectionId: 'c',
      entryId: 'e',
      completedCount: 1,
      startedAt: DateTime.utc(2026),
    ),
  ]);
  await DriftAdhkarBookmarkRepository(db).toggle('e', now: DateTime.utc(2026));
  await DriftAdhkarReminderRepository(db)
      .save(AdhkarReminder.defaultFor(AdhkarReminderKind.morning));
}
