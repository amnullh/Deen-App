# Implementation guide for parallel workstreams

Read this first. Several agents work in the same repository at the same time; the rules below keep their
changes from colliding. Anything not covered here: follow the constitution
(`.specify/memory/constitution.md`), the spec, the plan and the contracts.

## Read before you start

- `specs/001-offline-worship-app/spec.md` (what and why), `plan.md` (how, decisions D-1 to D-15),
  `tasks.md` (task IDs; yours are listed in your brief), `data-model.md`, `contracts/*.md`,
  `research.md` (platform facts with VERIFIED / UNVERIFIED tags).
- Only the tasks in your brief are yours. Do not start another workstream's tasks.

## Environment

- Always: `export PATH="$HOME/development/flutter/bin:$PATH"` (Flutter 3.47.7, Dart 3.13.5).
- Never run `pkill`, `killall` or kill processes you did not start; other agents are running tests.
- Do not run `dart pub get` / `flutter pub get` unless you changed a pubspec you own. All app dependencies are
  already declared in `apps/mobile/pubspec.yaml` and resolved. If you truly need a new dependency, do not add it:
  report it in your final message (it needs a license check first).
- No Android SDK or Gradle is installed, and Xcode may be incomplete. Kotlin and Swift code you write cannot be
  compiled here: say so plainly in your report and keep that code simple and conventional. Do not install SDKs.
- Test commands: pure-Dart packages `cd packages/<pkg> && dart test`; app `cd apps/mobile && flutter test <file>`.
  Format with `dart format <your files>`, and keep `dart analyze` / `flutter analyze` clean for what you touch.
- Widget tests that use the database: drift streams keep timers alive. Never use `pumpAndSettle`; copy the
  `_settle` and `_unmount` helpers from `apps/mobile/test/ui/app_shell_test.dart`.
- No network access in tests. No personal data in logs. Prayer logic never reads the system clock (inject it).

## Test-first

Constitution principle 8: for prayer-time calculation, scheduling, fallback logic and the arbiter, write the
failing test first, run it to see it fail, then implement. Other code gets tests too (see the tasks).

## File ownership (collisions are the main risk)

Each workstream owns only the paths in its brief. You may READ anything. These shared files are OFF LIMITS unless
your brief says otherwise; ask for a change in your final report instead:

- `apps/mobile/pubspec.yaml`, `pubspec.yaml` (root), any `pubspec.yaml` you do not own
- `apps/mobile/lib/data/db/app_database.dart` and `*.g.dart` (all tables already exist)
- `apps/mobile/lib/app/providers.dart`, `apps/mobile/lib/app/app.dart`, `apps/mobile/lib/ui/app_shell.dart`
  (the lead wires pages into navigation; you expose a page widget and its providers)
- `apps/mobile/lib/domain/entities/enums.dart` and `settings.dart` (add new entity files instead)
- `specs/**/tasks.md`, `plan.md`, `spec.md`, `.specify/**`, `.github/**`, `content/LICENSES.md`
- generated files: `apps/mobile/lib/l10n/app_*.arb`, `apps/mobile/lib/l10n/generated/**`,
  `apps/mobile/lib/platform/generated/**`, Pigeon outputs

Things you add live in new files you own:

- Providers: `apps/mobile/lib/app/providers/<feature>_providers.dart` (Riverpod 3: use `.value`, not `valueOrNull`).
- Strings: a fragment file `apps/mobile/lib/l10n/fragments/<feature>.json` (format in
  `tools/l10n_merge/lib/merge.dart`). Every key needs `en`, `ar`, `ur`, `id` text. Key names are unique across
  the whole app: prefix them with your feature (`setupTitle`, `qiblaAccuracyLow`). Then run
  `dart run tools/l10n_merge/bin/merge.dart` followed by `cd apps/mobile && flutter gen-l10n`. Never edit the ARB
  files. Write careful Arabic, Urdu and Indonesian; they are reviewed by native speakers later (those review
  tasks stay open).
- License register rows for new dependencies or content: a Markdown file `content/register/<feature>.md` using the
  same table format as `content/LICENSES.md`. `dart run tools/license_scan/bin/scan.dart` must stay green.
- New pages: build the widget; do not edit navigation. Document the entry point (class name, constructor) in your
  report so the lead can wire it.

## Quality bar

- Clear small functions, doc comments that explain why, no dead code, no placeholder TODOs presented as done.
- Accessibility: every control has a semantic label; no meaning by color alone; RTL-safe layout (use
  `EdgeInsetsDirectional`, `AlignmentDirectional`); text must survive 2.0x text scale.
- Errors are shown as plain messages and never crash; refusing a permission never crashes.
- Honesty: a task is done only when its code exists, analyzes clean and its tests pass. Device, content and gate
  tasks (`[DEVICE]`, `[CONTENT]`, `[GATE]`) are not done by writing code: leave them open and say what is needed.
  Code that could not be compiled or run here (Kotlin, Swift) must be reported as "written, not compiled".

## Final report (your last message)

1. Task IDs you completed (with the proof: tests passing, counts).
2. Task IDs partly done or blocked, and why.
3. Files you created, grouped by directory.
4. Anything the lead must do: navigation wiring, shared-file changes, new dependency requests, register rows.
5. Any bug or inconsistency you found in the spec, plan, contracts or other workstreams' code.
Keep it under 500 words.
