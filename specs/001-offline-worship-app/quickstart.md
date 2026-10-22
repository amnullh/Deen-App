# Quickstart: Build, Test and Validate Phase 0

**Date**: 2026-10-21 | **Plan**: [plan.md](plan.md)

This is a run-and-validate guide. Nothing is implemented yet; commands and results below describe how Phase 0 is
validated once tasks are done. Details live in the linked contracts and data model.

## Prerequisites

- macOS (required for iOS builds), Xcode current, Android Studio with SDK for API 26 and the current target SDK.
- Flutter 3.44 or newer and Dart 3.12 or newer. Flutter was not installed on the machine used for planning, so
  confirm versions first: `flutter --version`.
- Turn off tool telemetry: `flutter --disable-analytics` and `dart --disable-analytics`.
- Own devices for the matrix: Pixel, Samsung, Xiaomi, Oppo or Vivo, and an iPhone on the current and previous
  iOS (two phones or two OS versions over time).
- A Fajr-capable test environment: set the device clock and time zone through system settings.

## 1. Set up

```bash
git clone https://github.com/amnullh/Deen-App.git && cd Deen-App
scripts/setup.sh                              # analytics off, Flutter 3.44+ check, resolves the Dart workspace
dart run tools/geonames_build/bin/build.dart  # builds content/cities/cities.db (downloads GeoNames; one-off, about 200 MB)
dart run tools/sync_content/bin/sync.dart     # copies content into the app and platform folders
dart run tools/l10n_merge/bin/merge.dart      # regenerates the four ARB files from the string fragments
(cd apps/mobile && dart run build_runner build && flutter gen-l10n)
dart run tools/license_scan/bin/scan.dart     # must pass; fails on disallowed or unknown licenses
dart run tools/license_scan/bin/check_network.dart
dart run tools/license_scan/bin/notice.dart --check
```

Expected: the scan reports every package and content file as registered in
[content/LICENSES.md](../../content/LICENSES.md) and `content/register/*.md`. `cities.db` is not committed
(it is over 5 MB); build it once per checkout.

## 2. Unit tests (fast loop)

```bash
for d in packages/prayer_engine packages/schedule_planner tools/fixtures_gen tools/hijri_table_gen \
         tools/geonames_build tools/sync_content tools/license_scan tools/l10n_merge; do (cd $d && dart test); done
```

Expected: the engine matches the independent oracle within 1 minute for every method (13 of 14; Moonsighting has structural tests only), 20 cities, both Asr schools, 365 days (the oracle runs inside the tests, so there are no stored fixture files); planner
vectors pass for DST, zone jumps, polar cases, clock changes and the iOS 63-request budget; arbiter vectors
pass. `packages/prayer_engine/tool/accuracy_report.dart` prints every disagreement when a method fails.

## 3. App tests

```bash
cd apps/mobile
flutter analyze
flutter test                                # unit and widget tests (four languages, RTL, 2.0x text)
flutter test integration_test -d <device>   # setup flow on a device or emulator (the same scenarios also run on the host inside `flutter test`)
```

Expected: no analyzer errors; no overflow or clipped text in any language at 2.0x text size.

## 4. Platform dependency checks

```bash
cd apps/mobile/android && ./gradlew :app:dependencies | grep -i "com.google.android.gms" || echo "clean"
flutter pub deps --style=compact            # review against the license register
```

Expected: `clean`. Any `gms` line is a failure of spike S4 and constitution principle 4.

## 5. Run on a device

```bash
flutter run -d <device-id> --release
```

Validate the stories in order:

1. **Setup (Story 1)**: airplane mode on, fresh install, finish setup in 90 seconds or less using the offline city
   search; refuse every permission once and confirm no crash and a visible way back.
2. **Times (Story 2)**: change method, Asr method, offsets and Hijri adjustment; every screen updates at once.
3. **Alerts (Story 3)**: open the Reliability check (one tap from home), press "send a test Azaan in 1 minute",
   lock the phone and confirm the alert and a single Azaan.
4. **Qibla, Tasbih, Adhkar, Settings (Stories 4-7)**: follow each story's acceptance scenarios.

## 6. Reliability scenarios (real devices)

Run each on every device in the matrix and record pass or fail with the alert journal.

| Scenario | How |
|----------|-----|
| Reboot | Plan an alert 3 minutes ahead, reboot, do not open the app, confirm it fires |
| Force-quit | Swipe the app away or force stop, confirm behavior and the Reliability check message |
| Time zone change | Change the device zone; confirm absolute alert instants are unchanged and the app suggests a location review |
| Daylight saving | Set the clock across a DST transition for the saved location |
| Manual clock change | Move the clock forward and back; confirm alerts re-register |
| Airplane mode, battery saver | Enable and confirm alerts fire |
| Doze (Android) | `adb shell dumpsys deviceidle force-idle`, then wait for the alert |
| Standby buckets (Android) | `adb shell am set-standby-bucket <package> rare`, then wait |
| Call in progress | Receive a call at alert time; confirm silence plus vibration |
| Headphones and Bluetooth | Connect and confirm routing follows the user's choice |
| iPhone silent switch | Confirm the notification sound is muted and tap-to-play behavior (spike S8) |
| 64-slot budget (iOS) | Enable reminders on all prayers; confirm the 63-request cap and renewal alert |
| Exact alarm refused (Android 14+) | Refuse it in setup; confirm setup finishes, alerts still arrive, and the Reliability check flags reduced precision |
| Exact alarm granted in setup | Accept it; confirm the default short tone fires within 5 seconds (spike S11) |
| Quiet hours | Set quiet hours around an alert; confirm it becomes a silent notification and is listed as silenced, not missed |
| Window top-up (Android) | Leave the app unopened for 7 days; confirm the 14-day window never empties (spike S10) and the "open the app" notice appears about 7 days before the end |
| iPhone tap-to-play with silent switch | Switch on silent, tap the notification; confirm the full Azaan plays (spike S8) |

## 7. Seven-day soak (SC-002)

1. Install the release build on each matrix device and set all five prayers to short tone, some to full Azaan.
2. Include reboots and a time zone change during the week.
3. After day 7, open the Reliability check and export the alert log summary (planned time, fired time, deviation).
4. Pass criteria: 99% of alerts within 5 seconds of the planned time on exact-alarm devices, and no alert ID has
   more than one `played` entry.

## 8. Accessibility and performance

- TalkBack (Android) and VoiceOver (iOS): every screen operable without sight (SC-006).
- Cold start to the next-prayer screen under 2 seconds on a mid-range 2020 phone (SC-004), measured with a
  release build.
- Battery: compare the system's per-app battery use over 24 hours with the app installed and idle (SC-005).

## 9. Release checklist

- Privacy policy URL live; Play Data safety and App Store privacy label state no data collected (SC-007).
- Play foreground-service declaration (`mediaPlayback`) with a user-scheduled-alert description and video.
- Permission justifications and reviewer notes explaining Azaan alerts.
- Device-matrix sign-off recorded; licenses and attributions visible in the About screen.
