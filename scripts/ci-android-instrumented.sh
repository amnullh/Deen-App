#!/usr/bin/env bash
# Builds the app once (so Gradle has local.properties and the Flutter plugin set
# up) and then runs the instrumented tests on the emulator that
# reactivecircus/android-emulator-runner started. CI only.
set -euxo pipefail
cd "$(dirname "$0")/../apps/mobile"
flutter build apk --debug
cd android
./gradlew connectedDebugAndroidTest
