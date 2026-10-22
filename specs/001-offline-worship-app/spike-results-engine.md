# Spike results: prayer engine (S9 accuracy, S5 Hijri), workstream W1

Date: 2026-10-21. Code: `packages/prayer_engine`, `tools/fixtures_gen`, `tools/hijri_table_gen`.
Run everything with `cd packages/prayer_engine && dart test` (237 tests, about 18 s) and
`cd tools/fixtures_gen && dart test` (13 tests). `dart run tool/accuracy_report.dart` (in `packages/prayer_engine`)
prints the per-method, per-city disagreement table used below.

## S9. Does `adhan_dart` 2.0.1 meet 1 minute against the oracle?

Setup: 20 reference cities, 13 methods (all except Moonsighting Committee), 2 Asr schools, 365 days of 2026,
6 events: 87,600 comparisons per method, compared as whole minutes. Tolerance stays at 1 minute and
`_knownGaps` in `oracle_accuracy_test.dart` is empty.

### First run (adhan_dart alone, oracle as first written)

Every method failed. About 1,870 of 87,600 comparisons were outside 1 minute for 10 methods; Tehran 2,239, Jafari
2,171, Singapore 9,261, worst deviation 2,279 minutes (a different day). Causes, each analysed against a third
reference, NASA/JPL Horizons (DE441), queried for the disputed days:

| # | Disagreement | Who was wrong | Evidence | Resolution |
|---|--------------|---------------|----------|------------|
| 1 | Dhuhr off by 2 on about 10 days per method (Singapore: 9,000 comparisons) | Neither. A convention the oracle did not model: MWL, ISNA, Egypt, Karachi and Singapore add 1 minute to Dhuhr; Singapore (MUIS) rounds every time up. The 1-minute margin plus rounding of a 29.9 s fraction gave 2 minutes | Method definitions in `adhan_dart` `CalculationMethod.dart` | Oracle now carries `dhuhr: +1` and `roundsUp` per method; `method_conventions_test.dart` pins them. UNVERIFIED against an official source: they follow the reference library, not an official document |
| 2 | Asr off by 2 to 6 minutes at high latitudes in winter (London, Oslo, Reykjavik, also New York and Los Angeles on a few days) | `adhan_dart` | JPL: Reykjavik 2026-01-01 true Asr 13:56:35, oracle 13:56:30, adhan_dart 14:01:00. London 01-26: JPL 14:16:32, adhan_dart 14:18:00. Five more cases in `test/asr_shadow_test.dart` | `adhan_dart` takes the Sun's declination at 00:00 UT for the noon shadow. Fixed in the engine: Asr is solved with the declination at noon for the shadow length and at the event itself for the angle (`lib/src/solar.dart`, `SunSolver.asr`) |
| 3 | Fajr, sunrise, Maghrib and Isha wrong by hours or a whole day in Tromso (polar night and day) | `adhan_dart` | It clamps `acos` arguments to 1, so a sun that does not rise or set yields meaningless times; the existing adapter caught only a floor-of-NaN error that does not occur there | Resolved event by event, null plus `Notice(polarNoEvent, prayer)` for each missing event (`lib/src/polar.dart`) |
| 4 | Tromso 2026-01-15: sunrise 10:22 vs oracle 10:29, sunset 11:26 vs 11:18 (7 minutes) | `adhan_dart` | JPL: sunrise 10:29:35, sunset 11:18:14. The single Newton correction step of `adhan_dart` is not enough when the Sun only grazes the horizon | For latitudes of 62 degrees and above (except Moonsighting) the whole day is computed by the engine's own solver, which iterates to convergence. Below 62 degrees `adhan_dart` agrees with the oracle within 1 minute |
| 5 | Tehran and Jafari Maghrib at Oslo, Reykjavik and Tromso in spring and summer (up to 62 minutes) | The oracle | By angle, Maghrib fell after Isha, which was limited by the night rule. `adhan_dart` uses the angle only when it falls between sunset and Isha | Oracle bug fixed with the same rule (tests in `tools/fixtures_gen/test/oracle_test.dart`). The engine's own solver follows it |
| 6 | The night length for the high-latitude rule | The oracle (PrayTimes uses the same-day sunrise and sunset) | `adhan_dart` measures sunset to the next sunrise, the Islamic definition of the night | Oracle now uses tomorrow's sunrise; when it does not exist the rule is not applied |
| 7 | Existence of events on 5 to 6 grazing days per year in Tromso (Asr in November, sunrise 18 May, sunset 25 July) | The oracle (3 fixed-point iterations; a cosine just out of range returned "no event") | JPL: on 2026-05-17 the Sun dips to -0.859 degrees, below the -0.833 threshold, so a sunrise exists on 18 May; on 2026-11-20 Asr is 10:35:20 | Oracle now iterates 8 times and decides existence only on the last pass. The engine's solver does the same, with a 2e-5 tolerance on the cosine |
| 8 | Umm al-Qura Isha during Ramadan | `adhan_dart` (always 90 minutes) | Umm al-Qura prescribes 120 minutes in Ramadan | Engine switches to 120 when `isRamadan(localDate)` (Hijri table below). Verified in `method_conventions_test.dart` |

### Result after the corrections

Per method (87,600 comparisons each, 2026): worst deviation 1 minute, 0 comparisons over 1 minute.

| Method | Result | Worst | Notes |
|--------|--------|-------|-------|
| Muslim World League | pass | 1 min | |
| ISNA | pass | 1 min | |
| Egypt | pass | 1 min | |
| Umm al-Qura | pass | 1 min | 120 min Isha in Ramadan |
| Karachi | pass | 1 min | |
| Tehran | pass | 1 min | Maghrib by angle only between sunset and Isha |
| Jafari | pass | 1 min | same |
| Gulf | pass | 1 min | |
| Kuwait | pass | 1 min | |
| Qatar | pass | 1 min | |
| Singapore | pass | 1 min | rounds up (oracle too) |
| Diyanet | pass | 1 min | fixed offsets: sunrise -7, Dhuhr +5, Asr +4, Maghrib +7 |
| France UOIF | pass | 1 min | |
| Moonsighting Committee | NOT covered by an independent oracle | n/a | structural tests only (below) |

Honest limits of this result:

- The oracle was edited during the spike. Every edit is either a convention (item 1), a definition shared with the
  Islamic night (item 6) or a defect shown by JPL Horizons (items 2, 5, 7). The oracle itself is now tested against
  JPL (`tools/fixtures_gen/test/oracle_test.dart`) so it cannot drift back. The oracle and the engine's own solver
  both use low-precision solar coordinates (about 0.01 degree); JPL is the only fully independent reference and it
  is used on about 30 chosen instants, not the full grid.
- Where the Sun only grazes the horizon (Tromso on the first and last days of the midnight sun and polar night) one
  0.001 degree model difference moves an event by minutes. The accuracy test passes there, but a real observer would
  see the same sensitivity. `horizons_events_test.dart` allows 2 minutes against JPL for one such case.
- Dhuhr margins, rounding up for Singapore and the Diyanet offsets follow `adhan_dart` and have not been checked
  against the official tables (T065 is open, see below).
- Between 62 degrees and the polar circle, and for every day without a sunrise or sunset, the engine does not use
  `adhan_dart` at all. Moonsighting Committee always uses `adhan_dart` (outside polar days), so at 62 degrees and above
  its sunrise and sunset can be a few minutes off on grazing days.

### Moonsighting Committee

No independent oracle exists in this project: its seasonal twilight tables are not part of the PrayTimes method.
`test/moonsighting_test.dart` has structural tests only: daily order of events in six cities and five dates, the
seasonal dawn interval (longest at midsummer, mirrored in the southern hemisphere, never more than 75 minutes at the
equator), the Dhuhr +5 and Maghrib +3 adjustments, the seventh-of-the-night rule above 55 degrees north with its
notice, and polar nulls. These tests would not catch a wrong coefficient. Needs official samples (T065).

### Engine behaviour added in this workstream

- Imsak, midnight, last third (`lib/src/night_times.dart`): the night runs from the day's displayed Maghrib to the
  next day's displayed Fajr; midnight is its midpoint; the last third starts two thirds in. Offsets set by the user
  are included because the displayed times are used. Imsak is Fajr minus `imsakMinutes` (a negative value throws
  `ArgumentError`). All are null when Maghrib or the next Fajr is null. Some schools measure the night to sunrise;
  the UI should state the convention.
- Polar days (`lib/src/polar.dart`): events that do not occur are null with `Notice(polarNoEvent, prayer)`. Fajr and
  Isha by twilight angle still occur in polar night and are returned; Isha of interval methods (Umm al-Qura, Gulf,
  Qatar) needs a sunset and is null. Asr is null when the Sun is below the horizon at noon. The high-latitude night
  rule is applied only when a night exists, and `Notice(highLatitudeRuleApplied, prayer)` is added when it moved Fajr
  or Isha by more than 2 minutes from the twilight time (or the angle is never reached).
- Date line and DST: `dateline_dst_test.dart` (Apia, Kiritimati, London and Sydney transition days): all pass with
  the existing solar-day shift, so no code change was needed.

## S5. Hijri (Umm al-Qura)

- `tools/hijri_table_gen/bin/gen.dart` downloads ICU4X `ummalqura_data.rs` (pinned commit
  `0455cbc76805bcace221573f242e2a7a82d10322`, Unicode-3.0), checks that 301 consecutive years chain exactly (each year
  starts the day after the previous one ends) and writes
  `packages/prayer_engine/lib/src/hijri/umm_al_qura_table.dart` (7 KB) with the full license notice. Rerun offline
  with `dart run tools/hijri_table_gen/bin/gen.dart path/to/ummalqura_data.rs`.
- Range: 1 Muharram 1300 AH (1882-11-12) to the last day of 1600 AH (2174-11-25). Outside it `toHijri` throws
  `RangeError`; `isRamadan` returns false.
- API: `toHijri(localDate, {adjustmentDays})` (adjustment -2..+2, +1 gives the next day's Hijri date),
  `fromHijri(year, month, day, {adjustmentDays})`, `isRamadan`, `hijriMonthLength`.
- Verified against published dates: 1 Ramadan 1447 = 2026-02-18 (Umm al-Qura calendar as quoted by Muhammadiyah, citing
  ummulqura.org.sa, accessed 2026-02-17); 1 Muharram 1448 = 2026-06-16 and 1 Ramadan 1448 = 2027-02-08 (makkahlive.net
  listing of the Umm al-Qura calendar, the latter also on muhammadiyah.or.id). All match. The table was also checked
  structurally for every year (29 or 30 day months, 354 or 355 day years, contiguity, round trip of every day).
- NOT verified: the official KACST table could not be fetched (the old ummulqura.org.sa redirects to a host that did not
  resolve here, and the Utrecht conversion tables were unreachable). The research claim of month-start mismatches in
  1451-1465 AH therefore remains UNVERIFIED. Someone with access should compare these years with the official table.
  Moon-sighting announcements in Saudi Arabia can differ from the calendar by a day, which the user adjustment covers.

## Tasks

- T064: done differently. No fixture files are stored; the oracle runs inside the test (about 1 s per method). This
  removes 14x20x2x365 rows of generated data from the repository. The Moonsighting column does not exist (no oracle).
- T065 [CONTENT]: OPEN. No official table could be fetched with terms that allow use. Needs hand-transcribed samples
  (Umm al-Qura Makkah, Diyanet Ankara and Istanbul, Moonsighting for a published city) with their source and terms.
- T066, T073: done, see above. T067/T074, T068/T075, T069, T070/T076, T072, T142: done.
- T072 covers the resolver implementations in this package; the "operating-system offsets when the zone equals the
  device zone, mismatch notice" policy is app code and is not tested here.
