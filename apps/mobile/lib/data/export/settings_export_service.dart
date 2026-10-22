// The constructor assigns private fields from named parameters, which cannot
// be initializing formals.
// ignore_for_file: prefer_initializing_formals

import 'dart:convert';

import 'package:prayer_engine/prayer_engine.dart' as engine;

import '../../domain/adhkar/adhkar_bookmark.dart';
import '../../domain/adhkar/adhkar_reminder.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/settings.dart';
import '../../domain/repositories/adhkar_repository.dart';
import '../../domain/repositories/alert_preference_repository.dart';
import '../../domain/repositories/location_repository.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/result.dart';
import '../db/app_database.dart';
import 'tasbih_settings_store.dart';

/// Value of `format` in every settings file.
const String settingsExportFormat = 'deen-app-settings';

/// Highest file version this app writes and reads. Raise it only for an
/// incompatible change and keep an importer for every released version
/// (contracts/settings-export.md).
const int settingsExportVersion = 1;

/// Why an import was refused.
enum ImportFailureKind {
  /// Valid JSON, but not a Deen App settings file.
  notSettingsFile,

  /// Written by a newer version of the app.
  newerVersion,

  /// Not JSON, or the header is unusable.
  unreadable,

  /// A value is missing, of the wrong type or outside its allowed range.
  invalidValue,

  /// The file was valid but saving it failed; nothing was changed.
  applyFailed,
}

/// An import that was refused. [field] names the offending key (for example
/// `prayer.offsetsMinutes.fajr`) and never contains a value, so it is safe to
/// show.
class ImportFailure extends AppError {
  const ImportFailure(this.kind, String message, {this.field})
    : super(ErrorCode.invalidArgument, message);

  final ImportFailureKind kind;
  final String? field;
}

/// What a successful import did besides saving.
class ImportReport {
  const ImportReport({required this.scheduleRefreshed});

  /// False when the schedule rebuild after import failed. The data is saved;
  /// the app rebuilds the schedule the next time it opens.
  final bool scheduleRefreshed;
}

/// Writes and reads the versioned settings file described in
/// contracts/settings-export.md.
///
/// The file never contains the alert log, tasbih history, permission states or
/// device identifiers. Import validates every value first and then saves all of
/// it in one transaction, so a bad file changes nothing.
class SettingsExportService {
  SettingsExportService({
    required AppDatabase db,
    required SettingsRepository settings,
    required LocationRepository location,
    required AlertPreferenceRepository alerts,
    required TasbihSettingsStore tasbih,
    required AdhkarBookmarkRepository bookmarks,
    required AdhkarReminderRepository reminders,
    required DateTime Function() clock,
    required String appVersion,
    Future<void> Function()? onImported,
  }) : _db = db,
       _settings = settings,
       _location = location,
       _alerts = alerts,
       _tasbih = tasbih,
       _bookmarks = bookmarks,
       _reminders = reminders,
       _clock = clock,
       _appVersion = appVersion,
       _onImported = onImported;

  final AppDatabase _db;
  final SettingsRepository _settings;
  final LocationRepository _location;
  final AlertPreferenceRepository _alerts;
  final TasbihSettingsStore _tasbih;
  final AdhkarBookmarkRepository _bookmarks;
  final AdhkarReminderRepository _reminders;
  final DateTime Function() _clock;
  final String _appVersion;

  /// Called after a successful import so the alert schedule is rebuilt.
  final Future<void> Function()? _onImported;

  /// `deen-settings-yyyymmdd.json`, using the date in UTC.
  String exportFileName() {
    final d = _clock().toUtc();
    String two(int n) => n.toString().padLeft(2, '0');
    return 'deen-settings-${d.year.toString().padLeft(4, '0')}'
        '${two(d.month)}${two(d.day)}.json';
  }

  /// The settings file as text.
  Future<String> exportJson() async {
    final settings = await _settings.get();
    final location = await _location.get();
    final prefs = await _alerts.getAll();
    final global = await _alerts.getGlobal();
    final tasbih = await _tasbih.read();
    final bookmarks = await _bookmarks.getAll();
    final reminders = await _reminders.getAll();

    final out = <String, Object?>{
      'format': settingsExportFormat,
      'version': settingsExportVersion,
      'exportedAt': _isoSeconds(_clock()),
      'appVersion': _appVersion,
      'language': ?settings?.language.name,
      if (settings != null) ...{
        'appearance': {
          'theme': settings.theme.name,
          'textScale': settings.textScale,
          'highContrast': settings.highContrast,
        },
      },
      if (location != null)
        'location': {
          'source': location.source.name,
          'latitude': location.latitude,
          'longitude': location.longitude,
          'cityId': location.cityId,
          'displayName': location.displayName,
          'timeZoneId': location.timeZoneId,
          'countryCode': location.countryCode,
        },
      if (settings != null)
        'prayer': {
          'method': settings.method.name,
          'asr': settings.asrMethod.name,
          'highLatitudeRule': settings.highLatitudeRule.name,
          'offsetsMinutes': {
            for (final prayer in engine.Prayer.values)
              prayer.name: settings.offsetsMinutes[prayer] ?? 0,
          },
          'imsakMinutes': settings.imsakMinutes,
          'hijriAdjustment': settings.hijriAdjustment,
        },
      'alerts': {
        'perPrayer': {
          for (final p in prefs)
            p.prayer.name: {
              'type': p.type.name,
              'voiceId': p.voiceId,
              'variant': p.variant.name,
              'loudMode': p.loudMode,
              'volumeChoice': p.volumeChoice.name,
              'preReminderMinutes': p.preReminderMinutes,
              'ignoreQuietHours': p.ignoreQuietHours,
            },
        },
        'audioOutput': global.audioOutput.name,
        'quietHours': global.quietHours == null
            ? null
            : {
                'start': _formatMinutes(global.quietHours!.startMinutes),
                'end': _formatMinutes(global.quietHours!.endMinutes),
              },
        'suhoorReminder': {
          'enabled': global.suhoorReminderEnabled,
          'minutes': global.suhoorReminderMinutes,
        },
      },
      'tasbih': {
        'target': tasbih.target,
        'keepAwake': tasbih.keepAwake,
        'volumeKeys': tasbih.volumeKeys,
        'lock': tasbih.lock,
        'haptics': tasbih.haptics,
        'sound': tasbih.sound,
      },
      'adhkar': {
        'bookmarks': [for (final b in bookmarks) b.entryId],
        'reminders': [
          for (final r in reminders)
            {
              'kind': r.kind.name,
              'anchor': r.anchor.name,
              'offsetMinutes': r.offsetMinutes,
              'enabled': r.enabled,
            },
        ],
      },
    };
    return '${const JsonEncoder.withIndent('  ').convert(out)}\n';
  }

  /// Validates [text] and, only if all of it is valid, saves it in one
  /// transaction and then rebuilds the schedule.
  Future<Result<ImportReport>> importJson(String text) async {
    final _Plan plan;
    try {
      plan = _parse(text);
    } on _Invalid catch (e) {
      return Err(e.toFailure());
    }

    try {
      final resolved = await _resolve(plan);
      await _db.transaction(() => _apply(resolved));
    } on _Invalid catch (e) {
      return Err(e.toFailure());
    } on Object catch (_) {
      return const Err(
        ImportFailure(
          ImportFailureKind.applyFailed,
          'The settings could not be saved. Nothing was changed.',
        ),
      );
    }

    var refreshed = true;
    try {
      await _onImported?.call();
    } on Object catch (_) {
      refreshed = false;
    }
    return Ok(ImportReport(scheduleRefreshed: refreshed));
  }

  // ---- Parsing and validation (no I/O) ----

  _Plan _parse(String text) {
    final Object? decoded;
    try {
      decoded = jsonDecode(text);
    } on FormatException {
      throw const _Invalid(
        ImportFailureKind.unreadable,
        'This file is not readable as settings.',
      );
    }
    if (decoded is! Map<String, Object?>) {
      throw const _Invalid(
        ImportFailureKind.unreadable,
        'This file is not readable as settings.',
      );
    }
    if (decoded['format'] != settingsExportFormat) {
      throw const _Invalid(
        ImportFailureKind.notSettingsFile,
        'This is not a Deen App settings file.',
      );
    }
    final version = decoded['version'];
    if (version is! int || version < 1) {
      throw const _Invalid(
        ImportFailureKind.unreadable,
        'The file has no usable version.',
        field: 'version',
      );
    }
    if (version > settingsExportVersion) {
      throw const _Invalid(
        ImportFailureKind.newerVersion,
        'This file was made by a newer version of the app.',
        field: 'version',
      );
    }

    final r = _Reader();
    final plan = _Plan();
    plan.language = r.optEnum(decoded, '', 'language', AppLanguage.values);

    final appearance = r.optObject(decoded, '', 'appearance');
    if (appearance != null) {
      plan.theme = r.optEnum(
        appearance,
        'appearance',
        'theme',
        ThemePreference.values,
      );
      plan.textScale = r.optDouble(
        appearance,
        'appearance',
        'textScale',
        min: 0.8,
        max: 2.0,
      );
      plan.highContrast = r.optBool(appearance, 'appearance', 'highContrast');
    }

    final location = r.optObject(decoded, '', 'location');
    if (location != null) plan.location = _parseLocation(r, location);

    final prayer = r.optObject(decoded, '', 'prayer');
    if (prayer != null) {
      plan.method = r.optEnum(
        prayer,
        'prayer',
        'method',
        engine.CalculationMethod.values,
      );
      plan.asr = r.optEnum(prayer, 'prayer', 'asr', engine.AsrMethod.values);
      plan.highLatitudeRule = r.optEnum(
        prayer,
        'prayer',
        'highLatitudeRule',
        engine.HighLatitudeRule.values,
      );
      final offsets = r.optObject(prayer, 'prayer', 'offsetsMinutes');
      if (offsets != null) {
        for (final entry in offsets.entries) {
          final known = engine.Prayer.values.where((p) => p.name == entry.key);
          // A prayer this version does not know is an unknown key: ignored.
          if (known.isEmpty) continue;
          final value = r.optInt(
            offsets,
            'prayer.offsetsMinutes',
            entry.key,
            min: PrayerSettings.minOffset,
            max: PrayerSettings.maxOffset,
          );
          if (value != null) plan.offsets[known.single] = value;
        }
      }
      plan.imsakMinutes = r.optInt(
        prayer,
        'prayer',
        'imsakMinutes',
        min: 0,
        max: 120,
      );
      plan.hijriAdjustment = r.optInt(
        prayer,
        'prayer',
        'hijriAdjustment',
        min: PrayerSettings.minHijriAdjustment,
        max: PrayerSettings.maxHijriAdjustment,
      );
    }

    final alerts = r.optObject(decoded, '', 'alerts');
    if (alerts != null) _parseAlerts(r, alerts, plan);

    final tasbih = r.optObject(decoded, '', 'tasbih');
    if (tasbih != null) {
      plan.tasbihTarget = r.optInt(
        tasbih,
        'tasbih',
        'target',
        min: TasbihSettings.minTarget,
        max: TasbihSettings.maxTarget,
      );
      plan.keepAwake = r.optBool(tasbih, 'tasbih', 'keepAwake');
      plan.volumeKeys = r.optBool(tasbih, 'tasbih', 'volumeKeys');
      plan.lock = r.optBool(tasbih, 'tasbih', 'lock');
      plan.haptics = r.optBool(tasbih, 'tasbih', 'haptics');
      plan.sound = r.optBool(tasbih, 'tasbih', 'sound');
    }

    final adhkar = r.optObject(decoded, '', 'adhkar');
    if (adhkar != null) {
      plan.bookmarks = r.optStringList(adhkar, 'adhkar', 'bookmarks');
      plan.reminders = _parseReminders(r, adhkar);
    }
    return plan;
  }

  AppLocation _parseLocation(_Reader r, Map<String, Object?> json) {
    const path = 'location';
    final source = r.requireEnum(json, path, 'source', LocationSource.values);
    final latitude = r.requireDouble(json, path, 'latitude', min: -90, max: 90);
    final longitude = r.requireDouble(
      json,
      path,
      'longitude',
      min: -180,
      max: 180,
    );
    final name = r.requireString(json, path, 'displayName');
    final zone = r.requireString(json, path, 'timeZoneId');
    final country = r.requireString(json, path, 'countryCode').toUpperCase();
    if (country.length != 2) throw _Invalid.value('$path.countryCode');
    return AppLocation(
      source: source,
      latitude: latitude,
      longitude: longitude,
      cityId: r.optInt(json, path, 'cityId', min: 0, max: 1 << 40),
      displayName: name,
      timeZoneId: zone,
      countryCode: country,
      // Set when saved: the file carries no timestamp for the location.
      updatedAt: _clock(),
    );
  }

  void _parseAlerts(_Reader r, Map<String, Object?> alerts, _Plan plan) {
    final perPrayer = r.optObject(alerts, 'alerts', 'perPrayer');
    if (perPrayer != null) {
      for (final entry in perPrayer.entries) {
        final matches = AlertPrayer.values.where((p) => p.name == entry.key);
        final path = 'alerts.perPrayer.${entry.key}';
        if (matches.isEmpty) continue; // unknown key: ignored
        final json = entry.value;
        if (json is! Map<String, Object?>) throw _Invalid.value(path);
        plan.prefs[matches.single] = _PrefPatch(
          type: r.optEnum(json, path, 'type', AlertType.values),
          voiceId: r.optString(json, path, 'voiceId'),
          variant: r.optEnum(json, path, 'variant', AzaanVariant.values),
          loudMode: r.optBool(json, path, 'loudMode'),
          volumeChoice: r.optEnum(
            json,
            path,
            'volumeChoice',
            VolumeChoice.values,
          ),
          hasPreReminder: json.containsKey('preReminderMinutes'),
          preReminderMinutes: r.optInt(
            json,
            path,
            'preReminderMinutes',
            min: AlertPreference.minReminderMinutes,
            max: AlertPreference.maxReminderMinutes,
          ),
          ignoreQuietHours: r.optBool(json, path, 'ignoreQuietHours'),
        );
      }
    }
    plan.audioOutput = r.optEnum(
      alerts,
      'alerts',
      'audioOutput',
      AudioOutput.values,
    );
    if (alerts.containsKey('quietHours')) {
      plan.hasQuietHours = true;
      final quiet = alerts['quietHours'];
      if (quiet != null) {
        if (quiet is! Map<String, Object?>) {
          throw _Invalid.value('alerts.quietHours');
        }
        plan.quietHours = QuietHours(
          startMinutes: r.requireClock(quiet, 'alerts.quietHours', 'start'),
          endMinutes: r.requireClock(quiet, 'alerts.quietHours', 'end'),
        );
      }
    }
    final suhoor = r.optObject(alerts, 'alerts', 'suhoorReminder');
    if (suhoor != null) {
      plan.suhoorEnabled = r.optBool(
        suhoor,
        'alerts.suhoorReminder',
        'enabled',
      );
      plan.suhoorMinutes = r.optInt(
        suhoor,
        'alerts.suhoorReminder',
        'minutes',
        min: 5,
        max: 180,
      );
    }
  }

  List<AdhkarReminder>? _parseReminders(
    _Reader r,
    Map<String, Object?> adhkar,
  ) {
    final raw = adhkar['reminders'];
    if (raw == null) return null;
    if (raw is! List<Object?>) throw _Invalid.value('adhkar.reminders');
    final result = <AdhkarReminder>[];
    for (var i = 0; i < raw.length; i++) {
      final path = 'adhkar.reminders[$i]';
      final json = raw[i];
      if (json is! Map<String, Object?>) throw _Invalid.value(path);
      final reminder = AdhkarReminder(
        kind: r.requireEnum(json, path, 'kind', AdhkarReminderKind.values),
        anchor: r.requireEnum(json, path, 'anchor', ReminderAnchor.values),
        offsetMinutes: r.requireInt(json, path, 'offsetMinutes'),
        enabled: r.optBool(json, path, 'enabled') ?? false,
      );
      if (reminder.validate() != null) throw _Invalid.value(path);
      result.add(reminder);
    }
    return result;
  }

  // ---- Merging with what is saved now ----

  Future<_Resolved> _resolve(_Plan plan) async {
    PrayerSettings? settings;
    if (plan.touchesSettings) {
      final current = await _settings.get();
      final method = plan.method ?? current?.method;
      final asr = plan.asr ?? current?.asrMethod;
      final rule = plan.highLatitudeRule ?? current?.highLatitudeRule;
      final language = plan.language ?? current?.language;
      if (method == null || asr == null || rule == null) {
        throw _Invalid.value('prayer');
      }
      if (language == null) throw _Invalid.value('language');
      final base =
          current ??
          PrayerSettings(
            method: method,
            asrMethod: asr,
            highLatitudeRule: rule,
            language: language,
          );
      settings = base.copyWith(
        method: method,
        asrMethod: asr,
        highLatitudeRule: rule,
        language: language,
        offsetsMinutes: {...base.offsetsMinutes, ...plan.offsets},
        imsakMinutes: plan.imsakMinutes,
        hijriAdjustment: plan.hijriAdjustment,
        theme: plan.theme,
        textScale: plan.textScale,
        highContrast: plan.highContrast,
      );
    }

    final currentPrefs = {for (final p in await _alerts.getAll()) p.prayer: p};
    final prefs = <AlertPreference>[
      for (final entry in plan.prefs.entries)
        entry.value.applyTo(currentPrefs[entry.key]!),
    ];

    GlobalAlertSettings? global;
    if (plan.touchesGlobal) {
      final current = await _alerts.getGlobal();
      global = current.copyWith(
        audioOutput: plan.audioOutput,
        quietHours: plan.quietHours,
        clearQuietHours: plan.hasQuietHours && plan.quietHours == null,
        suhoorReminderEnabled: plan.suhoorEnabled,
        suhoorReminderMinutes: plan.suhoorMinutes,
      );
    }

    TasbihSettings? tasbih;
    if (plan.touchesTasbih) {
      tasbih = (await _tasbih.read()).copyWith(
        target: plan.tasbihTarget,
        keepAwake: plan.keepAwake,
        volumeKeys: plan.volumeKeys,
        lock: plan.lock,
        haptics: plan.haptics,
        sound: plan.sound,
      );
    }

    return _Resolved(
      settings: settings,
      location: plan.location,
      prefs: prefs,
      global: global,
      tasbih: tasbih,
      bookmarkIds: plan.bookmarks,
      reminders: plan.reminders,
    );
  }

  /// Runs inside one transaction. Any failure throws, which rolls back
  /// everything written so far.
  Future<void> _apply(_Resolved r) async {
    final now = _clock();
    if (r.settings != null) _check(await _settings.save(r.settings!));
    if (r.location != null) _check(await _location.save(r.location!));
    for (final pref in r.prefs) {
      _check(await _alerts.save(pref));
    }
    if (r.global != null) _check(await _alerts.saveGlobal(r.global!));
    if (r.tasbih != null) await _tasbih.write(r.tasbih!);
    if (r.bookmarkIds != null) {
      // Keep the file's order: each bookmark is a millisecond newer.
      await _bookmarks.replaceAll([
        for (var i = 0; i < r.bookmarkIds!.length; i++)
          AdhkarBookmark(
            entryId: r.bookmarkIds![i],
            createdAt: now.add(Duration(milliseconds: i)),
          ),
      ]);
    }
    if (r.reminders != null) _check(await _reminders.saveAll(r.reminders!));
  }

  static void _check(Result<void> result) {
    final error = result.errorOrNull;
    if (error != null) throw StateError(error.message);
  }

  static String _isoSeconds(DateTime t) =>
      t.toUtc().toIso8601String().replaceFirst(RegExp(r'\.\d+Z$'), 'Z');

  static String _formatMinutes(int minutes) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(minutes ~/ 60)}:${two(minutes % 60)}';
  }
}

/// A problem found while reading the file.
class _Invalid implements Exception {
  const _Invalid(this.kind, this.message, {this.field});

  factory _Invalid.value(String field) => _Invalid(
    ImportFailureKind.invalidValue,
    'A value in the file is missing or out of range.',
    field: field,
  );

  final ImportFailureKind kind;
  final String message;
  final String? field;

  ImportFailure toFailure() => ImportFailure(kind, message, field: field);
}

/// Typed access to JSON objects. Absent or null keys read as null for
/// optional values; a wrong type or a value out of range throws.
class _Reader {
  Map<String, Object?>? optObject(
    Map<String, Object?> json,
    String path,
    String key,
  ) {
    final value = json[key];
    if (value == null) return null;
    if (value is! Map<String, Object?>) throw _Invalid.value(_join(path, key));
    return value;
  }

  T? optEnum<T extends Enum>(
    Map<String, Object?> json,
    String path,
    String key,
    List<T> values,
  ) {
    final value = json[key];
    if (value == null) return null;
    for (final v in values) {
      if (v.name == value) return v;
    }
    throw _Invalid.value(_join(path, key));
  }

  T requireEnum<T extends Enum>(
    Map<String, Object?> json,
    String path,
    String key,
    List<T> values,
  ) =>
      optEnum(json, path, key, values) ??
      (throw _Invalid.value(_join(path, key)));

  int? optInt(
    Map<String, Object?> json,
    String path,
    String key, {
    required int min,
    required int max,
  }) {
    final value = json[key];
    if (value == null) return null;
    if (value is! num || value != value.truncate()) {
      throw _Invalid.value(_join(path, key));
    }
    final n = value.toInt();
    if (n < min || n > max) throw _Invalid.value(_join(path, key));
    return n;
  }

  int requireInt(Map<String, Object?> json, String path, String key) =>
      optInt(json, path, key, min: -1 << 30, max: 1 << 30) ??
      (throw _Invalid.value(_join(path, key)));

  double? optDouble(
    Map<String, Object?> json,
    String path,
    String key, {
    required double min,
    required double max,
  }) {
    final value = json[key];
    if (value == null) return null;
    if (value is! num || value.isNaN) throw _Invalid.value(_join(path, key));
    final d = value.toDouble();
    if (d < min || d > max) throw _Invalid.value(_join(path, key));
    return d;
  }

  double requireDouble(
    Map<String, Object?> json,
    String path,
    String key, {
    required double min,
    required double max,
  }) =>
      optDouble(json, path, key, min: min, max: max) ??
      (throw _Invalid.value(_join(path, key)));

  bool? optBool(Map<String, Object?> json, String path, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is! bool) throw _Invalid.value(_join(path, key));
    return value;
  }

  String? optString(Map<String, Object?> json, String path, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is! String || value.trim().isEmpty) {
      throw _Invalid.value(_join(path, key));
    }
    return value.trim();
  }

  String requireString(Map<String, Object?> json, String path, String key) =>
      optString(json, path, key) ?? (throw _Invalid.value(_join(path, key)));

  List<String>? optStringList(
    Map<String, Object?> json,
    String path,
    String key,
  ) {
    final value = json[key];
    if (value == null) return null;
    if (value is! List<Object?> ||
        value.any((e) => e is! String || e.trim().isEmpty)) {
      throw _Invalid.value(_join(path, key));
    }
    return value.cast<String>().map((e) => e.trim()).toSet().toList();
  }

  /// `HH:MM` as minutes after midnight.
  int requireClock(Map<String, Object?> json, String path, String key) {
    final value = json[key];
    final match = value is String
        ? RegExp(r'^([01]?\d|2[0-3]):([0-5]\d)$').firstMatch(value)
        : null;
    if (match == null) throw _Invalid.value(_join(path, key));
    return int.parse(match.group(1)!) * 60 + int.parse(match.group(2)!);
  }

  static String _join(String path, String key) =>
      path.isEmpty ? key : '$path.$key';
}

/// Everything the file asks to change, validated but not yet merged.
class _Plan {
  AppLanguage? language;
  ThemePreference? theme;
  double? textScale;
  bool? highContrast;
  AppLocation? location;
  engine.CalculationMethod? method;
  engine.AsrMethod? asr;
  engine.HighLatitudeRule? highLatitudeRule;
  final Map<engine.Prayer, int> offsets = {};
  int? imsakMinutes;
  int? hijriAdjustment;

  final Map<AlertPrayer, _PrefPatch> prefs = {};
  AudioOutput? audioOutput;
  bool hasQuietHours = false;
  QuietHours? quietHours;
  bool? suhoorEnabled;
  int? suhoorMinutes;

  int? tasbihTarget;
  bool? keepAwake;
  bool? volumeKeys;
  bool? lock;
  bool? haptics;
  bool? sound;

  List<String>? bookmarks;
  List<AdhkarReminder>? reminders;

  bool get touchesSettings =>
      language != null ||
      theme != null ||
      textScale != null ||
      highContrast != null ||
      method != null ||
      asr != null ||
      highLatitudeRule != null ||
      offsets.isNotEmpty ||
      imsakMinutes != null ||
      hijriAdjustment != null;

  bool get touchesGlobal =>
      audioOutput != null ||
      hasQuietHours ||
      suhoorEnabled != null ||
      suhoorMinutes != null;

  bool get touchesTasbih =>
      tasbihTarget != null ||
      keepAwake != null ||
      volumeKeys != null ||
      lock != null ||
      haptics != null ||
      sound != null;
}

class _PrefPatch {
  const _PrefPatch({
    this.type,
    this.voiceId,
    this.variant,
    this.loudMode,
    this.volumeChoice,
    this.hasPreReminder = false,
    this.preReminderMinutes,
    this.ignoreQuietHours,
  });

  final AlertType? type;
  final String? voiceId;
  final AzaanVariant? variant;
  final bool? loudMode;
  final VolumeChoice? volumeChoice;
  final bool hasPreReminder;
  final int? preReminderMinutes;
  final bool? ignoreQuietHours;

  AlertPreference applyTo(AlertPreference base) => base.copyWith(
    type: type,
    voiceId: voiceId,
    variant: variant,
    loudMode: loudMode,
    volumeChoice: volumeChoice,
    preReminderMinutes: preReminderMinutes,
    clearPreReminder: hasPreReminder && preReminderMinutes == null,
    ignoreQuietHours: ignoreQuietHours,
  );
}

class _Resolved {
  const _Resolved({
    required this.settings,
    required this.location,
    required this.prefs,
    required this.global,
    required this.tasbih,
    required this.bookmarkIds,
    required this.reminders,
  });

  final PrayerSettings? settings;
  final AppLocation? location;
  final List<AlertPreference> prefs;
  final GlobalAlertSettings? global;
  final TasbihSettings? tasbih;
  final List<String>? bookmarkIds;
  final List<AdhkarReminder>? reminders;
}
