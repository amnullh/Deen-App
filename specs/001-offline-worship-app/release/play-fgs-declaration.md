# Play Console foreground-service declaration: `mediaPlayback` (task T190)

Status: text drafted from the repository on 2026-10-21. It has not been entered in Play Console. **The demo
video has not been made and cannot be produced by an agent: recording a real device is a manual task (section 5).**
T190 stays open until the video exists and the declaration is submitted.

Sources, all from [research.md](../research.md) R-A3 unless noted: foreground service must be declared in the
Play Console with a description, the user impact and a video; the video must show a user-initiated start;
autoplaying audio does not qualify; an alarm-triggered Azaan is not user-initiated at play time, so it is framed as
a user-scheduled alert and review friction is expected. That risk assessment is ours.

Documentation (the URLs listed in R-A3, nothing else):
- https://support.google.com/googleplay/android-developer/answer/13392821 (VERIFIED)
- https://support.google.com/googleplay/android-developer/answer/16965181 (VERIFIED)
- https://developer.android.com/develop/background-work/services/fgs/restrictions-bg-start (VERIFIED)
- https://developer.android.com/about/versions/15/behavior-changes-15 (VERIFIED)
- https://developer.android.com/develop/background-work/services/fgs/service-types (VERIFIED)
- https://developer.android.com/about/versions/14/changes/fgs-types-required (VERIFIED)
- https://developer.android.com/develop/background-work/services/fgs/timeout (PARTIAL)

The exact field names and the list of use cases in the console were not read for this document. Match the text
below to the fields the console shows, and do not change its meaning.

## 1. What the manifest declares (the facts the text is built on)

From `apps/mobile/android/app/src/main/AndroidManifest.xml`:

- `<service android:name=".AzaanPlaybackService" android:exported="false" android:directBootAware="true"
  android:foregroundServiceType="mediaPlayback"/>`
- permissions `FOREGROUND_SERVICE` and `FOREGROUND_SERVICE_MEDIA_PLAYBACK` (normal permissions)
- the service is started only by `AlarmReceiver`, for an alarm the user scheduled (`SCHEDULE_EXACT_ALARM`). The
  boot receiver (`SystemEventReceiver`) only re-registers alarms and never starts the service, because apps
  targeting Android 15 may not start a `mediaPlayback` service from a `BOOT_COMPLETED` receiver (R-A3).
- the service calls `startForeground` first, then checks the arbiter, then requests audio focus; it plays the
  bundled recording with `MediaPlayer` and no Dart engine; the ongoing notification has a Stop action; losing audio
  focus (for example an incoming call) stops playback and vibrates instead (`AzaanPlaybackService.kt`).
- audio is a bundled recording of the call to prayer; the app has no network permission, so it cannot stream.

## 2. Use case selection

- Foreground service type: **Media playback** (`mediaPlayback`), the type declared in the manifest. The service
  plays an audio recording the user chose.
- The console may list use cases or sub-options under this type. Pick the one that means "the app plays audio the
  user asked for". Its exact label is UNVERIFIED: read it in the console. Do not choose a type the manifest does
  not declare, and do not choose a use case about navigation, calls or communication.
- Related policy statement to keep consistent with the manifest: the Android 14 page requires every foreground
  service to declare a type, and `mediaPlayback` is a type in the service-types page.

## 3. Text for the declaration

Paste the following, shortening only if the console limits length.

### Description (what the foreground service does)

> Deen App is an offline prayer-time app. The user chooses, for each of the five daily prayers, to hear the call to
> prayer (the Azaan, a bundled audio recording) at the prayer time. The app calculates the time on the
> device and schedules an exact alarm that the user has allowed. When that alarm fires, a foreground service of
> type mediaPlayback plays the user-chosen recording with MediaPlayer. While it plays, the service shows an
> ongoing notification with a Stop button. The service ends when the recording finishes or when the user taps Stop.
> It stops playing and vibrates instead if a phone call takes the audio focus. It is never started at device boot
> and it never runs without the user having scheduled the alert. The app has no network access and plays only a
> recording bundled in the app.

Check before submitting: the length of the recordings. R-A3 says only "An Azaan lasts minutes"; measure the
bundled recordings and replace "a few minutes" with the real longest duration.

### User impact if the service is deferred or interrupted

> The user chose a specific time for the call to prayer. If Android deferred the service, the call to prayer would
> start late or not at all, and the user, who relies on it to know that the prayer time has arrived, could miss
> it. If the service were interrupted partway, the Azaan would stop in the middle of the call, which is
> disrespectful to the content and leaves the user not knowing whether the prayer time has started. A normal
> background task or a notification alone cannot play a full recording with the screen off for its whole length.

What the app does when the service cannot run (so the statement above stays honest): it posts a notification on a
channel whose sound is the bundled Azaan and records `failed:fgs_blocked` in the alert journal (R-A3). That tone
is a fallback and is not the full Azaan on every device. If a call interrupts playback, the app vibrates and
records `suppressed:call_in_progress`.

### Why the start is allowed from the background

> The service is started by an exact alarm that the user scheduled, to complete an action the user requested.

R-A3: the documented exemption reads "Your app invokes an exact alarm to complete an action that the user
requests". The page does not say which alarm API qualifies and does not mention `setAlarmClock`; the app uses
`setAlarmClock` for prayer alerts (plan R-A2). Whether the service really starts from that alarm is spike S1 and
needs the device matrix (Pixel, Samsung, Xiaomi on Android 14 and 15). Do not submit a statement that S1 has not
confirmed.

### Additional statements for the reviewer

- No `INTERNET` permission, no account, no data collection.
- A user can switch the Azaan off, for any prayer, in Prayer alerts at any time.
- The service is not exported; the alarm receiver is not exported.
- Not used: `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`, `USE_FULL_SCREEN_INTENT`, `USE_EXACT_ALARM`.

## 4. Demo video: framing and script

Requirement from R-A3: the video must show a user-initiated start. The video therefore must show the user
scheduling the alert, and then the alert playing at the time the user chose. It must not show the Azaan starting
on its own with no scheduling step, because autoplaying audio does not qualify.

Do not show anything the app does not do. Do not edit the video to make the alarm appear to be a user tap.

### What to prepare

- A real Android device (Android 14 or 15), the release build or one with the same manifest, and a screen
  recorder plus a second camera or phone to film the locked device (the system screen recorder may not capture the
  lock screen). Narrate or caption in English; add captions in the language the console allows.
- Notifications allowed and the "Alarms & reminders" setting allowed (show these steps; they are part of the
  user-initiated story). Phone volume at a level that records.
- Quick check first: the real UI labels are those in `apps/mobile/lib/l10n/app_en.arb`: "Prayer alerts", "Full
  Azaan", "Reliability check", "Send a test Azaan in 1 minute", "Stop".

### Storyboard

| # | Shot | What the viewer sees | Caption or narration |
|---|------|----------------------|----------------------|
| 1 | Home screen | The prayer times for today. Narrate that the app is offline and calculates times on the device | "Deen App works offline. This is the user's own prayer schedule." |
| 2 | More menu, then "Prayer alerts" | The five prayers with the alert type for each | "The user chooses what happens at each prayer time." |
| 3 | Choose "Full Azaan" for one prayer | The selection changes to "Full Azaan" | "The user schedules the Azaan for this prayer." |
| 4 | The permission step | The "Allow exact alarms?" screen, then the system Alarms & reminders setting turned on; the notification permission prompt allowed | "The user allows exact alarms and notifications." |
| 5 | Reliability check (the shield icon on the home screen) | Permissions are shown as OK, and the next scheduled alerts are listed | "The app shows what is scheduled." |
| 6 | Tap "Send a test Azaan in 1 minute" | The message "Test Azaan set for {time}. Lock your phone and wait." | "The user asks for a test alert one minute from now." |
| 7 | Lock the phone | Press the power button on camera; clock visible | "The user locks the phone." |
| 8 | Wait one minute | Show the time on the lock screen, the screen stays locked | "The phone stays locked." |
| 9 | The Azaan plays | The lock screen shows the ongoing notification with a Stop button; the audio is audible and the recording is audible on the video | "At the time the user chose, the foreground service plays the Azaan." |
| 10 | Tap Stop | The Azaan stops and the notification disappears | "The user can stop it at any time." |
| 11 | Optional | Reopen Prayer alerts and set the prayer to Off | "The user can switch it off." |

Notes for the person recording:
- The test alert is requested as a full Azaan (`DeliveryType.fullAzaan`) and goes through the same alarm path as a
  real prayer alert. Confirm on the device that the Stop-button notification appears before relying on this, then
  say in the narration that real alerts behave the same.
- Keep every step in one continuous take, or label cuts, so the one-minute wait is not hidden.
- Do not include any private location in the video: use a city from the built-in list.
- Upload to a place the console accepts (a link or file as the console asks; the form was not researched).

## 5. What an agent cannot do here, and what is still open

- **The video cannot be produced by an agent.** It needs a physical Android device, a screen recording and a
  camera. This is a manual task for a person.
- The declaration cannot be entered by an agent: it needs the Play Console account and the app listing.
- Open items before submission:
  - [ ] Measure the length of the bundled Azaan recordings and complete the description
  - [ ] Spike S1 result (service starts from the alarm on Pixel, Samsung and Xiaomi, Android 14 and 15)
  - [ ] Spike S7 result (alarm type and its status-bar icon), because the description names the alarm
  - [ ] Read the live console fields and use-case options, then adjust section 3
  - [ ] Record the video from the storyboard and attach it
  - [ ] Submit the declaration and record the date and the result in [store-notes.md](store-notes.md)
