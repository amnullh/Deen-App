---

description: "Task list for Masjid Directory, Verification and Masjid Schedules (Phase 1)"
---

# Tasks: Masjid Directory, Verification and Masjid Schedules (Phase 1)

**Input**: Design documents from `specs/002-masjid-directory-verification/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/](contracts/), [quickstart.md](quickstart.md)

**Build gate (constitution principle 9)**: no task outside Phase 1 (Pre-build gates) may start until Phase 0 meets its exit criteria. The gate tasks that are paperwork or decisions may start now.

**Tests**: Included. Principle 8 requires test-first work for scheduling, fallback logic and token authorization, and requires contract tests for backend APIs. Write each test first and confirm it fails before the implementation task that follows it.

**Organization**: grouped by user story (US1 to US7). The three P1 stories (US1, US2, US3) together are the MVP: a listener can only trust a Masjid schedule once the Masjid has been verified by a person.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: can run in parallel (different files, no dependency on an unfinished task)
- **[Story]**: US1 to US7 map to the spec's user stories; gate, setup, foundational and polish tasks carry no label
- **[GATE]**: a decision or approval task; tasks that depend on it must not start until it is done
- **[OWNER]**: needs the product owner or the founding team (a purchase, a person, a decision)
- **[LEGAL]**: needs a lawyer or data-protection adviser; an agent can only prepare the questions
- **[DEVICE]**: needs a physical phone from the Phase 0 device matrix
- **[DRILL]**: a timed or people-based exercise (restore drill, Operator dry run, mail test); not automatable
- Contract references name files under `specs/002-masjid-directory-verification/contracts/`. Route groups follow the tags in `openapi.yaml` (auth, account, masjids, schedules, claims, operator-review, operator-moderation, operator-directory, operator-admin, recovery, public, ops); policy rows follow `authz-matrix.md`; states and audit action names follow `state-machines.md`.

## Path Conventions

- Server: `services/api/` (`src/`, `migrations/`, `test/`), shared TypeScript `services/domain/`
- Console: `apps/operator-console/`
- App: `apps/mobile/` (existing); new Dart packages `packages/masjid_schedule/`, `packages/directory_client/`
- Directory data tooling: `tools/directory-pack/`; license tooling: `tools/license_scan/`
- Infrastructure: `infra/`; scripts: `scripts/`; registers: `content/register/`
- Evidence of runs: `specs/002-masjid-directory-verification/evidence/`

---

## Phase 1: Pre-build gates (decisions, paperwork, purchases)

**Purpose**: Everything that can and must be decided before code. Paperwork is allowed now; implementation is not.

- [ ] T001 [GATE] Confirm that Phase 0 meets its exit criteria (the 31 open tasks in `specs/001-offline-worship-app/tasks.md`: device matrix, soak, content review, store submission) and record the date and sign-off in `specs/002-masjid-directory-verification/plan.md` under a new "Build gate" heading
- [ ] T002 [GATE] [OWNER] Record answers to owner decisions O1 to O16 in a "Decision log" table in `specs/002-masjid-directory-verification/plan.md` (each default stands unless changed); O1 (provider), O2 (backup custodian), O3 (domain), O4 (suggestions), O7 (break-glass contacts) and O14 (spec wording) block later tasks
- [ ] T003 [GATE] Apply the confirmed spec wording changes (O14) in `specs/002-masjid-directory-verification/spec.md`: FR-004 add Muazzin, FR-016 split into claim status and listing status, FR-026 recovery code or break-glass (a call alone never skips the 48-hour delay), FR-027 no address in any listener-facing log; re-run the requirements checklist in `specs/002-masjid-directory-verification/checklists/requirements.md`
- [ ] T004 [GATE] Amend constitution action A1 (phase labels in principle 9) through `/speckit-constitution`, edit `.specify/memory/constitution.md`
- [ ] T005 [GATE] Amend constitution action A2 (Exceptions Register rows: domain registrar and DNS, Let's Encrypt with Caddy pinned to it, Docker Hub and GHCR, and the contingent mail relay row from `research.md` R-10) through `/speckit-constitution`, edit `.specify/memory/constitution.md`
- [ ] T006 [GATE] Amend constitution action A3 (PostGIS wording in Technology Constraints) through `/speckit-constitution`, edit `.specify/memory/constitution.md`
- [ ] T007 [GATE] [OWNER] Run the day-0 provider test on the candidate VPS (outbound `telnet gmail-smtp-in.l.google.com 25`, reverse-DNS control, price and plan availability at order time, fair-use text for traffic) and record the result in `infra/README.md` before buying; if port 25 is closed, pick the fallback provider or adopt the contingent relay row
- [ ] T008 [OWNER] Buy the VPS and the domain, create `data.`, `api.` and `console.` DNS records with a 300-second TTL, and record provider, region, plan, monthly price, VAT status and renewal date in `infra/README.md`
- [ ] T009 [GATE] [OWNER] Name the custodian of the always-on team machine (backup repository, Uptime Kuma, optional Prometheus) and two holders of the age key and restic password; record roles, not secrets, in `infra/README.md`
- [ ] T010 [GATE] [OWNER] Appoint the founding Operators (at least two, both super-admin) and record names and start dates in `specs/002-masjid-directory-verification/ops/operator-runbook.md` ("Fill in before use" table)
- [ ] T011 [LEGAL] Obtain a licensing review of the ten ODbL questions in `research.md` R-27 (base and overlay by id, merged on-phone cache, attribution footer, contributor terms, overlay terms against principle 10) and record answers in `research.md`
- [ ] T012 [LEGAL] Obtain a review of `specs/002-masjid-directory-verification/ops/dpia.md` (19 open legal questions, lawful bases, third-party committee contacts, retention values, 12-month evidence fingerprint) and record the outcome and any changed retention values in `data-model.md` section 12
- [ ] T013 [GATE] Draft the admin and Muazzin terms of use (acceptance of ODbL-compatible terms for edits to the base layer, overlay terms, acceptable use) in `specs/002-masjid-directory-verification/ops/admin-terms.md` and mark it for legal review
- [ ] T014 [GATE] Re-read the live Google Play Data safety and Apple privacy label wording and decide the honest answers for "region request sends IP address and a 5 km cell"; record the decision in `specs/001-offline-worship-app/release/store-notes.md` and `specs/001-offline-worship-app/research.md` (R-A7, R-I7)
- [ ] T015 [GATE] Verify every item marked UNVERIFIED in `research.md` that gates a build decision (OVH monthly price, Contabo port 25, OpenDKIM license, ASVS 5.0 numbering, Altcha version and license, `pg_trgm` behaviour on Arabic, Android and iOS FTS5) and replace each mark with the checked fact and source
- [ ] T016 [GATE] Run the OSM planet filter once on a build machine (`tools/directory-pack/README.md` procedure) to count real non-empty 5 km cells and objects, and update the pack size and storage estimates in `research.md` R-28 and R-29
- [ ] T017 [GATE] Decide the Phase 0 `LocalClock.toUtc` east-of-Greenwich defect (documented behaviour differs from the code in London and Sydney): fix with additions-only vectors in `packages/schedule_planner/test_vectors/`, or correct the comment; record the decision in `specs/001-offline-worship-app/tasks.md`

**Checkpoint**: gates answered; nothing below starts before the first task of this phase is done.

---

## Phase 2: Setup (Shared Infrastructure)

**Purpose**: Repository skeleton for the server, console, Dart packages, infrastructure and registers.

- [ ] T018 Create `pnpm-workspace.yaml` (members `services/*` and `apps/operator-console` only), `.node-version` (26), root `package.json` with `engines`, `.npmrc` (release-age gate, strict build scripts, no exotic subdependencies) and extend `.gitignore` for `node_modules/`, `dist/`, `build/`, `.env*`, `infra/secrets/*.dec.*`
- [ ] T019 [P] Scaffold `services/api` (`package.json`, `tsconfig.json` with `erasableSyntaxOnly`, `verbatimModuleSyntax`, `noEmit`; `src/main-api.ts` and `src/main-worker.ts` placeholders; `Dockerfile` pinned by digest, non-root, read-only filesystem) running TypeScript through Node's native type stripping
- [ ] T020 [P] Scaffold `services/domain` (`package.json`, `tsconfig.json`, `src/index.ts`) for the shared claim-transition table, authorization policy and generated API types
- [ ] T021 [P] Scaffold `apps/operator-console` with Vite 8, React 19, React Aria Components, React Router, TanStack Query, `openapi-fetch`, React Hook Form, Zod 4 (`z.config({ jitless: true })`), `react-intl`, `maplibre-gl`, `pmtiles`; plain CSS with logical properties; `index.html` without inline script or style
- [ ] T022 [P] Create the pure-Dart package `packages/masjid_schedule/pubspec.yaml` (depends on `prayer_engine` only; no `dart:io`, no Flutter) with `lib/masjid_schedule.dart` and a `test_vectors/` folder
- [ ] T023 [P] Create the Dart package `packages/directory_client/pubspec.yaml` (no new pub dependency; uses `dart:io`) with `lib/directory_client.dart`, `test/` and `test/egress_vectors.json` placeholder
- [ ] T024 Add the new Dart packages to the root `pubspec.yaml` workspace list and run `flutter pub get`
- [ ] T025 [P] Create `tools/directory-pack/` skeleton (`README.md` with the open-method statement, `import/`, `sql/`, `LICENSE-NOTICE.md`) for the importer and the ODbL dump method
- [ ] T026 [P] Create the dependency registers `content/register/server-deps.md`, `content/register/server-tools.md`, `content/register/server-images.md` with the columns from `research.md` R-25 and one row per dependency chosen in `research.md` sections 1 to 8 (name, version, license, production or dev, maintainer health, alternatives)
- [ ] T027 [P] Create the infrastructure skeleton `infra/bootstrap.sh`, `infra/compose/docker-compose.yml` (profiles `core`, `observe`, `full`), `infra/caddy/Caddyfile`, `infra/secrets/README.md`, `infra/runbooks/`, `infra/Makefile`
- [ ] T028 [P] Add `specs/002-masjid-directory-verification/evidence/README.md` describing the evidence files each scenario in `quickstart.md` produces and who signs
- [ ] T029 [P] Add the pull-request template items for server dependencies (license, health, alternatives, register row) to `.github/pull_request_template.md` and update `CONTRIBUTING.md` for the Node tree and pinned GitHub Actions

---

## Phase 3: Foundational (Blocking Prerequisites)

**Purpose**: Server core, database foundation, CI and license gates, the app's network choke point, and the directory data pipeline that every story needs. No user story can start before this phase is done.

### 3a. CI and license gates (first, so every later task is checked)

- [ ] T030 Write tests first in `tools/license_scan/test/scanner_test.dart` for the new `check_network` rules (INTERNET allowed in the main manifest only with `usesCleartextTraffic=false` and a network security config, `ACCESS_NETWORK_STATE` still forbidden, import-boundary scan, URL-literal scan, allowlist file) and flip the existing "INTERNET is forbidden" test
- [ ] T031 Rewrite `tools/license_scan/bin/check_network.dart` and `tools/license_scan/lib/` to implement rules (a) to (g) from `contracts/directory-client.md` section 12 and add `tools/license_scan/network_allowlist.yaml`
- [ ] T032 [P] Write tests first in `tools/license_scan/test/pnpm_lock_test.dart` (parser, SPDX `OR` and `AND`, a fixture lock with GPL, UNLICENSED, `OR` and `AND` cases) then implement `tools/license_scan/lib/pnpm_lock.dart` and `tools/license_scan/bin/scan_server.dart`; copyleft inside the Node runtime closure fails, every direct dependency needs a row in `content/register/server-deps.md`
- [ ] T033 [P] Implement `tools/license_scan/bin/check_ci_tools.dart` (every `uses:` is a 40-character commit SHA; every tool and image has a row in `content/register/server-tools.md` or `server-images.md`) with tests in `tools/license_scan/test/check_ci_tools_test.dart`; extend `tools/license_scan/denylist.txt` with the npm patterns from `research.md` R-25
- [ ] T034 Create `.github/workflows/ci-server.yml` (path-filtered jobs: lint-type, unit, integration with Testcontainers, contract with Schemathesis, supply-chain with OSV-Scanner and Trivy binary and gitleaks binary, zap, console-e2e) and an always-running `gate` job; add `paths-ignore` for server paths to `.github/workflows/ci.yml` and a matching `gate` job; pin every action by commit SHA; fix the emulator-runner license comment (Apache-2.0)
- [ ] T035 [P] Create `.github/workflows/nightly.yml` (fast-check 20,000 runs, ZAP active scan against staging only, Schemathesis 500 examples, OSV and Trivy rescan, emulator mitmproxy capture) with `workflow_dispatch`
- [ ] T036 [P] Extend `scripts/ci-test-summary.py` and add a committed baseline file `scripts/ci-test-baseline.json` so CI fails if the executed Phase 0 test count drops

### 3b. Server core

- [ ] T037 Write migration tests first in `services/api/test/integration/migrations.test.ts` (apply 0001 to 0005 on a PostGIS container, check roles, extensions, generated `geohash5` column, `new_masjid_id()`, grants) then add `services/api/migrations/0001_foundation.sql` (extensions `postgis`, `pg_trgm`, `pgcrypto`; roles `migrator`, `app`, `evidence_svc`; `new_masjid_id()`; `app.normalize_name()`; `app.tags_allowed()`; `state_transition`) per `data-model.md` section 14
- [ ] T038 Add `services/api/migrations/0002_accounts.sql` (account, credential, mfa_factor, recovery_code, actor_map, operator, operator_role, terms_acceptance) per `data-model.md`
- [ ] T039 Write tests first in `services/api/test/integration/audit.test.ts` (app role gets permission denied on UPDATE, DELETE, TRUNCATE; hash chain verifies; actor from `set_config`; default action name when none set; a forgotten action is still audited) then add `services/api/migrations/0003_audit.sql` (audit_log, audit_anchor, `audit_append()`, `audit_event()`, hash chain with advisory lock, REVOKEs, generic row-audit trigger function) per `data-model.md` section 15
- [ ] T040 Add `services/api/migrations/0004_base.sql` (osm_import_batch, masjid, masjid_osm_ref, masjid_translation with the one-primary constraint trigger, curated_entry, osm_staging) and `services/api/migrations/0005_overlay.sql` (masjid_profile with `calc_settings`, public_contact, photo, masjid_version, schedule, schedule_version) per `data-model.md`
- [ ] T041 Add `services/api/migrations/0011_seeds.sql` (reason-code tables, vocabulary lists for facilities and languages, the `state_transition` seed hook) and `services/api/scripts/bootstrap-operator.ts` (creates the first super-admin from the founders' secret file, audited as `operator.bootstrapped`) with a test in `services/api/test/integration/bootstrap.test.ts`
- [ ] T042 Add `services/api/migrations/0009_packs.sql` (pack_build, pack_file, pack_dirty_cell and the publish views `v_publish_base`, `v_publish_overlay`, `v_publish_sched`) per `data-model.md`
- [ ] T043 Implement the Kysely migrator wrapper and `kysely-codegen` step in `services/api/src/db/migrate.ts` and `services/api/src/db/types.generated.ts`; CI applies migrations to a PostGIS container, regenerates types and fails on a diff
- [ ] T044 [P] Implement configuration loading and secret handling in `services/api/src/config/index.ts` (SOPS-decrypted environment, KEK ids, pepper, SMTP URL, no defaults for secrets, fail fast)
- [ ] T045 [P] Implement logging in `services/api/src/config/logger.ts` with pino redaction (authorization, cookie, set-cookie, password, totp, token, code, email, phone, filename), request path without query string, and a snapshot test `services/api/test/unit/log-redaction.test.ts` that fails on any forbidden key
- [ ] T046 Write tests first in `services/api/test/contract/problem-errors.test.ts` then implement the OpenAPI-driven server in `services/api/src/server.ts` and `services/api/src/openapi/glue.ts` (routes created from `operationId` in `specs/002-masjid-directory-verification/contracts/openapi.yaml`, Ajv with `removeAdditional: false`, RFC 9457 problem+json handler with stable codes, request id, 404 body identical for another Masjid's resource and a missing one)
- [ ] T047 [P] Implement security headers and cookie plumbing in `services/api/src/http/security.ts` (helmet, `__Host-sid` and `__Host-pa` cookie options, Origin and `Sec-Fetch-Site` check on unsafe methods, JSON-only bodies, CSRF header check) with tests in `services/api/test/unit/security-headers.test.ts`
- [ ] T048 [P] Implement the Valkey client and rate-limit plumbing in `services/api/src/ratelimit/index.ts` (tiers from `research.md` R-09 and `r5` 2.9, daily-rotating salted address hash with a time to live of at most 1 hour for public routes, nothing persisted) with tests in `services/api/test/unit/ratelimit.test.ts`
- [ ] T049 Implement the authorization policy loader in `services/api/src/authz/policy.ts` reading `x-roles`, `x-scope`, `x-mfa`, `x-step-up` from the OpenAPI file with default deny; add `services/domain/src/authz-policy.ts` and a completeness test `services/api/test/authz/policy-completeness.test.ts` (every route has a policy row; no route outside the contract)
- [ ] T050 [P] Implement `ops` routes `getHealth` and `getReady` (checks PostgreSQL and Valkey) in `services/api/src/routes/ops.ts`, excluded from request logs
- [ ] T051 Generate API types from the contract into `services/domain/src/api-types.generated.ts` with `openapi-typescript` and add the `redocly lint` step to `ci-server.yml`; add `scripts/check-contract-examples.sh` that validates every file in `specs/002-masjid-directory-verification/contracts/examples/` with Ajv
- [ ] T052 Implement the worker entrypoint in `services/api/src/main-worker.ts` and the pg-boss setup in `services/api/src/jobs/boss.ts` (own `pgboss` schema, owner-level role at start-up only, queues, cron with timezone, idempotent handlers) with a test `services/api/test/integration/jobs-boot.test.ts`
- [ ] T053 [P] Implement the mail outbox and sender in `services/api/src/mail/outbox.ts` and `services/api/src/mail/send.ts` (nodemailer over `SMTP_URL`, templates for the admin and Operator emails listed in `ops/operator-runbook.md`, retry with back-off, bounce handling flag) with tests in `services/api/test/unit/mail.test.ts`
- [ ] T054 [P] Add the development stack `infra/compose/docker-compose.dev.yml` (PostGIS 18, Valkey, Caddy with local TLS, a local SMTP sink) and `infra/Makefile` targets `dev-up`, `dev-down`, `dev-seed`; add `scripts/dev-seed.ts` fixture generator for 300,000 synthetic Masjids with realistic density

### 3c. The app's network choke point and local storage (client foundation)

- [ ] T055 Write tests first in `apps/mobile/test/flutter_test_config.dart` adding the global `HttpOverrides` guard driven by `--dart-define=DEEN_TEST_NET=off|fail|hang|garbage` (default `off`: any request from a test that did not opt in fails the suite), and run the existing Phase 0 suite under it
- [ ] T056 Move `LocalClock`, `addDays` and the search-text normalizer (`apps/mobile/lib/data/cities/name_normalizer.dart`) into `packages/prayer_engine/lib/src/` (re-exported from `packages/schedule_planner`), keeping every Phase 0 test and vector unchanged (additions only)
- [ ] T057 Add the Android and iOS network configuration: `INTERNET` permission, `android:usesCleartextTraffic="false"`, `apps/mobile/android/app/src/main/res/xml/network_security_config.xml` (cleartext off, debug-only user-CA trust in `src/debug`), iOS ATS left at default; update the manifest comment and verify with the rewritten `check_network`
- [ ] T058 Write migration tests first in `apps/mobile/test/data/db/schema_v2_test.dart` (drift `SchemaVerifier` v1 to v2, data preserved, `drift_schemas/` snapshots committed) then bump `AppDatabase.schemaVersion` to 2 in `apps/mobile/lib/data/db/` adding `masjid_follow`, `masjid_schedule_cache`, `directory_state`, `masjid_notice` and the settings columns `scheduleSource` and `activeMasjidId`
- [ ] T059 Add the delete-all step for the new files (`directory.db`, temporary pack files) in `apps/mobile/lib/domain/settings/delete_all_data.dart` with a test in `apps/mobile/test/domain/settings/delete_all_test.dart`
- [ ] T060 [P] Create the l10n fragment `apps/mobile/lib/l10n/fragments/masjid.json` (keys for consent, badges, confirm, follow, status notices, time-zone banner, attribution, errors; `description` for every key) with English text, then run `tools/l10n_merge` so CI `merge.dart --check` passes; Arabic, Urdu and Bahasa Indonesia strings are added in the story phases

### 3d. Directory data pipeline (base layer and static publishing), used by US1, US2 and US6

- [ ] T061 Write tests first in `tools/directory-pack/test/` for the tag allow-list, the refine rules (keep `amenity=place_of_worship` with `religion=muslim`, or `building=mosque` flagged `needs_review`; drop disused, abandoned, ruins, schools, cemeteries; `kind` mosque or musalla), Latin search-key generation and the shared Arabic and Latin normalizer vectors in `packages/prayer_engine/test_vectors/name_normalizer.json`
- [ ] T062 Implement the importer in `tools/directory-pack/import/` (Geofabrik download with conditional GET, `osmium tags-filter`, `osm2pgsql` flex style into the staging schema, refine SQL in `tools/directory-pack/sql/refine.sql`) and `services/api/src/jobs/osm-import.ts` that loads a batch into `osm_staging` and creates an `osm_import_batch`
- [ ] T063 Implement stable ids and re-import matching in `services/api/src/directory/osm-match.ts` (exact reference update unless an Operator override exists; 50 m and similarity 0.6 attach; node inside an existing building outline; tombstone after two consecutive missed imports; claimed or verified Masjids flagged, never hidden) with tests in `services/api/test/integration/osm-match.test.ts`
- [ ] T064 Write tests first in `services/api/test/unit/packs.test.ts` (cell assignment by `ST_GeoHash(location, 5)`, parts by `FNV-1a-32(id) mod N` with `N = ceil(bytes / 400 KB)`, `N <= 16`, 500,000-byte limit on unpadded canonical bytes, padding classes 4, 16, 64, 256, 512 KB of gzip size, byte-identical output for unchanged cells) then implement `services/api/src/packs/build.ts`, `services/api/src/packs/format.ts` and `services/api/src/packs/pad.ts` per `contracts/static-files.md` sections 3 to 5
- [ ] T065 Implement the publish procedure in `services/api/src/packs/publish.ts` (generation directories, hard links for unchanged files with mtime untouched, parts 2 to N before part 1, `.gz` and `.br` sidecars, `scripts/pack-check` before the atomic symlink flip, manifest written last, 30-day retention sweep) and the pg-boss queue `packs` with singleton key per cell in `services/api/src/jobs/packs.ts`
- [ ] T066 Implement `scripts/pack-check` (sizes, parts, `cv`, JSON schemas, field allow-list that fails on phone, email, website, photo or contact fields, licence header, padding class) with a poisoned fixture test in `scripts/test/pack-check.test.ts`
- [ ] T067 [P] Implement the open ODbL dump generator in `services/api/src/packs/dump.ts` (`directory-base-{gen}.ndjson.gz`, `LICENSE-ODbL-1.0.txt`, `NOTICE.md`, `SHA256SUMS`, last 12 kept, `origin` filter per FR-031) with a test that the dump equals the base files byte for byte
- [ ] T068 [P] Implement the manifest and `redirects.json` writers in `services/api/src/packs/manifest.ts` (fields from `contracts/static-files.md`: `gen`, `overlay.gen`, `min_app`, licence block, stale rules, `classes_kb`)
- [ ] T069 Configure Caddy for the three hosts in `infra/caddy/Caddyfile` (`data.` with precompressed sidecars, no `log` directive, cache classes from `research.md` R-29, security headers; `api.` serving only `/v1/public/*` with no cookies; `console.` serving the SPA, `/v1/*` to the API and `/tiles/` with range requests; Let's Encrypt as the only issuer; admin endpoint on loopback; metrics per host only) and add `infra/caddy/test/caddy-static.test.sh` that asserts ETag, 304, 206, sidecar encoding and an empty access log for a known test address

**Checkpoint**: migrations, audit, OpenAPI server, CI and license gates, the app's single network entry point and a publishable base layer exist. User stories can start; US1 and US2 can run in parallel with US3.

---


## Phase 4: User Story 1 - Find and confirm my Masjid (Priority: P1) MVP

**Goal**: A listener downloads a region, searches nearby or by name, confirms a Masjid and follows several, with no account and no coordinate finer than a 5 km cell leaving the phone.

**Independent Test**: Download one region, turn the network off, search nearby, confirm a Masjid, and inspect a recording of the traffic taken while using the feature (`quickstart.md` Scenario A). Covers FR-009 to FR-012, SC-001, SC-004.

### Tests for User Story 1 (write first, confirm they fail)

- [ ] T070 [P] [US1] Create `packages/directory_client/test/egress_vectors.json` (about 150 allow and deny cases: coordinates in path, query, header and body; six-character cell; `%` escapes; userinfo; fragment; wrong host; POST to the data host; redirect to another host) and `packages/directory_client/test/egress_policy_test.dart` against the grammar in `contracts/directory-client.md` section 3
- [ ] T071 [P] [US1] Write `packages/directory_client/test/fake_server_test.dart` using a loopback `HttpServer` and `HttpOverrides` that records every request: exact header set, `User-Agent: DeenDirectory/1`, no `Cookie`, empty query, only grammar paths; include the metamorphic property (two coordinates in one cell give a byte-identical request set), the differential property (two simulated device states give byte-identical logs), a canary request with a fine coordinate that the checker must fail, and a 20,000-input seeded fuzz of coordinates and query text
- [ ] T072 [P] [US1] Write `packages/directory_client/test/atomic_commit_test.dart` (process killed between parts, mixed `cv` set, a 404 part, `cv` mismatch retried up to three times; stored data never changes on failure) and `packages/directory_client/test/cadence_test.dart` (fake clock: manifest at most every 12 hours, 0 to 120 s jitter, at most three parallel downloads, exponential back-off with `Retry-After`, randomised order with 100 to 800 ms jitter)
- [ ] T073 [P] [US1] Write `packages/directory_client/test/kill_switch_test.dart` (empty `DEEN_DIRECTORY_BASE_URL` constructs no `HttpClient`; consent object required for every call) and `packages/directory_client/test/staleness_test.dart` (base older than 90 days banner; `min_app` above the app version; unsupported `rf`)
- [ ] T074 [P] [US1] Write `apps/mobile/test/data/directory/search_test.dart` (normalised Arabic with and without tashkeel, alef and ya variants, Urdu forms, Latin transliteration keys, leading `al-`, mosque-word synonyms, prefix type-ahead, distance sort with the bounding box then haversine) and `apps/mobile/integration_test/fts5_test.dart` that creates an FTS5 table with the trigram tokenizer and asserts `compile_options` on Android and iOS
- [ ] T075 [P] [US1] Write `apps/mobile/test/domain/directory/follow_test.dart` (several follows, exactly one "my Masjid", remove any, nothing sent to the server, a follow survives deletion of its pack) and `apps/mobile/test/domain/directory/confirm_test.dart` (never selected without confirmation; pending and unclaimed Masjids show name and location only)
- [ ] T076 [US1] Write `apps/mobile/integration_test/find_confirm_test.dart` that runs the whole flow against the fake server with a stopwatch (SC-001: under 60 seconds) and with the network switched off after one download

### Implementation for User Story 1

- [ ] T077 [US1] Implement `EgressPolicy` and the typed `DirectoryClient` in `packages/directory_client/lib/src/egress_policy.dart` and `packages/directory_client/lib/src/directory_client.dart` (manifest, country summary, g4 index, base and overlay cell parts, schedule bundle, redirects, and the two POSTs; no generic `get(url)`; HTTPS only; no redirects except one same-host hop; connect 10 s and total 30 s; body caps 600 KB and 256 KB; gzip only)
- [ ] T078 [US1] Implement the consent object, the null-object kill switch and the build-time `DEEN_DIRECTORY_BASE_URL` and `DEEN_DIRECTORY_API_URL` defines in `packages/directory_client/lib/src/consent.dart` and `apps/mobile/lib/app/directory_config.dart`; wire both defines in the CI build commands and `apps/mobile/README.md`
- [ ] T079 [US1] Implement conditional requests and per-cell cache state, the 12-hour manifest cadence, jitter, back-off, parallelism limit and the multi-part atomic commit in `packages/directory_client/lib/src/sync.dart`
- [ ] T080 [US1] Implement the rebuildable `directory.db` in `apps/mobile/lib/data/directory/directory_database.dart` (tables `masjid`, `cell_state`, `masjid_fts` with `unicode61 remove_diacritics 2` and `prefix='2 3'`, optional trigram table) provisioned like `CityDatabaseProvisioner`, with ingest of a whole cell set in one transaction
- [ ] T081 [US1] Implement search and near-me queries in `apps/mobile/lib/data/directory/directory_repository.dart` (normalised query, bounding box and squared-distance ordering, haversine label, the stated radius per latitude, curated Masjids first) using the shared normalizer from `packages/prayer_engine`
- [ ] T082 [US1] Implement the follow and confirm repositories in `apps/mobile/lib/data/directory/follow_repository.dart` (drift tables from schema v2, denormalised fields, one `isMine`, redirect remapping from `redirects.json`)
- [ ] T083 [US1] Implement the use cases and providers in `apps/mobile/lib/domain/directory/` (consent, download plans for near me (3 by 3 cells), area (g4 index), whole country (summary only) and manual (country and city from the bundled `cities.db`), search, confirm, follow) and register them in `apps/mobile/lib/app/app_overrides.dart`
- [ ] T084 [US1] Add the "Masjids" destination and routes in `apps/mobile/lib/ui/app_shell.dart` and `apps/mobile/lib/ui/directory/` : consent screen (what is sent, what is stored, four equal choices), search page with badges, madhhab, method, Azaan variant, distance, "unnamed mosque, 300 m" label, the real radius, and the persistent `© OpenStreetMap contributors` footer linking to the OSM copyright page
- [ ] T085 [US1] Add the Masjid detail and confirm screen in `apps/mobile/lib/ui/directory/masjid_detail_page.dart` (madhhab, method and Azaan variant shown; says what will change; explicit Confirm; follow, "my Masjid", remove) and the follow list in `apps/mobile/lib/ui/directory/follow_list_page.dart`
- [ ] T086 [US1] Implement background refresh of followed cells only in `apps/mobile/lib/platform/` for iOS `BGAppRefreshTask` (`refreshFollowed()` inside its time limit, never a new cell) and a foreground refresh on launch and resume for both platforms
- [ ] T087 [P] [US1] Add Arabic, Urdu and Bahasa Indonesia strings for the directory UI in `apps/mobile/lib/l10n/fragments/masjid.json` (reviewed by a native speaker) and right-to-left golden tests in `apps/mobile/test/ui/goldens/directory/` (tagged `golden`)
- [ ] T088 [P] [US1] Add accessibility tests in `apps/mobile/test/ui/directory/a11y_test.dart` (semantics labels, large text, touch targets, screen-reader order) for consent, search, detail and follow list
- [ ] T089 [US1] Build the country summary and g4 index writers in `services/api/src/packs/country.ts` (only major Masjids; country file under 500,000 bytes keeping the lowest `rk` entries) and seed the curated Two Holy Mosques entries with sources in `tools/directory-pack/seed/curated-haramain.json` (full curated list is US6)
- [ ] T090 [P] [US1] Add the emulator capture step to the `android-emulator` job in `.github/workflows/ci.yml` (mitmproxy `mitmdump` with `-http-proxy`, DNS log through `-dns-server`, debug build trusts the user CA only through `src/debug`, nightly and release only, HAR archived) and `scripts/ci-android-capture.sh`
- [ ] T091 [US1] Run `quickstart.md` Scenario A on the debug build and store the HAR, the stopwatch log and the verdict in `specs/002-masjid-directory-verification/evidence/scenario-a-YYYYMMDD/`

**Checkpoint**: a listener can find and confirm a Masjid offline; traffic is proven cell-level only.

---

## Phase 5: User Story 2 - Use my Masjid's schedule (Priority: P1) MVP

**Goal**: A confirmed Verified Masjid's Azaan, Iqamah and Jumu'ah times replace calculated times for alerts, with fixed, calculated-plus-offset and Iqamah-after-Azaan forms, date ranges, several Jumu'ah shifts, the Masjid's own time zone and a way back to calculated times.

**Independent Test**: Confirm a Verified Masjid whose schedule differs from the calculated times and check that the next alerts change within 5 seconds with no duplicates (`quickstart.md` Scenarios B and C). Covers FR-005, FR-013 to FR-015, SC-003, SC-007.

### Tests for User Story 2 (write first, confirm they fail)

- [ ] T092 [P] [US2] Create the golden vectors `packages/masjid_schedule/test_vectors/expansion.json` (the eight worked cases in `contracts/schedule-rules.md` section 7: fixed time, spring-forward gap, autumn overlap, calculated plus offset, Iqamah across midnight rejected, southern hemisphere, 30-minute offset zone, two Jumu'ah shifts; expected instants generated by the Dart expander and reviewed) and `packages/masjid_schedule/test/vectors_test.dart`
- [ ] T093 [P] [US2] Write `packages/masjid_schedule/test/wall_to_utc_test.dart` for rule E4 (sign-independent: London 2026-03-29 and 2026-10-25, New York 2026-03-08 and 2026-11-01, Sydney 2026-10-04, Lord Howe, Chatham, Kathmandu) and `packages/masjid_schedule/test/validate_test.dart` (one table test per issue code, severity and path: `iqamah_before_azaan`, `range_overlap`, `range_gap`, `jumuah_not_friday`, `unknown_zone`, `offset_out_of_range`, `too_many_shifts`, `range_ends_soon`, others)
- [ ] T094 [P] [US2] Write property tests in `packages/masjid_schedule/test/properties_test.dart` (one Azaan per prayer per local date, increasing order, exactly 30 consecutive local dates across 23 and 25 hour days, gap flagged `gapShifted`, overlap first occurrence, determinism, results independent of the host time zone under `TZ=UTC`, `Pacific/Kiritimati`, `America/St_Johns`, curated zones around every transition including Cairo, Casablanca, Amman, Istanbul, Apia)
- [ ] T095 [P] [US2] Write `packages/masjid_schedule/test/js_parity_test.dart` and `packages/masjid_schedule/tool/parity.mjs` (eight cities, 14 methods, 122 days, every instant compared in milliseconds between the Dart VM and the compiled JavaScript in Node; zero differences)
- [ ] T096 [P] [US2] Write `packages/masjid_schedule/test/engine_identity_test.dart` (`MasjidScheduleEngine(source: null)` equals the wrapped engine for 14 methods, 20 cities and 366 days) and extend `apps/mobile/test/domain/alerts/planner_plan_builder_test.dart` (plan equals the Phase 0 plan byte for byte when the source is calculated)
- [ ] T097 [P] [US2] Write new sequences in `packages/schedule_planner/test_vectors/arbiter.json` (switch before play, switch after play, played-then-switch skips the later time) replayed by Dart in `packages/schedule_planner/test/arbiter_vectors_test.dart` and by Kotlin in `apps/mobile/android/app/src/androidTest/kotlin/org/deenapp/mobile/ArbiterVectorsTest.kt`, and additions-only planning vectors (Masjid days through `dayOverrides`, quiet hours in another zone, renewal cap) in `packages/schedule_planner/test_vectors/planning_dst.json`
- [ ] T098 [P] [US2] Write `apps/mobile/test/domain/alerts/schedule_coordinator_test.dart` additions (new trigger `masjidChanged`, fingerprint includes source, schedule version and sync day so an update is not skipped as unchanged) and `apps/mobile/test/domain/directory/staleness_test.dart` (30 days since last successful sync, a manifest confirming the held `overlay.gen` counts as a sync, clock moved backwards distrusts `syncedAt`, per-day fallback)
- [ ] T099 [P] [US2] Write server tests in `services/api/test/unit/sched-bundle.test.ts` (rules only, id-only stubs for every Masjid in the area, Verified only including the grace period, Suspended and Revoked withdrawn, no contacts or photos, Pending shows overlay `st` only) and `services/api/test/integration/overlay-pack.test.ts`

### Implementation for User Story 2

- [ ] T100 [US2] Create `specs/002-masjid-directory-verification/contracts/schemas/masjid-schedule-1.json` from the schema in `contracts/schedule-rules.md` section 3 and add an Ajv test in `services/api/test/unit/schedule-schema.test.ts` that validates every vector input
- [ ] T101 [US2] Implement the rule model, JSON parsing, `wallToUtc`, rounding and `expandDay` in `packages/masjid_schedule/lib/src/` (rules E1 to E11 and D1 to D6; Masjid zone governs; own `wallToUtc`, not `LocalClock.toUtc`) with no `dart:io`
- [ ] T102 [US2] Implement `validate` in `packages/masjid_schedule/lib/src/validate.dart` returning issue codes with severity and path
- [ ] T103 [US2] Implement `MasjidScheduleEngine` in `packages/masjid_schedule/lib/src/masjid_schedule_engine.dart` (wraps `PrayerTimeEngine`; sunrise, Imsak and midnight stay calculated; per-day fallback) and add `NoticeCode.masjidSchedule` and `NoticeCode.masjidFallbackStale` in `packages/prayer_engine/lib/src/types.dart` with the exhaustive-switch fix in `apps/mobile/lib/ui/home/detail_page.dart`
- [ ] T104 [US2] Switch the bundled-time-zone import in `packages/prayer_engine/lib/src/offset_resolver.dart` to a conditional import that uses the 10-year data on the JavaScript build, and add `packages/masjid_schedule/tool/build_js.dart` (`dart compile js -O2`, bundle size budget 120 KB brotli, writes `packages/masjid_schedule/build/js/masjid_schedule.js`)
- [ ] T105 [US2] Add the CI step that builds the JavaScript module and runs the parity and vector tests in `.github/workflows/ci-server.yml` (Dart SDK from the pinned version with checksum) and publish the module as a build artifact consumed by `services/api` and `apps/operator-console`
- [ ] T106 [US2] Implement the Node bridge in `services/api/src/schedule/js-bridge.ts` (worker thread, JSON in and out, timeouts) exposing `validateSchedule`, `expandPreview` with tests in `services/api/test/unit/js-bridge.test.ts`
- [ ] T107 [US2] Implement the overlay and schedule-bundle builders in `services/api/src/packs/overlay.ts` and `services/api/src/packs/sched.ts` (fields `st`, `vu`, `cm`, `as`, `hl`, `of`, `sr`; id-only stubs per precision-4 area; padding; `overlay/index.json`) and trigger rebuilds of the dirty cells from the `packs` queue
- [ ] T108 [US2] Add the planner changes in `packages/schedule_planner/lib/src/`: `RebuildTrigger.masjidChanged` with `skipsWhenUnchanged`, the fingerprint fields, `PlannerInput.quietHoursZoneId` (quiet hours stay in the phone's zone), `PlannerInput.masjidExpiresAt` and the renewal alert cap `min(existing, expiresAt - 3 days)`, and the effective-location provider (Masjid coordinates and zone name the dates) in `apps/mobile/lib/app/providers/prayer_providers.dart`
- [ ] T109 [US2] Implement the schedule cache and sync in `apps/mobile/lib/data/directory/schedule_repository.dart` (fetch the area bundle for each followed Masjid, store rules with `syncedAt`, `expiresAt`, sha and etag, count a manifest confirmation of the held `overlay.gen` as a sync, detect status changes into `masjid_notice`, keep the last good rules until `expiresAt`)
- [ ] T110 [US2] Implement the source switch use case in `apps/mobile/lib/domain/directory/schedule_source.dart` (confirm required, switch to and from calculated times, "applies from tomorrow" when a prayer today already played, Friday alert follows the chosen Jumu'ah shift, Iqamah display-only) and rebuild alerts through `ScheduleCoordinator`
- [ ] T111 [US2] Add the UI in `apps/mobile/lib/ui/directory/` and `apps/mobile/lib/ui/home/` : source switch, Jumu'ah shift picker per follow, Iqamah times, "updated" markers, the time-zone banner ("your phone is in X, times are for Y"), the stale-schedule banner, the status-changed banner with one tap to calculated times, and a Reliability page row in `apps/mobile/lib/ui/reliability/`
- [ ] T112 [P] [US2] Add Arabic, Urdu and Bahasa Indonesia strings and right-to-left goldens for the schedule UI in `apps/mobile/lib/l10n/fragments/masjid.json` and `apps/mobile/test/ui/goldens/schedule/`
- [ ] T113 [US2] Add `apps/mobile/integration_test/phase0_offline_test.dart` and a CI job variant in `.github/workflows/ci.yml` that runs the whole Phase 0 suite under `DEEN_TEST_NET=off`, `fail` and `hang`, once with an empty `DEEN_DIRECTORY_BASE_URL`, and the instrumented suite in airplane mode via `scripts/ci-android-instrumented.sh`
- [ ] T114 [US2] [DEVICE] Measure the switch-to-Masjid-schedule time (target under 5 seconds, no duplicate alerts) on Pixel, Samsung, Xiaomi and iPhone and record results in `specs/002-masjid-directory-verification/evidence/scenario-b-YYYYMMDD/`
- [ ] T115 [US2] [DEVICE] Re-run the Phase 0 device matrix and the 7-day soak with the server blocked (airplane mode, and Wi-Fi with a DNS blackhole) and record results in `specs/002-masjid-directory-verification/evidence/scenario-c-YYYYMMDD/`

**Checkpoint**: a seeded Verified Masjid schedule replaces calculated times on the phone and the Phase 0 suite is unchanged with the server down.

---

## Phase 6: User Story 3 - Claim and verify a Masjid (Priority: P1) MVP

**Goal**: A Masjid Admin signs up with strong credentials and multi-factor sign-in, claims or creates a Masjid, submits evidence, and an Operator verifies it by phone and decides; every step is audited; evidence is encrypted and deleted 90 days after the decision.

**Independent Test**: Run a claim from sign-up to a Verified or Rejected decision and read the audit log (`quickstart.md` Scenarios D, E, F, G). Covers FR-004, FR-006, FR-008, FR-016 to FR-018, FR-026, FR-032, SC-008.

### 6a. Accounts, passwords, second factor, sessions

- [ ] T116 [P] [US3] Write tests first in `services/api/test/unit/password.test.ts` (length 12 and 15 for Operators, maximum 128, any Unicode, no composition rules, blocklist hit, context words, argon2id parameters, dummy hash for unknown email) then implement `services/api/src/auth/password.ts` and `services/api/scripts/build-blocklist.ts` (top one million list as a sorted SHA-1 binary file searched by binary search)
- [ ] T117 [P] [US3] Write tests first in `services/api/test/unit/totp.test.ts` (RFC 6238 vectors, window zero, replay rejected through the Valkey mark and `last_used_step`, secret encrypted with AES-256-GCM and account id as additional data, a fresh step for step-up) then implement `services/api/src/auth/totp.ts`
- [ ] T118 [P] [US3] Write tests first in `services/api/test/unit/recovery-codes.test.ts` (ten codes, 80 bits, argon2id hashed, single use, regenerate invalidates, input normalisation) then implement `services/api/src/auth/recovery-codes.ts`
- [ ] T119 [US3] Write tests first in `services/api/test/integration/session.test.ts` (opaque 256-bit ids, `__Host-sid`, rotation at login, step-up and role change, idle and absolute timeouts per role, concurrent session limits, revoke, `session_epoch` kills a restored Valkey snapshot, pre-auth `__Host-pa` cookie is never a session) then implement `services/api/src/session/store.ts` and `services/api/src/session/preauth.ts`
- [ ] T120 [US3] Write tests first in `services/api/test/mfa/enforcement.test.ts` generating every session state (none, password-only, enrolment pending, verified, expired, after reset, after break-glass) against every protected route (only "verified" reaches a handler; others return `mfa_required` with no data; the public allow-list is explicit; no SMS or social endpoint exists) then implement the MFA gate in `services/api/src/auth/gate.ts`
- [ ] T121 [US3] Implement brute-force and lockout controls in `services/api/src/auth/throttle.ts` (5 failures per 15 minutes per account, 20 per address, doubling cool-off to 24 hours, Operators lock after 10 until another super-admin unlocks, identical responses for unknown and known accounts) with tests in `services/api/test/integration/throttle.test.ts`, and the `auth_event` writer with raw address retention of 30 days then truncation in `services/api/src/auth/auth-events.ts`
- [ ] T122 [US3] Implement the `auth` and `account` route groups (sign-up, email verification, login, TOTP verify, enrolment start and confirm, recovery codes shown once, recovery-code step, logout, session list and terminate, step-up, password change, `getSession`, change email, account delete request, own-data export request) in `services/api/src/routes/auth.ts` and `services/api/src/routes/account.ts`, with contract tests in `services/api/test/contract/auth.test.ts`
- [ ] T123 [US3] Implement the account lifecycle tables migration `services/api/migrations/0007_auth_and_mail.sql` (reset_token, recovery_case, auth_event, email_outbox, operator_task; `privacy_request` is added in US7) and attach audit triggers

### 6b. Claims, evidence, committee contacts, decisions

- [ ] T124 [US3] Generate the transition table: write `services/domain/scripts/gen-transitions.ts` that reads `contracts/state-machines.md` and emits `services/domain/src/claim-transitions.ts` (`satisfies Record<State, Record<Event, Rule | null>>`), plus a CI check that fails if the generated file or the doc differs
- [ ] T125 [US3] Write tests first in `services/api/test/unit/state-machine.test.ts` (every state and event pair for all 12 machines, 653 pairs: illegal pairs return 409, leave state unchanged and write zero audit rows; model-based random sequences with a fake clock; identical-evidence resubmission stays rejected; at most one appeal per decision) and `services/api/test/integration/transition-trigger.test.ts` (direct `UPDATE` of every illegal pair is rejected by the database trigger)
- [ ] T126 [US3] Add `services/api/migrations/0006_claims.sql` (claim, decision, appeal, claim_conflict and members, evidence_file, evidence_fingerprint, committee_contact, verification_call, case_note, masjid_member, invitation, ownership_transfer; then the foreign key `masjid.verified_claim_id`) and `services/api/migrations/0010_enforcement.sql` (audit triggers on every audited table, transition triggers, row-level security on `committee_contact`, column and table grants, `evidence_open()`, `read_committee_contact()`, seeded `state_transition`)
- [ ] T127 [US3] Implement the transition engine in `services/api/src/domain/transition.ts` consuming `services/domain/src/claim-transitions.ts` (guards, side effects, one audit action per event, optimistic checks) and the listing-status projection in `services/api/src/domain/listing-status.ts` (Unclaimed, Pending, Verified, Suspended, Revoked; badge mapping)
- [ ] T128 [P] [US3] Write tests first in `services/api/test/unit/evidence-crypto.test.ts` (AES-256-GCM blob format `magic | version | kek_id | nonce | ciphertext | tag`, additional authenticated data, tamper and wrong-key failures, KEK rotation re-wraps data keys only) then implement `services/api/src/evidence/crypto.ts` and `services/api/src/evidence/store.ts` (`EvidenceStore{put,get,delete}` over a directory owned by `evidence_svc`)
- [ ] T129 [US3] Write tests first in `services/api/test/integration/upload-abuse.test.ts` (wrong magic bytes, polyglot, zip bomb, huge pixel dimensions, truncated PDF, PDF with JavaScript, `../` filenames, EICAR, over limits 10 MB, 8 files, 40 MB; HEIC, SVG, GIF, archives and Office rejected) then implement the upload pipeline in `services/api/src/evidence/upload.ts` and `services/api/src/transcode/` (magic-byte allow-list, quarantine on tmpfs with a byte counter, `vips` and `pdftoppm` run as separate sandboxed executables with no network, memory and time limits, re-encode to WebP at most 3000 px, metadata dropped, PDFs at most 10 pages at 150 dpi, random disk names, display label sanitised)
- [ ] T130 [US3] Write tests first in `services/api/test/integration/evidence-access.test.ts` (stored bytes differ from the plaintext; no key in a database dump; non-assigned Operator gets the same 404 as a missing item; `evidence.view_start` written before decryption and a failed audit write blocks the view (fail-closed); every view and end audited; committee contacts visible only to the assigned Operator while the case is open and not after) then implement the evidence view and contact read in `services/api/src/evidence/access.ts`
- [ ] T131 [US3] Implement the evidence retention sweeper in `services/api/src/jobs/evidence-sweeper.ts` (daily: `delete_after <= now` and no hold: set `wrapped_dek` to null, delete contacts and notes, write `evidence.purged`, then unlink; appeal hold; 30-day reminder to the super-admin for holds; draft evidence deleted 7 days after timeout or withdrawal; early deletion on request; `evidence_past_due` metric) with fake-clock tests in `services/api/test/integration/evidence-sweeper.test.ts` (day 89 present, day 91 gone, restored older dump re-swept)
- [ ] T132 [US3] Implement the evidence fingerprint in `services/api/src/evidence/fingerprint.ts` (HMAC-SHA256 of sanitised images with the pepper from SOPS, kept 12 months after a merit rejection, nothing else; lost arbitration and no-response store none) and the identical-evidence check at claim submit
- [ ] T133 [US3] Implement the `claims` route group in `services/api/src/routes/claims.ts` (create, submit, add evidence multipart, list own, read status with reason, appeal once, withdraw, request early deletion, submit two committee contacts) with contract tests in `services/api/test/contract/claims.test.ts`
- [ ] T134 [US3] Implement the `operator-review` route group in `services/api/src/routes/operator-review.ts` (queue with filters, take and assign, read case, evidence list and view, committee contact read, add note, record verification call outcome with codes C1 to C7, decide verify, needs more information or reject with a required reason code, appeal decision, conflict list and arbitration) with step-up rules from the authorization matrix and contract tests in `services/api/test/contract/operator-review.test.ts`
- [ ] T135 [US3] Implement conflicting claims in `services/api/src/domain/conflict.ts` (both claims held, no edit rights, Operator arbitration, `freeze_incumbent` only on Operator choice, `arbitrate_resume` returns the winner to the queue) and ownership transfer, invitations and members in `services/api/src/routes/masjid-members.ts` with tests in `services/api/test/integration/conflict.test.ts`
- [ ] T136 [US3] Implement verification lifecycle jobs in `services/api/src/jobs/verification-lifecycle.ts` (`verified_until` = decision + 12 months, reminder at T-30 days with `reminder_sent_at`, renewal opens at T-30, 30-day grace, then listing drops to Pending and the schedule layer is withdrawn from the next pack build, "Needs more information" timeout after 30 days to Rejected with `REJ-NO-RESPONSE`, bounced-address task) with tests in `services/api/test/integration/verification-lifecycle.test.ts` using a fake clock (+335, +365 and +395 days)
- [ ] T137 [US3] Implement the audit read routes for admins and Operators in `services/api/src/routes/audit.ts` (admins see rows for their own Masjids without evidence, contact or Operator-name events; Operators see all and their searches are audited; Muazzins none; chain verification status for super-admins) with tests in `services/api/test/integration/audit-read.test.ts`
- [ ] T138 [P] [US3] Generate the authorization matrix test in `services/api/test/authz/matrix.test.ts` from `services/domain/src/authz-policy.ts` plus the independent hand-written never-list from `contracts/authz-matrix.md` (about 60 operations by 9 principals by 4 targets; an admin of another Masjid never gets a 2xx on private data; identical responses for another Masjid's resource and a missing one) and a completeness test that every route has a policy row
- [ ] T139 [US3] Write the audit coverage test in `services/api/test/integration/audit-coverage.test.ts` (wrap the database client, record every INSERT, UPDATE and DELETE on audited tables per request, assert an audit row with actor and time in the same transaction for every state-changing route)

### 6c. Recovery: password reset, second-factor reset, break-glass

- [ ] T140 [US3] Write tests first in `services/api/test/integration/recovery.test.ts` (password reset: always 202 with the same body and timing, token valid 10 minutes, single use, never bypasses MFA, kills sessions; second-factor reset: password plus email link plus a consumed recovery code plus an Operator at least reviewer who is not the requester, no delay; break-glass: super-admin initiates, contact on the case called, a different Operator at reviewer or above approves (database check approver differs from initiator), 48-hour delay by an injectable clock with reminders at 24 hours and 1 hour, notification emails with a cancel link, cancel by the admin or either Operator, all old sessions closed, execution re-checks that the Masjid is not Suspended or Revoked)
- [ ] T141 [US3] Implement the `recovery` route group and state machines in `services/api/src/routes/recovery.ts` and `services/api/src/domain/recovery.ts` (password reset request and confirm, second-factor reset start and advance, break-glass initiate, contacts put and get, call log, approve, cancel, status, public lockout request `createRecoveryRequest` that creates the `recovery_request` task, `unlockAccount`) and the delayed notice and execution jobs in `services/api/src/jobs/recovery.ts` (`not_before` is authoritative; the job only notifies and re-checks)

### 6d. Admin console pages for the claim flow

- [ ] T142 [US3] Implement the API client, session, CSRF token handling and error mapping in `apps/operator-console/src/api/client.ts` and `apps/operator-console/src/session/` using `openapi-fetch` and the generated types
- [ ] T143 [US3] Implement the sign-up, verify-email, login, authenticator enrolment, printable recovery-code page, step-up dialog, password reset and lost-authenticator request pages in `apps/operator-console/src/routes/auth/` with the strength meter running in the browser only
- [ ] T144 [US3] Implement the claim wizard (find or create a Masjid, evidence upload, two committee contacts, submit), the claim status page showing status and reason, appeal and withdraw, and early-deletion request in `apps/operator-console/src/routes/claims/`
- [ ] T145 [P] [US3] Write Playwright tests in `apps/operator-console/e2e/claim-flow.spec.ts` (direct URL to every protected route before MFA redirects to enrolment or verification; the editor cannot be reached without MFA) and `apps/operator-console/e2e/csp.spec.ts` (strict CSP, zero violations, the React Aria style hash drift check, headers asserted on 200, 404 and 500)
- [ ] T146 [P] [US3] Add axe tests for every US3 page in English and `dir=rtl` in `apps/operator-console/e2e/a11y-us3.spec.ts` and the English strings in `apps/operator-console/src/i18n/en.json` extracted with `@formatjs/cli`
- [ ] T147 [US3] Run `quickstart.md` Scenarios D, E, F and G with the fake clock and record the audit log export, the matrix reports and the verdict in `specs/002-masjid-directory-verification/evidence/scenario-d-g-YYYYMMDD/`

**Checkpoint (MVP)**: US1, US2 and US3 together: a real Masjid can be claimed, verified by a phone call, published, found and followed on a phone, and its schedule drives alerts.

---


## Phase 7: User Story 4 - Manage a Masjid's profile and schedule (Priority: P2)

**Goal**: A Verified Masjid's admins edit names, address, location, madhhab, method, variant, photos and schedule with a 14-day preview and impossible-value warnings; edits are versioned and can be rolled back; a Pending Masjid shows listeners only its name and location.

**Independent Test**: Edit a Verified Masjid, see it appear for listeners after the next build, then roll the edit back (`quickstart.md` Scenario D step 4 and the dry-run path for Al-Noor). Covers FR-007, FR-013, FR-019, FR-020, FR-029, FR-030.

### Tests for User Story 4 (write first, confirm they fail)

- [ ] T148 [P] [US4] Write `services/api/test/integration/profile-edit.test.ts` (optimistic lock: stale `If-Match` returns 412, a lost race 409, a missing header 428, all `version_conflict`; every edit creates a `masjid_version`; rollback creates a new version copying an older one; names need exactly one primary; Pending Masjid publishes name and location only, marked unverified; edits to base fields are published only after the admin accepted the ODbL-compatible terms, otherwise queued for an Operator)
- [ ] T149 [P] [US4] Write `services/api/test/integration/schedule-edit.test.ts` (replace rules with `If-Match`, validation errors reject the save with issue codes, warnings return with a 200, a 14-day preview equals the Dart expansion, calc settings override in the preview request, history and rollback)
- [ ] T150 [P] [US4] Write `services/api/test/integration/photo-upload.test.ts` (same allow-list and transcoder as evidence, EXIF and GPS removed, size caps, photos never appear in any published file) using `scripts/pack-check`
- [ ] T151 [P] [US4] Write `apps/operator-console/e2e/profile-schedule.spec.ts` (edit names in Arabic script, transliteration and local language with one primary; place a pin and enter coordinates; build a summer and winter range plus two Jumu'ah shifts; see the warning for Iqamah before Azaan; preview 14 days; roll back) and `apps/operator-console/e2e/a11y-us4.spec.ts` (axe in English and `dir=rtl`, keyboard-only)

### Implementation for User Story 4

- [ ] T152 [US4] Implement the profile routes in `services/api/src/routes/masjids-profile.ts` (read, create, edit with `If-Match`, name translations, location and address, languages and facilities, madhhab, method and Azaan variant, `calc_settings`, public contact) and the version history and rollback routes in `services/api/src/routes/masjids-versions.ts`
- [ ] T153 [US4] Implement the terms-acceptance flow in `services/api/src/domain/terms.ts` and `services/api/src/routes/account-terms.ts` (record `terms_acceptance`, `masjid_version.terms_version`) and the Operator queue entry for edits made without accepted terms
- [ ] T154 [US4] Implement photo upload, list, download and delete in `services/api/src/routes/masjids-photos.ts` reusing `services/api/src/transcode/` (re-encode, metadata dropped, random disk names)
- [ ] T155 [US4] Implement the `schedules` route group in `services/api/src/routes/schedules.ts` (read rules, replace with `If-Match`, validate, preview 14 days through `services/api/src/schedule/js-bridge.ts`, history, rollback) and mark dirty cells for the `packs` queue after every commit
- [ ] T156 [US4] Implement the console profile editor in `apps/operator-console/src/routes/masjid/profile.tsx` (translation rows with the primary choice, address, madhhab, method and variant selects, languages and facilities lists, photos, contact details, save with version check and conflict dialog)
- [ ] T157 [US4] Implement the coordinate picker in `apps/operator-console/src/components/LocationPicker.tsx` with MapLibre and self-hosted PMTiles (`setWorkerUrl` through the Vite `?url` import, `worker-src 'self'`, glyphs and sprites from our own host) and the list-plus-coordinate-entry fallback when no tiles are configured (FR-029); test Arabic label shaping and the RTL text plugin need in `apps/operator-console/e2e/map-arabic.spec.ts`
- [ ] T158 [P] [US4] Add `infra/tiles/extract.sh` (Protomaps build to a national z0 to 13 extract plus city boxes at z14 to 15 with `pmtiles extract`, run on a laptop or in CI, never on the server), `infra/tiles/README.md` (attribution, refresh quarterly, excluded from backups) and copy the basemap assets and Noto fonts (SIL OFL) into `apps/operator-console/public/map-assets/` with their licenses in `content/LICENSES.md`
- [ ] T159 [US4] Implement the schedule editor in `apps/operator-console/src/routes/masjid/schedule.tsx` (date ranges, the three time forms, Iqamah, Jumu'ah shifts, calc settings) loading `masjid_schedule.js` in a Web Worker (`apps/operator-console/src/workers/schedule.worker.ts`) for the 14-day preview and live validation, showing the tzdata version in the footer and the issue codes from `contracts/schedule-rules.md`
- [ ] T160 [US4] Implement the version history and rollback UI in `apps/operator-console/src/routes/masjid/history.tsx` and the members, invitations and ownership-transfer pages in `apps/operator-console/src/routes/masjid/members.tsx` (US3 routes)
- [ ] T161 [P] [US4] Add the English strings in `apps/operator-console/src/i18n/en.json`, extract with `@formatjs/cli`, and add a pseudo-locale long-string test in `apps/operator-console/e2e/pseudo-locale.spec.ts`

**Checkpoint**: an admin keeps a Verified listing and schedule accurate, with preview, warnings and rollback.

---

## Phase 8: User Story 5 - Operator console (Priority: P2)

**Goal**: Operators review claims, search everything, suspend or revoke, handle abuse reports and run recoveries with strict roles, step-up and a complete audit trail.

**Independent Test**: Decide a claim, suspend a Masjid, handle an abuse report and perform a two-person recovery, then check the audit trail (`quickstart.md` Scenarios D, F and K). Covers FR-021, SC-002, SC-008.

### Tests for User Story 5 (write first, confirm they fail)

- [ ] T162 [P] [US5] Write `services/api/test/integration/operator-moderation.test.ts` (suspend and reinstate for moderator and super-admin only; revoke for reviewer and super-admin; a reviewer files a `suspension_flag` task instead of suspending; suspended Masjid withdrawn from the next pack build; person suspension kills sessions; every action audited and step-up required)
- [ ] T163 [P] [US5] Write `services/api/test/integration/operator-admin.test.ts` (only a super-admin creates Operators, changes roles or offboards; offboarding revokes sessions and reassigns open cases; Operators need 15-character passwords and MFA; search across Masjids, people and audit events is itself audited; lockout of an Operator needs another super-admin)
- [ ] T164 [P] [US5] Write `apps/operator-console/e2e/operator-roles.spec.ts` (each role sees and can do only what the matrix allows; idle timeout 15, 15 and 10 minutes and absolute limits; step-up dialog; evidence viewer shows images only, fetched as bytes, blob URL revoked on close, Operator watermark visible) and `apps/operator-console/e2e/a11y-us5.spec.ts` (axe in English and `dir=rtl`, keyboard-only review of a claim)

### Implementation for User Story 5

- [ ] T165 [US5] Add `services/api/migrations/0008_public_and_merge.sql` (suggestion, abuse_report, duplicate_candidate, masjid_merge) with audit and transition triggers; it is also used by US6
- [ ] T166 [US5] Implement the `operator-moderation` route group in `services/api/src/routes/operator-moderation.ts` (suspend, reinstate, revoke Masjid and person, abuse-report list, triage, status transitions and resolve, `flagForSuspension`, `listOperatorTasks`, `completeOperatorTask` for `suspension_flag` and `recovery_request` tasks) with contract tests in `services/api/test/contract/operator-moderation.test.ts`
- [ ] T167 [US5] Implement the `operator-admin` route group in `services/api/src/routes/operator-admin.ts` (Operator accounts and roles, offboarding, global search with audit, audit filters and chain verification status, review SLA report for SC-002, audit coverage report for SC-008) with contract tests in `services/api/test/contract/operator-admin.test.ts`
- [ ] T168 [US5] Implement the audit chain jobs in `services/api/src/jobs/audit-chain.ts` (nightly `verify_chain()`, daily head-hash anchor to an off-server destination configured in `infra/`, `audit_purge()` at 24 months with a checkpoint row) with tests in `services/api/test/integration/audit-chain.test.ts`
- [ ] T169 [US5] Implement the console review queue and case page in `apps/operator-console/src/routes/review/` (filters by status, age, country and assignee; evidence viewer showing sanitised page images with the watermark; notes; call outcome form; decision buttons with required reasons; appeal and arbitration views; the page reads button enablement from `services/domain/src/claim-transitions.ts`)
- [ ] T170 [US5] Implement the console moderation pages in `apps/operator-console/src/routes/moderation/` (suspend and revoke dialogs with reasons, abuse-report workflow, suspension flags and recovery requests task list, person suspension)
- [ ] T171 [US5] Implement the console search, audit viewer and dashboards in `apps/operator-console/src/routes/search/`, `apps/operator-console/src/routes/audit/` and `apps/operator-console/src/routes/reports/` (SLA in working days, audit coverage, chain verification)
- [ ] T172 [US5] Implement the console Operator administration in `apps/operator-console/src/routes/operators/` (create, role change, offboarding checklist, unlock) and the break-glass and second-factor reset pages in `apps/operator-console/src/routes/recovery/` (initiate, log the call, approve, cancel, status with the 48-hour countdown)
- [ ] T173 [US5] Implement console session behaviour in `apps/operator-console/src/session/idle.ts` (idle and absolute timeouts per role, warning dialog, forced re-login, step-up freshness) and the role-aware navigation in `apps/operator-console/src/routes/layout.tsx`
- [ ] T174 [P] [US5] Add the English strings in `apps/operator-console/src/i18n/en.json` for the Operator pages and the keyboard-shortcut help page

**Checkpoint**: a two-Operator team can run the whole review and moderation workflow from the console.

---

## Phase 9: User Story 6 - Directory seeding and quality (Priority: P2)

**Goal**: The directory starts from OpenStreetMap, stays clean through moderation, accepts listener suggestions without identifying anyone, shows attribution everywhere, and publishes the open data layer.

**Independent Test**: Import a sample region, merge a duplicate, accept a suggestion, and view the attribution in the app and the console (`quickstart.md` Scenario H). Covers FR-022, FR-023, FR-031, FR-033.

### Tests for User Story 6 (write first, confirm they fail)

- [ ] T175 [P] [US6] Write `services/api/test/integration/duplicates.test.ts` (high: within 30 m and shared normalised name, node inside a building outline or one side unnamed; medium: within 150 m and `pg_trgm` similarity at least 0.35; cross-script pairs compared after normalisation; never auto-merged; merged ids kept as aliases and published in `redirects.json`; `pg_trgm` behaviour on Arabic names on a UTF-8 database)
- [ ] T176 [P] [US6] Write `services/api/test/integration/public-writes.test.ts` (suggestions and abuse reports: existing Masjid id plus text, or new Masjid with cell id, country and free-text name and address and no coordinates; proof of work required; honeypot; rate-limit key is a salted hash in Valkey with a time to live of at most 1 hour; a scan of the database, logs and a dump finds no address, no hash, no identifier; responses never reveal whether anything matched; contact email deleted 30 days after the case closes)
- [ ] T177 [P] [US6] Write `services/api/test/integration/import-review.test.ts` (staging diff against the previous batch, bounding checks of coordinates against the country, name length and URL scheme stripping, HTML escaped, Operator approval before publication, rollback of a batch restores the previous generation) and `services/api/test/unit/licence-fields.test.ts` (no field outside the allow-list in any published file; the dump contains only OpenStreetMap-derived and curated base fields)

### Implementation for User Story 6

- [ ] T178 [US6] Implement duplicate detection and merge in `services/api/src/directory/duplicates.ts` and the `operator-directory` routes in `services/api/src/routes/operator-directory.ts` (candidate list, merge, dismiss, import batch list, staging diff, approve, rollback, curated entries with `sources[]`) with contract tests in `services/api/test/contract/operator-directory.test.ts`
- [ ] T179 [US6] Implement the `public` routes in `services/api/src/routes/public.ts` (`getPowChallenge`, `createSuggestion`, `createAbuseReport`) and the self-hosted proof-of-work service in `services/api/src/public/pow.ts` (Altcha-style, stateless verification, verified license and version in `content/register/server-deps.md`); the `api.` host serves nothing else
- [ ] T180 [US6] Implement the app side of suggestions and abuse reports in `packages/directory_client/lib/src/public_posts.dart` and `apps/mobile/lib/ui/directory/suggest_page.dart` (correction text for an existing Masjid; for a new Masjid the cell id, country and free-text name and address; no coordinates; solve the challenge; show the same neutral response always) with the egress vectors extended in `packages/directory_client/test/egress_vectors.json`
- [ ] T181 [US6] Implement monthly full re-import per enabled country and the optional weekly Overpass delta for pilot countries in `services/api/src/jobs/osm-refresh.ts` (replication timestamp recorded; tombstones; redirects)
- [ ] T182 [US6] Hand-verify and publish the curated list: write `tools/directory-pack/seed/curated.json` for the Two Holy Mosques and other major Masjids with `sources[]` (official site or authority and Wikidata, license, retrieved date), review by a second person, and add a test `tools/directory-pack/test/curated_test.dart` that fails on an entry without sources or with proprietary-map provenance [OWNER]
- [ ] T183 [US6] Implement the console import review and suggestions queue in `apps/operator-console/src/routes/directory/` (staging diff, approve, rollback, duplicate merge, suggestion accept into the base layer, reject, merge with a duplicate, curated entry editor) with English strings and axe tests in `apps/operator-console/e2e/a11y-us6.spec.ts`
- [ ] T184 [P] [US6] Add the attribution surfaces: the console footer and map corner `© OpenStreetMap contributors`, the app About screen (full ODbL notice text, Licences list) in `apps/mobile/lib/ui/about/`, the dump `NOTICE.md`, the `lic` field of every pack file, and the rows for OpenStreetMap, ODbL, Wikidata, Noto fonts and Protomaps assets in `content/LICENSES.md`; regenerate `LICENSES/NOTICE` with `dart run tools/license_scan/bin/notice.dart`
- [ ] T185 [P] [US6] Add the GitHub Release publishing script for the open dump in `scripts/publish-dump.sh` (assets `directory-base-{gen}.ndjson.gz`, `LICENSE-ODbL-1.0.txt`, `NOTICE.md`, `SHA256SUMS`; last 12 kept; `latest` pointer) and publish the importer, SQL and generator method under `tools/directory-pack/` with a README that states the ODbL offer of method
- [ ] T186 [US6] Run `quickstart.md` Scenario H on one small country and record the generation, dump checksums, `pack-check` output and screenshots of the attribution in `specs/002-masjid-directory-verification/evidence/scenario-h-YYYYMMDD/`

**Checkpoint**: the directory is seeded, moderated and attributed, and listeners can contribute without being identified.

---

## Phase 10: User Story 7 - Admin lifecycle and data requests (Priority: P3)

**Goal**: Admins and Muazzins delete their accounts and export their own data; Operators answer privacy requests within 30 days.

**Independent Test**: Delete an admin account and export a Muazzin's data, then close a privacy request (`quickstart.md` Scenario K, Masjid Taqwa path). Covers FR-024.

### Tests for User Story 7 (write first, confirm they fail)

- [ ] T187 [P] [US7] Write `services/api/test/integration/account-deletion.test.ts` (personal data removed; the Masjid listing and audit rows stay; the `actor_map` row is deleted so entries become unlinkable and show "Former admin"; sessions killed; the last admin of a Masjid cannot delete without transferring or an Operator decision; deletion audited)
- [ ] T188 [P] [US7] Write `services/api/test/integration/privacy-requests.test.ts` (export contains only the requester's own data and their own audit rows; deadline 30 days, reminder at day 20, overdue flag after day 30; identity check; erasure refusal reasons recorded; export downloads audited) and `services/api/test/integration/retention-sweepers.test.ts` (raw address 30 days then truncated /24 or /48 for 12 months then deleted; suggestion contact email 30 days after closure; fingerprints 12 months after rejection; audit purge at 24 months with a checkpoint; database backups at most 30 days)

### Implementation for User Story 7

- [ ] T189 [US7] Add `services/api/migrations/0012_privacy.sql` (privacy_request with deadline fields) with audit and transition triggers
- [ ] T190 [US7] Implement account deletion and own-data export in `services/api/src/domain/account-lifecycle.ts` and finish the routes `requestAccountDeletion` and `requestDataExport` in `services/api/src/routes/account.ts`
- [ ] T191 [US7] Implement the privacy-request routes and jobs in `services/api/src/routes/privacy.ts` and `services/api/src/jobs/privacy.ts` (open, verify identity, export, erase, refuse, close; reminder at day 20; overdue flag after day 30) and the retention sweepers in `services/api/src/jobs/retention.ts`
- [ ] T192 [US7] Implement the console pages in `apps/operator-console/src/routes/account/` (delete account, export my data, session list) and `apps/operator-console/src/routes/privacy/` (Operator privacy-request queue with deadlines) with axe tests in `apps/operator-console/e2e/a11y-us7.spec.ts`

**Checkpoint**: personal data can be exported and deleted on time; retention rules run on their own.

---

## Phase 11: Production infrastructure and operations

**Purpose**: Everything needed to run the pilot on the purchased server inside the cost ceiling. Required before any release.

- [ ] T193 Implement `infra/bootstrap.sh` (also valid as cloud-init user data): deploy user, SSH keys only with root login and passwords off, default-deny firewall allowing 80, 443 tcp and udp and WireGuard, Docker rules in the `DOCKER-USER` chain, unattended security upgrades, `chrony`, journald limits, swap or zram, WireGuard to the team machine
- [ ] T194 Implement `infra/compose/docker-compose.yml` with profiles `core`, `observe`, `full`: images pinned by digest, non-root, `read_only`, `cap_drop: [ALL]`, `no-new-privileges`, `mem_limit` from `research.md` R-19, only Caddy publishes ports, the Docker socket never mounted; add the demotion steps and the numeric RAM rule to `infra/runbooks/profiles.md`
- [ ] T195 [P] Configure the mail host in `infra/mail/` (Postfix outbound only with OpenDKIM, PTR and HELO match, SPF `-all`, two DKIM selectors, DMARC first `p=none` then `p=reject`, TLS, submission on `127.0.0.1:587`) and write `infra/mail/README.md` with the SNDS and JMRP registration steps and the swap to the relay by changing `SMTP_URL`
- [ ] T196 [P] Implement secrets with SOPS and age in `infra/secrets/` (recipients: two founders and the server; `infra/Makefile` `deploy` target decrypts to tmpfs and runs Compose; a rotation procedure in `infra/runbooks/rotate-keys.md` for KEK, pepper and TOTP-secret key)
- [ ] T197 Implement backups in `infra/backup/` (`pg_dump -Fc` and `pg_dumpall --globals-only` every 6 hours staged and sent by restic with 14 daily and 2 weekly kept and no monthly copies, evidence directory excluded, pull-model repository on the team machine over WireGuard, encrypted dumps with the offline recovery key, heartbeat push to Uptime Kuma, alert if no backup in 8 hours) and `infra/backup/check.sh` that verifies freshness
- [ ] T198 [P] Set up monitoring in `infra/monitoring/`: `node_exporter`, Caddy metrics per host, Prometheus and Grafana for profile `observe` (bound to WireGuard, dashboards for RAM, requests by host and status, 200 versus 304 ratio, queue depth, `evidence_past_due`, backup age, certificate expiry), Loki and Alloy for `full`, and the Uptime Kuma configuration for the team machine probing manifest freshness, `/v1/health`, TLS expiry (14 days), SMTP banner and DNS, with alerts to the custodian's mailbox or a self-hosted ntfy
- [ ] T199 Implement the logging policy checks in `infra/caddy/test/log-policy.test.sh` (no access log on `data.`; error logs filtered; a known test address appears in no file under `/var/log`, journald, Docker logs or Caddy output; no `LOG` firewall rules on 443; no per-cell or per-address metric labels) and the evidence retention check `infra/backup/test/evidence-not-in-backup.sh`
- [ ] T200 Implement the cost report in `scripts/cost-report.sh` (reads `infra/README.md` plan facts, applies EUR to USD and VAT, prints the monthly total against US$8.00 warn and US$9.50 breach and the 25% price-rise trigger) and schedule a monthly reminder task for the Operator lead
- [ ] T201 Deploy the staging environment from `infra/` on the purchased server (or a second small VPS), run the mail day-0 checks and `infra/caddy/test/caddy-static.test.sh`, and record the deployment in `specs/002-masjid-directory-verification/evidence/deploy-staging-YYYYMMDD.md`
- [ ] T202 [P] Copy `ops/restore-runbook.md` to `infra/runbooks/restore.md` with real commands and table names, and `ops/operator-runbook.md` to a published location agreed in the decision log; keep the specs copies as pointers

---

## Phase 12: Polish, hardening and exit

**Purpose**: Evidence for every success criterion, the Phase 0 document revisions, store and privacy updates, and the Phase 1 sign-off.

### Phase 0 document and store changes

- [ ] T203 [P] Revise the Phase 0 statements that say "no network": `specs/001-offline-worship-app/spec.md` (line 9, FR-001, FR-002, SC-007), `specs/001-offline-worship-app/plan.md` (summary, technical context, Constitution check 1 and 4), `README.md`, `CONTRIBUTING.md`, `.github/pull_request_template.md`, the `check_network.dart` header comment and the manifest comment, adding the explicit consented exception
- [ ] T204 [P] Update `content/privacy/privacy-policy.md` in English, Arabic, Urdu and Bahasa Indonesia (the optional directory, what is sent, the honest disclosure that the host sees the address, no listener account, no stored follows, deletion) and the About, setup and settings strings in `apps/mobile/lib/l10n/fragments/about.json`, `setup.json`, `settings_data.json`; native-speaker review
- [ ] T205 [P] Answer the Google Play Data safety and Apple privacy label per the gate decision and update `specs/001-offline-worship-app/release/store-notes.md` sections 1 to 3 and `specs/001-offline-worship-app/research.md` (R-A7, R-I7)
- [ ] T206 [P] Publish the notices and policies listed in `ops/dpia.md` (privacy notice for admins and Muazzins, listener statement, notice for committee contacts, verification-evidence policy, retention schedule, session statement, admin terms, security policy and `security.txt`, breach response plan, subprocessor list) on the project page and link them in the console footer

### Security and quality evidence

- [ ] T207 Create `specs/002-masjid-directory-verification/checklists/asvs-l2.md` (rows: ASVS 5.0 id, applies, test id or file, evidence, status) and `scripts/check-asvs.ts` that fails when a "covered" row names a test that does not exist; record the ClamAV deviation (5.4.3) with the compensating controls
- [ ] T208 Add `.zap/rules.tsv` and the ZAP jobs in `.github/workflows/ci-server.yml` and `.github/workflows/nightly.yml` (API scan from the OpenAPI file with a pre-seeded MFA-verified session, baseline on the console, active scan nightly on staging only; medium and above fail; every warning exception has a reason) and review the first run's findings
- [ ] T209 [OWNER] Arrange the external review of the authentication module (`services/api/src/auth/`, `services/api/src/session/`, recovery flows) by a person with security experience and record findings and fixes in `specs/002-masjid-directory-verification/evidence/auth-review-YYYYMMDD.md`; this is an exit criterion before Phase 2
- [ ] T210 [P] Implement the load test in `scripts/load/run.sh`, `scripts/load/targets/` and `scripts/load/check.mjs` (vegeta scenarios S1, S2 and S3 with `If-None-Match` per target, thresholds from `plan.md`, resource limits sampled over SSH) and the protected-environment workflow `.github/workflows/load-test.yml` that refuses any target other than the `LOAD_TARGET` host
- [ ] T211 Run the load test on the staging server and record reports and the cost projection in `specs/002-masjid-directory-verification/evidence/scenario-i-YYYYMMDD/` (`quickstart.md` Scenario I)
- [ ] T212 [P] Implement `scripts/dr/smoke.sh` (health; manifest and one pack 200 and 304; admin login with MFA; claim read; audit chain intact and latest audit id not older than the backup; evidence upload, view and delete round trip on a test claim; sweeper rerun; Caddy log has no address and path pair; a real phone downloads a region) and the drill record template `specs/002-masjid-directory-verification/evidence/restore-drill-template.md`
- [ ] T213 [DRILL] Run the timed restore drill from `infra/runbooks/restore.md` on a fresh VPS with a timekeeper who is not the executor (target 2 h 45 min, limit 4 h; two signatures) and record `specs/002-masjid-directory-verification/evidence/scenario-j-YYYYMMDD/`
- [ ] T214 [DRILL] Run the Operator dry run from `ops/operator-runbook.md` with two Operators and three mock Masjids (Al-Noor, Dar-us-Salam, Masjid Taqwa) including the 48-hour break-glass delay once in real time; record the evidence CSV (`ID, Masjid, Step, Actor/role, Expected, Actual, Audit entry id(s), Screenshot file, Start, End, Pass/Fail, Defect id, Observer initials`) and fold every undocumented step back into the runbook
- [ ] T215 [DRILL] Run the 14-day mail exit test (40 seed messages to Gmail, Outlook.com, Yahoo and iCloud) and record headers and placement in `specs/002-masjid-directory-verification/evidence/scenario-l-YYYYMMDD/`; on failure adopt the relay row and update `infra/mail/`
- [ ] T216 [DEVICE] Perform the manual TalkBack, VoiceOver and keyboard-only passes of the app directory screens and the console (claim review, schedule editor, evidence viewer) and record defects and fixes in `specs/002-masjid-directory-verification/evidence/a11y-manual-YYYYMMDD.md`
- [ ] T217 [P] Produce the release SBOM and license reports (Trivy CycloneDX, `scan_server.dart`, Dart scan) as release artifacts and regenerate `LICENSES/NOTICE`; confirm every direct dependency has a register row and every `uses:` is pinned

### Exit

- [ ] T218 Run the fast gates in `quickstart.md` section 1 on `main` and confirm Phase 0 CI jobs are unchanged and green (`dart`, `android-dependencies`, `android-emulator`, `ios`)
- [ ] T219 [OWNER] Run the pilot with 3 to 5 Masjids and willing committees for 14 days, track incidents, and record the result in `specs/002-masjid-directory-verification/evidence/pilot-YYYYMMDD.md`
- [ ] T220 [GATE] [OWNER] Sign off the ten Phase 1 exit criteria in `specs/002-masjid-directory-verification/plan.md` with two Operator signatures, link each to its evidence file, and record Deferred-to-Phase-2 items (signed data files, Operator-held evidence keys, hardware keys, Iqamah alerts) as the first inputs to the Phase 2 specification

---

## Dependencies and Execution Order

### Phase dependencies

- **Phase 1 (gates)**: the first task blocks everything else; the paperwork tasks can start now. Provider test and purchase block Phase 11 deployment; legal reviews block the Phase 12 publication tasks, not coding.
- **Phase 2 (setup)** needs the first gate task (Phase 0 exit).
- **Phase 3 (foundational)** needs Phase 2 and blocks every user story. Inside it: 3a (CI and license gates) first, then 3b (server core) and 3c (client foundation) in parallel, then 3d (directory data pipeline).
- **US1 and US2** need Phase 3. US2 needs US1's directory and follow storage on the phone and the `packs` publisher, but its server part (overlay and schedule bundles) can start once Phase 3d is done.
- **US3** needs Phase 3b only; it can run in parallel with US1 and US2.
- **US4** needs US3 (accounts, claims, versions) and US2's expansion package. **US5** needs US3 (claims and evidence APIs) and shares the console shell from US3. **US6** needs Phase 3d and US5 for the console queue pages; its public-write and import tasks can start after Phase 3. **US7** needs US3.
- **Phase 11 (infrastructure)** can start after Phase 2 for the compose and bootstrap parts and needs the purchased server for deployment; it blocks every release and the Phase 12 evidence runs.
- **Phase 12** needs all stories it evidences; the Phase 0 document revisions and the notices can start as soon as the owner decisions are recorded.

### Within each story

Tests first and failing; then migrations and domain code; then routes or client code; then UI; then the quickstart scenario run and its evidence.

### Parallel opportunities

- Phase 2: the `[P]` scaffolds (api, domain, console, two Dart packages, tools, registers, infra) run together.
- Phase 3: 3a license tasks, 3b server tasks and 3c client tasks touch different trees and run in parallel.
- US1 tests (egress vectors, fake server, atomic commit, cadence, kill switch, search, follow) are all `[P]`.
- US2: the `masjid_schedule` package (vectors, wall-to-UTC, validate, properties, parity) is independent of the server bundle builders and of the planner changes.
- US3: password, TOTP, recovery codes and evidence crypto are independent modules; console pages wait for the API client.
- Across stories, with three people: one on the app (US1, US2 client), one on the server (US3, then US4, US5 APIs), one on the console and infrastructure.

### Parallel example: User Story 1

```text
T (egress vectors)  T (fake-server test)  T (atomic commit + cadence tests)
T (kill switch + staleness tests)  T (search tests)  T (follow + confirm tests)
then: EgressPolicy + DirectoryClient  ||  directory.db + search  ||  follow repositories
then: use cases and providers -> consent, search, detail and follow screens
```

## Implementation Strategy

### MVP first (US1, US2, US3)

1. Clear the gates, finish Setup and Foundational.
2. Build US1 and test it with `quickstart.md` Scenario A; at this point the app finds and confirms Masjids offline with proven cell-level traffic.
3. Build US2 with a seeded Verified Masjid; prove Scenarios B and C.
4. Build US3 and run Scenarios D to G; the three P1 stories together are the MVP because a schedule is only trustworthy after a person has verified the Masjid.
5. Stop and validate with the pilot Operators before adding US4 and US5.

### Incremental delivery

US4 (self-service profile and schedule) and US5 (full Operator console) make the pilot self-running; US6 improves directory quality and openness; US7 closes the privacy lifecycle. Phase 11 and 12 run alongside from the first deployable build; nothing ships to the stores before Phase 11 and the privacy and store tasks in Phase 12 are done.

### Notes

- `[P]` tasks touch different files and have no dependency on an unfinished task.
- Commit after each task or logical group; every commit that adds a dependency updates the register in the same pull request.
- Constitution amendments A1 to A3 and the Phase 0 document revisions are tasks here, not silent edits.
- No task may add a listener identifier, a coordinate finer than a 5 km cell, a network call outside `packages/directory_client`, or a copyleft library inside the app or the Node runtime closure.
