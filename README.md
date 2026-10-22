# Deen App

An offline-first daily worship app for Android and iOS: reliable Azaan alerts, accurate prayer times, Qibla,
Tasbih and Adhkar. Phase 0 has no server, no account and no network dependency; everything works in airplane mode
after install, and the app collects no personal data.

The project is built entirely on open-source software with no licensing cost, so a community can run, audit and
sustain it. Project rules live in the [constitution](.specify/memory/constitution.md).

## Status

Phase 1 (an optional server with a Masjid directory, verification and Masjid schedules) is planned, not started: see [specs/002-masjid-directory-verification/](specs/002-masjid-directory-verification/) ([plan](specs/002-masjid-directory-verification/plan.md)). Building it waits for Phase 0 to meet its exit criteria.

Phase 0 is in implementation. Planning documents are in
[specs/001-offline-worship-app/](specs/001-offline-worship-app/): the
[spec](specs/001-offline-worship-app/spec.md), [plan](specs/001-offline-worship-app/plan.md),
[tasks](specs/001-offline-worship-app/tasks.md) and [quickstart](specs/001-offline-worship-app/quickstart.md).

## Layout

| Path | Purpose |
|------|---------|
| `apps/mobile/` | Flutter app (Android and iOS) |
| `packages/prayer_engine/` | Pure Dart prayer-time engine, Hijri, Qibla, regional defaults |
| `packages/schedule_planner/` | Pure Dart alert planner and arbiter |
| `tools/` | Build-time tools: fixtures oracle, city database, Hijri table, license scan, content sync |
| `content/` | Content sources and the license register ([content/LICENSES.md](content/LICENSES.md)) |
| `specs/` | Spec-driven development documents |

## Build prerequisites

- macOS for iOS builds; Android Studio with an SDK for API 26 and the current target SDK
- Flutter 3.44 or newer (includes Dart); then run `scripts/setup.sh`, which turns off Flutter and Dart tool
  analytics and resolves the workspace
- Own physical devices are needed for the reliability tests; see the quickstart

## License rules

- The project's own code is licensed under Apache-2.0 ([LICENSE](LICENSE)).
- Every dependency and every bundled asset must be open source or freely redistributable and be listed in
  [content/LICENSES.md](content/LICENSES.md) with its source and license (religious content also needs a named
  reviewer). CI fails on a disallowed or unknown license. See [CONTRIBUTING.md](CONTRIBUTING.md).
