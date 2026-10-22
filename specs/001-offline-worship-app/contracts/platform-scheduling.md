# Contract: Platform Scheduling and Playback (Pigeon)

**Definitions live in**: `apps/mobile/pigeons/scheduling.dart` (generated to Dart, Kotlin, Swift).
Citations for every platform claim are in [research.md](../research.md). Signatures below are the contract;
bodies are implementation.

## Common types

```dart
class ScheduledAlert {
  String alertId;            // stable id from the planner
  int fireAtEpochMs;         // absolute instant
  AlertKind kind;            // prayer, preReminder, suhoor, adhkarReminder, renewal
  DeliveryType delivery;     // silent, vibrate, shortTone, fullAzaan
  String? audioRef;          // bundled asset key; native resolves it
  String title; String body; String stopLabel;   // already localized
  bool loudMode; VolumeChoice volumeChoice;      // Android only
  bool preciseAllowed;       // false when exact alarms are not allowed (inexact fallback)
}

class JournalEntry {
  String alertId; int plannedAtEpochMs; int? firedAtEpochMs;
  JournalState state;        // fired, played, acknowledged, suppressed, failed
  String? cause;             // see data-model cause enum
}
```

## SchedulerApi (Dart calls native) and AlertScheduler (Dart interface)

The Dart `AlertScheduler` interface has two implementations. On Android it is the Pigeon `SchedulerApi` below,
implemented natively in Kotlin. On iOS it is `IosAlertScheduler`, written in Dart on top of
`flutter_local_notifications` (no Swift scheduler); the iOS column describes the behavior that implementation must
provide. Notification permission is requested with `permission_handler` on both platforms, so the Android
`requestNotificationPermission` and iOS equivalents delegate to it. The exact-alarm permission is Android-only.

| Method | Android | iOS | Notes |
|--------|---------|-----|-------|
| `replaceSchedule(List<ScheduledAlert>)` | persists the full snapshot (about 60 days) to device-protected storage, cancels all registered alarms, registers the first 14 days | cancels pending requests, adds requests (max 63) | Atomic from the caller's view: after it returns, only the new set is pending. Idempotent. |
| `scheduleTestAlert(delaySeconds, delivery)` | registers a one-off alarm | schedules one request | Used by "send a test Azaan in 1 minute". |
| `getPermissionState()` | notifications, exactAlarm, batteryOptimizationIgnored | notifications, soundEnabled | Read on every launch. |
| `requestNotificationPermission()` | runtime request (Android 13+) | `requestAuthorization` | Called only after the app explained why. |
| `openExactAlarmSettings()` | `ACTION_REQUEST_SCHEDULE_EXACT_ALARM` | not applicable | Called only when the user turns on a full Azaan or reminder. |
| `openBatterySettings()` | `ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS` | not applicable | Never requests the ignore permission. |
| `openAppNotificationSettings()` | app notification settings | app settings | "Way back to the permission". |
| `readJournal(sinceEpochMs)` | returns entries from `journal.log` | returns inferred entries (pending diff, delivered list) | iOS entries have source `iosInferred`. |
| `clearJournal()` | clears after import | no-op | Called after the app imports entries. |
| `getPendingSummary()` | registered alarm count, next 5 | pending requests, next 5 | Feeds the Reliability check. |

Guarantees (Android):
- Window top-up: native keeps the next 14 days registered. Each time an alarm fires, and on every system event
  below, it registers the next missing days from the snapshot. The Reliability check reads `scheduleRunsUntil`
  from the snapshot's last alert. The `renewal` alert in the snapshot posts the "open the app" notice about 7 days
  before the snapshot ends.
- Exact alarms denied: alerts are registered inexactly with `preciseAllowed=false` and journaled as such.
- At alarm time with the app not running, the native receiver: checks the journal for `played` on this alertId
  (arbiter rule), starts `AzaanPlaybackService` for `fullAzaan` or posts a notification for other types, and
  appends a journal entry. No Dart code runs.
- On LOCKED_BOOT_COMPLETED, BOOT_COMPLETED, TIME_SET, TIMEZONE_CHANGED, MY_PACKAGE_REPLACED and the exact-alarm
  permission-state-changed broadcast, the snapshot is re-registered. The boot receiver never starts the
  service (Android 15 restriction).
- If the service start throws, the receiver posts a notification whose channel sound is the Azaan and journals
  `failed` with cause `fgs_blocked`.
- Channels: `tone_v1`, `silent_v1`, `vibrate_v1`, `reminder_v1`, `renewal_v1`, `playback_v1` (service
  notification, silent), and `azaan_v1_<voice>_<variant>` for the fallback. A changed sound uses a new version
  suffix; channels are never edited.
- Notification action "Stop / Acknowledge" stops playback, restores audio focus and journals `acknowledged`.
- Audio attributes: `USAGE_ALARM` only when `loudMode` is true; otherwise `USAGE_NOTIFICATION`. Focus is requested
  as transient gain after `startForeground`. An incoming call (focus loss) pauses playback and triggers a
  vibration instead; the journal records `suppressed:call_in_progress`.
- The service never changes system stream volume. With `gentleRamp` it ramps the player's own volume from 0.2 to
  1.0 over 8 seconds (proposed values, to be tuned on devices); `keepCurrent` plays at the current stream
  volume without ramping.

Guarantees (iOS):
- All requests are non-repeating calendar triggers with explicit date components and `timeZone`
  (spike S2 may switch to time-interval triggers; the interface does not change).
- Notification sounds are bundled clips shorter than 30 seconds; `fullAzaan` requests carry the clip and the
  `alertId` in the payload.
- A tap opens the app and the Dart layer calls `PlaybackApi.playFullAzaan(alertId)`.

## PlaybackApi (in-app playback)

| Method | Behavior |
|--------|----------|
| `playFullAzaan(alertId, audioRef)` | Checks the arbiter and ledger first; configures `.playback` session (iOS) or in-app player (Android); records `played` |
| `preview(audioRef)` / `stopPreview()` | Preview in the voice list; previews do not count as played |
| `stop()` | Stops any playback and releases audio focus or session |

Interruptions (iOS calls, Siri, other audio) pause playback and journal `suppressed`.

## Events (native to Dart)

| Event | Payload | Used for |
|-------|---------|----------|
| `onPermissionChanged` | permission state | refresh Reliability check, trigger `replaceSchedule` |
| `onNotificationTapped` | alertId | iOS tap-to-play, Android open app |
| `onRefreshWindow` | none | iOS `BGAppRefreshTask` fired: rebuild schedule |

## Error handling

All methods return a typed result with an error code: `permission_denied`, `exact_alarm_denied`,
`service_start_blocked`, `budget_exceeded`, `invalid_argument`. The Reliability check maps each code to a plain
fix message. Native code never throws across the channel.
