import 'dart:convert';

import 'package:deen_mobile/data/db/app_database.dart';
import 'package:deen_mobile/data/export/settings_export_service.dart';
import 'package:deen_mobile/data/export/tasbih_settings_store.dart';
import 'package:deen_mobile/data/repositories/drift_adhkar_repository.dart';
import 'package:deen_mobile/data/repositories/drift_alert_preference_repository.dart';
import 'package:deen_mobile/data/repositories/drift_location_repository.dart';
import 'package:deen_mobile/data/repositories/drift_settings_repository.dart';
import 'package:deen_mobile/domain/adhkar/adhkar_reminder.dart';
import 'package:deen_mobile/domain/entities/enums.dart';
import 'package:deen_mobile/domain/entities/settings.dart';
import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prayer_engine/prayer_engine.dart';

final _now = DateTime.utc(2026, 10, 21, 8);

class _Harness {
  _Harness({TasbihSettingsStore Function(AppDatabase)? tasbihStore})
    : db = AppDatabase(NativeDatabase.memory()) {
    settings = DriftSettingsRepository(db);
    location = DriftLocationRepository(db);
    alerts = DriftAlertPreferenceRepository(db);
    bookmarks = DriftAdhkarBookmarkRepository(db);
    reminders = DriftAdhkarReminderRepository(db);
    tasbih = (tasbihStore ?? DriftTasbihSettingsStore.new)(db);
    service = SettingsExportService(
      db: db,
      settings: settings,
      location: location,
      alerts: alerts,
      tasbih: tasbih,
      bookmarks: bookmarks,
      reminders: reminders,
      clock: () => _now,
      appVersion: '0.1.0',
      onImported: () async => importedCalls++,
    );
  }

  final AppDatabase db;
  late final DriftSettingsRepository settings;
  late final DriftLocationRepository location;
  late final DriftAlertPreferenceRepository alerts;
  late final DriftAdhkarBookmarkRepository bookmarks;
  late final DriftAdhkarReminderRepository reminders;
  late final TasbihSettingsStore tasbih;
  late final SettingsExportService service;
  int importedCalls = 0;

  Future<void> close() => db.close();

  /// Fills every exported store with non-default values.
  Future<void> populate() async {
    await location.save(
      AppLocation(
        source: LocationSource.city,
        latitude: 21.4225,
        longitude: 39.8262,
        cityId: 104515,
        displayName: 'Mecca',
        timeZoneId: 'Asia/Riyadh',
        countryCode: 'SA',
        updatedAt: _now,
      ),
    );
    await settings.save(
      const PrayerSettings(
        method: CalculationMethod.karachi,
        asrMethod: AsrMethod.hanafi,
        highLatitudeRule: HighLatitudeRule.seventhOfNight,
        language: AppLanguage.ur,
        offsetsMinutes: {
          Prayer.fajr: -5,
          Prayer.sunrise: 1,
          Prayer.dhuhr: 2,
          Prayer.asr: 3,
          Prayer.maghrib: 4,
          Prayer.isha: 60,
        },
        imsakMinutes: 15,
        hijriAdjustment: -2,
        theme: ThemePreference.dark,
        textScale: 1.5,
        highContrast: true,
      ),
    );
    await alerts.save(
      const AlertPreference(
        prayer: AlertPrayer.fajr,
        type: AlertType.fullAzaan,
        voiceId: 'voice-2',
        variant: AzaanVariant.shia,
        loudMode: true,
        volumeChoice: VolumeChoice.gentleRamp,
        preReminderMinutes: 10,
        ignoreQuietHours: true,
      ),
    );
    await alerts.save(
      const AlertPreference(prayer: AlertPrayer.isha, type: AlertType.vibrate),
    );
    await alerts.saveGlobal(
      const GlobalAlertSettings(
        audioOutput: AudioOutput.bluetooth,
        quietHours: QuietHours(startMinutes: 22 * 60, endMinutes: 5 * 60 + 30),
        suhoorReminderEnabled: true,
        suhoorReminderMinutes: 45,
        // Not exported: must not leak into the file.
        exactAlarmState: PermissionState.granted,
        notificationPermissionState: PermissionState.denied,
        setupCompleted: true,
      ),
    );
    await tasbih.write(
      const TasbihSettings(
        target: 99,
        keepAwake: true,
        volumeKeys: true,
        lock: true,
        haptics: false,
        sound: true,
      ),
    );
    await bookmarks.toggle('entry-b', now: DateTime.utc(2026, 1, 2));
    await bookmarks.toggle('entry-a', now: DateTime.utc(2026, 1, 1));
    await reminders.saveAll([
      const AdhkarReminder(
        kind: AdhkarReminderKind.morning,
        anchor: ReminderAnchor.fajr,
        offsetMinutes: 20,
        enabled: true,
      ),
      const AdhkarReminder(
        kind: AdhkarReminderKind.evening,
        anchor: ReminderAnchor.maghrib,
        offsetMinutes: -10,
        enabled: true,
      ),
    ]);
  }
}

Map<String, Object?> _file([Map<String, Object?> extra = const {}]) => {
  'format': 'deen-app-settings',
  'version': 1,
  ...extra,
};

String _json(Object? value) => jsonEncode(value);

void main() {
  // Round-trip tests open a second in-memory database on purpose.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late _Harness h;

  setUp(() => h = _Harness());
  tearDown(() => h.close());

  group('export', () {
    test('writes the versioned header and file name', () async {
      await h.populate();
      final json = jsonDecode(await h.service.exportJson()) as Map;
      expect(json['format'], 'deen-app-settings');
      expect(json['version'], 1);
      expect(json['exportedAt'], '2026-10-21T08:00:00Z');
      expect(json['appVersion'], '0.1.0');
      expect(json['language'], 'ur');
      expect(h.service.exportFileName(), 'deen-settings-20261021.json');
    });

    test('excludes permission states, alert log and identifiers', () async {
      await h.populate();
      final text = await h.service.exportJson();
      final json = jsonDecode(text) as Map<String, Object?>;
      expect(json.keys.toSet(), {
        'format',
        'version',
        'exportedAt',
        'appVersion',
        'language',
        'appearance',
        'location',
        'prayer',
        'alerts',
        'tasbih',
        'adhkar',
      });
      for (final leaked in [
        'exactAlarm',
        'notificationPermission',
        'alertLog',
        'deviceId',
        'clockSample',
        'granted',
        'denied',
        'setupCompleted',
      ]) {
        expect(text.contains(leaked), isFalse, reason: leaked);
      }
    });

    test('exports audioOutput and ignoreQuietHours', () async {
      await h.populate();
      final json = jsonDecode(await h.service.exportJson()) as Map;
      final alerts = json['alerts'] as Map;
      expect(alerts['audioOutput'], 'bluetooth');
      expect(alerts['quietHours'], {'start': '22:00', 'end': '05:30'});
      expect(alerts['suhoorReminder'], {'enabled': true, 'minutes': 45});
      final fajr = (alerts['perPrayer'] as Map)['fajr'] as Map;
      expect(fajr['ignoreQuietHours'], isTrue);
      expect(fajr['loudMode'], isTrue);
      expect(fajr['volumeChoice'], 'gentleRamp');
      expect(fajr['variant'], 'shia');
    });

    test('works before setup: only defaults and what exists', () async {
      final json = jsonDecode(await h.service.exportJson()) as Map;
      expect(json.containsKey('prayer'), isFalse);
      expect(json.containsKey('location'), isFalse);
      expect(json.containsKey('language'), isFalse);
      expect(json['alerts'], isNotNull);
    });
  });

  group('round trip', () {
    test('import into an empty device restores everything', () async {
      await h.populate();
      final exported = await h.service.exportJson();

      final other = _Harness();
      addTearDown(other.close);
      final result = await other.service.importJson(exported);
      expect(result.isOk, isTrue, reason: '${result.errorOrNull}');
      expect(await other.service.exportJson(), exported);
      expect(other.importedCalls, 1, reason: 'schedule rebuilt once');

      final globals = await other.alerts.getGlobal();
      expect(globals.audioOutput, AudioOutput.bluetooth);
      expect(
        globals.setupCompleted,
        isFalse,
        reason: 'bookkeeping not imported',
      );
      expect((await other.alerts.getAll()).first.ignoreQuietHours, isTrue);
      expect((await other.settings.get())!.offsetsMinutes[Prayer.isha], 60);
      expect((await other.tasbih.read()).target, 99);
      expect((await other.bookmarks.getAll()).map((b) => b.entryId), [
        'entry-a',
        'entry-b',
      ]);
    });

    test(
      'keeps device bookkeeping when importing over existing data',
      () async {
        await h.populate();
        final exported = await h.service.exportJson();
        await h.alerts.saveGlobal(
          (await h.alerts.getGlobal()).copyWith(
            audioOutput: AudioOutput.speaker,
            exactAlarmState: PermissionState.denied,
          ),
        );
        expect((await h.service.importJson(exported)).isOk, isTrue);
        final globals = await h.alerts.getGlobal();
        expect(globals.audioOutput, AudioOutput.bluetooth);
        expect(globals.exactAlarmState, PermissionState.denied);
        expect(globals.setupCompleted, isTrue);
      },
    );

    test('keeps the tasbih count when importing tasbih settings', () async {
      await h.db
          .into(h.db.tasbihStateTable)
          .insertOnConflictUpdate(
            TasbihStateTableCompanion(
              id: const Value(1),
              count: const Value(17),
            ),
          );
      final result = await h.service.importJson(
        _json(
          _file({
            'tasbih': {'target': 100},
          }),
        ),
      );
      expect(result.isOk, isTrue);
      final row = await h.db.select(h.db.tasbihStateTable).getSingle();
      expect(row.count, 17);
      expect(row.target, 100);
    });
  });

  group('rejection', () {
    Future<void> expectRejected(String text, ImportFailureKind kind) async {
      await h.populate();
      final before = await h.service.exportJson();
      final result = await h.service.importJson(text);
      final error = result.errorOrNull;
      expect(error, isA<ImportFailure>());
      expect((error! as ImportFailure).kind, kind);
      expect(await h.service.exportJson(), before, reason: 'nothing applied');
      expect(h.importedCalls, 0);
    }

    test('unknown format', () async {
      await expectRejected(
        _json({'format': 'something-else', 'version': 1}),
        ImportFailureKind.notSettingsFile,
      );
    });

    test('missing format', () async {
      await expectRejected(
        _json({'version': 1}),
        ImportFailureKind.notSettingsFile,
      );
    });

    test('a newer version', () async {
      await expectRejected(
        _json({'format': 'deen-app-settings', 'version': 2}),
        ImportFailureKind.newerVersion,
      );
    });

    test('a missing or non-numeric version', () async {
      await expectRejected(
        _json({'format': 'deen-app-settings'}),
        ImportFailureKind.unreadable,
      );
      await expectRejected(
        _json({'format': 'deen-app-settings', 'version': 'one'}),
        ImportFailureKind.unreadable,
      );
    });

    test('text that is not JSON, or JSON that is not an object', () async {
      await expectRejected('not json {', ImportFailureKind.unreadable);
      await expectRejected('[1,2]', ImportFailureKind.unreadable);
      await expectRejected('', ImportFailureKind.unreadable);
    });

    test('is all-or-nothing: one bad value applies nothing', () async {
      await expectRejected(
        _json(
          _file({
            'appearance': {'theme': 'light', 'textScale': 1.0},
            'tasbih': {'target': 50},
            'adhkar': {
              'bookmarks': ['new-entry'],
            },
            'prayer': {
              'offsetsMinutes': {'fajr': 61},
            },
          }),
        ),
        ImportFailureKind.invalidValue,
      );
    });

    test('rolls back when a store fails while applying', () async {
      final failing = _Harness(tasbihStore: (_) => _ThrowingTasbihStore());
      addTearDown(failing.close);
      await failing.settings.save(
        const PrayerSettings(
          method: CalculationMethod.karachi,
          asrMethod: AsrMethod.standard,
          highLatitudeRule: HighLatitudeRule.middleOfNight,
          language: AppLanguage.en,
        ),
      );
      final result = await failing.service.importJson(
        _json(
          _file({
            'appearance': {'theme': 'dark'},
            'tasbih': {'target': 50},
          }),
        ),
      );
      expect(
        (result.errorOrNull! as ImportFailure).kind,
        ImportFailureKind.applyFailed,
      );
      expect((await failing.settings.get())!.theme, ThemePreference.system);
      expect(failing.importedCalls, 0);
    });
  });

  group('range validation', () {
    final cases = <String, Map<String, Object?>>{
      'offset above 60': {
        'prayer': {
          'offsetsMinutes': {'fajr': 61},
        },
      },
      'offset below -60': {
        'prayer': {
          'offsetsMinutes': {'isha': -61},
        },
      },
      'Hijri adjustment 3': {
        'prayer': {'hijriAdjustment': 3},
      },
      'Imsak 121': {
        'prayer': {'imsakMinutes': 121},
      },
      'text scale 2.5': {
        'appearance': {'textScale': 2.5},
      },
      'text scale 0.5': {
        'appearance': {'textScale': 0.5},
      },
      'unknown theme': {
        'appearance': {'theme': 'sepia'},
      },
      'unknown calculation method': {
        'prayer': {'method': 'moonsighting-by-owl'},
      },
      'pre-reminder 4': {
        'alerts': {
          'perPrayer': {
            'fajr': {'preReminderMinutes': 4},
          },
        },
      },
      'pre-reminder 61': {
        'alerts': {
          'perPrayer': {
            'fajr': {'preReminderMinutes': 61},
          },
        },
      },
      'unknown alert type': {
        'alerts': {
          'perPrayer': {
            'dhuhr': {'type': 'siren'},
          },
        },
      },
      'unknown audio output': {
        'alerts': {'audioOutput': 'tin-can'},
      },
      'quiet hours not a time': {
        'alerts': {
          'quietHours': {'start': '25:00', 'end': '05:00'},
        },
      },
      'quiet hours missing end': {
        'alerts': {
          'quietHours': {'start': '22:00'},
        },
      },
      'suhoor 4 minutes': {
        'alerts': {
          'suhoorReminder': {'enabled': true, 'minutes': 4},
        },
      },
      'suhoor 181 minutes': {
        'alerts': {
          'suhoorReminder': {'enabled': true, 'minutes': 181},
        },
      },
      'latitude 91': {
        'location': {
          'source': 'city',
          'latitude': 91.0,
          'longitude': 0.0,
          'displayName': 'X',
          'timeZoneId': 'UTC',
          'countryCode': 'GB',
        },
      },
      'longitude -181': {
        'location': {
          'source': 'city',
          'latitude': 0.0,
          'longitude': -181.0,
          'displayName': 'X',
          'timeZoneId': 'UTC',
          'countryCode': 'GB',
        },
      },
      'location without a time zone': {
        'location': {
          'source': 'city',
          'latitude': 0.0,
          'longitude': 0.0,
          'displayName': 'X',
          'countryCode': 'GB',
        },
      },
      'tasbih target 0': {
        'tasbih': {'target': 0},
      },
      'tasbih target 100001': {
        'tasbih': {'target': 100001},
      },
      'tasbih flag is not a bool': {
        'tasbih': {'keepAwake': 'yes'},
      },
      'bookmarks not a list of text': {
        'adhkar': {
          'bookmarks': [1, 2],
        },
      },
      'morning reminder anchored to Asr': {
        'adhkar': {
          'reminders': [
            {
              'kind': 'morning',
              'anchor': 'asr',
              'offsetMinutes': 0,
              'enabled': true,
            },
          ],
        },
      },
      'reminder offset 500': {
        'adhkar': {
          'reminders': [
            {
              'kind': 'evening',
              'anchor': 'asr',
              'offsetMinutes': 500,
              'enabled': true,
            },
          ],
        },
      },
      'language not supported': {'language': 'fr'},
    };

    for (final entry in cases.entries) {
      test('rejects ${entry.key}', () async {
        await h.populate();
        final before = await h.service.exportJson();
        final result = await h.service.importJson(_json(_file(entry.value)));
        final error = result.errorOrNull;
        expect(error, isA<ImportFailure>(), reason: entry.key);
        expect((error! as ImportFailure).kind, ImportFailureKind.invalidValue);
        expect((error as ImportFailure).field, isNotNull);
        expect(await h.service.exportJson(), before);
      });
    }

    test('accepts the boundary values', () async {
      await h.populate();
      final result = await h.service.importJson(
        _json(
          _file({
            'prayer': {
              'offsetsMinutes': {'fajr': -60, 'isha': 60},
              'hijriAdjustment': 2,
              'imsakMinutes': 0,
            },
            'appearance': {'textScale': 0.8},
            'alerts': {
              'perPrayer': {
                'fajr': {'preReminderMinutes': 5},
                'isha': {'preReminderMinutes': 60},
              },
              'suhoorReminder': {'enabled': false, 'minutes': 180},
            },
            'tasbih': {'target': 100000},
          }),
        ),
      );
      expect(result.isOk, isTrue, reason: '${result.errorOrNull}');
    });
  });

  group('forward and partial files', () {
    test('ignores unknown keys at every level', () async {
      await h.populate();
      final result = await h.service.importJson(
        _json(
          _file({
            'futureTopLevel': {'x': 1},
            'appearance': {'theme': 'light', 'sparkle': true},
            'prayer': {
              'offsetsMinutes': {'midnight': 5},
            },
            'alerts': {
              'perPrayer': {
                'asr': {'type': 'silent', 'newOption': 3},
                'sunrise': {'type': 'silent'},
              },
              'brandNew': [],
            },
          }),
        ),
      );
      expect(result.isOk, isTrue, reason: '${result.errorOrNull}');
      expect((await h.settings.get())!.theme, ThemePreference.light);
      expect(
        (await h.alerts.getAll())[AlertPrayer.asr.index].type,
        AlertType.silent,
      );
    });

    test('missing optional keys keep the current values', () async {
      await h.populate();
      final result = await h.service.importJson(
        _json(
          _file({
            'appearance': {'theme': 'light'},
            'alerts': {
              'perPrayer': {
                'fajr': {'type': 'silent'},
              },
            },
          }),
        ),
      );
      expect(result.isOk, isTrue, reason: '${result.errorOrNull}');
      final settings = (await h.settings.get())!;
      expect(settings.theme, ThemePreference.light);
      expect(settings.textScale, 1.5);
      expect(settings.highContrast, isTrue);
      expect(settings.method, CalculationMethod.karachi);
      final fajr = (await h.alerts.getAll()).first;
      expect(fajr.type, AlertType.silent);
      expect(fajr.ignoreQuietHours, isTrue);
      expect(fajr.voiceId, 'voice-2');
      expect((await h.alerts.getGlobal()).audioOutput, AudioOutput.bluetooth);
      expect((await h.bookmarks.getAll()), hasLength(2));
    });

    test('explicit null quiet hours turns them off', () async {
      await h.populate();
      final result = await h.service.importJson(
        _json(
          _file({
            'alerts': {'quietHours': null},
          }),
        ),
      );
      expect(result.isOk, isTrue);
      expect((await h.alerts.getGlobal()).quietHours, isNull);
    });

    test('a different time zone and language are allowed', () async {
      final result = await h.service.importJson(
        _json(
          _file({
            'language': 'id',
            'prayer': {
              'method': 'singapore',
              'asr': 'standard',
              'highLatitudeRule': 'middleOfNight',
            },
            'location': {
              'source': 'city',
              'latitude': -36.85,
              'longitude': 174.76,
              'cityId': 2193733,
              'displayName': 'Auckland',
              'timeZoneId': 'Pacific/Auckland',
              'countryCode': 'nz',
            },
          }),
        ),
      );
      expect(result.isOk, isTrue, reason: '${result.errorOrNull}');
      final location = (await h.location.get())!;
      expect(location.timeZoneId, 'Pacific/Auckland');
      expect(location.countryCode, 'NZ');
      expect((await h.settings.get())!.language, AppLanguage.id);
    });

    test('appearance without any saved settings is refused plainly', () async {
      final result = await h.service.importJson(
        _json(
          _file({
            'appearance': {'theme': 'dark'},
          }),
        ),
      );
      final error = result.errorOrNull! as ImportFailure;
      expect(error.kind, ImportFailureKind.invalidValue);
      expect(error.field, 'prayer');
    });

    test('a header-only file is a valid no-op', () async {
      await h.populate();
      final before = await h.service.exportJson();
      expect((await h.service.importJson(_json(_file()))).isOk, isTrue);
      expect(await h.service.exportJson(), before);
    });

    test(
      'a failing schedule rebuild is reported, data stays imported',
      () async {
        final failing = SettingsExportService(
          db: h.db,
          settings: h.settings,
          location: h.location,
          alerts: h.alerts,
          tasbih: h.tasbih,
          bookmarks: h.bookmarks,
          reminders: h.reminders,
          clock: () => _now,
          appVersion: '0.1.0',
          onImported: () async => throw StateError('boom'),
        );
        final result = await failing.importJson(
          _json(
            _file({
              'tasbih': {'target': 12},
            }),
          ),
        );
        expect(result.valueOrNull?.scheduleRefreshed, isFalse);
        expect((await h.tasbih.read()).target, 12);
      },
    );
  });
}

class _ThrowingTasbihStore implements TasbihSettingsStore {
  @override
  Future<TasbihSettings> read() async => const TasbihSettings();

  @override
  Future<void> write(TasbihSettings settings) async {
    throw StateError('disk full');
  }
}
