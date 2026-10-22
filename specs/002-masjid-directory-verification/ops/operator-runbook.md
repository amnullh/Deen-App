# Operator Runbook and Onboarding Guide (Phase 1)

**Status**: DRAFT 0.1, 2026-10-22. **Owner**: <OPERATOR_LEAD>. **Spec**: [../spec.md](../spec.md) (FR-028 deliverable), decisions in [../research.md](../research.md).

> **Needs validation.** Nothing in this document is proven yet. It is proven by the Operator dry run (section 24): two Operators must complete every path from this document alone, with no help from the authors. Items marked PROPOSED are working rules this draft suggests because the spec is silent; the dry run confirms or changes them. Items marked [LAWYER] need a lawyer or data-protection adviser. Items marked UNVERIFIED are facts nobody has checked yet. No Operator may review a real claim until this document is final and the dry run has passed (FR-028).

How to read the marks:

| Mark | Meaning |
|------|---------|
| [LAWYER] | Needs legal review before it is relied on |
| UNVERIFIED | A fact we have not confirmed from a primary source |
| PROPOSED | A working rule from this draft, not yet in the spec; confirm in the dry run |
| `<PLACEHOLDER>` | A name, address or decision not made yet; fill in (table below) |

## Fill in before use

| Placeholder | What it is | Value | Decided by |
|-------------|-----------|-------|------------|
| `<DOMAIN>` | The project's domain. The console is expected at `console.<DOMAIN>` (research R-01) | not decided | Owner |
| `<OPERATOR_LEAD>` | The person who owns this document and the service targets | not decided | Owner |
| `<OPERATOR_1>`, `<OPERATOR_2>`, ... | Names of the founding-team Operators and their roles (section 1) | not decided | Owner |
| `<CALL_METHOD>` | How Operators place verification calls without a paid telephony service (own phone, team phone, free calling app) and whether the caller number is shown | not decided | Owner |
| `<TEAM_CHAT>` | The private channel Operators use to coordinate. It must never carry evidence, phone numbers or codes | not decided | Owner |
| `<OPS_MAILBOX>` | The shared team mailbox that receives replies and security notices (the server has no inbound mailbox) | not decided | Owner |
| `<PRIVACY_EMAIL>` | Address for privacy requests | not decided | Owner |
| `<SECURITY_EMAIL>` | Address for security reports (also in `security.txt`) | not decided | Owner |
| `<PRIVACY_URL>` | Public page with the privacy notice and the committee-contact notice | not decided | Owner, [LAWYER] |
| `<CONTROLLER_NAME>` | Legal name of the organisation responsible for the data | not decided | Owner, [LAWYER] |
| `<AUTHORITY_NAME>` | The data-protection authority to notify in a breach | not decided | [LAWYER] |
| `<LAWYER_CONTACT>` | Who to call for legal questions and incident advice | not decided | Owner |
| `<WORKING_DAYS_RULE>` | Which days count as working days for the 5-day target, and the list of public holidays used | not decided | Owner |
| `<TEAM_TIMEZONE>` | Time zone used to read deadlines | not decided | Owner |
| `<KEY_HOLDER_1>`, `<KEY_HOLDER_2>` | The two people who hold the `age` key and the backup password (see [restore-runbook.md](restore-runbook.md)) | not decided | Owner |
| `<SERVER_ACCESS_PERSON>` | Who can log in to the server for an incident | not decided | Owner |

---

## 0. What an Operator does, in one page

- You decide whether a Masjid claim is real. You do it by reading the evidence and, most important, by **phoning people who know the Masjid**. Documents alone never prove a claim.
- You handle abuse reports, listener suggestions, duplicates and the OpenStreetMap import.
- You answer privacy requests within 30 days.
- You help admins who are locked out, using the recovery procedures here.
- Every action you take is written to an audit log with your name and the time. Assume someone will read it.
- You handle very private data: committee members' names and phone numbers, and photos or scans of Masjid papers. Section 8 and section 9 are the rules for that. If a rule here and your habit disagree, follow the rule.
- You never need to be technical for most of this. The technical parts (server, backups, keys) are in the restore runbook and are for the people named as key holders.

Two Operators are the minimum, so that one can review the other's work (spec clarification, 2026-10-22).

## 1. Roles and what each may do

There are three Operator roles (FR-021). Rules for what each role may do are enforced by the console. The suspend, reinstate, revoke, arbitration, break-glass and unlock rows are fixed by the API contract. The other rows are PROPOSED. The authoritative table is the authorization policy in the code (research R-02); if the two differ, the code wins and this page is corrected.

| Action | Reviewer | Moderator | Super-admin |
|--------|:--------:|:---------:|:-----------:|
| Search any Masjid, admin, Muazzin or audit event | Yes | Yes | Yes |
| Read the audit log (your reads are logged too) | Yes | Yes | Yes |
| Open the review queue and take a claim case | Yes | No | Only to be assigned |
| View evidence and committee contacts of a case | Only if assigned to it, case open, step-up done | No | Only if assigned to it. There is no automatic read right |
| Add case notes | Yes | Abuse and suggestion items only | Yes |
| Record the phone call and its outcome | Yes (assigned case) | No | Yes (assigned case) |
| Decide a claim: Verified, Needs more information, Rejected | Yes (assigned) | No | Yes (assigned) |
| Decide an appeal (must be a different Operator than the first decision) | Yes | No | Yes |
| Arbitrate conflicting claims (arbitration decisions) | Yes | No | Yes |
| File a fraud flag task for a moderator (when you suspect fraud) | Yes | n/a | Yes |
| Approve a second-factor reset (not for your own account) | Yes | No | Yes |
| Start break-glass recovery and log its verification call | No | No | Yes (only) |
| Approve break-glass as the second Operator (never the initiator, never a moderator) | Yes | **No** | Yes (if not the initiator) |
| Suspend a Masjid or a person | **No** (a reviewer never suspends; file a flag task instead) | Yes | Yes |
| Reinstate a Masjid or a person after a suspension | No | Yes | Yes |
| Revoke a Masjid or a person | Yes | No | Yes |
| Triage abuse reports | View | Yes | Yes |
| Moderate suggestions, merge duplicates | No | Yes | Yes |
| Review an OpenStreetMap import diff | No | Yes | Yes |
| Publish an approved OpenStreetMap import | No | No | Yes |
| Handle privacy requests | No | Yes | Yes |
| Unlock a locked admin or Muazzin account | Yes | Yes | Yes |
| Unlock a locked Operator account | No | No | Yes |
| Create, change or remove Operators | No | No | Yes |
| Hold the keys for the server (see restore runbook) | Only if named | Only if named | Only if named |

Roster (fill in): | `<OPERATOR_1>`: ... | `<OPERATOR_2>`: ... |

Rules that apply to everyone:

1. You cannot approve your own request, your own reset or your own decision on a case you also handled for an appeal.
2. Super-admins have **no automatic right to read evidence**. If a super-admin needs to see a case, the case is assigned to them first, and that is logged.
3. Both founders hold the super-admin role. A break-glass needs a super-admin to start it and a **different** reviewer or super-admin to approve; a moderator can never approve it. So the Operator team must always include at least two people who can approve: if only the two founders exist, each can approve the other's break-glass. If a third Operator joins as a moderator only, that does not change who can approve. Open point 1 in section 25.
4. A reviewer who suspects fraud does **not** suspend. They file a flag task; a moderator or super-admin decides on the suspension.

## 2. First-day checklist (new Operator)

A super-admin creates your account and sends an invitation by email. You do the rest. Tick each box.

- [ ] I received the invitation email and opened it from the link (never from a search result).
- [ ] I set a password of at least **15 characters** (Operators need 15; admins need 12). A phrase of four or five unrelated words works well. It must not be used anywhere else. A password manager is allowed and recommended. Pasting is allowed.
- [ ] I set up an **authenticator app** (any standard TOTP app; the console uses 6 digits that change every 30 seconds). I did not use text messages: there are none.
- [ ] I received **10 recovery codes**. I printed them, wrote nothing else on the page, and stored the page where my phone is not (a drawer at home, not a photo, not a cloud note, not chat). Each code works once.
- [ ] I tested that I can sign out and sign in again with password plus authenticator code.
- [ ] I understand **step-up** (below).
- [ ] I read sections 0 to 12 and section 15 of this runbook and the quick reference card (section 26).
- [ ] I read the Operator code of conduct and signed it. [LAWYER] (document to be written; listed in the DPIA policy checklist)
- [ ] I know the two numbers I might need at 2 a.m.: `<OPERATOR_LEAD>` and `<LAWYER_CONTACT>`.
- [ ] I took part in a dry run on the staging console (section 24) before touching any real claim.
- [ ] I know I must tell the super-admin the same day if I lose my phone, my recovery codes or my password manager.

**What step-up means.** Some actions are risky: viewing evidence, deciding a claim, suspending or revoking, approving a reset, break-glass steps, changing a role, changing your own sign-in details. For these, the console asks for your password and a fresh authenticator code, even though you are already signed in. The code must be a **new one** that has not been used yet, so you may need to wait up to 30 seconds for the next code. A step-up is valid for 5 minutes. After that, you are asked again. This is normal and intended.

**Your session limits** (so you are not surprised):

| Role | Signed out after idle | Signed out after (total) | Sessions at once |
|------|----------------------|--------------------------|------------------|
| Reviewer, Moderator | 15 minutes | 8 hours | 2 |
| Super-admin | 10 minutes | 4 hours | 2 |

Ten wrong sign-in attempts lock an Operator account until another super-admin unlocks it. Do not guess your password repeatedly.

Rules for your device: screen lock on, disk encryption on, system updates on, no shared accounts, no signing in on someone else's computer. Do your review work in a private place where nobody can see your screen.

## 3. Claim status definitions and decision reasons

### 3.1 Statuses (FR-016)

| Status | Meaning | What the admin sees | What listeners see |
|--------|---------|---------------------|---------------------|
| Unclaimed | Nobody has claimed this Masjid. Imported or curated data. | n/a | Listed, labelled unverified |
| Pending | A claim is submitted and not decided, or a verification expired after the grace period | "Under review" or "Renewal needed" | "Claimed pending". Name and location only, marked unverified. No schedule |
| Needs more information | The case is incomplete or something does not match. The admin must act | The reason and what is missing | As Pending |
| Verified | Claim confirmed by evidence and a successful phone call. Valid 12 months | Verified, with the expiry date | Verified badge. Schedule offered |
| Rejected | The claim is refused | The reason, and that one appeal is allowed | As before the claim (Unclaimed or unchanged) |
| Suspended | Temporarily stopped by an Operator, for example an open abuse report or a security doubt | The reason | The app keeps the last good schedule until it is 30 days old, tells the listener the status changed and offers calculated times |
| Revoked | Verification removed by an Operator | The reason | Schedule no longer offered |

The console keeps the claim status and the Masjid listing status as two separate things (research section 7, row 6). If the two screens show different words for the same state, do not worry; follow the console.

### 3.2 Decision reasons

Every decision needs a **reason code** and a **short plain sentence** that the admin will read. The code list below is PROPOSED; it must match the reason list configured in the console. If a code is missing, pick the closest one and log a defect (section 24).

| Decision | Reason codes |
|----------|--------------|
| Verified | `VER-CONFIRMED` (committee confirmed the claimant by phone and evidence is consistent), `VER-RENEWED` (renewal checked) |
| Needs more information | `NMI-DOCS-UNREADABLE`, `NMI-DOCS-INCOMPLETE`, `NMI-LETTER-MISSING` (authorisation letter), `NMI-PHOTOS`, `NMI-CONTACTS-INVALID` (contact details wrong or unreachable), `NMI-DETAILS-MISMATCH` (name or address differs from the listing), `NMI-CALL-NOT-REACHED` (three attempts on two days) |
| Rejected | `REJ-NOT-AUTHORISED` (committee did not confirm the claimant), `REJ-EVIDENCE-INAUTHENTIC`, `REJ-CONTACT-DISOWNED` (the contact says they do not know the claim), `REJ-LOST-ARBITRATION` (another claimant was confirmed), `REJ-NO-RESPONSE` (no answer 30 days after a request for information, PROPOSED), `REJ-NOT-A-MASJID` |
| Suspended | `SUS-ABUSE-REPORT`, `SUS-SECURITY` (suspected account takeover), `SUS-DISPUTE`, `SUS-WRONG-SCHEDULE` |
| Revoked | `REV-FALSE-CLAIM`, `REV-IMPERSONATION`, `REV-COMMITTEE-WITHDREW`, `REV-FORGED-EVIDENCE`, `REV-TERMS-BREACH` |

How to write the sentence for the admin:

- State what the admin must do or why the decision was made, in two or three plain sentences.
- Never name a committee contact or quote what they said. Write "the contact we reached did not confirm your authority", not "Brother X said you are not the secretary".
- Never mention another claimant by name.
- Never include phone numbers, evidence details or anything about how you detected a forgery. Write "the documents could not be accepted as genuine".
- Keep the tone respectful. Many admins are volunteers.

## 4. Claim review, end to end

Target: every complete claim gets a review outcome within **5 working days** (SC-002). See section 20 for how it is counted.

### 4.1 Steps

| # | Step | Detail | Done when |
|---|------|--------|-----------|
| 1 | Take the case | Take the oldest unassigned case in the queue. Assigning it to yourself is what gives you the right to see its evidence. A case has one assigned Operator at a time | Case shows your name |
| 2 | Check completeness | Required: committee or trust documents, authorisation letter, building photos, contact details of two committee members. If anything is missing or unreadable, go to step 9 with `NMI-*` | All parts present and readable |
| 3 | Check the claim against the listing | Does the name, address and location in the claim match the listing and the photos? Use public information (the Masjid's own website, OpenStreetMap, the public listing of the area). Do not upload evidence anywhere. See section 8 | Match noted, or mismatch noted |
| 4 | Check for duplicates and conflicts | Search the Masjid and nearby names. Any other claim on the same Masjid? If yes, stop and go to section 6 | No conflict, or conflict handed to section 6 |
| 5 | Check the claimant's account | Account age, other claims by the same person, earlier rejections for this Masjid (identical evidence stays rejected: the console warns you) | Noted |
| 6 | Find an independent number | Section 5.2. Record the source | Number and source noted, or "none exists" |
| 7 | Make the verification call | Section 5. Maximum three attempts on at least two different days | Outcome code recorded |
| 8 | Second look (when required) | A second Operator reviews when: no independent number exists, the call outcome is `C3` or `C7`, the documents look suspicious, or you are unsure. The second Operator is assigned to the case for the review and records their own opinion | Second note recorded, or "not required" |
| 9 | Decide | Choose the status, the reason code and the sentence. The console asks for step-up. A reason is mandatory | Decision saved, admin notified |
| 10 | Close out | Check the notes are factual. The 90-day deletion clock starts at the final decision. If the case moves to appeal, the clock stops (section 7) | Case closed or on appeal hold |

### 4.2 Decision guide

| Situation | Decision |
|-----------|----------|
| Documents consistent, call confirmed by an independent number and at least one committee contact, no conflict | Verified `VER-CONFIRMED` |
| No independent number exists, both committee contacts answered separately and confirmed, second Operator agrees | Verified `VER-CONFIRMED`; note "no independent number" |
| Documents fine, nobody reachable after three attempts on two days | Needs more information `NMI-CALL-NOT-REACHED`; ask the admin for another contact |
| A contact says they do not know the claimant | Do not decide on that call alone. Try the independent number. If still not confirmed: Rejected `REJ-NOT-AUTHORISED` or `REJ-CONTACT-DISOWNED` |
| Documents look edited or inconsistent | Section 8.4 |
| Two claims on one Masjid | Section 6 |
| Anything that feels wrong but you cannot say why | Ask a second Operator. Do not verify while in doubt: Verified is a human judgement and later phases will give Verified Masjids broadcast rights |

### 4.3 Other claim situations (PROPOSED, spec edge cases without an answer)

| Situation | Rule |
|-----------|------|
| A claim arrives for a Masjid that is already Verified | Treat it as a conflict (section 6). Do not tell the claimant who the current admin is |
| A claim arrives for a Suspended Masjid | Hold the claim until the suspension is resolved. Tell the claimant it is on hold |
| A claim arrives for a Revoked Masjid | Full review, and a second Operator must agree before Verified |
| The admin does not answer a Needs more information request | After 30 days, close as Rejected `REJ-NO-RESPONSE`. The admin may start a new claim with new evidence |
| The admin's email address no longer works | Section 10.3 |
| Evidence files unreadable, too large or malicious | The upload pipeline rejects them. Ask the admin to upload again as a clear photo or scan (JPEG, PNG, WebP or PDF). Never ask for a file by email |

## 5. Phone verification script

This is the core of verification (FR-017). **Documents alone never suffice.** There is no paid telephony and no text messages: you call, you talk, you write down what happened.

### 5.1 Rules for every call

1. Call from `<CALL_METHOD>`. Do not save the number in your phone contacts. Delete the call-history entry if your phone allows it. (A personal phone's call history is a private-data leak; prefer a team phone if there is one.)
2. Call at a sensible local time for the Masjid's time zone. Avoid the five prayer times and Jumu'ah. Begin with a greeting such as "As-salamu alaykum".
3. Speak in the language the person is comfortable with. If you cannot, ask the super-admin to reassign the case to an Operator who can. Do not read the number or details to a helper.
4. Do not record the call. Take written notes in the case only. [LAWYER] (call-recording and calling rules differ by country)
5. Never ask for a password, a code, an ID number or money, and say that Deen App never will.
6. Never read out the claimant's documents or tell the person what the claimant wrote beyond what is needed ("a person called <CLAIMANT_NAME> asked to manage your Masjid's listing").
7. If somebody phones or writes to you first, do not rely on it. Call back on the number on file or the independent number.

### 5.2 Which number to call

Use the best number available, in this order. Record which one you used and where it came from.

| Priority | Number | Why |
|----------|--------|-----|
| 1 | A **public, independent** number: the Masjid's own public website, its OpenStreetMap entry, the register of a national or local Masjid federation or charity, a municipality or umbrella-organisation listing, or a public map listing | The claimant did not supply it, so a forger cannot control who answers |
| 2 | The numbers of the **two committee contacts** supplied in the claim | Needed to confirm the person's role; but the claimant chose them |

Rules:

- **Always try priority 1 first** and, where it exists, make at least one call to it. The independent number is for reaching the Masjid, not for confirming the claim by itself: ask for a committee member.
- If the independent number and a committee contact both confirm, that is the normal "Verified" case.
- If **no independent number exists**: record `none exists`, call both committee contacts separately, and require a second Operator's review before Verified (section 4.2).
- Signs of trouble: a "committee contact" number is the same as the claimant's number or sounds like the claimant; the same person answers for both contacts; the independent number leads to the claimant.
- A number from a document the claimant uploaded is **not** independent.

### 5.3 What to say

Read the notice (section 5.4) at the start of the call to **every committee contact**. For a person answering the independent public number who is not a listed contact, give only the first two sentences and the purpose; do not collect their personal details beyond a name and role as they state them.

Opening:

> "As-salamu alaykum. My name is `<FIRST_NAME>`. I am calling from Deen App, a prayer-times app. Is this `<MASJID_NAME>`? Is this a good time, for two or three minutes?"

Then the notice (section 5.4). Then the questions:

| # | Ask | Record |
|---|-----|--------|
| 1 | "Can I confirm your name, and your role at the Masjid?" | Name and role as stated, only for this check |
| 2 | "Is `<MASJID_NAME>` at `<ADDRESS_AS_LISTED>`?" | Yes, no, differs |
| 3 | "Do you know `<CLAIMANT_NAME>`? What is their role at the Masjid?" | Their words, in short |
| 4 | "Did the committee agree that `<CLAIMANT_NAME>` may manage the Masjid's listing and prayer times in Deen App?" | Yes, no, not sure |
| 5 | "Is anyone else saying they represent the Masjid, or has anyone else asked about this?" | Yes, no (details if yes: conflict, section 6) |
| 6 | "Are the details we have for you correct, and may we call this number again if needed?" (for a committee contact) | Yes, corrections |
| 7 | "Who else on the committee could confirm this?" (if you could not confirm yet) | A name and how to reach them only if offered; otherwise skip |
| 8 | Close: "Thank you, jazakumullahu khayran. We will tell `<CLAIMANT_NAME>` the result. If you want to see, correct or delete the details we hold about you, contact `<PRIVACY_EMAIL>`." | Notice given: yes |

Do not ask anything else. Do not argue with a person who says they do not know the claimant; thank them and end the call politely.

### 5.4 The notice to the committee contact (Art. 14 style) [LAWYER]

This is the information duty for people whose details were given to us by someone else. Say it in your own words but cover every point. A written version must be published at `<PRIVACY_URL>`; after the call, if you hold an email address for the contact, send the link through the console's notice template (not from your own mailbox). Whether a spoken notice is enough is an open legal question (DPIA open question 4).

> "`<CLAIMANT_NAME>` asked us to list them as a manager of `<MASJID_NAME>` and gave us your name and phone number as a committee contact, so that we can check that this is right. We keep your name, number and what you tell us only for this check. Only the Operator handling this case can see it, and we delete it 90 days after the decision, or later only if the decision is appealed. We do this because we only want genuine Masjids to be verified. You can ask to see it, correct it or delete it, and you can complain to `<AUTHORITY_NAME>`. The full notice is at `<PRIVACY_URL>`. The controller is `<CONTROLLER_NAME>`. Are you happy to continue?"

If the person says **no**, or asks for deletion: stop the call, thank them, record outcome `C6`, and open a privacy request for that contact (section 15) the same day. The claim then needs another contact: Needs more information `NMI-CONTACTS-INVALID`.

### 5.5 Outcome codes

Record exactly one code per call attempt.

| Code | Meaning | Next step |
|------|---------|-----------|
| `C1` Confirmed | Reached a person who confirmed the claimant's authority | Continue; Verified if the rest is satisfied |
| `C2` Denied | Reached a person who says the claimant is not authorised or not known | Try another number; do not decide on one call; likely Rejected |
| `C3` Unsure | Reached a person who cannot confirm | Ask for another committee member; second Operator review |
| `C4` No answer | Nobody answered, or voicemail only. Leave **no** message with details | Try again on another day; max three attempts on two days |
| `C5` Wrong number | The number does not belong to the Masjid | Needs more information `NMI-CONTACTS-INVALID` |
| `C6` Declined | The person refused to continue or asked for deletion | Stop; privacy request; another contact needed |
| `C7` Suspicious | Pressure, inconsistent answers, the answerer is the claimant on a "different" number, or any other doubt | Stop; second Operator; see section 8.4 |

### 5.6 What to record in the case notes

- Date, time and your name (the console adds them).
- Which number, and its **source** ("independent: Masjid website" or "claim contact 1").
- Who answered: the name and role they gave.
- Whether the notice was given: yes or no.
- Answers to questions 2 to 5, in a few words.
- The outcome code.
- Next step.

Do **not** record: the call itself, any ID number, any opinion about the person's character, anything about their family or beliefs, the number in plain text in notes (the case already holds it).

## 6. Conflicting claims

Two claims on the same Masjid are both held; **neither claimant has edit rights** until you decide (FR-018).

1. Tell neither claimant who the other is. Tell both: "another claim exists; we will review both and contact you."
2. Assign both to the same reviewer so one person sees the whole picture. A **second Operator** must agree to the final decision.
3. Find the independent number (section 5.2) and call it. Ask question 3 and 4 of the script about **each** claimant by name.
4. Call the committee contacts of each claim. Note whether the two claims name overlapping people.
5. Ask each claimant, through the console, for what is missing (Needs more information).
6. Decide: the confirmed claimant goes on (Verified); the other is Rejected `REJ-LOST-ARBITRATION`. If neither can be confirmed, both are Needs more information or Rejected.
7. Submitting the identical evidence again stays Rejected (FR-016.9). A genuinely new claim needs new evidence.
8. The rejected claimant may appeal once (section 7).
9. **Ownership transfer** (a new admin takes over from the current admin) needs an Operator's approval: confirm with the current admin and an independent number; log it.

## 7. Appeals (one only)

- A rejected claimant may appeal **once**.
- The appeal is decided by a **different Operator** than the one who made the first decision. The first Operator may not decide it, and should not coach the second.
- Setting an appeal puts a **hold** on the evidence: it is kept while the appeal is open and for 90 days after the appeal decision (not longer). A reminder every 30 days goes to the super-admin so a hold is never forgotten. No other kind of hold exists without a written decision by a super-admin. [LAWYER] for legal holds.
- Target: appeal decided within **10 working days** (PROPOSED).
- The appeal decision is final. Tell the admin the decision and a reason; do not re-open it later unless **new** evidence arrives as a new claim.
- If the first decision turns out to be wrong, record it in the notes and tell the `<OPERATOR_LEAD>`.

## 8. Evidence handling rules

Evidence means the documents, letters and photos an admin uploaded, and the committee contacts' details. It is special: it shows who runs a place of worship. If it leaked, real people could be harmed.

### 8.1 Rules (read twice)

| # | Rule |
|---|------|
| 1 | **Only the assigned Operator** may open the evidence of a case, and only while the case is open |
| 2 | The console asks for **step-up** before showing evidence. This is by design |
| 3 | **Every view is logged**: who, which file, when. If the log cannot be written, the file is not shown. If you open things without a need, someone will see it |
| 4 | **Never download, save, copy, screenshot or photograph** evidence or a committee contact's details. The viewer has your identity as a watermark. The watermark is there to deter, not to excuse |
| 5 | Never send evidence or contact details by email, chat, text or paper. Never read a contact's number aloud to a colleague |
| 6 | Never upload evidence to any outside service, including reverse image search, translation or document-check sites. (The security research suggested reverse image search; this runbook forbids it because the file would leave our control. Open point 4) |
| 7 | Never discuss a case in `<TEAM_CHAT>` with names or numbers. Use the case id |
| 8 | The files you see are **re-encoded images**, not the originals. Originals are not kept. This means original PDF signatures are gone; you verify by phone, not by signature |
| 9 | Notes you write are deleted with the evidence at 90 days. Keep notes factual and short |
| 10 | Do not keep your own copy of anything (paper notes, a spreadsheet, a message to yourself). If you must note a number to dial, write it, dial, and shred it at once, or dial from the console view |
| 11 | If someone sends you documents by email or chat: do not open them. Reply that documents must go through the claim form, delete the message, and tell the super-admin |
| 12 | Lock your screen when you leave. Do not review evidence in a public place or on a shared screen |
| 13 | Viewing more than 25 different cases in a day raises an alert. If it happens by mistake, tell the super-admin |

### 8.2 Deletion

- Evidence and contacts are deleted **90 days after the final decision**, automatically, by a daily job. An early deletion on request is also possible (section 15).
- You do not delete evidence by hand. If you think something should be deleted sooner, ask a super-admin.
- The status "evidence missing, request re-upload" can appear after a server restore (restore runbook); ask the admin to upload again.

### 8.3 What to do if you made a mistake

Opened the wrong case, forwarded something, left a screen unlocked, lost a printed note: tell the super-admin **the same day**. A quick, honest report is never a disciplinary matter by itself; hiding it is. If personal data may have left our control, section 18 applies.

### 8.4 Suspected forged or edited document

Signs: edited fonts or alignment, inconsistent dates or names, a letter that does not match the Masjid's real name, photos that do not match the street or building, a "committee" with the same handwriting on every signature.

1. Do not accuse anyone. Do not tell the claimant that you suspect forgery.
2. Stop reviewing as if it were routine: record the facts in the notes (what is inconsistent) and set the call outcome `C7` if the call also felt wrong.
3. Ask a **second Operator** to look, with the case assigned to them for that review.
4. Call the **independent number** (section 5.2) and ask the questions about the claimant. Use only public information to check the building or name.
5. Decide:
   - Cannot confirm from the call and the evidence is inconsistent: Rejected `REJ-EVIDENCE-INAUTHENTIC` or Needs more information.
   - Clearly forged and used to claim a Masjid they do not represent: Rejected, and file a flag task so that a moderator or super-admin can suspend the claimant's account (`SUS-SECURITY`). A reviewer never suspends. A reviewer or super-admin may Revoke (`REV-FALSE-CLAIM`, `REV-FORGED-EVIDENCE`).
6. The system keeps a fingerprint of rejected evidence for 12 months so identical re-submission stays rejected. You do nothing for this.
7. Tell the `<OPERATOR_LEAD>`. Do **not** go to the police, a press contact or another Masjid on your own. Any such step is a super-admin decision with `<LAWYER_CONTACT>`.

## 9. Committee contact privacy rules

Committee members never agreed to give us their details; someone else gave them. Treat them as third parties with rights.

| Rule | Detail |
|------|--------|
| Who can see | Only the **assigned Operator**, only while the **case is open** (FR-032) |
| Every view | Logged |
| Where they live | A separate table. They never appear in lists, search results, exports or the admin's own screens |
| Use | Only to verify the claim and, if needed, to recover that Masjid's admin (break-glass). No marketing, no other messages, no sharing with other Masjids |
| Contact | One call per attempt, with the notice. Do not text. Do not call at prayer times or late at night |
| Retention | Deleted with the evidence 90 days after the final decision |
| Their rights | Access, correction and deletion on request: section 15. Answer within 30 days |
| If they object | Stop, log `C6`, start a privacy request, ask the claimant for another contact |
| Never | Add them to a list, save them in your phone, give them to the admin, give them to another claimant, tell them anything about the claimant's other claims |

## 10. Renewal and the 12-month timeline

Verification lasts **12 months** (FR-017). Dates below count from the Verified decision.

| When | What happens | Operator action |
|------|--------------|-----------------|
| Day 0 | Verified. Expiry date set at day 365 | None |
| Expiry minus 30 days | Reminder email to the admins ("please renew") | Watch the "expiring soon" list; do not chase early |
| Expiry (day 365) | Grace period begins. The Masjid is still shown as Verified | Send a personal reminder (section 10.2) if the admin has not started renewal |
| Expiry plus 30 days | Status drops to **Pending**; listeners see "Claimed pending". The schedule is no longer offered. Phones keep the last schedule until it is 30 days old and then show calculated times | Contact the admin and the committee through the independent number if there is no response |
| After that | The Masjid remains Pending until renewed, claimed by another person, or withdrawn | Review as in section 4 |

### 10.1 How a renewal is reviewed (PROPOSED)

A renewal is shorter than a first claim:

- [ ] The admin confirms the Masjid details and the committee contacts in the console. New documents are needed only if the committee or authorisation changed.
- [ ] One verification call to the independent number or a committee contact, with the notice (section 5). Ask questions 3 and 4 again.
- [ ] If anything changed (a new admin, a new committee), treat it as a first claim.
- [ ] Decide `VER-RENEWED`. The new 12 months start from the decision.

### 10.2 Reminders

- The system sends the 30-day reminder and the grace-period notices by email. To protect the mail system from bursts, renewals are queued (about 60 per day).
- Do not send mail from your own address. If a personal reminder is needed, use the console message tool.

### 10.3 The admin's email address no longer works

Signs: reminder emails bounce. Steps:

1. Do not change the account email on a request from a different address.
2. Phone the Masjid on the independent number or a committee contact on file (if the case is not open, the contact is no longer visible: ask the super-admin to open a recovery case).
3. If the admin is reachable, they sign in and change their email themselves (step-up).
4. If they cannot sign in at all, use the lost-authenticator or break-glass process (section 14).
5. If no admin can be reached, the Masjid drops to Pending after the grace period; that is correct and safe.

## 11. Abuse report triage

Listeners can report a Masjid from the app. Reports reach you without any listener account. A report may carry a contact email only if the listener typed it; that email is deleted when the case closes plus 30 days.

### 11.1 Targets (PROPOSED)

| Type | First response | Resolution | Priority |
|------|----------------|------------|----------|
| Impersonation (someone pretending to be a Masjid admin or committee, or the Deen App team) | 1 working day | 3 working days | High. Suspend at once if the report looks credible |
| Fake Masjid (a listed place that does not exist or is not a Masjid) | 2 working days | 7 working days | Medium |
| Wrong information (name, address, location, times, facilities) | 5 working days | 10 working days | Normal, but see the prayer-times rule below |

"First response" means a person has looked at it, set the status and, if there is a contact email, replied. If many reports arrive, handle impersonation first, then prayer-time errors, then the rest.

### 11.2 Status workflow

The console defines the status workflow (FR-021). PROPOSED labels: New, In review, Waiting, Resolved (action taken), Closed (no action). Always write the reason for closing.

### 11.3 Procedure by type

**Wrong information**

1. Identify the Masjid and what is claimed to be wrong.
2. If the Masjid is Verified: contact the admin through the console and ask them to correct it; give 7 days. If the admin does not respond and the error could mislead worshippers about prayer times, suspend the Masjid (`SUS-WRONG-SCHEDULE`). Listeners then keep the last good schedule until it expires in 30 days and are offered calculated times.
3. If the Masjid is Unclaimed or Pending: check public sources. If clearly wrong, correct the open data field and note the source. Corrections to OpenStreetMap-derived fields may also be reported to OpenStreetMap by a volunteer (optional).
4. Close with what you did.

**Fake Masjid**

1. Check the name and location in public sources and map imagery. Is it a Masjid, a closed building, a duplicate or a test entry?
2. If it does not exist or is a duplicate: merge (section 12) or hide the listing with the console's suspend or remove action, and record the source. If the console has no such action for Unclaimed listings, log a defect.
3. If it was claimed and verified: treat as possible false claim: a moderator suspends (a reviewer files a flag task), then open a review (section 4, forged-evidence path), and call the independent number.

**Impersonation**

1. If credible, a moderator or super-admin **suspends** the Masjid's admin account and the Masjid edit rights at once (step-up, `SUS-SECURITY`), so nothing changes while you check.
2. Review the account's audit entries: what changed, when, from which sign-ins.
3. Call the Masjid on an independent number; ask whether the person is a real committee member.
4. If the account is a hijack of a real admin: section 14 (recovery) and section 18 (incident).
5. If it is a fake person: Revoke `REV-IMPERSONATION`; roll back their changes from version history.
6. If someone is pretending to be the Deen App team (a phishing risk): tell the real admins by email through the console; add the case to the incident log.
7. Reinstating (moderator or super-admin) after a security suspension should be done by a **different Operator** than the one who suspended (PROPOSED).

## 12. Listener suggestions, duplicates and OpenStreetMap imports

### 12.1 Suggestions

Suggestions are moderated and rate-limited (FR-022). They are never applied automatically.

- **Correction to an existing Masjid**: check public sources; apply or reject; reject with a short reason in the notes. A suggestion never overrides a Verified Masjid's own data; pass it to the admin.
- **New Masjid**: the app sends only the 5 km area, the country and typed name and address. **There is no coordinate from the listener.** You place the pin yourself from public maps (OpenStreetMap). Check for duplicates first.
- Flood from one source (many suggestions in a short time): reject in bulk, note it, tell the super-admin. Do not try to identify the sender; the server stores no address.
- If a listener gave an email, you may reply once; the email is deleted when the case closes plus 30 days. Never promise a result.
- Never auto-merge.

### 12.2 Duplicate merges

1. Open both records. Compare names (Arabic script, transliteration, local language), addresses, locations, source (imported, curated, claimed) and status.
2. Keep the record that is **claimed or Verified**. If both are Verified or both have admins, do not merge: call both admins' committees and ask a super-admin (a merge of two Verified Masjids needs a second Operator).
3. Merge fields carefully. Keep the primary display name. Keep the OpenStreetMap identifiers of both so the next import does not recreate the duplicate.
4. Everything is versioned; a wrong merge can be rolled back. Check the result.
5. Followers' phones store follows locally; the merge does not affect that. Whether an old Masjid id stays valid as an alias is UNVERIFIED; ask the engineers.

### 12.3 OpenStreetMap import review

The import comes from OpenStreetMap places of worship tagged as Muslim (ODbL). A moderator reviews, a super-admin publishes.

- [ ] The import runs into a **staging** copy first. You review a **diff against the last import**.
- [ ] Row count change is plausible (no sudden drop or doubling).
- [ ] Coordinates fall inside the stated country; names are not absurdly long; no URLs other than `https` in website fields; no HTML in names.
- [ ] A sample of 20 random new or changed entries is checked on a public map.
- [ ] New entries are labelled **Unclaimed** and unverified. Nothing imported is ever Verified.
- [ ] Duplicates of existing entries are flagged for merge, not auto-merged.
- [ ] The OpenStreetMap attribution and licence notice (ODbL) still appear in the app and the console.
- [ ] Only the OpenStreetMap-derived fields go into the openly published layer. Admin-entered schedules, photos and contacts are never part of a bulk export (FR-031).
- [ ] A super-admin publishes; the version can be rolled back.
- [ ] Note the import date, source extract date and your name in the audit log (automatic).

## 13. Suspend and revoke procedures

| | Suspend | Revoke |
|---|---------|--------|
| Purpose | Stop things now while you check; reversible | End the verification or the account's rights |
| Who | Moderator, super-admin. A reviewer files a flag task and never suspends | Reviewer, super-admin |
| Step-up | Yes | Yes |
| Reason | Required: code and sentence | Required: code and sentence |
| Takes effect | Immediately. For an account: all sessions are closed | Immediately |
| Listener effect | The app keeps the last good schedule until it is 30 days old, shows that the status changed, and offers calculated times | Schedule no longer offered |
| Review | Within 5 working days (PROPOSED) | A revoked admin can appeal once if the revocation ends a verified status |
| Undo | Reinstate (moderator or super-admin). After a security suspension, a different Operator reinstates (PROPOSED) | A new claim with a full review and second Operator agreement |

Procedure:

1. Search for the Masjid or the person. Make sure you have the right one (check the id, not only the name).
2. Choose suspend or revoke. Choose the reason code. Write the sentence (section 3.2).
3. Complete step-up.
4. Check the audit entry appeared.
5. Tell the `<OPERATOR_LEAD>` for any revoke and any suspension of a Verified Masjid.
6. Plan the follow-up: for a suspend, the date you will decide.

If you are a reviewer and a case needs a suspension, file the flag task with the case id and the reason code you suggest.

Never suspend or revoke for personal, religious-school or political reasons. The reason must be a code on the list.

## 14. Lost authenticator, lost recovery codes and break-glass

Admins sign in with email, password and an authenticator-app code. There are three levels of recovery, and a lockout path. Use the lowest that fits.

| Situation | Process | Section |
|-----------|---------|---------|
| Forgot password | The admin uses the email link. Nothing for an Operator to do | 14.1 |
| Lost the authenticator but has a recovery code | Second-factor reset, Operator approves | 14.2 |
| Lost the authenticator **and** all recovery codes | Break-glass | 14.3 |
| An Operator lost their authenticator or codes | Operator recovery | 14.4 |
| Locked out after too many wrong attempts | Unlock | 14.5 |

### 14.1 Password reset (admin does it alone)

The admin asks for a reset. An email with a link arrives; it works **once** and for **10 minutes**. They set a new password, and they still need their authenticator code or a recovery code (a reset never skips the second factor). All their other sessions end and they get a notice. If they say "the link did not arrive", check the spam folder, then ask them to request one new link. Do not send a link by hand or ask for the new password.

### 14.2 Second-factor reset with a recovery code

1. The admin asks for a reset in the app and proves they know the password and own the email address.
2. The admin gives **one valid recovery code**. The system checks and uses it up. You never see the code.
3. A reviewer or super-admin takes the request. **You cannot approve your own request.** Step-up is required.
4. Check: does the request look normal? Is the account recently changed (new email, new password, new device)? If anything is off, ask for a call to the independent number first.
5. Approve. The system removes the old authenticator and codes, closes all sessions, and sends a one-time enrolment link (valid 10 minutes). The admin signs in with the password, enrols a new authenticator and receives new recovery codes.
6. The request expires after 7 days if not completed.
7. You **never** set a credential, read a code or see a secret.

The spec also mentions "a verification call" as an alternative proof to a recovery code (FR-026). This draft does **not** use a call alone as a shortcut: an admin without a recovery code goes to break-glass, which always has the 48-hour delay. Open point 2 in section 25.

### 14.3 Break-glass (both the authenticator and the recovery codes are lost)

This is a rare, slow and deliberately hard process. It needs **a call, a second Operator and a 48-hour delay**.

Who: the **initiator** is a super-admin (A). The **approver** is a different **reviewer or super-admin** (B). B must not be A and **must not be a moderator**. Only a super-admin starts break-glass and logs its call.

| # | Step | Who | Notes |
|---|------|-----|-------|
| 1 | Receive the request. A locked-out admin without codes files a **public lockout request** (the app or console sends it to `POST /v1/auth/recovery-requests`), which creates a `recovery_request` task in the review queue. A takes the task | A | A is assigned to the case so A may see the committee contacts. Do not act on a request that arrived by email or chat; ask the person to file the lockout request |
| 2 | Start break-glass: write the reason and the case id | A | Status `initiated`. Step-up |
| 3 | **The call**: phone a committee contact on file (and the independent number if available). **If no contact is on file** (the 90-day purge deleted them), A adds fresh committee contacts to the case, each **verified through an independent public number** (section 5.2) before they are relied on; they are deleted with the case. Never use a contact that only the requester vouches for. Use the script (section 5) with these questions: "Does `<ADMIN_NAME>` manage the Masjid's listing? Did they ask to recover their account? Is it correct that they lost their sign-in details?" Give the notice | A | Record the outcome code. Must be `C1`. Anything else: stop, no break-glass |
| 4 | Log the call in the break-glass case | A | Status `call_verified` |
| 5 | **Second approval** (a reviewer or a different super-admin, never a moderator): read A's call record. For higher risk (the admin changed email recently, a conflict exists, the committee contact is the claimant) place your own call | B | B uses step-up. The system refuses if B is A |
| 6 | **48-hour delay starts** at B's approval | System | Immediately the system emails the admin and **every committee contact** with a **cancel link**. Reminders go out at 24 hours and 1 hour. The account cannot change factors during the delay |
| 7 | **Cancel**: the admin, A or B can cancel at any time | Anyone | If someone says "I did not ask for this", cancel at once, suspend the account (`SUS-SECURITY`) and treat it as a possible takeover (section 18) |
| 8 | At 48 hours the system checks again: not cancelled, Masjid not Suspended or Revoked | System | If a check fails, the process ends |
| 9 | Completed: the system removes the old authenticator and codes, closes **all** old sessions, voids reset links, forces a password reset and a new authenticator enrolment, issues new recovery codes, and notifies everyone | System | Tell the admin to print the new codes |

Every step is written to the audit log. The 48-hour timer is the same in tests and in real life; we run it for real once in the dry run.

**What Operators must never do in break-glass**

- Never skip or shorten the 48 hours "because it is urgent". There is no urgent exception.
- Never approve a request you initiated, or one you cannot explain. A moderator never approves.
- Never rely on a freshly added contact that was not verified through an independent public number.
- Never accept an email, a chat message, a text or a voice message as the proof. Only the call.
- Never use only the phone number supplied in the recovery request. Use the number on file for the committee contact, and the independent number if one exists.
- Never read out, set, reset or receive a password, authenticator secret or recovery code.
- Never cancel the process on behalf of someone you have not verified, or ignore a cancel request.
- Never share the committee contacts with the admin or with B in writing.
- Never help the same person do this twice in a month without telling the `<OPERATOR_LEAD>`.

### 14.4 An Operator is locked out

An Operator's own reset needs a **super-admin and a second Operator** (a super-admin is the one who unlocks an Operator), and an identity check (a call or a video call with another Operator who knows them, by `<CALL_METHOD>`). Treat a lost Operator device as an incident: section 17 and section 18. Both founders hold the super-admin role, so each can unlock the other. If a founder leaves and only one super-admin remains, that person cannot unlock themselves: appoint another super-admin first (open point 1).

### 14.5 A locked admin or Muazzin account

After too many wrong sign-in attempts an account is locked. Any Operator (reviewer, moderator or super-admin) may unlock an **admin or Muazzin** account, after checking it is really the account owner: use the lockout path above if they also lost their codes. Only a **super-admin** unlocks an **Operator** account.

## 15. Privacy requests

Anyone whose data we hold may ask: admins, Muazzins, committee contacts and Operators. **Deadline: 30 days** from the day the request arrives (FR-024). A reminder fires at **day 20**.

### 15.1 Procedure

| Day | Step |
|-----|------|
| 0 | Log the request in the console: who, what, date received, channel. The deadline is shown. Reply within 2 working days to say it is received |
| 0 to 3 | **Check identity.** A signed-in admin with step-up is already verified. Anyone else: call back on the number we hold (not a number in the request). For a committee contact: the number on the case. Do not ask for an ID document. If you cannot verify, do not release anything |
| 3 to 15 | Gather what we hold (section 15.2). Decide what can be released or deleted (section 15.3) |
| 20 | Reminder. If you are not nearly done, tell the `<OPERATOR_LEAD>` |
| 30 at the latest | Reply with the result. Close the request in the console. Write the outcome. If you cannot meet 30 days, tell the requester before day 30 with the reason [LAWYER] (the legal limit may allow an extension; this project commits to 30 days) |

Listeners: we hold nothing about listeners. If a listener asks, say so and explain the network-address note (DPIA section 12). No further action is needed.

### 15.2 Export (access)

An admin or Muazzin can export their own data from the console. You may do it for them after identity checks. The export includes: account details, role, the Masjids they manage, the claims they submitted, audit entries about them, privacy-request history, security events (with the stored address, if still within 30 days). It does not include other people's data. Whether the export includes the evidence images and the committee contacts the admin supplied is open (DPIA open question 5) [LAWYER].

### 15.3 Erasure

| Removed | Remains |
|---------|---------|
| Email, password hash, authenticator secret, recovery codes, sessions, invitations | The Masjid listing, with the Masjid's own data (if the person was the only admin, the Masjid keeps its status until expiry and you must flag it: no one can renew) |
| Evidence and committee contacts for the person's claims (purged now, not at 90 days; an open claim becomes withdrawn or Needs more information) | Audit entries. They become **anonymous**: the link from the entry to the account is deleted, so they read "Former admin" |
| Raw security-log addresses | Truncated security-log addresses already kept for up to 12 months [LAWYER] |
| | A fingerprint of rejected evidence for up to 12 months, so identical re-submission stays rejected [LAWYER] |
| | Encrypted database backups for up to 30 more days (they hold no files) |
| | A minimal record that the request existed (id, dates, outcome) [LAWYER] |

Tell the requester about the "remains" column in the reply. For a committee contact: delete the contact row and notes about them as soon as the identity check passes, unless the case is open; if open, remove it and tell the assigned Operator that another contact is needed.

## 16. Muazzin and admin account support (short)

- Muazzins have an account but no listing rights. Admins invite and remove them.
- An admin who is also a Muazzin elsewhere has two roles; they do not mix.
- A deleted admin is not a revoked Masjid. Check that every Masjid they managed has another admin.

## 17. Offboarding an Operator

Do this on the **same day** the person leaves or loses trust. The super-admin does it; a second Operator watches and signs.

- [ ] Disable the account and **revoke all sessions** (console).
- [ ] **Reassign** every open case and any open privacy request, break-glass or appeal they hold. Check none is left assigned.
- [ ] Remove them from `<TEAM_CHAT>`, `<OPS_MAILBOX>` and any alert channel.
- [ ] Remove their device access: SSH key and WireGuard peer on the server, access to the team backup machine, the repository and any password manager vault.
- [ ] **If they held keys** (the `age` key or the backup password): rotate them. This needs the key holders and the restore runbook (key custody and rotation). Remove them as a recipient of the secrets file and re-encrypt it. Rotate the encryption key that wraps evidence keys and the secrets file recipients. A departure with key access is a rotation trigger.
- [ ] Ask them to delete any paper or digital copy of recovery codes and any call history entries of committee contacts.
- [ ] Remind them of the confidentiality duty, in writing. [LAWYER]
- [ ] Keep the audit trail. The link between their identity and their audit entries is kept while they work for us and for 24 months after (PROPOSED, [LAWYER]); do not delete the account in a way that breaks it.
- [ ] Write the date, the keys rotated and who signed in the offboarding record.

## 18. Incident response

Examples: suspected evidence leak; an admin or Operator account taken over; an unexpected evidence view alert; a lost device with call history; a server compromise.

**Lead**: `<OPERATOR_LEAD>` or the first super-admin on the scene. A second Operator writes the timeline.

| Time | Step | Detail |
|------|------|--------|
| Immediately | **Contain** | Take the smallest action that stops the harm. Account: suspend and close all sessions. Evidence viewing: ask `<SERVER_ACCESS_PERSON>` to block the evidence route or stop the API. Server compromise: do not wipe the server yet; take a provider snapshot, then isolate. Rotate secrets that may be known (restore runbook, section on key rotation). Do not delete logs |
| Within 24 hours | **Assess** | What data (evidence, contacts, accounts)? Whose? How many people? Since when? Is it still happening? How likely is harm to those people (they are linked to a place of worship)? Write the facts, not guesses |
| Within 72 hours of becoming aware | **Decide on notifying the authority** | If the breach is likely to put people's rights at risk, notify `<AUTHORITY_NAME>` within **72 hours** of becoming aware. If you cannot decide in time, notify and add details later [LAWYER]. Call `<LAWYER_CONTACT>` |
| Always | **Breach register** | One entry per breach, even if nobody is notified: date and time of discovery, what happened, data and numbers involved, effects, actions, who decided what and why. Reason for not notifying, when so |
| Without undue delay if risk is high | **Tell affected people** | Admins and committee contacts affected: what happened, what data, what we did, what they can do, who to contact. Plain language, no blame. Draft: "We found that `<WHAT>` on `<DATE>`. The information involved was `<DATA>`. We have `<ACTIONS>`. You can `<STEPS>`. Questions: `<PRIVACY_EMAIL>`." [LAWYER] |
| Within 14 days (PROPOSED) | **Review** | What failed, what to change, fix this runbook. Update the breach register. Tell the DPIA owner: a breach triggers a DPIA review |

Specific cases:

- **Account takeover**: suspend the account; close sessions; review the audit log for what the intruder did; roll back the Masjid changes using version history; verify the real admin with a call; recovery by break-glass; check whether the intruder viewed anything (an admin cannot see evidence; an Operator can).
- **Suspected evidence leak**: find which cases were exposed (view log); block the route; crypto-shred the affected cases early if the case is closed (ask engineering); tell the affected admins and contacts; rotate the evidence key-encryption keys.
- **Operator's lost or stolen device**: disable the account and sessions; ask what the device held (call history); treat as an incident if it could contain contact numbers.
- **Server compromise**: the live server holds the keys that decrypt evidence while it runs, so a root-level compromise exposes the evidence that still exists on that server (the design's stated limit, research R-13). Treat it as a high-risk breach until shown otherwise; restore onto a new server (restore runbook) and rotate everything.

## 19. Evidence for audits: what the audit log shows

- Every state change on a Masjid or account has an entry with the actor and the time (SC-008, FR-006).
- Operators can read all entries; admins read entries about their own Masjids, without evidence events, contact events or Operator names.
- A nightly job checks that the log chain is unbroken. If an alert says it is broken, treat it as an incident (section 18).
- When you search the audit log, the search is itself logged.

## 20. Service targets and how to measure them

| Target | Value | Source |
|--------|-------|--------|
| Complete claim gets a review outcome | within 5 working days | SC-002 |
| Impersonation report first response | 1 working day | PROPOSED |
| Fake Masjid first response | 2 working days | PROPOSED |
| Wrong information first response | 5 working days | PROPOSED |
| Appeal decided | 10 working days | PROPOSED |
| Privacy request answered | 30 days, reminder at day 20 | FR-024 |
| Break-glass delay | 48 hours, no shortening | FR-026 |
| Evidence past its deletion date | zero (daily check) | FR-008 |
| Operator effort per claim, median | 30 minutes or less | dry-run pass rule |

### 20.1 Counting rule for SC-002 (PROPOSED)

- **Working days** follow `<WORKING_DAYS_RULE>`. Fill in before launch. In many places the weekend is not Saturday and Sunday.
- **Start**: the moment the claim is complete (all required parts submitted).
- **Stop**: the first review outcome recorded: Verified, Rejected or Needs more information.
- **Pause**: time waiting for the admin after "Needs more information" does not count. The clock restarts when the admin resubmits.

### 20.2 How to measure

| Measure | How | When | Who |
|---------|-----|------|-----|
| Age of the oldest open claim | Queue sorted by submission date; count working days | Every working day | The Operator on duty |
| Share of claims with an outcome in 5 working days | Console SLA report: decision date minus submit date in working days | Weekly, and monthly summary | `<OPERATOR_LEAD>` |
| Cases at risk | Amber at day 3, red at day 4 (PROPOSED) | Daily | Operator on duty |
| Abuse and privacy deadlines | Console due dates and day-20 reminder | Daily | Operator on duty |
| Median Operator effort | Time from "case taken" to decision, from the SLA report; in the dry run, the observer's stopwatch | Monthly and in the dry run | `<OPERATOR_LEAD>` |

If the SLA report is not ready, keep a simple sheet outside the console with **case ids and dates only** (no names, no numbers).

If you will miss 5 working days, tell the claimant and set the reason in the case notes. Escalate to `<OPERATOR_LEAD>` when two or more claims are at risk. Staffing, not shortcuts, is the answer.

## 21. Daily and weekly routine

Daily (15 minutes if quiet):

- [ ] Sign in; check the review queue, oldest first.
- [ ] Check abuse reports; handle impersonation first.
- [ ] Check privacy requests with due dates.
- [ ] Check alerts: uptime, mail failures, evidence past due.
- [ ] Check the "expiring soon" and "grace" lists.

Weekly:

- [ ] Review the SLA report.
- [ ] Check that the latest backup is fresh (restore runbook, appendix).
- [ ] Look at suggestions: clear the queue.
- [ ] Read the evidence-view alerts.

Monthly: review the cost (alert at US$8, action at US$9.50, from the plan), the Operator list (who still needs access), and appeal holds.

## 22. Language and tone with admins

The console is in English at launch (other languages later). Many admins write in other languages. Use short, polite, plain English; say what you need; give one next step; thank them for their time. Never shame, never threaten, never share another person's information.

## 23. Common mistakes (read before your first case)

| Mistake | Instead |
|---------|---------|
| Trusting the documents | Documents help; the call decides |
| Calling only the numbers the claimant gave | Find an independent number first |
| Writing a committee member's name in a reason | Use the neutral sentences in section 3.2 |
| Deciding while unsure | Ask a second Operator |
| Taking a photo of the screen "just to ask a colleague" | Reassign the case |
| Skipping the notice | Always give it, every call |
| Shortening break-glass | The delay is the control |
| Forgetting the clock | Check the queue every working day |

## 24. Operator dry run (the proof of this document)

The dry run proves this runbook and SC-002, SC-008, FR-021 and FR-028 (research R-24; test plan section 5). It runs before any Operator reviews a real claim.

**Setting**: staging stack, nothing real. Two Operators (O1 reviewer, O2 moderator and super-admin), one note taker, two testers who play admins and committee contacts using their own phones (no paid telephony). **Only this document and the console are allowed as help.**

| Masjid | Path to complete |
|--------|------------------|
| M1 Al-Noor | Sign-up, password, authenticator, recovery codes, claim with documents, verification call, Verified, admin edits the schedule, rollback, 14-day preview |
| M2 Dar-us-Salam | Two conflicting claims, arbitration, the loser is Rejected, identical re-submission stays Rejected, appeal, one decision |
| M3 Masjid Taqwa | Needs more information, Pending listing, Suspended then reinstated, abuse report through its workflow, lost authenticator and recovery codes (break-glass: initiator asks, a different Operator approves, the 48-hour delay runs once for real, notifications, old sessions closed), privacy export, account deletion |

Break-glass is started and its call logged by a super-admin only, and approved by a reviewer or a different super-admin, never a moderator. The test plan has O1 (reviewer) asking and O2 approving; swap them so that the super-admin O2 starts it and the reviewer O1 approves (open point 6). The lockout request is filed through the public route and appears as a `recovery_request` task.

**Pass**: every step done from the document alone; no blocking defect; 100% of state changes have an audit entry (a script compares the expected action list with the audit rows); no protected screen reachable before the second factor; evidence viewed only by the assigned Operator; median Operator effort per claim 30 minutes or less; the SLA report shows decision date minus submit date in working days; every step that was not in this document is added to it.

### 24.1 The evidence file

One CSV file per dry run, at `specs/002-masjid-directory-verification/evidence/dry-run-YYYYMMDD.csv`. Start the file with five comment lines (a line beginning with `#`) for: date, build SHA, environment, participants, time zone. Then the column header row and one row per step:

`ID | Masjid | Step | Actor/role | Expected | Actual | Audit entry id(s) | Screenshot file | Start | End | Pass/Fail | Defect id | Observer initials`

| Column | What to write |
|--------|---------------|
| ID | A running number: `M1-01`, `M1-02` ... |
| Masjid | M1, M2 or M3 |
| Step | The step in a few words (for example "Phone verification, independent number") |
| Actor/role | Who did it and in which role (O1 reviewer) |
| Expected | What this document says should happen |
| Actual | What happened, including anything you had to guess |
| Audit entry id(s) | The id of every audit entry the step should have produced. Copy exactly; the script checks them |
| Screenshot file | File name of a screenshot (staging only; never of real evidence) |
| Start, End | Time stamps in the file's time zone |
| Pass/Fail | Pass only if done from this document alone |
| Defect id | The defect number in the tracker, if Fail or if you had to guess |
| Observer initials | The observer's initials |

Example row:

`M1-07 | M1 | Phone verification, independent number | O1 reviewer | Call outcome C1 recorded, notice given | C1 recorded, notice given, took 6 min | AUD-0042 | m1-07.png | 10:42 | 10:48 | Pass | - | NT`

Defects found in the dry run are fixed in this document before the real launch and the file is kept as evidence.

## 25. Open points for the owner

| # | Point | Why it matters | Needs |
|---|-------|----------------|-------|
| 1 | Both founders hold super-admin, so each can unlock the other and approve the other's break-glass. What happens if one leaves? | A single super-admin cannot unlock themselves | Appoint a third super-admin or reviewer before a founder leaves |
| 2 | FR-026 lists "a recovery code or a verification call" for resetting the second factor; this draft sends "no recovery code" to break-glass with its 48-hour delay | Avoid a shortcut that skips the delay | Confirm in the state-machine contract |
| 3 | The reason code list, the status labels and the abuse workflow names are PROPOSED | The console must show the same words | Align with the console configuration |
| 4 | The security research suggested reverse image search of evidence; this draft forbids it | It sends evidence to a third party | Owner and [LAWYER] confirm |
| 5 | Does the data export include evidence images and committee contacts? | Third-party data in an access request | [LAWYER] |
| 6 | The test plan (O1 reviewer asks, O2 approves) differs from the API contract (a super-admin starts, a reviewer or other super-admin approves) | The test must match the real rule | Fix the test plan |
| 7 | Working days and holidays | SC-002 cannot be counted without them | `<WORKING_DAYS_RULE>` |
| 8 | Call method and number visibility | Operator privacy and the "no paid telephony" rule | `<CALL_METHOD>` |
| 9 | Abuse, appeal and renewal targets are PROPOSED | Not in the spec | Owner accepts or changes after the dry run |
| 10 | Notice by voice enough for a committee contact? | Art. 14 | [LAWYER] |

## 26. Quick reference card (print this page)

**Before anything: lock your screen. Evidence is never downloaded, photographed, copied or sent.**

| Need | Do |
|------|-----|
| Sign in | Email, password (15+), authenticator code. Step-up = password plus a **fresh** code, valid 5 minutes |
| See evidence | Only the **assigned** Operator, only while the case is **open**. Every view is logged |
| Claim review target | Outcome within **5 working days** (clock from the complete claim) |
| Verify | **Call.** Independent public number first. Give the **notice**. Ask the 8 questions. Record a code |
| Outcome codes | `C1` confirmed, `C2` denied, `C3` unsure, `C4` no answer, `C5` wrong number, `C6` declined, `C7` suspicious |
| Calls | No recording. No texts. No paid services. Max 3 attempts on 2 days. Not at prayer times |
| Not sure? | Second Operator. Never verify in doubt |
| Decision | Status plus reason code plus a plain sentence. Never name the contact |
| Conflict | Hold both. No edit rights for either. Reviewer or super-admin arbitrates; second Operator agrees. Loser: `REJ-LOST-ARBITRATION` |
| Appeal | One only. Different Operator. 10 working days (proposed) |
| Renewal | Verified 12 months. Reminder at day 335. Grace to day 395. Then Pending |
| Reports | Impersonation 1 working day (suspend if credible). Fake Masjid 2. Wrong information 5 |
| Suspend, reinstate | Moderator or super-admin. Immediate, reversible, reason needed. **A reviewer never suspends: file a flag task.** Revoke: reviewer or super-admin |
| Forged document | Do not accuse. Second Operator. Call the independent number. Tell the lead. No police by yourself |
| Locked out (too many attempts) | Any Operator unlocks an admin or Muazzin; only a super-admin unlocks an Operator |
| Lost authenticator, has a code | Reset: another reviewer or super-admin approves (not you for yourself) |
| Lost authenticator and codes | Admin files a **lockout request** (`recovery_request` task). **Break-glass**: super-admin starts and logs the **call** to a committee contact (no contact left after the purge: add fresh ones, verified via an independent public number). A **different reviewer or super-admin** approves, never a moderator. **48 hours**, notices and cancel link |
| Never | Skip the 48 hours. Accept email as proof. Set or read a code. Approve your own request |
| Privacy request | 30 days. Reminder day 20. Verify identity by callback. Say what remains |
| Leaver | Revoke sessions, rotate keys if they had any, reassign cases, same day |
| Incident | Contain now. Assess in 24 hours. Authority decision within 72 hours. Register it. Tell people if risk is high |
| People | `<OPERATOR_LEAD>`, `<LAWYER_CONTACT>`, `<SERVER_ACCESS_PERSON>`, `<KEY_HOLDER_1>`, `<KEY_HOLDER_2>` |

---

## Validation

| What is proven | By | Status |
|----------------|----|--------|
| Every procedure here can be done from this document alone; the Operator effort target; audit coverage for state changes; assigned-Operator-only evidence view; break-glass with a real 48-hour delay | The **Operator dry run** (section 24) on staging, with the evidence CSV | Not yet run |
| The service target of 5 working days and its measurement | The dry run's SLA report, then the first month of the pilot | Not yet run; counting rule PROPOSED |
| Legal wording: Art. 14 notice, call recording, retention periods, third-party data in exports, authority and 72-hour rule, confidentiality duty | **Legal review** [LAWYER] together with the DPIA | Not started |
| Alignment with the console (role matrix, reason codes, statuses) and with the state-machine contract | Review by the engineers against the policy table and the contracts; the dry run exposes differences | Not started |
| Key rotation and server steps referenced here | The timed **restore drill** (see [restore-runbook.md](restore-runbook.md)) | Not yet run |

Still open: the placeholders in the "Fill in before use" table, the ten open points in section 25, the Operator code of conduct and the published notices (see the policy checklist in [dpia.md](dpia.md)), and the console screens, which do not exist yet (Phase 1 is in planning, and building starts when Phase 0 exits, constitution principle 9).
