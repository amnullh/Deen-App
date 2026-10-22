# Feature Specification: Masjid Directory, Verification and Masjid Schedules (Phase 1)

**Feature Branch**: `002-masjid-directory-verification`

**Created**: 2026-10-22

**Status**: Draft. Planning only: under constitution principle 9, building starts when Phase 0 meets its exit criteria.

**Input**: User description: "Build 'Deen App' Phase 1: the Masjid directory, the Masjid claim and verification process, Masjid-specific prayer schedules, and the operator console. The Phase 0 app already exists and works offline. Phase 1 adds an optional server. If the server is down, the app keeps working exactly as in Phase 0."

## Why

Prayer times from a formula rarely match what a specific Masjid actually announces. Later phases let a Masjid broadcast its Azaan live to phones, which is only safe if we know the Masjid is real. This phase creates the trusted list of Masjids and the people allowed to speak for them.

## Actors

- **Listener**: app user, no account.
- **Masjid Admin**: a verified person who manages one or more Masjids. Has an account with multi-factor sign-in.
- **Muazzin**: a person a Masjid Admin invites. Has an account but no listing rights. (Broadcast rights come in Phase 2.)
- **Operator**: Deen App team member who reviews claims and moderates.
- **Super-admin**: an Operator who manages other Operators.

## Clarifications

### Session 2026-10-22

- Q: Where does the initial directory come from? → A: OpenStreetMap places of worship tagged as Muslim (ODbL license). The attribution and share-alike obligations apply to the derived directory and are shown in the app and the console. The Two Holy Mosques and other major Masjids are curated by hand.
- Q: How does the app search nearby without sending location? → A: The server publishes static, cacheable files per region (cells of about 5 km, plus country files). The app downloads and searches them on the phone.
- Q: Is admin-entered data published under the OpenStreetMap license? → A: No. Only the OpenStreetMap-derived fields (names, locations, addresses) are published openly. Admin-entered schedules, photos and contact details are a separate layer under the project's own terms and are never exported in bulk.
- Q: How does an admin who lost both the authenticator and the recovery codes get back in? → A: An Operator phones a committee contact on file and a second Operator approves; a 48-hour delay applies, the admin and the committee contacts are notified, and all old sessions are closed.
- Q: Who can see committee members' phone numbers and emails collected in a claim? → A: Only the Operator assigned to an open case, and only while the case is open. Every view is logged, and the details are deleted with the evidence 90 days after the final decision.
- Q: How large may a region file be? → A: Under 500 KB per cell; dense cells are split into parts of the same cell that are always downloaded together (a finer cell would reveal a finer location); country files hold only a summary (names and coordinates of major Masjids).
- Q: How do admins sign in and recover? → A: Email, password and an authenticator-app code. No text messages and no social login. Password reset uses an email link. Resetting the second factor needs an Operator's approval plus a recovery code or a verification call.
- Q: How is email delivered? → A: Self-hosted mail with SPF, DKIM and DMARC, or a relay that is open source or permanently free; a free relay is recorded in the constitution's Exceptions Register.
- Q: How long is verification evidence kept? → A: 90 days after the final decision, longer only while under appeal.
- Q: How does renewal work? → A: Verification lasts 12 months, a reminder goes out 30 days before, there is a 30-day grace period, then the status drops to Pending (shown to listeners as "Claimed pending").
- Q: Who are the Operators at the start? → A: The founding team, at least 2 people so that review by a second person is possible. Operator onboarding documentation is a deliverable.
- Q: What map does the admin use to place a Masjid? → A: A map built on OpenStreetMap data from a self-hosted or free community tile source; if no free source can carry the pilot load, a simple list and a coordinate picker with no map background.
- Q: How are Masjid names stored? → A: In Arabic script, transliteration and the local language, with one primary display name.
- Q: Where does the admin and operator console live? → A: In a web app, separate from the mobile apps.
- Q: Which languages does the console support? → A: English first; other languages in Phase 4. All console text stays localizable.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Find and confirm my Masjid (Priority: P1)

A listener finds a Masjid by name, by "near me", or by browsing a country, city or region (including a curated list of the Two Holy Mosques and other famous Masjids), confirms it, and can follow several Masjids on the phone.

**Why this priority**: Every other story depends on a listener choosing a real, confirmed Masjid, and it must protect the listener's location.

**Independent Test**: Download one region, turn the network off, search nearby, confirm a Masjid, and inspect a recording of the network traffic taken while using the feature.

**Acceptance Scenarios**:

1. **Given** the listener types part of a name, **When** results appear, **Then** each shows the name, distance, a verification badge (Verified, Claimed pending, Unclaimed), the madhhab and calculation method if known, and the Azaan variant.
2. **Given** a downloaded region (static files of about 5 km cells plus country files) and no network, **When** the listener chooses "near me", **Then** nearby Masjids are listed using only data on the phone.
3. **Given** the listener browses a country, city or region, **When** they open the curated list, **Then** the Two Holy Mosques and other famous Masjids are findable.
4. **Given** a search result, **When** the listener has not confirmed it, **Then** the app does not use it for times or alerts; the app never picks a Masjid silently.
5. **Given** several confirmed Masjids, **When** the listener marks one as "my Masjid" or removes any, **Then** the change applies on the phone only and nothing about it is sent to the server.
6. **Given** any use of this feature, **When** network traffic is captured, **Then** no request carries coordinates finer than a 5 km cell, and text search sends only the text typed.

---

### User Story 2 - Use my Masjid's schedule (Priority: P1)

A confirmed Masjid supplies Azaan, Iqamah and Jumu'ah times that replace calculated times for alerts, with a way back to calculated times.

**Why this priority**: This is the reason the directory exists: the times people actually hear and follow.

**Independent Test**: Confirm a Verified Masjid whose schedule differs from the calculated times and check that the next alerts change within 5 seconds with no duplicates.

**Acceptance Scenarios**:

1. **Given** a confirmed Verified Masjid with a schedule, **When** the listener switches to it, **Then** Azaan, Iqamah and Jumu'ah times replace calculated times for alerts, and the next alert times and the on-device alerts from Phase 0 update in under 5 seconds with no duplicate alerts.
2. **Given** the schedule rules, **When** a Masjid defines times as fixed clock times, as calculated times plus offsets, or as Iqamah offsets after Azaan, **Then** each form produces the same displayed times everywhere in the app.
3. **Given** date-range rules (for example summer and winter) and several Jumu'ah shifts, **When** the date or shift changes, **Then** the right rule and every shift are shown.
4. **Given** the listener is online, **When** the schedule changes, **Then** the app holds the next 30 days, refreshes at the next opportunity, and marks changed times as "updated".
5. **Given** schedule data older than 30 days, **When** the listener opens the app, **Then** the app falls back to calculated times and says so.
6. **Given** the Masjid's time zone differs from the phone's, **When** times are shown, **Then** they follow the Masjid's own time zone and daylight saving, and the app clearly says the phone is elsewhere.
7. **Given** the listener switches back to calculated times, **When** the change is made, **Then** alerts follow the calculated times again.

---

### User Story 3 - Claim and verify a Masjid (Priority: P1)

A Masjid Admin signs up with strong credentials and multi-factor sign-in, claims or creates a Masjid, submits evidence, and an Operator verifies it by phone.

**Why this priority**: Verification is the trust foundation for everything that reaches listeners and for later broadcast rights.

**Independent Test**: Run a claim from sign-up to a Verified or Rejected decision and read the audit log.

**Acceptance Scenarios**:

1. **Given** a new Masjid Admin, **When** they sign up with an email and a strong password, **Then** they must set up multi-factor sign-in (an authenticator app code) and keep printable recovery codes before they can do anything else, and cannot reach any editing screen without it. No text message or social sign-in exists.
1a. **Given** an admin forgets their password, **When** they ask for a reset, **Then** an email link lets them set a new one. **Given** an admin loses their authenticator, **When** they ask to reset it, **Then** an Operator must approve, and the admin must present a recovery code or pass a verification call.
2. **Given** an unclaimed Masjid or a new one, **When** the admin claims or creates it, **Then** they submit committee or trust documents, an authorization letter, building photos and contact details of two committee members.
3. **Given** a complete claim, **When** an Operator reviews it, **Then** they verify by phone call to a committee contact, using no paid telephony or text-message service.
4. **Given** the statuses Unclaimed, Pending, Verified, Needs more information, Rejected, Suspended and Revoked, **When** a decision is made, **Then** the admin sees the status and the reason, and may appeal once.
5. **Given** more than one admin, **When** the Masjid is managed, **Then** several admins can manage it, ownership transfers only with an Operator's approval, and an admin can invite and remove Muazzins.
6. **Given** two claims on the same Masjid, **When** they conflict, **Then** both are held for Operator arbitration and neither claimant has edit rights until it is resolved.
7. **Given** a Verified Masjid, **When** 12 months pass, **Then** verification expires unless renewed; a reminder is sent 30 days before; after the 30-day grace period the status drops to Pending (shown to listeners as "Claimed pending") and its schedule is no longer offered.
8. **Given** any state change, **When** it happens, **Then** it is written to an audit log (with actor and time) that admins and Operators can read.
9. **Given** a claim was rejected, **When** identical evidence is submitted again, **Then** it stays rejected.
10. **Given** verification documents, **When** they are stored, **Then** they are encrypted, visible only to Operators, access-logged, and deleted 90 days after a final decision unless under appeal; admins may request earlier deletion.

---

### User Story 4 - Manage a Masjid's profile and schedule (Priority: P2)

An admin edits the Masjid's profile and schedule, previews it, and can roll changes back.

**Why this priority**: Keeps the listing and times accurate after verification.

**Independent Test**: Edit a Verified Masjid, see it appear for listeners, then roll the edit back.

**Acceptance Scenarios**:

1. **Given** an admin of a Verified Masjid, **When** they edit names (in Arabic script, in transliteration and in the local language, with one primary display name), address, location (a pin on a map, or coordinates when no free map source can carry the load), photos, languages spoken, madhhab, calculation method, Azaan variant, contact details and facilities, **Then** the changes go live immediately.
2. **Given** a schedule edit, **When** the admin previews it, **Then** the next 14 days are shown and impossible values (for example Iqamah before Azaan) are warned about.
3. **Given** a Pending Masjid, **When** a listener looks it up, **Then** only its name and location appear, marked unverified.
4. **Given** any change, **When** it is saved, **Then** it is versioned and can be rolled back.

---

### User Story 5 - Operator console (Priority: P2)

Operators review claims, moderate, search, and respond to abuse, with strict roles and audit.

**Why this priority**: Without it, claims cannot be decided and abuse cannot be handled.

**Independent Test**: Decide a claim, suspend a Masjid, handle an abuse report and perform a two-person recovery, then check the audit trail.

**Acceptance Scenarios**:

1. **Given** the review queue, **When** an Operator filters it and opens a case, **Then** they see the evidence, add notes and decide with a required reason.
2. **Given** a search term, **When** an Operator searches, **Then** they can find any Masjid, admin, Muazzin or audit event, and suspend or revoke a Masjid or a person immediately.
3. **Given** an abuse report (wrong information, fake Masjid, impersonation), **When** it is handled, **Then** it moves through a defined status workflow.
4. **Given** the roles reviewer, moderator and super-admin, **When** an Operator acts, **Then** they can only do what their role allows, sign in with multi-factor authentication, and every action is audited.
5. **Given** a Masjid whose admins are locked out, **When** a super-admin starts recovery, **Then** it completes only with a second person's approval.

---

### User Story 6 - Directory seeding and quality (Priority: P2)

The directory starts from open data and stays clean through moderation.

**Why this priority**: A useful directory needs breadth on day one without implying false trust.

**Independent Test**: Import a sample region, merge a duplicate, accept a suggestion, and view the attribution in the app and the console.

**Acceptance Scenarios**:

1. **Given** an import from OpenStreetMap places of worship tagged as Muslim, **When** Masjids appear, **Then** they are Unclaimed and clearly labeled as unverified information.
2. **Given** duplicates and near-duplicates, **When** they are detected, **Then** Operators can review and merge them.
3. **Given** a listener suggests a correction or a new Masjid, **When** it is submitted, **Then** it is moderated and rate-limited.
4. **Given** the curated list of major Masjids, **When** it is published, **Then** each entry is hand-verified with recorded sources.
5. **Given** imported data, **When** it is shown, **Then** the OpenStreetMap attribution and the ODbL license notice appear in the app and in the console, and the OpenStreetMap-derived fields of the directory are published openly so the license's share-alike obligation is met; admin-entered schedules, photos and contacts are kept as a separate layer and are not part of that publication.

---

### User Story 7 - Admin lifecycle and data requests (Priority: P3)

Admins and Muazzins control their own data, and Operators handle privacy requests on time.

**Why this priority**: Required for trust and law, but fewer people use it daily.

**Independent Test**: Delete an admin account and export a Muazzin's data, then close a privacy request.

**Acceptance Scenarios**:

1. **Given** an admin deletes their account, **When** it completes, **Then** personal data is removed while the Masjid listing and audit entries remain, anonymized.
2. **Given** an admin or Muazzin asks for their data, **When** they export, **Then** they receive their own data.
3. **Given** a privacy request, **When** an Operator handles it, **Then** a documented process is followed and the request is answered within 30 days.

---

### Edge Cases

- The server is unreachable or slow: every Phase 0 feature, alerts, and already-downloaded regions and schedules keep working.
- A listener confirms a Masjid, then it is suspended, revoked or its verification expires: the app keeps the last good schedule until it expires in 30 days, tells the listener the status changed, and offers calculated times.
- Two admins edit the same schedule at once, or an edit conflicts with a rollback.
- A schedule rule has overlapping or missing date ranges, or a Jumu'ah shift on a non-Friday.
- A Masjid has no time zone data, or its time zone changes its daylight-saving rules.
- A region download is interrupted, partly stored, or newer data arrives while an older pack is in use.
- An admin loses the authenticator device and the recovery codes.
- A claim is submitted for a Masjid that is already Verified, Suspended or Revoked.
- A Masjid Admin who is also invited as a Muazzin elsewhere.
- A listener's phone is in a different country or time zone than the Masjid.
- A suggestion flood from one source; a duplicate of an existing Masjid.
- Evidence files that are unreadable, too large, or malicious.
- A 12-month renewal reminder when the admin's email address no longer works.
- Operators who leave the team: access removal and reassignment of open cases.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Phase 0 behavior MUST NOT regress, and the app MUST work when the server is unreachable.
- **FR-002**: Listeners MUST NOT need an account for anything in this phase.
- **FR-003**: The server MUST NOT store listener location, identifiers or follows.
- **FR-004**: Admin and Operator accounts MUST require multi-factor sign-in.
- **FR-005**: Only Verified Masjids MAY show schedules and be eligible for later broadcast rights.
- **FR-006**: Every state change on a Masjid or account MUST be audited with actor and time.
- **FR-007**: All user-facing text, including the console, MUST be localizable. The console MUST meet WCAG 2.1 AA.
- **FR-008**: Verification documents MUST be encrypted at rest, access-logged, visible only to Operators and automatically deleted 90 days after a final decision (unless under appeal).
- **FR-009**: The app MUST find Masjids by name, by nearby, and by browsing a country, city or region, and MUST include a curated list of major Masjids.
- **FR-010**: The app MUST NOT use a Masjid until the listener confirms it, and MUST let the listener follow several, mark one as "my Masjid" and remove any, with follows stored on the phone only.
- **FR-011**: Nearby search MUST work from downloadable regional directory data kept on the phone, with no location sent to the server; no network request MAY carry coordinates finer than a 5 km cell.
- **FR-012**: The directory MUST work offline once a region has been downloaded.
- **FR-013**: A Masjid schedule MUST support fixed times, calculated-plus-offset times, Iqamah-after-Azaan offsets, date-range rules and multiple Jumu'ah shifts, interpreted in the Masjid's time zone.
- **FR-014**: The app MUST cache the next 30 days of a confirmed Masjid's schedule, refresh when online, mark updated times, and fall back to calculated times (saying so) when the data is older than 30 days.
- **FR-015**: Switching to or from a Masjid schedule MUST update the next alerts within 5 seconds and MUST NOT create duplicate alerts.
- **FR-016**: Claims MUST follow the statuses Unclaimed, Pending, Verified, Needs more information, Rejected, Suspended and Revoked, with reasons shown to the admin and one appeal; a rejected claim MUST stay rejected when identical evidence is submitted again.
- **FR-017**: Verification MUST include an Operator phone call and MUST NOT use a paid telephony or text-message service; it MUST expire after 12 months with a reminder 30 days before and a 30-day grace period, after which the status drops to Pending and the Masjid's schedule is no longer offered.
- **FR-018**: Conflicting claims MUST be held for Operator arbitration, with no edit rights for either claimant until resolved; ownership transfer MUST require Operator approval.
- **FR-019**: Admin edits to a Verified Masjid MUST go live immediately and be versioned with rollback; a Pending Masjid MUST show listeners only its name and location, marked unverified.
- **FR-020**: Schedule edits MUST preview the next 14 days and warn about impossible values.
- **FR-021**: The operator console MUST provide a review queue, evidence viewer, notes, required decision reasons, global search, immediate suspend/revoke, an abuse-report workflow, role-based access and audited actions, with a two-person break-glass recovery.
- **FR-022**: Imported directory entries MUST be labeled Unclaimed and unverified, duplicates MUST be detected and merged by Operators, and listener suggestions MUST be moderated and rate-limited.
- **FR-023**: Data attribution and license notices MUST be shown in the app and the console.
- **FR-024**: Admins MUST be able to delete their account (anonymizing audit entries and keeping the listing) and export their own data; Operators MUST answer privacy requests within 30 days.
- **FR-025**: The server MUST cost no more than the stated pilot budget to run, and every component MUST follow the constitution's open-source, zero-licensing-cost rule.
- **FR-026**: Admin sign-in MUST use email, password and an authenticator-app code; a password reset MUST use an email link; resetting the second factor MUST need an Operator's approval plus a recovery code or a verification call. When both the authenticator and the recovery codes are lost, recovery MUST need a verification call to a committee contact on file, approval by a second Operator, a 48-hour delay with notification to the admin and the committee contacts, and closing of all old sessions.
- **FR-027**: Server access logs MUST NOT pair a listener's network address with the region files they request.
- **FR-028**: Operator onboarding documentation (roles, review procedure, phone-call verification script, privacy handling, break-glass) MUST be delivered before the first Operator reviews a claim.
- **FR-029**: The location picker MUST work without a map background (a list and a coordinate entry) when no free map source can carry the pilot load.
- **FR-030**: Masjid names MUST support Arabic script, transliteration and the local language, with one primary display name.
- **FR-031**: Exports of the directory for open publication MUST contain only OpenStreetMap-derived fields; admin-entered schedules, photos and contact details MUST NOT be included in any bulk export.
- **FR-032**: Committee members' contact details collected in a claim MUST be visible only to the Operator assigned to the open case, only while the case is open; every view MUST be logged; the details MUST be deleted with the evidence 90 days after the final decision.
- **FR-033**: Each region file MUST be under 500 KB; a cell that would exceed it MUST be split into numbered parts of the same cell that the app always downloads together, so that no request reveals anything finer than the cell; a country file MUST hold only a summary of major Masjids.

### Key Entities

- **Masjid**: a listed place of worship: names in Arabic script, transliteration and the local language with one primary display name, address, location, photos, languages spoken, madhhab, calculation method, Azaan variant, contacts, facilities, status, source (imported, curated, claimed), version history.
- **Schedule**: a Masjid's times: rules by date range, each time defined as fixed, calculated-plus-offset or Iqamah-after-Azaan; Jumu'ah shifts; the Masjid's time zone; a version and a last-updated time.
- **Region Pack**: a static, cacheable file of directory data for a cell of about 5 km or for a country, kept on the phone, with a version and the OpenStreetMap license notice.
- **Follow**: a listener's choice of a Masjid, including "my Masjid"; stored on the phone only.
- **Account**: an admin, Muazzin or Operator with an email, strong password, multi-factor method and recovery codes, and a role.
- **Claim**: an admin's request to manage a Masjid, with status, evidence, reviewer notes, decision reason, appeal and expiry.
- **Evidence Document**: an uploaded file for a claim, encrypted, with access log and deletion date.
- **Invitation**: a Masjid Admin's invitation of a Muazzin or another admin.
- **Audit Entry**: who did what to what, and when, for every state change.
- **Abuse Report / Suggestion**: a listener's report or proposed correction, with a moderation status.
- **Privacy Request**: an export or deletion request with deadline and outcome.

## Constitution Check

Principles that apply to this phase (constitution v1.2.0) and how the requirements meet them:

| Principle | How this spec meets it |
|-----------|------------------------|
| 1 Local-first reliability | FR-001, FR-012, FR-014: the server is optional; schedules and regions are cached on the phone |
| 2 Platform honesty | Region downloads and cached schedules use ordinary storage and network access; platform claims are cited in the plan |
| 3 User consent and respect | FR-010: the listener always confirms a Masjid; the app shows madhhab, method and Azaan variant |
| 4 Privacy by design | FR-002, FR-003, FR-011: no accounts, no stored listener location or follows, no coordinates finer than 5 km |
| 5 Broadcast security | FR-004, FR-005, FR-016 to FR-018: multi-factor sign-in, human verification and Verified-only eligibility prepare Phase 2 |
| 7 Religious and cultural correctness | FR-013: madhhab, calculation method and Azaan variant are first-class fields and Masjid times override calculated times only with confirmation |
| 8 Testing and quality gates | Success criteria SC-001 to SC-008 are measurable, including a captured-traffic test and a restore drill |
| 9 Simplicity and scope control | Out of Scope below; planning now, building after Phase 0 exits |
| 10 Open source and zero cost | FR-017, FR-023, FR-025; see Infrastructure Cost |
| 11 Accessibility and localization | FR-007 for the app and the console |
| 6 Audio quality and delivery | Not applicable (no audio in this phase) |

## Infrastructure Cost

This phase adds a server, so it has a recurring cost, unlike Phase 0. It MUST run on a single modest virtual server (constitution principle 10) and serve up to 50,000 listeners per day reading directory data (SC-005).
The monthly cost ceiling for the pilot is US$10 per month, decided by the product owner on 2026-10-22. The ceiling covers the server, its backups and storage, and excludes the store developer fees already listed in the constitution's Exceptions Register.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A listener finds and confirms a Masjid in under 60 seconds.
- **SC-002**: A complete claim is reviewed within 5 working days (a service target the operations team commits to).
- **SC-003**: With the server fully offline, 100% of Phase 0 features still work.
- **SC-004**: No network request from the app carries coordinates finer than a 5 km cell, verified by a captured-traffic test.
- **SC-005**: Server cost stays within the pilot budget of US$10 per month on one modest virtual server, for up to 50,000 listeners per day reading directory data.
- **SC-006**: Recovery from a full server loss takes under 4 hours using backups, practiced once before the phase closes.
- **SC-007**: Switching to a Masjid schedule updates the next alerts within 5 seconds with no duplicate alerts, on the supported device matrix.
- **SC-008**: Every state change on a Masjid or account has an audit entry (100%), and no admin or Operator reaches a protected screen without multi-factor sign-in (0 exceptions in testing).

## Assumptions

- Operators exist and will perform reviews; verification requires a human phone call.
- The first pilot has 3 to 5 Masjids with willing committees.
- The initial directory comes from OpenStreetMap (ODbL). Only the fields derived from it are published openly; admin-entered data is a separate layer. A licensing review in planning confirms exactly which fields count as derived and how region files combine the two layers.
- A region is a country or a documented subdivision of one, sized so a typical download is small enough for mobile data; the exact packaging is a planning decision.
- Reminders to admins (for example the 12-month renewal) are sent by email; no push notifications exist yet. Email comes from a self-hosted mail setup (with SPF, DKIM and DMARC) or from a relay that is open source or permanently free (recorded in the Exceptions Register). Whether a $10 server can deliver mail reliably is checked in planning.
- Hardware security keys are not required in this phase.
- The listener app remains available in English, Arabic, Urdu and Bahasa Indonesia. The admin and operator console is a web app, separate from the mobile apps, in English at launch; other languages arrive in Phase 4, and all console text stays localizable.
- Operators are initially the founding team, at least 2 people.
- Phase 0's alert planner and settings are the integration point: a Masjid schedule is supplied to the existing planner as times for the five prayers.

## Out of Scope

Live audio, push notifications, broadcaster tools, community posts, Quran features, payments, listener accounts.
