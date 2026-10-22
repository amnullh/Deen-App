# Contract: Prayer Engine and Planner Packages (pure Dart)

**Packages**: `packages/prayer_engine`, `packages/schedule_planner`. No Flutter imports and no I/O in either.
Interfaces below are signatures and rules, not implementations.

## prayer_engine

```dart
enum CalculationMethod {
  muslimWorldLeague, isna, egypt, ummAlQura, karachi, tehran, jafari,
  gulf, kuwait, qatar, singapore, diyanet, franceUoif, moonsightingCommittee,
}
enum AsrMethod { standard, hanafi }
enum HighLatitudeRule { middleOfNight, seventhOfNight, angleBased }
enum Prayer { fajr, sunrise, dhuhr, asr, maghrib, isha }

class DayTimes {
  final String localDate;            // YYYY-MM-DD in the location's zone
  final Map<Prayer, DateTime?> times;  // UTC instants; null when the event does not occur (polar)
  final DateTime? imsak, midnight, lastThirdOfNight;
  final List<Notice> notices;          // e.g. highLatitudeRuleApplied, polarNoSunset
}

abstract interface class PrayerTimeEngine {
  DayTimes timesFor({
    required double latitude, required double longitude, required String timeZoneId,
    required String localDate, required CalculationMethod method, required AsrMethod asr,
    required HighLatitudeRule highLatitudeRule, required Map<Prayer, int> offsetsMinutes,
    required int imsakMinutes,
  });
}

CalculationMethod suggestedMethod(String countryCode);        // regional defaults, MWL fallback
HighLatitudeRule defaultHighLatitudeRule(double latitude);    // sensible default above 48 degrees
double qiblaBearing(double latitude, double longitude);       // degrees 0..360, great circle
bool isAtHaram(double latitude, double longitude);            // within the Haram boundary tolerance
HijriDate toHijri(String localDate, {int adjustmentDays = 0}); // Umm al-Qura table, range documented
```

Rules:
- Determinism: same inputs always give the same output. No `DateTime.now()` inside the package.
- Offsets are applied after calculation; they never change which prayer is "next" incorrectly across midnight.
- Polar events that do not occur return null plus a notice; they never throw.
- Accuracy bar: within 1 minute of the oracle for every method, 20 reference cities, 365 days (plan D-3).
- `adhan_dart` is used only inside `AdhanDartEngine`. A method that fails the bar is replaced by an own
  implementation behind the same interface; callers do not change.

## schedule_planner

```dart
class PlannerInput {
  final LocationInput location;           // lat, lon, timeZoneId, countryCode
  final PrayerSettings prayerSettings;
  final List<AlertPreference> alertPreferences;
  final GlobalAlertSettings global;
  final DateTime now;                     // injected
  final PlatformBudget budget;            // android(snapshotDays: 60, renewalDaysBeforeEnd: 7) | ios(maxRequests: 63)
  final OffsetResolver offsets;           // OS offsets when location zone == device zone, bundled tz data otherwise
  final Permissions permissions;          // exactAlarm, notifications
  final String language;
}

List<PlannedAlert> plan(PlannerInput input);   // pure, sorted by fireAt, stable alertIds

String alertId(String kind, String localDate, {bool pre = false});
```

Rules:
- Alert IDs are stable for the same prayer and date across rebuilds, so a rebuild never creates a duplicate.
- Only alerts with `fireAt > now` are returned. Quiet-hours and permission downgrades are applied here, not in
  platform code.
- iOS budget: sort by `fireAt`; keep the nearest 62 alerts; the 63rd request is a `renewal` alert placed at the
  last kept alert's date. Android: all alerts within 60 local days plus a `renewal` alert about 7 days before the
  end; native keeps only the next 14 days registered (see platform-scheduling.md).
- Quiet hours: an audible alert whose `fireAt` falls inside quiet hours is delivered as `silent` unless the prayer's
  `ignoreQuietHours` is true; the planner marks the reason so the Reliability check shows "silenced by quiet hours".
- Exact-alarm denied (Android): alerts are marked `preciseAllowed=false`.
- Reminders tied to an anchor (pre-prayer, suhoor, adhkar) are computed from the same `DayTimes` as the prayer.

## Alert arbiter

```dart
abstract interface class PlaybackLedger {
  bool hasPlayed(String alertId);
  void markPlayed(String alertId, DateTime at);
}

enum ArbiterDecision { play, skipAlreadyPlayed, skipSuppressed }
ArbiterDecision decide(String alertId, PlaybackLedger ledger, {required bool suppressed});
```

Rules: one `play` per alertId; `markPlayed` is called by the caller after playback starts, never by `decide`.
The same rule is implemented in Kotlin for alarm time. Both are tested against `test_vectors/arbiter.json`.

## Test vectors (shared)

`packages/schedule_planner/test_vectors/` holds JSON used by both Dart tests and Android instrumented tests:
arbiter cases, alert ID cases, and DST and clock-change planning cases. Platform code that reimplements a rule
MUST pass the same vectors.
