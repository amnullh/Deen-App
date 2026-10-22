# Android native dependencies (workstream W5)

Gradle dependencies of `apps/mobile/android/app/build.gradle.kts`. Versions are the ones written in the build
file; they were not resolved here (no Gradle in this environment), so the verification column is U until
`./gradlew :app:dependencies` and the POM licenses are read.

| Name | Version | SPDX license | Verified | Status | Notes |
|------|---------|--------------|----------|--------|-------|
| androidx.core:core | 1.13.1 | Apache-2.0 | U | pending | NotificationCompat, ServiceCompat, ContextCompat |
| org.jetbrains.kotlinx:kotlinx-coroutines-android | 1.8.1 | Apache-2.0 | U | pending | imported by the Pigeon-generated Kotlin code, so it is required |
| androidx.test:runner | 1.6.2 | Apache-2.0 | U | pending (test) | instrumented tests only, not shipped |
| androidx.test:rules | 1.6.1 | Apache-2.0 | U | pending (test) | instrumented tests only, not shipped |
| androidx.test.ext:junit | 1.2.1 | Apache-2.0 | U | pending (test) | instrumented tests only, not shipped |

## Project-authored files under `res/raw`

| Path | Description | License | Status |
|------|-------------|---------|--------|
| apps/mobile/android/app/src/main/res/raw/keep.xml | resource-shrinker keep rule so run-time-looked-up Azaan recordings are not removed; contains no content | project-authored, same license as the app | approved |

## CI tooling (not shipped in the app)

| Name | Version | License | Verified | Use |
|------|---------|---------|----------|-----|
| reactivecircus/android-emulator-runner | v2.33.0 | MIT | U (check the repository LICENSE file before relying on it) | GitHub Action that starts an Android emulator for the instrumented tests; runs only in CI |
| actions/checkout | v4 | MIT | U | GitHub-owned action that fetches the repository in CI |
