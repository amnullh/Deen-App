# State Machines and Transition Tables (Phase 1)

**Date**: 2026-10-22 | **Spec**: [../spec.md](../spec.md) | **Research**: [../research.md](../research.md) | **Data model**: [../data-model.md](../data-model.md)

This file is the human-readable copy of the one TypeScript transition table in `services/domain` (R-02, R-24). CI regenerates it and fails on `git diff`. Every table is loadable by a program: one Markdown row per transition, columns `state | event | to | guard | audit action | side effects`.

**Loader rules**
1. A cell written `{A, B}` in the `state` or `event` column is a set; the loader expands it to one row per element. Rows are grouped only when every other column is identical.
2. Several rows with the same `(state, event)` are routes: their guards start with `route:`; the first matching route wins and exactly one must match (the route test proves it). Other guard names are preconditions; their failure is `403` for role and ownership guards, `409 guard_failed:<name>` for state guards and `422` for validation.
3. After expansion, the legal pairs plus the `ILLEGAL (409)` pairs must equal states x events exactly, with no overlap. Section 6 states the totals.
4. `to` of `(deleted)` means the row is removed (account deletion only). `(new)` and `(none)` mark the initial transition.
5. Check order on every call: authentication and second factor (`401 mfa_required`), resource scope (a Masjid or case the actor cannot see answers `404` like a missing id), role and ownership guards (`403`), pair legality (`409 illegal_transition`), business guards (`409 guard_failed`), validation (`422`). A failed call changes nothing and writes no audit row.

## 0. Conventions

**Role sets** (rulings of 2026-10-22; the runbook table is a proposal and must be aligned, Issues 5): **RV** = reviewer or super_admin; **MD** = moderator or super_admin; **OP** = any Operator role; **SA** = super_admin. Suspend and reinstate (a Masjid or a person) are MD; revoke is RV; arbitration and appeal decisions are RV; break-glass initiate and `log_call` are SA only; the break-glass second approval is RV (never a moderator, never the initiator). A reviewer who suspects fraud files an `operator_task` of kind `fraud_flag` for a moderator instead of suspending. Super-admins have no implicit evidence right: they must be assigned first. The founding team of at least 2 Operators both hold super_admin, so four-eyes works from day one.

**Guard names**

| Guard | Meaning |
|-------|---------|
| claimant | actor_ref equals `claim.claimant_ref`; account active; second factor verified |
| assignee | actor_ref equals `claim.assigned_to_ref`; role RV; `operator.onboarding_ack_at` set (FR-028) |
| arbitrator | `claim_conflict.arbitrator_ref`; role RV; never an earlier assignee of a member claim |
| step_up | password plus a fresh TOTP step within 5 minutes (Operators) or 10 minutes (admins) |
| reason | a reason code from the list (runbook 3.2: `VER-*`, `NMI-*`, `REJ-*`, `SUS-*`, `REV-*`) plus a plain sentence without names or numbers |
| evidence_ok | at least one committee or trust document, an authorization letter, a building photo, at least 2 distinct committee contacts, every file sanitised (US3.2) |
| listing_open | listing not retired |
| listing_not_suspended | listing status is not Suspended (a claim on a Suspended Masjid is held, runbook 4.3) |
| call_ok | a `verification_call` for this claim by the assignee with outcome C1 (C3 and C7 also need `second_look_ok`) |
| second_look_ok | if `second_review_required` (set when the listing is Revoked, no independent number exists, or the assignee asks): a `case_note` of kind second_opinion by an Operator who is not the assignee |
| window_open | `now <= appeal_deadline` (decision + 30 days) |
| one_appeal | no `appeal` row exists for the decision (`UNIQUE (decision_id)`; a second insert is `409`) |
| not_original_decider | actor_ref differs from `decision.decided_by_ref` of the appealed decision (trigger) |
| route:competitor | another claim in an active status, or a Verified claim, exists for the Masjid from a claimant who is not a member of it |

**Active claim statuses** (used by the listing machine and the conflict rule): Submitted, InReview, NeedsInfo, Conflicted, Appealed. Draft, Rejected, RejectedFinal, Withdrawn, Superseded, Expired, Revoked and RevokedFinal are not active.

**Side-effect notation**: `L:<event>` emits that event on the listing machine in the same transaction; `mail:<template>` inserts an `email_outbox` row with a dedupe key; `pack:dirty(...)` inserts `pack_dirty_cell` rows; `fp:store` writes `evidence_fingerprint`; `decision(kind)` inserts a `decision` row. Everything in a row (state change, audit rows, side-effect rows) is one transaction. Timers are columns; sweepers are idempotent and may run late or twice; time is injected in tests.

## 1. Claim status machine

Claim status is about one admin's request. Listing status (section 2) is about the Masjid. Spec FR-016 mixes them in one list; the two machines together derive all seven of its statuses (section 2c).

| Status | Meaning | Admin sees | Active |
|--------|---------|------------|--------|
| Draft | being written; files uploaded; nothing visible to Operators | Draft | no |
| Submitted | complete, in the queue, unassigned | Under review | yes |
| InReview | assigned Operator is checking; call pending | Under review | yes |
| NeedsInfo | Operator needs more; admin must act | Needs more information, with reason | yes |
| Verified | confirmed; valid 12 months | Verified until `vu` | no |
| Rejected | refused; one appeal within 30 days | Rejected, reason, appeal option | no |
| RejectedFinal | rejected, appeal used or window passed, or automatic (identical evidence, no response) | Rejected | no |
| Appealed | the single appeal is open | Appeal in review | yes |
| Withdrawn | admin withdrew, draft or listing timeout | Withdrawn | no |
| Conflicted | held for arbitration; no edit rights; evidence readable by the arbitrator only | On hold | yes |
| Superseded | an earlier Verified claim replaced by a newer Verified one | Replaced | no |
| Expired | Verified claim whose grace period ended | Expired, renew | no |
| Revoked | verification removed by an Operator; one appeal within 30 days | Revoked, reason | no |
| RevokedFinal | revoke appeal dismissed or window passed | Revoked | no |

States: Draft, Submitted, InReview, NeedsInfo, Verified, Rejected, RejectedFinal, Appealed, Withdrawn, Conflicted, Superseded, Expired, Revoked, RevokedFinal. Events: submit, assign, request_info, respond, verify, reject, appeal, appeal_reopen, appeal_dismiss, lapse_appeal_window, withdraw, timeout, conflict_open, arbitrate_resume, arbitrate_reject, supersede, expire, listing_revoked, request_early_deletion.

14 states x 19 events = 266 pairs: 44 legal (49 rows, route rows share a pair), 222 illegal.

Initial transition (no prior state):

| state | event | to | guard | audit action | side effects |
|---|---|---|---|---|---|
| (new) | create_draft | Draft | claimant (account kind admin, MFA verified); kind=claim: listing not retired; kind=create: a hidden Masjid row is created (published_at null) after a duplicate check against nearby Masjids; kind=renewal: actor is a masjid_member admin and now >= verified_until-30 days or the listing is Pending after a lapse | claim.draft_created | draft_expires_at=now+30 days; one open claim per claimant and Masjid (partial unique index) |

Legal transitions:

| state | event | to | guard | audit action | side effects |
|---|---|---|---|---|---|
| Draft | submit | RejectedFinal | claimant; evidence_ok; listing_open; route:fp_match (bundle fingerprint equals one stored for this Masjid) | claim.rejected_identical | auto decision REJ-IDENTICAL-EVIDENCE (no appeal: final); delete_after=+90d; mail:claim_rejected asks for new evidence; no new fingerprint |
| Draft | submit | Conflicted | claimant; evidence_ok; listing_open; route:competitor (an active or Verified claim by a different claimant exists) | claim.conflicted | submitted_at=now; create or join claim_conflict (this claim = challenger; a Verified claim = incumbent); other active claims get conflict_open; L:claim_submitted if listing Unclaimed; mail:claim_received |
| Draft | submit | Submitted | claimant; evidence_ok; listing_open; route:clear (neither of the above) | claim.submitted | submitted_at=now; draft_expires_at=null; L:claim_submitted if listing Unclaimed; if listing Revoked then second_review_required=true; mail:claim_received |
| Draft | withdraw | Withdrawn | claimant | claim.withdrawn | delete_after=+7d (never decided); evidence of a never-submitted draft is not kept 90 days |
| Draft | timeout | Withdrawn | system; route:draft_idle (draft_expires_at <= now, 30 days idle) | claim.timed_out | delete_after=+7d |
| Draft | request_early_deletion | Draft | claimant; step_up | claim.early_deletion_requested | evidence purged now (evidence.purged_early rows), contacts and notes deleted; claim stays Draft and fails evidence_ok |
| Submitted | assign | InReview | role RV; operator.onboarding_ack_at set (FR-028); actor is not the claimant; super-admin only by being assigned | claim.assigned | assigned_to_ref=actor; only the assignee may open evidence and committee contacts (A) |
| Submitted | withdraw | Withdrawn | claimant | claim.withdrawn | delete_after=+90d; L:claims_closed when the listing is Pending and no active claim remains; mail:claim_withdrawn |
| Submitted | conflict_open | Conflicted | system; route:competitor | claim.conflicted | join claim_conflict as challenger |
| {Submitted, InReview, NeedsInfo} | request_early_deletion | Withdrawn | claimant; step_up; explicit confirmation | claim.early_deletion_requested | evidence purged now (evidence.purged_early rows), contacts and notes deleted; L:claims_closed when the listing is Pending and no active claim remains |
| InReview | assign | InReview | current assignee (hand over) or super_admin; target has role RV and onboarding_ack_at; also used by offboarding | claim.reassigned | assigned_to_ref=target; the old assignee loses evidence and contact access at once; operator_task reassign_case closed |
| InReview | request_info | NeedsInfo | assignee; step_up; reason NMI-* | claim.info_requested | decision(request_info); needs_info_due_at=+30d; mail:claim_needs_info (reason shown); evidence kept; delete_after stays null |
| InReview | verify | Verified | assignee; step_up; reason VER-*; call_ok; second_look_ok; listing_not_suspended; no open conflict (a conflicted claim is not InReview) | claim.verified | decision(verify); final_at=now; evidence delete_after=+90d; masjid_member(admin) upsert; masjid.published_at set if null; L:verified (verified_at=now, verified_until=now+12 months, grace_until=verified_until+30 days, reminder/expiry/lapse flags null, verified_claim_id); other Verified claims of the Masjid get supersede; mail:claim_verified; pack:dirty(base cell, overlay cell, sched gh4) |
| InReview | reject | Rejected | assignee; step_up; reason REJ-* | claim.rejected | decision(reject); evidence delete_after=+90d; appeal_deadline=+30d; fp:store (12 months) only for REJ-NOT-AUTHORISED, REJ-EVIDENCE-INAUTHENTIC, REJ-CONTACT-DISOWNED, REJ-NOT-A-MASJID; L:claims_closed when the listing is Pending and no active claim remains; mail:claim_rejected (reason, one appeal, fingerprint notice) |
| {InReview, NeedsInfo} | withdraw | Withdrawn | claimant | claim.withdrawn | delete_after=+90d; L:claims_closed when the listing is Pending and no active claim remains |
| InReview | conflict_open | Conflicted | system; route:competitor | claim.conflicted | assigned_to_ref=null (the conflict's arbitrator gets evidence and contact access instead); join claim_conflict |
| NeedsInfo | respond | Submitted | claimant; evidence_ok; at least one new file or message | claim.info_provided | needs_info_due_at=null; assigned_to_ref kept as preferred assignee (queue shows it); the same decision cannot be appealed after a response |
| NeedsInfo | appeal | Appealed | claimant; one_appeal on the request_info decision; statement of at least 20 characters | claim.appealed | appeal(origin=needs_info); evidence hold (hold_reason=appeal); needs_info_due_at=null; L:claim_submitted if listing Unclaimed; Operator queue item |
| NeedsInfo | timeout | RejectedFinal | system; route:needs_info_due (needs_info_due_at <= now) | claim.rejected_no_response | auto decision REJ-NO-RESPONSE; final; delete_after=+90d; no fingerprint (a new claim with the same files plus answers is allowed); L:claims_closed when the listing is Pending and no active claim remains; mail:claim_rejected |
| NeedsInfo | conflict_open | Conflicted | system; route:competitor | claim.conflicted | assigned_to_ref=null; join claim_conflict; needs_info_due_at paused |
| Verified | supersede | Superseded | system; another claim of this Masjid became Verified (renewal, arbitration winner, appeal) | claim.superseded | none (listing is handled by the new claim) |
| Verified | expire | Expired | system; now >= grace_until and listing.verified_claim_id = this claim | claim.expired | L:grace_elapsed (listing to Pending); mail:lapse_notice (dedupe on lapse_notice_sent_at); pack:dirty(overlay st=P, rules leave sched) |
| Verified | listing_revoked | Revoked | system, caused by L:revoke (RV, step_up, reason REV-*) | claim.revoked | appeal_deadline=+30d; masjid_member rows deleted; other active claims get second_review_required=true; mail:revoked |
| Verified | request_early_deletion | Verified | claimant; step_up | claim.early_deletion_requested | evidence purged now (evidence.purged_early rows), contacts and notes deleted; state and listing unchanged; contacts gone, so a later break-glass needs fresh contacts (data-model Issue 2) |
| Rejected | appeal | Appealed | claimant; window_open (now <= appeal_deadline); one_appeal; statement of at least 20 characters | claim.appealed | appeal(origin=rejected); evidence hold; L:claim_submitted if listing Unclaimed |
| Rejected | lapse_appeal_window | RejectedFinal | system; appeal_deadline < now | claim.appeal_window_lapsed | final_at=now |
| Rejected | request_early_deletion | Rejected | claimant; step_up | claim.early_deletion_requested | evidence purged now (evidence.purged_early rows), contacts and notes deleted; fingerprint kept as told at rejection |
| RejectedFinal | request_early_deletion | RejectedFinal | claimant; step_up | claim.early_deletion_requested | evidence purged now (evidence.purged_early rows), contacts and notes deleted |
| Appealed | appeal_reopen | Conflicted | role RV; not_original_decider; step_up; reason; route:competitor | claim.appeal_reopened | appeal=upheld; join claim_conflict; evidence hold stays |
| Appealed | appeal_reopen | InReview | role RV; not_original_decider; step_up; reason; route:clear | claim.appeal_reopened | appeal=upheld; assigned_to_ref=actor; fingerprint of this rejection deleted; second_review_required=true when origin=revoked or listing Revoked; L:claim_submitted if listing Unclaimed; evidence hold stays until the next decision |
| Appealed | appeal_dismiss | RejectedFinal | role RV; not_original_decider; step_up; reason; route:origin_rejected | claim.appeal_dismissed | appeal=dismissed; hold released; evidence delete_after=now+90d; final_at=now; L:claims_closed when the listing is Pending and no active claim remains |
| Appealed | appeal_dismiss | NeedsInfo | role RV; not_original_decider; step_up; reason; route:origin_needs_info | claim.appeal_dismissed | appeal=dismissed; hold released; needs_info_due_at=now+30d |
| Appealed | appeal_dismiss | RevokedFinal | role RV; not_original_decider; step_up; reason; route:origin_revoked | claim.appeal_dismissed | appeal=dismissed; hold released; evidence delete_after=now+90d; listing stays Revoked |
| Appealed | withdraw | Withdrawn | claimant | claim.withdrawn | appeal=withdrawn; hold released; delete_after=+90d; L:claims_closed when the listing is Pending and no active claim remains |
| Appealed | request_early_deletion | Withdrawn | claimant; step_up; explicit confirmation | claim.early_deletion_requested | appeal=withdrawn; evidence purged now (evidence.purged_early rows), contacts and notes deleted; L:claims_closed when the listing is Pending and no active claim remains |
| Withdrawn | request_early_deletion | Withdrawn | claimant; step_up | claim.early_deletion_requested | evidence purged now (evidence.purged_early rows), contacts and notes deleted |
| Conflicted | withdraw | Withdrawn | claimant | claim.withdrawn | delete_after=+90d; if at most one active member remains the conflict dissolves and that claim gets arbitrate_resume (system) |
| Conflicted | arbitrate_resume | Submitted | arbitrator of the conflict (role RV, independent of every earlier assignee of a member claim; step_up; reason) or system route:single_member (conflict dissolved) | claim.arbitration_resumed | assigned_to_ref=null; claim returns to the queue; conflict resolved or dissolved; incumbent Verified claim is untouched |
| Conflicted | arbitrate_reject | Rejected | arbitrator (role RV); step_up; reason REJ-LOST-ARBITRATION | claim.arbitration_rejected | decision(reject); evidence delete_after=+90d; appeal_deadline=+30d; no fingerprint; mail:claim_rejected (never names the other claimant); L:claims_closed when the listing is Pending and no active claim remains |
| Conflicted | request_early_deletion | Withdrawn | claimant; step_up; explicit confirmation | claim.early_deletion_requested | evidence purged now (evidence.purged_early rows), contacts and notes deleted; same dissolve check |
| Superseded | request_early_deletion | Superseded | claimant; step_up | claim.early_deletion_requested | evidence purged now (evidence.purged_early rows), contacts and notes deleted |
| Expired | request_early_deletion | Expired | claimant; step_up | claim.early_deletion_requested | evidence purged now (evidence.purged_early rows), contacts and notes deleted |
| Revoked | appeal | Appealed | claimant; window_open; one_appeal on the revoke decision; statement | claim.appealed | appeal(origin=revoked); evidence hold; listing stays Revoked |
| Revoked | lapse_appeal_window | RevokedFinal | system; appeal_deadline < now | claim.appeal_window_lapsed | final_at=now |
| Revoked | request_early_deletion | Revoked | claimant; step_up | claim.early_deletion_requested | evidence purged now (evidence.purged_early rows), contacts and notes deleted |
| RevokedFinal | request_early_deletion | RevokedFinal | claimant; step_up | claim.early_deletion_requested | evidence purged now (evidence.purged_early rows), contacts and notes deleted |

Illegal pairs (every other pair):

| state | event | to | guard | audit action | side effects |
|---|---|---|---|---|---|
| Draft | {assign, request_info, respond, verify, reject, appeal, appeal_reopen, appeal_dismiss, lapse_appeal_window, conflict_open, arbitrate_resume, arbitrate_reject, supersede, expire, listing_revoked} | ILLEGAL (409) | - | none (0 rows) | none; state, audit, outbox, pack_dirty and jobs unchanged |
| Submitted | {submit, request_info, respond, verify, reject, appeal, appeal_reopen, appeal_dismiss, lapse_appeal_window, timeout, arbitrate_resume, arbitrate_reject, supersede, expire, listing_revoked} | ILLEGAL (409) | - | none (0 rows) | none; state, audit, outbox, pack_dirty and jobs unchanged |
| InReview | {submit, respond, appeal, appeal_reopen, appeal_dismiss, lapse_appeal_window, timeout, arbitrate_resume, arbitrate_reject, supersede, expire, listing_revoked} | ILLEGAL (409) | - | none (0 rows) | none; state, audit, outbox, pack_dirty and jobs unchanged |
| NeedsInfo | {submit, assign, request_info, verify, reject, appeal_reopen, appeal_dismiss, lapse_appeal_window, arbitrate_resume, arbitrate_reject, supersede, expire, listing_revoked} | ILLEGAL (409) | - | none (0 rows) | none; state, audit, outbox, pack_dirty and jobs unchanged |
| Verified | {submit, assign, request_info, respond, verify, reject, appeal, appeal_reopen, appeal_dismiss, lapse_appeal_window, withdraw, timeout, conflict_open, arbitrate_resume, arbitrate_reject} | ILLEGAL (409) | - | none (0 rows) | none; state, audit, outbox, pack_dirty and jobs unchanged |
| {Rejected, Revoked} | {submit, assign, request_info, respond, verify, reject, appeal_reopen, appeal_dismiss, withdraw, timeout, conflict_open, arbitrate_resume, arbitrate_reject, supersede, expire, listing_revoked} | ILLEGAL (409) | - | none (0 rows) | none; state, audit, outbox, pack_dirty and jobs unchanged |
| {RejectedFinal, Withdrawn, Superseded, Expired, RevokedFinal} | {submit, assign, request_info, respond, verify, reject, appeal, appeal_reopen, appeal_dismiss, lapse_appeal_window, withdraw, timeout, conflict_open, arbitrate_resume, arbitrate_reject, supersede, expire, listing_revoked} | ILLEGAL (409) | - | none (0 rows) | none; state, audit, outbox, pack_dirty and jobs unchanged |
| Appealed | {submit, assign, request_info, respond, verify, reject, appeal, lapse_appeal_window, timeout, conflict_open, arbitrate_resume, arbitrate_reject, supersede, expire, listing_revoked} | ILLEGAL (409) | - | none (0 rows) | none; state, audit, outbox, pack_dirty and jobs unchanged |
| Conflicted | {submit, assign, request_info, respond, verify, reject, appeal, appeal_reopen, appeal_dismiss, lapse_appeal_window, timeout, conflict_open, supersede, expire, listing_revoked} | ILLEGAL (409) | - | none (0 rows) | none; state, audit, outbox, pack_dirty and jobs unchanged |

Notes: a claim for a Verified Masjid by someone who is not a member goes to Conflicted at submit (the incumbent stays Verified and keeps editing unless an Operator freezes it, data-model Issue 3). A claim for a Suspended Masjid is held in the queue; verify fails with `guard_failed:listing_not_suspended` until the suspension is lifted. A claim for a Revoked Masjid is reviewed in full and needs a second Operator's agreement. An unreadable or malicious upload never reaches this machine: the pipeline rejects it with 422 and the claim stays Draft.

## 2. Masjid listing status

### 2a. States and events
Unclaimed (imported, curated or suggested, no claim), Pending (a claim is active, or a verification lapsed), Verified (valid 12 months, plus a 30-day grace during which the listing is still Verified and the console shows "expired, renew"), Suspended (temporary stop), Revoked (verification removed). Listing events: `claim_submitted` (emitted only while Unclaimed), `claims_closed` (emitted only while Pending), `verified`, `grace_elapsed`, `suspend`, `lift` (recomputes the target from facts, no stored prior status), `revoke`, `appeal_file`, `appeal_dismiss` (suspension appeals; an upheld appeal is a `lift`).

### 2b. Transition table
States: Unclaimed, Pending, Verified, Suspended, Revoked. Events: claim_submitted, claims_closed, verified, grace_elapsed, suspend, lift, revoke, appeal_file, appeal_dismiss.

5 states x 9 events = 45 pairs: 15 legal (18 rows, route rows share a pair), 30 illegal.

Legal transitions:

| state | event | to | guard | audit action | side effects |
|---|---|---|---|---|---|
| Unclaimed | claim_submitted | Pending | system; emitted by a claim leaving Draft or an appeal that reopens a claim, only while the listing is Unclaimed | listing.pending | pack:dirty(overlay: st=P); base fields unchanged |
| Unclaimed | suspend | Suspended | role MD; step_up; reason SUS-* | listing.suspended | decision(suspend); pack:dirty (overlay row removed); mail:suspended to admins if any |
| Pending | claims_closed | Unclaimed | system; no active claim left; route:never_verified (verified_at is null) | listing.unclaimed | pack:dirty(overlay: st removed) |
| Pending | claims_closed | Pending | system; no active claim left; route:previously_verified (a lapsed listing) | listing.claims_closed | none; an Operator may suspend or leave it; admins can still start a renewal |
| Pending | verified | Verified | system, from claim.verify | listing.verified | verified_at=now; verified_until=now+12 months; grace_until=verified_until+30 days; flags cleared; pack:dirty(base, overlay, sched gh4); admin members granted |
| Pending | suspend | Suspended | role MD; step_up; reason SUS-* | listing.suspended | decision(suspend); pack:dirty |
| Pending | revoke | Revoked | role RV; step_up; reason REV-* | listing.revoked | decision(revoke); masjid_member rows deleted; other active claims get second_review_required=true; pack:dirty; mail:revoked |
| Verified | verified | Verified | system, from a renewal claim.verify; route:renewal | listing.renewed | verified_until=now+12 months (spec rule; an early renewal loses remaining days); flags cleared; verified_claim_id swapped; old claim superseded |
| Verified | grace_elapsed | Pending | system; now >= grace_until | listing.lapsed | pack:dirty(overlay st=P; rules leave sched); mail:lapse_notice; claim.expire |
| Verified | suspend | Suspended | role MD; step_up; reason SUS-* | listing.suspended | decision(suspend); pack:dirty (overlay row and rules removed); phones keep the last schedule up to 30 days and show a status-changed notice |
| Verified | revoke | Revoked | role RV; step_up; reason REV-* | listing.revoked | decision(revoke); claim.listing_revoked; masjid_member rows deleted; pack:dirty; mail:revoked |
| Suspended | lift | Verified | role MD; reason; step_up; for SUS-SECURITY the lifter differs from the suspender; route:in_term (verified_until set, now <= grace_until, verified claim still Verified) | listing.lifted | pack:dirty |
| Suspended | lift | Pending | role MD; reason; step_up; same lifter rule; route:active_or_lapsed (an active claim exists, or verified_at is set but the term has passed) | listing.lifted | pack:dirty (overlay st=P) |
| Suspended | lift | Unclaimed | role MD; reason; step_up; same lifter rule; route:none (no active claim, never verified) | listing.lifted | pack:dirty |
| Suspended | revoke | Revoked | role RV; step_up; reason REV-* | listing.revoked | as revoke from Verified; decision(revoke) |
| Suspended | appeal_file | Suspended | admin of the Masjid; one appeal per suspend decision (unique decision_id); statement | listing.appeal_filed | appeal row; Operator queue item |
| Suspended | appeal_dismiss | Suspended | role RV; not the suspender; step_up; reason | listing.appeal_dismissed | appeal=dismissed (an upheld appeal is a lift) |
| Revoked | verified | Verified | system, from claim.verify; second_look_ok mandatory (second Operator agrees); full review | listing.verified | as Pending verified; masjid_member granted again |

Illegal pairs (every other pair):

| state | event | to | guard | audit action | side effects |
|---|---|---|---|---|---|
| Unclaimed | {claims_closed, verified, grace_elapsed, lift, revoke, appeal_file, appeal_dismiss} | ILLEGAL (409) | - | none (0 rows) | none; state, audit, outbox, pack_dirty and jobs unchanged |
| Pending | {claim_submitted, grace_elapsed, lift, appeal_file, appeal_dismiss} | ILLEGAL (409) | - | none (0 rows) | none; state, audit, outbox, pack_dirty and jobs unchanged |
| Verified | {claim_submitted, claims_closed, lift, appeal_file, appeal_dismiss} | ILLEGAL (409) | - | none (0 rows) | none; state, audit, outbox, pack_dirty and jobs unchanged |
| Suspended | {claim_submitted, claims_closed, verified, grace_elapsed, suspend} | ILLEGAL (409) | - | none (0 rows) | none; state, audit, outbox, pack_dirty and jobs unchanged |
| Revoked | {claim_submitted, claims_closed, grace_elapsed, suspend, lift, revoke, appeal_file, appeal_dismiss} | ILLEGAL (409) | - | none (0 rows) | none; state, audit, outbox, pack_dirty and jobs unchanged |

Undo of a revoke is a new claim with full review and a second Operator (runbook 13); there is no `reset` event.

### 2c. Projection: claim and listing status to the seven FR-016 statuses and the listener badge

| FR-016 status | Derived from | Rule | Overlay file (`st`) | Listener badge |
|---------------|--------------|------|---------------------|----------------|
| Unclaimed | listing | `listing_status = unclaimed` | no overlay row | Unclaimed; name and location marked unverified |
| Pending | listing | `listing_status = pending` | `st = P` only (no madhhab, method, variant, `vu`, `sr`, no rules) | Claimed pending; name and location only |
| Verified | listing | `listing_status = verified`, including the grace period | `st = V`, `vu`, madhhab, method, variant, `sr`; rules in the `sched` bundle | Verified |
| Needs more information | claim | latest claim of the viewing admin for this Masjid is NeedsInfo | listing is Pending | admin only; listeners see Claimed pending |
| Rejected | claim | latest claim is Rejected or RejectedFinal | listing is Unclaimed again if no other claim is active | admin only, with reason and appeal state; listeners see the state as before the claim |
| Suspended | listing | `listing_status = suspended` | no overlay row; no rules | none of the three badges applies (Issues 4); phones keep the last schedule up to 30 days and show a status-changed notice |
| Revoked | listing | `listing_status = revoked` | no overlay row; no rules | as Suspended |

Claim statuses without an FR-016 name (Draft, InReview, Appealed, Withdrawn, Conflicted, Superseded, Expired, RevokedFinal) are admin-console labels only (section 1) and never reach a listener.

## 3. Verification lifecycle timers

Every timer is a column; the sweeper selects by the column and acts only if the column still says so. Example for a decision on 2026-11-02: `verified_until` 2027-11-02 (decision + 12 months), reminder due 2027-10-03 (`verified_until - 30 days`), expiry notice 2027-11-02, grace ends 2027-12-02 (`verified_until + 30 days`), when the listing drops to Pending, the claim becomes Expired and the schedule rules leave the next `sched` build.

| Timer | Column | Set when | Due when | Sweeper | Action | Idempotency |
|-------|--------|----------|----------|---------|--------|-------------|
| Renewal reminder (T-30) | `masjid.reminder_sent_at` | claim.verify (null) | listing Verified, `now >= verified_until - 30 days`, `reminder_sent_at` null | sweep.verification (daily) | mail:renewal_reminder to every admin, set the column, `verification.reminder_sent`; capped at 60 mails per day | dedupe key `verif_reminder:<masjid>:<verified_until epoch>` |
| Expiry notice (T) | `masjid.expiry_notice_sent_at` | claim.verify (null) | `now >= verified_until`, null | sweep.verification | mail:expiry_notice; listing stays Verified; console shows "expired, renew" | `verif_expiry:<masjid>:<epoch>` |
| Grace end, lapse (T+30) | `masjid.grace_until` | claim.verify | `now >= grace_until`, listing Verified | sweep.verification | L:grace_elapsed and claim.expire in one transaction; `lapse_notice_sent_at`; pack:dirty | state guard (already Pending is a no-op) |
| Hard-bounced reminder | `email_outbox.state = hard_bounce` | mail bounce | template is a verification mail | sweep.outbox | `operator_task(bounced_address)`; an Operator reaches the admin by another route; the admin changes the email in the console (step-up) | one task per masjid and verified_until |
| Draft idle | `claim.draft_expires_at` | create_draft (+30 days) | `<= now` | sweep.claim_timers | claim.timeout | state guard |
| Needs-info timeout | `claim.needs_info_due_at` | request_info (+30 days) | `<= now` | sweep.claim_timers | claim.timeout (REJ-NO-RESPONSE) | state guard |
| Appeal window | `claim.appeal_deadline` | reject, revoke, arbitrate_reject (+30 days) | `< now`, status Rejected or Revoked | sweep.claim_timers | claim.lapse_appeal_window | state guard |
| Evidence retention | `evidence_file.delete_after` | any final decision (+90 days); draft withdrawn (+7 days); appeal decision (+90 days) | `<= now`, `hold_reason` null, not purged | sweep.evidence_purge | crypto-shred, delete contacts and notes, `evidence.purged`, then unlink | `purged_at` |
| Appeal hold review | `evidence_file.hold_reason` | appeal | every 30 days while held | sweep.hold_review | `operator_task(hold_review)` for a super-admin | one open task per claim |
| Fingerprint expiry | `evidence_fingerprint.delete_after` | merit rejection (+12 months) | `<= now` | sweep.fingerprint_purge | delete row | row gone |
| Recovery expiry | `recovery_case.expires_at` | start or initiate (+7 days) | `<= now`, state not terminal and not approved | sweep.recovery | expire event | state guard |
| Break-glass delay | `recovery_case.not_before` | approve (+48 h) | `<= now`, state approved | sweep.recovery | execute (re-check) or abort; reminders at `not_before - 24 h` and `- 1 h` | `reminder_24h_at`, `reminder_1h_at`, `executed_at` |
| Reset token | `reset_token.expires_at`, `flow_expires_at` | request (+10 min), open_link (+10 min) | `<= now` | sweep.tokens | expire | state guard |
| Invitation | `invitation.expires_at` | send (+7 days) | `<= now`, pending | sweep.invitations | expire | state guard |
| Transfer | `ownership_transfer.expires_at` | request (+14 days) | `<= now`, open | sweep.transfers | expire | state guard |
| Privacy reminder and overdue | `privacy_request.reminder_due_at`, `due_at` | receive (+20 and +30 days) | reminder null and due; or past due and open | sweep.privacy | reminder mail to the handlers; overdue flag and task | `reminder_sent_at` |
| Contact email of a public write | `contact_delete_after` | case closed (+30 days) | `<= now` | sweep.public_contacts | null the address | column null |
| IP truncation and deletion | `auth_event.ts` | each event | 30 days; 12 months | sweep.auth_event | truncate to /24 or /48; delete | `ip_truncated` |
| Operator pseudonym link | `actor_map.delete_after` | offboarding (+24 months, proposal) | `<= now` | sweep.actor_map | delete row | row gone |
| Superseded pack files | `pack_file.delete_after` | superseded (+30 days minimum) | `<= now` | sweep.packs | delete file and row | row gone |
| Audit anchor and purge | `audit_anchor` | daily; 24-month rule | daily; retention | audit.anchor, audit_purge | head hash off-server; checkpoint then purge | one row per day |
| Import staging | `osm_staging` | batch applied (+90 days) | `<= now` | sweep.import | delete rows | rows gone |

## 4. Recovery machines

Sign-in is email, password and an authenticator code; there is no text message and no social login. Password reset never bypasses the second factor. Losing the authenticator has two paths: with a recovery code it is a second-factor reset (4b, no delay); without one it is break-glass (4c, always 48 hours). A verification call alone never shortcuts the delay: the call is a required step of break-glass, nothing more.

### 4a. Password reset (`reset_token.state`)
States: emailed, link_ok, mfa_ok, completed, expired, voided, locked. Events: open_link, submit_mfa, set_password, expire, void, lock.

7 states x 6 events = 42 pairs: 10 legal (10 rows, route rows share a pair), 32 illegal.

Initial transition (no prior state):

| state | event | to | guard | audit action | side effects |
|---|---|---|---|---|---|
| (none) | request | emailed | public; always answers 202 with the same body and timing; a row, token and email exist only if the account exists; 3 per hour per address, 10 per hour per source | recovery.password_reset.requested | token 256 bits, sha256 stored; expires_at=now+10 min; older open tokens voided; mail:password_reset_link; unknown address: nothing stored, nothing audited |

Legal transitions:

| state | event | to | guard | audit action | side effects |
|---|---|---|---|---|---|
| emailed | open_link | link_ok | POST with the token (never GET); sha256(token) matches; now < expires_at; state emailed | recovery.password_reset.link_opened | flow_expires_at=now+10 min; Referrer-Policy no-referrer |
| emailed | expire | expired | system; expires_at <= now (10 minutes after the email) | recovery.password_reset.expired | none |
| emailed | void | voided | system; a newer request for the account, a password or factor change, break-glass execution, or suspension | recovery.password_reset.voided | none |
| link_ok | submit_mfa | mfa_ok | valid TOTP of a fresh step (single use) or a recovery code (consumed); rate limit 5 per 5 min per session | recovery.password_reset.mfa_verified | a reset never bypasses the second factor (ASVS 6.4.3); failures are counted in Valkey and do not change state |
| {link_ok, mfa_ok} | expire | expired | system; flow_expires_at <= now | recovery.password_reset.expired | none |
| {link_ok, mfa_ok} | void | voided | system; as above | recovery.password_reset.voided | none |
| link_ok | lock | locked | system; 5 failed code attempts in the flow | recovery.password_reset.locked | email:reset_locked; a new request is needed |
| mfa_ok | set_password | completed | password passes policy (12 characters, Operators 15, at most 128, local breached list, context words); not equal to the current one | recovery.password_reset.completed | new argon2id hash; session_epoch+1; all sessions closed; other tokens voided; mail:password_changed to the current address (and to the previous address if the email changed in the last 24 h) |

Illegal pairs (every other pair):

| state | event | to | guard | audit action | side effects |
|---|---|---|---|---|---|
| emailed | {submit_mfa, set_password, lock} | ILLEGAL (409) | - | none (0 rows) | none; state, audit, outbox, pack_dirty and jobs unchanged |
| link_ok | {open_link, set_password} | ILLEGAL (409) | - | none (0 rows) | none; state, audit, outbox, pack_dirty and jobs unchanged |
| mfa_ok | {open_link, submit_mfa, lock} | ILLEGAL (409) | - | none (0 rows) | none; state, audit, outbox, pack_dirty and jobs unchanged |
| {completed, expired, voided, locked} | {open_link, submit_mfa, set_password, expire, void, lock} | ILLEGAL (409) | - | none (0 rows) | none; state, audit, outbox, pack_dirty and jobs unchanged |

### 4b. Second-factor reset (`recovery_case.kind = mfa_reset`)
Variant A only: the admin proves the password and the email link and presents a valid recovery code, which is consumed at `start`; then an Operator (reviewer or above, never the requester) approves. No delay. Notifications: the admin gets mail at start, at execution and on denial; the old authenticator is gone at execution.
States: requested, in_review, approved, executed, denied, cancelled, expired. Events: take, approve, execute, deny, cancel, expire.

7 states x 6 events = 42 pairs: 9 legal (9 rows, route rows share a pair), 33 illegal.

Initial transition (no prior state):

| state | event | to | guard | audit action | side effects |
|---|---|---|---|---|---|
| (none) | start | requested | admin has passed the password reset link step (password + email link) AND presents a valid recovery code; the code is verified and consumed here; account kind admin or muazzin; no open recovery_case for the account | recovery.mfa_reset.requested | recovery_code_consumed_at=now; expires_at=now+7 days; operator queue item. An admin with no recovery code does not enter this machine: the console tells them to ask for break-glass (an Operator opens it) |

Legal transitions:

| state | event | to | guard | audit action | side effects |
|---|---|---|---|---|---|
| requested | take | in_review | role RV; actor is not the initiator; onboarding_ack; step_up | recovery.mfa_reset.taken | assigned_to_ref=actor |
| requested | cancel | cancelled | the admin who started it | recovery.mfa_reset.cancelled | recovery code stays consumed (the admin gets new codes at enrolment) |
| requested | expire | expired | system; expires_at <= now (7 days) | recovery.mfa_reset.expired | mail:mfa_reset_expired |
| in_review | approve | approved | role RV; actor is not the initiator (constraint recovery_case_approver_not_initiator); step_up; account recently changed (new email, new password) means ask for a call to an independent number first (runbook 14.2) | recovery.mfa_reset.approved | approved_by_ref=actor; the Operator never sees a secret or sets a credential |
| in_review | deny | denied | role RV; not the initiator; step_up; reason | recovery.mfa_reset.denied | mail:mfa_reset_denied |
| in_review | cancel | cancelled | the admin who started it, or the assignee | recovery.mfa_reset.cancelled | none |
| in_review | expire | expired | system; expires_at <= now | recovery.mfa_reset.expired | none |
| approved | execute | executed | system, immediately after approval; no delay in this variant | recovery.mfa_reset.executed | delete TOTP secret and recovery codes; session_epoch+1; all sessions closed; one-time enrolment link (10 min); forced password login, new authenticator and new recovery codes; mail:mfa_reset_executed |
| approved | cancel | cancelled | the admin, or any Operator, before execution | recovery.mfa_reset.cancelled | none |

Illegal pairs (every other pair):

| state | event | to | guard | audit action | side effects |
|---|---|---|---|---|---|
| requested | {approve, execute, deny} | ILLEGAL (409) | - | none (0 rows) | none; state, audit, outbox, pack_dirty and jobs unchanged |
| in_review | {take, execute} | ILLEGAL (409) | - | none (0 rows) | none; state, audit, outbox, pack_dirty and jobs unchanged |
| approved | {take, approve, deny, expire} | ILLEGAL (409) | - | none (0 rows) | none; state, audit, outbox, pack_dirty and jobs unchanged |
| {executed, denied, cancelled, expired} | {take, approve, execute, deny, cancel, expire} | ILLEGAL (409) | - | none (0 rows) | none; state, audit, outbox, pack_dirty and jobs unchanged |

### 4c. Break-glass (`recovery_case.kind = break_glass` or `operator_recovery`)
Initiator: a super-admin (initiate and `log_call` are SA only). Approver: a different Operator who is a reviewer or super-admin, never a moderator (constraint `recovery_case_approver_not_initiator`). The delay starts at the approver's approval (`not_before = approved_at + 48 h`, constraint `recovery_case_not_before_48h`). During the delay the admin and every committee contact hold a cancel link, reminders go at 24 h and 1 h, and the account cannot change factors. `operator_recovery` is an Operator's own lockout: a different super-admin initiates, a second Operator (reviewer or super-admin) co-signs, an identity check by video or in person replaces the committee call, and the same 48 h applies (proposal, Issues 8).
States: initiated, call_verified, approved, executed, cancelled, expired. Events: log_call, approve, remind, execute, abort, cancel, expire.

6 states x 7 events = 42 pairs: 10 legal (10 rows, route rows share a pair), 32 illegal.

Initial transition (no prior state):

| state | event | to | guard | audit action | side effects |
|---|---|---|---|---|---|
| (none) | initiate | initiated | initiator has role super_admin; for break_glass the subject is an admin or muazzin account with no usable recovery code; for operator_recovery the subject is an Operator and the initiator is a different super-admin; step_up; reason; no open recovery_case for the account | recovery.break_glass.initiated | expires_at=now+7 days; assigned_to_ref=initiator (so the initiator may read the committee contacts of the case, FR-032); operator_task created |

Legal transitions:

| state | event | to | guard | audit action | side effects |
|---|---|---|---|---|---|
| initiated | log_call | call_verified | role SA, and the actor is the initiator (assigned); a verification_call with outcome C1 to a committee contact on file; step_up | recovery.break_glass.call_logged | call_id set; for operator_recovery the call is an identity check by video or in person and no committee contact is involved |
| {initiated, call_verified} | cancel | cancelled | the admin, the initiator, or any Operator | recovery.break_glass.cancelled | cancel_reason required |
| initiated | expire | expired | system; expires_at <= now (7 days) | recovery.break_glass.expired | none |
| call_verified | approve | approved | role RV (reviewer or super_admin, never a moderator); actor is not the initiator (constraint recovery_case_approver_not_initiator); for operator_recovery a second Operator (role RV) also co-signs (second_approved_by_ref, distinct from both); step_up | recovery.break_glass.approved | approved_at=now; not_before=approved_at+48 h (constraint recovery_case_not_before_48h); at once mail:break_glass_started to the admin and to every committee contact with a cancel link (notified_admin_at, notified_contacts_at); factor changes blocked for the account |
| call_verified | expire | expired | system; expires_at <= now | recovery.break_glass.expired | none |
| approved | remind | approved | system; now >= not_before-24 h and reminder_24h_at is null, or now >= not_before-1 h and reminder_1h_at is null | recovery.break_glass.reminder_sent | mail:break_glass_reminder to the admin and contacts; sets the matching flag (idempotent) |
| approved | execute | executed | system; now >= not_before (409 delay_not_elapsed before that, the API is authoritative); re-check: not cancelled, Masjid listing not Suspended or Revoked | recovery.break_glass.executed | delete TOTP and recovery codes; session_epoch+1; Valkey sessions purged; reset tokens voided; force password reset and new enrolment with new recovery codes; mail to admin, contacts and Operators |
| approved | abort | cancelled | system; the re-check at not_before failed (Masjid Suspended or Revoked, or account disabled) | recovery.break_glass.aborted | cancel_reason=recheck_failed; mail to initiator and approver |
| approved | cancel | cancelled | the admin (cancel link), the initiator, the approver, or any Operator | recovery.break_glass.cancelled | cancel_reason required; if the cancel comes from someone saying they did not ask, suspend the account (SUS-SECURITY) |

Illegal pairs (every other pair):

| state | event | to | guard | audit action | side effects |
|---|---|---|---|---|---|
| initiated | {approve, remind, execute, abort} | ILLEGAL (409) | - | none (0 rows) | none; state, audit, outbox, pack_dirty and jobs unchanged |
| call_verified | {log_call, remind, execute, abort} | ILLEGAL (409) | - | none (0 rows) | none; state, audit, outbox, pack_dirty and jobs unchanged |
| approved | {log_call, approve, expire} | ILLEGAL (409) | - | none (0 rows) | none; state, audit, outbox, pack_dirty and jobs unchanged |
| {executed, cancelled, expired} | {log_call, approve, remind, execute, abort, cancel, expire} | ILLEGAL (409) | - | none (0 rows) | none; state, audit, outbox, pack_dirty and jobs unchanged |

### 4d. Account status (`account.status`)
Short brute-force cool-offs live in Valkey (5 failures per 15 minutes, doubling to 24 h) and never change status. Status `locked` follows 10 failures for an Operator (20 in 24 h for an admin or Muazzin, proposal). `unlock` is the Operator action on a locked account: a moderator or super-admin for an admin or Muazzin; a different super-admin plus a second Operator for an Operator.
States: pending_mfa, active, locked, disabled. Events: enrol_mfa, lock, unlock, disable, reinstate, delete.

4 states x 6 events = 24 pairs: 11 legal (12 rows, route rows share a pair), 13 illegal.

Initial transition (no prior state):

| state | event | to | guard | audit action | side effects |
|---|---|---|---|---|---|
| (none) | create | pending_mfa | sign-up (admin) with a strong password; invitation accept (muazzin, co_admin); Operator creation by a super-admin | account.created | email verified by link (auth.email_verified); no editing screen until enrol_mfa |

Legal transitions:

| state | event | to | guard | audit action | side effects |
|---|---|---|---|---|---|
| pending_mfa | enrol_mfa | active | the account owner; a valid TOTP code from the new secret; recovery codes shown once | auth.mfa_enrolled | mfa_factor.activated_at=now; session id rotated; until then no handler is reachable (FR-004) |
| pending_mfa | disable | disabled | role MD (suspend, reason SUS-*) or RV (revoke, reason REV-*); not self; step_up | account.disabled | session_epoch+1; sessions closed; for an offboarded Operator also run the offboarding checklist |
| pending_mfa | delete | (deleted) | privacy_request delete InProgress with identity verified; handler role MD | account.deleted | see privacy fulfil |
| active | lock | locked | system; account kind operator and 10 failed sign-ins, or admin or muazzin and 20 failed sign-ins in 24 h (proposal); the shorter Valkey cool-offs never change status | account.locked | session_epoch+1; sessions closed; mail:account_locked |
| {active, locked} | disable | disabled | as above | account.disabled | as above |
| {active, locked, disabled} | delete | (deleted) | same | account.deleted | same |
| locked | unlock | active | account kind admin or muazzin: role MD; account kind operator: role SA different from the account plus a co-signature by a second Operator (role RV); step_up for each signer | account.unlocked | failure counters cleared; mail:account_unlocked |
| disabled | reinstate | active | role MD; step_up; for SUS-SECURITY a different Operator than the one who disabled; route:mfa_enrolled | account.reinstated | none |
| disabled | reinstate | pending_mfa | same; route:no_mfa (no active factor) | account.reinstated | forces enrolment |

Illegal pairs (every other pair):

| state | event | to | guard | audit action | side effects |
|---|---|---|---|---|---|
| pending_mfa | {lock, unlock, reinstate} | ILLEGAL (409) | - | none (0 rows) | none; state, audit, outbox, pack_dirty and jobs unchanged |
| active | {enrol_mfa, unlock, reinstate} | ILLEGAL (409) | - | none (0 rows) | none; state, audit, outbox, pack_dirty and jobs unchanged |
| locked | {enrol_mfa, lock, reinstate} | ILLEGAL (409) | - | none (0 rows) | none; state, audit, outbox, pack_dirty and jobs unchanged |
| disabled | {enrol_mfa, lock, unlock, disable} | ILLEGAL (409) | - | none (0 rows) | none; state, audit, outbox, pack_dirty and jobs unchanged |

### 4e. Public lockout request (no session, no state machine)
An admin who is locked out and has no recovery code asks for help with `POST https://api.<domain>/v1/recovery-request` with only the email address. The route is unauthenticated and public: proof-of-work and honeypot, 3 per hour per address hash and 10 per hour per source (counters in Valkey only), and the **same 202 answer, body and timing** whether or not the email exists. If the account exists and has no open recovery case or open `recovery_request` task, it creates one `operator_task(kind = recovery_request, subject_id = account id)` and writes `recovery.lockout_requested` (actor null, role public). Nothing else is stored: no email address, no address of the sender, no free text. A super-admin picks the task up and, if the admin cannot use a recovery code, initiates break-glass (4c); the task never grants anything by itself.
## 5. Moderation, membership and privacy workflows

### 5a. Abuse reports (public write, no identifier)
States: New, Triaged, Investigating, ActionTaken, Dismissed, Duplicate, Spam. Events: triage, investigate, resolve_action, dismiss, mark_duplicate, mark_spam, reopen.

7 states x 7 events = 49 pairs: 15 legal (15 rows, route rows share a pair), 34 illegal.

Initial transition (no prior state):

| state | event | to | guard | audit action | side effects |
|---|---|---|---|---|---|
| (none) | receive | New | public POST to api.; proof-of-work and honeypot; rate limit per hashed-address bucket held in Valkey only; body at most 2000 characters; stores cell id, country, Masjid id, text, optional typed email; no coordinates, no address, no hash of an address | abuse.received | actor_ref null, actor_role public |

Legal transitions:

| state | event | to | guard | audit action | side effects |
|---|---|---|---|---|---|
| New | triage | Triaged | role MD | abuse.triaged | assigned_to_ref=actor |
| {New, Triaged, Investigating} | dismiss | Dismissed | role MD; reason (not actionable) | abuse.dismissed | closed_at=now; contact_delete_after=+30 days |
| {New, Triaged, Investigating} | mark_duplicate | Duplicate | role MD; duplicate_of_id set | abuse.duplicate | closed_at=now; contact_delete_after=+30 days |
| {New, Triaged} | mark_spam | Spam | role MD | abuse.spam | closed_at=now; contact_delete_after=+30 days |
| Triaged | investigate | Investigating | role MD; assignee | abuse.investigating | Operator may call the Masjid; notes only in case_note |
| Investigating | resolve_action | ActionTaken | role MD; outcome in (corrected, suspended, revoked, retired); suspended needs MD, revoked needs RV; step_up for those | abuse.actioned | outcome corrected = masjid_version change_kind operator; suspended or revoked = the listing event with its own audit row; retired = masjid.retired_at; closed_at=now; contact_delete_after=+30 days |
| {ActionTaken, Dismissed, Duplicate, Spam} | reopen | Triaged | role MD; now < closed_at+30 days; reason | abuse.reopened | closed_at=null; contact_delete_after=null |

Illegal pairs (every other pair):

| state | event | to | guard | audit action | side effects |
|---|---|---|---|---|---|
| New | {investigate, resolve_action, reopen} | ILLEGAL (409) | - | none (0 rows) | none; state, audit, outbox, pack_dirty and jobs unchanged |
| Triaged | {triage, resolve_action, reopen} | ILLEGAL (409) | - | none (0 rows) | none; state, audit, outbox, pack_dirty and jobs unchanged |
| Investigating | {triage, investigate, mark_spam, reopen} | ILLEGAL (409) | - | none (0 rows) | none; state, audit, outbox, pack_dirty and jobs unchanged |
| {ActionTaken, Dismissed, Duplicate, Spam} | {triage, investigate, resolve_action, dismiss, mark_duplicate, mark_spam} | ILLEGAL (409) | - | none (0 rows) | none; state, audit, outbox, pack_dirty and jobs unchanged |

### 5b. Suggestions (public write, no identifier)
States: New, InReview, Accepted, Rejected, Duplicate, Spam. Events: take, release, accept, reject, mark_duplicate, mark_spam.

6 states x 6 events = 36 pairs: 9 legal (9 rows, route rows share a pair), 27 illegal.

Initial transition (no prior state):

| state | event | to | guard | audit action | side effects |
|---|---|---|---|---|---|
| (none) | receive | New | public POST to api.; same protections as abuse; kind=new_masjid carries no coordinates (an Operator places the pin) and the accepted terms version | suggestion.received | actor_ref null, actor_role public |

Legal transitions:

| state | event | to | guard | audit action | side effects |
|---|---|---|---|---|---|
| New | take | InReview | role MD | suggestion.taken | assigned_to_ref=actor |
| {New, InReview} | reject | Rejected | role MD; reason | suggestion.rejected | closed_at=now; contact_delete_after=+30 days |
| {New, InReview} | mark_duplicate | Duplicate | role MD; masjid_id of the existing Masjid | suggestion.duplicate | closed_at=now; contact_delete_after=+30 days |
| {New, InReview} | mark_spam | Spam | role MD | suggestion.spam | closed_at=now; contact_delete_after=+30 days |
| InReview | release | New | assignee or super_admin | suggestion.released | assigned_to_ref=null |
| InReview | accept | Accepted | role MD; assignee; kind=correction: apply as a new masjid_version (change_kind suggestion) with expected_version_no (409 on conflict); kind=new_masjid: an Operator enters the location (inside the 3x3 block of the suggested cell), no unresolved high duplicate candidate, terms_version recorded, not copied from another database | suggestion.accepted | new_masjid creates masjid(source=suggested, Unclaimed, published_at=now, contrib_terms_version) + version 1; result_masjid_id; closed_at=now; contact_delete_after=+30 days; pack:dirty(base) |

Illegal pairs (every other pair):

| state | event | to | guard | audit action | side effects |
|---|---|---|---|---|---|
| New | {release, accept} | ILLEGAL (409) | - | none (0 rows) | none; state, audit, outbox, pack_dirty and jobs unchanged |
| InReview | {take} | ILLEGAL (409) | - | none (0 rows) | none; state, audit, outbox, pack_dirty and jobs unchanged |
| {Accepted, Rejected, Duplicate, Spam} | {take, release, accept, reject, mark_duplicate, mark_spam} | ILLEGAL (409) | - | none (0 rows) | none; state, audit, outbox, pack_dirty and jobs unchanged |

### 5c. Invitations (Muazzin or co-admin; expire after 7 days)
Removing a Muazzin is a membership delete by any admin (`member.removed`, step-up); removing an admin is an ownership transfer of kind `remove_admin` (5e).
States: Pending, Accepted, Declined, Expired, Revoked. Events: accept, decline, revoke, expire.

5 states x 4 events = 20 pairs: 4 legal (4 rows, route rows share a pair), 16 illegal.

Initial transition (no prior state):

| state | event | to | guard | audit action | side effects |
|---|---|---|---|---|---|
| (none) | send | Pending | actor is admin of the Masjid; listing Verified and not frozen; kind muazzin or co_admin; invitee not already a member; at most 20 pending per Masjid; 3 per hour per address; an admin who is a muazzin elsewhere is allowed | invitation.sent | token 256 bits (sha256 stored); expires_at=now+7 days; mail:invitation; a co_admin invite also notifies every current admin (shared ownership is visible) |

Legal transitions:

| state | event | to | guard | audit action | side effects |
|---|---|---|---|---|---|
| Pending | accept | Accepted | token valid; now < expires_at; accepting account email equals the invited email; account kind is not operator; MFA enrolled before the role is usable; kind=co_admin and account kind muazzin upgrades to admin (account.kind_changed) | invitation.accepted | masjid_member row added; invitee_email nulled; mail:invitation_accepted to the inviter; for co_admin mail:admin_added to every existing admin |
| Pending | decline | Declined | the invitee (token) | invitation.declined | invitee_email nulled |
| Pending | revoke | Revoked | inviter, or any admin of the Masjid; or an Operator | invitation.revoked | invitee_email nulled |
| Pending | expire | Expired | system; expires_at <= now (7 days) | invitation.expired | invitee_email nulled |

Illegal pairs (every other pair):

| state | event | to | guard | audit action | side effects |
|---|---|---|---|---|---|
| {Accepted, Declined, Expired, Revoked} | {accept, decline, revoke, expire} | ILLEGAL (409) | - | none (0 rows) | none; state, audit, outbox, pack_dirty and jobs unchanged |

### 5d. Privacy requests (30-day deadline, reminder at day 20)
States: Received, IdentityPending, InProgress, Fulfilled, Refused, Withdrawn. Events: request_identity, verify_identity, fulfil, refuse, withdraw.

6 states x 5 events = 30 pairs: 10 legal (10 rows, route rows share a pair), 20 illegal.

Initial transition (no prior state):

| state | event | to | guard | audit action | side effects |
|---|---|---|---|---|---|
| (none) | receive | Received | signed-in admin or muazzin (self-service form) or an email to the privacy address logged by an Operator; kind export or delete | privacy.received | due_at=created_at+30 days; reminder_due_at=created_at+20 days (sweep.privacy sends privacy.reminder_sent once); overdue = now > due_at in a non-terminal state raises privacy.overdue_flagged and an operator_task |

Legal transitions:

| state | event | to | guard | audit action | side effects |
|---|---|---|---|---|---|
| Received | request_identity | IdentityPending | role MD | privacy.identity_requested | mail asking the requester to confirm through a signed-in session or an Operator callback to the account's email |
| Received | verify_identity | InProgress | route:session_identity (request was made from a signed-in session of the same account; automatic) | privacy.identity_verified | identity_method=session; handler assigned (role MD) |
| {Received, IdentityPending, InProgress} | refuse | Refused | role MD; reason code; the answer is still due by due_at | privacy.refused | closed_at=now; answer mail with reasons (e.g. audit and fingerprint exceptions) |
| {Received, IdentityPending, InProgress} | withdraw | Withdrawn | the requester | privacy.withdrawn | closed_at=now |
| IdentityPending | verify_identity | InProgress | role MD; callback or session confirmation recorded; route:callback | privacy.identity_verified | identity_method=callback |
| InProgress | fulfil | Fulfilled | role MD; step_up; kind=export: the account's own data only; kind=delete: account deletion run (below) | privacy.fulfilled | export: encrypted file for 7 days, privacy.export_generated; delete: open claims withdrawn and evidence purged, invitations revoked, recovery cases cancelled, memberships removed, sessions closed, auth_event cascade, actor_map row deleted, account row deleted (listings, versions and audit rows stay); operator_task orphaned_listing if the last admin of a Verified Masjid; confirmation mail sent before the address is deleted; closed_at=now; requester_email nulled at +30 days |

Illegal pairs (every other pair):

| state | event | to | guard | audit action | side effects |
|---|---|---|---|---|---|
| Received | {fulfil} | ILLEGAL (409) | - | none (0 rows) | none; state, audit, outbox, pack_dirty and jobs unchanged |
| IdentityPending | {request_identity, fulfil} | ILLEGAL (409) | - | none (0 rows) | none; state, audit, outbox, pack_dirty and jobs unchanged |
| InProgress | {request_identity, verify_identity} | ILLEGAL (409) | - | none (0 rows) | none; state, audit, outbox, pack_dirty and jobs unchanged |
| {Fulfilled, Refused, Withdrawn} | {request_identity, verify_identity, fulfil, refuse, withdraw} | ILLEGAL (409) | - | none (0 rows) | none; state, audit, outbox, pack_dirty and jobs unchanged |

### 5e. Ownership transfer (Operator approval required, FR-018)
States: Requested, Consented, Executed, Declined, Rejected, Withdrawn, Expired. Events: consent, decline, approve, reject, withdraw, expire.

7 states x 6 events = 42 pairs: 8 legal (8 rows, route rows share a pair), 34 illegal.

Initial transition (no prior state):

| state | event | to | guard | audit action | side effects |
|---|---|---|---|---|---|
| (none) | request | Requested | kind=transfer: requester is an admin of a Verified, unfrozen Masjid, names the incoming email; no open transfer for the Masjid | transfer.requested | token for the incoming party; mail:transfer_offer; expires_at=now+14 days |
| (none) | request | Consented | kind=remove_admin: requester is an admin, target is another admin of the same Masjid; no consent step | transfer.requested | goes straight to the Operator queue; the target is told by mail |

Legal transitions:

| state | event | to | guard | audit action | side effects |
|---|---|---|---|---|---|
| Requested | consent | Consented | the incoming account (token); MFA enrolled; accepted admin_terms | transfer.consented | incoming_account_id set; operator queue item |
| Requested | decline | Declined | the incoming account | transfer.declined | incoming_email nulled |
| {Requested, Consented} | withdraw | Withdrawn | the requester | transfer.withdrawn | incoming_email nulled |
| Requested | expire | Expired | system; expires_at <= now (14 days) | transfer.expired | incoming_email nulled |
| Consented | approve | Executed | role RV; actor is not the requester (constraint); step_up; call_ok (a verification_call to a committee contact or independent number, outcome C1); listing Verified and not Suspended; no open conflict; outgoing still an admin; incoming account active with MFA | transfer.approved | kind=transfer: masjid_member admin row of the requester replaced by the incoming account; kind=remove_admin: the target's row deleted; mail to old and new admins; listing and verification dates unchanged; terminal_at=now |
| Consented | reject | Rejected | role RV; step_up; reason | transfer.rejected | mail to the requester |
| Consented | expire | Expired | system; expires_at <= now | transfer.expired | incoming_email nulled |

Illegal pairs (every other pair):

| state | event | to | guard | audit action | side effects |
|---|---|---|---|---|---|
| Requested | {approve, reject} | ILLEGAL (409) | - | none (0 rows) | none; state, audit, outbox, pack_dirty and jobs unchanged |
| Consented | {consent, decline} | ILLEGAL (409) | - | none (0 rows) | none; state, audit, outbox, pack_dirty and jobs unchanged |
| {Executed, Declined, Rejected, Withdrawn, Expired} | {consent, decline, approve, reject, withdraw, expire} | ILLEGAL (409) | - | none (0 rows) | none; state, audit, outbox, pack_dirty and jobs unchanged |

### 5f. Conflicting claims and arbitration (FR-018)
A conflict exists per Masjid (one open at a time). Claims in it are Conflicted and unassigned; challengers hold no membership, so they have no edit rights; the arbitrator, not an earlier assignee, reads the evidence and contacts of the members.
States: Open, Resolved, Dissolved. Events: join, freeze_incumbent, assign_arbitrator, resolve, dissolve.

3 states x 5 events = 15 pairs: 5 legal (5 rows, route rows share a pair), 10 illegal.

Initial transition (no prior state):

| state | event | to | guard | audit action | side effects |
|---|---|---|---|---|---|
| (none) | open | Open | system; a claim is submitted for a Masjid that has another active claim by a different claimant, or a Verified claim by someone else | conflict.opened | one open conflict per Masjid (partial unique); claims go Conflicted with assigned_to_ref=null; challengers have no edit rights because they hold no masjid_member row |

Legal transitions:

| state | event | to | guard | audit action | side effects |
|---|---|---|---|---|---|
| Open | join | Open | system; another competing claim is submitted for the Masjid | conflict.member_joined | claim_conflict_member row; the claim goes Conflicted |
| Open | freeze_incumbent | Open | role RV; step_up; reason (suspected impersonation or dispute); only when a Verified incumbent exists | conflict.incumbent_frozen | freeze_incumbent=true: the incumbent's admins lose edit rights until resolve (the spec's literal both-frozen reading is opt-in, data-model Issue 3) |
| Open | assign_arbitrator | Open | role RV; arbitrator is none of the earlier assignees of member claims; step_up | conflict.arbitrator_assigned | arbitrator_ref set; the arbitrator may read evidence and committee contacts of member claims |
| Open | resolve | Resolved | arbitrator (role RV); step_up; reason; winner chosen (a member claim or the incumbent)  | conflict.resolved | winner claim: arbitrate_resume; each other challenger: arbitrate_reject (REJ-LOST-ARBITRATION); if the incumbent wins it is untouched; freeze lifted; winner_claim_id set |
| Open | dissolve | Dissolved | system; at most one active member remains (others withdrew or were rejected) | conflict.dissolved | the remaining claim gets arbitrate_resume (system); freeze lifted |

Illegal pairs (every other pair):

| state | event | to | guard | audit action | side effects |
|---|---|---|---|---|---|
| {Resolved, Dissolved} | {join, freeze_incumbent, assign_arbitrator, resolve, dissolve} | ILLEGAL (409) | - | none (0 rows) | none; state, audit, outbox, pack_dirty and jobs unchanged |

## 6. Illegal-transition test recipe

One generated test per machine, from the tables above (or from the TypeScript table they are generated from; a CI step asserts the two are equal).

| machine | states | events | pairs | legal | illegal | API events (409 on illegal) | system events (function call) |
|---|---|---|---|---|---|---|---|
| claim | 14 | 19 | 266 | 44 | 222 | submit, assign, request_info, respond, verify, reject, appeal, appeal_reopen, appeal_dismiss, withdraw, arbitrate_resume, arbitrate_reject, request_early_deletion | lapse_appeal_window, timeout, conflict_open, supersede, expire, listing_revoked |
| listing | 5 | 9 | 45 | 15 | 30 | suspend, lift, revoke, appeal_file, appeal_dismiss | claim_submitted, claims_closed, verified, grace_elapsed |
| password_reset | 7 | 6 | 42 | 10 | 32 | open_link, submit_mfa, set_password | expire, void, lock |
| mfa_reset | 7 | 6 | 42 | 9 | 33 | take, approve, deny, cancel | execute, expire |
| break_glass | 6 | 7 | 42 | 10 | 32 | log_call, approve, cancel | remind, execute, abort, expire |
| account | 4 | 6 | 24 | 11 | 13 | enrol_mfa, unlock, disable, reinstate, delete | lock |
| abuse | 7 | 7 | 49 | 15 | 34 | triage, investigate, resolve_action, dismiss, mark_duplicate, mark_spam, reopen | none |
| suggestion | 6 | 6 | 36 | 9 | 27 | take, release, accept, reject, mark_duplicate, mark_spam | none |
| invitation | 5 | 4 | 20 | 4 | 16 | accept, decline, revoke | expire |
| privacy | 6 | 5 | 30 | 10 | 20 | request_identity, verify_identity, fulfil, refuse, withdraw | none |
| transfer | 7 | 6 | 42 | 8 | 34 | consent, decline, approve, reject, withdraw | expire |
| conflict | 3 | 5 | 15 | 5 | 10 | freeze_incumbent, assign_arbitrator, resolve | join, dissolve |
| **total** | | | **653** | **150** | **503** | | |

1. **Coverage check.** Expand the sets, then assert `legal pairs UNION illegal pairs = states x events` and that the two sets are disjoint. Print the totals above; a changed count fails the build until this file is regenerated (`git diff --exit-code`). `satisfies Record<State, Record<Event, Rule | null>>` makes a missing cell a compile error.
2. **Fixtures.** A factory `makeIn(machine, state)` creates a row in that state through a test-only role that sets `app.fixture = on` (the transition trigger skips only for that setting; production roles cannot set it). For a claim it also creates the Masjid, claimant, assignee and a complete evidence set so that no guard but the state can fail.
3. **Illegal pair through the API** (events not marked system). Act as a fully authorised principal (right role, second factor, fresh step-up, assigned to the case). Snapshot: the row, `count(*)` of `audit_log`, `email_outbox`, `pack_dirty_cell`, `evidence_file` (including `purged_at`), `masjid_member`, pg-boss jobs, and `updated_at`. Call the endpoint. Expect `409` with body `{code: "illegal_transition", state, event}`; the snapshot must be byte-identical afterwards, in particular **zero audit rows**.
4. **Illegal pair for system events.** Call `transition(machine, state, event, ctx)` directly: result `ILLEGAL_TRANSITION`, snapshot unchanged. Separately assert, from the route list, that no HTTP route exposes a system event.
5. **SQL level.** For every triple `(from, event, to)` not in `state_transition`, run `SET LOCAL app.event = event; UPDATE ... SET status = to WHERE status = from` and expect SQLSTATE `DN409` from the trigger (about 4,100 statements for the claim machine, a few seconds in one rolled-back transaction).
6. **Legal pair.** Per row, three calls: an actor missing the role or ownership gives `403` and zero audit rows; an actor who fails one named business guard gives `409 guard_failed:<name>` or `422` and zero audit rows; the satisfying call gives the `to` state, exactly one audit row with `action` equal to the table value for the primary object (cascaded rows share the action and carry their own `object_type`), the listed side-effect rows, and the same `to` through every route (route test: each `route:` guard is true for exactly one row).
7. **Model-based property test** (`fc.commands` with a 20-line reference interpreter and a fake clock; 200 runs per pull request, 20,000 nightly with the seed logged). Invariants: (I1) a merit-rejected claim with an identical fingerprint within 12 months ends RejectedFinal and never re-enters review; (I2) at most one `appeal` row per decision; (I3) listing Verified implies exactly one Verified claim equal to `verified_claim_id`; (I4) Revoked implies no `masjid_member` rows; (I5) an open conflict implies no challenger holds a member row; (I6) with the clock at decision +335 d the reminder exists once, at +365 d the expiry notice, at +395 d the listing is Pending and the claim Expired (calendar months, so the dates are computed, not added); (I7) every legal transition writes at least one audit row and every rejected call writes none; (I8) a purged evidence row has a null `wrapped_dek`, and no row outlives `delete_after` without a hold; (I9) break-glass reaches `executed` only at `now >= approved_at + 48 h` with approver different from initiator and all earlier sessions invalid; (I10) after a password reset or a second-factor reset executes, a session with an older `session_epoch` is rejected.
8. **Three consumers of one table.** The generated Markdown (this file); the seeded `state_transition` rows checked by the trigger; the console, whose action buttons come from the table: a Playwright test asserts the buttons shown for a claim equal the legal events of its state that the viewer's role may call.

## 7. Event catalogue (audit action names)

One dotted namespace, `^[a-z_]+(\.[a-z_]+)+$`. Sink `audit_log` rows are hash-chained and never hold an address; `auth_event` holds the address for 30 days (data-model section 4). Audience `admin, operator` rows are visible to admins of the Masjid (never evidence, contact or Operator-name rows). The 172 actions below cover every audit action in the tables above plus the non-transition events (notes, evidence reads, imports, keys). If a row trigger fires without a named action, the default is `<table>.<insert|update|delete>`.

| audit action | emitted by | sink | audience | object_type |
|---|---|---|---|---|
| auth.login_ok | POST /login after second factor | auth_event | operator | account |
| auth.login_failed | POST /login, wrong password or code | auth_event | operator | account |
| auth.mfa_failed | second factor failure | auth_event | operator | account |
| auth.lockout | brute-force cool-off or Operator lock | audit_log + auth_event | operator | account |
| auth.email_verified | email link opened after sign-up, invitation or email change | audit_log | admin, operator | account |
| auth.step_up_ok | password plus fresh TOTP for a risky action | audit_log | operator | account |
| auth.mfa_enrolled | account.enrol_mfa | audit_log | admin, operator | account |
| auth.recovery_code_used | password reset or second-factor reset | audit_log + auth_event | operator | account |
| auth.recovery_codes_regenerated | console, step-up | audit_log | admin, operator | account |
| auth.password_changed | console change | audit_log | admin, operator | account |
| auth.email_changed | console change with verification of the new address | audit_log | admin, operator | account |
| auth.session_terminated | user, Operator, concurrency eviction, epoch bump | audit_log + auth_event | operator | account |
| account.created | account.create | audit_log | operator | account |
| account.locked | account.lock | audit_log | operator | account |
| account.unlocked | account.unlock | audit_log | operator | account |
| account.disabled | account.disable | audit_log | operator | account |
| account.reinstated | account.reinstate | audit_log | operator | account |
| account.deleted | privacy fulfil (delete) | audit_log | operator | account |
| account.kind_changed | invitation accept (muazzin to admin) | audit_log | operator | account |
| recovery.lockout_requested | public lockout request (no session) | audit_log | operator | operator_task |
| recovery.password_reset.requested | password_reset.request (known accounts only) | audit_log | operator | reset_token |
| recovery.password_reset.link_opened | password_reset.open_link | audit_log | operator | reset_token |
| recovery.password_reset.mfa_verified | password_reset.submit_mfa | audit_log | operator | reset_token |
| recovery.password_reset.completed | password_reset.set_password | audit_log | admin, operator | reset_token |
| recovery.password_reset.expired | sweep.tokens | audit_log | operator | reset_token |
| recovery.password_reset.voided | sweep.tokens, newer request | audit_log | operator | reset_token |
| recovery.password_reset.locked | password_reset.lock | audit_log | operator | reset_token |
| recovery.mfa_reset.requested | mfa_reset.start | audit_log | operator | recovery_case |
| recovery.mfa_reset.taken | mfa_reset.take | audit_log | operator | recovery_case |
| recovery.mfa_reset.approved | mfa_reset.approve | audit_log | operator | recovery_case |
| recovery.mfa_reset.executed | mfa_reset.execute | audit_log | admin, operator | recovery_case |
| recovery.mfa_reset.denied | mfa_reset.deny | audit_log | operator | recovery_case |
| recovery.mfa_reset.cancelled | mfa_reset.cancel | audit_log | operator | recovery_case |
| recovery.mfa_reset.expired | sweep.recovery | audit_log | operator | recovery_case |
| recovery.break_glass.initiated | break_glass.initiate (also operator_recovery) | audit_log | operator | recovery_case |
| recovery.break_glass.call_logged | break_glass.log_call | audit_log | operator | recovery_case |
| recovery.break_glass.approved | break_glass.approve | audit_log | operator | recovery_case |
| recovery.break_glass.reminder_sent | break_glass.remind (24 h, 1 h) | audit_log | operator | recovery_case |
| recovery.break_glass.executed | break_glass.execute | audit_log | admin, operator | recovery_case |
| recovery.break_glass.aborted | break_glass.abort (re-check failed) | audit_log | operator | recovery_case |
| recovery.break_glass.cancelled | break_glass.cancel | audit_log | operator | recovery_case |
| recovery.break_glass.expired | sweep.recovery | audit_log | operator | recovery_case |
| claim.draft_created | claim.create_draft | audit_log | admin, operator | claim |
| claim.submitted | claim.submit (clear) | audit_log | admin, operator | claim |
| claim.conflicted | claim.submit or conflict_open or appeal_reopen (competitor) | audit_log | admin, operator | claim |
| claim.rejected_identical | claim.submit (fingerprint match) | audit_log | admin, operator | claim |
| claim.assigned | claim.assign from Submitted | audit_log | operator | claim |
| claim.reassigned | claim.assign from InReview | audit_log | operator | claim |
| claim.info_requested | claim.request_info | audit_log | admin, operator | claim |
| claim.info_provided | claim.respond | audit_log | admin, operator | claim |
| claim.verified | claim.verify | audit_log | admin, operator | claim |
| claim.rejected | claim.reject | audit_log | admin, operator | claim |
| claim.rejected_no_response | claim.timeout from NeedsInfo | audit_log | admin, operator | claim |
| claim.appealed | claim.appeal | audit_log | admin, operator | claim |
| claim.appeal_reopened | claim.appeal_reopen | audit_log | admin, operator | claim |
| claim.appeal_dismissed | claim.appeal_dismiss | audit_log | admin, operator | claim |
| claim.appeal_window_lapsed | claim.lapse_appeal_window | audit_log | admin, operator | claim |
| claim.withdrawn | claim.withdraw | audit_log | admin, operator | claim |
| claim.timed_out | claim.timeout from Draft | audit_log | admin, operator | claim |
| claim.arbitration_resumed | claim.arbitrate_resume | audit_log | operator | claim |
| claim.arbitration_rejected | claim.arbitrate_reject | audit_log | admin, operator | claim |
| claim.superseded | claim.supersede | audit_log | admin, operator | claim |
| claim.expired | claim.expire | audit_log | admin, operator | claim |
| claim.revoked | claim.listing_revoked | audit_log | admin, operator | claim |
| claim.early_deletion_requested | claim.request_early_deletion | audit_log | admin, operator | claim |
| claim.note_added | case note on any open case | audit_log | operator | case_note |
| listing.pending | listing.claim_submitted | audit_log | admin, operator | masjid |
| listing.unclaimed | listing.claims_closed (never verified) | audit_log | admin, operator | masjid |
| listing.claims_closed | listing.claims_closed (previously verified) | audit_log | admin, operator | masjid |
| listing.verified | listing.verified | audit_log | admin, operator | masjid |
| listing.renewed | listing.verified from Verified | audit_log | admin, operator | masjid |
| listing.lapsed | listing.grace_elapsed | audit_log | admin, operator | masjid |
| listing.suspended | listing.suspend | audit_log | admin, operator | masjid |
| listing.lifted | listing.lift | audit_log | admin, operator | masjid |
| listing.revoked | listing.revoke | audit_log | admin, operator | masjid |
| listing.appeal_filed | listing.appeal_file | audit_log | admin, operator | masjid |
| listing.appeal_dismissed | listing.appeal_dismiss | audit_log | admin, operator | masjid |
| listing.retired | merge, vanished, operator removal | audit_log | admin, operator | masjid |
| verification.reminder_sent | sweep.verification at T-30 days | audit_log | admin, operator | masjid |
| verification.expiry_notice_sent | sweep.verification at T | audit_log | admin, operator | masjid |
| verification.lapse_notice_sent | sweep.verification at T+30 days | audit_log | admin, operator | masjid |
| verification.call_logged | verification_call insert | audit_log | operator | verification_call |
| verification.bounce_task_created | sweep.outbox on hard bounce | audit_log | operator | operator_task |
| evidence.uploaded | upload pipeline | audit_log | operator | evidence_file |
| evidence.view_start | evidence_open() (fail closed) | audit_log | operator | evidence_file |
| evidence.view_end | console close | audit_log | operator | evidence_file |
| evidence.hold_set | appeal | audit_log | operator | evidence_file |
| evidence.hold_released | appeal decided | audit_log | operator | evidence_file |
| evidence.purged | sweep.evidence_purge | audit_log | operator | evidence_file |
| evidence.purged_early | early deletion | audit_log | operator | evidence_file |
| evidence.purged_all | last evidence row of a case purged (starts the 12-month audit clock) | audit_log | operator | claim |
| evidence.missing_after_restore | restore drill sweeper | audit_log | operator | evidence_file |
| contact.added | claim submit, break-glass contact entry | audit_log | operator | committee_contact |
| contact.view | read_committee_contact() | audit_log | operator | committee_contact |
| contact.purged | sweep.evidence_purge | audit_log | operator | committee_contact |
| masjid.created | import apply, create claim, suggestion accept, curated | audit_log | admin, operator | masjid |
| masjid.edited | profile edit (new masjid_version) | audit_log | admin, operator | masjid |
| masjid.rolled_back | rollback (new version) | audit_log | admin, operator | masjid |
| masjid.osm_vanished_flagged | import apply for claimed or verified Masjids | audit_log | operator | masjid |
| schedule.edited | schedule save (new schedule_version) | audit_log | admin, operator | schedule |
| schedule.rolled_back | schedule rollback | audit_log | admin, operator | schedule |
| member.added | membership insert | audit_log | admin, operator | masjid_member |
| member.removed | membership delete | audit_log | admin, operator | masjid_member |
| invitation.sent | invitation.send | audit_log | admin, operator | invitation |
| invitation.accepted | invitation.accept | audit_log | admin, operator | invitation |
| invitation.declined | invitation.decline | audit_log | admin, operator | invitation |
| invitation.revoked | invitation.revoke | audit_log | admin, operator | invitation |
| invitation.expired | sweep.invitations | audit_log | admin, operator | invitation |
| transfer.requested | transfer.request | audit_log | admin, operator | ownership_transfer |
| transfer.consented | transfer.consent | audit_log | admin, operator | ownership_transfer |
| transfer.declined | transfer.decline | audit_log | admin, operator | ownership_transfer |
| transfer.approved | transfer.approve | audit_log | admin, operator | ownership_transfer |
| transfer.rejected | transfer.reject | audit_log | admin, operator | ownership_transfer |
| transfer.withdrawn | transfer.withdraw | audit_log | admin, operator | ownership_transfer |
| transfer.expired | sweep.transfers | audit_log | admin, operator | ownership_transfer |
| conflict.opened | conflict.open | audit_log | operator | claim_conflict |
| conflict.member_joined | conflict.join | audit_log | operator | claim_conflict |
| conflict.incumbent_frozen | conflict.freeze_incumbent | audit_log | admin, operator | claim_conflict |
| conflict.arbitrator_assigned | conflict.assign_arbitrator | audit_log | operator | claim_conflict |
| conflict.resolved | conflict.resolve | audit_log | operator | claim_conflict |
| conflict.dissolved | conflict.dissolve | audit_log | operator | claim_conflict |
| operator.bootstrapped | first super-admin script | audit_log | operator | operator |
| operator.created | super-admin | audit_log | operator | operator |
| operator.role_granted | operator_role insert | audit_log | operator | operator_role |
| operator.role_revoked | operator_role revoke | audit_log | operator | operator_role |
| operator.offboarded | offboarding checklist | audit_log | operator | operator |
| operator.cases_reassigned | offboarding | audit_log | operator | operator |
| audit.search | Operator reads audit_log | audit_log | operator | audit_log |
| audit.chain_verified | nightly verify_chain() | audit_log | operator | audit_log |
| audit.anchored | daily anchor | audit_log | operator | audit_anchor |
| audit.purged | audit_purge() writes this first | audit_log | operator | audit_log |
| import.batch_started | importer | audit_log | operator | osm_import_batch |
| import.batch_approved | moderator or super-admin | audit_log | operator | osm_import_batch |
| import.batch_applied | super-admin publish | audit_log | operator | osm_import_batch |
| import.batch_rejected | review | audit_log | operator | osm_import_batch |
| import.batch_rolled_back | super-admin reverts an applied batch | audit_log | operator | osm_import_batch |
| import.batch_failed | importer | audit_log | operator | osm_import_batch |
| duplicate.detected | importer, nightly detector | audit_log | operator | duplicate_candidate |
| duplicate.merged | moderator merge | audit_log | operator | masjid_merge |
| duplicate.dismissed | moderator | audit_log | operator | duplicate_candidate |
| duplicate.deferred | moderator | audit_log | operator | duplicate_candidate |
| suggestion.received | public POST | audit_log | operator | suggestion |
| suggestion.taken | suggestion.take | audit_log | operator | suggestion |
| suggestion.released | suggestion.release | audit_log | operator | suggestion |
| suggestion.accepted | suggestion.accept | audit_log | operator | suggestion |
| suggestion.rejected | suggestion.reject | audit_log | operator | suggestion |
| suggestion.duplicate | suggestion.mark_duplicate | audit_log | operator | suggestion |
| suggestion.spam | suggestion.mark_spam | audit_log | operator | suggestion |
| abuse.received | public POST | audit_log | operator | abuse_report |
| abuse.triaged | abuse.triage | audit_log | operator | abuse_report |
| abuse.investigating | abuse.investigate | audit_log | operator | abuse_report |
| abuse.actioned | abuse.resolve_action | audit_log | operator | abuse_report |
| abuse.dismissed | abuse.dismiss | audit_log | operator | abuse_report |
| abuse.duplicate | abuse.mark_duplicate | audit_log | operator | abuse_report |
| abuse.spam | abuse.mark_spam | audit_log | operator | abuse_report |
| abuse.reopened | abuse.reopen | audit_log | operator | abuse_report |
| privacy.received | privacy.receive | audit_log | operator | privacy_request |
| privacy.identity_requested | privacy.request_identity | audit_log | operator | privacy_request |
| privacy.identity_verified | privacy.verify_identity | audit_log | operator | privacy_request |
| privacy.fulfilled | privacy.fulfil | audit_log | operator | privacy_request |
| privacy.refused | privacy.refuse | audit_log | operator | privacy_request |
| privacy.withdrawn | privacy.withdraw | audit_log | operator | privacy_request |
| privacy.reminder_sent | sweep.privacy at day 20 | audit_log | operator | privacy_request |
| privacy.overdue_flagged | sweep.privacy after day 30 | audit_log | operator | privacy_request |
| privacy.export_generated | privacy.fulfil (export) | audit_log | operator | privacy_request |
| privacy.export_downloaded | requester download | audit_log | operator | privacy_request |
| task.created | system or Operator | audit_log | operator | operator_task |
| task.done | Operator | audit_log | operator | operator_task |
| pack.generation_published | pack builder flips a generation | audit_log | operator | pack_build |
| key.kek_rotated | key rotation runbook | audit_log | operator | key |
| key.pepper_rotated | key rotation runbook | audit_log | operator | key |
| email.hard_bounced | mail bounce handler | audit_log | operator | email_outbox |

## 8. Issues found

| # | Contradiction or gap | Where | Recommendation |
|---|----------------------|-------|----------------|
| 1 | FR-016 lists claim and listing statuses together | spec FR-016, r7 B8 | Two machines; section 2c derives all seven. Reword FR-016 |
| 2 | Appeals: spec says once, brief says once per decision; a claim can be appealed at NeedsInfo and again at Rejected. No appeal window is given | FR-016 | One per decision (database unique); window 30 days so evidence (deleted at +90 days) still exists; confirm with the owner |
| 3 | Runbook 4.3 says a claim on a Suspended Masjid is held, and on a Revoked Masjid needs a second Operator; an earlier idea was to refuse such claims | runbook, spec edge case | Held (verify guard) and `second_review_required`, as modelled |
| 4 | Listener presentation of Suspended and Revoked is undefined (spec has three badges; overlay `st` is V or P) | spec US1, R-27, edge cases | Add `st = S` or keep absence of the overlay row plus the phone's status-changed notice; decide before the overlay schema freezes |
| 5 | Roles: the runbook lets a reviewer suspend and a moderator approve break-glass; the rulings say suspend and reinstate are MD, revoke RV, break-glass initiate and `log_call` SA only, second approval RV | runbook 1 and 14.3, r7 1c | This file follows the rulings (consistent with r7's never-list: a reviewer does not suspend and files a `fraud_flag` task); update the runbook tables; privacy MD and import publish SA are unchanged |
| 6 | Needs-info timeout: runbook closes as Rejected REJ-NO-RESPONSE; modelled as RejectedFinal without a fingerprint so the admin can start a new claim | runbook 4.3 | Confirm |
| 7 | Break-glass needs a committee contact "on file" but contacts are deleted 90 days after the decision | FR-026, FR-032 | data-model Issue 2; `log_call` fails with `guard_failed:contact_on_file` if none exists |
| 8 | Operator lockout: coordinator ruling is a different super-admin plus a second Operator, with no delay stated | rulings, runbook 14.4 | Modelled as `operator_recovery` on the break-glass machine with the same 48 h (proposal) |
| 9 | r1 variant B (a call alone to reset the second factor) is dropped by ruling, but FR-026 still names "a verification call" | FR-026 | Amend FR-026: reset needs a recovery code and an Operator; no code means break-glass |
| 10 | r7 and R-24 estimate 112 claim pairs and one table | R-24 | Now 266 claim pairs and 653 over 12 machines; all generated |
| 11 | The Verified incumbent is never moved to Conflicted (the `conflict_open` pair is illegal for Verified); the spec says both claimants lose edit rights | FR-018 | `freeze_incumbent` is an Operator choice (data-model Issue 3) |
| 12 | `arbitrate_resume` returns the winner to the queue (Submitted) rather than straight to verification, because the call is still required | FR-018 | Proposal |
| 13 | `verified_until = decision + 12 months` costs an early renewal its remaining days | FR-017 | Renewal opens at T-30 so the loss is at most 30 days |
| 14 | Draft evidence is deleted 7 days after a timeout or withdrawal, not 90 (nothing was decided) | FR-008 | Proposal; confirm |
| 15 | The claim `submit` check of identical evidence compares only against merit rejections (REJ-NOT-AUTHORISED, REJ-EVIDENCE-INAUTHENTIC, REJ-CONTACT-DISOWNED, REJ-NOT-A-MASJID); lost arbitration and no response store no fingerprint | FR-016 | Confirm so a loser can resubmit |
