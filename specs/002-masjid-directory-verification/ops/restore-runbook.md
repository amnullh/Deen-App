# Restore Runbook: Full Server Loss (Phase 1)

**Status**: DRAFT 0.1, 2026-10-22. **Owner**: `<ENGINEERING_LEAD>`. **Proves**: SC-006 (recovery from a full server loss in under 4 hours, practised once before the phase closes). **Spec**: [../spec.md](../spec.md). **Decisions**: [../research.md](../research.md) (R-19, R-22, R-23).

> **Needs validation.** This runbook has never been run. It is proven by the **timed restore drill** (section 14), run on a real second server that then becomes production. Every command below is a placeholder written from the research, because `infra/` does not exist yet (Phase 1 is in planning; building starts when Phase 0 exits, constitution principle 9). Replace each placeholder with the real command when `infra/bootstrap.sh`, the compose file and the backup scripts exist, and correct this document during the drill. When `infra/` exists, copy this file to `infra/runbooks/restore.md`.

**Targets**: hard limit **4 hours**; planned time **2 hours 45 minutes**. Data-loss limit (RPO): **6 hours** (database dump every 6 hours).

Marks: UNVERIFIED = fact not confirmed; PROPOSED = a working rule from this draft; `<PLACEHOLDER>` = not decided.

## Fill in before use

| Placeholder | What it is | Value | Decided by |
|-------------|-----------|-------|------------|
| `<DOMAIN>` | Project domain. Hosts: `data.<DOMAIN>`, `api.<DOMAIN>`, `console.<DOMAIN>` | not decided | Owner |
| `<VPS_PROVIDER>` | Server host. Research: OVHcloud VPS-1 primary candidate, Contabo Cloud VPS 4 fallback. Not purchased | not decided | Owner |
| `<FALLBACK_PROVIDER>` | The provider to use if the first cannot supply a server within the time | not decided | Owner |
| `<SERVER_IP4>`, `<SERVER_IP6>` | Addresses of the new server | at restore time | Executor |
| `<REPO_URL>` | The code repository (for `git clone`) | not decided | Owner |
| `<KEY_HOLDER_1>`, `<KEY_HOLDER_2>` | The two people who each hold the `age` key and the backup repository password | not decided | Owner |
| `<ESCROW_LOCATION>` | Where the offline sealed copy of the keys is kept (a safe, a bank box) and who can open it | not decided | Owner |
| `<TEAM_MACHINE>` | The always-on team machine that holds the second backup copy; its WireGuard address and who administers it | not decided | Owner |
| `<RESTIC_REPO>` | Location of the backup repository on `<TEAM_MACHINE>` | not decided | Engineering |
| `<SECRETS_FILE>` | The encrypted secrets file in the repository (planned: `infra/secrets/*.sops.yaml`) | not decided | Engineering |
| `<REGISTRAR>` | Where DNS is edited, and who has the login | not decided | Owner |
| `<MAIL_ROUTE>` | Self-hosted mail on the server, or a relay (affects the mail DNS records) | not decided | Owner |
| `<EXECUTOR>`, `<TIMEKEEPER>` | Who runs the drill and who keeps time. Different people; the executor is not the author of this runbook | per drill | Owner |
| `<STATUS_NOTE_URL>` | Where an outage note is posted for admins (no listener channel exists) | not decided | Owner |
| `<OPERATOR_LEAD>` | The person who decides communications and escalation | not decided | Owner |
| `<BACKUP_CONTENTS_LIST>` | Exact list of what each backup contains. The research says: database dump and globals, plus the Caddy data directory if backed up. It must be fixed in `infra/` and compared with step 5 | not decided | Engineering |

---

## 1. When this runbook applies

Use it when the production server is gone or unusable and cannot be repaired quickly: the provider lost it, the disk is destroyed, the server is compromised and must be replaced, or the provider account is lost.

**What users feel**: listeners keep working. The app works offline; downloaded Masjid data and cached schedules stay on phones for up to 30 days (FR-001, FR-012, FR-014). Only admins and Operators are affected: no console, no new claims, no sign-in, no mail.

Do not start this runbook for a short outage. First check: provider status, the server console, reboot. Decide within 30 minutes (PROPOSED).

If the cause is a **compromise**, also follow the key rotation in section 11 and the incident process (operator runbook, section 18). Do not re-use the old server.

## 2. Roles

| Role | Does |
|------|------|
| Incident lead | Declares the drill or disaster, decides communication, owns the clock |
| Executor | Types the commands. Uses only this document |
| Timekeeper | Not the executor. Writes the wall-clock time at each step in the drill record |
| Key holder 1 and 2 | Provide the `age` key and the backup password. At least one must be reachable at T+0 |
| Operator lead | Writes the messages to admins (section 12) |

At least two people are needed. For a real disaster with a single person available, it still works but slower; a real disaster does not need a timekeeper but should still record times.

## 3. Prerequisites (check these every quarter, and before the drill)

### 3.1 Keys and passwords

| Item | Who holds it | Where | Check |
|------|--------------|-------|-------|
| The `age` private key that opens the secrets file | `<KEY_HOLDER_1>` and `<KEY_HOLDER_2>`, each with their own key; the server also has its own key | Each person's own secure storage; offline sealed copy at `<ESCROW_LOCATION>` | Each holder can decrypt the secrets file today (`sops -d` test as in step 4 of section 4, without printing the output) |
| The backup repository password (restic) | `<KEY_HOLDER_1>` and `<KEY_HOLDER_2>` | Their password managers; offline sealed copy at `<ESCROW_LOCATION>` | Each holder can list the repository today |
| Secrets file `<SECRETS_FILE>` | In the code repository, encrypted to the two holders' keys and the server's key | Repository on GitHub, plus clones | `git clone` works from a clean laptop |
| Server SSH key for the new server | The executor | Executor's own key | Ready |
| Registrar and DNS login | `<REGISTRAR>` account holder | | The login works and is **not** locked in the lost server's mail |
| VPS provider account and payment method | Owner | | Account can order a server |
| Provider API or panel access | Owner | | Works |
| Uptime monitor access | Team machine owner | | Works |

Rule: **losing the server must never mean losing the keys.** The keys are not on the server alone. One holder's laptop being lost must not block recovery: the other holder and the escrow copy are the cover. If both holders and the escrow are gone, the encrypted backups and the secrets file are unreadable. That is the single point of failure; check it every quarter.

### 3.2 Backup location

- The second copy lives on `<TEAM_MACHINE>`, an always-on machine of a team member, reached over WireGuard. It is a **pull-model** copy: the machine fetches data from the server and holds the repository, so a hacked server cannot delete history (research R-22).
- The restore reads from `<RESTIC_REPO>` on that machine.
- Check: the machine is on, has free disk, its clock is right, and the last backup is less than 6 hours old (appendix A.4).
- If `<TEAM_MACHINE>` is also lost, the encrypted history is lost. The provider's own daily backup, if any, is the same account and is not counted as an off-site copy.

### 3.3 DNS

- Set the **TTL to 300 seconds (5 minutes)** for the A and AAAA records of `data.<DOMAIN>`, `api.<DOMAIN>` and `console.<DOMAIN>`, **well before** any disaster (24 hours before a planned drill). A long TTL turns a 5-minute switch into hours.
- Know where the mail records live: SPF (names the sending address), DKIM key records, DMARC, and the reverse DNS (PTR) which is set in the **provider's** panel, not in DNS (research R-10). These all change when the address changes.
- Check: `dig +short <name> A` shows the right value; `dig <name>` shows TTL 300.

### 3.4 The secrets file

The secrets file holds the key that wraps evidence keys, the key for the stored authenticator secrets, the pepper for audit and fingerprint keys, and mail and database passwords. It is decrypted into memory-only storage on the new server; plaintext must never be written to disk or printed in logs.

If the secrets file is lost or its `age` keys are lost, the stored authenticator secrets cannot be decrypted: every admin and Operator would have to re-enrol their authenticator through recovery. That is a second reason to protect the key.

### 3.5 Software and images

The container images are pinned by digest and mirrored to the project's public registry (research R-23, section 7 of the infra research). Docker Hub's anonymous pull limits (100 per 6 hours per address, UNVERIFIED today) must not be relied on during a restore. Check that the pinned images exist in the project registry.

## 4. The timed restore: step table

T+ is the planned time at which a step starts. The ten steps follow the research table (infrastructure research section 5, decision R-22) and their budgets sum to **2 h 45 min**. The hard limit is **4:00**. Every command is a placeholder: fix each one in the first drill.

Differences from the research notes, on purpose: **evidence files are not restored** (they are never in off-server backups; section 9), and the session store (Valkey) is not restored (everyone signs in again).

| Step | T+ | Budget | What | Command placeholders | Done when |
|------|----|--------|------|----------------------|-----------|
| 1 | 0:00 | 10 min | **Declare.** Write the time. Confirm one key holder is reachable and has the `age` key and the backup password. Open this runbook. Freeze changes: tell Operators to stop work. Note the last good backup time from the monitor | `date -u` | Time written; key holder confirmed |
| 2 | 0:10 | 20 min | **Order a new server** at `<VPS_PROVIDER>` (or `<FALLBACK_PROVIDER>`), the same plan size as production. Add the executor's SSH key. Note the addresses | Provider panel; `ssh <ADMIN_USER>@<SERVER_IP4>` | SSH works |
| 3 | 0:30 | 15 min | **Bootstrap.** Run the bootstrap script: users, SSH hardening (keys only, no root, no passwords), firewall (default deny; 80, 443/tcp, 443/udp, the WireGuard port), automatic security updates, Docker, WireGuard | `scp infra/bootstrap.sh <SERVER>:~`; `sudo bash bootstrap.sh` | Script finished with no error; `docker version` works |
| 4 | 0:45 | 10 min | **Code and secrets.** Clone the repository. The key holder gives the `age` key to the executor through a safe channel (never chat or email). Decrypt the secrets file into memory-only storage and place the environment file | `git clone <REPO_URL>`; `SOPS_AGE_KEY_FILE=<MEMORY_ONLY_PATH> sops -d <SECRETS_FILE> > <TMPFS_PATH>/env` | Environment file in memory-only storage; **nothing printed to screen or logs** |
| 5 | 0:55 | 10 min | **Fetch the backup.** Bring up the WireGuard link to `<TEAM_MACHINE>` (the machine adds the new server as a peer). List snapshots and restore the latest: the database dump and globals, and the Caddy data directory and static manifest if the backup holds them. Verify checksums. **No evidence files** (they are not in the backup) | `wg-quick up <WG_INTERFACE>`; `restic -r <RESTIC_REPO> snapshots`; `restic -r <RESTIC_REPO> restore latest --target <RESTORE_DIR>`; `sha256sum -c <MANIFEST>` | Checksums match; contents match `<BACKUP_CONTENTS_LIST>`; the snapshot is within the 6-hour limit, or the gap is noted |
| 6 | 1:05 | 15 min | **Restore the database.** Start only PostgreSQL. Restore globals, then the dump. Run the migration status check. Check row counts and the time of the last audit entry against the backup manifest (section 5) | `docker compose --profile core up -d postgres`; `psql -f <GLOBALS_SQL>`; `pg_restore --clean --if-exists -d <DB_NAME> <DUMP_FILE>`; `<MIGRATION_STATUS_CMD>` | Row counts match the backup manifest; last audit time is within the data-loss limit |
| 7 | 1:20 | 30 min | **Start the stack and switch DNS.** (a) Start the `core` profile (web server, API, worker, PostgreSQL, Valkey, mail). (b) Set the reverse DNS (PTR) for the new address in the provider panel. (c) Change A and AAAA for `data.`, `api.` and `console.` to the new addresses (TTL is already 300) and update SPF (section 7). (d) Certificates: if the Caddy data directory was restored the old certificates are used; otherwise the web server requests new ones from Let's Encrypt, which needs DNS to be right first | `docker compose --profile core up -d`; provider panel (PTR); `<REGISTRAR>` panel; `docker compose logs caddy`; `dig +short <host> A` | All containers healthy; names resolve to the new address from two outside resolvers; HTTPS valid on all three hosts |
| 8 | 1:50 | 20 min | **Rebuild the static files.** Run the job that publishes the region files and manifest; compare the manifest hash with the restored data | `<PUBLISH_PACKS_JOB>`; `<MANIFEST_HASH_CHECK>` | Manifest hash matches |
| 9 | 2:10 | 20 min | **Smoke tests** (section 8), **sweeper rerun and missing-evidence marking** (section 9), **audit chain check** (section 10) | `scripts/dr/smoke.sh` (planned name); `<SWEEPER_CMD>`; `<VERIFY_CHAIN_CMD>` | All checks pass |
| 10 | 2:30 | 15 min | **Close.** Re-enable the backup timer and take the first backup on the new server; give the team machine the new server's details; point the monitor at the new address; tell admins (section 12); record every time and deviation; rotate keys if the cause was a compromise (section 11); sign the record (section 14) | `<BACKUP_NOW_CMD>`; section 14 | First new backup exists; drill record signed |

**Pass rule**: all of steps 1 to 9 complete and verified by **T+4:00**; the target is **T+2:45** for all ten.

### Decision points

| At | If | Then |
|----|----|------|
| T+0:30 | No server yet | Order at `<FALLBACK_PROVIDER>` in parallel |
| T+1:05 | The latest backup is missing or unreadable | Use the next older snapshot; note the larger data loss; tell admins |
| T+2:30 | Step 9 is not finished | Finish the smoke tests first; do the first backup right after |
| T+3:00 | The smoke tests still fail | Call `<OPERATOR_LEAD>`; decide whether to open to admins with known gaps |
| T+3:30 | Not working | Tell admins a later time; keep going. The 4-hour mark is a hard test limit, not a reason to cut a safety step |

## 5. Verification queries

Run after the database restore (step 6) and again after the stack is up. Queries are written in plain SQL for the pilot's expected tables; the real table names come from the data model (not yet written; UNVERIFIED), so adjust.

| Check | Query or action | Expected |
|-------|-----------------|----------|
| Row counts | `SELECT count(*) FROM <masjid_table>;` for Masjids, accounts, claims, evidence metadata, audit | Equal to the counts in the backup manifest |
| Latest audit entry | `SELECT max(ts), max(id) FROM audit_log;` | The time is within 6 hours of the failure; the id is not lower than the backup manifest id |
| Claims by status | `SELECT status, count(*) FROM <claim_table> GROUP BY status;` | The same shape as before; open cases are still open |
| Evidence metadata | `SELECT count(*) FROM <evidence_table> WHERE wrapped_dek IS NOT NULL;` | A number greater than 0 if there were open cases; every one of these has **no file** after a restore (section 9) |
| Migrations | `<MIGRATION_STATUS_CMD>` | No pending or failed migration |
| App role cannot change audit | `UPDATE audit_log SET ... ;` as the application role | `permission denied` |
| Sessions | Existing sessions do not work | Everyone must sign in again; this is expected |

## 6. Costs and the second server

The drill is run on a real second server that then becomes production, so it costs one overlapping month of the monthly price, not an extra. Research R-18 shows the all-in monthly cost ceiling is US$10; the drill month is about US$9.56 before VAT (OVH plan, no extra storage box), UNVERIFIED until the provider is chosen. Delete the old server only after the drill is signed and one day has passed.

## 7. Network and mail changes after the address changes

| Item | Action |
|------|--------|
| A and AAAA records | New address (step 7) |
| SPF | Update to the new address |
| Reverse DNS (PTR) | Set in the provider panel, must match the mail host name (forward-confirmed) |
| DKIM | Same key (from the secrets file); check a test mail |
| DMARC | Unchanged |
| WireGuard peers | The team machine needs the new server's public key and address; the server needs the team machine as a peer |
| Monitor | Point probes to the new address; the backup heartbeat resumes (appendix A.5) |
| Provider firewall | Open 80, 443 (tcp and udp) and the WireGuard port; nothing else public |
| Port 25 | If self-hosted mail is used, the **new** server must have outbound port 25 open (test with a connection to a public mail server before ordering; research R-10). If closed, switch to the relay for the duration (an entry already prepared in the Exceptions Register) |

## 8. Smoke tests

The planned script (`scripts/dr/smoke.sh`, research test plan section 5) runs these. Until it exists, do them by hand and tick them.

| # | Test | Pass |
|---|------|------|
| 1 | **Health**: the API health endpoint answers on the new server | OK |
| 2 | **Manifest and files**: the manifest and three region files return 200 on first request and 304 with an `If-None-Match` | OK |
| 3 | **Admin sign-in with the second factor**: an Operator signs in with password and authenticator code and reaches the review queue | OK |
| 4 | **A claim can be read**: open a claim and see the status and history | OK |
| 5 | **Audit chain is intact** and the latest audit id is not lower than the backup manifest id (section 10) | OK |
| 6 | **Evidence round trip**: upload a test image to a **test claim**, view it with step-up, check the view is logged, delete it. (The old evidence files do not exist after restore; this proves that the key wrapping and the secrets file work.) | OK |
| 7 | **Purge job rerun**: the sweeper runs and removes anything older than 90 days after the final decision; nothing past due remains (section 9) | OK |
| 8 | **No address-and-region pair in the web server log**: with a known test address, request a region file; search the logs for the address; there is none | OK |
| 9 | **A real phone downloads a region** from the new server and shows nearby Masjids; then switch the phone to airplane mode and confirm it still works | OK |
| 10 | **Mail**: send a test email to a seed inbox; headers show `spf=pass dkim=pass dmarc=pass`; the message is not in spam | OK |
| 11 | **TLS**: all three hosts have valid certificates | OK |
| 12 | **Monitor green**: the uptime monitor on the team machine shows all probes up | OK |
| 13 | **Sweeper marked missing evidence** (section 9) | OK |
| 14 | **Secrets**: no secret appears in the terminal transcript or the logs | OK |

## 9. What is NOT restored: evidence files

By design, evidence files are never copied to an off-server backup (decision R-15, and the retention promise in the DPIA). The backup holds only the wrapped keys inside the database dump. After a full server loss:

- All evidence files that existed on the lost server are **gone**. This is intended, not a failure.
- The database says the evidence exists (metadata and a wrapped key), but the file is missing.
- Cases in progress, and closed cases still inside their 90 days, now have **missing evidence**.

### 9.1 What to do after the restore

1. **Run the sweeper** (the daily retention job) on the new server. It is safe to run many times. It deletes anything past 90 days and writes the audit entries. (Reason: the restored database may contain entries that should already have been purged; backups hold data for up to 30 days.)
2. **Mark the cases whose file is missing.** The system shows "evidence missing, request re-upload" for them. Check that the job did it: `<MISSING_EVIDENCE_CHECK>`.
3. **List the affected cases** for the Operators by case id (no names).
4. For each **open** case: ask the admin to upload again, using the status message and the console; the clock for the 5-working-day target restarts on the new upload and the delay is noted as caused by the incident.
5. For each **closed case inside its 90 days**: nothing to do. The decision remains in the database. If an appeal is open, the appeal needs the evidence: ask the admin to upload again; an appeal hold stays in place.
6. For a **break-glass in the 48-hour delay**: check it survived the restore (it lives in the database). If the 48 hours expired during the outage, the job must re-check the conditions before executing; do not let it run unreviewed. Tell the admin and the committee contacts that the process was delayed.
7. **Committee contacts** are in the database and are restored for open cases; they are deleted on schedule by the sweeper.
8. Add one line to the incident record: evidence lost by design, count of cases affected, date.

## 10. Audit chain verification

The audit log is append-only and hash-chained. A nightly job normally verifies it; after a restore, run it by hand.

1. Run `<VERIFY_CHAIN_CMD>`. It must report an unbroken chain from the first entry to the restored head.
2. Compare the restored **head hash** with the last **anchor** that was stored off the server (the daily anchor: a signed commit or an email to the key holders; where it is kept is a planned detail, UNVERIFIED). Cases:
   - The restored head equals the anchor: no entries were lost.
   - The restored head is **older** than the anchor: entries were lost; the missing window is at most the data-loss limit (6 hours). This is expected after a restore. Record the window, and the head hashes, in the drill or incident record.
   - The restored head is **newer** than the anchor or the chain is broken: stop. Treat it as possible tampering (operator runbook, section 18).
3. Write an audit event for the restore itself (what, when, who) after the chain check passes. (Check that the console or script offers this; if not, record the restore in the incident record.)
4. Tell the Operators the lost window so they can re-check the work done in it (section 12).

## 11. Key custody and rotation after a restore

### 11.1 Always

| Item | Action |
|------|--------|
| The new server's `age` key | Create a new key pair on the new server. Add its public key to the secrets file recipients, re-encrypt the file, remove the **old** server's key as a recipient |
| Old server | Delete it at the provider after the drill, once the new server is stable. Cancel the contract |
| WireGuard keys | New pair for the new server; update the team machine |
| SSH access | Confirm only authorised keys exist |
| Session store | Not restored. All sessions are gone. As an extra, bump the session epoch for all accounts so no stale session can ever return (a database column; the command is `<BUMP_EPOCH_CMD>`) |

### 11.2 If the cause was a compromise, or a key holder left, or anything might be known to someone else

| Item | Action |
|------|--------|
| Evidence key-encryption keys | Rotate (re-wrap the keys; files are not touched; there are no old files anyway after a restore) |
| Stored authenticator secrets key | Rotate (re-encrypt all stored secrets) |
| Audit pepper and fingerprint key | Rotating breaks matching of old fingerprints and the chain anchor mapping: decide with the Operator lead and record |
| Database and cache passwords, mail credentials | Rotate |
| Backup repository password | Rotate and re-initialise if the old password may be known; the team machine keeps the history |
| Admin and Operator credentials | Force a password reset for everyone and consider re-enrolment of authenticators |
| Notify | Follow the breach process (operator runbook, section 18; DPIA, breach steps) |

### 11.3 Key holders

- Two key holders must always exist. When a holder leaves, replace them within a week: add the new holder's `age` key, re-encrypt, re-key the backup password (a new copy), and update the escrow.
- Keep the escrow copy sealed; open it only for a real disaster or the annual check. Record every opening.
- Never store the `age` key or the backup password in the repository, chat, email, a photo or a cloud note.

## 12. Communication

The first message goes out within 30 minutes of declaring a real disaster. Messages go from a team mailbox or channel, **not** from the server (it may be down). Admin emails come from the team's own mailbox using each admin's address from a safe list kept by the Operator lead (PROPOSED: the list is exported in the 24 hours before any planned change; if no list exists, wait for the console to return and use its mail). Post the same text at `<STATUS_NOTE_URL>`.

### Template 1: outage notice to admins and Operators

> Subject: Deen App admin service is temporarily unavailable
>
> Assalamu alaykum,
>
> The Deen App admin and Operator service is not available at the moment because of a server problem. We are restoring it from backups. We expect to be back by `<TIME, TIME ZONE>` and will write again when it is.
>
> **The app on your phone keeps working.** Prayer times, Masjid information you already downloaded and your alerts continue to work offline. Nothing changes for people who use the app.
>
> What does not work for now: signing in to the admin console, submitting or reviewing claims, editing a Masjid or its schedule.
>
> You do not need to do anything. Please do not send documents or codes by email. We will never ask for your password or authenticator code.
>
> Deen App team, `<OPERATOR_LEAD>`

### Template 2: restored notice

> Subject: Deen App admin service is back
>
> Assalamu alaykum,
>
> The admin service is working again. For security you must sign in again with your password and authenticator code.
>
> Because we restored from a backup, changes made between `<LAST_BACKUP_TIME>` and `<OUTAGE_START>` (about `<N>` hours) may be missing. Please check any edit, claim or schedule change you made in that period and enter it again if it is gone.
>
> If you have a claim under review and we asked you for documents, you may be asked to upload them again: for your privacy we do not keep copies of your documents outside the server, so they were not restored. We are sorry for the extra work. Your claim's place in the queue is kept.
>
> If something looks wrong, write to `<SUPPORT_EMAIL>`.
>
> Deen App team

### Template 3: for Operators only (internal)

> The server was restored at `<TIME>`. Data after `<LAST_BACKUP_TIME>` is missing (a window of `<N>` hours). Do the following: (1) sign in again; (2) check the list of cases with missing evidence (ids only); (3) re-check any decision you made in the window; (4) do not start break-glass or recovery requests until the lead confirms the delay timers are still correct; (5) record every anomaly.

### Template 4: public line (optional)

> Our directory and admin services are being restored after a server problem. The app keeps working offline.

Do not post details of the cause until the lead decides.

## 13. Do not do these

- Do not paste the `age` key, the backup password or any decrypted secret into chat, email, a ticket or a terminal that is being recorded in clear.
- Do not skip the checksum check to save time.
- Do not open the public site before the smoke tests pass on a compromise recovery.
- Do not restore a backup older than needed.
- Do not reuse the old server's keys on a new server.
- Do not tell admins their documents are "safe in the backup": they are not in it, by design.

## 14. Drill record form

Copy this section into a new file for each drill: `specs/002-masjid-directory-verification/evidence/restore-drill-YYYYMMDD.md`. Fill every line.

### 14.1 Header

| Field | Value |
|-------|-------|
| Drill date and time zone | |
| Reason (before launch, backup change, yearly, other) | |
| Runbook version and commit | |
| Executor | |
| Timekeeper (not the executor) | |
| Key holders present | |
| New server provider, plan, address | |
| Last backup time used and age at T+0 | |
| DNS TTL checked as 300 s before the drill (yes or no) | |
| Terminal transcript saved at | |

### 14.2 Timeline (wall-clock time per step)

| Step | Planned T+ | Planned budget | Actual start | Actual end | Elapsed | Pass | Notes |
|------|-----------|----------------|--------------|------------|---------|------|-------|
| 1 Declare | 0:00 | 10 min | | | | | |
| 2 Order server | 0:10 | 20 min | | | | | |
| 3 Bootstrap | 0:30 | 15 min | | | | | |
| 4 Code and secrets | 0:45 | 10 min | | | | | |
| 5 Fetch and restore backup files | 0:55 | 10 min | | | | | |
| 6 Restore database | 1:05 | 15 min | | | | | |
| 7 Start stack, DNS, certificates | 1:20 | 30 min | | | | | |
| 8 Static files | 1:50 | 20 min | | | | | |
| 9 Smoke tests, sweeper, chain check | 2:10 | 20 min | | | | | |
| 10 First backup, close, sign | 2:30 | 15 min | | | | | |
| **Total** (target 2:45, limit 4:00) | | | | | | | |

### 14.3 Smoke tests (section 8)

| # | Result | Time | Note |
|---|--------|------|------|
| 1 | | | |
| 2 | | | |
| 3 | | | |
| 4 | | | |
| 5 | | | |
| 6 | | | |
| 7 | | | |
| 8 | | | |
| 9 | | | |
| 10 | | | |
| 11 | | | |
| 12 | | | |
| 13 | | | |
| 14 | | | |

### 14.4 Results against the pass rule

| Criterion | Pass or fail | Value |
|-----------|--------------|-------|
| Wall clock 4:00 or less | | |
| Wall clock 2:45 or less (target) | | |
| Data loss within 6 hours | | |
| Audit chain unbroken; head vs anchor compared | | |
| No secret printed in logs or transcript | | |
| Evidence handling as in section 9 (sweeper rerun, missing evidence marked) | | |
| All smoke tests pass | | |
| Every runbook correction committed | | |

### 14.5 Deviations and defects

| # | Step | What differed from the runbook | Fix (committed where) | Defect id |
|---|------|--------------------------------|------------------------|-----------|
| 1 | | | | |
| 2 | | | | |
| 3 | | | | |

### 14.6 Sign-off

| Role | Name | Signature | Date |
|------|------|-----------|------|
| Executor | | | |
| Timekeeper | | | |
| Second signature (a key holder or `<OPERATOR_LEAD>`) | | | |

Two signatures are required: the executor's and one other (the timekeeper counts). The SC-006 evidence is this record, the transcript, the per-step times, the smoke output and the deviation list.

## 15. When to run the drill

| Run it | Why |
|--------|-----|
| **Before launch**, once, on a real second server that becomes production (SC-006) | Required by the success criteria |
| **After any change to the backup system**: tool, schedule, retention, location, encryption, key custody | The runbook may no longer be true |
| **After a major infrastructure change**: provider, server size, operating system release, database major version, storage layout | Steps and times change |
| **When a key holder changes** (a light version: confirm the new holder can decrypt and list the repository) | The recovery path must not depend on a person who left |
| **Every 12 months** | Skills and tools drift |
| **Quarterly, a light version**: restore the latest backup into a throwaway container and run the verification queries (section 5) | Catches a bad backup early (research infra section 6) |
| **After any real disaster**: record real times in the same form | Real data is the best drill |

Rehearse first on a local virtual machine before the first real-server drill. The executor must not be the runbook's author; correct the document during the drill.

---

## Appendix A: Routine backups

### A.1 Schedule and content

| Item | Rule |
|------|------|
| Database dump | `pg_dump -Fc` plus `pg_dumpall --globals-only`, **every 6 hours** at 00:00, 06:00, 12:00 and 18:00 UTC (data-loss limit 6 hours) |
| Staging | The dump is written to a staging folder on the server |
| Second copy | The team machine pulls the staged files over WireGuard and stores them in an encrypted restic repository (A.3) |
| Contents | The database dump and globals; the Caddy data directory (certificates) and the static manifest if `<BACKUP_CONTENTS_LIST>` says so. Anything else must be listed there |
| **Never in a backup** | **Evidence files**, the secrets file in plain form, the session store, logs with addresses |
| Evidence files | Only encrypted at rest on the server; deleted at 90 days; not copied off the server (DPIA, retention) |
| Timing | Scheduled away from the five prayer windows and from peak traffic (research R-20) |

### A.2 Retention

| Rule | Value |
|------|-------|
| Maximum age of any database backup | **30 days** (research R-15; DPIA). Dumps hold committee contacts and notes, which are deleted from live systems at 90 days, so backups must age out quickly |
| Applied policy | 14 daily snapshots plus 2 weekly snapshots (so the oldest is under 30 days). Command: `restic forget --keep-daily 14 --keep-weekly 2 --prune` (placeholder) |
| Check | After every prune: `restic snapshots` shows no snapshot older than 30 days |
| Conflict to resolve | Research R-22 lists 14 daily, 8 weekly and 6 monthly. That would keep dumps for 6 months and breaks the 30-day promise. This runbook applies the stricter rule until the owner decides (also DPIA section 18, item 2) |

### A.3 The pull-model second copy

- The second copy sits on `<TEAM_MACHINE>`, which has the repository password; the **server does not have credentials to delete or overwrite the repository** (research R-22). A hacked server therefore cannot erase history.
- The machine runs the pull and the backup, and the prune. Command placeholders: `rsync <SERVER>:<STAGING_DIR>/ <LOCAL_STAGING>/`; `restic -r <RESTIC_REPO> backup <LOCAL_STAGING>`; `restic -r <RESTIC_REPO> forget ... --prune`.
- Alternative with the same property (append-only server mode) is allowed if the pull model proves painful; the owner decides. Either way the rule is: **the server can add backups but cannot delete them.**
- The repository password is held by `<KEY_HOLDER_1>` and `<KEY_HOLDER_2>` and escrowed offline (section 3.1).
- The machine needs: 99% uptime (research), free disk of at least `<MIN_FREE_GB>`, an up-to-date clock, disk encryption, a locked account, and a person who can fix it. If it goes down, the server still has staged dumps for a short time (staging is cleared only after a successful pull); fix it within 24 hours.
- A second copy at a storage-box provider is optional and breaks the budget when VAT applies (research R-18); do not assume it exists.

### A.4 How to check that a backup is fresh

| Check | How | How often | Pass |
|-------|-----|-----------|------|
| Latest snapshot age | `restic -r <RESTIC_REPO> snapshots --latest 1` | Weekly by the Operator on duty; the monitor checks it automatically | Younger than 7 hours (one missed run plus margin) |
| Contents look right | `restic -r <RESTIC_REPO> ls latest` shows the dump and globals | Weekly | Both files present, sizes similar to last week |
| Dump readable | `pg_restore --list <DUMP_FILE>` | Weekly | Lists tables with no error |
| Repository healthy | `restic -r <RESTIC_REPO> check` | Monthly | No errors |
| Real restore | Restore into a throwaway container and run the queries in section 5 | **Quarterly** | Row counts plausible; audit chain verifies |
| Oldest snapshot | `restic snapshots` | After every prune | Under 30 days |
| Disk space | `df -h` on the team machine and the server | Weekly | Under 75% used (the plan's alert level) |

If any check fails, tell the Operator lead the same day and fix before the next run.

### A.5 Uptime monitor and heartbeat

- The uptime monitor (Uptime Kuma, MIT) runs on a **team member's always-on machine, not on the server**: a monitor on the same server cannot report that the server died (research R-19). If no always-on machine exists, a scheduled probe on GitHub Actions every 5 minutes is the last resort.
- Probes: manifest freshness (age of the last-modified time), the API health endpoint, certificate expiry (14 days), the mail server greeting, DNS.
- **Backup heartbeat**: after each successful backup run, the job calls a push URL of the monitor. If no heartbeat arrives for **8 hours** (the 6-hour schedule plus margin; PROPOSED, the research suggested 26 hours for a daily schedule), the monitor alerts. Treat a missing heartbeat as an incident for the key holders.
- Alerts go to a team member's mailbox or a self-hosted notification service; not to a chat service hosted by a third party (research R-19).
- If the monitor machine itself is down, the team gets no alerts: ask one person to check by hand every Monday that the monitor is up and the last heartbeat is recent.

### A.6 Who does what

| Task | Who | When |
|------|-----|------|
| Weekly freshness check | Operator on duty (needs the team machine access) | Weekly |
| Quarterly real restore (light) | `<KEY_HOLDER_1>` or `<KEY_HOLDER_2>` | Quarterly |
| Escrow and key-holder check | `<OPERATOR_LEAD>` | Quarterly |
| Full drill | Executor and timekeeper | Section 15 |
| Updating this runbook | `<ENGINEERING_LEAD>` | After every drill or change |

---

## Validation

| What is proven | By | Status |
|----------------|----|--------|
| Recovery from a full server loss in under 4 hours (target 2 h 45 min), with the data-loss limit of 6 hours, the audit chain intact, no secret in logs and every runbook correction committed (SC-006) | The **timed restore drill** on a real second server (section 14), run before launch, with a timekeeper and two signatures | Not yet run |
| Each command placeholder is real, and the step budgets are right | The first drill: the executor, who did not write the runbook, corrects the document as they go | Not yet run |
| The backup routine (6-hour schedule, 30-day retention, pull copy, heartbeat) | The first weeks in the pilot and the quarterly light restore (appendix A.4); a configuration test for "no evidence in backups" and "no snapshot older than 30 days" | Not yet run; the backup system does not exist |
| Admin communication and the sweeper and missing-evidence handling | The drill (smoke tests 6, 7, 13) and a table-top read-through with the Operators | Not yet run |
| Key custody (two holders, escrow) | A decrypt-and-list test by each holder, repeated quarterly | Not yet done; holders not named |
| Legal wording of the backup retention promise ("deleted from live systems at 90 days; encrypted database backups expire within 30 more days") | **Legal review** with the DPIA (open question 8) | Not started |

Still open: every `<PLACEHOLDER>` in the table at the top; the real commands and table names (they depend on `infra/` and the data model, which do not exist yet); the conflict between the 30-day backup rule and the 6-month retention in research R-22; the exact backup contents list; the name and location of the anchor store for the audit chain head; the provider and its port-25 policy (UNVERIFIED); and whether the first drill's timings hold on the chosen provider.
