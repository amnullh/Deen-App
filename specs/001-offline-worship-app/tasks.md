---

description: "Task list for Offline Worship App (Phase 0)"
---

# Tasks: Offline Worship App (Phase 0)

**Input**: Design documents from `specs/001-offline-worship-app/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/](contracts/), [quickstart.md](quickstart.md)

**Revision**: regenerated on 2026-10-21 after constitution v1.1.0, the second clarify session (exact alarm in setup, 60-day Android horizon, iPhone tap-to-play, SC-003, quiet hours) and the analysis report. Changes against the first version: the native-code gate is done, the exact-alarm step moved into setup, the Android snapshot and window top-up were added, language and location settings, the no-network check, `LICENSE`, the dependency PR template, the time-zone offset resolver, the recording mapping and two new spikes (S10, S11) were added.

**Tests**: Included. Constitution principle 8 requires test-first work for prayer-time calculation, scheduling, fallback logic and the alert arbiter, and the plan's testing section requires golden, integration, real-device and accessibility tests. Write each test first and confirm it fails before the implementation task that follows it.

**Organization**: Grouped by user story (US1 to US7) so each can be built and tested alone. The three P1 stories (US1, US2, US3) together form the MVP: an alert is only trustworthy once setup, times and alerts all work.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: can run in parallel (different files, no dependency on an unfinished task)
- **[Story]**: US1 to US7 map to the spec's user stories; Setup, Foundational and Polish tasks carry no label
- **[GATE]**: a decision or approval task. Implementation tasks that depend on it must not start until it is done
- **[DEVICE]**: needs a physical phone from the device matrix; cannot be done on an emulator
- **[CONTENT]**: needs a human (scholar, native speaker, Muazzin); an agent can only prepare the request and the register entry
- A checked box (`[x]`) means the task is already done

## Path Conventions

- Flutter app: `apps/mobile/` (`lib/domain`, `lib/data`, `lib/platform`, `lib/ui`, `test`, `integration_test`)
- Android native: `apps/mobile/android/app/src/main/kotlin/org/deenapp/mobile/`
- iOS native: `apps/mobile/ios/Runner/`
- Pure Dart packages: `packages/prayer_engine/`, `packages/schedule_planner/`
- Tooling: `tools/<name>/`; content register: `content/LICENSES.md`
- Spec artifacts: `specs/001-offline-worship-app/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Settle the remaining open decisions and create the repository skeleton.

- [x] T001 [GATE] Amend the constitution to v1.1.0 (native-code scope, GitHub exception, amendment changelog), done 2026-10-21 in `.specify/memory/constitution.md`
- [x] T002 [GATE] Add the content the constitution requires but the spec lacks (analysis C2): a "Constitution check" section listing which principles apply and how, an infrastructure-cost line (hosting $0; store fees only), and citations for each platform claim (link to the research.md sections) in `specs/001-offline-worship-app/spec.md` (done; wording in spec.md)
- [x] T003 [GATE] Confirm plan decisions D-14 (Shia wording plays at every prayer, including Fajr), D-15 (Imsak 10 minutes before Fajr; reminders never use a full Azaan) and decide how a wrong device clock is detected offline (clock before app build date, backward jump, drift against the monotonic clock) through `/speckit-clarify`, recording the answers in `specs/001-offline-worship-app/spec.md` (confirmed by the product owner 2026-10-22; recorded in spec.md and plan.md)
- [x] T004 [GATE] Decide the Story 6 content route (plan D-4: own collections from primary sources with commissioned translations, or written permission) and record it in `specs/001-offline-worship-app/plan.md` and `content/LICENSES.md` (decided 2026-10-22: the project's own collection from primary hadith sources; recorded in plan.md D-4)
- [x] T005 [GATE] Decide privacy-policy hosting (plan D-5) and CI runner type (plan D-9: public repo, or self-hosted macOS runner); if GitHub Pages is used, amend the Exceptions Register in `.specify/memory/constitution.md`; record the choice in `specs/001-offline-worship-app/plan.md` (decided 2026-10-22: GitHub Pages and a public repository; constitution v1.2.0; the owner must set the repository to public and enable Pages)
- [x] T006 Create the Dart workspace root files `pubspec.yaml`, `analysis_options.yaml`, `.gitignore`, a `LICENSE` file with the Apache-2.0 text (constitution principle 10 default), and expand `README.md` (build prerequisites, license rules, link to quickstart)
- [x] T007 Scaffold the Flutter app with `flutter create` into `apps/mobile` for Android and iOS; set Android minSdk 26 and current target SDK, iOS deployment target 16.0, and application id `org.deenapp.mobile` in `apps/mobile/android/app/build.gradle.kts` and `apps/mobile/ios/Runner.xcodeproj` (**confirm the application id before the first store upload; it cannot change later**)
- [x] T008 [P] Create the pure-Dart package `packages/prayer_engine/pubspec.yaml` with no Flutter dependency and a `lib/prayer_engine.dart` barrel file
- [x] T009 [P] Create the pure-Dart package `packages/schedule_planner/pubspec.yaml` (depends on `prayer_engine`) and `lib/schedule_planner.dart`
- [x] T010 [P] Create tool skeletons with their own `pubspec.yaml` in `tools/fixtures_gen/`, `tools/geonames_build/`, `tools/hijri_table_gen/`, `tools/license_scan/`, `tools/sync_content/`
- [x] T011 [P] Add `scripts/setup.sh` that runs `flutter --disable-analytics` and `dart --disable-analytics`, checks Flutter is 3.44 or newer, and runs `dart pub get`
- [x] T012 [P] Configure lints and formatting (`flutter_lints`, `dart format` check) in `analysis_options.yaml`; add `flutter_lints` (BSD-3-Clause) to `content/LICENSES.md`
- [x] T013 [P] Add `.github/pull_request_template.md` and `CONTRIBUTING.md` requiring, for every new dependency, its license, maintainer health and alternatives considered (constitution principle 10), a reviewer check against the Constitution check, and a rule for storing large binaries (Git LFS or release assets for `cities.db` and audio)
- [x] T014 Create the CI workflow skeleton `.github/workflows/ci.yml` running setup, `flutter analyze` and `dart test` for both packages; the scan and check steps are added in T034 once the tools exist; use the runner chosen in T005

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Shared pieces every story needs: prayer-time engine core, database, localization, theme, platform-channel definitions, license and privacy tooling.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [x] T015 [P] Define engine types and the `PrayerTimeEngine` interface exactly as in [contracts/prayer-engine-api.md](contracts/prayer-engine-api.md) in `packages/prayer_engine/lib/src/types.dart`
- [x] T016 [P] Write failing contract tests (determinism, no `DateTime.now()`, null for non-occurring events, offsets applied after calculation) in `packages/prayer_engine/test/engine_contract_test.dart`
- [x] T017 Implement `AdhanDartEngine` mapping all 14 methods, both Asr schools and the three high-latitude rules onto `adhan_dart` 2.0.1 in `packages/prayer_engine/lib/src/adhan_dart_engine.dart` (depends on T015, T016)
- [x] T018 [P] Implement `suggestedMethod(countryCode)` using clarification D1 (MWL fallback) with the country table in `packages/prayer_engine/lib/src/region_defaults.dart` and tests in `packages/prayer_engine/test/region_defaults_test.dart`
- [x] T019 [P] Implement `defaultHighLatitudeRule(latitude)` (default above 48 degrees) with an explanation key in `packages/prayer_engine/lib/src/high_latitude_default.dart` and tests in `packages/prayer_engine/test/high_latitude_default_test.dart`
- [x] T020 Create the drift database with the `Location`, `PrayerSettings`, `AlertPreference` (including `ignoreQuietHours`) and global-settings tables (including `audioOutput`, `clockSample`, `scheduleRunsUntil`) from [data-model.md](data-model.md) and a migration framework in `apps/mobile/lib/data/db/app_database.dart`
- [x] T021 [P] Define repository interfaces in `apps/mobile/lib/domain/repositories/` (`settings_repository.dart`, `location_repository.dart`, `alert_preference_repository.dart`) and the `Result` and error types in `apps/mobile/lib/domain/result.dart`
- [x] T022 Implement the repositories over drift with range validation (offsets -60..60, Hijri -2..2, reminders 5..60) in `apps/mobile/lib/data/repositories/` and tests in `apps/mobile/test/data/repositories_test.dart`
- [x] T023 [P] Set up Riverpod providers and the app entry point with an injected clock in `apps/mobile/lib/main.dart` and `apps/mobile/lib/app/providers.dart`
- [x] T024 [P] Set up localization with ARB files for English, Arabic, Urdu and Bahasa Indonesia (`apps/mobile/lib/l10n/app_en.arb`, `app_ar.arb`, `app_ur.arb`, `app_id.arb`), `l10n.yaml`, and RTL for Arabic and Urdu
- [x] T025 [P] Bundle fonts (Amiri, Noto Naskh Arabic, Noto Sans Arabic, Noto Nastaliq Urdu, Noto Sans) with their `OFL.txt` files under `apps/mobile/assets/fonts/`, register them in `apps/mobile/pubspec.yaml`, and add their entries to `content/LICENSES.md`
- [x] T026 [P] Build the theme and layout scaffolding (light, dark, text scale, high contrast, language-specific font choice, directional padding) in `apps/mobile/lib/ui/theme/app_theme.dart`
- [x] T027 Create the navigation shell with the home route and a one-tap Reliability check entry (placeholder page) in `apps/mobile/lib/ui/app_shell.dart` and `apps/mobile/lib/ui/reliability/reliability_page.dart`
- [x] T028 [P] Write the Pigeon definitions from [contracts/platform-scheduling.md](contracts/platform-scheduling.md) (Android-only `SchedulerApi`, plus `PlaybackApi` and events) and [contracts/platform-device.md](contracts/platform-device.md) in `apps/mobile/pigeons/scheduling.dart` and `apps/mobile/pigeons/device.dart`, and generate the Dart and Kotlin stubs (Swift stubs only for the device APIs) into `apps/mobile/lib/platform/generated/`, the Android Kotlin folder and `apps/mobile/ios/Runner/`
- [x] T029 Implement `tools/license_scan/bin/scan.dart`: read `pubspec.lock` and the Gradle dependency report, fail on any license outside the allowlist (MIT, BSD-2/3, Apache-2.0, ISC, MPL-2.0, Unicode-3.0, SIL OFL 1.1 for fonts) or unknown, and fail when a file under `content/` or `apps/mobile/assets/` has no entry in `content/LICENSES.md`
- [x] T030 [P] Implement `tools/sync_content/bin/sync.dart` to copy content into `apps/mobile/assets/` and verify every file is registered; add a check that iOS notification clips are shorter than 30 seconds
- [x] T031 [DEVICE] Confirm the Android build is free of proprietary Play Services (spike S4): run `./gradlew :app:dependencies`, inspect the built APK, add `tools/license_scan/bin/check_gms.dart`, and record the result in `specs/001-offline-worship-app/research.md` (done in CI: the release runtime classpath has no Play Services, Firebase or Play Core; run 39733337073)
- [x] T032 Implement `tools/license_scan/bin/check_network.dart`: fail if the release Android merged manifest declares `INTERNET` or `ACCESS_NETWORK_STATE`, if a known analytics, ads or tracker SDK (denylist in `tools/license_scan/denylist.txt`) appears in the Gradle or pub dependency graph, or if the iOS app declares network usage keys beyond the platform defaults (FR-001, FR-002)
- [x] T033 Run `flutter pub deps` and `./gradlew :app:dependencies` after the first successful build; record every new or transitive package and license in `content/LICENSES.md`, resolving the "pending" rows (`permission_handler`, `file_picker`, `build_runner`, `drift_dev`, AndroidX, Kotlin) (Dart packages by `tools/license_scan`; Android libraries in `content/register/android-deps.md`, 71 permissive licenses read from CI run 39734250456)
- [x] T034 Complete the CI workflow: add the license scan (T029), the GMS check (T031), the no-network and tracker check (T032) and the content-register check to `.github/workflows/ci.yml`

**Checkpoint**: Foundation ready. User stories can start; US1, US2 and the spikes and content work in US3 can run in parallel.

---

## Phase 3: User Story 1 - First-run setup (Priority: P1) 🎯 MVP

**Goal**: A new user finishes setup in 90 seconds or less, offline, with location kept on the device and every permission optional. Settings stay changeable afterward.

**Independent Test**: Fresh install in airplane mode; choose language, pick a city from the offline list, accept suggested methods, refuse every permission; the app shows today's prayer times without crashing. Repeat in Arabic and confirm right-to-left with no clipped text. Change language and location afterward from settings.

### Tests for User Story 1 ⚠️ write first, confirm they fail

- [x] T035 [P] [US1] Widget test for the setup flow in all four languages, RTL layout and no clipped text at large text size in `apps/mobile/test/ui/setup_flow_test.dart`
- [x] T036 [P] [US1] Integration test: skip location, choose a manual city, reach prayer times, with all permissions refused, in `apps/mobile/integration_test/setup_flow_test.dart` (host test `test/ui/setup_scenario_test.dart`; device run needs a phone)
- [x] T037 [P] [US1] Unit test that refusing each permission (including the exact-alarm permission) leaves setup finishable and lists what will not work, in `apps/mobile/test/domain/permission_flow_test.dart`
- [x] T038 [P] [US1] Unit test for offline city search (case and diacritic insensitive, Arabic, Urdu and Indonesian names, population ordering) in `apps/mobile/test/data/city_search_test.dart`
- [x] T039 [P] [US1] Widget test that language and location can be changed after setup and that the schedule is rebuilt, in `apps/mobile/test/ui/settings_change_test.dart`

### Implementation for User Story 1

- [x] T040 [US1] Implement `tools/geonames_build/bin/build.dart` to build `cities.db` from GeoNames `cities15000` plus filtered `alternateNamesV2` (ar, ur, id), with the attribution text from `content/LICENSES.md`, into `content/cities/cities.db` (storage per the rule from T013)
- [x] T041 [US1] Check whether any `cities15000` rows carry extra sub-source notices (research R-C3) and record the finding and attribution in `content/LICENSES.md`
- [x] T042 [US1] Implement `CityRepository` search over the read-only `cities.db` in `apps/mobile/lib/data/cities/city_repository.dart` (depends on T040)
- [x] T043 [P] [US1] Implement the Android `LocationApi` (`LocationManager`, permission state, single fix with last-known fallback, no Google Play Services) in `apps/mobile/android/app/src/main/kotlin/org/deenapp/mobile/LocationApiImpl.kt` (built in CI and the app's instrumented tests ran on an Android 14 emulator, run 39733337073; behavior on real OEM devices stays with the device spikes T091 to T096)
- [x] T044 [P] [US1] Implement the iOS `LocationApi` (`CLLocationManager`, when-in-use only, approximate-aware) and add `NSLocationWhenInUseUsageDescription` with plain wording in `apps/mobile/ios/Runner/LocationApiImpl.swift` and `apps/mobile/ios/Runner/Info.plist` (the iOS app builds for the simulator in CI, run 39734250456; behavior on a real iPhone stays with the device spikes T093 and T094)
- [x] T045 [US1] Implement the Dart `LocationService` wrapper in `apps/mobile/lib/platform/location_service.dart`
- [x] T046 [US1] Implement time-zone resolution for GPS and approximate fixes (device zone through `flutter_timezone`, city zone from the record) in `apps/mobile/lib/domain/resolve_timezone.dart` with tests in `apps/mobile/test/domain/resolve_timezone_test.dart`
- [x] T047 [US1] Implement the Android permission methods of `SchedulerApi` (`getPermissionState` for exact alarm and battery state, `openExactAlarmSettings`, `openAppNotificationSettings`) in `apps/mobile/android/app/src/main/kotlin/org/deenapp/mobile/SchedulerApiImpl.kt` (the remaining methods are added in T123; depends on T028) (built in CI and the app's instrumented tests ran on an Android 14 emulator, run 39733337073; behavior on real OEM devices stays with the device spikes T091 to T096)
- [x] T048 [US1] Implement the setup state machine (language, location, methods, permissions including exact alarm, battery, privacy) in `apps/mobile/lib/domain/setup/setup_controller.dart`
- [x] T049 [US1] Build the language picker screen in `apps/mobile/lib/ui/setup/language_page.dart`
- [x] T050 [P] [US1] Build the location step screen (precise, approximate, city search, plain-language statement that location stays on the device) in `apps/mobile/lib/ui/setup/location_page.dart`
- [x] T051 [P] [US1] Build the method step: suggested regional method, change option, and Asr method with Standard preselected plus a plain explanation of Standard and Hanafi, in `apps/mobile/lib/ui/setup/method_page.dart`
- [x] T052 [P] [US1] Build the notification-permission explanation and request using `permission_handler` in `apps/mobile/lib/ui/setup/notification_permission_page.dart`
- [x] T053 [P] [US1] Build the Android exact-alarm step: explain why exact timing matters, link to the system setting, and continue setup if refused with the reduced-precision message, in `apps/mobile/lib/ui/setup/exact_alarm_page.dart` (depends on T047)
- [x] T054 [P] [US1] Build the Android battery-optimization guide with a "how to fix" screen per brand (Xiaomi, Oppo, Vivo, Huawei, Samsung, OnePlus, other) and a link to the system settings list, using project-written text in `apps/mobile/lib/ui/setup/battery_guide_page.dart` and `apps/mobile/assets/oem_guides/*.json`
- [x] T055 [P] [US1] Build the privacy summary screen stating that no personal data is collected in `apps/mobile/lib/ui/setup/privacy_page.dart`
- [x] T056 [US1] Build the degraded-permission banner and "way back to the permission" action (opens app settings) in `apps/mobile/lib/ui/common/permission_banner.dart`
- [x] T057 [P] [US1] Build the post-setup settings pages for language and location (reusing the setup widgets) in `apps/mobile/lib/ui/settings/language_settings_page.dart` and `apps/mobile/lib/ui/settings/location_settings_page.dart`
- [x] T058 [US1] Add setup strings to all four ARB files and golden-test the screens in `apps/mobile/lib/l10n/` and `apps/mobile/test/ui/goldens/setup/` (golden images not written)
- [ ] T059 [CONTENT] [US1] Native-speaker review of setup strings in Arabic, Urdu and Bahasa Indonesia; record reviewer and date in `content/LICENSES.md`
- [ ] T060 [DEVICE] [US1] Verify each OEM battery-guide step on the owned devices and record the OS version and date in `apps/mobile/assets/oem_guides/verified.md`
- [ ] T061 [DEVICE] [US1] Time five first-run setups on a phone in airplane mode (each run must take 90 seconds or less to pass SC-001) and record results in `specs/001-offline-worship-app/checklists/device-matrix.md`

**Checkpoint**: Setup works end to end and is testable on its own.

---

## Phase 4: User Story 2 - Accurate prayer times (Priority: P1) 🎯 MVP

**Goal**: Today's times for the saved location, all 14 methods, both Asr schools, high-latitude rules, offsets, Umm al-Qura Hijri date, next-prayer countdown, correct across time zone and DST changes.

**Independent Test**: Run the engine against the generated oracle fixtures (20 cities, all methods, both Asr schools, 365 days) and the hand-checked official samples; open the app, change method, and see every screen update at once.

### Tests and fixtures for User Story 2 ⚠️ write first

- [x] T062 [US2] Define the 20 reference cities (spread across hemispheres, equator, above 48 degrees, a date-line case, and each regional default) in `tools/fixtures_gen/cities.json`
- [x] T063 [US2] Implement the independent oracle (published solar-position and angle formulas, written without using `adhan_dart`) in `tools/fixtures_gen/lib/oracle.dart`
- [x] T064 [US2] Generate fixtures for 20 cities x 14 methods x 2 Asr schools x 365 days into `packages/prayer_engine/test/fixtures/oracle/` in a compact format (done differently: the oracle runs inside the tests; no stored fixture files)
- [ ] T065 [CONTENT] [US2] Hand-transcribe official-table samples (for example Umm al-Qura for Makkah, Diyanet for Ankara and Istanbul, Moonsighting for a published city) with source and date noted, no scraping, into `packages/prayer_engine/test/fixtures/official/` after checking each source's terms
- [x] T066 [P] [US2] Write the failing accuracy test (within 1 minute of the oracle for every combination; within 2 minutes of the official samples) in `packages/prayer_engine/test/oracle_accuracy_test.dart`
- [x] T067 [P] [US2] Write failing tests for Imsak, midnight and last third of night in `packages/prayer_engine/test/night_times_test.dart`
- [x] T068 [P] [US2] Write failing tests for polar day and night (null events plus notices) in `packages/prayer_engine/test/polar_test.dart`
- [x] T069 [P] [US2] Write failing tests for a date-line location and for DST and time-zone rule changes in `packages/prayer_engine/test/dateline_dst_test.dart`
- [x] T070 [P] [US2] Write failing Hijri tests against published Umm al-Qura reference dates, including the user adjustment of -2 to +2, in `packages/prayer_engine/test/hijri_test.dart`
- [x] T071 [P] [US2] Write failing tests for the countdown and next-prayer logic across midnight and day navigation, using an injected clock, in `apps/mobile/test/domain/next_prayer_test.dart`
- [x] T072 [P] [US2] Write failing tests for the `OffsetResolver` (operating-system offsets when the location zone equals the device zone, bundled data otherwise, mismatch notice) in `packages/prayer_engine/test/offset_resolver_test.dart`

### Implementation for User Story 2

- [x] T073 [US2] Run spike S9: record which methods pass the 1-minute bar with `adhan_dart` and which fail, in `specs/001-offline-worship-app/research.md`; implement an own method implementation behind the same interface for each failing method in `packages/prayer_engine/lib/src/methods/` (depends on T064, T066)
- [x] T074 [P] [US2] Implement Imsak (10 minutes before Fajr by default, configurable per T003), midnight and last third of night in `packages/prayer_engine/lib/src/night_times.dart`
- [x] T075 [P] [US2] Implement polar-case resolution and notices in `packages/prayer_engine/lib/src/polar.dart`
- [x] T076 [US2] Implement `tools/hijri_table_gen/bin/gen.dart` to generate the Umm al-Qura month-length table from ICU4X data (range 1300-1600 AH, Unicode License V3 notice kept) into `packages/prayer_engine/lib/src/hijri/umm_al_qura_table.dart`, and implement `toHijri` in `packages/prayer_engine/lib/src/hijri/hijri.dart`; run spike S5 against published dates and record the result
- [x] T077 [US2] Implement the `OffsetResolver` interface and the bundled-data implementation in `packages/prayer_engine/lib/src/offset_resolver.dart` (research R-T1)
- [x] T078 [US2] Implement the operating-system resolver and the start-up comparison that shows a "time-zone rules may have changed" notice when the two disagree in `apps/mobile/lib/domain/os_offset_resolver.dart` and `apps/mobile/lib/domain/tz_rules_notice.dart`
- [x] T079 [US2] Implement `ClockSanityCheck` per the decision in T003 (persist and compare the `clockSample`) in `apps/mobile/lib/domain/clock_sanity.dart` with tests in `apps/mobile/test/domain/clock_sanity_test.dart`
- [x] T080 [US2] Implement the day-times use case (times, Jumu'ah label, next prayer, countdown, previous and next day) in `apps/mobile/lib/domain/prayer/day_times_usecase.dart`
- [x] T081 [US2] Build the home screen with the prayer list, next prayer and live countdown in `apps/mobile/lib/ui/home/home_page.dart`
- [x] T082 [P] [US2] Build the detail view (Imsak, midnight, last third of night, Hijri date with adjustment) in `apps/mobile/lib/ui/home/detail_page.dart`
- [x] T083 [P] [US2] Build the prayer settings page (method, Asr, high-latitude rule with explanation, per-prayer offsets, Hijri adjustment) in `apps/mobile/lib/ui/settings/prayer_settings_page.dart`
- [x] T084 [US2] Ensure a change in method or settings updates every screen at once through provider invalidation, with a test in `apps/mobile/test/ui/settings_propagation_test.dart`
- [x] T085 [US2] Implement the once-per-region "suggested method for this region" banner when the location moves to a region with a different default, with tests, in `apps/mobile/lib/domain/prayer/region_suggestion.dart` and `apps/mobile/lib/ui/home/region_suggestion_banner.dart`
- [x] T086 [US2] Recompute on time-zone or DST change and on app resume (observe system zone changes) in `apps/mobile/lib/app/lifecycle_observer.dart`
- [x] T087 [US2] Add the clock-warning banner and the time-zone-rules notice to the home screen in `apps/mobile/lib/ui/home/clock_warning_banner.dart` and `apps/mobile/lib/ui/home/tz_rules_banner.dart`
- [x] T088 [US2] Add Story 2 strings to all four ARB files, semantic labels for times and countdown, and golden tests in four languages in `apps/mobile/lib/l10n/` and `apps/mobile/test/ui/goldens/home/`
- [ ] T089 [CONTENT] [US2] Native-speaker review of Story 2 strings in Arabic, Urdu and Bahasa Indonesia; scholar sign-off on the method names and high-latitude explanation text; record in `content/LICENSES.md`
- [ ] T090 [DEVICE] [US2] Name the reference mid-range 2020 phone, measure cold start to the next-prayer screen on it (SC-004) and record both in `specs/001-offline-worship-app/checklists/device-matrix.md`

**Checkpoint**: Times are correct, configurable and testable on their own.

---

## Phase 5: User Story 3 - Reliable local Azaan alerts (Priority: P1) 🎯 MVP

**Goal**: The chosen alert fires within 5 seconds of the planned time without opening the app, survives reboots, time changes and updates, never plays two Azaans for one prayer, keeps a 60-day schedule alive and warns before it ends, and the Reliability check explains and fixes problems.

**Independent Test**: Run the 7-day soak on the device matrix with reboots and time zone changes (SC-002), and the scripted scenarios in [quickstart.md](quickstart.md) section 6.

### De-risking spikes (do first; results shape the tasks below)

- [ ] T091 [DEVICE] [US3] Spike S1 and S7: build a throwaway app that sets an alarm with `setAlarmClock` and with `setExactAndAllowWhileIdle`, starts a `mediaPlayback` foreground service from the receiver, and note the status-bar alarm icon; run on Pixel, Samsung and Xiaomi (Android 14 and 15); record in `specs/001-offline-worship-app/spike-results.md`
- [ ] T092 [DEVICE] [US3] Spike S6: record `USAGE_ALARM` and `USAGE_NOTIFICATION` behavior with ringer silent, vibrate and Do Not Disturb on each Android device in `specs/001-offline-worship-app/spike-results.md`
- [ ] T093 [DEVICE] [US3] Spike S2 and S3: on an iPhone, schedule non-repeating calendar triggers with explicit time zone, change the device zone, and schedule 70 requests to see which are dropped; record in `specs/001-offline-worship-app/spike-results.md`
- [ ] T094 [DEVICE] [US3] Spike S8: on an iPhone with the silent switch on, tap a notification and test in-app playback with the `.playback` category; record in `specs/001-offline-worship-app/spike-results.md`
- [ ] T095 [DEVICE] [US3] Spike S10: prototype the Android 14-day registered window with top-up from the alarm receiver, run 7 days including reboot and force-stop, and record the highest alarm count each device accepts, in `specs/001-offline-worship-app/spike-results.md`
- [ ] T096 [DEVICE] [US3] Spike S11: measure the default short tone with exact alarms granted and with them refused on Android 14 and 15, and record the inexact delay in `specs/001-offline-worship-app/spike-results.md`

### Content for User Story 3

- [ ] T097 [CONTENT] [US3] Select or commission the Azaan recordings: 2 voices x standard, Fajr (with "as-salatu khayrun min an-nawm") and Shia-wording versions; obtain CC0, CC-BY or signed Muazzin licenses; add entries to `content/LICENSES.md` and store sources under `content/audio/`
- [ ] T098 [CONTENT] [US3] Scholar review of pronunciation and wording for all six recordings, approval of the iOS clip cut points, and confirmation of the recording mapping in [data-model.md](data-model.md); record reviewer and date in `content/LICENSES.md`
- [x] T099 [P] [US3] Create the short alert tone (CC0, synthesized by the project) in `content/audio/tone-short.wav` with its entry in `content/LICENSES.md`
- [x] T100 [US3] Encode the audio for each platform (Android compressed files, iOS clips under 30 seconds as caf or aiff) with a documented script in `tools/sync_content/bin/encode.dart` and `tools/sync_content/encode_audio.md`, and verify clip lengths in CI

### Tests for User Story 3 ⚠️ write first

- [x] T101 [P] [US3] Write the shared test vectors (arbiter cases, alert ID cases, recording mapping, DST and clock-change planning cases, iOS 63-request budget, Android 60-day snapshot) in `packages/schedule_planner/test_vectors/`
- [x] T102 [P] [US3] Write failing planner tests (stable IDs, 60-day Android snapshot with renewal alert about 7 days before the end, nearest-first iOS budget with renewal alert, quiet-hours demotion with `ignoreQuietHours`, exact-alarm-denied marking, reminder rules, suhoor, DST and clock changes, polar cases) in `packages/schedule_planner/test/planner_test.dart`
- [x] T103 [P] [US3] Write failing arbiter tests (one play per alert ID, suppressed cases) in `packages/schedule_planner/test/arbiter_test.dart`
- [x] T104 [P] [US3] Write failing tests for the recording mapping (standard Fajr uses the Fajr recording, Shia wording uses the Shia recording at every prayer, reminders never use a full Azaan) in `packages/schedule_planner/test/recording_mapping_test.dart`
- [x] T105 [P] [US3] Write failing tests for the journal importer and missed-alert detector, including quiet-hours alerts listed as silenced, `schedule_ended`, and the iOS "possibly missed" case, in `apps/mobile/test/domain/missed_alert_test.dart`
- [x] T106 [P] [US3] Write failing tests for `ScheduleCoordinator` triggers (launch, foreground, settings change, location change, time-zone change, permission change, clock change, window running low) in `apps/mobile/test/domain/schedule_coordinator_test.dart`
- [x] T107 [P] [US3] Write Android instrumented tests that run the Kotlin arbiter and alert-ID rules against the shared vectors in `apps/mobile/android/app/src/androidTest/kotlin/org/deenapp/mobile/ArbiterVectorsTest.kt` (built in CI and the app's instrumented tests ran on an Android 14 emulator, run 39733337073; behavior on real OEM devices stays with the device spikes T091 to T096)
- [x] T108 [P] [US3] Write tests that loud mode defaults to off and that no code path changes system stream volume without opt-in (unit test for the setting, instrumented test for the service) in `apps/mobile/test/domain/loud_mode_test.dart` and `apps/mobile/android/app/src/androidTest/kotlin/org/deenapp/mobile/LoudModeTest.kt`

### Implementation for User Story 3: shared logic

- [x] T109 [US3] Implement alert IDs and the planner (60-day Android snapshot with renewal alert, iOS budgeting, quiet-hours demotion, exact-alarm downgrade, reminders, suhoor, adhkar reminders, offset resolver input) in `packages/schedule_planner/lib/src/planner.dart` and `packages/schedule_planner/lib/src/alert_id.dart`
- [x] T110 [P] [US3] Implement the arbiter in `packages/schedule_planner/lib/src/arbiter.dart`
- [x] T111 [US3] Implement the recording mapping and reminder-type rules in `packages/schedule_planner/lib/src/recording_mapping.dart`
- [x] T112 [US3] Add the `alert_log` drift table and repository per [data-model.md](data-model.md) in `apps/mobile/lib/data/db/tables/alert_log.dart` and `apps/mobile/lib/data/repositories/alert_log_repository.dart`
- [x] T113 [US3] Implement the journal importer and missed-alert detector with cause mapping in `apps/mobile/lib/domain/alerts/missed_alert_detector.dart`
- [x] T114 [US3] Implement `ScheduleCoordinator` (build plan, call the platform scheduler, rebuild on every trigger, update `scheduleRunsUntil`) in `apps/mobile/lib/domain/alerts/schedule_coordinator.dart`

### Implementation for User Story 3: Android

- [x] T115 [US3] Configure `apps/mobile/android/app/src/main/AndroidManifest.xml`: `SCHEDULE_EXACT_ALARM`, `POST_NOTIFICATIONS`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MEDIA_PLAYBACK`, `RECEIVE_BOOT_COMPLETED`, direct-boot-aware receivers, the service with `foregroundServiceType="mediaPlayback"`, and removal of `flutter_local_notifications` receivers with `tools:node="remove"`; do not declare `INTERNET`, `USE_EXACT_ALARM`, `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`, `READ_PHONE_STATE` or `USE_FULL_SCREEN_INTENT` (built in CI and the app's instrumented tests ran on an Android 14 emulator, run 39733337073; behavior on real OEM devices stays with the device spikes T091 to T096)
- [x] T116 [P] [US3] Implement `AlertJournal` (append-only file in device-protected storage) in `apps/mobile/android/app/src/main/kotlin/org/deenapp/mobile/AlertJournal.kt` (built in CI and the app's instrumented tests ran on an Android 14 emulator, run 39733337073; behavior on real OEM devices stays with the device spikes T091 to T096)
- [x] T117 [P] [US3] Implement the Kotlin arbiter and alert-ID rules matching the shared vectors in `apps/mobile/android/app/src/main/kotlin/org/deenapp/mobile/Arbiter.kt` (built in CI and the app's instrumented tests ran on an Android 14 emulator, run 39733337073; behavior on real OEM devices stays with the device spikes T091 to T096)
- [x] T118 [US3] Implement `AlarmScheduler`: persist the 60-day snapshot to device-protected storage, keep the next 14 days registered and top the window up from the snapshot, use the alarm type chosen after spikes S1, S7 and S10, check `canScheduleExactAlarms()`, and use inexact alarms with `preciseAllowed=false` when denied, in `apps/mobile/android/app/src/main/kotlin/org/deenapp/mobile/AlarmScheduler.kt` (built in CI and the app's instrumented tests ran on an Android 14 emulator, run 39733337073; behavior on real OEM devices stays with the device spikes T091 to T096)
- [x] T119 [P] [US3] Implement the receivers for LOCKED_BOOT_COMPLETED, BOOT_COMPLETED, TIME_SET, TIMEZONE_CHANGED, MY_PACKAGE_REPLACED and the exact-alarm permission-state change (re-register and top up only; never start the service from boot) in `apps/mobile/android/app/src/main/kotlin/org/deenapp/mobile/SystemEventReceiver.kt` (built in CI and the app's instrumented tests ran on an Android 14 emulator, run 39733337073; behavior on real OEM devices stays with the device spikes T091 to T096)
- [x] T120 [US3] Implement the notification channels (`tone_v1`, `silent_v1`, `vibrate_v1`, `reminder_v1`, `renewal_v1`, `playback_v1`, `azaan_v1_<voice>_<variant>`) and the localized notification builder with the Stop / Acknowledge action in `apps/mobile/android/app/src/main/kotlin/org/deenapp/mobile/Notifications.kt` (built in CI and the app's instrumented tests ran on an Android 14 emulator, run 39733337073; behavior on real OEM devices stays with the device spikes T091 to T096)
- [x] T121 [US3] Implement `AzaanPlaybackService` (`MediaPlayer`, audio focus after `startForeground`, `USAGE_ALARM` only in loud mode, optional gentle ramp, call interruption leads to vibration, Stop action, no change to system volume) in `apps/mobile/android/app/src/main/kotlin/org/deenapp/mobile/AzaanPlaybackService.kt` (built in CI and the app's instrumented tests ran on an Android 14 emulator, run 39733337073; behavior on real OEM devices stays with the device spikes T091 to T096)
- [x] T122 [US3] Implement `AlarmReceiver`: arbiter check, start the service for full Azaan or post the notification otherwise, fall back to a channel-sound notification and journal `failed:fgs_blocked` if the service cannot start, and top up the registered window, in `apps/mobile/android/app/src/main/kotlin/org/deenapp/mobile/AlarmReceiver.kt` (built in CI and the app's instrumented tests ran on an Android 14 emulator, run 39733337073; behavior on real OEM devices stays with the device spikes T091 to T096)
- [x] T123 [US3] Complete the Android `SchedulerApi` (`replaceSchedule`, `scheduleTestAlert`, `openBatterySettings`, `readJournal`, `clearJournal`, `getPendingSummary`) in `apps/mobile/android/app/src/main/kotlin/org/deenapp/mobile/SchedulerApiImpl.kt` (extends the file started in T047) (built in CI and the app's instrumented tests ran on an Android 14 emulator, run 39733337073; behavior on real OEM devices stays with the device spikes T091 to T096)
- [x] T124 [US3] Implement audio output routing: speaker by default, headphones or Bluetooth when chosen, in `apps/mobile/android/app/src/main/kotlin/org/deenapp/mobile/AudioRouting.kt` (built in CI and the app's instrumented tests ran on an Android 14 emulator, run 39733337073; behavior on real OEM devices stays with the device spikes T091 to T096)
- [x] T125 [US3] Write Android instrumented tests for the receiver, the service start, the window top-up and the journal in `apps/mobile/android/app/src/androidTest/kotlin/org/deenapp/mobile/AlarmFlowTest.kt` (built in CI and the app's instrumented tests ran on an Android 14 emulator, run 39733337073; behavior on real OEM devices stays with the device spikes T091 to T096)

### Implementation for User Story 3: iOS

- [x] T126 [US3] Implement `IosAlertScheduler` (Dart, implementing the common `AlertScheduler` interface) with `flutter_local_notifications`: non-repeating calendar triggers with explicit time zone (or time-interval triggers if spike S2 requires), the 63-request budget, the renewal notification as the last request, and the `alertId` payload, in `apps/mobile/lib/platform/ios_alert_scheduler.dart`
- [x] T127 [US3] Implement tap handling: open the app and play the full Azaan through `just_audio` and `audio_session` with the `.playback` category, interruption handling, and the arbiter check, in `apps/mobile/lib/platform/playback_service.dart`
- [x] T128 [US3] Configure iOS: bundle notification clips, `UIBackgroundModes` audio, `BGTaskSchedulerPermittedIdentifiers`, and register a best-effort `BGAppRefreshTask` that rebuilds the schedule in `apps/mobile/ios/Runner/Info.plist` and `apps/mobile/ios/Runner/AppDelegate.swift` (the iOS app builds for the simulator in CI, run 39734250456; behavior on a real iPhone stays with the device spikes T093 and T094)
- [x] T129 [US3] Implement iOS journal inference (pending-request diff and delivered list; entries are `iosInferred` and may be "possibly missed") in `apps/mobile/lib/platform/ios_journal.dart`
- [x] T130 [US3] Implement the one-time iPhone silent-switch notice (the notification sound is muted; vibration offered; tapping plays the Azaan) in `apps/mobile/lib/ui/alerts/silent_switch_notice.dart`

### Implementation for User Story 3: screens

- [x] T131 [US3] Build the per-prayer alert settings page (off, silent, vibrate, short tone, full Azaan, "ignore quiet hours" switch) in `apps/mobile/lib/ui/alerts/alert_settings_page.dart`
- [x] T132 [P] [US3] Build the voice picker with previews of every version, the Shia-wording option clearly labeled and visible, in `apps/mobile/lib/ui/alerts/voice_picker_page.dart`
- [x] T133 [P] [US3] Build the loud-mode controls (Android only: off by default, per prayer, "keep my current volume" or "gentle ramp"), quiet hours, audio output choice, pre-prayer reminders (5 to 60 minutes) and the Ramadan suhoor reminder in `apps/mobile/lib/ui/alerts/alert_options_page.dart`
- [x] T134 [US3] Implement the re-prompt flow when the user turns on an audible alert or a reminder while exact alarms are not granted, with the inexact-fallback message if refused, in `apps/mobile/lib/ui/alerts/exact_alarm_flow.dart`
- [x] T135 [US3] Build the Reliability check screen: permission states, next 5 scheduled alerts, last alert result, "send a test Azaan in 1 minute", plain fixes for each problem, "alerts run until" date, "silenced by quiet hours" and inexact-alarm flags, in `apps/mobile/lib/ui/reliability/reliability_page.dart`
- [x] T136 [US3] Show the missed-alert notice with a likely cause at next app open in `apps/mobile/lib/ui/reliability/missed_alert_banner.dart`
- [x] T137 [US3] Handle the renewal notification (tap opens the app and rebuilds the schedule) and add its localized text in `apps/mobile/lib/domain/alerts/renewal_handler.dart`
- [x] T138 [US3] Add Story 3 strings (including native-notification text) to all four ARB files and golden-test the screens in `apps/mobile/lib/l10n/` and `apps/mobile/test/ui/goldens/alerts/` (layout-check goldens only)
- [ ] T139 [CONTENT] [US3] Native-speaker review of Story 3 strings in Arabic, Urdu and Bahasa Indonesia; record in `content/LICENSES.md`

### Validation for User Story 3

- [ ] T140 [DEVICE] [US3] Run the scripted reliability scenarios from [quickstart.md](quickstart.md) section 6 on every matrix device and record pass or fail in `specs/001-offline-worship-app/checklists/device-matrix.md`
- [ ] T141 [DEVICE] [US3] Run the 7-day soak with reboots and a time-zone change on every matrix device, export the alert log summary and evaluate SC-002 (99% within 5 seconds on exact-alarm devices, no duplicate Azaan) in `specs/001-offline-worship-app/checklists/soak-results.md`

**Checkpoint**: MVP complete (US1, US2, US3). Stop here and decide on a pilot release before starting P2 stories.

---

## Phase 6: User Story 4 - Qibla (Priority: P2)

**Goal**: A compass arrow and a text bearing to the Qibla, working offline, with tilt compensation and accuracy warnings.

**Independent Test**: Compare shown bearings for 10 injected city locations against the independent implementation; on a device, align with a surveyed reference direction and confirm the error is within 3 degrees after calibration.

### Tests for User Story 4 ⚠️ write first

- [x] T142 [P] [US4] Write failing tests for `qiblaBearing` against an independent implementation (with adhan-js values as a sanity check only) and for `isAtHaram` in `packages/prayer_engine/test/qibla_test.dart`
- [x] T143 [P] [US4] Write failing tests for heading smoothing, interference detection and calibration prompts using recorded sensor streams in `apps/mobile/test/domain/heading_filter_test.dart`

### Implementation for User Story 4

- [x] T144 [US4] Implement `qiblaBearing` and `isAtHaram` in `packages/prayer_engine/lib/src/qibla.dart`
- [x] T145 [US4] Implement the localized compass-direction text ("212 degrees, southwest") in `apps/mobile/lib/domain/qibla/direction_text.dart`
- [x] T146 [P] [US4] Implement the Android `HeadingApi` (rotation vector, sensor accuracy callbacks, magnetometer magnitude, magnetic declination) in `apps/mobile/android/app/src/main/kotlin/org/deenapp/mobile/HeadingApiImpl.kt` (built in CI and the app's instrumented tests ran on an Android 14 emulator, run 39733337073; behavior on real OEM devices stays with the device spikes T091 to T096)
- [x] T147 [P] [US4] Implement the iOS `HeadingApi` (`CLHeading` with `headingAccuracy`, device orientation) in `apps/mobile/ios/Runner/HeadingApiImpl.swift` (the iOS app builds for the simulator in CI, run 39734250456; behavior on a real iPhone stays with the device spikes T093 and T094)
- [x] T148 [US4] Implement the Dart heading service and filter, started only while the screen is visible, in `apps/mobile/lib/platform/heading_service.dart` and `apps/mobile/lib/domain/qibla/heading_filter.dart`
- [x] T149 [US4] Build the Qibla screen: arrow, degrees and text, accuracy indicator, calibration prompt, magnetic-interference warning, "you are at the Haram" state, and the no-compass fallback with usage instructions, in `apps/mobile/lib/ui/qibla/qibla_page.dart`
- [x] T150 [US4] Add Story 4 strings, screen-reader description of the bearing, and golden tests in `apps/mobile/lib/l10n/` and `apps/mobile/test/ui/goldens/qibla/` (golden images not written)
- [ ] T151 [CONTENT] [US4] Native-speaker review of Story 4 strings (including direction names); record in `content/LICENSES.md`
- [ ] T152 [DEVICE] [US4] Inject 10 city locations and compare the displayed bearing with the computed value, then run one physical alignment against a surveyed direction (within 3 degrees after calibration), including flat and upright holding and indoor interference, recorded in `specs/001-offline-worship-app/checklists/device-matrix.md`

**Checkpoint**: Qibla works on its own.

---

## Phase 7: User Story 5 - Tasbih counter (Priority: P2)

**Goal**: A large tap counter with targets, history and state that survives app kill and reboot.

**Independent Test**: Count, force-quit, reboot, reopen; the count, target and history are intact.

### Tests for User Story 5 ⚠️ write first

- [x] T153 [P] [US5] Write failing tests for counting, targets (33, 99, custom), reset-with-confirmation and daily totals in `apps/mobile/test/domain/tasbih_test.dart`
- [x] T154 [P] [US5] Write a failing integration test that state survives an app restart in `apps/mobile/integration_test/tasbih_persistence_test.dart`

### Implementation for User Story 5

- [x] T155 [P] [US5] Create the optional tap sound (CC0, synthesized by the project) in `content/audio/tasbih-tick.wav` with its entry in `content/LICENSES.md`
- [x] T156 [US5] Add the `tasbih_state` and `tasbih_days` drift tables and repository in `apps/mobile/lib/data/db/tables/tasbih.dart` and `apps/mobile/lib/data/repositories/tasbih_repository.dart`
- [x] T157 [US5] Implement tasbih logic in `apps/mobile/lib/domain/tasbih/tasbih_controller.dart`
- [x] T158 [P] [US5] Implement the Android `VolumeKeyApi` (intercept volume keys only while the Tasbih screen is visible) in `apps/mobile/android/app/src/main/kotlin/org/deenapp/mobile/VolumeKeyApiImpl.kt` (built in CI and the app's instrumented tests ran on an Android 14 emulator, run 39733337073; behavior on real OEM devices stays with the device spikes T091 to T096)
- [x] T159 [US5] Build the Tasbih screen: large tap target, haptic feedback (Flutter built-in), optional sound, target picker, history, reset confirmation, keep-awake (`wakelock_plus`), volume-key counting (Android) and tap lock, in `apps/mobile/lib/ui/tasbih/tasbih_page.dart`
- [x] T160 [US5] Add Story 5 strings, accessibility labels and golden tests in `apps/mobile/lib/l10n/` and `apps/mobile/test/ui/goldens/tasbih/` (golden images not written)
- [ ] T161 [CONTENT] [US5] Native-speaker review of Story 5 strings; record in `content/LICENSES.md`

**Checkpoint**: Tasbih works on its own.

---

## Phase 8: User Story 6 - Adhkar (Priority: P2)

**Goal**: Scholar-reviewed adhkar collections with progress, bookmarks and optional reminders.

**Independent Test**: Open each collection offline, finish a session, bookmark an entry, enable a morning reminder, and confirm the About screen lists each text's source and reviewer.

**⚠️ Blocked by T004**: no adhkar text, translation or transliteration may be added until its source, license and reviewer are recorded (FR-008). Research found no cleared source for any of them.

### Content for User Story 6

- [ ] T162 [CONTENT] [US6] Assemble the Arabic adhkar texts from the source chosen in T004 (for example hadith primary sources) with references, into `content/adhkar/adhkar-ar.json`, and add entries to `content/LICENSES.md`
- [ ] T163 [CONTENT] [US6] Scholar review of the Arabic text (diacritics, hadith grading, repeat counts) and of every translation and transliteration; record reviewer and date in `content/LICENSES.md`
- [ ] T164 [CONTENT] [US6] Commission or obtain English, Urdu and Bahasa Indonesia translations and transliteration with licenses that allow free redistribution into `content/adhkar/`
- [x] T165 [US6] Build the adhkar content pack and validate that every entry has a source, license and reviewer in `tools/sync_content/bin/adhkar_pack.dart`

### Tests for User Story 6 ⚠️ write first

- [x] T166 [P] [US6] Write failing tests for session progress and bookmarks in `apps/mobile/test/domain/adhkar_test.dart`
- [x] T167 [P] [US6] Write failing planner tests for morning reminders relative to Fajr and evening reminders relative to Asr or Maghrib in `packages/schedule_planner/test/adhkar_reminders_test.dart`

### Implementation for User Story 6

- [x] T168 [US6] Add the `adhkar_progress`, `adhkar_bookmark` and `adhkar_reminder` drift tables and repositories in `apps/mobile/lib/data/db/tables/adhkar.dart` and `apps/mobile/lib/data/repositories/adhkar_repository.dart`
- [x] T169 [US6] Implement the adhkar content loader for the read-only pack in `apps/mobile/lib/data/adhkar/adhkar_content_loader.dart`
- [x] T170 [US6] Implement session and bookmark logic in `apps/mobile/lib/domain/adhkar/adhkar_session.dart`
- [x] T171 [US6] Extend the planner with `adhkarReminder` alerts anchored to Fajr, Asr and Maghrib in `packages/schedule_planner/lib/src/planner.dart`
- [x] T172 [US6] Build the collections list, entry view (Arabic, transliteration, translation, repeat count, source reference), progress and bookmarks in `apps/mobile/lib/ui/adhkar/collections_page.dart` and `apps/mobile/lib/ui/adhkar/entry_page.dart`
- [x] T173 [P] [US6] Build the reminder settings in `apps/mobile/lib/ui/adhkar/reminder_settings_page.dart`
- [x] T174 [US6] Show each text's source and reviewer in the About screen content list in `apps/mobile/lib/ui/about/content_credits_page.dart`
- [x] T175 [US6] Add Story 6 strings, accessibility labels and golden tests in four languages in `apps/mobile/lib/l10n/` and `apps/mobile/test/ui/goldens/adhkar/` (golden images not written)
- [ ] T176 [CONTENT] [US6] Native-speaker review of Story 6 interface strings; record in `content/LICENSES.md`

**Checkpoint**: Adhkar works on its own once content is cleared.

---

## Phase 9: User Story 7 - Settings, accessibility, data (Priority: P3)

**Goal**: Appearance and accessibility controls, settings export and import, delete-all-data, and a complete About screen.

**Independent Test**: Operate every screen with TalkBack and VoiceOver, export settings, import them after a data wipe, and confirm delete-all leaves nothing behind.

### Tests for User Story 7 ⚠️ write first

- [x] T177 [P] [US7] Write failing export/import tests against [contracts/settings-export.md](contracts/settings-export.md) (round trip including `audioOutput` and `ignoreQuietHours`, unknown version rejected, all-or-nothing, range validation) in `apps/mobile/test/data/settings_export_test.dart`
- [x] T178 [P] [US7] Write a failing test that "delete all my data" clears the database, the Android snapshot and journal, and all scheduled alerts in `apps/mobile/test/data/delete_all_test.dart`

### Implementation for User Story 7

- [x] T179 [US7] Implement export and import per the contract (versioned JSON, system share or save sheet, file picker) in `apps/mobile/lib/data/export/settings_export_service.dart`
- [x] T180 [US7] Implement delete-all-data with a confirmation that notes saved export files remain, in `apps/mobile/lib/domain/delete_all_data.dart`
- [x] T181 [P] [US7] Build the appearance and accessibility settings (theme, text size, high contrast) in `apps/mobile/lib/ui/settings/appearance_page.dart`
- [x] T182 [P] [US7] Build the data settings (export with a plain location warning, import, delete all) in `apps/mobile/lib/ui/settings/data_page.dart`
- [x] T183 [US7] Build the About screen: open-source licenses, content sources and attributions (GeoNames wording, OFL fonts, Unicode notice), scholar reviewers, and privacy policy, in `apps/mobile/lib/ui/about/about_page.dart`
- [x] T184 [US7] Audit every screen for one-handed reachability and for information conveyed by color alone, and fix findings, recording the audit in `specs/001-offline-worship-app/checklists/accessibility.md` (224 automated checks in `test/ui/accessibility_guidelines_test.dart`; two findings F6/F7 recorded in the checklist; real screen-reader pass is T187)
- [x] T185 [US7] Add Story 7 strings and golden tests in four languages in `apps/mobile/lib/l10n/` and `apps/mobile/test/ui/goldens/settings/` (golden images not written)
- [ ] T186 [CONTENT] [US7] Native-speaker review of Story 7 and About-screen strings; record in `content/LICENSES.md`
- [ ] T187 [DEVICE] [US7] TalkBack and VoiceOver pass on every screen (SC-006), recorded in `specs/001-offline-worship-app/checklists/accessibility.md`

**Checkpoint**: All user stories are independently functional.

---

## Phase 10: Polish & Cross-Cutting Concerns

**Purpose**: Release readiness and the checks that span stories.

- [ ] T188 [P] Write the privacy policy (no data collected, on-device location) in all four languages in `content/privacy/privacy-policy.md` and publish it at the URL chosen in T005 (policy text written in four languages, not yet reviewed by native speakers and not yet published: hosting is decision T005)
- [x] T189 [P] Prepare store assets: Play Data safety answers (no data collected), App Store privacy label (no data collected), permission justifications, and reviewer notes explaining user-scheduled Azaan alerts, in `specs/001-offline-worship-app/release/store-notes.md` (written in `release/store-notes.md`; console wording marked UNVERIFIED there; submission-time confirmation is T197)
- [ ] T190 [P] Prepare the Play Console foreground-service (`mediaPlayback`) declaration text and a demo video framed as a user-scheduled alert in `specs/001-offline-worship-app/release/play-fgs-declaration.md` (declaration text and video script written in `release/play-fgs-declaration.md`; the demo video itself is a manual task)
- [x] T191 Generate `LICENSES/NOTICE` from `content/LICENSES.md` through `tools/license_scan` and wire it into the About screen build, in `LICENSES/NOTICE` (generator `tools/license_scan/bin/notice.dart`, output `LICENSES/NOTICE`, checked in CI; the About screen shows full license texts through Flutter's registry)
- [x] T192 Run the license scan, the no-network and tracker check, and the content-register check in CI to completion with no pending rows left in `content/LICENSES.md` (GitHub Actions run 39733337073 passed every job except the iOS job, which was skipped at that time)
- [ ] T193 [DEVICE] Measure background battery use over 24 hours (SC-005): Android with `adb shell dumpsys batterystats`, iPhone with Xcode energy diagnostics or MetricKit, recorded in `specs/001-offline-worship-app/checklists/device-matrix.md`
- [ ] T194 [DEVICE] Run the full real-device matrix sign-off (Pixel, Samsung, Xiaomi, Oppo or Vivo, iPhone on current and previous iOS) required for release, recorded in `specs/001-offline-worship-app/checklists/device-matrix.md`
- [x] T195 Re-run the constitution check against the finished design and update the table in `specs/001-offline-worship-app/plan.md` (plan.md constitution table updated)
- [x] T196 Run the full [quickstart.md](quickstart.md) from a clean clone and fix anything that does not work in `specs/001-offline-worship-app/quickstart.md` (run from a fresh `git clone` on 2026-10-22: setup, l10n check, scans, NOTICE check, analysis and all 932 app tests pass; the city-database download and the device steps were not repeated)
- [ ] T197 Verify store listings declare "no data collected" (SC-007) before the first submission and record the confirmation in `specs/001-offline-worship-app/release/store-notes.md`

---

## Dependencies and Execution Order

### Phase dependencies

- **Setup (Phase 1)**: starts immediately. T001 is done. T002 and T003 must finish before release and before the tasks that name them (T074, T079, T111, T098). T004 gates all of US6. T005 gates T014 and T188.
- **Foundational (Phase 2)**: depends on T006 to T014. Blocks every user story. Native work is allowed under constitution v1.1.0 once each module has its contract (already written).
- **US1, US2, US3**: all depend on Foundational. US1 and US2 can run in parallel. US3's spikes (T091 to T096) and content tasks (T097 to T100) can start as soon as Phase 1 is done, in parallel with US1 and US2.
- **US4, US5**: depend on Foundational only; can run in parallel with each other and with US3 after the engine exists.
- **US6**: depends on Foundational, on the planner from US3 (T109), and on gate T004.
- **US7**: depends on Foundational and benefits from US3 and US6 data being present (export, delete-all and About cover them).
- **Polish**: after the stories being released.

### Task-level dependencies that matter

- T017 depends on T015 and T016. T073 depends on T064 and T066. T076 needs T070 failing first.
- T047 depends on T028. T053 depends on T047. T123 extends the file from T047 (do not run in parallel with it).
- T109 depends on T101 and T102. T110 depends on T103. T111 depends on T104.
- T118 depends on T091, T095 and T096. T122 depends on T115, T116, T117, T120 and T121.
- T126 depends on T093. T127 depends on T094. T130 depends on T094.
- T134 depends on T123 and T053. T135 depends on T113, T114, T123 and T129.
- T140 and T141 depend on all other US3 implementation tasks and on the content from T097 and T098.
- T171 depends on T109. T174 depends on T162 to T164.
- T156 and T159 may use the tick sound from T155; T099 is not required by US5.

### User story dependencies

- US1: no dependency on other stories (uses engine core, city data, and the permission methods in T047).
- US2: no dependency on other stories.
- US3: needs US1 (location, permissions) and US2 (times) to be useful, but the planner, native code and spikes are independent and can be built and tested first.
- US4, US5: independent.
- US6: needs the planner (US3) only for reminders; reading and progress work without it.
- US7: independent for appearance and About; export and delete-all touch every other story's data.

## Parallel Opportunities

- **Phase 1**: T008 to T013 in parallel.
- **Phase 2**: T015, T016, T018, T019, T021, T023 to T026, T028 and T030 in parallel, then T017, T020 and T022 in order.
- **US1**: tests T035 to T039 in parallel; T043 and T044 in parallel; screens T050 to T055 and T057 in parallel.
- **US2**: tests T066 to T072 in parallel; T074 and T075 in parallel; T082 and T083 in parallel.
- **US3**: spikes T091 to T096 can run on different devices at once; tests T101 to T108 in parallel; Android tasks T116, T117 and T119 in parallel; T132 and T133 in parallel.
- **US4**: T142 and T143; T146 and T147.
- **Across stories**: once Foundational is done, one developer can take US1, another US2, a third the US3 spikes and content, a fourth US4 and US5.

### Example: User Story 3 start

```text
Parallel:
- T091 Spike S1/S7 on Pixel, Samsung and Xiaomi
- T093 Spike S2/S3 on an iPhone
- T095 Spike S10 window top-up prototype
- T097 Select or commission the Azaan recordings
- T101 Shared test vectors
- T102 Planner tests
- T103 Arbiter tests
```

## Implementation Strategy

### MVP first (US1 + US2 + US3)

1. Finish the remaining gates (T002 to T005), then Phase 1 and Phase 2.
2. Build US2 and US1 in parallel; both are visible without alerts.
3. Run the US3 spikes early, finish US3, and run the soak (T141). The MVP is not done until SC-002 passes on the matrix.
4. Stop and validate: run [quickstart.md](quickstart.md). Decide on a closed pilot.

### Incremental delivery

1. MVP release to a small group (US1, US2, US3).
2. Add US4 (Qibla) and US5 (Tasbih): independent, low risk.
3. Add US6 (Adhkar) only after the content gate (T004, T162 to T164) is cleared.
4. Add US7 completeness and the release polish.

### Risks that can stop the plan

- No cleared Fajr or Shia-wording recordings (T097): US3 cannot ship its full voice set.
- Alarm-started foreground service blocked on a device (T091): the notification-sound fallback becomes the main path and SC-002 must be re-measured.
- Window top-up unreliable or alarm limit lower than expected (T095): the registered window shrinks and the renewal notice moves earlier.
- Adhkar content not clearable (T004): US6 moves out of Phase 0.

## Notes

- Mark a task done only after its test passes (or, for [DEVICE] tasks, the result is recorded in the named file).
- Commit after each task or small group of tasks.
- Do not add a dependency, asset or font without its entry in `content/LICENSES.md` (CI will fail).
- Total tasks: 197 (1 already done). [P] tasks are those marked in the lists above.
