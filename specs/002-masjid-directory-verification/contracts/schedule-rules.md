# Contract: Masjid Schedule Rules (`masjid-schedule/1`)

**Spec**: [../spec.md](../spec.md) (FR-013, FR-014, FR-015, FR-020, US2) | **Decisions**: [../research.md](../research.md) R-06, R-29 | **Related**: [static-files.md](static-files.md) (where records are published), [directory-client.md](directory-client.md) (sync and staleness)

A Masjid's schedule is published as RULES plus an IANA zone. The phone expands them into dated times with the shared pure-Dart package `packages/masjid_schedule` (depends on `prayer_engine` only; no `dart:io`, no Flutter), compiled with `dart compile js -O2` for Node (API validation) and the browser (console 14-day preview). One implementation, one set of golden vectors. Normative words: MUST, SHOULD, MAY.

## 1. Inputs that are NOT in the rules

| Needed | Source | Field |
|--------|--------|-------|
| Coordinates | base record of the same `id` | `la`, `lo` |
| Calculation method, Asr method, high-latitude rule, per-prayer offsets | overlay record of the same id (static-files.md 4.3) | `cm` (method), `as` (Asr: `s` or `h`), `hl` (`m`, `s`, `a`), `of` (six minute offsets) |
| Zone | the rules record | `tz` |
| Calculated instants | `prayer_engine` (Phase 0) | `PrayerTimeEngine.timesFor` |

If a rule uses a calculated form and the overlay has no `cm`, validation fails with `calc_settings_missing`. Sunrise, Imsak, midnight and last third stay calculated (a Masjid schedule replaces the five prayers only).

## 2. Wire format

Rules record (inside `m` of a sched bundle; standalone use adds `"fmt":"masjid-schedule/1"`):

```json
{"id":"m4kx72ab","tz":"Asia/Jakarta","rev":7,"upd":"2026-10-20T04:11:00Z","r":[
 {"f":"11-01","t":"03-14","p":{
    "fj":{"a":["c",0],"i":["a",15]},"dh":{"a":["c",3],"i":["a",10]},"as":{"a":["c",0],"i":["a",10]},
    "mg":{"a":["c",2],"i":["a",5]},"is":{"a":["f","19:30"],"i":["f","19:45"]}},
  "j":[{"a":["f","12:00"],"k":["f","11:40"],"l":"ar"},{"a":["f","13:15"],"l":"id"}]},
 {"f":"03-15","t":"10-31","p":{ /* same shape */ }}]}
```

| Key | Meaning |
|-----|---------|
| `id`, `tz`, `rev`, `upd` | Masjid id; IANA zone; revision (equals overlay `sv`); informational UTC time |
| `r` | 1 to 12 range rules |
| `f`, `t` | first and last day, inclusive: `MM-DD` (repeats every year) or `YYYY-MM-DD` (one period) |
| `p` | the five prayers `fj`, `dh`, `as`, `mg`, `is`, all required; each `{a, i?}` |
| `a` | Azaan time form (fixed or calculated) |
| `i` | Iqamah time form (fixed, calculated or after Azaan); optional |
| `j` | Jumu'ah shifts, 1 to 4, optional per range; each `{a, k?, l?, d?}` |
| `k`, `l`, `d` | khutbah start (fixed or calculated form); language tag; ISO weekday, default 5 (only 5 is valid) |

Time forms (arrays, tag first):

| Form | Wire | Meaning | Allowed in |
|------|------|---------|-----------|
| Fixed | `["f","HH:mm"]` | wall clock in `tz` | `a`, `i`, shift `a`, `k` |
| Calculated plus offset | `["c",off]` or `["c",off,"u5"]` | engine time of the same prayer (Dhuhr for Jumu'ah) plus `off` minutes (-120 to 120); optional rounding `n` (nearest, half up) or `u` (up) to step 5, 10, 15 or 30 | `a`, `i`, shift `a`, `k` |
| After Azaan | `["a",min]` | Azaan instant plus `min` minutes (1 to 120) | `i` only |

### Why compact keys (measured)

A 300-Masjid area bundle (2 to 3 ranges each, 2 Jumu'ah shifts, random times) serialised both ways:

| Form | raw per record | records in a 400 KB part | gzip, 300 records | brotli, 300 records |
|------|----------------|--------------------------|-------------------|---------------------|
| compact keys (above) | 824 B | 485 | 26.9 KB | 6.9 KB |
| verbose names (`ranges`, `prayers`, `azaan`, `{"type":"fixed","value":...}`) | 1,892 B | 211 | 31.2 KB | 7.5 KB |

On the wire the difference is 14% and padding hides it, so wire size is NOT the reason. The reason is the 500,000-byte UNCOMPRESSED limit and the part count (static-files.md section 5): verbose keys split a bundle at 211 verified Masjids instead of 485 and double the parts a phone must fetch (every part of an area is always fetched). So compact keys, nothing more compact (no integer minutes for fixed times: `HH:mm` stays readable).

## 3. JSON Schema (`contracts/schemas/masjid-schedule-1.json`)

The schema checks SHAPE and types. Bounds that have their own issue code (offsets, shift count, range count, rounding step) are checked by the validator so the code is specific. Writers are strict (`additionalProperties:false`); readers on the phone ignore unknown keys.

```json
{"$schema":"https://json-schema.org/draft/2020-12/schema","title":"masjid-schedule/1 record","type":"object",
 "additionalProperties":false,"required":["id","tz","rev","r"],
 "properties":{"fmt":{"const":"masjid-schedule/1"},"id":{"type":"string","pattern":"^m[a-z2-7]{7}$"},
  "tz":{"type":"string","minLength":3,"maxLength":40},"rev":{"type":"integer","minimum":1},
  "upd":{"type":"string","format":"date-time"},
  "r":{"type":"array","minItems":1,"items":{"$ref":"#/$defs/range"}}},
 "$defs":{
  "date":{"type":"string","pattern":"^([0-9]{4}-)?(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])$"},
  "hm":{"type":"string","pattern":"^([01][0-9]|2[0-3]):[0-5][0-9]$"},
  "fixed":{"type":"array","prefixItems":[{"const":"f"},{"$ref":"#/$defs/hm"}],"minItems":2,"maxItems":2},
  "calc":{"type":"array","prefixItems":[{"const":"c"},{"type":"integer"},{"type":"string","pattern":"^[nu][0-9]{1,2}$"}],"minItems":2,"maxItems":3},
  "after":{"type":"array","prefixItems":[{"const":"a"},{"type":"integer"}],"minItems":2,"maxItems":2},
  "azaanT":{"oneOf":[{"$ref":"#/$defs/fixed"},{"$ref":"#/$defs/calc"}]},
  "iqamahT":{"oneOf":[{"$ref":"#/$defs/fixed"},{"$ref":"#/$defs/calc"},{"$ref":"#/$defs/after"}]},
  "prayer":{"type":"object","additionalProperties":false,"required":["a"],
   "properties":{"a":{"$ref":"#/$defs/azaanT"},"i":{"$ref":"#/$defs/iqamahT"}}},
  "shift":{"type":"object","additionalProperties":false,"required":["a"],
   "properties":{"a":{"$ref":"#/$defs/azaanT"},"k":{"$ref":"#/$defs/azaanT"},
    "l":{"type":"string","pattern":"^[a-z]{2,3}(-[A-Za-z0-9]{2,8})*$"},"d":{"type":"integer","minimum":1,"maximum":7}}},
  "range":{"type":"object","additionalProperties":false,"required":["f","t","p"],
   "properties":{"f":{"$ref":"#/$defs/date"},"t":{"$ref":"#/$defs/date"},
    "p":{"type":"object","additionalProperties":false,"required":["fj","dh","as","mg","is"],
     "properties":{"fj":{"$ref":"#/$defs/prayer"},"dh":{"$ref":"#/$defs/prayer"},"as":{"$ref":"#/$defs/prayer"},
      "mg":{"$ref":"#/$defs/prayer"},"is":{"$ref":"#/$defs/prayer"}}},
    "j":{"type":"array","minItems":1,"items":{"$ref":"#/$defs/shift"}}}}}}
```

## 4. Date ranges

| Rule | Detail |
|------|--------|
| One form per record | all `MM-DD` (yearly) or all `YYYY-MM-DD` (dated); mixing is `range_mixed_forms` |
| Yearly | evaluated on a 365-day year (`02-29` is not a valid value; in a leap year 29 February uses the range that covers 28 February). Together the ranges MUST cover every day exactly once. One range may wrap the year end (`f` after `t`, for example `11-01` to `03-14`) |
| Dated | ranges MUST join with no gap and no overlap from the first `f` to the last `t`; the schedule applies from the first `f` to the last `t`; outside that interval the day falls back to calculated times; a warning `range_ends_soon` fires when the last `t` is under 30 days away |
| Overlap, gap | `range_overlap`, `range_gap`, each naming the first offending date |
| Order | any order accepted; the console serialiser sorts by start for byte-stable output |

## 5. Expansion semantics (normative)

`expandDay(record, localDate, engine, settings) -> MasjidDay{azaan[5], iqamah[5], jumuah[], flags}`. Instants are UTC.

| # | Rule |
|---|------|
| E1 | The Masjid zone `tz` governs every local date and clock reading. The phone's zone is never used for expansion (only for the "your phone is elsewhere" banner and quiet hours). |
| E2 | Pick the range containing `localDate` (yearly: by `MM-DD`; dated: by full date). None: the whole day falls back to calculated times. |
| E3 | Fixed `HH:mm` converts with `wallToUtc(tz, localDate, minutes)` (E4). |
| E4 | `wallToUtc` MUST be sign-independent: let A and B be the zone offsets one day before and one day after the wall time read as UTC. If A = B use it. Otherwise each of `naive - A`, `naive - B` is valid when the zone offset at that instant equals the offset used. Both valid (a repeated hour): the EARLIER instant, the first occurrence. Neither valid (a skipped hour): `naive - B`, the offset in force after the change, and the result carries `gapShifted`. |
| E5 | Calculated: take the engine instant for the prayer (Masjid coordinates, `tz`, overlay settings), floor to the whole minute, add `off` minutes as an absolute duration. |
| E6 | Rounding works on the LOCAL wall clock: take the local minute-of-day of the instant, round (`u` up, `n` nearest with half up) to the step, convert back with `wallToUtc` (so E4 applies). Rounding on UTC would be wrong in zones whose offset is not a multiple of the step (for example +5:45). |
| E7 | Iqamah after Azaan: Azaan instant plus `min` minutes, absolute duration (across a DST change it is still `min` real minutes). Iqamah calculated: the engine time of the same prayer, E5 and E6. |
| E8 | A result whose local date differs from `localDate` is invalid (see E11). Azaan keys MUST be strictly increasing in the order fajr, dhuhr, asr, maghrib, isha. |
| E9 | Jumu'ah: on a local Friday each shift is expanded like a prayer, using calculated Dhuhr as the base of `["c",...]`. On other days `j` is ignored. A shift whose `d` is not 5 is rejected at validation (`jumuah_not_friday`). The expander returns all shifts; the planner wrapper uses the shift the listener chose (`jumuahShiftIndex`, default 0) for the Friday `dhuhr:<date>` alert and shows the rest. |
| E10 | A calculated time the engine cannot produce (polar `null`) leaves that prayer null in the Masjid day; the wrapper then uses the calculated value (also null) per prayer. |
| E11 | Runtime guard: an invalid Iqamah (not after its Azaan, or on another local date) is dropped and the Azaan shown alone; an invalid Azaan falls back to calculated for that prayer and flags `invalidRule`. Per prayer and per day, never the whole schedule. |

### DST and horizon statements

| # | Statement |
|---|-----------|
| D1 | Fixed times in a repeated hour resolve to the first occurrence; in a skipped hour to the instant with the post-change offset and flag `gapShifted` (E4). This is the documented Phase 0 `LocalClock.toUtc` behaviour; Phase 0's code does not do it east of Greenwich (Issues 1). |
| D2 | The phone prefers its OS offsets only for its own zone; any other Masjid zone uses the bundled `timezone` data (tzdata 2026e). The console shows the tzdata version; after a government rule change the preview and a phone can differ until the app updates (R-06). |
| D3 | Horizon: 30 consecutive LOCAL dates in `tz`, from the local date (in `tz`) of the last successful sync, inclusive: D0 to D29. A 23-hour or 25-hour day counts as one date. Dates outside use calculated times, per day. |
| D4 | Staleness: the schedule is stale when `now - syncedAt > 30 days`, where `syncedAt` is the last successful sync (HTTP 200 or 304, or a manifest that confirms the held `overlay.gen`, directory-client.md section 8), NOT the admin's last edit. A stable schedule therefore does not expire. A stale schedule means calculated times everywhere and a banner. |
| D5 | Time moving backwards (`ClockSanityCheck.movedBackward`) distrusts `syncedAt`: the schedule is treated as stale until the next sync. |
| D6 | Renewal: the Android renewal alert date is capped at `min(existing, expiresAt - 3 days)`, `expiresAt = syncedAt + 30 days` (planner input `masjidExpiresAt`). |

## 6. Validation issue codes

`validate(record, {settings?, engine?}) -> List<Issue{code, severity, path, message_key, args}>`. `error` rejects the save (API 422), `warning` shows in the console preview and never blocks. Static checks need no engine; expansion checks run the expander over all 365 days of a reference year (and the 14-day preview) and need coordinates and settings.

| Code | Sev | Condition |
|------|-----|-----------|
| `schema_invalid` | error | shape does not match the schema |
| `bad_version` | error | `fmt` or bundle `rf` is not `masjid-schedule/1` |
| `unknown_zone` | error | `tz` not in the bundled tz database |
| `bad_time_format`, `bad_date` | error | not `HH:mm`; not a real calendar day |
| `range_overlap`, `range_gap` | error | section 4 |
| `range_mixed_forms` | error | `MM-DD` and `YYYY-MM-DD` mixed |
| `too_many_ranges` | error | more than 12 ranges |
| `offset_out_of_range` | error | calculated offset beyond -120..120, Iqamah-after beyond 1..120 |
| `bad_rounding` | error | step not 5, 10, 15 or 30, or mode not `n` or `u` |
| `iqamah_before_azaan` | error | Iqamah not after its Azaan on some day |
| `iqamah_crosses_midnight` | error | Iqamah on another local date than its Azaan |
| `azaan_crosses_midnight` | error | calculated plus offset leaves its local date |
| `prayer_order` | error | Azaan times not strictly increasing |
| `jumuah_not_friday` | error | a shift with `d` other than 5 |
| `too_many_shifts` | error | more than 4 shifts |
| `empty_shift_list` | error | `j` present and empty |
| `calc_settings_missing` | error | calculated form and no overlay `cm` |
| `time_in_dst_gap` | warning | a fixed time is `gapShifted` on some day (first date given) |
| `time_in_dst_overlap` | warning | a fixed time falls in a repeated hour |
| `iqamah_gap_unusual` | warning | Iqamah under 3 or over 60 minutes after Azaan |
| `fajr_after_sunrise` | warning | Fajr Azaan not before calculated sunrise |
| `khutbah_before_azaan` | warning | khutbah start earlier than the shift's Azaan |
| `jumuah_missing` | warning | a range has no `j` |
| `jumuah_shifts_close` | warning | two shifts under 15 minutes apart |
| `calc_polar_null` | warning | a calculated time is null on some day |
| `range_ends_soon` | warning | dated form ends within 30 days |

## 7. Golden test vectors

Files `packages/masjid_schedule/test_vectors/*.json`, generated by the Dart expander (committed), replayed by `dart test`, by `node --test` against the compiled JS and available to any future port. Calculated times are STUBS so a vector does not depend on astronomy.

```json
{"format":"masjid-schedule-vectors/1","tzdata":"2026e","cases":[{
  "name":"fixed_normal_day","zone":"Europe/London","rules":{ /* a rules record */ },
  "settings":{"cm":"muslimWorldLeague","as":"s","hl":"m","of":[0,0,0,0,0,0],"la":51.5,"lo":-0.12},
  "calc":{"2026-10-22":{"dhuhr":"2026-10-22T11:52:40Z"}},
  "dates":["2026-10-22"],
  "expect":{"2026-10-22":{"azaan":{"dhuhr":"2026-10-22T12:00:00Z"},"iqamah":{"dhuhr":"2026-10-22T12:10:00Z"},"jumuah":[],"flags":{}}},
  "expect_issues":[{"code":"iqamah_crosses_midnight","severity":"error","path":"r[0].p.is.i"}],
  "horizon":{"syncedAt":"2026-10-15T23:30:00Z","expect":{"first":"2026-10-16","last":"2026-11-14","count":30}}}]}
```

`calc` lists only the prayers a case uses (a missing one used by a rule is a harness error); a case has `expect`, `expect_issues` or both; flags are `gapShifted` per prayer. The doc values below were computed with an independent JavaScript reference of rules E3 to E6 while writing; the Dart expander is the source of truth, and a first-run mismatch means this document or the code is wrong and must be fixed before the vectors freeze.

| # | Case | Zone, date | Input | Expected |
|---|------|-----------|-------|----------|
| 1 | Fixed time, normal day | Europe/London, 2026-10-22 (BST, +01:00) | Dhuhr `["f","13:00"]` Iqamah `["a",10]`; Isha `["f","20:30"]` | Dhuhr 2026-10-22T12:00:00Z; Iqamah 12:10:00Z; Isha 19:30:00Z |
| 2a | Fixed in spring-forward gap | America/New_York, 2026-03-08 (02:00 EST to 03:00 EDT at 07:00Z) | Fajr `["f","02:30"]` (contrived) | 2026-03-08T06:30:00Z, `gapShifted` (post-change offset -04:00) |
| 2b | Same, east of Greenwich | Europe/London, 2026-03-29 (01:00Z change) | Fajr `["f","01:30"]` | 2026-03-29T00:30:00Z, `gapShifted` |
| 3a | Fixed in autumn overlap | America/New_York, 2026-11-01 (06:00Z change) | Fajr `["f","01:30"]` | 2026-11-01T05:30:00Z (first occurrence, EDT); warning `time_in_dst_overlap` |
| 3b | Same, east of Greenwich | Europe/London, 2026-10-25 (01:00Z change) | Fajr `["f","01:30"]` | 2026-10-25T00:30:00Z (first, BST). Phase 0 `LocalClock.toUtc` returns 01:30:00Z here (the second occurrence): the vector exists to catch that |
| 4a | Calculated plus offset | Asia/Kolkata, 2026-10-22 (+05:30) | stub Dhuhr 06:11:40Z, `["c",3]` | floor to 06:11, +3: 2026-10-22T06:14:00Z |
| 4b | Offset plus rounding up | Asia/Kolkata, 2026-10-22 | stub Maghrib 12:19:30Z, `["c",2,"u5"]` | 12:21Z is 17:51 local, up to 17:55: 2026-10-22T12:25:00Z |
| 4c | Fixed in a 30-minute zone | Asia/Kolkata, 2026-10-22 | Dhuhr `["f","13:15"]` | 2026-10-22T07:45:00Z |
| 4d | Rounding on the local clock | Asia/Kathmandu (+05:45), 2026-10-22 | stub Asr 09:48:50Z, `["c",0,"u30"]` | 09:48Z is 15:33 local, up to 16:00: 2026-10-22T10:15:00Z (rounding on UTC would give 10:00Z) |
| 5 | Iqamah after Azaan crossing midnight | any, any | Isha `["f","23:50"]`, Iqamah `["a",20]` | rejected: error `iqamah_crosses_midnight` at `r[0].p.is.i` |
| 6a | Southern hemisphere, day before | Australia/Sydney, 2026-10-03 (AEST +10) | Fajr `["f","04:30"]` | 2026-10-02T18:30:00Z |
| 6b | Southern hemisphere, change day (02:00 to 03:00 at 2026-10-03T16:00Z, a 23-hour day) | Australia/Sydney, 2026-10-04 | Fajr `["f","04:30"]`; Dhuhr `["f","12:15"]`; contrived Fajr `["f","02:30"]` | 2026-10-03T17:30:00Z; 2026-10-04T01:15:00Z; contrived: 2026-10-03T15:30:00Z `gapShifted` |
| 7 | Two Jumu'ah shifts | Europe/London, Friday 2026-10-23 (BST) | `j`: `{a:["f","13:15"],k:["f","13:00"],l:"en"}`, `{a:["f","14:00"],l:"ar"}` | shift 1 Azaan 2026-10-23T12:15:00Z, khutbah 12:00:00Z, `en`; shift 2 Azaan 13:00:00Z, `ar`; Thursday 2026-10-22 and Saturday 2026-10-24: `jumuah` empty |
| 8 | Horizon across a 25-hour day | Europe/London, sync at 2026-10-15T23:30:00Z (00:30 BST on 16 October) | none | first 2026-10-16, last 2026-11-14, count 30 (includes 25 October); `now = sync + 30 days` not stale; `+ 30 days 1 s` stale |
| 9 | Range gap | any | yearly ranges `01-01..06-30` and `07-02..12-31` | error `range_gap` at 07-01 |
| 10 | Jumu'ah not Friday | any | shift with `"d":4` | error `jumuah_not_friday` |

## 8. Planner integration (summary)

`MasjidScheduleEngine implements PrayerTimeEngine` wraps the Phase 0 engine and replaces the five Azaan instants when the source is a fresh Masjid schedule (R6 section 2). `NoticeCode` gains `masjidSchedule` and `masjidFallbackStale`. With `source == null` it returns the wrapped engine's result unchanged (identity property). Iqamah and extra Jumu'ah shifts are display-only in Phase 1.

## 9. Issues found

| # | Contradiction | Recommendation |
|---|---------------|----------------|
| 1 | Phase 0 `LocalClock.toUtc` (packages/schedule_planner/lib/src/local_time.dart) documents "first occurrence in a repeated hour, offset after the change in a skipped hour", but its algorithm guesses the offset at the wall time read as UTC, so it behaves differently by hemisphere: New York (west) gets the documented result; London and Sydney (east) get the SECOND occurrence in an overlap and a forward shift in a gap (London 2026-10-25 01:30 gives 01:30Z, not 00:30Z; London 2026-03-29 01:30 gives 01:30Z, not 00:30Z). Verified by replicating the algorithm in JavaScript. | `masjid_schedule` MUST NOT call it; it ships its own sign-independent `wallToUtc` (E4). Fix Phase 0 separately with additions-only vectors (3b), or change the Phase 0 comment. The owner may prefer a forward shift in gaps; decide before the vectors freeze. |
| 2 | `LocalClock` and `addDays` are in `schedule_planner` and not exported; `masjid_schedule` may depend on `prayer_engine` only (R6 section 2). | Move them to `prayer_engine` (re-export from `schedule_planner`). |
| 3 | Brief says coordinates come from the overlay; they live in base (`la`, `lo`) and overlay holds only settings (R-27). | Merged record: coordinates from base. |
| 4 | "No overlaps or gaps" excludes a dated Ramadan exception on top of yearly summer and winter ranges. | v1 forces one form per record (a dated record must be renewed each year, `range_ends_soon`). If admins need exceptions, add an additive `x` list in `masjid-schedule/1.1`. |
| 5 | R6 `expiresAt = syncedAt + 30 days` and the brief's horizon of 30 local dates differ by up to a day. | Both apply (D3, D4); harmless. |
| 6 | R4 expands fixed rules server-side (`x` rows); R-06 forbids it. | No `x` rows; phone expands. |
| 7 | `Iqamah after Azaan` crossing midnight depends on calculated Isha, which depends on overlay settings that can change after save. | Validate on save and on settings change; E11 runtime guard covers the rest. |
| 8 | Phase 0 `DayTimes` has one Dhuhr; several Jumu'ah shifts cannot be separate alerts. | Friday alert follows the chosen shift (E9); owner to confirm. |

## 10. Validation

| Proves | Test |
|--------|------|
| Section 7 vectors | `dart test` and `node --test` on compiled JS read the same `test_vectors/*.json`; zero differences |
| dart2js parity | sweep like the R6 spike (8 cities, 14 methods, 122 days, ms compare) re-run on every `masjid_schedule` change |
| Host independence | vectors run with `TZ=UTC`, `Pacific/Kiritimati`, `America/St_Johns` |
| Properties | fast-check/`package:test` generated rules: one Azaan per prayer per date, increasing order, exactly 30 consecutive local dates across 23 and 25 hour days, gap flagged, overlap first; curated zones (Lord Howe, Chatham, Apia, Cairo, Casablanca, Amman, Istanbul, Kathmandu, Kolkata) around every transition |
| Schema and codes | Ajv on the schema plus one table test per issue code, severity and path |
| Wrapper identity | `MasjidScheduleEngine(source: null)` equals the engine for 14 methods x 20 cities x 366 days |
| Phase 0 untouched | all existing `planning_*.json`, `arbiter.json`, `alert_ids.json` pass unchanged |
