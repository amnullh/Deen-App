# Feature Specification: Offline Worship App (Phase 0)

**Feature Branch**: `001-offline-worship-app`

**Created**: 2026-10-21

**Status**: Draft

**Input**: User description: "Build 'Deen App' Phase 0: an offline-first daily worship app for Android and iOS. No server, no account, no network dependency. Everything works in airplane mode after install. Includes first-run setup, accurate prayer times, reliable local Azaan alerts, Qibla, Tasbih, Adhkar, and settings/accessibility/data controls."

## Why

Muslims need a prayer alert they can trust. Existing apps miss alerts after reboots, timezone changes, or when the OS kills background work. Phase 0 proves we can deliver a reliable baseline Azaan before any live or server feature exists.

## Actors

- **Listener**: any app user. There is no account and no sign-in.

## Clarifications

### Session 2026-10-21

- Q: What calculation method is suggested by region? → A: MWL for Europe and the Far East, ISNA for North America, Umm al-Qura for the Arabian Peninsula, Egypt for Africa and the Middle East outside the Peninsula, Karachi for South Asia, Diyanet for Turkey, Singapore for Southeast Asia. The user can always override.
- Q: Where do Azaan recordings come from, and when may they ship? → A: Openly licensed recordings (CC0 or CC-BY) or recordings made with a consenting Muazzin who signs a written license. No recording ships until a scholar has reviewed pronunciation and wording and its license is recorded in content/LICENSES.md. Two voices ship at launch.
- Q: Does the Shia-wording option ship at launch? → A: Yes, clearly labeled and visible in the voice list, not hidden.
- Q: Which dataset powers the offline city search? → A: GeoNames cities with population over 15,000 (CC-BY, attribution required), bundled with the app.
- Q: When is the Android exact-alarm permission requested? → A: When the user turns on any audible alert (short tone or full Azaan) or a reminder, with a link to the system setting; if refused, alerts fall back to inexact notifications with a clear explanation. It is also requested in setup, because the default alert is the short tone; if refused, setup continues and the Reliability check shows the reduced precision. (Refined by the second clarify session: the short-tone default needs exact alarms too.)
- Q: What happens on iPhone when the silent switch is on? → A: The notification sound is muted by the switch (the app shows a one-time explanation and offers vibration). After the user taps the notification, the app plays the full Azaan even if the switch is on, because Apple documents that in-app media playback ignores the switch; to be confirmed on a device before release.
- Q: How does loud mode behave on Android? → A: Off by default and set per prayer, with a "keep my current volume" choice and a "gentle ramp" choice. The app never changes system volume without opt-in.
- Q: Which Hijri calendar is the default? → A: Umm al-Qura, with the user's -2 to +2 day adjustment.
- Q: Is a home-screen widget in Phase 0? → A: No, moved to Phase 4.
- Q: How does Qibla get its heading? → A: A standard compass; AR is Phase 4.
- Q: Which languages ship, and how are translations checked? → A: English, Arabic, Urdu and Bahasa Indonesia, each reviewed by a native speaker before release.
- Q: What alert type does each prayer start with after first-run setup? → A: Short tone for all five prayers; the full Azaan is opt-in per prayer.
- Q: Does each launch voice need its own Fajr and Shia-wording versions? → A: Yes. Both voices ship with standard, Fajr and Shia-wording versions (6 recordings), all scholar-reviewed and licensed.
- Q: What happens when the user does not open the app for a long time and scheduled alerts run out? → A: Android schedules about 60 days ahead (rebuilt on every launch) and posts an "open the app" notification about 7 days before the schedule ends; iPhone uses its last pending notification for the same purpose; the Reliability check shows the date alerts run until.
- Q: What does "match a published reference table" mean for prayer-time accuracy? → A: Strict 1 minute against an independent calculation from the published formulas for 20 cities, every method and both Asr schools across a full year, plus hand-checked samples from official tables within 2 minutes wherever such tables exist.
- Q: What do quiet hours do to an alert that falls inside them? → A: Audible alerts become silent notifications; each prayer has an "ignore quiet hours" switch (off by default).
- Q: Which Asr method does setup suggest? → A: Standard is preselected, and setup asks the user to confirm their Asr method with a plain-language explanation of Standard and Hanafi.
- Q: What happens to the user's chosen method when they travel to a region with a different suggested method? → A: The chosen method is kept; the app shows a dismissible suggestion, once per new region, to switch to that region's default.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - First-run setup (Priority: P1)

A new user opens the app for the first time and sets it up in under 90 seconds: language, location, calculation method, permissions and battery settings, ending with a privacy summary.

**Why this priority**: Every other feature depends on a known language, location and permission state. A bad first run means missed alerts later.

**Independent Test**: Install on a clean device, put it in airplane mode, complete setup using only the offline city list, and confirm the app shows today's prayer times.

**Acceptance Scenarios**:

1. **Given** a clean install, **When** the user picks a language from English, Arabic, Urdu or Bahasa Indonesia, **Then** all screens switch to that language, and Arabic and Urdu lay out right to left with no clipped text.
2. **Given** the location step, **When** the user chooses precise location, approximate location, or searches a city from the built-in offline list (cities with population over 15,000), **Then** a location is saved on the device and the app states in plain words that location never leaves the device.
3. **Given** the user skips location, **When** they choose a manual city, **Then** prayer times are still produced.
4. **Given** a saved location, **When** setup reaches the method step, **Then** the app suggests the regional default method (see FR-009) and lets the user change it. It also asks the user to confirm their Asr method, with Standard preselected and a plain-language explanation of Standard and Hanafi.
5. **Given** the app needs notification permission, **When** that step is reached, **Then** the app explains why before asking. On Android, the app also explains why it needs the exact-alarm permission (alerts at the exact time instead of approximate) and requests it in setup, because every prayer starts with an audible short tone; the user can refuse and still finish setup (see Story 3).
6. **Given** the user refuses any or all permissions, **When** setup continues, **Then** the app never crashes, shows which features will not work, and offers a way back to the permission later.
7. **Given** an Android device, **When** setup reaches battery settings, **Then** the app shows a plain "how to fix" screen specific to the device brand.
8. **Given** setup is finishing, **When** the privacy summary appears, **Then** it states the app collects no personal data.
9. **Given** setup is complete, **When** the user opens settings, **Then** they can change language, location, and methods at any time.

---

### User Story 2 - Accurate prayer times (Priority: P1)

A user sees today's prayer times for their location, with the next prayer and a live countdown always visible.

**Why this priority**: Correct times are the foundation of alerts. Wrong times make every alert wrong.

**Independent Test**: Compare computed times for 20 reference cities, every calculation method and both Asr schools against an independent calculation from the published formulas for a full year, and against hand-checked official-table samples where official tables exist.

**Acceptance Scenarios**:

1. **Given** a location, **When** the user opens the home screen, **Then** Fajr, Sunrise, Dhuhr, Asr, Maghrib and Isha are shown, with Dhuhr labeled Jumu'ah on Fridays.
2. **Given** the detail view, **When** the user opens it, **Then** Imsak, midnight and the last third of the night are also shown.
3. **Given** the method list, **When** the user selects any of Muslim World League, ISNA, Egypt, Umm al-Qura, Karachi, Tehran, Jafari, Gulf, Kuwait, Qatar, Singapore, Turkey (Diyanet), France (UOIF) or Moonsighting Committee, **Then** all screens update at once. Asr offers Standard and Hanafi.
4. **Given** a latitude above 48 degrees, **When** no high-latitude rule is chosen, **Then** the app applies a sensible default and explains it. The user can choose middle of the night, seventh of the night, or angle-based.
5. **Given** any prayer, **When** the user sets a manual offset between -60 and +60 minutes, **Then** that prayer's time shifts accordingly everywhere, including alerts.
6. **Given** the home screen, **When** time passes, **Then** the next prayer and a live countdown stay visible, and the user can move to previous and next days.
7. **Given** the Hijri date, **When** shown, **Then** it uses the Umm al-Qura calendar by default, and **When** the user sets an adjustment from -2 to +2 days, **Then** the displayed Hijri date shifts accordingly.
8. **Given** the user travels or the timezone or daylight saving rule changes, **When** the change happens, **Then** times are recomputed correctly without user action. **Given** the new location's suggested method differs from the user's chosen one, **Then** the chosen method is kept and a dismissible suggestion to switch is shown once per new region.
9. **Given** a device clock that is clearly wrong, **When** the app detects it, **Then** it warns the user.

---

### User Story 3 - Reliable local Azaan alerts (Priority: P1)

A user gets their chosen alert at the right time every day without opening the app, and can see and fix anything that would stop alerts from firing.

**Why this priority**: This is the product's reason to exist: a prayer alert the user can trust.

**Independent Test**: Run on the supported device matrix for 7 days including reboots and timezone changes, and measure alert timing and duplicates.

**Acceptance Scenarios**:

1. **Given** each prayer, **When** the user configures it, **Then** they can choose exactly one of: off, silent notification, vibrate, short tone, or full Azaan. Every prayer starts as short tone after setup. On Android, exact alarms are needed for any audible alert or reminder, so the request is made in setup and again, if still not granted, when the user selects a full Azaan or a reminder.
2. **Given** the voice list, **When** the user browses it, **Then** two scholar-reviewed Azaan voices are available at launch. Each voice has a standard version, a Fajr version including "as-salatu khayrun min an-nawm", and a Shia-wording version that is clearly labeled and visible in the list, and every version can be previewed.
3. **Given** an Android device and a prayer with loud mode on, **When** the time arrives, **Then** the Azaan is audible even if the ringer is silent, the notification has a Stop / Acknowledge button, and phone calls are respected.
4. **Given** an Android prayer with loud mode off (the default), **When** the ringer is silent, **Then** the Azaan does not override silent mode.
5. **Given** an iPhone, **When** a full Azaan alert fires, **Then** the notification sound is 30 seconds or shorter and tapping it opens the app and plays the full Azaan. **Given** the iPhone silent switch is on, **Then** the notification sound is muted and the app shows a one-time plain explanation and offers vibration; **When** the user taps the notification, **Then** the app plays the full Azaan despite the switch.
6. **Given** reminders, **When** the user sets a pre-prayer reminder of 5 to 60 minutes before, or a pre-Fajr suhoor reminder for Ramadan, **Then** they fire at the correct time.
7. **Given** loud mode is turned on for a prayer, **When** the user configures it, **Then** they choose either "keep my current volume" or "gentle ramp", and the app never changes system volume without that opt-in. The user can also set quiet hours (a start and end time): an alert whose time falls inside them is delivered as a silent notification instead of its audible type, unless that prayer's "ignore quiet hours" switch (off by default) is on.
7a. **Given** an Android user in setup or turning on an audible alert (short tone or full Azaan) or a reminder, **When** exact alarms are not yet allowed, **Then** the app explains why and links to the system setting. **If** the user refuses, **Then** alerts fall back to inexact notifications with a clear message that timing may be less precise.
8. **Given** an Azaan playing, **When** headphones or Bluetooth are not chosen, **Then** audio goes to the speaker. **When** a phone call is in progress, **Then** the Azaan is silenced and the device vibrates instead.
9. **Given** device reboot, app update, timezone change, daylight saving change, manual clock change, or location change, **When** it happens, **Then** alerts are rescheduled automatically.
10. **Given** iPhone's limit of 64 pending notifications, **When** the app runs or the OS grants background time, **Then** the app refreshes a rolling schedule within that limit.
10a. **Given** the app has not been opened for a long time, **When** the scheduled alerts are about to run out, **Then** on Android the schedule covers about 60 days ahead (rebuilt on every launch) and a notification asks the user to open the app about 7 days before it ends; on iPhone the last pending notification asks the same. The Reliability check always shows the date alerts run until.
11. **Given** the home screen, **When** the user taps the Reliability check entry, **Then** one tap opens a screen showing permission state, the next 5 scheduled alerts, the last alert result, a "send a test Azaan in 1 minute" button, and plain instructions to fix each problem.
12. **Given** an alert that did not fire, **When** the user next opens the app, **Then** the app tells them and gives the likely cause.

---

### User Story 4 - Qibla (Priority: P2)

A user sees an arrow pointing to the Qibla, with the bearing in degrees and in words, working offline.

**Why this priority**: A common daily need, but prayer times and alerts matter more.

**Independent Test**: Compare shown bearing for 10 reference cities against reference values after calibration.

**Acceptance Scenarios**:

1. **Given** a location, **When** the user opens Qibla, **Then** the arrow and a text such as "212 degrees, southwest" are shown, based on the great-circle bearing.
2. **Given** sensor accuracy is low, **When** the compass is in use, **Then** an accuracy indicator and calibration prompt are shown, and magnetic interference triggers a warning.
3. **Given** the device is held flat or upright, **When** the user turns, **Then** the heading remains correct.
4. **Given** a device with no compass, **When** the user opens Qibla, **Then** the bearing is shown in degrees with an explanation of how to use it.
5. **Given** the user is at or near the Kaaba, **When** Qibla opens, **Then** the app shows "you are at the Haram".

---

### User Story 5 - Tasbih counter (Priority: P2)

A user counts remembrance with a large tap target, targets, and history that persists.

**Why this priority**: Useful daily companion, independent of alerts.

**Independent Test**: Count, kill the app, reboot, and confirm the count and history remain.

**Acceptance Scenarios**:

1. **Given** the counter, **When** the user taps, **Then** the count increases with haptic feedback and optional sound.
2. **Given** target options, **When** the user chooses 33, 99 or a custom value, **Then** the app signals when the target is reached.
3. **Given** a count, **When** the user resets, **Then** a confirmation is required.
4. **Given** daily use, **When** the user opens history, **Then** daily totals are shown.
5. **Given** optional modes, **When** enabled, **Then** the screen stays awake, volume keys count (Android), and a lock prevents accidental taps.
6. **Given** the app is killed or the device reboots, **When** reopened, **Then** the state is preserved.

---

### User Story 6 - Adhkar (Priority: P2)

A user reads scholar-reviewed adhkar collections with progress tracking and optional reminders.

**Why this priority**: Adds daily worship value but depends on content review.

**Independent Test**: Open each collection offline, complete one session, and confirm progress, bookmarks and About-screen attribution.

**Acceptance Scenarios**:

1. **Given** collections, **When** the user browses, **Then** morning, evening, after prayer, before sleep, waking and other Hisn al-Muslim collections are available.
2. **Given** an entry, **When** shown, **Then** it displays Arabic, transliteration, translation, repeat count and source reference.
3. **Given** a session, **When** the user works through entries, **Then** progress is tracked per session and entries can be bookmarked.
4. **Given** reminders are opted in, **When** the time arrives, **Then** morning reminders are timed relative to Fajr and evening reminders relative to Asr or Maghrib.
5. **Given** the About screen, **When** opened, **Then** each text's reviewer and source are shown.

---

### User Story 7 - Settings, accessibility, data (Priority: P3)

A user adjusts appearance and accessibility, moves settings between devices, and deletes all data.

**Why this priority**: Important for trust and inclusion but does not block the core prayer flow.

**Independent Test**: Operate every screen with a screen reader, export then import settings, then delete all data.

**Acceptance Scenarios**:

1. **Given** settings, **When** the user picks dark or light theme, text size, or high contrast, **Then** all screens follow.
2. **Given** any screen, **When** used with a screen reader or one hand, **Then** every control is reachable and no information is conveyed by color alone.
3. **Given** settings, **When** the user exports and later imports a file, **Then** their settings are restored.
4. **Given** "delete all my data", **When** confirmed, **Then** all app data is removed from the device.
5. **Given** the About screen, **When** opened, **Then** it shows open-source licenses, content sources and attributions, scholar reviewers and the privacy policy.

---

### Edge Cases

- Polar day and polar night, where some prayer times do not occur naturally.
- A location on the date line.
- A device clock that is wrong; the app warns.
- A user who has not moved but whose timezone rule changed.
- Every permission refused during setup.
- Two alert triggers for the same prayer (for example, after a reschedule): only one Azaan may play.
- The device is rebooted or the app updated between scheduling and the alert time.
- User is on a call, or on headphones, when an Azaan fires.
- Quiet hours overlap an alert time: the alert becomes a silent notification unless the prayer ignores quiet hours; the Reliability check lists it as "silenced by quiet hours", not as missed.
- The user is near the Kaaba, or the compass reports interference indoors.
- Data export imported on a device with a different language or timezone.
- Exact-alarm permission refused on Android: alerts still fire as inexact notifications and the Reliability check shows the reduced precision.
- A location in a region with no regional default: the app suggests Muslim World League and explains that it is a general default.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The app MUST work fully offline after install.
- **FR-002**: The app MUST NOT collect, transmit or store personal data off the device, and MUST NOT include analytics, ad or tracking SDKs.
- **FR-003**: Prayer times MUST be calculated on the device.
- **FR-004**: A Reliability check MUST exist and be reachable from the home screen in one tap.
- **FR-005**: Every prayer MUST produce at most one audible Azaan per device.
- **FR-006**: Loud mode (overriding silent mode on Android) MUST be off by default and opt-in per prayer, MUST offer "keep my current volume" and "gentle ramp", and MUST NOT change system volume without opt-in.
- **FR-007**: Every user-facing string MUST be localizable. English, Arabic, Urdu and Bahasa Indonesia MUST all ship, each reviewed by a native speaker before release.
- **FR-008**: Every bundled audio, text, font and dataset MUST have a recorded source, license and reviewer. Azaan recordings MUST be CC0, CC-BY, or recorded with a Muazzin's signed written license, MUST be scholar-reviewed for pronunciation and wording, and MUST be listed in content/LICENSES.md before they ship. The offline city list (GeoNames, CC-BY) MUST carry attribution.
- **FR-009**: Users MUST be able to choose a calculation method, Asr method, high-latitude rule, per-prayer offset and Hijri adjustment, and changes MUST apply to all screens and alerts at once. The suggested method by region is: MWL for Europe and the Far East, ISNA for North America, Umm al-Qura for the Arabian Peninsula, Egypt for Africa and the Middle East outside the Peninsula, Karachi for South Asia, Diyanet for Turkey, Singapore for Southeast Asia; the user can always override.
- **FR-010**: Alerts MUST be rescheduled automatically after reboot, app update, timezone change, daylight saving change, manual clock change and location change, and the app MUST warn the user before the scheduled alerts run out (see Story 3, scenario 10a).
- **FR-011**: The app MUST explain each permission before requesting it, and MUST keep working with degraded features if any permission is refused. On Android, exact-alarm permission MUST be requested, after a plain explanation, in setup and whenever the user turns on an audible alert or a reminder while it is not granted; refusing it MUST NOT block setup.
- **FR-012**: Settings MUST be exportable and importable as a local file, and the user MUST be able to delete all data from the device.
- **FR-013**: All controls MUST be operable with a screen reader, and no information MAY be conveyed by color alone.

### Key Entities

- **Location**: the user's saved place (coordinates or offline-list city, timezone); stored only on the device.
- **Prayer Settings**: calculation method, Asr method, high-latitude rule, per-prayer offsets, Hijri adjustment.
- **Alert Preference**: per prayer, one of off / silent / vibrate / short tone / full Azaan, plus voice choice, reminders, an "ignore quiet hours" switch (default off), and (Android) loud mode off/on with a volume choice of keep-current or gentle ramp.
- **Scheduled Alert**: a planned alert with prayer, time, type and result (fired, missed, suppressed).
- **Azaan Voice**: a named voice with three bundled recordings (standard, Fajr, Shia wording), each with its own source, license and reviewer.
- **Tasbih Session**: counts, target and daily totals.
- **Adhkar Entry / Collection**: Arabic text, transliteration, translation, repeat count, source reference, reviewer; plus bookmarks and session progress.
- **Content Record**: source, license and reviewer for each bundled asset.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A new user completes first-run setup in 90 seconds or less.
- **SC-002**: 99% of local alerts fire within 5 seconds of the calculated time on the supported device matrix over 7 days, including reboots and timezone changes, and no prayer ever produces two Azaans. On Android this applies when exact alarms are allowed; inexact fallback alerts are excluded and flagged in the Reliability check.
- **SC-003**: Prayer times are within 1 minute of an independent calculation from the published formulas for 20 cities, every calculation method and both Asr schools, across a full year, and within 2 minutes of hand-checked samples from official tables wherever an official table exists for that method and city.
- **SC-004**: The app opens to the next prayer in under 2 seconds on a mid-range 2020 phone.
- **SC-005**: Background battery use is under 1% per day.
- **SC-006**: Every screen is fully operable with a screen reader.
- **SC-007**: Store listings declare "no data collected".
- **SC-008**: The Qibla bearing is within 3 degrees of a reference bearing after calibration for 10 cities.

## Constitution Check

Principles that apply to Phase 0 (constitution v1.1.0) and how the requirements meet them:

| Principle | How this spec meets it |
|-----------|------------------------|
| 1 Local-first reliability | FR-001, FR-003; alerts are scheduled on the device; no server exists |
| 2 Platform honesty | Platform behavior in this spec is cited in "Platform Behavior References" below; the iPhone silent-switch and Android exact-alarm behavior is stated as documented, with device confirmation before release |
| 3 User consent and respect | FR-006 (loud mode opt-in, per prayer, off by default); Story 3 scenarios 3, 4, 7; content sources and reviewers FR-008 |
| 4 Privacy by design | FR-002; location stays on the device (Story 1); no accounts; "delete all my data" (FR-012) |
| 7 Religious and cultural correctness | FR-009 (14 methods, both Asr schools, high-latitude rules, offsets, Hijri adjustment); SC-003 defines how times are verified |
| 8 Testing and quality gates | SC-001 to SC-008 are measurable; the device matrix and 7-day soak are in the plan |
| 9 Simplicity and scope control | Out of Scope below; Phase 0 only |
| 10 Open source and zero cost | FR-008; all content freely redistributable; see Infrastructure Cost |
| 11 Accessibility and localization | FR-007, FR-013; SC-006 |
| 5, 6 Broadcast security, audio delivery | Not applicable in Phase 0 (no broadcasting) |

## Infrastructure Cost

Phase 0 has no server, domain or hosting, so the expected recurring infrastructure cost is zero. The only
fees are the store developer programs (Apple Developer Program, Google Play developer fee), which the
constitution's Exceptions Register already allows. A privacy-policy URL is required by both stores; where it
is hosted is an open decision (plan D-5).

## Platform Behavior References

The platform claims in this spec rest on the sources recorded, with their verification status, in
[research.md](research.md): exact-alarm permission and defaults (R-A1), alarm types and Doze (R-A2),
foreground-service start rules (R-A3), battery-optimization policy (R-A4), boot and time-change receivers
(R-A5), audio focus, notification permission and channels (R-A6); iPhone notification limits, sound length and
silent switch (R-I1 to R-I3), refresh options (R-I5), and store privacy declarations (R-A7, R-I7). Behavior
marked UNVERIFIED there is confirmed on real devices before release.

## Out of Scope

Any server, account, live stream, Masjid directory, community feature, Quran reader, home-screen widgets (Phase 4), AR Qibla (Phase 4), and payments.

## Assumptions

- Minimum supported OS is Android 8.0 and iOS 16.
- Users have a phone with a working clock.
- Azaan recordings are openly licensed (CC0 or CC-BY) or recorded with a consenting Muazzin under a signed written license.
- Scholar reviewers for Azaan audio and Adhkar texts are identified before release; content without a recorded reviewer does not ship.
- Qibla uses the device's standard compass; AR is deferred to Phase 4.
- iPhone alerts are bound by OS limits on notification sound length and pending notifications, and the iPhone silent switch mutes the notification sound (but not in-app playback started by the user's tap); the app informs the user rather than working around these. Apple's documented behavior for in-app playback is confirmed on a real device before release.
- The "supported device matrix" is defined in the plan and includes Pixel, Samsung, Xiaomi and iPhone on the current and previous iOS.
- The sensible high-latitude default above 48 degrees is chosen during planning and documented for the user: the seventh-of-the-night rule above 48 degrees latitude, middle of the night otherwise.
- Defaults implemented and confirmed by the product owner on 2026-10-22 (plan D-14, D-15, task T003): the Shia-wording recording plays at every prayer, including Fajr, because that wording has no "as-salatu khayrun min an-nawm"; Imsak is 10 minutes before Fajr and configurable; a reminder never plays the full Azaan (it uses the short tone); a wrong device clock is detected offline when the clock is earlier than the app's build date, jumps backward by more than 2 minutes between launches, or drifts by more than 5 minutes against the phone's monotonic clock.
