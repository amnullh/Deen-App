# Research: Offline Worship App (Phase 0)

**Date**: 2026-10-21 | **Plan**: [plan.md](plan.md)

Evidence tags: **VERIFIED** = the cited official page was fetched and says it. **PARTIAL** = page read but the
specific point is an inference. **UNVERIFIED** = memory, a forum, or an unreachable page; must be confirmed on a
real device or in the store console before the feature relies on it. The constitution (principle 2) requires
every platform claim to carry a citation; this file is that record.

All research was done on 2026-10-21 by reading the sources directly. Nothing here was run on a device.

## 1. Android decisions

### R-A1. Exact alarm permission: SCHEDULE_EXACT_ALARM

- **Decision**: declare `SCHEDULE_EXACT_ALARM` (user-granted). Do not declare `USE_EXACT_ALARM`. Request it in
  setup (after a plain explanation) because every prayer starts as an audible short tone, and again whenever the
  user turns on an audible alert or reminder while it is not granted (spec clarification, second session).
  Without it, the Android planner marks alerts `preciseAllowed=false` and the Reliability check says so (spike S11).
- **Rationale**:
  - `USE_EXACT_ALARM` is auto-granted and cannot be revoked, but is limited by Play policy to apps whose core
    function is an exact alarm; "alarm or timer apps, and calendar apps that show event notifications" are the
    examples. A prayer app is not named. Declared apps are reviewed and non-qualifying apps can be barred from
    publishing. Treated as a review risk. (PARTIAL)
  - `SCHEDULE_EXACT_ALARM` is the route for everyone else, and it matches clarification D5: ask only when the
    user turns on a full Azaan or a reminder, deep link to the setting, fall back to inexact if refused.
  - On Android 14+ it is denied by default for new installs targeting 13+. On Android 13 and lower it is
    pre-granted. Revoking it cancels all future exact alarms, so the app re-checks on every launch and on the
    permission-state-changed broadcast. (VERIFIED)
- **Alternatives**: `USE_EXACT_ALARM` (rejected: review risk; may be revisited if Play accepts the justification).
- **Citations**:
  - https://developer.android.com/develop/background-work/services/alarms/schedule (VERIFIED)
  - https://developer.android.com/about/versions/14/changes/schedule-exact-alarms (VERIFIED)
  - https://support.google.com/googleplay/android-developer/answer/9888170 (PARTIAL)
  - https://support.google.com/googleplay/android-developer/answer/16558241 (PARTIAL)

### R-A2. Alarm type: setAlarmClock for prayer-time alerts, setExactAndAllowWhileIdle for reminders

- **Finding that contradicts the brief's assumption**: the docs list `setAlarmClock()` as needing the permission
  too. The idea that it needs none is not supported. (VERIFIED, Android 14 page)
- **Decision**: use `setAlarmClock` for the audible prayer-time alert and `setExactAndAllowWhileIdle` for
  reminders, subject to spike S7. If the status-bar alarm icon or "next alarm" display is unacceptable, use
  `setExactAndAllowWhileIdle` for everything.
- **Rationale**: `setAlarmClock` alarms keep firing normally in Doze and are never time-adjusted; the system exits
  Doze before they fire. `setExactAndAllowWhileIdle` is limited to about once per 9 minutes per app in Doze, so a
  5-minute pre-prayer reminder can be delayed. (VERIFIED, doze-standby page)
- **Open**: the alarm-icon side effect is UNVERIFIED (reference page truncated). Test on devices (S7).
- **Citations**: https://developer.android.com/training/monitoring-device-state/doze-standby (VERIFIED)

### R-A3. Foreground service for the full Azaan

- **Decision**: the alarm receiver starts a native `AzaanPlaybackService` (`foregroundServiceType="mediaPlayback"`)
  that plays with `MediaPlayer`, with no Dart engine involved. Declare `FOREGROUND_SERVICE` and
  `FOREGROUND_SERVICE_MEDIA_PLAYBACK` (normal permissions, auto-granted). (VERIFIED)
- **Background-start exemption**: "Your app invokes an exact alarm to complete an action that the user requests"
  is on the exemption list. The page does not say which alarm API qualifies and does not mention
  `setAlarmClock`. Receiving TIMEZONE_CHANGED, TIME_CHANGED, BOOT_COMPLETED and MY_PACKAGE_REPLACED is also
  listed. (VERIFIED, applicability to our case PARTIAL; spike S1)
- **Android 15**: apps targeting 35+ may not start a `mediaPlayback` service from a BOOT_COMPLETED receiver
  (throws `ForegroundServiceStartNotAllowedException`). Plan: the boot receiver only re-registers alarms; the
  service starts only from the alarm receiver. (VERIFIED)
- **Fallback**: if the service cannot start, post a notification on a channel whose sound is the bundled Azaan
  (channel audio attributes `USAGE_ALARM` only if loud mode is on), and record `failed:fgs_blocked` in the journal.
- **Timeouts**: the documented 6-hour timeout covers only `dataSync` and `mediaProcessing`. `mediaPlayback` is
  not named; "no timeout" is an inference. An Azaan lasts minutes. (PARTIAL)
- **Play Console**: a foreground-service declaration with description, user impact and a video is required.
  The video must show a user-initiated start; autoplaying audio does not qualify. An alarm-triggered Azaan is not
  user-initiated at play time, so frame it as a user-scheduled alert and expect review friction. (VERIFIED, risk
  assessment is ours)
- **Citations**:
  - https://developer.android.com/develop/background-work/services/fgs/restrictions-bg-start (VERIFIED)
  - https://developer.android.com/about/versions/15/behavior-changes-15 (VERIFIED)
  - https://developer.android.com/develop/background-work/services/fgs/service-types (VERIFIED)
  - https://developer.android.com/about/versions/14/changes/fgs-types-required (VERIFIED)
  - https://developer.android.com/develop/background-work/services/fgs/timeout (PARTIAL)
  - https://support.google.com/googleplay/android-developer/answer/13392821 (VERIFIED)
  - https://support.google.com/googleplay/android-developer/answer/16965181 (VERIFIED)

### R-A4. Battery optimization: settings link only

- **Decision**: link to the system battery-optimization settings list and OEM guidance screens. Do not request
  `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`.
- **Rationale**: `ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS` ("most apps can use this") needs no permission.
  The direct request is allowed only when the core function is adversely affected; the documented acceptable
  cases (chat or calling apps that cannot use FCM, safety apps, task automation, companion apps) do not include
  prayer apps, and Play's policy reads "Don't bypass System power management unless eligible". A user who
  allowlists the app also gains background-start and exact-alarm exemptions. (VERIFIED)
- **OEM screens** (Xiaomi, Oppo, Vivo, Huawei, Samsung, OnePlus): write our own guidance and verify the steps on
  our devices; do not copy third-party text without a license.
- **Citations**: https://developer.android.com/training/monitoring-device-state/doze-standby (VERIFIED);
  https://support.google.com/googleplay/android-developer/answer/9888379 (VERIFIED, does not name the permission)

### R-A5. Rescheduling and what survives

- **Decision**: native receivers re-register alarms from a device-protected snapshot on LOCKED_BOOT_COMPLETED
  (with `directBootAware`), BOOT_COMPLETED, TIME_SET, TIMEZONE_CHANGED, MY_PACKAGE_REPLACED and the
  exact-alarm permission-state broadcast. The Dart app also rebuilds the whole schedule on every launch.
- **Facts**: alarms are cancelled on shutdown. BOOT_COMPLETED and LOCKED_BOOT_COMPLETED, TIMEZONE_CHANGED and
  TIME_SET are exempt from implicit-broadcast limits. Boot receivers only work after the user has launched the
  app once. Direct boot requires device-protected storage. (VERIFIED)
- **Unverified, so we do not rely on them**: whether alarms survive an app update (reschedule regardless), and
  what force-stop does. The Task Manager "Stop" button on Android 13+ is documented as leaving alarms to fire,
  which contradicts a blanket "stop clears alarms" assumption. (VERIFIED for Task Manager only)
- **Messaging consequence**: the Reliability check explains that after force-stop, reboot or update, reliability
  depends on the app having rescheduled, and shows the schedule's last rebuild time.
- **Horizon and top-up (spec scenario 10a)**: the planner produces a 60-day snapshot. Native code keeps only the
  next 14 days registered (about 70 alarms with five prayers, about 190 with every reminder on) and, each time an
  alarm fires or a system event arrives, registers the next missing days from the snapshot. This keeps the count
  far from any per-app alarm limit. That limit is not stated on the pages read (UNVERIFIED), so spike S10 records
  the real number per device. A `renewal` notification is scheduled about 7 days before the snapshot ends.
- **Why prayer instants are stable**: planned instants are absolute (location-based). A device time zone change
  does not move them, so receivers only re-register the snapshot. Recomputation for a new location happens when
  the app next runs.
- **Citations**: alarms/schedule page; https://developer.android.com/develop/background-work/background-tasks/broadcasts/broadcast-exceptions;
  https://developer.android.com/privacy-and-security/direct-boot;
  https://developer.android.com/develop/background-work/services/fgs/handle-user-stopping (all VERIFIED)

### R-A6. Audio, notifications, full-screen intent

- **Audio focus and calls**: use `AUDIOFOCUS_GAIN_TRANSIENT`; no phone-state permission is mentioned in the
  docs, so `READ_PHONE_STATE` is not needed. Apps targeting 35 can request focus only when top app or running a
  foreground service, so request after `startForeground()`. (VERIFIED)
- **USAGE_ALARM vs USAGE_NOTIFICATION vs USAGE_MEDIA with ringer silent and Do Not Disturb**: UNVERIFIED. The
  common belief is that the alarm stream is not silenced by ringer mode and alarms pass DND by default. Spike S6.
- **POST_NOTIFICATIONS**: runtime permission on Android 13+, off by default for new installs. Alarm notifications
  are not exempt. If denied, the foreground-service notification is hidden from the drawer but still shown in the
  Task Manager. (VERIFIED)
- **Channels are immutable** for sound and importance once created. Use channel IDs that include a version and
  the voice (`azaan_v1_<voice>_<version>`); changing a sound means a new channel. (VERIFIED)
- **USE_FULL_SCREEN_INTENT**: limited to calling and alarm apps, and Play restricts it. Not needed. Skip. (VERIFIED)
- **Citations**: https://developer.android.com/media/optimize/audio-focus;
  https://developer.android.com/develop/ui/views/notifications/notification-permission;
  https://developer.android.com/develop/ui/views/notifications/channels;
  https://developer.android.com/about/versions/14/behavior-changes-14 (VERIFIED)

### R-A7. Play Data safety

"Collect" means transmitting data off the device. Data processed only on device need not be disclosed, so
on-device location does not need declaring. The form and a privacy-policy URL are still required. Any
third-party SDK that sends data off device counts as collection, which is another reason for the plan's
no-trackers rule. (VERIFIED) https://support.google.com/googleplay/android-developer/answer/10787469

## 2. iOS decisions

### R-I1. Scheduling: non-repeating calendar requests, rebuilt often

- **Decision**: one non-repeating `UNCalendarNotificationTrigger` per alert, built from fully specified
  year/month/day/hour/minute/second components with an explicit `timeZone`. Rebuild the entire schedule on every
  foreground, on time-zone change and on significant time change. No repeating triggers (prayer times drift).
- **Why not rely on the docs**: Apple's calendar-trigger page says nothing about time zones, and a forum thread
  disagrees with itself on whether a trigger follows local time after a zone change. Only the deprecated
  `UILocalNotification.timeZone` page documents absolute vs wall-clock behavior. (VERIFIED for those pages;
  modern behavior UNVERIFIED, spike S2)
- **Fallback**: `UNTimeIntervalNotificationTrigger` (fire date minus now), recomputed on each reschedule.
- **Citations**: https://developer.apple.com/documentation/usernotifications/uncalendarnotificationtrigger;
  https://developer.apple.com/documentation/uikit/uilocalnotification/timezone;
  https://developer.apple.com/forums/thread/811265

### R-I2. The 64-notification limit

- The current UserNotifications docs do not state the 64 limit. An Apple DTS engineer confirms "a limit of 64 ...
  no way around it". The deprecated `UILocalNotification` page says the system keeps the soonest 64 and
  discards the rest. Whether the same rule applies to modern requests, and whether any error is raised, is
  UNVERIFIED (spike S3). (VERIFIED for the quotes)
- **Decision**: planner budget is 63 requests, nearest first, last slot reserved for a "open the app to keep
  alerts on" notification. Five prayers alone fit about 12 days; with reminders on all five, about 6 days.
- **Worst case**: a user who never opens the app and has no refresh runs out of alerts after the last scheduled
  instant. The renewal notification and the Reliability check "schedule runs until" line are the mitigation.
- **Citations**: https://developer.apple.com/forums/thread/811171; https://developer.apple.com/documentation/uikit/uilocalnotification

### R-I3. Notification sound and the silent switch

- Custom sound files must be shorter than 30 seconds; longer files fall back to the default sound. Accepted
  formats are Linear PCM, IMA4, mu-law and a-law, packaged as aiff, wav or caf. The file must be in the app
  bundle or the container's `Library/Sounds`. (VERIFIED)
- With Silent mode on, "iPhone doesn't ring or play alerts or other sound effects (but iPhone may still
  vibrate)". So the notification sound is muted. Vibration per notification is UNVERIFIED. (VERIFIED, Apple Support)
- **Resolved (spec clarification, second session)**: the `.playback` audio category continues "with the Silent
  switch set to silent". After the user taps the notification and the app is in the foreground, in-app playback
  therefore plays despite the switch; only the notification sound is muted. The spec now says exactly this. The
  device confirmation (spike S8) is still required before release. (VERIFIED in docs; device test pending)
- **Guideline 2.5.9** says apps may not alter Ring/Silent switch behavior. Using the documented `.playback`
  category after a user tap is ordinary media playback, not altering the switch. (VERIFIED guideline; our reading)
- **Citations**: https://developer.apple.com/documentation/usernotifications/unnotificationsound;
  https://support.apple.com/guide/iphone/silence-iphone-iph81c7fd7d1/ios;
  https://developer.apple.com/documentation/avfaudio/avaudiosession/category-swift.struct/playback;
  https://developer.apple.com/documentation/avfoundation/configuring-your-app-for-media-playback

### R-I4. No code runs at delivery, no audio from background

- Nothing in the docs says the `audio` background mode lets a suspended app start playback when a local
  notification fires. `willPresent` runs only while the app is in the foreground. A notification service
  extension only modifies remote notifications. For actionable notifications the system launches the app in the
  background on selection; starting audio from that launch is UNVERIFIED. (VERIFIED for the quotes)
- **Decision**: rely on tap-to-open then in-app playback. `UIBackgroundModes: audio` is declared only so
  playback continues if the user locks the screen or switches app. Do not use silent looping audio to stay alive
  (App Review 2.5.4 risk).
- **Citations**: willPresent, UNNotificationServiceExtension and notification-actions pages (VERIFIED);
  https://developer.apple.com/app-store/review/guidelines/

### R-I5. Keeping the schedule topped up

- **Decision**: rebuild on every foreground (primary) and register a best-effort `BGAppRefreshTask` that
  re-submits itself (bonus only). The task is short (about 30 seconds), has no guaranteed launch time ("many
  hours"), and only one can be pending. (VERIFIED)
- **Rejected**: significant-location-change (a terminated app is relaunched only with Always authorization;
  Apple says When-In-Use is preferred) and silent push (needs APNs and a server).
- **Citations**: BGAppRefreshTask, BGTaskRequest.earliestBeginDate, requesting-authorization pages; background
  strategies page.

### R-I6. Time Sensitive and Critical Alerts

- Time Sensitive "breaks through system notification controls" including Focus, but the user can turn it off.
  It does not bypass the silent switch in any documentation found. Whether the entitlement is self-service is
  UNVERIFIED. Not planned for Phase 0; candidate for a later spec. Critical Alerts need an approved entitlement
  and are out of scope. (VERIFIED for what is quoted)

### R-I7. App Store

- Privacy: "collect" means transmitting data off the device, so on-device data is not collected. A privacy-policy
  URL is required for all apps. The exact label wording "Data Not Collected" is UNVERIFIED; the console offers
  "No, we do not collect data from this app". (VERIFIED)
- `NSLocationWhenInUseUsageDescription` is required if location is used while in use. Guidelines 5.1.1(ii) (clear
  purpose strings), 5.1.1(iv) (offer an alternative when location is declined: our manual city list),
  5.1.2(i) (may not require push or location to use the app) all match the spec. (VERIFIED)
- Live Activities, PushKit and Critical Alerts are out of scope for Phase 0. (VERIFIED)
- **Citations**: https://developer.apple.com/app-store/app-privacy-details/;
  https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/;
  https://developer.apple.com/documentation/bundleresources/information-property-list/nslocationwheninuseusagedescription

## 3. Prayer-time engine and reference data

### R-P1. adhan_dart

- `adhan_dart` 2.0.1 (MIT, published 2026-05-11, no dependencies) supports every requested method (MWL, ISNA as
  `northAmerica`, Egypt, Umm al-Qura, Karachi, Tehran, Jafari, Gulf, Kuwait, Qatar, Singapore, Turkey, France,
  Moonsighting Committee), both Asr schools, the three high-latitude rules, last third of night, Qibla, and a
  polar-circle resolution option. The Moonsighting method implements season-adjusted twilight. Imsak is not
  provided; compute as Fajr minus a configurable offset. (VERIFIED from source; numeric accuracy not validated)
- `adhan` (stale, Dart 2) is rejected.
- **Decision**: wrap behind `PrayerTimeEngine`; validate every method against the oracle (spike S9); replace
  only the methods that fail.

### R-P2. What "matches a published reference table within 1 minute" can mean

- No machine-readable, clearly licensed set of tables exists for 20 cities x 14 methods x 365 days.
  - Aladhan publishes no data license and states times can differ from official sources by 1-5 minutes.
  - praytimes.org is reported to be LGPL (UNVERIFIED): dev-time cross-check only, never bundled.
  - The `adhan-testdata` repository has no LICENSE file and contains manually adjusted copies of third-party
    tables: do not copy.
  - Diyanet, Umm al-Qura and Moonsighting publish tables but no terms were found (UNVERIFIED): compare by hand,
    do not scrape.
- Sources of disagreement: rounding vs truncation of seconds, Diyanet local offsets, Umm al-Qura fixed Isha
  interval, Moonsighting latitude- and season-dependent twilight, high-latitude handling.
- **Decision (adopted in the spec's SC-003, second clarify session)**:
  1. Primary oracle: an independent implementation of the published astronomical formulas, in `tools/fixtures_gen`.
     Strict plus or minus 1 minute for all methods x 20 cities x full year.
  2. Secondary: hand-transcribed official-table samples with source noted, plus or minus 2 minutes, for the
     method/city pairs where an official table exists.
  3. High-latitude rules are tested against their rule definitions, not against another source's numbers.
  4. adhan-js (MIT) outputs may be used as a further dev-time cross-check.

### R-T1. Time-zone rule source (analysis finding U2)

- **Problem**: the `timezone` package bundles its own tz database, so a government rule change published after the
  app build is missing, while the operating system's rules update independently. Prayer instants depend on the
  location's UTC offset on each date.
- **Decision**: the planner receives an `OffsetResolver`. When the saved location's zone equals the device's current
  zone, the resolver uses the operating system's offsets (via `DateTime` conversions on the device zone, no new
  native code); otherwise it uses the bundled data (for example a city chosen from the offline list while
  travelling). On every launch the app compares the two for the saved zone over the next 60 days and, if they
  disagree, shows a notice "time-zone rules may have changed; update the app" and uses the OS value when it
  applies.
- **Alternatives**: bundled data only (stale after rule changes); a native channel for OS zone rules (more native
  code, not needed for the common case).
- **Tests**: planner vectors for a simulated rule change; spike coverage in S2 and device matrix DST scenarios.

### R-P3. Qibla

Kaaba coordinates 21.4225241 N, 39.8261818 E (as used by adhan-js; Wikipedia gives 21.4225, 39.82617).
Initial great-circle bearing: `atan2(sin Δλ, cos φ · tan φk − sin φ · cos Δλ)` normalized to 0-360. No
authoritative, legally reusable 10-city table was found; adhan-js has 11 cities (MIT, derived from its own
output), usable only as a sanity check. The 3-degree acceptance is therefore tested in two parts: exact math
against the independent implementation, and a device test of the heading pipeline against a surveyed direction.

### R-P4. Hijri (Umm al-Qura)

- ICU4X's `Hijri<UmmAlQura>` has table data for 1300 AH (1882-11-12) to 1600 AH (2174-11-25), sourced from KACST
  month lengths, under the Unicode License V3 (permissive, keep the notice). (VERIFIED from source)
- The `hijri` package covers only 1356-1500 AH, throws outside that range and has no verified publisher: rejected.
  KACST tables carry no accessible terms: do not bundle directly.
- **Decision**: generate our own month-length table from ICU4X data with `tools/hijri_table_gen`, keep the
  notice, validate against published dates (spike S5). One third-party claim of month-start mismatches in 1451-1465
  AH is UNVERIFIED and is why S5 exists.

## 4. Packages and platform integration

| Topic | Decision | Rationale |
|-------|----------|-----------|
| Location | Own small channel (`LocationManager`, `CLLocationManager`) | `geolocator_android` hard-depends on proprietary `play-services-location`. `forceLocationManager` does not remove it from the APK. A Gradle exclusion is supported by the library but untested. A channel is about 100 lines total and removes the dependency. |
| Heading | Own channel: Android rotation vector plus accuracy and magnetic-field magnitude; iOS `CLHeading` with `headingAccuracy` | Needed for tilt compensation, accuracy indicator and interference warning. `flutter_compass` is about 2 years stale; `sensors_plus` gives raw sensors with no heading. |
| Storage | `drift` + `sqlite3` 3.x | `sqlite3_flutter_libs` is end-of-life. The `sqlite3` build hook downloads checksummed binaries from GitHub at build time; pin or vendor for hermetic builds. `sqflite` is the fallback. |
| Notifications | `flutter_local_notifications` on iOS only; Android receivers removed from the manifest | One scheduler per platform behind an `AlertScheduler` interface avoids duplicate alerts. |
| In-app audio | `just_audio` + `audio_session` | MIT, no Google Play Services found; used for previews, iOS tap-to-play and in-app Android playback. |
| Android alert audio | Native `MediaPlayer` in the service | No Dart engine at alarm time; `audio_service` not needed. |
| Volume keys (Tasbih, Android) | Native key handler through Pigeon | `volume_controller` has an unverified publisher and cannot intercept hardware keys alone. |
| State and l10n | Riverpod 3.4.3; ARB files in en, ar, ur, id | Native alert text is localized by Dart and sent in the schedule snapshot. |
| Flutter SDK floor | Pin Flutter 3.44+ | `sqflite`, `wakelock_plus`, `volume_controller` and others require it; `flutter_local_notifications` needs 3.38.1+. Flutter was not installed on this machine, so no `pub get` has been run yet. |
| Default Android template | Check with `./gradlew :app:dependencies` after scaffolding | Template has no Play or GMS dependencies; the engine references Play Core at compile time only (PARTIAL). Do not enable deferred components. |
| Tool telemetry | `flutter --disable-analytics`, `dart --disable-analytics` in setup and CI | Flutter and Dart CLIs have their own telemetry, separate from the app. Not tested here. |

## 5. Content

### R-C1. Azaan audio

- CC0 candidates (VERIFIED license metadata): `Adhan.ogg` (42 s), `Beautiful adhan.ogg` (154 s), `Adhan in
  Istanbul.webm` (video, extract audio), Internet Archive `AzanZhurMasjidKlcc` (CC0, 3-minute Dhuhr). CC-BY 3.0:
  Great Mosque of Mecca recording, Malmo Fajr azan.
- Avoid: CC BY-NC-ND, CC BY-SA (ShareAlike conflicts with permissive redistribution), and files whose "public
  domain" claim is asserted by the uploader for modern recordings.
- **Gaps**: no verified Fajr version with "as-salatu khayrun min an-nawm" (a listener must confirm), and no
  acceptably licensed Shia-wording recording. Plan on recording both with consenting Muazzins under the signed
  license required by clarification D2. Six recordings in total (2 voices x 3 versions) plus 30-second iOS clips.
- Scholar review of pronunciation, wording and clip cut points is required before any recording ships.

### R-C2. Adhkar (Hisn al-Muslim)

- No explicit redistribution grant for the book was found. Repositories labeled MIT (for example
  `asellam/HisnElMuslim`, `YousefAsalya/Islamic-Pro-azkar-API`) do not clear the book's selection and
  arrangement. AGPL and unlicensed repositories are unusable.
- No openly licensed Urdu or Indonesian translation was found, and no clean English translation or
  transliteration source. IslamHouse and sunnah.com terms could not be retrieved.
- **Consequence**: FR-008 ("licensed for free redistribution") cannot be met for Story 6 with found sources.
  Options in plan D-4: own collections from primary hadith sources with commissioned translations, or written
  permission. Story 6 ships last and is gated on content clearance.

### R-C3. Cities (GeoNames)

`cities15000.txt`: 34,174 rows, 8.5 MB (3.36 MB zipped), CC BY 4.0, includes IANA timezone. Language-tagged
names exist only in `alternateNamesV2` (205 MB zip); filtered to our cities it yields about 9,490 Arabic, 6,308
Urdu and 4,004 Indonesian rows (about 0.85 MB raw). Do the filtering in a dev-time script. Attribution: "Contains
data from GeoNames (https://www.geonames.org), licensed under CC BY 4.0. Modified: filtered and recoded." CC BY
also requires the license link and an indication of changes. Whether some rows carry extra sub-source notices
is UNVERIFIED and is a task.

### R-C4. Fonts

Amiri, Noto Naskh Arabic, Noto Sans Arabic, Noto Nastaliq Urdu and Noto Sans are all SIL OFL 1.1 (VERIFIED in
google/fonts). Sizes: Amiri about 431 KB, Naskh 308 KB, Noto Sans Arabic 845 KB, Nastaliq Urdu 690 KB, Noto Sans
2.05 MB. Ship the full `OFL.txt` and copyright line. Subsetting counts as modification: check each file for a
Reserved Font Name before subsetting. The fonts may not be sold alone.

## 6. Cost and hosting

- Phase 0 runtime infrastructure: none. No server, no domain, no CDN. Expected monthly cost: $0.
- Required fees (already in the Exceptions Register): Apple Developer Program and Google Play developer fee.
  Check the current amounts before budgeting.
- Open: privacy-policy hosting (plan D-5) and CI runners (D-9).

## 7. Open items carried to tasks

Spikes S1-S9 (see plan), content acquisition and review, constitution amendment (D-1), spec edits (D-2, D-3, D-8),
quiet-hours definition (D-8), transitive license audit (T-001), Play and App Store console declarations.
