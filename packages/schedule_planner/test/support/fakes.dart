import 'dart:convert';
import 'dart:io';

import 'package:prayer_engine/prayer_engine.dart';
import 'package:schedule_planner/schedule_planner.dart';

/// Reads a JSON file from `test_vectors/` (tests run from the package root).
Map<String, Object?> loadVector(String name) {
  final text = File('test_vectors/$name').readAsStringSync();
  return jsonDecode(text) as Map<String, Object?>;
}

/// A zone whose offset steps at known instants (for DST and clock changes).
class StepOffsetResolver implements OffsetResolver {
  StepOffsetResolver(this.initialMinutes, [this.changes = const []]);

  final int initialMinutes;

  /// `(atUtc, offsetMinutes)` in ascending order.
  final List<(DateTime, int)> changes;

  int minutesAt(DateTime utc) {
    var minutes = initialMinutes;
    for (final (at, m) in changes) {
      if (!utc.isBefore(at)) minutes = m;
    }
    return minutes;
  }

  Set<int> get allOffsets => {initialMinutes, for (final (_, m) in changes) m};

  @override
  Duration offsetAt(String timeZoneId, DateTime utcInstant) =>
      Duration(minutes: minutesAt(utcInstant.toUtc()));
}

/// A prayer engine whose every day has the same local clock times. It converts
/// local clock time to UTC with its own simple search over the zone's offsets,
/// so it does not share code with the planner.
class FakeDayEngine implements PrayerTimeEngine {
  FakeDayEngine(
    this.zone, {
    Map<Prayer, String?>? localTimes,
    this.overrides = const {},
  }) : localTimes =
           localTimes ??
           const {
             Prayer.fajr: '05:00',
             Prayer.sunrise: '06:30',
             Prayer.dhuhr: '12:00',
             Prayer.asr: '15:30',
             Prayer.maghrib: '18:00',
             Prayer.isha: '19:30',
           };

  final StepOffsetResolver zone;
  final Map<Prayer, String?> localTimes;

  /// Per local date, replacements for single prayers (null = does not occur).
  final Map<String, Map<Prayer, String?>> overrides;

  int calls = 0;

  DateTime? _toUtc(String localDate, String? hhmm) {
    if (hhmm == null) return null;
    final d = localDate.split('-').map(int.parse).toList();
    final t = hhmm.split(':').map(int.parse).toList();
    final naive = DateTime.utc(d[0], d[1], d[2], t[0], t[1]);
    for (final offset in zone.allOffsets) {
      final candidate = naive.subtract(Duration(minutes: offset));
      if (zone.minutesAt(candidate) == offset) return candidate;
    }
    throw StateError('No valid instant for $localDate $hhmm');
  }

  @override
  DayTimes timesFor({
    required double latitude,
    required double longitude,
    required String timeZoneId,
    required String localDate,
    required CalculationMethod method,
    required AsrMethod asr,
    required HighLatitudeRule highLatitudeRule,
    required Map<Prayer, int> offsetsMinutes,
    required int imsakMinutes,
  }) {
    calls++;
    final day = {...localTimes, ...?overrides[localDate]};
    return DayTimes(
      localDate: localDate,
      times: {for (final p in Prayer.values) p: _toUtc(localDate, day[p])},
    );
  }
}

const PlannerLocation testLocation = PlannerLocation(
  latitude: 21.42,
  longitude: 39.83,
  timeZoneId: 'Etc/UTC',
  countryCode: 'SA',
);

const PlannerPrayerSettings testPrayerSettings = PlannerPrayerSettings(
  method: CalculationMethod.ummAlQura,
);

PlannerAlertPreference pref(
  Prayer prayer, {
  PlannerAlertType type = PlannerAlertType.shortTone,
  String voiceId = 'voice-1',
  PlannerAzaanVariant variant = PlannerAzaanVariant.standard,
  bool loudMode = false,
  PlannerVolumeChoice volumeChoice = PlannerVolumeChoice.keepCurrent,
  int? preReminderMinutes,
  bool ignoreQuietHours = false,
}) => PlannerAlertPreference(
  prayer: prayer,
  type: type,
  voiceId: voiceId,
  variant: variant,
  loudMode: loudMode,
  volumeChoice: volumeChoice,
  preReminderMinutes: preReminderMinutes,
  ignoreQuietHours: ignoreQuietHours,
);

/// All five prayers with the same type.
List<PlannerAlertPreference> allPrayers({
  PlannerAlertType type = PlannerAlertType.shortTone,
  int? preReminderMinutes,
}) => [
  for (final p in alertPrayers)
    pref(p, type: type, preReminderMinutes: preReminderMinutes),
];

/// A planner input over a UTC-zone fake engine with sensible defaults.
PlannerInput buildInput({
  required DateTime now,
  List<PlannerAlertPreference>? prefs,
  PlannerGlobalSettings global = const PlannerGlobalSettings(),
  PlatformBudget budget = const PlatformBudget.android(
    snapshotDays: 3,
    renewalDaysBeforeEnd: 1,
  ),
  PlannerPermissions permissions = const PlannerPermissions(),
  bool Function(String)? isRamadan,
  StepOffsetResolver? zone,
  FakeDayEngine? engine,
  PlannerLocation location = testLocation,
}) {
  final z = zone ?? StepOffsetResolver(0);
  return PlannerInput(
    location: location,
    prayerSettings: testPrayerSettings,
    alertPreferences: prefs ?? allPrayers(),
    global: global,
    now: now,
    budget: budget,
    offsets: z,
    engine: engine ?? FakeDayEngine(z),
    permissions: permissions,
    isRamadan: isRamadan ?? (_) => false,
  );
}

Prayer _prayer(String name) => Prayer.values.byName(name);

/// Builds a planner input from a `planning/1` vector case.
PlannerInput inputFromVector(Map<String, Object?> input) {
  final loc = input['location']! as Map<String, Object?>;
  final zoneJson = input['zone']! as Map<String, Object?>;
  final zone = StepOffsetResolver(zoneJson['initialOffsetMinutes']! as int, [
    for (final c in zoneJson['changes']! as List<Object?>)
      (
        DateTime.parse((c! as Map)['atUtc'] as String),
        (c as Map)['offsetMinutes'] as int,
      ),
  ]);
  final localTimes = <Prayer, String?>{
    for (final e in (input['localTimes']! as Map<String, Object?>).entries)
      _prayer(e.key): e.value as String?,
  };
  final overrides = <String, Map<Prayer, String?>>{
    for (final e
        in ((input['dayOverrides'] ?? <String, Object?>{})
                as Map<String, Object?>)
            .entries)
      e.key: {
        for (final p in (e.value! as Map<String, Object?>).entries)
          _prayer(p.key): p.value as String?,
      },
  };
  final budgetJson = input['budget']! as Map<String, Object?>;
  final budget = budgetJson['platform'] == 'ios'
      ? PlatformBudget.ios(maxRequests: budgetJson['maxRequests']! as int)
      : PlatformBudget.android(
          snapshotDays: budgetJson['snapshotDays']! as int,
          renewalDaysBeforeEnd: budgetJson['renewalDaysBeforeEnd']! as int,
        );
  final quiet = input['quietHours'] as Map<String, Object?>?;
  final suhoor = input['suhoor'] as Map<String, Object?>?;
  final permissions =
      (input['permissions'] ?? <String, Object?>{}) as Map<String, Object?>;
  PlannerPermission perm(String? name) => name == null
      ? PlannerPermission.unknown
      : PlannerPermission.values.byName(name);
  final ramadan = {
    for (final d in (input['ramadanDates'] ?? <Object?>[]) as List<Object?>)
      d! as String,
  };
  return PlannerInput(
    location: PlannerLocation(
      latitude: (loc['latitude']! as num).toDouble(),
      longitude: (loc['longitude']! as num).toDouble(),
      timeZoneId: loc['timeZoneId']! as String,
      countryCode: loc['countryCode']! as String,
    ),
    prayerSettings: testPrayerSettings,
    alertPreferences: [
      for (final p in input['alertPreferences']! as List<Object?>)
        _prefFromJson(p! as Map<String, Object?>),
    ],
    global: PlannerGlobalSettings(
      quietHours: quiet == null
          ? null
          : PlannerQuietHours(
              startMinutes: quiet['startMinutes']! as int,
              endMinutes: quiet['endMinutes']! as int,
            ),
      suhoorReminderEnabled: suhoor?['enabled'] as bool? ?? false,
      suhoorReminderMinutes: suhoor?['minutes'] as int? ?? 30,
      adhkarReminders: [
        for (final raw
            in (input['adhkarReminders'] ?? <Object?>[]) as List<Object?>)
          _adhkarFromJson(raw! as Map<String, Object?>),
      ],
    ),
    now: DateTime.parse(input['now']! as String),
    budget: budget,
    offsets: zone,
    engine: FakeDayEngine(zone, localTimes: localTimes, overrides: overrides),
    permissions: PlannerPermissions(
      exactAlarm: perm(permissions['exactAlarm'] as String?),
      notifications: perm(permissions['notifications'] as String?),
    ),
    isRamadan: ramadan.contains,
  );
}

PlannerAlertPreference _prefFromJson(Map<String, Object?> j) => pref(
  _prayer(j['prayer']! as String),
  type: PlannerAlertType.values.byName(j['type']! as String),
  voiceId: j['voiceId'] as String? ?? 'voice-1',
  variant: PlannerAzaanVariant.values.byName(
    j['variant'] as String? ?? 'standard',
  ),
  loudMode: j['loudMode'] as bool? ?? false,
  volumeChoice: PlannerVolumeChoice.values.byName(
    j['volumeChoice'] as String? ?? 'keepCurrent',
  ),
  preReminderMinutes: j['preReminderMinutes'] as int?,
  ignoreQuietHours: j['ignoreQuietHours'] as bool? ?? false,
);

PlannerAdhkarReminder _adhkarFromJson(Map<String, Object?> j) =>
    PlannerAdhkarReminder(
      kind: PlannerAdhkarKind.values.byName(j['kind']! as String),
      anchor: PlannerAdhkarAnchor.values.byName(j['anchor']! as String),
      offsetMinutes: j['offsetMinutes']! as int,
      enabled: j['enabled'] as bool? ?? true,
    );
