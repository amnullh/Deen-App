# schedule_planner

Pure Dart (no Flutter, no I/O, no system clock) alert planner, alert IDs, recording mapping and the alert arbiter.
Contract: `specs/001-offline-worship-app/contracts/prayer-engine-api.md` (schedule_planner section).
Shared test vectors for Dart and Android: [`test_vectors/README.md`](test_vectors/README.md).

```dart
import 'package:schedule_planner/schedule_planner.dart';
```

All type names are prefixed (`Planner...`, `Planned...`) so the package can be imported next to the app's own
entities without clashes. The app maps its entities to these inputs (field names match the app's where they exist).

## Plan

```dart
List<PlannedAlert> plan(PlannerInput input);
```

Pure and deterministic. Returns only alerts with `fireAt > input.now`, sorted by `fireAt` (ties by `alertId`),
already downgraded for quiet hours and permissions, and cut to the platform budget.

### Input

```dart
class PlannerInput {
  PlannerLocation location;                    // latitude, longitude, timeZoneId, countryCode
  PlannerPrayerSettings prayerSettings;        // method, asr, highLatitudeRule, offsetsMinutes, imsakMinutes
  List<PlannerAlertPreference> alertPreferences; // one per prayer: fajr, dhuhr, asr, maghrib, isha
  PlannerGlobalSettings global;                // quietHours, suhoorReminderEnabled/Minutes, adhkarReminders
  DateTime now;                                // injected; never read from the clock
  PlatformBudget budget;                       // PlatformBudget.android() | PlatformBudget.ios()
  OffsetResolver offsets;                      // from prayer_engine; decides local dates and quiet hours
  PrayerTimeEngine engine;                     // from prayer_engine, injected
  PlannerPermissions permissions;              // exactAlarm, notifications (default unknown)
  String language;                             // carried, does not change the plan
  bool Function(String localDate) isRamadan;   // injected; default: never
}

class PlannerAlertPreference {
  Prayer prayer;                 // fajr, dhuhr, asr, maghrib, isha (sunrise ignored; missing prayer = off)
  PlannerAlertType type;         // off, silent, vibrate, shortTone, fullAzaan
  String voiceId;
  PlannerAzaanVariant variant;   // standard, shia
  bool loudMode;
  PlannerVolumeChoice volumeChoice; // keepCurrent, gentleRamp
  int? preReminderMinutes;       // null = none
  bool ignoreQuietHours;
}

class PlannerQuietHours { int startMinutes, endMinutes; }   // local minutes after midnight, may cross midnight
class PlannerAdhkarReminder { PlannerAdhkarKind kind; PlannerAdhkarAnchor anchor; int offsetMinutes; bool enabled; }
// morning -> anchor fajr; evening -> anchor asr or maghrib; offsetMinutes is minutes AFTER the anchor (negative = before)
class PlannerPermissions { PlannerPermission exactAlarm, notifications; }   // unknown | granted | denied
PlatformBudget.android({snapshotDays = 60, renewalDaysBeforeEnd = 7});  // renewalDaysBeforeEnd 0 = no renewal alert
PlatformBudget.ios({maxRequests = 63});
```

### Output

```dart
class PlannedAlert {
  String alertId;                // fajr:2026-10-22, fajr:2026-10-22:pre, suhoor:..., adhkar-morning:..., renewal:...
  PlannedAlertKind kind;         // prayer, preReminder, suhoor, adhkarReminder, renewal
  String localDate;              // YYYY-MM-DD in the location's zone
  DateTime fireAt;               // absolute UTC instant
  PlannedDelivery deliveryType;  // silent, vibrate, shortTone, fullAzaan, renewal (after all downgrades)
  int priority;                  // index in the final list; lower is nearer
  bool preciseAllowed;           // false when Android exact alarms are denied
  String messageKey;             // alert.prayer.<p>, alert.preReminder.<p>, alert.suhoor,
                                 // alert.adhkar.morning|evening, alert.renewal  (app localizes title and body)
  Prayer? prayer;                // prayer behind the alert (fajr for suhoor, anchor for adhkar, null for renewal)
  int? leadMinutes;              // minutes before the prayer, for pre-reminder and suhoor text
  String? audioRef;              // full Azaan: <voice>-fajr | <voice>-standard | <voice>-shia; short tone: tone-short
  String? voiceId;               // full Azaan only
  PlannerAzaanVariant? variant;  // full Azaan only
  bool loudMode; PlannerVolumeChoice volumeChoice;   // only for audible prayer alerts
  List<PlannedReason> reasons;   // silencedByQuietHours, inexactAlarm, notificationsDenied, reminderUsesShortTone
  Map<String, Object?> toJson();  PlannedAlert.fromJson(Map<String, Object?>);   // snapshot persistence
}
```

### Rules the caller can rely on

- Alert IDs are stable for the same prayer and local date, so a rebuild never creates a duplicate.
- Quiet hours are evaluated in the location's local time (offset from `input.offsets`, so DST is respected).
  An audible alert (`shortTone`, `fullAzaan`) inside quiet hours becomes `silent` with reason
  `silencedByQuietHours`, unless that prayer's `ignoreQuietHours` is true. Reminders use their prayer's flag.
- Reminders (pre-prayer, suhoor, adhkar) never use a full Azaan: `fullAzaan` becomes `shortTone` (reason
  `reminderUsesShortTone`, omitted when quiet hours silence it anyway). A pre-reminder for a prayer set to `off` is not planned. Suhoor and adhkar reminders are
  their own opt-in: if their prayer is `off` they use `shortTone`.
- Suhoor: `suhoorReminderMinutes` before Fajr, only on dates where `isRamadan(fajrLocalDate)` is true.
- Events that do not occur (polar days, `DayTimes.times[p] == null`) are skipped with their reminders.
- Exact alarm denied on Android: every alert has `preciseAllowed=false` and reason `inexactAlarm`. Notifications
  denied: alerts are still planned, with reason `notificationsDenied`.
- Android: local days `d0 .. d0+snapshotDays-1` (d0 = today in the location's zone) plus one `renewal` alert on
  local date `d0 + snapshotDays - renewalDaysBeforeEnd` at 09:00 local. Native keeps the first 14 days registered.
- iOS: the nearest `maxRequests - 1` alerts, plus a `renewal` alert one minute after the last kept alert, with that
  alert's local date in its id. So the list has at most `maxRequests` items.
- No renewal alert is planned when nothing else is planned, or when the renewal time is not after `now`.
- `deliveryType == renewal` is the "open the app" notice; `audioRef` is null.

## Other public API

```dart
String alertId(String kind, String localDate, {bool pre = false});   // throws ArgumentError on bad input
ParsedAlertId? parseAlertId(String id);                               // kind, localDate, pre; null if malformed
const List<Prayer> alertPrayers;                                       // fajr, dhuhr, asr, maghrib, isha

String recordingId({required String voiceId, required PlannerAzaanVariant variant, required Prayer prayer});
const String shortToneId;                                              // 'tone-short'
PlannerAlertType reminderType(PlannerAlertType prayerType);            // fullAzaan -> shortTone
PlannerAlertType standaloneReminderType(PlannerAlertType prayerType);  // reminderType, and off -> shortTone

abstract interface class PlaybackLedger { bool hasPlayed(String id); void markPlayed(String id, DateTime at); }
enum ArbiterDecision { play, skipAlreadyPlayed, skipSuppressed }
ArbiterDecision decide(String alertId, PlaybackLedger ledger, {required bool suppressed});
class InMemoryPlaybackLedger implements PlaybackLedger { ... }
```

`decide` order: already played wins over suppressed. It never writes to the ledger; call `markPlayed` after
playback starts.

## Tests

`dart test` in this folder. The planner tests run against a fake engine (fixed local times) so they are exact, plus
a small smoke test against the real `AdhanDartEngine`.
