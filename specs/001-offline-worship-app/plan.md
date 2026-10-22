# Implementation Plan: Offline Worship App (Phase 0)

**Branch**: `001-offline-worship-app` | **Date**: 2026-10-21 (revised after constitution v1.1.0 and the second clarify session) | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/001-offline-worship-app/spec.md`

## Summary

Phase 0 is a Flutter app (Android 8.0+, iOS 16+) with no server, account or network dependency. Its job is to
prove one thing: a prayer alert the user can trust. The design therefore puts all decisions in pure Dart that can
be tested to the minute (prayer-time engine, schedule planner, alert arbiter) and keeps platform code thin and
auditable.

- **Android** uses custom Kotlin: exact alarms (requested in setup, because the default alert is the short
  tone), boot/time receivers, a `mediaPlayback` foreground service that plays the Azaan without starting a Dart
  engine, and an on-device alert journal. The planner hands native code a 60-day snapshot; native keeps a 14-day
  window of registered alarms and tops it up every time an alarm fires. A renewal notification appears about
  7 days before the snapshot ends.
- **iOS** uses rolling, non-repeating local notifications (63-request budget), rebuilt on every foreground, with
  in-app playback after the user taps the notification. The notification sound is muted by the silent switch;
  tap-to-play is not (confirmed by Apple's docs, to be confirmed on a device).
- Research (see [research.md](research.md)) found several places where the platform docs differ from the brief.
  Items that still need your decision are listed under **Deviations and decisions** below.

## Technical Context

**Language/Version**: Dart 3.12+ and Flutter 3.44+ (pinned; several current packages require it), Kotlin (Android
native), Swift (iOS native, minimal)

**Primary Dependencies**: see the dependency license table below. Core: `adhan_dart` (behind our own engine
interface), `flutter_riverpod`, `drift` + `sqlite3`, `just_audio` + `audio_session`, `flutter_local_notifications`
(iOS scheduling and permission prompts), `timezone` + `flutter_timezone`, `intl` + `flutter_localizations`,
`pigeon` (dev). No `geolocator`, `audio_service`, `flutter_compass` or `volume_controller`.

**Storage**: SQLite via drift for settings, alert log, tasbih, adhkar progress, bookmarks. A separate read-only
bundled `cities.db` for the offline city search. A device-protected schedule snapshot and alert journal on
Android (readable before first unlock).

**Testing**: `flutter_test` and `dart test` (unit), `alchemist` (golden), SDK `integration_test` (emulator flows),
scripted real-device matrix with a 7-day soak, TalkBack and VoiceOver audits.

**Target Platform**: Android 8.0 (API 26) and newer, current target SDK; iOS 16 and newer.

**Project Type**: mobile-app with two pure-Dart packages and build-time tooling.

**Performance Goals**: cold start to next-prayer screen under 2 s on a mid-range 2020 phone (SC-004); alert
fires within 5 s of planned instant for 99% of alerts (SC-002); background battery use under 1% per day (SC-005).

**Constraints**: offline-capable; zero licensing cost; no analytics, ads or trackers; no proprietary Google Play
Services in the APK; no server infrastructure (Phase 0 hosting cost is $0).

**Scale/Scope**: single user per device; 7 stories; 4 languages; 2 voices x 3 versions of Azaan; about 34,000
cities; 14 calculation methods.

## Constitution Check

*GATE: PASS against constitution v1.1.0 (the native-code deviation was resolved by the amendment). Re-checked after implementation (2026-10-21, task T195): no violations in code that exists; items that can only be proven on devices or Gradle builds are tracked in tasks.md.*

| # | Principle | Status | How the plan meets it |
|---|-----------|--------|-----------------------|
| 1 | Local-first reliability | PASS | Times computed on device; alerts scheduled locally; bundled audio. No server path exists in Phase 0. |
| 2 | Platform honesty | PASS | Every platform claim is cited and flagged VERIFIED or UNVERIFIED in [research.md](research.md). No PushKit, no Critical Alerts, no silent-push assumption on iOS. Android uses `USAGE_ALARM` only in opt-in loud mode, `mediaPlayback` service type, audio focus instead of phone-state permission, Doze and OEM handling. `ACCESS_NOTIFICATION_POLICY` is not requested (the DND feature is out of Phase 0). |
| 3 | User consent and respect | PASS | Loud mode opt-in per prayer, default off, "keep volume" or "gentle ramp". Content sources, licenses and reviewers recorded in [content/LICENSES.md](../../content/LICENSES.md). Masjid items are N/A until Phase 1. |
| 4 | Privacy by design | PASS | No server, no account, no analytics or tracking SDKs. Location stays on device. Proprietary Play Services location library is excluded from the build (own location channel). Store labels declare no data collected. |
| 5 | Broadcast security | N/A | No broadcasting in Phase 0. |
| 6 | Audio quality and delivery | N/A | No capture or streaming. Bundled Azaan encoded for delivery size and platform limits only. |
| 7 | Religious and cultural correctness | PASS | All 14 methods, both Asr schools and 3 high-latitude rules are configurable. SC-003 now defines the test: strict 1 minute against an independent calculation, plus hand-checked official-table samples within 2 minutes wherever such tables exist. |
| 8 | Testing and quality gates | PASS | Test-first for engine, planner and arbiter. Device-matrix sign-off gates release. CI uses free tooling (Exceptions Register covers GitHub Actions). Backend contract tests are N/A (no backend). |
| 9 | Simplicity and scope control | PASS | Phase 0 only; widgets, AR, payments out. No gRPC or microservices. |
| 10 | Open source and zero cost | PASS with open items | Every Dart dependency (158 packages, including transitive) is checked by `tools/license_scan`: all MIT, BSD, Apache-2.0, ISC, MPL-2.0 or Unicode; `LICENSES/NOTICE` is generated. Open: the Android Gradle dependencies cannot be audited until an Android SDK build exists (T031, T033), and privacy-policy hosting (D-5). |
| 11 | Accessibility and localization | PASS | Four languages from day one; RTL goldens; TalkBack and VoiceOver audit. |

**Technology Constraints (v1.1.0)**: native Swift/Kotlin is allowed where no OSI-licensed Flutter plugin meets the
requirement, for audio session and playback, foreground services, exact-alarm scheduling and boot/time receivers,
the alert journal, location and heading sensors, and Live Activities. Each native module needs a written
platform-channel contract and may not use proprietary Google Play Services libraries. This plan complies:
[contracts/platform-scheduling.md](contracts/platform-scheduling.md) and
[contracts/platform-device.md](contracts/platform-device.md) cover every native module, and the APK check
(spike S4) enforces the Play Services rule.

**Other constitution notes**: the spec still lacks the Constitution check, infrastructure-cost line and platform
citations that Governance and principle 10 require (analysis finding C2); the cost is stated here and in
research section 6 ($0 hosting in Phase 0) and must be added to the spec.

## Project Structure

### Documentation (this feature)

```text
specs/001-offline-worship-app/
├── plan.md              # This file
├── research.md          # Phase 0 output: decisions, policy citations, spikes
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   ├── prayer-engine-api.md
│   ├── platform-scheduling.md
│   ├── platform-device.md
│   └── settings-export.md
├── checklists/requirements.md
└── tasks.md             # Phase 2 output (/speckit-tasks, not created here)
```

### Source Code (repository root)

```text
apps/mobile/                     # Flutter app (Dart)
├── lib/
│   ├── domain/                  # use cases, entities, repository interfaces (no Flutter, no I/O)
│   ├── data/                    # drift database, repositories, settings, content loaders, export/import
│   ├── platform/                # Dart side of Pigeon APIs: AlertScheduler, AudioPlayer, Location, Heading
│   ├── ui/                      # screens, widgets, themes, l10n, a11y
│   └── main.dart
├── pigeons/                     # Pigeon definitions (see contracts/)
├── android/app/src/main/kotlin/ # AlarmScheduler, receivers, AzaanPlaybackService, AlertJournal, Location, Heading
├── ios/Runner/                  # Swift: location + heading channel, BGAppRefreshTask registration
├── assets/                      # generated by tools/sync_content (audio, adhkar, cities.db, fonts)
└── test/ integration_test/
packages/
├── prayer_engine/               # pure Dart: engine interface, adhan_dart adapter, Imsak, Umm al-Qura Hijri, Qibla, regions
└── schedule_planner/            # pure Dart: planner, alert IDs, arbiter rules, iOS 64-slot budgeting
content/
├── LICENSES.md                  # per-asset and per-dependency register (source, license, reviewer)
├── audio/ adhkar/ fonts/ cities/  # source inputs and review records
tools/
├── fixtures_gen/                # independent oracle that generates prayer-time and Qibla fixtures
├── geonames_build/              # builds cities.db from GeoNames dumps
├── hijri_table_gen/             # generates the Umm al-Qura table from ICU4X data
├── license_scan/                # fails CI on disallowed or unknown licenses; checks content register
└── sync_content/                # copies content into apps/mobile/assets
.github/workflows/               # CI
```

**Structure Decision**: a Dart workspace with one Flutter app and two pure-Dart packages. The engine and planner
have no Flutter dependency so they run fast under `dart test`, can be reused by Phase 1, and are the only code
the reliability claim rests on. Native code lives only under the app's `android/` and `ios/` folders behind
Pigeon-generated interfaces, so each native surface has one written contract.

## Layers and key components

- **Prayer-time engine** (`packages/prayer_engine`): `PrayerTimeEngine` interface, `AdhanDartEngine` adapter, own
  Imsak (Fajr minus configurable minutes), midnight and last third of night, own Qibla bearing (great-circle,
  independent of the library), own Umm al-Qura Hijri table (generated from ICU4X data), `RegionDefaults`
  (country to method). `adhan_dart` is evaluated first and replaced per method only if it misses the 1-minute bar
  against the oracle.
- **Schedule planner** (`packages/schedule_planner`): pure function
  `plan(settings, location, tz, now, platformBudget) -> List<PlannedAlert>`. Alert IDs are stable
  (`fajr:2026-10-22`, `fajr:2026-10-22:pre`, `suhoor:2026-10-22`). Android: a 60-day snapshot, with a
  `renewal` alert about 7 days before its end; native registers only the next 14 days and tops the window up
  whenever an alarm fires or a system event occurs (this keeps the registered count near 200 even with every
  reminder on, so the per-app alarm limit, which is not documented in the pages read, is never approached).
  iOS: budget 63 requests, nearest first, with the last slot reserved for the `renewal` notification.
  Time-zone offsets: the planner prefers the operating system's current offsets when the location's zone equals
  the device zone, and bundled `timezone` data otherwise; a mismatch between the two raises a "time-zone rules
  may have changed" notice (decision R-T1).
- **Alert arbiter**: the rule "at most one audible Azaan per alert ID" is a pure function over a ledger of
  played IDs. The Dart implementation covers iOS and imports; the Kotlin implementation runs at alarm time.
  Both are tested against one shared vector file so they cannot diverge.
- **Android native**: `AlarmScheduler` (registers from a device-protected snapshot), receivers for boot, locked
  boot, time set, time zone, package replaced and exact-alarm permission change, `AzaanPlaybackService`
  (`mediaPlayback`, `MediaPlayer`, audio focus, optional ramp), `AlertJournal` (append-only record of fired,
  played, acknowledged, suppressed and failed), and a notification-sound fallback if the service cannot start.
- **iOS**: scheduling is Dart-side through `flutter_local_notifications` (`IosAlertScheduler`, which implements the
  same Dart `AlertScheduler` interface as the Android Pigeon bridge); `audio_session` and `just_audio` handle
  playback after tap; a small Swift module covers location and heading and the best-effort refresh task. The
  Pigeon `SchedulerApi` is Android-native only. Notification permission uses `permission_handler` on both
  platforms.
- **Data**: drift tables in [data-model.md](data-model.md); journal entries are imported into the alert log on app
  start, and the missed-alert detector compares planned alerts to the journal.

## Dependency license register

Verified by reading the package LICENSE files (V) or pub.dev tags only (U). Mirrored in
[content/LICENSES.md](../../content/LICENSES.md). CI fails on any license outside MIT, BSD-2/3, Apache-2.0, ISC,
MPL-2.0, Unicode-3.0 or SIL OFL 1.1 (fonts only).

| Dependency | Version | License | Verified | Use | Verdict |
|------------|---------|---------|----------|-----|---------|
| Flutter SDK, Dart SDK | 3.44+ / 3.12+ | BSD-3-Clause | V | framework | KEEP |
| adhan_dart | 2.0.1 | MIT | V | prayer times (adapter) | KEEP, evaluate against oracle |
| flutter_local_notifications | 22.3.2 | BSD-3-Clause | V | iOS scheduling, permission prompt | KEEP (Android receivers removed from manifest) |
| timezone | 0.11.2 | BSD-2-Clause | V | tz math | KEEP |
| flutter_timezone | 5.1.1 | Apache-2.0 | V | device tz id | KEEP |
| just_audio | 0.10.6 | MIT (ExoPlayer Apache-2.0) | V | in-app playback, preview | KEEP |
| audio_session | 0.2.4 | MIT | V | iOS session, interruptions | KEEP |
| flutter_riverpod | 3.4.3 | MIT | V | state | KEEP |
| drift | 2.35.2 | MIT | V | database | KEEP |
| sqlite3 | 3.7.1 | MIT (SQLite public domain) | V | bundled SQLite | KEEP; pin binary source for hermetic builds |
| intl, flutter_localizations | 0.20.3 / SDK | BSD-3-Clause | V / U | l10n | KEEP |
| pigeon | 29.0.11 | BSD-3-Clause | V | channel codegen (dev) | KEEP |
| permission_handler | 13.0.2 | MIT | V (impl U) | runtime permissions | KEEP after Android impl audit |
| wakelock_plus | 1.8.1 | BSD-3-Clause | V | tasbih keep-awake | KEEP |
| android_intent_plus | 6.1.0 | BSD-3-Clause | V | open settings pages | KEEP |
| file_picker | 13.1.0 | MIT | V (impl U) | settings import | KEEP after impl audit |
| share_plus | 13.3.1 | BSD-3-Clause | V | settings export | KEEP |
| path_provider | 2.1.6 | BSD-3-Clause | V | file paths | KEEP |
| alchemist | 0.14.1 | MIT | V | golden tests (dev) | KEEP |
| integration_test, flutter_test | SDK | BSD-3-Clause | U | tests | KEEP |
| AndroidX core, Kotlin stdlib | current | Apache-2.0 | U | Android native | KEEP |
| Umm al-Qura month table | generated | Unicode License V3 (ICU4X) | V (header) | Hijri | KEEP with notice |
| adhan, hijri_calendar, golden_toolkit, sqlite3_flutter_libs | any | n/a | V/U | n/a | REJECT: stale, EOL or discontinued |
| geolocator (+ geolocator_android) | 14.1.2 | MIT | V | n/a | REJECT: pulls proprietary Play Services location |
| flutter_compass | 0.8.1 | MIT | V | n/a | REJECT: about 2 years stale, no interference signal |
| audio_service | 0.18.19 | MIT | V | n/a | NOT NEEDED: native service plays the Azaan |
| volume_controller | 3.7.1 | MIT | V | n/a | REJECT: unverified publisher; native key handling instead |
| hijri | 3.0.1 | BSD-2-Clause | V | n/a | REJECT: throws outside 1356-1500 AH, unverified publisher |

Build and test tooling to confirm in task T-001: `build_runner`, `drift_dev`, the Android implementations of
`permission_handler` and `file_picker`, `url_launcher_*` (via `share_plus`). Run `flutter pub deps` and
`./gradlew :app:dependencies` after scaffolding and record anything new.

## Bundled content register (summary)

Full detail is in [content/LICENSES.md](../../content/LICENSES.md).

| Asset | Candidate source | License | Status |
|-------|------------------|---------|--------|
| 2 Azaan voices x (standard, Fajr, Shia wording) | Commons and Internet Archive CC0 files; commissioned recordings | CC0, CC-BY, or signed Muazzin license | Standard: candidates found. Fajr and Shia wording: none found, must be recorded. No scholar review yet. |
| iOS notification clips (30 s or less) | cut from the above | same as source | cut points need scholar approval |
| Short tone | synthesized by the project | CC0 / Apache-2.0 | to create |
| Adhkar Arabic text | own collection from primary sources, or cleared Hisn al-Muslim text | unresolved | BLOCKER, see D-4 |
| Adhkar translations (en, ur, id) and transliteration | none openly licensed found | unresolved | BLOCKER, see D-4 |
| GeoNames cities15000 (+ ar, ur, id names) | geonames.org | CC BY 4.0 | ready; attribution wording drafted |
| Fonts: Amiri, Noto Naskh Arabic, Noto Sans Arabic, Noto Nastaliq Urdu, Noto Sans | google/fonts | SIL OFL 1.1 | ready; ship OFL.txt, do not sell alone |
| UI translations (en, ar, ur, id) | project-written | project license | native-speaker review per FR-007 |

## Testing plan

- **Prayer engine**: generated oracle fixtures, 20 cities x 14 methods x 365 days x both Asr schools, plus
  hand-transcribed official-table samples (decision D-3). Planner: DST transitions, zone jumps, polar cases,
  clock changes, iOS budgeting. Arbiter: shared vectors with Kotlin. All written before implementation.
- **Qibla**: formula tests against an independent implementation; heading pipeline tests with recorded sensor
  streams; device test against a surveyed reference direction.
- **UI**: golden tests in four languages (LTR and RTL, large text); integration tests for the seven stories.
- **Real-device matrix (own devices)**: Pixel, Samsung, Xiaomi, Oppo or Vivo, iPhone on current and previous iOS.
  Scenarios: reboot, force-quit, time zone change, DST, manual clock change, airplane mode, battery saver, Doze
  (`adb shell dumpsys deviceidle force-idle`), standby buckets, incoming call, headphones, silent switch.
  7-day soak using the alert journal to measure fire-time error (SC-002). Procedure in [quickstart.md](quickstart.md).
- **Accessibility**: TalkBack and VoiceOver passes on every screen (SC-006).
- **CI**: GitHub Actions free tier or self-hosted runners; lint, analyze, unit, golden, license scan, and a check
  that every file under `content/` and `apps/mobile/assets/` has a register entry. iOS jobs need macOS runners.

## Release plan

Store assets: privacy policy URL, Play Data safety form (no data collected), App Store privacy label (no data
collected), permission justifications, Play foreground-service declaration for `mediaPlayback`, reviewer notes
explaining user-scheduled Azaan alerts. Details and citations in [research.md](research.md).

## Phase 0 de-risking spikes (exit criteria before dependent work)

| ID | Question | Exit criterion |
|----|----------|----------------|
| S1 | Does a foreground service start from a `setAlarmClock` alarm on Pixel, Samsung and Xiaomi (Android 14 and 15)? | Starts on all; else use notification-sound fallback and record |
| S2 | Do iOS calendar triggers with explicit time zone fire at the right instant after a zone change? | Verified on device, or switch to time-interval triggers |
| S3 | Which notifications does iOS drop above 64, and is there any signal? | Documented on device |
| S4 | Is the APK free of `com.google.android.gms`? | `./gradlew :app:dependencies` and APK inspection clean |
| S5 | Does the generated Umm al-Qura table match published dates? | Matches reference dates |
| S6 | `USAGE_ALARM` behavior with ringer silent and Do Not Disturb | Documented on device |
| S7 | Status-bar alarm icon side effect of `setAlarmClock` | Accepted, or alarm type changed |
| S8 | Does in-app playback after notification tap play with the iPhone silent switch on? | Documented on device |
| S9 | Does `adhan_dart` meet 1 minute against the oracle for every method? | Per-method pass list |
| S10 | Does the Android 14-day window top-up work from the alarm receiver on every matrix device (including after reboot and force-stop), and what is the highest alarm count a device accepts? | Window never empties in a 7-day run; limit recorded |
| S11 | Does the default short tone, with exact alarms granted vs refused, meet 5 s vs the inexact delay on Android 14 and 15? | Both cases measured and shown in the Reliability check |

## Deviations and decisions

| ID | Item | Status / recommendation |
|----|------|-------------------------|
| D-1 | Native code scope vs the constitution. | RESOLVED: constitution v1.1.0 widened the clause. |
| D-2 | iOS silent switch: notification sound is muted, tap-to-play is not. | RESOLVED in the spec (clarify session 2). Spike S8 confirms on a device. |
| D-3 | SC-003 reference tables. | RESOLVED in the spec: 1 minute vs independent calculation, 2 minutes vs hand-checked official samples. |
| D-4 | No openly licensed Hisn al-Muslim text, translations or transliteration found; an MIT label on a repo does not clear the book. FR-008 forbids shipping unlicensed text. | DECIDED 2026-10-22: build the project's own collections from primary hadith sources, with commissioned translations and scholar review; no third-party book is copied. Story 6 ships last and only after tasks T162 to T164 clear each text. |
| D-5 | Both stores require a privacy-policy URL. GitHub Pages and GitHub itself are free-tier SaaS not in the Exceptions Register. | DECIDED 2026-10-22: host the policy on GitHub Pages; constitution v1.2.0 adds Pages to the Exceptions Register. |
| D-6 | Brief proposed iOS significant-location-change. Apple requires "Always" location permission to relaunch the app, which conflicts with the spec's privacy stance. | Rejected. Use foreground rebuild plus best-effort background refresh. |
| D-7 | iOS horizon: 64 slots allow about 12 days of five prayers but only about 6 days with reminders on. | Planner fills nearest first and reserves the last slot for a renewal nudge. |
| D-8 | Quiet hours semantics. | RESOLVED in the spec: audible alerts become silent notifications; per-prayer "ignore quiet hours" switch (default off). |
| D-9 | CI on macOS is free only for public repositories on GitHub; repo visibility is unknown. | DECIDED 2026-10-22: the repository is to be made public (the owner changes visibility on GitHub); then set the repository variable ENABLE_IOS_CI to true to run the iOS job. |
| D-10 | Spec SC-002 and the iOS "missed alert" detector: iOS cannot confirm delivery. | Detector reports "possibly missed, cannot confirm" on iOS. |
| D-11 | Exact-alarm permission for the default short tone (Android). | RESOLVED in the spec: requested in setup; refusing never blocks setup. Plan impact: task T046 and the permission flow gain an exact-alarm step; the Reliability check flags inexact alerts (S11). |
| D-12 | Android horizon. | RESOLVED in the spec: about 60 days plus a renewal notice about 7 days before the end. Plan impact: 60-day snapshot, 14-day registered window, top-up at each alarm (S10). |
| D-13 | Time-zone rule source (analysis U2). | DECIDED in the plan (R-T1): OS offsets when the location zone equals the device zone, bundled data otherwise, with a mismatch notice. Needs a platform-channel contract and tasks. |
| D-14 | Which recording plays for Shia wording at Fajr (analysis U3). | CONFIRMED by the product owner 2026-10-22: the Shia recording at every prayer (it has no "as-salatu khayrun min an-nawm"). The scholar reviewer still reviews it (T098). |
| D-15 | Imsak default and reminder alert type (analysis A3, A4). | CONFIRMED 2026-10-22: Imsak is 10 minutes before Fajr, configurable; a reminder uses the prayer's alert type but never a full Azaan (short tone at most). |

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|--------------------------------------|
| Native Kotlin for alarm scheduling, receivers, journal, location, heading (permitted by constitution v1.1.0 with a contract per module) | Reliable alerts after reboot, force-stop and Doze require registering exact alarms and playing audio without starting a Dart engine | A Dart-only or plugin-only Android scheduler cannot start the playback service or write the journal at alarm time, and could not meet SC-002 or FR-005 |
| Native Swift location and heading module | The only OSI-licensed cross-platform location plugin pulls Google Play Services on Android; keeping both platforms on one small contract is simpler | `geolocator` with a Gradle exclusion is untested and fragile; `flutter_compass` is stale and lacks interference reporting |
| Two pure-Dart packages in addition to the app | Engine and planner must be unit-testable without Flutter and reusable by Phase 1 | A single app package slows the test loop and tempts Flutter imports into the domain layer |
| Build-time tools (`tools/`) | Oracle fixtures, cities database, Hijri table, license scan | Hand-maintained data cannot be audited or regenerated |
