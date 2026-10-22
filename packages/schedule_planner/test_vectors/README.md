# Shared test vectors

JSON files read by the Dart tests in `../test/` and, for the rules Kotlin reimplements (the arbiter, alert IDs and the
recording mapping), by the Android instrumented tests. A platform that reimplements a rule MUST pass the same vector
file. Every file has a `"schema"` field (`name/version`); change the version when the format changes.

Instants are UTC ISO-8601 strings ending in `Z`. Local dates are `YYYY-MM-DD` in the location's time zone.

## arbiter.json (`arbiter/1`)

Rule: at most one `play` per alert ID; `skipAlreadyPlayed` wins over `skipSuppressed`; the decision never writes the
ledger.

- `cases[]`: `{name, ledger: [alertId...], alertId, suppressed: bool, expected}`. Decide `alertId` against a ledger that
  holds exactly `ledger`. `expected` is one of `play`, `skipAlreadyPlayed`, `skipSuppressed`.
- `sequences[]`: `{name, steps: [{alertId, suppressed, expected, markPlayed}]}`. Start with an empty ledger. For each
  step compare the decision to `expected`, then, if `markPlayed` is true, add `alertId` to the ledger (the caller does
  this after playback starts).

## alert_ids.json (`alert_ids/1`)

- `build[]`: `{kind, localDate, pre, expected}`. `alertId(kind, localDate, pre)` equals `expected`; when `expected` is
  `null` the call must be rejected (exception or error result).
- `parse[]`: `{id, expected}`. `expected` is `{kind, localDate, pre}` or `null` when `id` is malformed.

Kinds: `fajr dhuhr asr maghrib isha suhoor adhkar-morning adhkar-evening renewal`. Only the five prayers take `pre`.
Format: `<kind>:<localDate>` or `<prayer>:<localDate>:pre`.

## recording_mapping.json (`recording_mapping/1`)

- `recordings[]`: `{voiceId, variant: standard|shia, prayer, expected}`. Recording id played by a full Azaan:
  standard Fajr `<voice>-fajr`, standard other prayers `<voice>-standard`, shia at every prayer `<voice>-shia`.
- `reminderTypes[]`: `{prayerType, expected, expectedStandalone}`. Reminder alert type for a prayer type:
  `fullAzaan` becomes `shortTone`; `expectedStandalone` is for a reminder with its own opt-in (suhoor, adhkar) and
  also turns `off` into `shortTone`.

## planning_*.json (`planning/1`)

`planning_dst.json` (DST and time-zone cases), `planning_android_60day.json`, `planning_ios_budget.json`. These are
planner cases for the Dart tests; they are readable by anything but only Dart runs the planner. Each case:

```text
name, description
input:
  now                   UTC instant
  location              {latitude, longitude, timeZoneId, countryCode}
  zone                  {initialOffsetMinutes, changes: [{atUtc, offsetMinutes}]}   offsets of the location's zone;
                        the test builds an OffsetResolver from this
  localTimes            {fajr, sunrise, dhuhr, asr, maghrib, isha: "HH:mm"}   fake engine: every day has these local
                        clock times, converted to UTC with `zone`. null or absent = event does not occur
  dayOverrides?         {"YYYY-MM-DD": {prayer: "HH:mm" | null}}
  budget                {platform: "android", snapshotDays, renewalDaysBeforeEnd} | {platform: "ios", maxRequests}
  alertPreferences      [{prayer, type, voiceId?, variant?, loudMode?, volumeChoice?, preReminderMinutes?,
                          ignoreQuietHours?}]   a prayer not listed is off
  quietHours?           {startMinutes, endMinutes} | null   local minutes after midnight
  suhoor?               {enabled, minutes}
  ramadanDates?         ["YYYY-MM-DD"...]   dates for which isRamadan is true
  adhkarReminders?      [{kind, anchor, offsetMinutes, enabled}]
  permissions?          {exactAlarm?, notifications?}   unknown | granted | denied
expected:               one of
  alerts: [...]         the full planned list, in order. Each item lists only the fields to check among
                        alertId, fireAt, deliveryType, audioRef, preciseAllowed, reasons (names, in enum order)
  or
expectedSummary:        {count, kindCounts: {kind: n}, first: {...}, last: {...}, renewal: {...}}
                        first/last/renewal items use the same field list as above
```

Rules the planning vectors encode: quiet hours are judged in the location's local time across DST changes; instants
are absolute; today's local date comes from the location zone; Android has `snapshotDays` days plus a renewal alert at
09:00 local on day `d0 + snapshotDays - renewalDaysBeforeEnd`; iOS keeps `maxRequests - 1` nearest alerts plus a
renewal alert one minute after the last kept alert.
