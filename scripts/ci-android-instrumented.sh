#!/usr/bin/env bash
# Builds the app once (so Gradle has local.properties and the Flutter plugin set
# up) and then runs the instrumented tests on the emulator that
# reactivecircus/android-emulator-runner started. CI only.
set -uxo pipefail
cd "$(dirname "$0")/../apps/mobile"
flutter build apk --debug || exit $?
cd android
./gradlew :app:connectedDebugAndroidTest
status=$?
# Failed tests become annotations, readable on the run page without a login.
python3 ../../../scripts/ci-junit-summary.py ../build/app/outputs
exit $status
