# Content and Dependency License Register

**Status**: DRAFT, created during planning on 2026-10-21 for `specs/001-offline-worship-app`. No content has
been added to the app yet. Nothing below may ship until its status is `cleared`.

**Rules** (constitution principle 10 and spec FR-008): every bundled audio file, text, font, dataset and every
library has a source, an OSI-approved or freely redistributable license, and, for religious content, a named
reviewer. CI fails when a file under `content/` or `apps/mobile/assets/` has no entry here.

Legend. Verified: V = license text or metadata read at the source; U = tag or report only, confirm before use.

## 1. Dependencies (Dart, Flutter, Android)

| Name | Version | SPDX license | Verified | Status | Notes |
|------|---------|--------------|----------|--------|-------|
| Flutter SDK | 3.44+ | BSD-3-Clause | V | approved | |
| Dart SDK | 3.12+ | BSD-3-Clause | V | approved | |
| adhan_dart | 2.0.1 | MIT | V | approved | no dependencies; Imsak computed by us |
| flutter_local_notifications | 22.3.2 | BSD-3-Clause | V | approved | iOS scheduling; Android receivers removed |
| timezone | 0.11.2 | BSD-2-Clause | V | approved | |
| flutter_timezone | 5.1.1 | Apache-2.0 | V | approved | |
| just_audio | 0.10.6 | MIT (ExoPlayer: Apache-2.0) | V | approved | |
| audio_session | 0.2.4 | MIT | V | approved | |
| flutter_riverpod | 3.4.3 | MIT | V | approved | |
| drift | 2.35.2 | MIT | V | approved | |
| sqlite3 | 3.7.1 | MIT (SQLite: public domain) | V | approved | build hook downloads binaries; pin or vendor |
| intl | 0.20.3 | BSD-3-Clause | V | approved | |
| flutter_localizations | SDK | BSD-3-Clause | U | approved | |
| pigeon | 29.0.11 | BSD-3-Clause | V | approved (dev) | |
| permission_handler | 13.0.2 | MIT | V | approved | Dart implementation packages (android, apple, platform interface, windows) read by `tools/license_scan` (all allowed licenses); the Android Gradle dependencies of the plugin are confirmed with T031/T033 |
| wakelock_plus | 1.8.1 | BSD-3-Clause | V | approved | |
| android_intent_plus | 6.1.0 | BSD-3-Clause | V | approved | |
| file_picker | 13.1.0 | MIT | V | approved | Dart implementation packages read by `tools/license_scan` (all allowed licenses); Android Gradle dependencies confirmed with T031/T033 |
| share_plus | 13.3.1 | BSD-3-Clause | V | approved | pulls url_launcher packages (BSD) |
| path_provider | 2.1.6 | BSD-3-Clause | V | approved | |
| alchemist | 0.14.1 | MIT | V | approved (dev) | |
| integration_test, flutter_test | SDK | BSD-3-Clause | U | approved (dev) | |
| build_runner | 2.16.1 | BSD-3-Clause | V | approved (dev) | code generation; read from the LICENSE file by `tools/license_scan` |
| drift_dev | 2.35.1 | MIT | V | approved (dev) | drift code generator |
| flutter_lints | 6.0.0 | BSD-3-Clause | V | approved (dev) | lint rules for the app |
| lints | 6.1.0 | BSD-3-Clause | V | approved (dev) | lint rules for pure-Dart packages and tools |
| test | 1.31.1 | BSD-3-Clause | V | approved (dev) | unit tests for pure-Dart packages and tools |
| path | 1.9.1 | BSD-3-Clause | V | approved | path handling |
| yaml | 3.1.4 | MIT | V | approved (tool) | used by `tools/license_scan` only |
| AndroidX core, Kotlin stdlib | current | Apache-2.0 | U | pending | confirm with `./gradlew :app:dependencies` |

Rejected (do not add): adhan (stale), hijri (range 1356-1500 AH, unverified publisher), hijri_calendar (stale),
golden_toolkit (discontinued), sqlite3_flutter_libs (end-of-life), geolocator and geolocator_android (pull
proprietary Play Services location), flutter_compass (stale), audio_service (not needed), volume_controller
(unverified publisher).

Build-time reference only, never bundled: ICU4X `icu_calendar` data (Unicode License V3; copied into a generated
table, notice kept, see section 4), adhan-js (MIT) and PrayTimes (reported LGPL, unverified) as cross-checks.

## 2. Audio

| Id | Description | Source | License | Reviewer | Status |
|----|-------------|--------|---------|----------|--------|
| voice-1 standard, Fajr, Shia | Voice 1, three versions | to be recorded or selected | CC0 / CC-BY / signed Muazzin license | TODO scholar | not cleared |
| voice-2 standard, Fajr, Shia | Voice 2, three versions | to be recorded or selected | CC0 / CC-BY / signed Muazzin license | TODO scholar | not cleared |
| ios-clips (6) | 30 seconds or less, cut from the above | derived | same as source | TODO scholar approves cut points | not cleared |
| tone-short | Short alert tone | synthesized by the project | CC0 | n/a | to create |

Candidate sources found (license metadata read on Wikimedia Commons or Internet Archive; none listened to or
reviewed yet):

| Candidate | License | Notes |
|-----------|---------|-------|
| Commons `Adhan.ogg` (42 s) | CC0 | standard wording unconfirmed |
| Commons `Beautiful adhan.ogg` (154 s) | CC0 | |
| Commons `Adhan in Istanbul.webm` | CC0 | video, extract audio |
| Internet Archive `AzanZhurMasjidKlcc` | CC0 | Dhuhr, 3 minutes |
| Commons Great Mosque of Mecca, 21 Jan 2013 | CC BY 3.0 | credit Seyfula Islam |
| Commons Eid al-Fitr Fajr azan, Malmo Mosque, 2012 | CC BY 3.0 | labelled Fajr; tathwib unconfirmed |

Not acceptable: CC BY-NC-ND (Cambridge Cairo set), CC BY-SA files, recordings whose public-domain status is only
asserted by the uploader. No acceptably licensed Fajr-with-tathwib or Shia-wording recording was found; these must
be recorded under the signed license (clarification D2).

## 3. Text content

| Id | Description | Source | License | Reviewer | Status |
|----|-------------|--------|---------|----------|--------|
| adhkar-ar | Adhkar Arabic texts | own collection from primary hadith sources (plan D-4, decided 2026-10-22) | to be recorded per entry | TODO scholar | BLOCKED until sourced and reviewed |
| adhkar-translit | Transliteration | none found | unresolved | TODO | BLOCKED |
| adhkar-en, adhkar-ur, adhkar-id | Translations | none found openly licensed | unresolved | TODO | BLOCKED |
| ui-en, ui-ar, ui-ur, ui-id | Interface strings | written by the project | project license (Apache-2.0) | TODO native speaker per language | to write |
| privacy-policy (`content/privacy/privacy-policy.md`) | Policy text in en, ar, ur, id | written by the project (2026-10-21) | project license (Apache-2.0) | native-speaker review of ar/ur/id pending (T186-style review) | written; not published (hosting: plan D-5) |

## 4. Datasets

| Id | Description | Source | License | Attribution | Status |
|----|-------------|--------|---------|-------------|--------|
| cities | Cities with population over 15,000, ids, names, coordinates, time zones, ar/ur/id names | GeoNames `cities15000` and `alternateNamesV2` (https://download.geonames.org/export/dump/) | CC BY 4.0 | "Contains data from GeoNames (https://www.geonames.org), licensed under CC BY 4.0. Modified: filtered and recoded." Link to https://creativecommons.org/licenses/by/4.0/ | to build; check row-level sub-source notices |
| ummalqura-table | Hijri month lengths 1300-1600 AH | generated from ICU4X (originally KACST month lengths) | Unicode License V3 | keep the Unicode license notice | to generate; validate (spike S5) |
| region-defaults | Country to calculation-method map | written by the project from clarification D1 | project license | n/a | to write |
| qibla-reference | 10 sanity bearings | computed by an independent implementation; adhan-js values for cross-check only | n/a (facts) | n/a | to generate |

## 5. Fonts

| Font | Use | Source | License | Status |
|------|-----|--------|---------|--------|
| Amiri | Arabic adhkar text | github.com/aliftype/amiri, google/fonts | SIL OFL 1.1 | approved; ship OFL.txt |
| Noto Naskh Arabic | Arabic UI | github.com/notofonts/arabic | SIL OFL 1.1 | approved |
| Noto Sans Arabic | Arabic UI fallback | github.com/notofonts/arabic | SIL OFL 1.1 | approved |
| Noto Nastaliq Urdu | Urdu UI | github.com/notofonts/nastaliq | SIL OFL 1.1 | approved |
| Noto Sans | Latin and Indonesian UI | github.com/google/fonts | SIL OFL 1.1 | approved |

Shipped files (all registered by the wildcard entry `apps/mobile/assets/fonts/*`; full license text kept beside each
font as `OFL-<Font>.txt`; unmodified from google/fonts, none declares a Reserved Font Name, downloaded 2026-10-21):
`Amiri-Regular.ttf`, `Amiri-Bold.ttf`, `NotoNaskhArabic-Variable.ttf`, `NotoSansArabic-Variable.ttf`,
`NotoNastaliqUrdu-Variable.ttf`, `NotoSans-Variable.ttf`.

OFL conditions: bundle the full license text and copyright line; do not sell the fonts alone; before subsetting,
check each file for a Reserved Font Name (subsetting is a modification).

## 6. Platform exceptions (Exceptions Register cross-reference)

Phase 0 uses none of the push or attestation exceptions. Active entries that apply: Apple Developer Program fee,
Google Play developer fee, and GitHub Actions free tier (optional). Open: privacy-policy hosting (plan D-5).

## 7. Aggregated notice

`LICENSES/NOTICE` (named in constitution principle 10) is generated from this register at build time by
`tools/license_scan`; this file stays the source of truth for review details.
