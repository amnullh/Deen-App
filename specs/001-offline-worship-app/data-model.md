# Data Model: Offline Worship App (Phase 0)

**Date**: 2026-10-21 | **Plan**: [plan.md](plan.md) | **Spec**: [spec.md](spec.md)

All data lives on the device. Nothing here is transmitted (FR-002). Field types are logical, not SQL. Instants
are stored as UTC epoch milliseconds; local dates as `YYYY-MM-DD` strings in the location's time zone.

## Storage layout

| Store | Where | Why |
|-------|-------|-----|
| `app.db` (drift/SQLite) | app documents directory | settings, alert log, tasbih, adhkar progress, bookmarks |
| `cities.db` (read-only asset) | bundled, copied on first use | offline city search; see R-C3 |
| `schedule.json` (Android) | device-protected storage | alarms can be re-registered before first unlock |
| `journal.log` (Android) | device-protected storage | native alert events, imported into `AlertLog` at app start |
| Content packs | bundled assets | audio, adhkar, fonts; each listed in `content/LICENSES.md` |

## Entities

### Location (single row)
| Field | Type | Rules |
|-------|------|-------|
| source | enum: precise, approximate, city | required |
| latitude, longitude | double | -90..90, -180..180; approximate source is rounded to about 1 km |
| cityId | int? | GeoNames id when source is city |
| displayName | text | shown to the user |
| timeZoneId | text | IANA id; from the city record, or resolved on device for GPS fixes |
| countryCode | text | ISO 3166 alpha-2; drives regional defaults |
| updatedAt | instant | |

### PrayerSettings (single row)
| Field | Type | Rules |
|-------|------|-------|
| method | enum of the 14 methods | default from `RegionDefaults(countryCode)`; MWL if no region matches |
| asrMethod | enum: standard, hanafi | default standard; confirmed in setup |
| highLatitudeRule | enum: middleOfNight, seventhOfNight, angleBased | default chosen above 48 degrees and explained |
| offsetsMinutes | map prayer to int | each -60..60; prayers: fajr, sunrise, dhuhr, asr, maghrib, isha |
| imsakMinutes | int | minutes before Fajr, default 10 (proposed, plan D-15); detail view only |
| hijriAdjustment | int | -2..2 |
| suggestedMethodDismissedFor | set of region codes | one suggestion per new region |
| language | enum: en, ar, ur, id | |
| appearance | theme (system, light, dark), textScale, highContrast | |

### AlertPreference (one row per prayer: fajr, dhuhr, asr, maghrib, isha)
| Field | Type | Rules |
|-------|------|-------|
| type | enum: off, silent, vibrate, shortTone, fullAzaan | default shortTone |
| voiceId | text | one of the two bundled voices |
| variant | enum: standard, shia | Recording chosen by the mapping table below |
| loudMode | bool | Android only; default false |
| volumeChoice | enum: keepCurrent, gentleRamp | required when loudMode is true |
| preReminderMinutes | int? | 5..60; null means none |
| ignoreQuietHours | bool | default false; true keeps this prayer's audible type inside quiet hours |

Recording mapping (proposed; the scholar reviewer confirms, plan D-14). Each voice has three recordings:

| variant | prayer | recording played |
|---------|--------|------------------|
| standard | Fajr | `<voice>-fajr` (includes "as-salatu khayrun min an-nawm") |
| standard | Dhuhr, Asr, Maghrib, Isha | `<voice>-standard` |
| shia | all five | `<voice>-shia` (Shia wording; it has no "as-salatu khayrun min an-nawm") |

Reminders (pre-prayer, suhoor, adhkar) never use a full Azaan: a reminder uses the prayer's alert type, except that
`fullAzaan` is played as `shortTone` (plan D-15, to be confirmed).

### Global alert settings (single row)
| Field | Type | Rules |
|-------|------|-------|
| audioOutput | enum: speaker, headphones, bluetooth | default speaker; used when such a device is connected (spec Story 3, scenario 8) |
| quietHours | start and end local time, or none | audible alerts inside it become silent notifications unless the prayer's `ignoreQuietHours` is true (spec) |
| clockSample | wall-clock instant, monotonic reading, boot id | last seen at app launch; used by the clock-sanity check |
| scheduleRunsUntil | instant | end of the last scheduled alert; shown in the Reliability check |
| suhoorReminderEnabled, suhoorReminderMinutes | bool, int | only offered during Ramadan by Umm al-Qura Hijri date |
| exactAlarmState | enum: unknown, granted, denied | Android; refreshed on every launch |
| notificationPermissionState | enum: unknown, granted, denied | |
| silentSwitchExplained | bool | one-time iOS explanation shown |

### PlannedAlert (planner output; persisted as the snapshot, not a table)
| Field | Type | Rules |
|-------|------|-------|
| alertId | text | stable and unique: `{prayer}:{localDate}` for the prayer, `:pre` for its reminder, `suhoor:{localDate}`, `adhkar-morning:{localDate}`, `adhkar-evening:{localDate}`, `renewal:{localDate}` |
| kind | enum: prayer, preReminder, suhoor, adhkarReminder, renewal | `renewal` is the "open the app" notice: about 7 days before a 60-day Android snapshot ends, or the last pending iOS request |
| fireAt | instant | absolute; computed with the location's rules |
| deliveryType | enum as AlertPreference.type, plus renewal | after quiet-hours and permission downgrades |
| audioRef | text? | recording id and variant for fullAzaan; tone id for shortTone |
| title, body | text | localized in the user's language at planning time |
| priority | int | lower is nearer; used by the iOS 63-request budget |

### AlertLogEntry (drift table `alert_log`)
| Field | Type | Rules |
|-------|------|-------|
| alertId | text | primary key together with `attempt` |
| plannedFireAt | instant | |
| state | enum below | |
| firedAt | instant? | actual delivery or start time (Android journal) |
| deviation | int? | milliseconds between planned and fired; feeds SC-002 |
| cause | enum? | `exact_alarm_denied`, `notification_denied`, `fgs_blocked`, `call_in_progress`, `quiet_hours` (listed as "silenced by quiet hours", not missed), `silent_mode`, `battery_restricted`, `app_not_run`, `schedule_ended`, `unknown` |
| source | enum: androidJournal, iosInferred, inApp | |

State machine for one alert ID:

```text
planned --(time passes, native journal entry)--> fired --> played --> acknowledged
planned --> suppressed (call, quiet hours, headphones rule)
planned --> failed (service blocked; fallback tone attempted)
planned --(time passes, no entry)--> missed
iOS: planned --(not pending, not delivered, no tap)--> possiblyMissed
```

Rules: at most one `played` per alertId (FR-005). The arbiter refuses a second play for an alertId that
already has a `played` entry. `missed` and `possiblyMissed` are decided at next app open; on iOS the app cannot
confirm delivery, so the user sees "possibly missed".

### TasbihState
| Field | Type | Rules |
|-------|------|-------|
| id | int | single active counter |
| count, target | int | target 33, 99 or custom 1..100000 |
| keepAwake, volumeKeys, lock, haptics, sound | bool | volumeKeys Android only |
| TasbihDay: date, total | text, int | daily totals for history; reset requires confirmation |

### Adhkar
| Entity | Fields |
|--------|--------|
| AdhkarCollection | id, kind (morning, evening, afterPrayer, beforeSleep, waking, other), titles per language, sourceId |
| AdhkarEntry | id, collectionId, order, arabic, transliteration, translations per language, repeatCount, reference, contentRecordId |
| AdhkarProgress | sessionId, collectionId, entryId, completedCount, startedAt, finishedAt |
| AdhkarBookmark | entryId, createdAt |
| AdhkarReminder | collectionKind (morning, evening), anchor (fajr, asr, maghrib), offsetMinutes, enabled |

Content tables are read-only assets; progress, bookmarks and reminders are drift tables.

### ContentRecord (register, not a table)
Lives in `content/LICENSES.md` and is checked by CI. Every audio file, text pack, font and dataset has:
id, kind, source URL, license (SPDX), attribution text, reviewer name and role (scholar or native speaker),
review date, hash of the shipped file, and notes (for example "clip cut approved").

### City (read-only `cities.db`)
| Field | Type |
|-------|------|
| geonameId | int |
| name, asciiName | text |
| names_ar, names_ur, names_id | text, searchable alternate names |
| latitude, longitude | double |
| countryCode, timeZoneId | text |
| population | int |

Search normalizes case and diacritics and matches a prefix on any name field, ordered by population.

## Settings export (versioned JSON)
Schema in [contracts/settings-export.md](contracts/settings-export.md). Covers Location, PrayerSettings,
AlertPreference rows, global alert settings, tasbih settings and bookmarks. Excludes the alert log and device
permission states. Import validates ranges and version before applying anything.

## Validation rules summary
- Offsets -60..60 min; Hijri adjustment -2..2; reminder 5..60 min; tasbih target 1..100000.
- Location is required before any planning; without it the app shows setup, never an empty or crashing screen.
- A fullAzaan or reminder type is accepted without exact-alarm permission; the planner marks it `inexact` and the
  Reliability check says so.
- `delete all my data` removes `app.db`, the Android snapshot and journal, all scheduled alerts and the export
  file the app itself created.
