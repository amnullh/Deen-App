# Quickstart and Validation Guide: Phase 1

**Plan**: [plan.md](plan.md) | **Contracts**: [contracts/](contracts/) | **Date**: 2026-10-22

This guide proves Phase 1 works end to end. It is a validation guide, not a build guide: the commands below are the ones the tasks will create (marked *planned*). Nothing here can run until Phase 0 meets its exit criteria and the build starts (constitution principle 9). Each scenario names the success criterion it proves and the evidence to keep.

## 0. Prerequisites

| Need | Version | Used for |
|------|---------|----------|
| Node.js, pnpm | 26 LTS (also 24), pnpm 12 | API, console, contract tests |
| Docker with Compose | current stable | PostgreSQL + PostGIS 18, Valkey, Caddy, Postfix test relay |
| Flutter and Dart | 3.47.x and 3.13.x (pinned by Phase 0 CI) | app, `masjid_schedule`, `directory_client`, dart2js build |
| Android emulator and a physical phone per Phase 0 matrix; an iPhone | as Phase 0 | alert and device scenarios |
| Playwright (Chromium), mitmproxy, vegeta, OWASP ZAP image, Schemathesis | versions in research.md R-24 | security, privacy, load, contract |
| A staging VPS (or local VM) with port 25 open | the chosen plan | load, mail and restore scenarios |
| Two Operators, two testers with their own phones | n/a | dry run |

Setup (*planned*): `scripts/setup.sh` (existing, extended), then `pnpm install --frozen-lockfile` at the repository root and `make -C infra dev-up` (compose profile `core` with fixtures). Environment names and secrets come from `infra/secrets/*.sops.yaml`; never commit plaintext.

## 1. Fast gates (every pull request)

| Step | Command (*planned*) | Pass |
|------|---------------------|------|
| Lint and types | `pnpm -r lint && pnpm -r typecheck`; `redocly lint specs/002-masjid-directory-verification/contracts/openapi.yaml` | no errors |
| Unit, property, matrices | `pnpm --filter api test` (state-machine pairs, authorization matrix, MFA matrix, rate limits, audit coverage) | all green; illegal transitions return 409 with zero audit rows |
| Schedule vectors | `dart test packages/masjid_schedule` and `node --test packages/masjid_schedule/build/js` | identical outputs in Dart and JavaScript; zero differences |
| Contract | `schemathesis run --max-examples 50 contracts/openapi.yaml --url http://localhost:3000` | no 5xx, schemas conform |
| Licenses and supply chain | `dart run tools/license_scan/bin/scan_server.dart`; `check_ci_tools.dart`; OSV-Scanner; Trivy; gitleaks | no disallowed, unknown or copyleft-in-runtime license; every Action pinned by SHA |
| Packs | `scripts/pack-check build/packs` on a generated 300,000-Masjid tree | sizes under 500,000 bytes, parts consistent, no field outside the allow-list, licence header present |
| App tests | `flutter test --exclude-tags golden` under `DEEN_TEST_NET=off`, then `fail`, then `hang` | Phase 0 suite passes unchanged; no request made by a test that did not opt in |

## 2. Scenario A: find and confirm a Masjid (US1; SC-001, SC-004, SC-003)

1. Install the debug build on the emulator with `DEEN_DIRECTORY_BASE_URL` pointing at the local `data.` host. Start mitmproxy and the DNS log.
2. Open Masjids, read the consent text, choose *Download this area*, then switch the network off.
3. Choose near me, search a Masjid by name (also an Arabic name with and without diacritics), open it, check the badge, madhhab, method and Azaan variant, confirm it, follow a second Masjid, mark one as "my Masjid", remove the other.
4. Time the run from tapping Masjids to the confirmation (a stopwatch or the integration test timer).

**Expected**: results come from the phone with the network off; the app never selects a Masjid on its own; the confirm screen says what will change. **Pass**: under 60 seconds (SC-001); the HAR shows only paths matching the egress grammar, empty query strings, the fixed header set, and requests for the nine cells around one cell (SC-004); two coordinates inside one cell give byte-identical request sets. **Evidence**: HAR archived with the build id, stopwatch log.

## 3. Scenario B: Masjid schedule replaces calculated times (US2; SC-007, FR-015)

1. Confirm a Verified test Masjid whose rules differ from the calculated times (fixed Fajr, Dhuhr calculated plus 3 minutes, Iqamah after Azaan, two Jumu'ah shifts, a time zone different from the phone's).
2. Switch to the Masjid schedule; time the interval until the next-alert list and the registered alarms show the new times (Android: `adb shell dumpsys alarm`; iOS: the notification list).
3. Switch back to calculated times; repeat with a prayer that already played today ("applies from tomorrow" shown).
4. Move the fake clock 31 days after the last sync with the server blocked.

**Pass**: under 5 seconds on each device of the matrix; no duplicate alerts (one per kind and date); the time-zone banner appears; after 31 days the app shows calculated times and says so; a manifest that confirms the held generation extends the 30 days (O16).

## 4. Scenario C: server offline changes nothing (FR-001, SC-003)

Run the Phase 0 integration and instrumented suites with the server returning HTTP 500, timing out, and with airplane mode on; run one build with an empty `DEEN_DIRECTORY_BASE_URL`. **Pass**: 100% of Phase 0 tests pass; the planned alert JSON equals the Phase 0 plan byte for byte when the source is calculated; the Phase 0 7-day soak and device matrix re-run with the server blocked.

## 5. Scenario D: claim to Verified (US3; SC-008, FR-004, FR-016)

1. Sign up as an admin, set a password, try to open the Masjid editor before enrolling an authenticator (must be refused), enrol TOTP, store recovery codes.
2. Claim a seeded Unclaimed Masjid, upload three images and a PDF, add two committee contacts, submit.
3. As Operator 1 take the case, view evidence (step-up prompt, audit row written before the image streams), phone the test committee contact, record the outcome, decide *Verified* with a reason.
4. Check the listener view: the overlay shows the badge; the schedule bundle contains the Masjid after the next build (or trigger the `packs` job).
5. Read the audit log as the admin and as an Operator.

**Pass**: no protected screen or endpoint is reachable without a verified second factor (0 exceptions across the session-state matrix); every state change has an audit row with actor and time (100%); only the assigned Operator sees contacts; evidence on disk differs from the uploaded bytes and no key is in the database dump.

## 6. Scenario E: conflicts, appeal, rejection stays rejected (FR-016, FR-018)

Two admins claim the same Masjid; both lose edit rights; an Operator arbitrates; the loser is rejected, resubmits identical evidence and is rejected again (fingerprint match); the loser appeals once and a second appeal is refused with 409. **Pass**: transition table honoured, audit complete, fingerprint kept 12 months and nothing else.

## 7. Scenario F: recovery and break-glass (FR-026)

1. Password reset: request, receive the email, complete with the authenticator code (reset never bypasses MFA); old sessions end.
2. Lost authenticator with a recovery code: Operator approves; new enrolment; notification emails.
3. Lost authenticator and codes: super-admin initiates break-glass, calls a contact added to the case, a different Operator approves, notifications go out to the admin and the contacts with a cancel link; the fake clock moves 24 h (reminder) then 48 h (execution); all old sessions are dead. Run the delay once in real time during the dry run.

**Pass**: approver differs from initiator (database check), execution only after `not_before`, cancellation works, every step audited.

## 8. Scenario G: evidence lifecycle and deletion (FR-008, FR-032)

With a fake clock: final decision, +89 days (evidence present), +91 days (sweeper crypto-shreds: `wrapped_dek` null, blob gone, contacts gone, `evidence.purged` audit row, `evidence_past_due` metric 0); appeal hold pauses the purge; an early-deletion request purges at once. Restore a database dump older than the purge and re-run the sweeper. **Pass**: no readable evidence remains beyond 90 days plus one retention cycle; the privacy notice wording matches.

## 9. Scenario H: directory seeding and attribution (US6; FR-022, FR-023, FR-031)

Import one small country (Geofabrik extract, `osmium`, `osm2pgsql`), approve the staging diff, run duplicate detection and merge one pair, accept one suggestion, publish a generation. **Pass**: imported Masjids are Unclaimed and labelled unverified; the open dump equals the base files; attribution footer visible in the app and console; no phone, email, website or operator tag in any published file (`pack-check` poisoned fixture fails as expected).

## 10. Scenario I: load and cost (SC-005)

Run vegeta S1, S2 and S3 from the protected Actions environment against the staging server (never production before launch day, never ZAP active scan against production). **Pass**: thresholds in plan.md (static p95 at most 150 ms for 304 and 600 ms for packs, errors under 0.05%, CPU under 60% in S2, RAM under 70%, no swap-in, no OOM kill); monthly cost report at most US$8.00 projected, hard ceiling US$10.

## 11. Scenario J: restore drill (SC-006)

Follow `ops/restore-runbook.md` with a timekeeper who is not the executor, on a fresh VPS. **Pass**: complete within 4 hours (target 2 h 45 min), data loss within the 6-hour RPO, audit chain intact, evidence handled by the "request re-upload" path, two signatures on the drill record.

## 12. Scenario K: Operator dry run (SC-002, SC-008, FR-021, FR-028)

Follow `ops/operator-runbook.md` with two Operators and three mock Masjids (Al-Noor to Verified with a schedule edit and rollback; Dar-us-Salam with conflict, appeal and identical resubmission; Masjid Taqwa with needs-information, suspension, abuse report, break-glass, privacy export and account deletion). **Pass**: every step done from the documents alone, no blocking defect, audit rows equal the expected action list, median effort per claim at most 30 minutes, SLA report shows working-day decision times, evidence CSV completed.

## 13. Scenario L: email exit test (R-10)

From the staging mail host send 10 messages each to Gmail, Outlook.com, Yahoo and iCloud seed inboxes over 7 days. **Pass**: all `spf=pass dkim=pass dmarc=pass`, at least 38 of 40 in the inbox, no hard bounce, reset email P95 under 60 seconds, the address on no major blocklist. Failure after one remediation round switches to the relay under the contingent Exceptions Register row.

## 14. Scenario M: security and accessibility sweep

ZAP API scan (PR) and active scan (nightly, staging), the console CSP smoke test (zero violations, hash drift check), axe on every route in English and `dir=rtl`, keyboard-only walk of the claim review, a manual TalkBack and VoiceOver pass, the ASVS 5.0 Level 2 checklist script (every covered row names a test that exists). **Pass**: no medium or higher finding without a recorded exception; zero axe violations; checklist complete; deviations (ClamAV) recorded.

## 15. Evidence and sign-off

Keep under `specs/002-masjid-directory-verification/evidence/` (created at the first run): HAR files, stopwatch and device logs, drill record, dry-run CSV, load reports, mail headers, ASVS checklist, cost report. Phase 1 exits when the ten criteria in plan.md are met and two Operators sign.
