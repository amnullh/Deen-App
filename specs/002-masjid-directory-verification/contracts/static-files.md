# Contract: Static Directory Files (`data.<domain>`)

**Spec**: [../spec.md](../spec.md) (FR-011, FR-012, FR-027, FR-031, FR-033) | **Decisions**: [../research.md](../research.md) R-01, R-17, R-20, R-21, R-27, R-28, R-29 | **Related**: [schedule-rules.md](schedule-rules.md), [directory-client.md](directory-client.md)

Everything the app reads from the server is a static file under `/v1/` (and `/dumps/`). No listener request reaches the API or the database. Normative words: MUST, SHOULD, MAY. Where this file and research.md disagree, research.md R-28/R-29 win and the difference is in "Issues found".

## 1. Hosts

| Host | Serves | App uses it | Logging |
|------|--------|-------------|---------|
| `data.<domain>` | static files under `/v1/...` and `/dumps/...` | GET only | no `log` directive, no cookies, no per-cell metrics |
| `api.<domain>` | `POST /v1/public/suggestions`, `POST /v1/public/abuse-reports` | the only host the app POSTs to | no addresses persisted (R-17) |
| `console.<domain>` | operator console, `/v1/*` (auth, account, masjids, claims, operator, ...) except `/v1/public/*`, `/tiles/` | never | admin logging |

## 2. Paths and cache headers

`gh5` = geohash precision 5 (alphabet `0123456789bcdefghjkmnpqrstuvwxyz`, lowercase), `gh4` = precision 4, `{n}` = part number 2 to 16. Precision 6 MUST NOT exist as a path. Exactly the R-29 table:

| Path | Cache-Control | Content |
|------|---------------|---------|
| `/v1/manifest.json` | `public, max-age=300, must-revalidate` + ETag | global manifest |
| `/v1/base/{gh5}.json`, `/v1/base/{gh5}.p{n}.json` | `public, max-age=86400, stale-while-revalidate=604800` + ETag | base layer (ODbL); empty cell: 404 with `max-age=3600` |
| `/v1/overlay/index.json` | `public, max-age=900` + ETag | cells that have overlay data |
| `/v1/overlay/{gh5}[.p{n}].json` | `public, max-age=900` + ETag | overlay layer (project terms) |
| `/v1/sched/{gh4}[.p{n}].json` | `public, max-age=900` + ETag | schedule rule bundle per area |
| `/v1/country/{ISO2}.json` | `public, max-age=86400` | major Masjids only |
| `/v1/g4/{gh4}.json` | `public, max-age=86400` | non-empty child cells of an area |
| `/v1/redirects.json` | `public, max-age=86400` | merged and removed ids |
| `/dumps/*` | `public, max-age=86400` | open dump (section 10) |

All responses: `Vary: Accept-Encoding`, `Referrer-Policy: no-referrer`, no `Set-Cookie`. No `Access-Control-Allow-Origin` except on `/dumps/*` (no browser needs the packs; R4 proposed `*` everywhere, see Issues). Content type `application/json; charset=utf-8`. Files are JSON, UTF-8, no BOM, keys in the fixed order shown in the examples, no insignificant whitespace.

## 3. Header block (every pack file)

| Key | Type | Meaning |
|-----|------|---------|
| `v` | int | file schema major (1). Readers MUST reject another major and MUST ignore unknown keys |
| `cell` | string | `gh5` (base, overlay) or `gh4` (sched, g4); `cc` replaces it in country files |
| `part`, `parts` | int | this part, total parts (1 to 16; `parts` repeated in every part) |
| `cv` | string | 8 lowercase hex: SHA-256 of the canonical `m` arrays of parts 1..N in order (header and `pad` excluded). A consistency token, not an integrity proof |
| `gen` | int | the generation in which this file's content last changed (not the current generation: otherwise every file would change every month) |
| `lic` | string | base, country, g4, redirects: full licence text (section 9) |
| `terms` | string | overlay, overlay index, sched: URL of the project overlay terms |
| `rf` | string | sched only: `masjid-schedule/1` |

Order: `v,cell,part,parts,cv,gen,lic|terms[,rf],m,pad`. A file without `lic` or `terms` is invalid (ODbL 4.2b).

## 4. File shapes and examples

### 4.1 Manifest (`/v1/manifest.json`, cap 256 KB, in practice about 2 KB)

```json
{"schema":1,"gen":412,"built":"2026-10-22T02:00:00Z","osm_ts":"2026-10-20T20:21:00Z","min_app":"1.0.0",
 "grid":{"p":5,"base":"/v1/base/{c}.json","part":"/v1/base/{c}.p{n}.json","overlay":"/v1/overlay/{c}.json","sched":"/v1/sched/{c4}.json","area":"/v1/g4/{c4}.json"},
 "part_max_raw_bytes":500000,"classes_kb":[4,16,64,256,512],
 "overlay":{"gen":1189,"index":"/v1/overlay/index.json"},
 "countries":{"ID":{"path":"/v1/country/ID.json","gen":412}},
 "redirects":{"path":"/v1/redirects.json","gen":410},
 "stale":{"base_days":90,"sched_days":30},
 "lic":{"base":"ODbL-1.0","attr":"© OpenStreetMap contributors","url":"https://www.openstreetmap.org/copyright","overlay_terms":"https://example.org/overlay-terms"}}
```

| Field | Rule |
|-------|------|
| `schema` | manifest schema major; client supports 1 |
| `gen`, `overlay.gen` | current base and overlay generations (two counters). R4 wrote `overlay_gen` in prose; the object form is the contract |
| `built`, `osm_ts` | build time of this generation; timestamp of the OSM extract it came from |
| `min_app` | semantic version. If the installed app is older the client shows "update app" and stops fetching anything except the manifest (held data stays usable). This field IS the minimum-supported-version endpoint |
| `stale` | server-advertised ages. The client uses `min(its built-in 90 and 30, manifest value)`: the server can only shorten. Base older than `base_days` since `osm_ts` shows a banner; a schedule not confirmed for `sched_days` means calculated times |
| `redirects.gen` | generation of the redirects file; the client fetches it only when this changes |

### 4.2 Base cell (`/v1/base/{gh5}[.p{n}].json`, ODbL)

```json
{"v":1,"cell":"qqy81","part":1,"parts":1,"cv":"9c41e2a7","gen":412,
 "lic":"Masjid names, locations and addresses contain information from OpenStreetMap, which is made available here under the Open Database License (ODbL). © OpenStreetMap contributors. https://www.openstreetmap.org/copyright | https://opendatacommons.org/licenses/odbl/1-0/",
 "m":[{"id":"m4kx72ab","osm":"w123456789","k":"mosque","n":"Masjid Agung Jawa Tengah","ar":"المسجد الكبير","en":"Great Mosque of Central Java","sx":"masjid agung jawa tengah almsjd alkbyr","la":-7.00712,"lo":110.44581,"ad":"Jl. Gajah, Semarang 50116","dn":"sunni"}],
 "pad":"…"}
```

Record keys (allow-list; anything else fails `pack-check`): `id` (required, `^m[a-z2-7]{7}$`), `osm` (`n|w|r` + digits), `k` (`mosque|musalla`), `n`, `ar`, `en`, `ur`, `nl` (country-language name), `in`, `an` (alt/official/old names, search only), `sx` (generated Latin search key), `la`, `lo` (5 decimals), `ad` (address string), `dn` (OSM denomination), `wd` (Wikidata id), `rv` (needs review flag 1), `src` (curated source id). Empty values omitted. Never present: phone, email, website, operator, photos, contacts.

### 4.3 Overlay cell (`/v1/overlay/{gh5}[.p{n}].json`, project terms)

```json
{"v":1,"cell":"qqy81","part":1,"parts":1,"cv":"d41a7c03","gen":1189,"terms":"https://example.org/overlay-terms",
 "m":[{"id":"m4kx72ab","st":"V","vu":"2027-09-30","mz":"shafii","cm":"muslimWorldLeague","as":"s","hl":"m","of":[0,0,0,0,0,0],"az":"std","sv":4}],"pad":"…"}
```

An id absent from the overlay is Unclaimed. Pending Masjids carry `st:"P"` and nothing else (US4 AC3).

| Key | Meaning |
|-----|---------|
| `st` | `V` Verified, `P` Claimed pending |
| `vu` | verified until (date) |
| `mz` | madhhab (admin value, separate from OSM `dn`) |
| `cm` | calculation method: the Phase 0 `CalculationMethod` name (`muslimWorldLeague`, `isna`, `egypt`, `ummAlQura`, `karachi`, ...) |
| `as` | Asr juristic method: `s` standard, `h` Hanafi |
| `hl` | high-latitude rule: `m` middle of night, `s` seventh of night, `a` angle based |
| `of` | per-prayer offsets in minutes, six integers: fajr, sunrise, dhuhr, asr, maghrib, isha (Phase 0 `offsetsMinutes`) |
| `az` | Azaan variant |
| `sv` | schedule revision (equals `rev` in the sched record) |

The calculation settings `cm`, `as`, `hl`, `of` live here only; the coordinates come from the base record (`la`, `lo`) of the same id; schedule-rules.md never duplicates either.

### 4.4 Overlay index (`/v1/overlay/index.json`)

```json
{"v":1,"gen":1189,"terms":"https://example.org/overlay-terms","c":{"qqy81":1,"qqy82":2}}
```
`c` maps each `gh5` that has overlay data to its part count. The client requests overlay files only for cells listed here.

### 4.5 Schedule bundle (`/v1/sched/{gh4}[.p{n}].json`)

```json
{"v":1,"cell":"qqy8","part":1,"parts":1,"cv":"5be10c44","gen":1189,"terms":"https://example.org/overlay-terms","rf":"masjid-schedule/1",
 "s":["m4kx72ac","m4kx72ad"],
 "m":[{"id":"m4kx72ab","tz":"Asia/Jakarta","rev":4,"upd":"2026-10-20T04:11:00Z","r":[ /* see schedule-rules.md */ ]}],"pad":"…"}
```
`s` = ids of every other Masjid in the area (id-only stubs); `m` = rules records for Verified Masjids with a schedule. One request names an area, never a Masjid. An id in neither `s` nor `m` means "removed or unverified": the client checks redirects and then shows the status notice. The area has parts when oversized; the client MUST fetch all parts of an area (fetching only the part that holds its id would reveal the id).

### 4.6 Country summary (`/v1/country/{ISO2}.json`)

```json
{"v":1,"cc":"ID","gen":412,"lic":"…","m":[{"id":"m4kx72ab","n":"Masjid Istiqlal","ar":"مسجد الاستقلال","la":-6.17007,"lo":106.83142,"rk":1}]}
```
Only major Masjids, sorted by `rk` (curated rank, 1 first). Never split: if a country exceeds 500,000 bytes the builder keeps the lowest ranks. The curated Two Holy Mosques list ships as the `rk`-ordered head of `SA`.

### 4.7 g4 index (`/v1/g4/{gh4}.json`)

```json
{"v":1,"cell":"qqy8","gen":412,"lic":"…","c":[["1",1,5],["2",2,310],["z",1,2]]}
```
`c` = non-empty child cells: last geohash character, part count, Masjid count. Used by the "Area" flow.

### 4.8 Redirects (`/v1/redirects.json`)

```json
{"v":1,"gen":410,"lic":"…","r":{"m3aaaaab":"m4kx72ab","m3bbbbbc":null}}
```
Ids only. A string value is the surviving id (chains flattened at build, no cycles); `null` is a tombstone (hidden Masjid). Entries are kept at least 12 months.

### 4.9 Dumps (`/dumps/`)

| File | Content |
|------|---------|
| `directory-base-{gen}.ndjson.gz` | one base record per line (same keys as 4.2 plus `osm`, `osm_ts`, `gen`); overlay never included (FR-031) |
| `LICENSE-ODbL-1.0.txt`, `NOTICE.md`, `SHA256SUMS` | licence, notice (section 9), checksums |
| `latest.json` | `{"gen":412,"file":"directory-base-412.ndjson.gz","sha256":"…","bytes":3112345}` |

One dump per generation, last 12 kept, also uploaded as GitHub Release assets. The generator is open source in `tools/directory-pack/`.

## 5. Size limits, parts and padding

| Rule | Value |
|------|-------|
| Hard limit | 500,000 UNCOMPRESSED bytes per file, measured on the unpadded canonical bytes (deterministic whatever `Accept-Encoding` says) |
| Parts | `N = ceil(unpadded bytes / 400 KB)` (KB = 1000 B); a record goes to part `1 + FNV-1a-32(id as UTF-8) mod N`; part 1 has no suffix, later parts `.p{n}`; `N <= 16` |
| Part meaning | none spatial: nothing finer than the cell is ever a request target |
| Balance | after splitting every part MUST be under 500,000 unpadded bytes; if hashing leaves one over, N grows by one and the split is redone |

**Padding** (R-17). Applies to base, overlay and sched pack files only. A trailing member `"pad"` carries a deterministic incompressible string (base64url of a SHA-256 counter stream keyed by `cv` and the part number, so unchanged files stay byte-identical). Readers MUST ignore it and MUST NOT store it. Whitespace padding is forbidden: gzip removes it and the wire size would again identify the cell.

Size classes are 4, 16, 64, 256 and 512 KB (decimal: 4,000 / 16,000 / 64,000 / 256,000 / 512,000 bytes) of **gzip-9 transfer size** (ratio 4 between classes, so the typical cell of a few records falls in the 4 KB class and the first near-me download is about 40 KB, not 580 KB), because the app asks for gzip only (dart:io cannot decode brotli). The builder produces the `.gz` sidecar itself (Node zlib level 9, no name or mtime in the header), picks the smallest class that holds it and adds pad until the sidecar is within 32 bytes below the class. The `.br` sidecar is built from the same padded file; its size is not guaranteed to be in a class (only browsers and curl use it).

How the limits relate: the 500,000 limit is on unpadded bytes and decides splitting; padded files are for transfer size only. The padded UNCOMPRESSED body of every part MUST stay at or below 512,000 bytes, which is under the client's 600 KB body cap (directory-client.md). If padding to the next class would break that bound (an unpadded part above about 330 KB), the file is padded only up to 512,000 uncompressed bytes and is exempt from the class rule; `pack-check` reports these as `class_exempt`. No cell is near this today (densest, Semarang, is 44 KB raw).

Not padded: manifest, overlay index, country, g4, redirects, dumps (their names do not depend on the listener's position).

## 6. Publish procedure

Generations are directories `/srv/data/gen/{gen}-{layer}/v1/...` and `/srv/data/current` is a symlink to a merged view (`current -> gens/{n}`).

1. Build into a fresh directory `gens/{n}.tmp` (queue `packs`, section 8). A file is written to `name.tmp` in the same directory, fsynced and `rename(2)`d: readers never see a partial file.
2. Unchanged files are hard-linked from the previous generation (same inode, same mtime), never rewritten, never `touch`ed. Caddy derives its ETag from mtime and size, so a rewritten identical file would invalidate every phone's cache and cost 30,000+ needless 200s.
3. For a changed multi-part set: write parts 2..N first, part 1 last (part 1 carries `cv`; a 304 on part 1 therefore proves the whole set unchanged, and a phone that reads part 1 first never sees a part 1 newer than parts it can still fetch).
4. Write `.gz` and `.br` sidecars next to each file before the file itself becomes visible.
5. Run `scripts/pack-check gens/{n}.tmp`; on failure delete the directory and keep the old generation live.
6. Flip: `ln -sfn gens/{n} current.new && mv -Tf current.new current` (atomic). Manifest is written last inside the generation, so it never advertises files that are not there.
7. Old generations stay at least 30 days (R-21), then `pack-sweep` removes directories older than 30 days that are not `current` or the previous 3 generations. Redirects entries and the last 12 dumps are kept separately (12 months, 12 files).

## 7. Caddy behaviours the design depends on

| Behaviour | Why |
|-----------|-----|
| `file_server { precompressed br gzip }` (sidecars `.br`, `.gz` beside each file) | no per-request CPU; gzip wire size is fixed by the build |
| ETag from mtime and size, per encoding variant | conditional requests work only if unchanged files keep mtime (section 6.2) |
| `If-None-Match` gives 304 with no body | prayer-time herd is mostly 304 (R-20) |
| Range requests give 206 | PMTiles on `console.` only; not used by packs |
| Custom 404 with `Cache-Control: public, max-age=3600` for `/v1/base/*` | empty cells are common; avoids repeat load |
| `data.` has no `log` block, error log filtered, metrics aggregate by host and status only | FR-027, no address and path pair is ever written |
| `Cache-Control` per path via `header` matchers (section 2) | as the table |
| HSTS, nosniff, no-referrer, `-Server` | R-21 header set |

Tested on Caddy 2.11.7 (R4). A CI job (`caddy-static`) runs the real image against a sample tree and asserts sidecar selection, 304, 404 headers and the absence of log output.

## 8. Build job outline

| Item | Rule |
|------|------|
| Queue | pg-boss queue `packs` in the worker; jobs idempotent |
| Singleton key | `cell:{gh5}` for base and overlay, `area:{gh4}` for sched, `country:{cc}`, `manifest`; a second job with the same key while one is queued is dropped |
| Triggers | commit of a Masjid change (profile, status, base override) enqueues its cell; a schedule change enqueues its area and its overlay cell; status transitions enqueue the same; the monthly import enqueues a full build |
| Debounce | `startAfter` 30 s so a burst of edits builds once |
| Nightly full diff | 03:00 UTC: rebuild everything in memory, compare canonical bytes with `current`, publish only differences (a safety net for missed triggers) |
| Output | canonical JSON, pad, sidecars, manifest, g4 index, overlay index, redirects, dump (monthly) |
| Concurrency | one publisher at a time (advisory lock); builders may run in parallel before it |
| Failure | a failed `pack-check` keeps the previous generation and raises an alert; the job retries 3 times with back-off |

## 9. Licence and attribution strings

Exact strings (R-27, verbatim form from R4 section 1):

| Use | Text |
|-----|------|
| Footer, console footer, map corner | `© OpenStreetMap contributors` linked to `https://www.openstreetmap.org/copyright` |
| Full text (About, dump README, `LICENSES/NOTICE`, `lic` field of every base, country, g4 and redirects file) | `Masjid names, locations and addresses contain information from OpenStreetMap, which is made available here under the Open Database License (ODbL). © OpenStreetMap contributors. https://www.openstreetmap.org/copyright \| https://opendatacommons.org/licenses/odbl/1-0/` |

`NOTICE.md` (dump): attribution line above; source (Geofabrik extract, `osm_ts`); "This dump contains only OpenStreetMap-derived and curated base fields. The overlay (status, schedules, calculation settings) is a separate database under separate terms and is not included"; field list of section 4.2; method link `tools/directory-pack/`; ODbL 1.0 reference. Curated entries show `src`. The 4.2c rule (keep OSM notices) is met by the header.

## 10. Validation checklist: `scripts/pack-check <dir>`

| # | Check | Fails when |
|---|-------|-----------|
| 1 | unpadded bytes | any file above 500,000 bytes |
| 2 | padded body | uncompressed body above 512,000 bytes; gzip size not in a class (except `class_exempt`) |
| 3 | parts consistent | `parts` differs between parts, a part missing, suffix beyond N, `part` wrong, hash(id) mod N wrong |
| 4 | `cv` | recomputed `cv` differs from any header |
| 5 | JSON Schema | file does not match its schema (schemas in `contracts/schemas/*.json`) |
| 6 | key allow-list | any key outside section 4 (blocks `phone`, `email`, `contact`, `website`, `photo`, `operator`, `note`) at any depth |
| 7 | licence | `lic` missing or not equal to section 9 text (base layer); `terms` missing (overlay) |
| 8 | layer separation | a base file containing overlay keys (`st`, `mz`, `cm`, `sv`...) or the reverse |
| 9 | ids | not `^m[a-z2-7]{7}$`; duplicate id in a layer; overlay or sched id absent from base; `rev` differs from overlay `sv` |
| 10 | coordinates | `la`, `lo` more than 5 decimals, or a record outside its cell |
| 11 | determinism | rebuilding gives byte-identical files; unchanged files keep inode and mtime |
| 12 | sidecars | `.gz` or `.br` missing or not equal to the compressed file |
| 13 | manifest | paths listed do not exist; `min_app` not a version; `overlay.gen` differs from the index |
| 14 | schedules | every rules record passes the schedule-rules.md validator with no error |

## 11. Issues found

| # | Contradiction | Recommendation |
|---|---------------|----------------|
| 1 | A 64 KB minimum class (first draft) would have made the world store about 10 GB and a 9-cell first download about 580 KB. | RESOLVED by the coordinator: classes are 4, 16, 64, 256 and 512 KB (section 5), so the median cell costs 4 KB. Padding only hides sizes from an observer who already sees the address, timing and nine requests, so it is kept modest. |
| 2 | R-17 says padded to 64..512 KB; R-28 says 500 KB limit on uncompressed bytes. They only fit if the class is the transfer size and the padded body stays at or below 512,000 bytes (section 5). | Adopted; `class_exempt` covers the rare top end. |
| 3 | R-21 gives manifest and schedule `max-age=60`; R-29 gives 300 and 900; R-21 calls versioned files immutable but R-29 paths are not content-addressed. | R-29 table used. Edit R-21. |
| 4 | R4 puts `Access-Control-Allow-Origin: *` on all files; R-29 omits it. | Only on `/dumps/*`. |
| 5 | R-27 puts the full text in `lic`; R4's example uses a 35-byte short form. | Full text (padding makes size irrelevant). |
| 6 | `gen` in the header would change every file each generation and break "never rewrite unchanged files". | `gen` = last-changed generation (section 3). |
| 7 | R-28 says the client skips all revalidation when manifest gens are unchanged, but a schedule is stale after 30 days without a sync. | A manifest response whose `overlay.gen` equals the gen of a held schedule counts as a sync (directory-client.md section 8). |
| 8 | The brief says coordinates come from the overlay record; overlay never holds coordinates (R-27, base holds `la`,`lo`). | Coordinates from base, settings from overlay. |
| 9 | R4 and R-28 do not say what "whole country" downloads. A country-to-cells index does not exist and 9,000 padded cells would be about 600 MB. | "Whole country" fetches only the country summary (4.6). |
| 10 | R-29 `stale` rules live in the client; the manifest also carries them. | Client uses the minimum of both. |
| 11 | Part count above 16 or a country file above 500,000 bytes has no R-28 rule. | N capped at 16; country keeps lowest `rk` entries. |

## 12. Validation

| Proves | Test |
|--------|------|
| Sections 3 to 5 | `scripts/pack-check` on a generated 300,000-Masjid fixture tree (CI, every pull request) |
| JSON Schemas and examples | Vitest plus Ajv: every example in this file validates; a mutated key fails |
| Parts, `cv`, publish order | integration test: publish while a client fetches in a loop; no mixed-cv commit ever succeeds |
| Unchanged files untouched | rebuild test asserts inode and mtime equality |
| Caddy behaviour | `caddy-static` job (section 7) |
| Padding classes | unit test on the builder: gzip size within 32 bytes of the class for 1,000 random cells |
| Allow-list and licence header | `pack-check` checks 6 and 7 with a poisoned fixture containing a phone number |
| Load and herd | vegeta S1 to S3 (R-24) against a tree with padded files |
