# Implementation Plan: Masjid Directory, Verification and Masjid Schedules (Phase 1)

**Branch**: `002-masjid-directory-verification` | **Date**: 2026-10-22 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/002-masjid-directory-verification/spec.md`, the owner's planning brief of 2026-10-22, and seven research reports consolidated in [research.md](research.md).

**Gate**: planning only. Under constitution principle 9, no feature code starts until Phase 0 meets its exit criteria (31 Phase 0 tasks still need devices, reviewers, recordings or publishing). Allowed now: paperwork (licensing review, DPIA review, Operator recruitment, provider port-25 test), listed in "Before the build starts".

## Summary

Phase 1 adds an optional server to the Phase 0 app. Listeners read static files only (a manifest, region packs per 5 km cell, schedule rule bundles per 40 km area), search them on the phone, confirm a Masjid and, if it is Verified, let its schedule replace calculated times. No listener account, no stored location, no stored follow. Masjid Admins, Muazzins and Operators use a web console backed by an admin API (Fastify, PostgreSQL with PostGIS, Valkey, pg-boss) with TOTP multi-factor sign-in, a claim and verification workflow with a human phone call, encrypted evidence that is deleted 90 days after a decision, and an append-only audit log. Everything runs on one small VPS inside US$10 per month. Schedules are published as rules; the phone expands them with the same Dart code (compiled to JavaScript for the server and the console preview), so the app, the preview and the validation cannot disagree.

## Technical Context

**Languages and versions**: server and console TypeScript 6.0 (type-check only; Node 26 runs `.ts` directly), Node.js 26 LTS (CI also 24); app Dart 3.13 and Flutter 3.47 (unchanged from Phase 0); new pure-Dart packages `masjid_schedule` and `directory_client`; SQL (PostgreSQL 18, PostGIS 3.6); shell for infrastructure scripts.

**Primary dependencies** (every license is listed in research.md and `content/register/server-deps.md`): Fastify 5, fastify-openapi-glue, Kysely, `pg`, pg-boss 12, `@node-rs/argon2`, `otpauth`, `@fastify/session`, `ioredis`, `nodemailer`; React 19, Vite 8, React Aria Components, MapLibre GL JS 6; Caddy, PostgreSQL, PostGIS, Valkey, Postfix with OpenDKIM, restic, SOPS and age; Dart `sqlite3` with FTS5 (already in Phase 0). All permissive or, for separately run server processes only, copyleft (PostGIS GPL-2.0-or-later, Grafana and Loki AGPL-3.0, osmium GPL-3.0, osm2pgsql GPL-2.0, libvips and poppler command-line tools).

**Storage**: PostgreSQL (all server state, audit log, pg-boss), Valkey (sessions, TOTP replay marks, rate-limit counters; losing it logs people out and nothing else), encrypted files on disk (evidence), static files on disk (packs, 2 to 6 GB of tiles optional), on the phone `directory.db` (rebuildable) and drift `app.db` schema 2.

**Testing**: Vitest with fast-check and Testcontainers; Schemathesis; Playwright with axe; OWASP ZAP; OSV-Scanner, Trivy, gitleaks; vegeta for load; mitmproxy for the emulator capture; Dart tests with shared vectors; manual: device matrix, Operator dry run, restore drill, TalkBack and VoiceOver pass on the console. See "Testing plan".

**Target platform**: one Linux VPS (2 vCPU, 4 GB RAM, 40 GB disk) running Docker Compose; modern evergreen browsers for the console; Android 8+ (API 26) and iOS as in Phase 0.

**Project type**: mobile app plus web service plus static web app plus infrastructure scripts.

**Performance goals**: 50,000 listeners per day on static files (about 337,000 requests and 4 GB per day on average, worst day about 225 GB, prayer-time herd about 120 opens per second in the first minute); static p95 at most 150 ms (304) and 600 ms (packs) during herd windows; admin API p95 at most 500 ms; switching a Masjid schedule updates alerts in under 5 seconds (planning itself takes about 40 ms; storage and notification registration dominate); finding and confirming a Masjid in under 60 seconds.

**Constraints**: constitution principles 1 to 11; cost at most US$10 per month all-in; the server is optional (the app behaves as in Phase 0 with it down); no coordinate finer than a 5 km cell ever leaves the phone; no listener address and region pair is ever stored; every state change audited; RAM budget in research R-19.

**Scale and scope**: pilot 3 to 5 Masjids (about 13 accounts, 2 Operators); directory seeded for 3 to 5 pilot countries (90,000 to 150,000 Masjids, 11,000 to 30,000 cells, about 135 to 360 MB of static files); design headroom to 500 Masjids and about 300,000 directory entries worldwide.

## Constitution Check

*Gate: must pass before the build. Re-checked after the design (below).* Result: **PASS with three amendments to propose** (A1 to A3). No unjustified violation; four items are recorded under Complexity Tracking.

| Principle | How the plan meets it | Status |
|-----------|-----------------------|--------|
| 1 Local-first reliability | Server is optional; `directory_client` has a null-object kill switch; Phase 0 suite runs under a network guard (`off`, `fail`, `hang`) and with airplane mode; stale schedule falls back per day to calculated times; the wrapper changes the planner's inputs only | Pass |
| 2 Platform honesty | Android adds only `INTERNET` (cleartext off, `ACCESS_NETWORK_STATE` stays forbidden); iOS ATS default; background refresh is best effort (iOS `BGAppRefreshTask` only, Android none); each claim cited in r6 | Pass |
| 3 Consent and respect | Listener confirms every Masjid; app shows madhhab, method and Azaan variant; a schedule applies from tomorrow if today's prayer already played; first download needs consent | Pass |
| 4 Privacy by design | Static read path; `data.` has no access log; padded packs; rate-limit keys are salted hashes in Valkey for at most 1 hour; no listener identifier in any table; admin IPs 30 days raw; DPIA; honest disclosure that the host sees the IP | Pass (store labels re-answered) |
| 5 Broadcast security | TOTP, recovery codes, step-up, 48-hour break-glass, Verified-only eligibility, audit chain; signed data deferred to Phase 2 (deferred list) | Pass |
| 6 Audio quality | Not applicable (no audio) | N/A |
| 7 Religious and cultural correctness | Madhhab, method and Azaan variant are first-class overlay fields; Masjid times override calculated times only after confirmation; Jumu'ah shifts; Masjid time zone governs | Pass |
| 8 Testing and quality gates | Contract tests from OpenAPI, generated state-machine and authorization matrices, schedule property tests, privacy capture test, ZAP, load test, restore drill; device matrix re-run with the server blocked | Pass |
| 9 Simplicity and scope | Planning now, build after Phase 0 exit; no microservices, no gRPC; one VPS; pg-boss instead of a queue service; **phase labels differ from the constitution (A1)** | Pass with A1 |
| 10 Open source and zero cost | Every dependency in research.md has a verified OSI license; copyleft only in separate server processes; excluded tools listed; cost table; **Exceptions Register rows needed (A2)** | Pass with A2 |
| 11 Accessibility and localization | Console on React Aria with axe in CI and a manual screen-reader pass; RTL-ready; English at launch, localizable; app strings in four languages | Pass |

### Constitution actions (each a separate `/speckit-constitution` run, not done here)

- **A1 Phase labels (principle 9)**: the constitution lists Phase 1 as "hardened live broadcast" and Phase 2 as "push-triggered wake"; the project's phases are Phase 0 offline app, Phase 1 directory and verification (this plan), Phase 2 broadcast, Phase 3 push wake, Phase 4 console languages and later items. Amend the list. MINOR.
- **A2 Exceptions Register rows**: domain registrar and its bundled DNS; Let's Encrypt (Caddy pinned to it as the only issuer); Docker Hub and GitHub Container Registry (CI-time image reads and our own public images); and, contingent, a transactional email relay with a permanent free tier, adopted only if the mail exit test fails. Drafts are in research.md R-10 and in the r3 and r1 reports. MINOR (1.3.0).
- **A3 Technology Constraints wording**: "PostGIS ... 5 km radius search" implies server-side location queries; here PostGIS builds the directory, computes geohash cells and serves the console, and the phone does the radius search. Reword.
- **Phase 0 documents to revise** (tasks, not amendments): spec 001 line 9, FR-001 and FR-002 (add the explicit, consented exception), SC-007, plan 001 summary, technical context and checks 1 and 4, `content/privacy/privacy-policy.md` in four languages, README, CONTRIBUTING, the pull-request template, the manifest comment, `store-notes.md` sections 1 to 3, research R-A7 and R-I7, About and setup strings (`about.json`, `setup.json`, `settings_data.json`).

### Re-check after design

All table rows stay Pass. New findings from design: break-glass needs committee contacts that FR-032 deletes after 90 days (resolved in owner decision O7); FR-016 mixes two status sets (two machines modelled); spec wording to amend after the owner confirms: FR-004 (add Muazzin), FR-016, FR-026, FR-027.

## Project Structure

### Documentation (this feature)

```text
specs/002-masjid-directory-verification/
├── spec.md
├── plan.md                      # this file
├── research.md                  # decisions with rationale, licenses, alternatives
├── data-model.md                # tables, layers, retention, access, audit, migrations
├── quickstart.md                # runnable validation scenarios
├── contracts/
│   ├── openapi.yaml             # admin, Operator and public API (single source)
│   ├── examples/*.json
│   ├── authz-matrix.md          # generated role x operation matrix + never-list
│   ├── state-machines.md        # 12 machines, 653 state/event pairs, audit actions
│   ├── static-files.md          # manifest, base, overlay, sched, country, g4, dumps
│   ├── schedule-rules.md        # masjid-schedule/1, DST rules, issue codes, vectors
│   └── directory-client.md      # the app's only network code, egress policy, privacy test
├── ops/
│   ├── operator-runbook.md      # FR-028 Operator onboarding (draft)
│   ├── dpia.md                  # data protection impact assessment (draft, needs review)
│   └── restore-runbook.md       # timed restore (draft, proven by the drill)
├── checklists/requirements.md
└── tasks.md                     # created later by /speckit-tasks
```

### Source code (repository root)

```text
services/
├── api/                         # Fastify API and pg-boss worker, one image, two entrypoints
│   ├── src/{routes,auth,session,audit,evidence,transcode,jobs,packs,mail,db,config}/
│   ├── migrations/              # NNNN_name.sql, forward-only (order in data-model.md section 14)
│   └── test/{unit,integration,contract,authz,mfa}/
└── domain/                      # shared TypeScript: claim-transitions.ts, authz-policy.ts, generated API types
apps/
├── mobile/                      # existing; adds lib/{domain,data,ui}/directory, drift schema 2, l10n masjid.json
└── operator-console/            # Vite + React static SPA
packages/
├── masjid_schedule/             # NEW pure Dart: rules, validation, day expansion; also compiled to JS
├── directory_client/            # NEW Dart: the only network code in the app, EgressPolicy
├── prayer_engine/               # existing; LocalClock and name normalizer move or are exported here
└── schedule_planner/            # existing; gains masjidChanged trigger, quiet-hours zone, renewal cap
tools/
├── license_scan/                # existing; check_network rewrite, scan_server.dart, check_ci_tools.dart
└── directory-pack/              # open importer, SQL and the dump method (ODbL offer of method)
infra/                           # bootstrap.sh, compose/, caddy/, secrets/ (SOPS), runbooks/, Makefile
content/register/                # + server-deps.md, server-tools.md, server-images.md
scripts/                         # + pack-check, load/, dr/smoke.sh
.github/workflows/               # + ci-server.yml, nightly.yml; ci.yml gets paths-ignore for server paths
pnpm-workspace.yaml              # lists services/* and apps/operator-console only
```

**Structure decision**: the owner's layout is kept (`services/api`, `apps/operator-console`, `infra/`). A single root `pnpm-workspace.yaml` covers the Node packages; the root `pubspec.yaml` names its Dart members explicitly so the two workspaces never see each other.

## Architecture

```text
 Phone (Flutter, Phase 0 intact)                         Console users (browser)
   directory_client (only network code)                         |
   directory.db (FTS5)   app.db (drift v2)                      | HTTPS, cookie session
        |  GET static, conditional, no cookies                  v
        v                                              +------------------+
 data.<domain>  ---------------------------------->    |   Caddy (TLS)    |
   /v1/manifest, base, overlay, sched, country, g4,     |  data.  api.  console. |
   redirects, dumps   (static files, no access log)     +--+------+-----+--+
 api.<domain>/v1/public/*  (suggestions, abuse, pow) -------+      |     |
 console.<domain> (SPA files, /v1/* admin API, /tiles/) -----------+     |
                                                                         v
                          +----------------------------------------------+
                          | api container (Fastify)   worker (pg-boss)   |
                          |  auth, claims, schedules, evidence, audit    |
                          |  Dart->JS masjid_schedule (validate/preview) |
                          +-----+---------------+--------------+---------+
                                v               v              v
                           PostgreSQL+PostGIS   Valkey      evidence/ (encrypted files)
                                 |
              pack build job (nightly + on change) writes static files atomically to disk
   Host: Postfix+OpenDKIM (outbound mail), restic timer -> team machine, node_exporter, WireGuard
   Team machine: Uptime Kuma, restic repository (pull model), optional Prometheus
```

Read path: manifest check (at most every 12 hours) leads to conditional requests for the cells the phone holds; near me is a fixed 3 by 3 block computed on the phone; the server learns a centre cell and an IP address, never a point (honest disclosure on the consent screen). Write path: admins and Operators only, plus two public listener POSTs on a separate host with proof of work. Details: research.md (R-01 to R-31), contracts/.

## Dependencies and licenses

The full tables are at the end of research.md sections 1 to 8 and become `content/register/server-deps.md` (name, version, license, production or development, maintainer health, alternatives) on the first pull request, as principle 10 requires. Summary of license classes: permissive (MIT, MIT-0, BSD-2 and BSD-3, Apache-2.0, ISC, MPL-2.0 for build and test tools) for everything in the Node tree, the console bundle and the Dart packages; copyleft only for separately run server-side processes (PostGIS, Grafana, Loki, osmium-tool, osm2pgsql, `vips` and `pdftoppm` command-line tools run in a sandbox). Excluded by license or policy: `sharp` (LGPL libvips in-process), MUI X Pro, Drizzle runtime (not chosen, Apache-2.0), k6, trufflehog, hadolint, Semgrep, CodeQL, `gitleaks-action`, MinIO, ClamAV (memory), OpenFreeMap, Mapbox, Google services, Dependabot (needs an Exceptions row; Renovate is AGPL: version bumps are manual or by a run-unmodified CLI).

## Server changes (summary; detail in data-model.md and contracts/)

1. API with 129 operations (126 on the console host, 3 on the api host; each role or step-up difference needs its own policy row), OpenAPI-first, routes created from `operationId`, request and response validation by Ajv, `removeAdditional: false`, problem+json errors, 404 for another Masjid's resource and a missing one with the same body.
2. Authentication in-house (research R-08, R-09); sessions in Valkey with a `session_epoch` in PostgreSQL; step-up; recovery machines (password reset, second-factor reset with a consumed recovery code, break-glass with a call, a second Operator and a 48-hour delay).
3. Claim and listing state machines from one transition table (`services/domain/claim-transitions.ts`), enforced again by a database trigger; 266 claim pairs and 653 pairs over 12 machines tested.
4. Evidence: upload to a sandboxed transcoder, AES-256-GCM per file, wrapped keys, assigned-Operator-only fail-closed access with audit, 90-day crypto-shred sweeper, appeal hold.
5. Audit: triggers plus `audit_event()`, hash chain with a daily off-server anchor, anonymisation by deleting `actor_map`.
6. Jobs (pg-boss): pack build (singleton per cell, atomic rename, never touch unchanged files), expiry and reminders, evidence sweeper, break-glass notices, mail outbox, OSM import, duplicate detection, privacy-request reminders.
7. Directory seeding with Geofabrik, osmium and osm2pgsql into a staging schema; Operator approval before publication; open ODbL dump published per generation.
8. Console: review queue, evidence viewer (images only), search, abuse and suggestion queues, duplicate merges, import review, schedule editor with a 14-day preview and validation from the compiled Dart code, audit and privacy-request screens, English at launch.

## Client changes (summary; detail in contracts/directory-client.md and research R-07, R-28 to R-30)

1. `packages/directory_client`: typed calls, `EgressPolicy`, consent object, kill switch, update cadence, atomic multi-part commits.
2. `packages/masjid_schedule`: rules model, validation, expansion; shared golden vectors; compiled to JS in CI.
3. `MasjidScheduleEngine` wraps `PrayerTimeEngine` (the single seam for the UI and the planner); effective location and Masjid time zone for date naming; quiet hours stay in the phone's zone; `RebuildTrigger.masjidChanged`; fingerprint includes source, schedule version and sync day; renewal alert capped before `expiresAt`.
4. Local storage: separate rebuildable `directory.db` (masjid table, `cell_state`, FTS5 over normalised text, optional trigram); drift `app.db` schema 1 to 2 (`masjid_follow`, `masjid_schedule_cache`, `directory_state`, `masjid_notice`, two settings columns) with a migration test; delete-all covers the new files.
5. UI: "Masjids" entry, consent screen (near me, area, whole country, manual), search with badges, confirm screen (what will change, "applies from tomorrow"), follow list with one "my Masjid", status-change banner, time-zone banner, Reliability page row, attribution footer; strings in four languages with right-to-left goldens.
6. Product defaults taken where the spec is silent (owner decision O6): the Friday alert follows the first Jumu'ah shift, or the shift the listener picks per follow; Iqamah times are display-only in Phase 1 (an Iqamah alert kind would need native changes).
7. No map in the app in Phase 1.

## Infrastructure and cost

Single VPS, Docker Compose with profiles `core`, `observe`, `full` and a numeric RAM rule; see research R-18 to R-23 for provider facts, the port-25 gate, the RAM budget, Caddy configuration, backups and hardening. Baseline cost about **US$5.28 per month** ($6.14 with 19 to 20% VAT on the EUR items) against the US$10 ceiling; adding a paid backup box (Storage Box) gives $8.87, or $10.41 with VAT, so the default second copy is a team machine. Review monthly; warn above $8.00, act above $9.50. **Second node** (a static-only edge, about $4 per month, needs a budget decision) when: peak above 1,000 requests per second sustained at a prayer window, egress above 150 Mbit/s for 5 minutes, host CPU p95 above 60%, monthly egress above 5 TB, or manifest p95 above 300 ms.

## Testing plan

| Area | What | Tool | Runs |
|------|------|------|------|
| Contract | every operation against the OpenAPI file; examples and responses validate; negative testing | Vitest + Ajv in unit; Schemathesis (50 examples per PR, 500 nightly) | PR, nightly |
| Claim state machine | every state and event pair; illegal returns 409, state unchanged, zero audit rows; model-based random sequences; database trigger test | generated from one table | PR |
| Authorization | role × operation × ownership matrix plus an independent never-list; IDOR returns identical responses for another Masjid and a missing one | in-process inject | PR |
| MFA enforcement | each session state × every protected route; TOTP vectors, replay, lockout; break-glass with a fake clock | Vitest, Playwright | PR |
| Schedule rules | DST gaps and overlaps, zone rule changes (Cairo, Casablanca, Amman, Istanbul, Apia, Lord Howe, Chatham), 30 and 45 minute offsets, southern hemisphere, host `TZ` variants, 30 consecutive local dates | fast-check, golden vectors replayed by `dart test` and `node --test` | PR (200 runs), nightly (20,000) |
| Evidence | stored bytes differ from plaintext; key not in DB or backup; assigned-Operator only; every view audited fail-closed; 90-day purge with a fake clock; appeal hold; upload abuse corpus (polyglot, zip bomb, huge pixels, `../`, EICAR) | integration | PR |
| Audit | every state-changing route writes an audit row with actor and time in the same transaction; app role cannot update or delete; chain verifies | integration | PR, DR |
| Privacy (SC-004) | egress allow-list unit tests; loopback fake-server integration with a same-cell metamorphic property and a device-state differential property; 20,000-input fuzz; canary that must fail; mitmproxy capture of the real debug build with a DNS log, HAR archived | Dart, mitmproxy | PR; nightly and release |
| Phase 0 regression (SC-003) | whole Phase 0 suite under `DEEN_TEST_NET=off|fail|hang`; identity test for the wrapper over 14 methods × 20 cities × 366 days; plan equals Phase 0 plan byte for byte when the source is calculated; instrumented suite in airplane mode | `flutter test`, androidTest | PR, release |
| Security | ZAP API scan from the OpenAPI file and baseline on the console (PR), active scan nightly on staging only; OSV-Scanner, Trivy (binary), gitleaks; ASVS 5.0 L2 checklist file whose test ids a script verifies; external review of the auth module before Phase 2 | ZAP, OSV, Trivy, gitleaks | PR, nightly, manual |
| Accessibility | axe on every route and state; keyboard-only flows; pseudo-locale long strings; `dir=rtl`; manual TalkBack and VoiceOver pass | Playwright, manual | PR, release |
| Load (SC-005) | S1 steady 30 min; S2 five 10-minute prayer-herd windows (about 41 requests per second at peak); S3 600 requests per second for 120 s with 25% new TLS connections; thresholds: static p95 at most 150 ms (304) and packs 600 ms, errors under 0.05%, S3 packs p95 at most 1.5 s, CPU under 60% (S2) and 90% (S3), RAM under 70%, no swap-in, no OOM kill | vegeta from a protected Actions environment | before launch and after infra change |
| Restore (SC-006) | timed drill on a real second VPS, target 2 h 45 min, limit 4 h, two signatures | `ops/restore-runbook.md` | before launch, yearly |
| Operator dry run (SC-002, SC-008) | 2 Operators and 3 mock Masjids (claim, conflict and appeal, break-glass with the 48-hour delay run once for real, privacy export, deletion), evidence CSV | `ops/operator-runbook.md` | before launch |
| Email exit test | 40 seed messages, 14 days (research R-10) | manual | pilot |
| Device matrix | Phase 0 matrix and 7-day soak re-run with the server blocked; schedule switch under 5 seconds on Pixel, Samsung, Xiaomi, iPhone | manual | release |

Licenses of every test tool are in research.md R-24; all dev-time; no copyleft tool that the constitution does not allow.

## Phase 1 exit criteria (gate for Phase 2)

1. SC-001 to SC-008 each have recorded evidence (test run, drill record, dry-run CSV, HAR).
2. Operator dry run passed: from documents alone, no blocking defect, 100% audit coverage, median effort per claim at most 30 minutes.
3. Restore drill within 4 hours with two signatures; audit chain intact after restore.
4. Mail exit test passed, or the relay row was adopted by amendment.
5. Load test thresholds met on the real VPS; monthly cost report under the ceiling.
6. Privacy test green on every pull request and the release HAR archived; store privacy labels and the privacy policy (four languages) updated.
7. ASVS 5.0 L2 checklist complete; every deviation (ClamAV, others) recorded; external review of the auth module done.
8. DPIA reviewed by a lawyer or data-protection adviser; ODbL licensing questions answered; privacy notices published.
9. Phase 0 device matrix and soak re-run with the server blocked.
10. Pilot live with 3 to 5 Masjids for 14 days with no Sev-1 incident.

## Owner decisions needed (defaults in bold take effect unless changed)

| # | Decision | Default taken in this plan |
|---|----------|----------------------------|
| O1 | Which VPS to buy (Hetzner is not orderable now; OVH VPS-1 monthly price and port-25 policy unverified); VAT status | Order only after the day-0 port-25 and reverse-DNS test; **OVH VPS-1 primary, Contabo fallback** |
| O2 | A named person with an always-on machine for the second backup copy and Uptime Kuma, and a second key holder | **Team machine, pull-model restic**; Storage Box only if margin allows |
| O3 | Domain name and registrar | Placeholder `<DOMAIN>` until chosen |
| O4 | New-Masjid suggestions without coordinates (SC-004 forbids finer than a cell) | **Cell id + country + free-text name and address; an Operator places the pin** |
| O5 | Keep an HMAC fingerprint of rejected evidence for 12 months so identical resubmission stays rejected | **Yes, 12 months**; lawyer review |
| O6 | Jumu'ah shift driving the Friday alert; Iqamah alerts | **First shift, per-follow choice; Iqamah display-only** |
| O7 | Break-glass needs a committee contact, but contacts are deleted 90 days after a decision | **Operator adds fresh contacts to the case, verified through an independent public number; contacts deleted with the case** (no spec change) |
| O8 | Overlay status for Suspended and Revoked | **Add `st = S`** so the app can say the status changed |
| O9 | Admin edits of name, address and location enter the ODbL base layer only after the admin accepts ODbL-compatible terms | **Yes**; licensing review |
| O10 | Appeal window and "Needs more information" timeout | **30 days each** (so evidence still exists at appeal) |
| O11 | Console map from self-hosted tiles (1 to 2 GB) | **Yes; coordinate picker if the disk is short** |
| O12 | Evidence shown as sanitised images only (PDFs rasterised) | **Yes** |
| O13 | Pre-approve the contingent mail-relay Exceptions row, used only on a failed exit test | **Yes, contingent** |
| O14 | Spec wording: FR-004 add Muazzin; FR-016 split into claim and listing status; FR-026 recovery code or break-glass; FR-027 no address in any listener-facing log | **Apply after confirmation** |
| O15 | Operator roles: both founders hold super-admin; break-glass initiator is a super-admin, approver a different Operator at reviewer or above | **As stated** |
| O16 | A manifest response that confirms the held `overlay.gen` counts as a successful sync, so an unchanged schedule does not expire after 30 days | **Yes** |

## Before the build starts (allowed under principle 9)

Paperwork and decisions only: answer O1 to O16; run the licensing review (ODbL questions in research R-27) and the DPIA review; amend the constitution (A1 to A3); recruit the second Operator; day-0 provider test (port 25, reverse DNS); choose the domain; verify unverified prices and ASVS items marked UNVERIFIED in the reports; run the planet filter once to count cells (Week-1 task). No feature code, no repository changes outside `specs/` and the constitution.

## Deferred to Phase 2 (recorded so they are not forgotten)

Signed data files with an offline key (before broadcast rights exist); Operator-held evidence keys (Phase 1.5 option); hardware security keys; Firebase per-Masjid topics reveal the Masjid to Google (push design); an in-app map with offline tiles (Phase 3 or later); Iqamah alerts (native change); a second console language (Phase 4); listener accounts (out of scope).

## Risks

| Risk | Mitigation |
|------|------------|
| Mail from a new VPS address lands in spam or port 25 is closed | Day-0 gate, 14-day exit test, contingent relay row, reset flows never depend on one mailbox |
| A $5 server is too small once Prometheus and Grafana run | Profiles with numeric rules and automatic demotion steps; second-node triggers |
| Dart-to-JavaScript build is a second toolchain | One pinned Dart SDK (already in CI), golden vectors that a TypeScript port could use |
| In-house authentication has our own bugs | Contract test per ASVS item, generated matrices, external review before Phase 2, Kratos as the documented fallback |
| pg-boss and Mox-class single-maintainer projects stall | Timers are database columns and jobs are idempotent; Postfix chosen over Mox |
| Licensing of base and overlay layers is judged differently by a lawyer | Layers are separate files, so merging them into one ODbL release is a configuration change |
| Hetzner-style capacity or price shocks | Fallback migration trigger at a 25% price rise or an unavailable plan; script-based restore |
| Evidence backup rule means lost files after a disaster | Documented "request re-upload" path; contacts re-collected under O7 |

## Complexity Tracking

| Item | Why needed | Simpler alternative rejected because |
|------|------------|--------------------------------------|
| Valkey as a fifth service | Sessions with instant revocation, TOTP replay marks and rate-limit counters kept off PostgreSQL; the constitution and the owner list it; Phase 2 needs it for broadcast state | PostgreSQL could do all three (kept as a fallback behind interfaces); Valkey costs 15 to 64 MB |
| Dart compiled to JavaScript | One rule-expansion implementation in the app, the server and the console preview; proven identical on 13,664 day rows | A TypeScript port needs the Phase 0 oracle work again and cannot prevent drift |
| Sandboxed transcoder (libvips and poppler tools) | Evidence must be re-encoded and rasterised without in-process LGPL code or an unaffordable antivirus | Storing originals or using `sharp` breaks principle 10 or the threat model |
| Separate static host, public API host and console host | Different logging, cookie and exposure rules (FR-027, FR-003) | One host mixes logging policies and exposes admin routes on the listener path |
