# Data Protection Impact Assessment: Verification Documents and Admin Accounts (Phase 1)

**Status**: DRAFT 0.1, 2026-10-22. **Owner**: `<DPIA_OWNER>`. **Spec**: [../spec.md](../spec.md). **Decisions**: [../research.md](../research.md). **Companion documents**: [operator-runbook.md](operator-runbook.md), [restore-runbook.md](restore-runbook.md).

> **Needs validation.** This is an engineering draft, not legal advice. It needs review by a lawyer or data-protection adviser before launch (marked [LAWYER] throughout). Likelihood and severity ratings are the team's own first estimates and need a second opinion. Facts nobody has checked yet are marked UNVERIFIED. The law that applies depends on who the controller is and where, which is not decided (open question 1, 2). Nothing here may be published as the project's final position until the legal review is done.

Marks used:

| Mark | Meaning |
|------|---------|
| [LAWYER] | Needs lawyer or DPO review |
| UNVERIFIED | A fact not confirmed from a primary source |
| PROPOSED | A working rule from this draft, not in the spec |
| `<PLACEHOLDER>` | A name or decision not made yet |

## Fill in before use

| Placeholder | What it is | Value | Decided by |
|-------------|-----------|-------|------------|
| `<CONTROLLER_NAME>` | The legal person responsible for the processing (is there a legal entity yet?) | not decided | Owner, [LAWYER] |
| `<DPIA_OWNER>` | Person who keeps this document up to date | not decided | Owner |
| `<DPO_OR_CONTACT>` | Data-protection officer or the privacy contact, if one is needed | not decided | Owner, [LAWYER] |
| `<PRIVACY_EMAIL>` | Address for privacy requests | not decided | Owner |
| `<AUTHORITY_NAME>` | The supervisory authority that applies | not decided | [LAWYER] |
| `<DOMAIN>` | Project domain (console and API hosts hang off it) | not decided | Owner |
| `<VPS_PROVIDER>` and `<VPS_REGION>` | Server host and the country of the data centre. Research lists OVHcloud as primary candidate and Contabo as fallback; no purchase decided | not decided | Owner |
| `<MAIL_ROUTE>` | Self-hosted mail on the same server, or a free relay (fallback only, decided after the 14-day exit test) | not decided | Owner |
| `<TEAM_MACHINE_LOCATION>` | Country and owner of the always-on machine that holds the second backup copy | not decided | Owner |
| `<KEY_HOLDER_1>`, `<KEY_HOLDER_2>` | The two people who hold the keys | not decided | Owner |
| `<OWNER: ...>` | Role that owns each policy document (section 17) | not decided | Owner |
| `<OPERATOR_COUNTRIES>` | Countries where Operators work and sign in from | not decided | Owner |

---

## 1. Summary

Deen App Phase 1 adds an optional server. Masjid admins sign up, claim a Masjid and upload documents. Operators check those documents and phone people on the committee. The listener app only reads public files and sends no personal data.

This DPIA covers the part that is risky for people: **verification documents** (committee and trust papers, authorisation letters, building photos) and **committee members' contact details**, plus the admin and Operator accounts around them. Together they reveal who runs a place of worship. In some places that can put people at risk.

Main findings (draft):

- The design collects as little as possible: re-encoded images only, two committee contacts, no ID numbers requested, deletion 90 days after the final decision.
- The largest remaining risks are an Operator misusing access, a compromise of the live server (it can decrypt evidence that still exists), and holding committee contacts' data about people who never agreed to it.
- Several retention periods and a fingerprint rule need legal sign-off before launch (section 6, section 18).
- The listener path processes no personal data by design, but IP addresses are visible to the server host and the network (section 12).

## 2. Why a DPIA is done

A DPIA is a risk assessment required (under the EU and UK regimes, UNVERIFIED for other places) for processing likely to result in a high risk to people. This project does it because: the data can reveal religious belief or role in a religious community (special-category data under Art. 9, [LAWYER]); it holds data about third parties who did not supply it themselves; hostile governments or individuals could be interested in it; and later phases (broadcast rights) raise the value of a Verified status. Whether the law strictly requires a DPIA at pilot scale is for the lawyer; the team does one regardless.

## 3. Processing description

### 3.1 Purpose

1. Decide whether a person is entitled to speak for a Masjid, so that only genuine Masjids carry a Verified badge, publish schedules, and (in Phase 2) get broadcast rights (constitution principle 5).
2. Operate admin and Operator accounts securely (multi-factor sign-in, recovery).
3. Keep an audit trail of state changes.
4. Answer privacy requests and handle abuse.

### 3.2 The steps

| # | Step | Data | Who sees it |
|---|------|------|-------------|
| 1 | An admin signs up | Email, password (stored as a hash), authenticator secret (encrypted), recovery codes (hashed), sign-in events with network address | The admin; the server; Operators see the account and events when needed |
| 2 | The admin claims or creates a Masjid and uploads evidence | Committee or trust documents, authorisation letter, building photos, **names, phone numbers and emails of two committee members** | Evidence: only the Operator assigned to the open case. Contacts: same |
| 3 | The upload is cleaned | Files are checked, re-encoded to images (metadata dropped), PDFs turned into page images; the originals are not kept | Server only |
| 4 | An Operator reviews and phones | Phone call to a committee contact; the Operator records the outcome and short notes | The assigned Operator |
| 5 | Decision | Status and reason (shown to the admin); audit entry | Admin sees status and reason; Operators see the case |
| 6 | After the decision | Evidence and contacts are deleted 90 days after the final decision (kept only while under appeal) | |
| 7 | Renewal | A shorter check at 12 months | As above |
| 8 | Recovery | Operator-approved reset; break-glass (started by a super-admin, approved by a reviewer or another super-admin) with a call to a committee contact and a 48-hour delay, with emails to the admin and every committee contact. If the 90-day purge already deleted the contacts, the Operator adds fresh contacts verified through an independent public number; they are deleted with the case | The initiating and approving Operators |
| 9 | Privacy requests | Request details, identity check, export or erasure | Operators |
| 10 | Offboarding or deletion | Account data removed; audit entries anonymised | |

### 3.3 Systems

One virtual server (Caddy, API and worker, PostgreSQL, Valkey, mail, monitoring agents), an encrypted evidence directory on that server, the Operator console (a web application), a second backup copy on a team member's machine, and GitHub for the project's public privacy page and code. See research R-01, R-13, R-19, R-22.

### 3.4 Scale and people

Pilot: 3 to 5 Masjids, about 13 accounts, at least 2 Operators. Planned later: about 500 Masjids and about 1,250 accounts (research R-10 estimate). Data subjects: Masjid admins, Muazzins, committee members named as contacts, Operators, and people who submit abuse reports or suggestions (only if they type an email).

## 4. Data categories

| Category | Examples | Source | Data subject | Special category? | Where it lives |
|----------|----------|--------|--------------|-------------------|-----------------|
| Admin account | Email, password hash (Argon2id), authenticator secret (AES-256-GCM encrypted), recovery-code hashes | The admin | Admin | No, but it identifies a person with a religious role | Database |
| Security log | Account reference, time, outcome, **network address**, browser family | Generated | Admin, Operator | No | Database table |
| Evidence documents | Committee or trust papers, authorisation letter, building photos; may show names, signatures, addresses, possibly ID numbers on documents | The admin | Admin, **committee members and others named on documents (third parties)** | Likely yes by inference (religious role and place) [LAWYER] | Encrypted files on the server; wrapped keys in the database |
| **Committee contacts** | Names, phone numbers, emails of two committee members; also fresh contacts an Operator adds to a break-glass case after the 90-day purge, verified through an independent public number and deleted with that case | The admin (or the Operator for fresh contacts), not the person | **Third parties** | Likely yes by inference [LAWYER] | Separate database table |
| Call and review notes | Outcome code, who answered (name and role), short notes, decision reason | The Operator | Contacts, admin | As above | Database; deleted with evidence |
| Fingerprints of rejected evidence | Keyed hash (HMAC-SHA256) of the cleaned images | Generated | Admin | No (hash only) | Database |
| Audit entries | Who did what, when; an anonymous actor reference | Generated | Admin, Operator | No | Database (append-only) |
| Operator identity | Name, work email, account, role, audit actor mapping | The Operator | Operator | No | Database |
| Muazzin account | Email, invitation, role | The admin invites; the Muazzin | Muazzin | Same as admin | Database |
| Abuse reports and suggestions | Text; an email only if the listener typed one | Listener | Listener (rarely) | No | Database |
| Backups | Database dumps (hold all of the above except evidence files) | Generated | All | As above | Team machine |
| Mail | Reminders and notices to admins; messages seen by mail providers | Generated | Admin, contacts | No | Mail system, recipient providers |
| Rate-limit keys | Keyed hash of an address with a salt that changes daily | Generated | Anyone using public routes | No | Valkey only, at most 1 hour |

Not collected: listener location, identifiers, follows, device data, accounts. The app stores follows on the phone only (FR-003, FR-010).

## 5. Lawful basis options [LAWYER]

The controller must pick one basis for each purpose before launch. These are options, not decisions.

| Processing | Options | Notes |
|-----------|---------|-------|
| Admin account and sign-in | Art. 6(1)(b) contract (the admin asks for the service); Art. 6(1)(f) legitimate interests for security logging | Security logging is a legitimate-interest purpose; write a short balancing test (LIA) |
| Verification of the admin's claim | Art. 6(1)(f) legitimate interests (the project's and the community's interest in genuine Masjids and safe broadcast); Art. 6(1)(b) | Documents can show religion by inference |
| Special-category inference (religious role and place) | Art. 9(2)(a) **explicit consent** by the admin for their own data (withdrawable: withdrawing means withdrawing the claim); other Art. 9(2) grounds are doubtful | Consent must be freely given and separate; withdrawal must be as easy as giving |
| Committee contacts (third parties) | Art. 6(1)(f); consent given **directly** by the person on the verification call (explicit, recorded as an outcome); Art. 9 position unclear | Consent via the admin is weak. The Art. 14 notice at the first contact is required either way |
| Break-glass emails to committee contacts | Art. 6(1)(f) (protect the account and the Masjid from takeover) | Mail goes to contacts who already know us from the verification call |
| Audit log | Art. 6(1)(f); accountability; legal obligations if any | Retention 24 months proposed |
| Fingerprints (identical evidence stays rejected) | Art. 6(1)(f) | 12 months; the admin is told. Open question 5 (BLOCKER) |
| Privacy-request handling | Art. 6(1)(c) legal obligation | Minimal record kept |
| Breach register | Art. 6(1)(c) | Required by Art. 33(5) |

Data subjects are told the basis in the privacy notice and the committee-contact notice (section 17).

## 6. Necessity and proportionality

### 6.1 Why documents and a call

A fake Masjid claim could later let someone broadcast an Azaan (or anything) to phones that trust the Masjid. The more power Verified brings, the more verification matters (constitution principle 5). A person asserting "I am the secretary" in a form is not enough. The documents give the Operator something to check against; the **phone call is the real check**.

### 6.2 Alternatives considered

| Alternative | Why not chosen (or why a part of it is kept) |
|-------------|-----------------------------------------------|
| Phone call only, no documents | Weaker: nothing to check consistency against; but the call is the core check and is kept |
| Check an existing public source only (website, OpenStreetMap, registry entry) | Many Masjids have none; useful only as a cross-check, which Operators do |
| Email-domain proof (an address at the Masjid's own domain) | Many Masjids have no domain; the domain owner may not be the committee |
| In-person visit by a local volunteer | Does not scale; adds a person who sees data; may be offered later for hard cases |
| Third-party identity-verification service | Violates principle 10 (paid or freemium SaaS), adds a processor, collects ID documents |
| Verify without keeping anything | Cannot defend a decision, cannot handle an appeal, cannot show the claim was checked |
| Keep evidence permanently | Disproportionate; creates the largest breach risk |
| Keep only a reference to the evidence (no files) | Possible fallback; loses the reviewer's ability to look again during an appeal |

### 6.3 Minimisation measures

- Only images are kept: uploads are re-encoded (metadata, GPS and similar removed) or rasterised; originals are never stored or served (research R-12, R-14).
- Two committee contacts, not a list. No ID numbers are requested; the claim form asks the admin to hide unrelated personal data.
- Contacts are stored separately, visible only to the assigned Operator while the case is open; every view is logged (FR-032).
- Documents are decryptable on the server only; delivery is gated by step-up and an audit row written first (research R-13).
- Evidence and contacts are deleted 90 days after the final decision (FR-008, FR-032); the delete uses key destruction first.
- Evidence files are never in off-server backups.
- No listener data of any kind.
- No paid text-message or telephony service; no third-party identity checks.
- Operator access: assigned-Operator-only; super-admin has no automatic read.

### 6.4 Honest limits

- Decryption is on the server in Phase 1. A live server compromise exposes the evidence that still exists (research R-13). Keys held outside the server are a documented later option, not Phase 1.
- Antivirus scanning is not run on uploads (memory cost); compensating controls are listed in research R-14.
- An assigned Operator can still photograph a screen. Watermarks and the audit log deter but do not prevent it.

## 7. Retention

| Data | Retention | Starts | Mechanism | Proof |
|------|-----------|--------|-----------|-------|
| Evidence documents and committee contacts (with Operator notes) | **90 days after the final decision**; longer **only while under appeal** (hold; deleted 90 days after the appeal decision) | Final decision | Daily job: destroy the key first, delete contact rows and notes, then delete the file | `evidence.purged` audit entry; daily check that nothing is past due |
| Fingerprints of rejected evidence | **12 months** | Rejection | Scheduled deletion | Audit entry. [LAWYER] |
| Operational audit log | **24 months** | Entry date | Scheduled deletion of old partitions | PROPOSED, [LAWYER] |
| Evidence and contact **access** events | 12 months after the purge date | Purge | As above | PROPOSED, [LAWYER] |
| Masjid version history | Life of the listing | n/a | n/a | PROPOSED |
| Audit chain anchors (hashes only) | Indefinitely | n/a | n/a | Hashes contain no personal data |
| Actor-to-account mapping (Operators) | While employed plus 24 months | Departure | Deleted | PROPOSED, [LAWYER] |
| Sign-in security log, raw network address | **30 days**, then truncated (IPv4 /24, IPv6 /48) for **12 months**, then deleted | Event | Scheduled job | LIA [LAWYER] |
| Application logs | 14 days | Log time | Journal retention | Config |
| Rate-limit counters | At most 24 hours (keys that carry a network address at most 1 hour) | Event | Expiry in Valkey | Test asserts none reach disk or backups |
| Database backups | **At most 30 days** | Backup time | Retention policy on the team machine | Check of oldest snapshot in the backup routine |
| Evidence files in backups | **Never** | n/a | Excluded | Backup configuration test |
| Abuse report or suggestion email (if typed) | Until the case closes plus 30 days | Case close | Scheduled deletion | PROPOSED |
| Admin account data | Life of the account; deleted on request (section 8) | | | |
| Privacy request record | Minimal (id, dates, outcome) for a period set by the lawyer | Request close | | [LAWYER], open question 6 |
| Breach register | Period set by the lawyer | Entry | | [LAWYER] |
| Listener data | None held | | | |

A note on backups: erasure from live systems is immediate; encrypted database backups (which hold no evidence files) age out within 30 more days. The privacy notice must say so (section 17). An inconsistency to fix: research R-22 lists backup retention of 14 daily, 8 weekly and 6 monthly, which would keep dumps (and the contacts inside them) for 6 months. This DPIA assumes the stricter 30 days stated in R-15; the backup configuration must follow it (restore runbook, routine backups).

## 8. Rights handling

| Right | How it is met | Notes |
|-------|---------------|-------|
| Information (Art. 13) | Privacy notice for admins and Muazzins at sign-up | Section 17 |
| Information for third parties (Art. 14) | Spoken notice at the first call to every committee contact, then a written notice by email link where we hold an address (operator runbook, section 5.4) | Verbal sufficiency [LAWYER] |
| Access and portability | Admins and Muazzins export their own data in the console. Others by email to `<PRIVACY_EMAIL>` | Whether the export includes evidence images and the contacts supplied is open question 5 |
| Rectification | Admins edit their own data. Contacts may ask us to correct | |
| Erasure | Admin deletes the account: personal data is removed; the Masjid listing and audit entries remain, **anonymised**. Committee contacts: deleted on request after an identity check | What remains: section 8.1 |
| Restriction and objection | Handled as privacy requests; objection by a committee contact stops processing and deletes the contact | |
| Withdraw consent | Withdrawing explicit consent means withdrawing the claim | |
| Complaint | The notice names `<AUTHORITY_NAME>` | |

**Commitment: every request is answered within 30 days** (FR-024). The console records the receipt date and deadline; a reminder fires on **day 20**. The law may allow an extension for complex cases; the project promises 30 days and tells the person early if it cannot [LAWYER].

**Identity check**: a signed-in admin with step-up is verified. For anyone else, an Operator calls back on a number we already hold, never one given in the request. No ID document is requested.

### 8.1 What remains after erasure

| Remains | Why | Limit |
|---------|-----|-------|
| Masjid listing | The listing is public information about a place, not the person; other admins may exist | If the person was the only admin, the Operator is warned |
| Audit entries | Accountability and tamper evidence. After deletion the link from entry to person is destroyed, so entries read "Former admin" | Pseudonymous until the mapping is deleted, anonymous after; [LAWYER] to confirm this is enough |
| Fingerprints of rejected evidence | Identical evidence must stay rejected | 12 months [LAWYER], open question 5 |
| Truncated security-log addresses | Pattern analysis | 12 months |
| Encrypted database backups | Technical | 30 days |
| Request record | Proof of compliance | Minimal |

## 9. Processors, sub-processors and other recipients [LAWYER]

A written agreement (processor terms) is needed for each processor.

| Party | Role | Data they can reach | Agreement | Open points |
|-------|------|----------------------|-----------|-------------|
| VPS host `<VPS_PROVIDER>` | Processor | Everything on the server (encrypted at the application level for evidence, but the host controls the machine); network addresses of every visitor | Provider terms and data-processing addendum | Not chosen; region `<VPS_REGION>`; provider's own log retention UNVERIFIED. Choose by retention policy and publish the name |
| Mail: self-hosted on the same server | No extra party | Admin emails in transit | n/a | Receiving mail providers (for example the admin's own) see the messages |
| Mail relay (fallback only, e.g. Resend free plan, Brevo as alternate) | Processor, only if the self-hosted mail exit test fails | Admin and contact email addresses, message content | Provider terms; Exceptions Register entry | Not adopted; location UNVERIFIED |
| Backup location: a team member's always-on machine | Team member acting for the controller (not an outside company) | Encrypted database dumps; the repository password and the `age` key are held by two people | Confidentiality agreement and a device-security rule | `<TEAM_MACHINE_LOCATION>`; a personal device holding other people's data needs an explicit rule |
| GitHub | Hosts code, issue tracking, CI and the privacy page | No personal data by design; the daily audit-chain head hash (not personal) may be recorded there | GitHub terms | Contributors' own data is theirs |
| Domain registrar and DNS | Supplier | Registrant data of the project; no user data | Terms | Not chosen |
| Let's Encrypt | Public certificate authority | Host names appear in public certificate logs | n/a | Host names are public by nature |
| Docker Hub and GitHub Container Registry | Image sources at build time | None | n/a | |
| Uptime monitor on a team machine | Team member | Health data only, no user data | | |
| OpenStreetMap | Source of imported data | None from us | ODbL licence | Attribution and share-alike obligations (operator runbook, section 12.3) |

Operators who work from their own devices are staff of the controller; they sign a confidentiality duty and a code of conduct [LAWYER].

## 10. International transfers [LAWYER]

| Flow | Possible transfer | Position |
|------|-------------------|----------|
| Admins and Operators sign in from many countries | Data returns to the person or to an Operator abroad | Remote access by an Operator outside the server's country counts as a transfer under some regimes. `<OPERATOR_COUNTRIES>` |
| Server in `<VPS_REGION>` | The candidates named in the research are in the EU (UNVERIFIED data-centre list) | In-region hosting avoids a transfer for EU data; for admins elsewhere it is a transfer into the EU |
| Mail relay (if used) | Providers named in the research are likely US-based (UNVERIFIED) | Transfer mechanism or in-region mail; only low-volume admin mail |
| Team backup machine | Possibly outside the server's country | `<TEAM_MACHINE_LOCATION>`; encrypted backups; decide if a transfer mechanism is needed |
| Listeners' network addresses | The server host sees addresses of phones worldwide | Section 12 |
| Authorities' requests | A hostile government may ask the host for data | Minimal retention is the main defence; legal-request procedure to be written (open question 14) |

## 11. Risk register

Scales: Low, Medium, High (team estimate; needs a second opinion). Risk is to the **people**, not only to the project. Threat numbers refer to the security research (r5 section 6) so the two documents stay linked.

| ID | Risk (threat no.) | Likelihood | Severity | Mitigations in the design | Residual |
|----|-------------------|-----------|----------|----------------------------|----------|
| R1 | **Fake Masjid claim** (1): someone claims a Masjid that is not theirs | Medium | High: harm to the community, later broadcast rights | Documents plus two committee contacts plus an Operator phone call; independent public number first; second Operator when doubtful; conflicting claims held; identical rejected evidence stays rejected; 12-month renewal | Medium: a convincing insider; numbers supplied by the claimant |
| R2 | **Forged documents** (2) | Medium | Medium | The call, not the paper, decides; images only; the script says documents alone never suffice; second Operator review | Medium: accepted; Verified is a human judgement |
| R3 | **Admin account takeover** (3) | Medium | High: false edits, reputation, later broadcast | Argon2id; blocklist of common passwords; authenticator code with single-use codes; single-use recovery codes; step-up; session closure on any factor change; rate limits; notices | Low to Medium: a phished authenticator code |
| R4 | **Insider Operator abuse** (4) | Low | High: reads private data, misuses contacts | Assigned-Operator-only view; step-up; audit written before viewing (no row, no view); alert when many cases are viewed; watermark; two-person rule for break-glass and transfer; offboarding checklist with key rotation | Medium: an assigned Operator can photograph a screen |
| R5 | **Mass scraping of the directory** (5) | High (the open layer is public) | Low | The open layer is public by design (ODbL). Admin layer (schedules, photos, contacts) is not in bulk files; no listing of contacts; rate limits | Accepted for the open layer; Low for the private layer |
| R6 | **Poisoned OpenStreetMap import** (6) | Low | Medium | Staging copy, diff review, bounds and format checks, Operator approval, labelled Unclaimed, versioned rollback | Low to Medium: subtle wrong coordinates |
| R7 | **Suggestion or abuse-report flood** (7) | Medium | Low | Proof-of-work and hidden-field checks, hashed-address limits with a short life, moderation queue, no auto-merge | Low |
| R8 | **Evidence leak** (8) | Low | High | Encrypted per file; keys wrapped; no URLs; no copies in backups; separate Unix user; purge at 90 days; viewer is images only; upload sandbox | Low to Medium: a live server compromise exposes evidence that still exists |
| R9 | **Email account takeover leading to password reset** (9) | Medium | High | A reset never skips the second factor; links are single-use and last 10 minutes; notices to the old and new address; second-factor reset needs an Operator plus a recovery code | Low |
| R10 | **Denial of service on a small server** (10) | Medium | Medium: admins cannot work; phones keep working | Static files cached by the web server; 500 KB file cap; rate limits; limited password-hash concurrency; memory limits; the app works offline (FR-001) | Medium: a large volumetric attack exceeds a US$10 server; no paid mitigation by principle 10 |
| R11 | **Backup leak** (11) | Low | High | Backups encrypted; keys held offline by two people; evidence excluded; 30-day retention; restore drill | Low |
| R12 | **Software supply-chain compromise** (12) | Low to Medium | High | Lockfile; release-age wait; install scripts off by default; vulnerability scanning; pinned images and CI actions; two reviewers for lockfile changes; no package installs on the server | Medium: a malicious new release can slip through |
| R13 | **Over-retention**: deletion job fails or backups keep contacts longer than said | Medium | Medium | Daily check that nothing is past due, with an alert; the order destroys the key first; backups at most 30 days; restore reruns the deletion job | Low to Medium, until the backup retention conflict (section 7) is fixed |
| R14 | **Third-party data without a relationship**: committee members never agreed to our holding their details | High | Medium | Notice at first contact; minimal use; visible to one Operator; deleted 90 days after the decision; deletion on request | Medium [LAWYER] |
| R15 | **Fingerprint retention challenged** (12-month rule) | Low | Low to Medium | Keyed hash only; admin told; short period; deleted on expiry | Low [LAWYER] |
| R16 | **Listener network address visible to the server host and network** | Medium | Medium: reveals that an address connected to a Masjid-directory server | No access log on the data host; padded file sizes; aggregate counters only; no third-party CDN; honest disclosure and VPN advice (section 12) | Medium, accepted and disclosed |
| R17 | **Backup on a team member's personal machine** | Medium | Medium: theft, shared use, loss | Encrypted repository; password held by two people; written device-security rule; pull model so the server cannot reach or delete it; uptime monitor | Medium: depends on a person |
| R18 | **Operator's phone holds call history of committee contacts** | Medium | Medium | Team phone preferred; do not save contacts; delete call-history entries; offboarding step | Medium |
| R19 | **Mail provider sees admin addresses and message text** | Medium | Low | Mail carries only account notices; no evidence; no listener data | Low |
| R20 | **Misuse for targeting** (a hostile authority obtains the host's data or compels an Operator) | Low | High | Minimal retention; deletion at 90 days; no listener data; legal-request procedure to be written | Medium [LAWYER] |

## 12. Data flow: the listener read path

**By design, the listener read path processes no personal data.** The app searches for Masjids on the phone; the phone only downloads static files. There are no accounts, no location sent, no identifiers, no follows on the server. The server never receives coordinates finer than a cell of about 5 km (FR-011, FR-003).

**But IP addresses are visible to the host.** When a phone downloads a file, the phone connects to our server, so the **server operator and the server's hosting provider can see the phone's IP address and the time it connected**. The network between them (the phone's mobile operator or Wi-Fi provider) can see that the phone connected to our server. Under GDPR an IP address is personal data; so while we hold none, the host sees some in transit. We say this plainly.

| Layer | Sees | Our policy |
|-------|------|------------|
| Our web server on the data host | Address, time and file path (which names the cell) | **No access log at all** on the data host, so no address-and-cell pair is ever written (FR-027). Error logs have addresses masked. Tested with a known address |
| Our metrics | Aggregate counts per host and status code | No per-cell label, no address label |
| Operating system and firewall | Connection tracking, system logs | No logging rules on port 443; system log for the web service is in memory only; no intrusion-ban tool on the data host |
| The VPS provider's network | Address, time, volume, the host name asked for | Cannot be switched off by us. Provider chosen by its retention policy and named publicly. File sizes are padded to fixed classes (64, 128, 256 and 512 KB) so size does not reveal the cell |
| The listener's own network | That the phone connected to our server | Disclosed; a VPN or Tor helps |
| A third-party CDN | Would add another recipient | **Not used** |
| Public write routes (suggestions, abuse reports) | Address, for a moment | A keyed hash with a salt that changes daily, held in memory only, expiring within 1 hour; never in the database, logs or backups; a test checks this |

Wording for the listener privacy statement and the first-download consent screen (r5 section 5; the exact text is a [LAWYER] review item):

> "When you download Masjid data your phone connects to our server, so the server operator and the server's hosting provider can see your IP address and when you connected. We do not log which area you download, we never ask for your location, and we keep no account or follow list. Your internet provider and network can see that you connected to our server. Use a VPN or Tor if that matters to you."

The consent screen offers "Download this area", "Download whole country" (reveals only the country), and "Not now". The app works without any download (Phase 0 behaviour).

Store privacy labels: the honest default is "approximate location and IP address, used for app functionality, not linked to you, not used for tracking", unless the store's "processed in real time and not retained" exemption fits, which holds only if no log keeps the address (research R-07, R-17). Verify against the live store wording when writing the labels (UNVERIFIED).

**Admin and Operator path (for contrast)**: personal data is processed: sections 4 to 11.

## 13. Residual risk and sign-off

| Question | Draft answer |
|----------|--------------|
| Are any risks High after mitigation? | None rated High residual in this draft. Several are Medium (R1, R2, R4, R10, R12, R14, R16, R17, R18, R20) |
| Is prior consultation with the authority needed (Art. 36)? | Only if a risk remains High. Not expected; [LAWYER] decides |
| Is a DPO needed (Art. 37)? | Open question 10 |
| Is an EU or UK representative needed (Art. 27)? | Depends on the controller's location (open question 2) |
| Do other laws apply (for example UK GDPR, India's DPDP Act 2023, others)? | UNVERIFIED. Depends on where admins and the controller are |

Sign-off (all blank until the review is done):

| Role | Name | Decision (approve, approve with conditions, reject) | Conditions | Date | Signature |
|------|------|-----------------------------------------------------|-----------|------|-----------|
| Controller representative (owner) | `<...>` | | | | |
| Operator lead | `<OPERATOR_LEAD>` | | | | |
| Engineering lead | `<...>` | | | | |
| Lawyer or DPO [LAWYER] | `<DPO_OR_CONTACT>` | | | | |

## 14. Review cadence

Review this DPIA:

- Before launch (the first admin sign-up).
- At the start of Phase 2: broadcast rights raise the value of Verified, so the risk changes.
- Every 12 months.
- After any breach or serious near miss.
- After any change to the upload pipeline, evidence storage, retention periods, the mail route, the host or the backup location.
- When the controller, the host country or the law changes.

Each review records the date, the reviewer, what changed and the new residual ratings.

## 15. Breach notification steps

(Operator runbook, section 18, has the full steps for Operators. This is the legal frame.) [LAWYER]

1. **Detect and contain** at once: suspend accounts, block the route, rotate secrets. Do not delete logs.
2. **Assess within 24 hours**: what data, whose, how many, likely harm.
3. **Notify the authority within 72 hours** of becoming aware when the breach is likely to put people's rights at risk (Art. 33; the text was not re-read live when this was written, UNVERIFIED). Late notification must be explained. If details are missing, notify in stages.
4. **Notify affected people without undue delay** when the risk is high (Art. 34): plain language, what happened, what data, what we did, what they can do, who to contact.
5. **Record every breach** in the breach register, including those not notified, with the reasons.
6. **Review within 14 days** (PROPOSED), then update this DPIA.
7. A processor (host, relay) that detects a breach must tell us without delay: put this in each processor agreement.

Special attention: the people involved can be linked to a place of worship, so the severity of a leak is rated high.

## 16. Open legal questions

| # | Question | Why it matters | Who |
|---|----------|----------------|-----|
| 1 | Who is the controller (a legal entity or individuals)? Is one needed before launch? | Every duty and every contract depends on it | Owner, [LAWYER] |
| 2 | Which laws apply: EU or UK GDPR through the host or the admins, the DPDP Act 2023 and others by where admins and the controller are? Is an Art. 27 representative needed? | Notice content, authority, transfers | [LAWYER] |
| 3 | Is data about a person's role in a Masjid, and a building photo, special-category data under Art. 9? Which ground for admins and for contacts? | Basis and consent design | [LAWYER] |
| 4 | Is a spoken Art. 14 notice on the verification call enough, with a written notice link by email? What if there is no email? | The notice duty to committee contacts | [LAWYER] |
| 5 | Is keeping a keyed fingerprint of rejected evidence for 12 months lawful, and does an erasure request override it? Does a data export include evidence images and the contacts the admin supplied? | Blocker for "identical evidence stays rejected" (FR-016.9); third-party data in access requests | [LAWYER] |
| 6 | Retention of the audit log (24 months), access events (12 months after purge), Operator mapping (employment plus 24 months), privacy-request records and the breach register: acceptable? | Retention table | [LAWYER] |
| 7 | Are audit entries with the link removed truly anonymous? Pseudonymous data is personal data until the mapping is gone | Erasure promise | [LAWYER] |
| 8 | Do encrypted database backups kept up to 30 days after erasure meet the erasure duty ("beyond use")? What notice wording? | Backup design | [LAWYER] |
| 9 | Legitimate-interest assessment for sign-in security logs with network addresses (30 days raw, 12 months truncated) | Basis | [LAWYER] |
| 10 | Is a DPO required (Art. 37)? Is prior consultation (Art. 36) needed? | Governance | [LAWYER] |
| 11 | Processor agreements with the VPS host, the relay (if used), and treatment of the team member who holds backups | Art. 28 | [LAWYER] |
| 12 | Are transfers involved: Operators abroad, the relay, the backup machine location? Which mechanism? | Chapter V | [LAWYER] |
| 13 | Is the host (and the mobile operator) a controller or processor for network addresses of listeners? What must the listener privacy statement and the store labels say? | The "no personal data by design" claim | [LAWYER] |
| 14 | Procedure for a legal request or compulsion from an authority; any legal hold beyond appeals | Risk R20 | [LAWYER] |
| 15 | Calling committee members in other countries: call-recording rules, telecom or marketing rules, working hours | Verification calls | [LAWYER] |
| 16 | Operator confidentiality duty, code of conduct and use of personal devices | Insider risk | [LAWYER] |
| 17 | Which authority to notify in a breach, and the 72-hour clock when several apply | Breach plan | [LAWYER] |
| 18 | Terms for admins: acceptable use and the licence of admin-entered data, with the ODbL carve-out | Open licence boundary (spec clarification) | [LAWYER] |
| 19 | Complaints and the 30-day commitment: is it fine to commit to 30 days where the law gives "one month, extendable"? | Wording | [LAWYER] |

## 17. Policy documents the project must publish

Owner is a role, to be named. "Due before launch" uses these checkpoints: **A** = before the first admin signs up; **B** = before the first claim is reviewed; **C** = before the app release that downloads data (store privacy-policy page needed); **D** = before launch review (Phase 1 close). All boxes are unchecked.

| Done | Document | Content | Owner | Due before launch |
|:----:|----------|---------|-------|-------------------|
| [ ] | Privacy notice for admins and Muazzins | What we hold, why, basis, retention, rights, backups, recipients, transfers, complaints [LAWYER] | `<OWNER: Controller>` | A |
| [ ] | Listener privacy statement | No collection; honest network disclosure (section 12); store policy page on GitHub Pages [LAWYER] | `<OWNER: Controller>` | C |
| [ ] | Store privacy-policy page and label answers | Matches the statement and the live store wording (UNVERIFIED) | `<OWNER: Engineering lead>` | C |
| [ ] | Notice for committee contacts (Art. 14) | Written version of the spoken notice; published at `<PRIVACY_URL>` [LAWYER] | `<OWNER: Operator lead>` | B |
| [ ] | Verification-evidence policy | What is collected and why, images only, 90 days, appeal holds, backups, how to ask for earlier deletion | `<OWNER: Operator lead>` | A |
| [ ] | Data retention schedule | Section 7, kept in sync with the code | `<OWNER: DPIA owner>` | A |
| [ ] | Cookie and session statement | One strictly necessary session cookie for admins and Operators; none for listeners | `<OWNER: Engineering lead>` | A |
| [ ] | Terms for admins | Acceptable use; licence of admin-entered data; ODbL carve-out; suspension and revocation [LAWYER] | `<OWNER: Controller>` | A |
| [ ] | OpenStreetMap and ODbL attribution, `LICENSES` and `NOTICE` | Attribution in the app and console; share-alike publication of the derived fields | `<OWNER: Engineering lead>` | C |
| [ ] | Security policy | `SECURITY.md`, `security.txt`, coordinated disclosure, no bounty | `<OWNER: Engineering lead>` | A |
| [ ] | Data breach response plan | Section 15 and operator runbook section 18, with a register template | `<OWNER: Operator lead>` | B |
| [ ] | Data-subject request procedure | Operator runbook section 15, 30 days, day-20 reminder | `<OWNER: Operator lead>` | B |
| [ ] | Operator onboarding documents and call script | [operator-runbook.md](operator-runbook.md) (FR-028); proven by the dry run | `<OWNER: Operator lead>` | B |
| [ ] | Operator code of conduct and offboarding | Confidentiality, device rules, leaving checklist [LAWYER] | `<OWNER: Operator lead>` | B |
| [ ] | Sub-processor list | Section 9, published | `<OWNER: DPIA owner>` | A |
| [ ] | Audit and log policy | What is logged, who reads, retention (section 7) | `<OWNER: Engineering lead>` | A |
| [ ] | Moderation and appeals policy | Reasons, one appeal, timelines, no discrimination | `<OWNER: Operator lead>` | A |
| [ ] | Accepted-deviation record for upload scanning | No antivirus scan on a small server; compensating controls (research R-14) | `<OWNER: Engineering lead>` | D |
| [ ] | DPIA summary (public) | A plain-language summary of this document | `<OWNER: DPIA owner>` | D |
| [ ] | Restore and backup procedure | [restore-runbook.md](restore-runbook.md); proven by the timed drill | `<OWNER: Engineering lead>` | D |

## 18. Items that must be decided before launch

| # | Decision | Where |
|---|----------|-------|
| 1 | Fingerprint rule for identical evidence (keep 12 months, or drop the rule) | Open question 5; spec FR-016.9 |
| 2 | Backup retention: 30 days (this DPIA) versus 14 daily, 8 weekly, 6 monthly (research R-22) | Section 7 |
| 3 | Suggestion for a new Masjid: the app sends a 5 km cell and typed text; an Operator places the pin | Research R-17; owner decision in the plan |
| 4 | Mail route: self-hosted or relay | Section 9 |
| 5 | Who is the controller and where | Open questions 1 and 2 |
| 6 | Evidence key custody beyond the server (Phase 1.5 option) | Research R-13; revisit at the review for Phase 2 |

## 19. Related technical facts (for the reviewer)

- Security standard targeted: OWASP ASVS 5.0.0 at Level 2. The antivirus requirement (5.4.3) is a recorded deviation.
- Evidence encryption: AES-256-GCM per file, a random key per file wrapped by a key-encryption key, with the file id, claim id and key id as authenticated data. Keys sit in a secrets file encrypted to two people's `age` keys plus the server's.
- Deletion: key destroyed first, then rows, then the file. Later restores rerun the deletion job; cases whose file is missing show "evidence missing, request re-upload".
- Audit: append-only, hash-chained; the head hash is anchored daily off the server; a nightly job verifies it.
- Constitution principles engaged: 4 (privacy by design), 5 (broadcast security and trust), 8 (testing and quality gates), 9 (simplicity), 10 (open source and zero cost).

---

## Validation

| What is proven | By | Status |
|----------------|----|--------|
| Legal soundness: bases, Art. 9, Art. 14 notice, retention, transfers, processor terms, breach clock, rights timeline, wording of every notice | **Legal review** [LAWYER], answering the 19 open questions in section 16 | Not started. This document must not be treated as final until it is done |
| Technical claims (images only, key destruction, backups without evidence, no access log on the data host, rate-limit keys never on disk, audit coverage) | Automated tests and the timed **restore drill** ([restore-runbook.md](restore-runbook.md)); the traffic test for SC-004; the **Operator dry run** for evidence-view rules and audit coverage | Not yet run; the system is not built |
| Operator procedures that apply this DPIA (notice on calls, deletion requests, incident steps) | The **Operator dry run** ([operator-runbook.md](operator-runbook.md), section 24) | Not yet run |
| Risk ratings and residual risk | A second reviewer (not the author) and the legal review; revisit after the pilot's first month and at the Phase 2 review | Not started |

Still open: every `<PLACEHOLDER>` in the table at the top, the 19 legal questions, the six decisions in section 18 that need an owner, publishing the 20 documents in section 17, and the sign-off block (section 13).
