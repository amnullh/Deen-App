# Register rows: content tools (workstream W7)

Rows for `content/LICENSES.md`, same format. Fold them into the main file when the workstreams are merged. The
`cities` row in section 4 of `content/LICENSES.md` ("to build") is superseded by the dataset row below.

## Datasets

| Id | Description | Source | License | Attribution | Status |
|----|-------------|--------|---------|-------------|--------|
| cities-db | `content/cities/cities.db`: 34,174 places (GeoNames `cities15000`: population over 15,000 or capitals) with ids, names, coordinates, country, IANA time zone, population, and Arabic, Urdu and Indonesian alternate names (18,744 kept) in a normalised search table | GeoNames dump files `cities15000.zip` and `alternateNamesV2.zip`, https://download.geonames.org/export/dump/ (files dated 2026-10-21 01:48 and 01:53 GMT) | CC BY 4.0 (https://creativecommons.org/licenses/by/4.0/) | "Contains data from GeoNames (https://www.geonames.org), licensed under CC BY 4.0 (https://creativecommons.org/licenses/by/4.0/). Modified: filtered and recoded." Stored in the database `metadata` table and to be shown on the About screen with a link to https://www.geonames.org/datasources/ (see the findings below) | built, license read at the source; sub-source notices unresolved (see findings) |

Built file facts (build date 2026-10-21):

- Size: 5,398,528 bytes (5.15 MiB). **This is over 5 MB: do not commit it as a plain git blob** (storage rule from T013;
  the lead decides: Git LFS, a release asset, or build in CI). The build is reproducible, so it can be regenerated
  instead of stored.
- SHA-256 of `cities.db`: `552e0473aa140abf504dbdb650b8b847285d28a02826e79c493a497e3444d950`
  (built twice with `--build-date 2026-10-21` into different paths; both files were byte-identical).
- SHA-256 of the inputs: `cities15000.zip` `94fc1384d9ec03160b70b24c8d74c38421c541576ec4e26959490efcf1b6afd7`
  (3,362,323 bytes); `alternateNamesV2.zip` `9f7de10e49711057b9267fc628826ccb79c69d2956da0afcbd5cdfb3055e5999`
  (204,951,147 bytes). GeoNames republishes these files daily, so a later download differs and so does the output;
  keep the input hashes with any rebuild.
- Rebuild: `dart run tools/geonames_build/bin/build.dart --build-date 2026-10-21` (downloads the zips once into a cache
  folder outside the repository, about 208 MB; needs the system `unzip`). Options are listed in the file header.
- Kept alternate names: languages `ar`, `ur`, `id` (a variant such as `ar-SA` counts as `ar`); rows flagged historic or
  colloquial are dropped; at most 6 names per city and language, preferred names first; spellings that normalise to
  the same text are stored once.
- Transformations ("Modified: filtered and recoded"): reduced to the fields above; alternate names filtered by language
  and flags; names normalised for search (lower case, diacritics removed, Arabic and Urdu letter variants folded)
  into a SQLite database.

### Findings for T041: sub-source notices in the GeoNames data (verified 2026-10-21)

What was read:

- The dump readme (https://download.geonames.org/export/dump/readme.txt): states that the data are licensed under
  CC BY 4.0, "provided as is without warranty or any representation of accuracy, timeliness or completeness", and
  points to https://www.geonames.org/datasources/ under the heading "Data Sources". It lists the 19 columns of the
  `geoname` table. There is no per-row source, license or attribution column. Neither the `cities15000.txt` columns nor
  the `alternateNamesV2` columns carry a source notice, so a per-row notice cannot be derived from the files.
- The data sources page lists 437 source records (136 distinct values in its country column, one of them blank). 146 of them carry
  licence or attribution text in the Licence column (for example CCBY 4.0, CCBY 3.0, CC0, "dl-de/by-2-0" (German data
  licence), "Licence Ouverte" (France), Open Government Licences, ODC-BY, IODL 2.0, public domain notes, and free-text
  credit lines such as "Contains information licensed under the Open Government Licence"). 291 have no text. The
  page assigns sources to countries, not to individual rows.
- 53 of the country codes with notice-bearing sources also have places in `cities.db` (18,163 of the 34,174 places,
  mainly DE, US, IT, GB, FR, CA, IN, ES, JP, AU). For Saudi Arabia, Indonesia and Pakistan (the app's main
  regions) the page lists one record with text for Indonesia and one for Pakistan; they are not row-level either.

What this does and does not show:

- Verified: the files have no row-level source or notice fields, and the project-wide license statement is CC BY 4.0.
- Verified: GeoNames publishes country-level source records, some with their own attribution wording.
- Not verified, and not claimed: which of those sources, if any, contributed to a given row of `cities15000`, and
  whether any of their terms require attribution beyond the GeoNames CC BY 4.0 credit. GeoNames does not say so on the
  pages read. The alternate names come from GeoNames' own alternate-name table, whose per-name origin is not
  published either.
- Action taken: the attribution text above is stored in the database and must be shown in the app, together with a
  link to the data sources page, so any further credit GeoNames requires is one tap away. Whether that is enough is a
  question for the license review of this register (plan D-4 stage), not something this tool decides.

## Audio (project-created)

| Id | Description | Source | License | Reviewer | Status |
|----|-------------|--------|---------|----------|--------|
| tone-short | `content/audio/shared/tone-short.wav`: gentle two-note alert (E5 then A5), 1.2 s, 44.1 kHz mono 16-bit PCM, peak about -6.9 dBFS (read with ffmpeg volumedetect). SHA-256 `7264e415948c33d4aa15c8b3ad81d24bc0354e812d0ebcb0b02799cf90d09895` | synthesised by the project with `tools/sync_content/bin/make_tones.dart` (code `tools/sync_content/lib/tone_synth.dart`, pure sine partials, no samples or third-party audio) | CC0 1.0 (public domain dedication) | n/a (not religious content) | cleared |
| tasbih-tick | `content/audio/shared/tasbih-tick.wav`: very short soft tick for the tasbih counter, 60 ms, 44.1 kHz mono 16-bit PCM, peak about -10.5 dBFS. SHA-256 `dd10d285d69ff065b2add39fdc069f4e11e4a41b486ad0d53f4503fdc3b7a9ba` | synthesised by the project with `tools/sync_content/bin/make_tones.dart` | CC0 1.0 (public domain dedication) | n/a | cleared |

Regenerate with `dart run tools/sync_content/bin/make_tones.dart`. The generator is deterministic; a different
platform's floating-point library may change a sample by one least-significant bit, which would change the hash.
These tasks name `content/audio/tone-short.wav` and `content/audio/tasbih-tick.wav`; the files live in
`content/audio/shared/` because that is the folder `tools/sync_content/lib/sync_plan.dart` copies into
`apps/mobile/assets/audio/`.

## Tools and test fixtures (no shipped content)

`content/adhkar/source/` and `content/adhkar/pack/` are empty: adhkar text is blocked (plan D-4). The adhkar pack builder
(`tools/sync_content/bin/adhkar_pack.dart`) and the audio encoder (`tools/sync_content/bin/encode.dart`) add no content
and no dependencies. `tools/geonames_build` uses the already registered `sqlite3` and `path` packages.
