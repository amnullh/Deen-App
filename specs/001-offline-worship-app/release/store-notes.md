# Store submission notes (task T189)

Status: draft prepared from the repository on 2026-10-21. Nothing here has been entered into Play Console or App
Store Connect. Sources: [research.md](../research.md) (R-A1, R-A3, R-A6, R-A7, R-I3, R-I4, R-I5, R-I7),
`apps/mobile/android/app/src/main/AndroidManifest.xml`, `apps/mobile/ios/Runner/Info.plist`,
[plan.md](../plan.md) (D-5, D-6), [data-model.md](../data-model.md). Evidence tags are the ones used in
research.md. Console wording changes over time: where a label below is marked UNVERIFIED, read the live console
before answering.

The Play foreground-service declaration has its own file: [play-fgs-declaration.md](play-fgs-declaration.md).
The privacy policy is `content/privacy/privacy-policy.md`.

## 1. Facts the answers rest on

| Fact | Where it is enforced or visible |
|------|---------------------------------|
| No server, no account, no analytics, no ads, no trackers | plan.md constitution check 4; `tools/license_scan/bin/check_network.dart` fails CI on a tracker SDK |
| Release Android build does not declare `INTERNET` | Main manifest does not list it. Only the debug and profile manifests add it (Flutter hot reload); `check_network.dart` checks the main manifest because only it ships |
| Location is read in the foreground only and stays on the device | Android `LocationApiImpl.kt` (no background location permission); iOS has only `NSLocationWhenInUseUsageDescription`; plan D-6 |
| The user can decline location and pick a city from the built-in list | AndroidManifest comment; spec Story 1; Info.plist text "You can choose a city instead." |
| Settings export is a file the user creates and shares | `lib/data/export/export_file_io.dart` (share sheet or save dialog); the export contains the saved location (`settings_export_service.dart`, and the in-app warning `settingsExportWarning`) |
| "Delete all my data" | `lib/domain/delete_all_data.dart`: cancels scheduled alerts, deletes the native alert snapshot and journal, empties every database table, deletes the app's export copies |

The merged release manifest (after plugins are merged) must be checked once from a real build: this repository
cannot build Android here, so "no INTERNET in the merged release manifest" is **not yet verified on a built APK or
bundle**. See the checklist.

## 2. Google Play: Data safety form

Basis (R-A7, VERIFIED): "collect" means transmitting data off the device. Data processed only on the device need
not be disclosed, so on-device location does not need declaring. The form and a privacy-policy URL are still
required. Any third-party SDK that sends data off the device would count as collection; the app has none.
Source: https://support.google.com/googleplay/android-developer/answer/10787469

| Console question | Answer | Why |
|------------------|--------|-----|
| Does your app collect or share any of the required user data types? | **No** | Nothing is transmitted off the device. No network permission, no SDK that sends data |
| Location (approximate, precise) | Not declared as collected | Processed on the device only to calculate prayer times and Qibla; never transmitted (R-A7) |
| Personal info, financial info, health, messages, photos, audio, files, calendar, contacts, app activity, web browsing, device or other IDs | Not collected | The app has no account, no analytics, no advertising ID use |
| Is all of the user data collected by your app encrypted in transit? / Can users request that data be deleted? | The console may not ask these when the first answer is No | UNVERIFIED: confirm in the console. For reference, the in-app "Delete all my data" exists (FR-012) |
| Privacy policy URL | `TODO(url): privacy policy URL, decided in T005 / plan D-5` | Required even though no data is collected |

Other Play declarations that exist and are not answered here (the team must complete them in the console; their
wording was not researched): app content questionnaire (ads: the app has none), target audience, and the Play
exact-alarm and foreground-service declarations covered below. Account-deletion URL: the app has no accounts, so
it should not apply (UNVERIFIED; confirm in the console).

## 3. App Store: App Privacy label

Basis (R-I7, VERIFIED): "collect" means transmitting data off the device, so on-device data is not collected. A
privacy-policy URL is required for all apps. The exact label wording "Data Not Collected" is UNVERIFIED; the
console offers the answer below.

- Question "Do you or your third-party partners collect data from this app?": answer
  **"No, we do not collect data from this app"**.
- Privacy Policy URL (required): `TODO(url): privacy policy URL, decided in T005 / plan D-5`.
- Tracking: the app does not track users; Info.plist has no tracking keys and `check_network.dart` checks for
  them. No App Tracking Transparency prompt is needed or implemented.
- Sources: https://developer.apple.com/app-store/app-privacy-details/ and
  https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/

## 4. Permission justifications

User-visible reason means the text or screen the user actually meets. Android permission names are those in
`AndroidManifest.xml` (main).

### Android

| Permission | Why the app needs it | User-visible reason | Notes |
|------------|----------------------|---------------------|-------|
| `SCHEDULE_EXACT_ALARM` | Prayer alerts must sound at the prayer time the app calculated, not minutes later. The planner marks alerts as not precise when this is missing | Setup and alert settings show "Allow exact alarms?": "To sound at the exact prayer time, Android needs the 'Alarms & reminders' permission for Deen App. Without it, alerts still arrive but may be a few minutes late." The user can continue without it | User-granted on Android 14+ (denied by default for new installs). Request is made after that explanation (R-A1). `USE_EXACT_ALARM` is deliberately not declared |
| `POST_NOTIFICATIONS` | Prayer alerts, reminders, the "open the app to renew alerts" notice, and the Azaan notification with its Stop button | Requested when the user turns on alerts or sends a test Azaan; the test refuses with "Allow notifications first, then try again." | Runtime permission on Android 13+. If refused, the app still works (times, Qibla, Tasbih, Adhkar) and the Reliability check shows the state (R-A6) |
| `FOREGROUND_SERVICE` | `AzaanPlaybackService` runs as a foreground service so the full Azaan can play with the screen off | The user sees the ongoing notification with a Stop button while the Azaan plays | Normal permission, auto-granted (R-A3) |
| `FOREGROUND_SERVICE_MEDIA_PLAYBACK` | The service type is `mediaPlayback`; Android 14+ requires the matching permission | Same as above | Normal permission, auto-granted (R-A3). Declaration: [play-fgs-declaration.md](play-fgs-declaration.md) |
| `RECEIVE_BOOT_COMPLETED` | Alarms are cancelled when the phone shuts down; the boot receiver re-registers the user's schedule | Not shown. The user-visible effect is that alerts keep sounding after a restart | The receiver only re-registers alarms; it never starts the playback service (Android 15 forbids that, R-A3) |
| `VIBRATE` | The "Vibrate" alert type and the vibrate notification channel; a short vibration when an Azaan is cut short by a phone call | The user picks "Vibrate" per prayer in Prayer alerts | Normal permission |
| `WAKE_LOCK` | Keeps the CPU awake while the Azaan plays with the screen off (`MediaPlayer.setWakeMode`) | Not shown; the Azaan plays to the end after the phone is locked | Normal permission |
| `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION` | Find the user's position to calculate prayer times and the Qibla bearing, once, in the foreground | Setup and location settings; the system prompt appears only when the user chooses "use my location". The app text states the location stays on the device. If the user grants only approximate, that is accepted | No background location. Optional: manual city list is the alternative. Both `uses-feature` location entries are `required="false"` |

Not declared on purpose (so a reviewer will not find them): `INTERNET`, `ACCESS_NETWORK_STATE`,
`USE_EXACT_ALARM`, `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` (the app only links to the system battery settings,
R-A4), `READ_PHONE_STATE` (audio focus is used instead, R-A6), `USE_FULL_SCREEN_INTENT` (R-A6),
`ACCESS_BACKGROUND_LOCATION`.

### iOS (`Info.plist`)

| Entry | Value | Why | User-visible reason |
|-------|-------|-----|---------------------|
| `NSLocationWhenInUseUsageDescription` | "Your location is used only on this device, to calculate prayer times and the Qibla direction. It is never sent anywhere. You can choose a city instead." | Calculate prayer times and Qibla in the foreground | This exact text is the system prompt. Declining falls back to the manual city list (guideline 5.1.1(iv), R-I7) |
| `UIBackgroundModes` = `audio` | Declared only so that, after the user taps the Azaan notification and the app plays the Azaan, playback continues if the user locks the screen or switches app (R-I4) | The user hears the whole Azaan after tapping the notification | The app does **not** loop silent audio to stay alive (App Review 2.5.4 risk, R-I4). Nothing in the docs says this mode lets a suspended app start playback by itself (R-I4) |
| `UIBackgroundModes` = `fetch` plus `BGTaskSchedulerPermittedIdentifiers` = `org.deenapp.mobile.refresh` | A best-effort `BGAppRefreshTask` that rebuilds the notification schedule so alerts do not run out (R-I5) | Not shown. The effect is that scheduled prayer notifications keep being refreshed even if the user does not open the app daily | Short task, no guaranteed launch time. The schedule is also rebuilt every time the app is opened |
| Notification permission | No Info.plist key; requested at runtime | Prayer alerts as notifications | The scheduler contract says to ask only after the app explained why (`alert_scheduler.dart`). Time Sensitive and Critical Alerts are not used (R-I6) |

## 5. Reviewer notes (paste into both consoles)

Both consoles allow review notes (Play: App access / notes to reviewer where offered; App Store Connect: App
Review Information, Notes). Suggested text, adapt to the field length:

> Deen App is a fully offline prayer-time app. It has no server, no account, no sign-in and no network access, so
> there is nothing to log in to and no demo account is needed. It collects no data.
>
> The call to prayer (Azaan) is a user-scheduled alert, in the same way a clock app's alarm is. Nothing plays
> unless the user has chosen it. In "Prayer alerts" the user picks, for each of the five prayers, what happens at
> that prayer time: off, silent notification, vibrate, short tone, or full Azaan. The prayer time itself is
> calculated on the device from the user's location or chosen city.
>
> To see it quickly: open the Reliability check (the shield icon on the home screen), allow notifications, and tap
> "Send a test Azaan in 1 minute". Lock the phone and wait one minute.
>
> Android: at the time the user chose, an exact alarm (the user granted "Alarms & reminders") starts a foreground
> service of type mediaPlayback that plays the full Azaan. The notification has a Stop button. The service stops
> when the recording ends or the user taps Stop. It is never started at boot; the boot receiver only re-registers
> the user's alarms.
>
> iOS: at the chosen time the app posts a local notification with a short sound. The full Azaan plays in the app
> when the user taps the notification. The `audio` background mode only lets that playback continue if the user
> locks the screen or switches app; the app does not play silent audio to stay running. The `fetch` mode is used
> by a best-effort app-refresh task that rebuilds the schedule.
>
> Location (When In Use / foreground only) is used on the device for prayer times and the Qibla direction and is
> never transmitted. Declining it leaves a built-in city list.

Statements in that text that depend on device confirmation and must be re-checked before submission: the iOS
tap-to-play with the silent switch on (spike S8), foreground-service start from the alarm on Pixel, Samsung and
Xiaomi (spike S1), and the Android alarm type and its status-bar icon (spike S7). Do not paste claims into the
console that the device matrix has not confirmed.

## 6. Pre-submission checklist

Open items from the plan are listed unchecked. Do not tick one without the evidence named next to it.

Policy and hosting
- [ ] T005: privacy-policy hosting decided (plan D-5); if GitHub Pages is used, the Exceptions Register in the
      constitution is amended first
- [ ] Policy published at a public URL and opens without login
- [ ] Policy URL entered in the app (the About screen shows "policy pending" until the URL is supplied through its
      `privacyPolicyUrlProvider`), in Play Console and in App Store Connect
- [ ] Privacy contact placeholder `TODO(contact): privacy contact address` replaced in all four languages of
      `content/privacy/privacy-policy.md`
- [ ] Arabic, Urdu and Indonesian policy text reviewed by native speakers (T186-style review), review recorded in
      `content/LICENSES.md`

Build and declarations
- [ ] Merged release manifest of a real build has no `INTERNET` and lists exactly the permissions in section 4
      (Android build not possible in the authoring environment)
- [ ] `tools/license_scan` and `check_network.dart` green in CI (T192)
- [ ] Play: Data safety form submitted with the section 2 answers
- [ ] Play: exact-alarm declaration or questionnaire completed if the console asks for one (UNVERIFIED that it does)
- [ ] Play: foreground-service (`mediaPlayback`) declaration submitted, see [play-fgs-declaration.md](play-fgs-declaration.md)
- [ ] T190 video recorded and uploaded (manual task, see play-fgs-declaration.md)
- [ ] App Store: App Privacy answered "No, we do not collect data from this app"
- [ ] Reviewer notes from section 5 pasted in both consoles
- [ ] Listing display name decided: the repository still has placeholder names (`android:label="deen_mobile"`,
      `CFBundleDisplayName` "Deen Mobile")

Device evidence the notes rely on
- [ ] Spike S1 (foreground service from the alarm), S7 (alarm icon), S8 (iOS silent switch), S6 and S11 recorded
- [ ] T194 device matrix sign-off (Pixel, Samsung, Xiaomi, Oppo or Vivo, iPhone on current and previous iOS)

Final gate
- [ ] SC-007 / T197: with the real store listings open, confirm both declare "no data collected", and record the
      confirmation here (date, who, screenshot or console export). **Not done: it needs the real listings.**

Confirmation record for T197 (leave blank until the listings exist):

| Store | Listing shows "no data collected" | Date | Confirmed by |
|-------|-----------------------------------|------|--------------|
| Google Play | | | |
| App Store | | | |

## 7. Risks reviewers may raise

1. **Exact alarm declaration, `SCHEDULE_EXACT_ALARM` versus `USE_EXACT_ALARM` (R-A1).** `USE_EXACT_ALARM` is
   auto-granted and cannot be revoked, but Play limits it to apps whose core function is an exact alarm (the
   examples are alarm, timer and calendar apps; a prayer app is not named; PARTIAL). Non-qualifying apps can be
   barred from publishing, so the app declares `SCHEDULE_EXACT_ALARM`, the user-granted permission, and falls back
   to inexact timing if the user refuses. Risk: a reviewer may ask why an app needs exact alarms; the answer is the
   user-scheduled prayer-time alert. If Play accepts the justification, `USE_EXACT_ALARM` may be revisited (R-A1).
   The Play policy pages are only PARTIALLY read (answers 9888170 and 16558241 in R-A1), so read the live policy
   before submitting.
2. **Foreground service declaration (R-A3).** Play needs a description, the user impact and a video, and the video
   must show a user-initiated start. An alarm-triggered Azaan is not user-initiated at play time, so the
   declaration frames it as a user-scheduled alert and we expect review friction. Android 14+ requires the
   `mediaPlayback` type and its permission. The background-start exemption "your app invokes an exact alarm to
   complete an action that the user requests" applies on its face, but the page does not say which alarm API
   qualifies and does not mention `setAlarmClock`, which the app uses for prayer alerts (spike S1). If the service
   cannot start, the app posts a notification whose sound is the Azaan and records `failed:fgs_blocked`.
3. **Background audio mode on iOS (R-I3, R-I4).** `UIBackgroundModes: audio` can draw App Review questions
   (guideline 2.5.4). It is declared only to continue playback the user started by tapping the notification; the
   app does not use silent looping audio. Guideline 2.5.9 forbids altering the Ring/Silent switch behaviour; the
   app uses the documented `.playback` category after a user tap, which is our reading of the guideline, and the
   device confirmation (S8) is pending. A reviewer may also notice that iOS cannot start the full Azaan with no
   user action, which is why the notes say "tap to play".
4. **Location (R-I7).** Guidelines 5.1.1(ii), 5.1.1(iv) and 5.1.2(i): clear purpose text, an alternative when
   location is declined (the city list) and no location requirement to use the app. The app satisfies these as
   designed.
5. **Notification-only features.** The app asks for notification permission after explaining why and works without
   it, but its main value (alerts) needs it. Describe this honestly in the listing.
