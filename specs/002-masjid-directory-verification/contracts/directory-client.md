# Contract: Directory Client (`packages/directory_client`)

**Spec**: [../spec.md](../spec.md) (FR-001, FR-003, FR-011, FR-012, FR-014, SC-003, SC-004) | **Decisions**: [../research.md](../research.md) R-07, R-17, R-20, R-24, R-28, R-29 | **Related**: [static-files.md](static-files.md), [schedule-rules.md](schedule-rules.md), `openapi.yaml` (written in parallel)

`packages/directory_client` is the ONLY network code in the app. It uses `dart:io` `HttpClient` directly (no new pub dependency for HTTP; SHA-256 for the proof of work comes from `package:crypto`, already in `pubspec.lock` as a transitive dependency: confirm in the plan). Normative words: MUST, SHOULD, MAY.

## 1. Typed API (no generic `get(url)`)

```dart
abstract interface class DirectoryClient {
  Future<Fetch<Manifest>>     manifest({String? etag});
  Future<Fetch<OverlayIndex>> overlayIndex({String? etag});
  Future<Fetch<AreaIndex>>    area(String gh4, {String? etag});
  Future<Fetch<CountryFile>>  country(String iso2, {String? etag});
  Future<Fetch<Redirects>>    redirects({String? etag});
  Future<Fetch<Pack>>         basePart(String gh5, int part, {String? etag});
  Future<Fetch<Pack>>         overlayPart(String gh5, int part, {String? etag});
  Future<Fetch<Pack>>         schedPart(String gh4, int part, {String? etag});
  Future<PowChallenge>        powChallenge();              // GET /v1/public/pow-challenge
  Future<SubmitResult>        submitSuggestion(Suggestion s);
  Future<SubmitResult>        submitAbuseReport(AbuseReport r);
}
sealed class Fetch<T> { Fetched(T value, String? etag, int bytes) | NotModified() | NotFound() }
```

| Item | Rule |
|------|------|
| Inputs | validated types only: `gh5` 5 chars and `gh4` 4 chars of the geohash alphabet, `iso2` two capitals, `part` 1 to 16. Coordinates never enter the package: callers compute the cell id on the phone (`GeohashCell.fromLatLon` lives in the app) |
| Outputs | parsed and validated objects (header checked, record keys allow-listed, `pad` dropped); raw bytes never leave the package |
| Errors (sealed `DirectoryError`) | `DirectoryDisabled` (null object), `ConsentMissing(scope)`, `EgressDenied(reason)`, `BodyTooLarge`, `Timeout`, `NetworkError`, `HttpError(status)`, `RateLimited(retryAfter)`, `ParseError(why)`, `LicenceMissing`, `UnsupportedVersion`, `PublishInProgress`, `LooksLikeCoordinates`, `PowFailed` |
| Orchestration | `DirectorySync` (same package) runs the flows in sections 7 to 10 on top of the client and an injected `DirectoryStore` (cell state, atomic commit, consent, follows: implemented with SQLite in the app, in memory in tests). The package has no SQLite or Flutter dependency |

## 2. Configuration, consent, kill switch

| Item | Rule |
|------|------|
| Build constants | `--dart-define=DEEN_DIRECTORY_BASE_URL=https://data.<domain>` and `DEEN_DIRECTORY_API_URL=https://api.<domain>` |
| Kill switch | empty `DEEN_DIRECTORY_BASE_URL` gives `DisabledDirectoryClient`: every method throws `DirectoryDisabled`, no `HttpClient` is created, zero sockets (the Phase 0 behaviour). Empty `DEEN_DIRECTORY_API_URL` disables the two POSTs only |
| Consent | `DirectoryConsent{atMs, scopes, version}`, scopes `nearMe`, `area`, `country:{ISO2}`, `manual`, `submit`. The constructor of the real client requires one; every method checks that a scope covers the request. Consent is persisted (`directory_state.consentAtMs`), revocable in settings; revoking wipes `directory.db` and cached state |
| Consent text | states what is sent: the phone's IP address and the 5 km cell (or the area); nothing else; the server keeps no log pairing them (R-17); "use a VPN if that matters". Choices: Near me, Area, Whole country (summary only), Manual, Not now |
| Setup | Phase 0 setup stays offline; the first network use is a Masjids screen action after consent |

## 3. EgressPolicy

`EgressPolicy.check(method, Uri)` runs before every request and on every redirect hop. Any violation throws `EgressDenied` before a socket opens.

| Rule | Value |
|------|-------|
| Scheme, port | `https`, 443 (explicit port rejected in production; a test-only constructor accepts a port) |
| Hosts | GET only to the host of `DEEN_DIRECTORY_BASE_URL`; POST only to the host of `DEEN_DIRECTORY_API_URL`; exact, lowercase string match, no wildcard |
| URI | no query, no fragment, no userinfo; total path at most 64 characters; no `%`, no `..`, no `//` |
| Redirects | off by default. At most 1 hop, to the same host and scheme, and the target must itself pass the path allow-list. A redirect on POST is refused |
| Cookies | none: no jar, `Set-Cookie` ignored |
| Authorization | never sent |

Geohash class `G = [0-9b-hjkmnp-z]` (32 symbols, no `a i l o`); part suffix `P = (\.p([2-9]|1[0-6]))?`.

| Method, host | Path regex |
|--------------|------------|
| GET data | `^/v1/manifest\.json$` |
| GET data | `^/v1/base/G{5}P\.json$` |
| GET data | `^/v1/overlay/index\.json$` |
| GET data | `^/v1/overlay/G{5}P\.json$` |
| GET data | `^/v1/sched/G{4}P\.json$` |
| GET data | `^/v1/country/[A-Z]{2}\.json$` |
| GET data | `^/v1/g4/G{4}\.json$` |
| GET data | `^/v1/redirects\.json$` |
| POST api | `^/v1/public/suggestions$` and `^/v1/public/abuse-reports$` |
| GET api | `^/v1/public/pow-challenge$` (stateless Altcha challenge; `openapi.yaml` `getPowChallenge`) |

Not allowed anywhere: `/dumps/*`, any 6-character cell, any path with `\d+\.\d{3,}`, any other path. The patterns are generated from one table in `lib/src/egress_grammar.dart` that the privacy test also uses.

Fixed header set (asserted on the fake server):

| Request | Headers (exactly) |
|---------|-------------------|
| GET | `Host`, `Accept: application/json`, `Accept-Encoding: gzip`, `User-Agent: DeenDirectory/1`, `If-None-Match: <etag>` only when an ETag is held, `Connection` (set by dart:io) |
| POST | the same minus `If-None-Match`, plus `Content-Type: application/json`, `Content-Length`. `GET /v1/public/pow-challenge` uses the GET set |

No other header is allowed: no `Cookie`, `Authorization`, `Referer`, `X-*`, `Accept-Language`, install or session id, device model, locale. The User-Agent carries no OS, device or app build. System trust store only, no `badCertificateCallback`, TLS 1.2 or later, no pinning (no signatures in Phase 1; integrity is TLS plus `cv`; signing is a Phase 2 prerequisite, R-07). dart:io speaks HTTP/1.1; Caddy serves it.

## 4. POST bodies (mirror of `openapi.yaml`; the contract test compares)

Source: `openapi.yaml` (`createSuggestion`, `createAbuseReport`, `getPowChallenge`; schemas `PublicSuggestionRequest`, `PublicAbuseReportRequest`, `PowChallenge`). The contract test compares these tables with the file. JSON UTF-8, `Content-Type: application/json` (else 415); response `202 {"status":"accepted"}` (uniform: it never says whether anything matched), `422`, `429` with `Retry-After`. Both POSTs are on the api host.

| Endpoint | Body fields the app sends |
|----------|---------------------------|
| `POST /v1/public/suggestions`, `kind:"correction"` | `kind`, `masjid_id`, `body` (1 to 2,000 characters), `pow` |
| `POST /v1/public/suggestions`, `kind:"new_masjid"` | `kind`, `cell_id` (5-character cell), `country_code`, `proposed_name` (1 to 200), `proposed_address` (up to 400), `terms_version`, optional `body` (note), `pow`. No coordinates; an Operator places the pin on accept |
| `POST /v1/public/abuse-reports` | `kind` (`wrong_info`, `fake_masjid`, `impersonation`), `masjid_id`, `body` (1 to 2,000), `pow` |
| `GET /v1/public/pow-challenge` | no body; returns `{algorithm:"SHA-256", challenge, salt, maxnumber, signature}`, `Cache-Control: no-store` |

| Rule | Detail |
|------|--------|
| Never sent | `contact_email` (optional in the API, but the app MUST NOT send it: no identifiers) and `hp` (honeypot, left absent); no device, locale, install or time data |
| `pow` | before each POST: `GET` a challenge, find `number` in `0..maxnumber` with `SHA-256(salt + number) == challenge` (SHA-256 from `package:crypto`), send base64 of `{"algorithm","challenge","number","salt","signature"}` (at most 2,048 characters). Solved in a background isolate, at most 20 s, cancellable (`PowFailed`). The server keeps no state (HMAC signature) |
| `terms_version` | the contribution-terms version the user accepted on the submit screen (ODbL notice, R-27) |
| Coordinate guard | before sending, `body`, `proposed_name` and `proposed_address` are rejected (`LooksLikeCoordinates`) when they match `-?\d{1,3}[.,]\d{3,}` or a map link (`geo:`, `google.<tld>/maps`, `openstreetmap.org/(#map|?mlat)`) |
| Size | request at most 8 KB |

## 5. Limits

| Limit | Value |
|-------|-------|
| Connect timeout | 10 s |
| Total timeout per request | 30 s |
| Body cap (decoded) | 600 KB for pack parts and country, 256 KB for manifest, 256 KB for the other index files; a stream that exceeds it is aborted: `BodyTooLarge` |
| Parallel downloads | at most 3 |
| Redirects | 1 hop (section 3) |

## 6. Conditional requests and per-cell cache state

`directory.db` table `cell_state(layer, cell, parts, cv, gen, etag1, fetched_at, verified_at)`; `layer` is `base`, `overlay` or `sched`. Only part 1 carries a stored ETag: part 1 is written last by the publisher and its header holds `cv` of the whole set, so a 304 on part 1 proves the whole set is unchanged; when part 1 changes, every part changed (the `cv` is in each header) and parts 2..N are fetched without `If-None-Match`. `verified_at` is advanced on 200 and on 304. Cells whose base file returned 404 are stored as empty (`parts=0`) and re-requested after 1 hour (the 404 `max-age`).

## 7. Update cadence

| Rule | Value |
|------|-------|
| Manifest check | at most one per 12 hours (`nextCheckAfterMs`), on launch or foreground, conditional. Skipped entirely when consent is missing |
| Skip rule | if `gen` and `overlay.gen` equal the stored ones, no other request is made |
| Revalidation | when `gen` changed: held base cells, conditional on part 1. When `overlay.gen` changed: the overlay index, then held overlay cells, then sched areas of followed Masjids whose overlay `sv` differs from the cached `rev` |
| New cells | background refresh NEVER fetches a cell the user did not choose (no new location data without a user action) |
| Prayer-time-triggered refresh | delay a random 0 to 120 s before the first request (herd, R-20); iOS `BGAppRefreshTask` may run `refreshFollowed()` within about 20 s; Android with the app closed does nothing |
| Back-off | 429, 5xx, timeout, network error: global exponential back-off 1 min, 2, 4, ... up to 6 h, honouring `Retry-After` (cap 24 h), persisted as `backoffLevel`, reset on success |
| Order and jitter | requests in a set are shuffled, started 100 to 800 ms apart, at most 3 in flight |
| Wi-Fi only | no (no `ACCESS_NETWORK_STATE`); a size prompt appears for the country file and for "widen" |

## 8. Staleness, schedule freshness, `min_app`

| Rule | Value |
|------|-------|
| Base age | `now - osm_ts` of the last manifest obtained (200 or 304) over the stored `stale.base_days`, using `min(90, manifest value)`: banner "directory data is old"; data remains usable |
| Schedule age | `now - syncedAt` over `min(30 days, manifest.stale.sched_days)`: calculated times and a banner (schedule-rules.md D4) |
| What counts as a sync | HTTP 200 or 304 on a sched part 1, OR a manifest response (200 or 304) whose `overlay.gen` equals the `overlay.gen` recorded when the held schedule was last fetched or confirmed (nothing changed since, so skipping revalidation must not let a stable schedule expire). `syncedAt := now` |
| Status change | overlay `st` for a followed Masjid that is no longer `V`, or the id missing from sched `m` and `s`: store a `masjid_notice`, keep the last good rules until `expiresAt`, offer calculated times |
| `min_app` | manifest `min_app` above the app version (semantic compare) or `schema` above 1: state `UpdateRequired`; only the manifest is fetched (at most every 12 h); held data remains usable; banner "update the app" |
| Unsupported pack | `v` not 1, or `rf` not `masjid-schedule/1`: file ignored, calculated times, banner "update the app" |

## 9. Flows and the exact requests they produce

Cell ids are computed on the phone. Order inside each step is shuffled and jittered (section 7). "If due" means the 12-hour rule.

| Flow | Requests (all GET, data host) |
|------|-------------------------------|
| Near me (3x3) | 1. `/v1/manifest.json` (if due). 2. `/v1/overlay/index.json` (if `overlay.gen` changed or none held). 3. For each of the 9 cells (the phone's cell and its 8 neighbours): `/v1/base/{gh5}.json`, plus `.p{n}` for parts 2..N. 4. For each of those cells listed in the overlay index: `/v1/overlay/{gh5}.json` plus parts. At most 2 + 9 + 9 requests plus parts. The UI states the real radius (3x3 covers one cell width: about 4.9 km at the equator, 3.5 km at 45 degrees) and offers "widen" (the next 16 cells, after a confirmation) |
| Area | `/v1/g4/{gh4}.json`, then base (and overlay) files of the non-empty children it lists. "Include neighbouring areas" adds up to 8 more `/v1/g4/{gh4}.json`, then their children |
| Country | `/v1/country/{ISO2}.json` only: the summary of major Masjids, and the curated Two Holy Mosques list for `SA`. It does not download cells |
| Manual | the user picks country then city from Phase 0's bundled `cities.db`; the city's centre gives a `gh4`; then the Area flow. No device location is used; the server learns the area the user chose |
| Follow and schedule | on confirm of a Verified Masjid (overlay `st:V`, `sv` present): `/v1/sched/{gh4}.json` plus ALL parts (never only the part that holds the id). Refresh follows section 7 |
| Redirects | `/v1/redirects.json` when `redirects.gen` changed and at least one follow exists. Followed ids are remapped (string) or marked "no longer listed" (`null`); a loop or more than 3 hops stops the remap |
| Text search | local only (FTS5); sends nothing. Online search of undownloaded places is not in Phase 1 |

No flow sends a request carrying coordinates, a Masjid id (apart from the POST bodies), a follow, a time or any identifier. The sched request names an area (about 39 by 19 km), which the consent text discloses.

### Multi-part atomic commit

1. `GET` part 1 (conditional if held). 304: set `verified_at`, stop. 404 (base only): store empty, stop.
2. Validate the header: `v` supported, `cell` equals the request, `part` is 1, `parts` is 1 to 16, `cv` is 8 hex, `lic` (base) or `terms` (overlay, sched) is present, else `LicenceMissing`.
3. For parts 2..N: `GET`, at most 3 in flight; validate `cell`, `part`, `parts` equal to part 1, and `cv` and `gen` equal to part 1.
4. Mismatch, a part 404, or a changed `parts`: a publish is in progress. Discard everything fetched, wait 2, 4, 8 s (plus jitter), restart at step 1 WITHOUT `If-None-Match`. After 3 retries fail with `PublishInProgress`; stored data is unchanged.
5. Validate every record (schema, allow-list, id grammar, coordinates inside the cell) before touching the store.
6. `store.commit(...)` writes all parts of the cell, the FTS rows and `cell_state` in ONE SQLite transaction, or nothing. A near-me or area set is staged in memory (at most 9 x 600 KB) and committed as one transaction; an interrupted set is discarded and the old data stays in use.

## 10. Android and iOS network configuration

| Platform | Setting |
|----------|---------|
| Android main manifest | `<uses-permission android:name="android.permission.INTERNET"/>` only; `ACCESS_NETWORK_STATE` stays forbidden; `android:usesCleartextTraffic="false"`; `android:networkSecurityConfig="@xml/network_security_config"` |
| `res/xml/network_security_config.xml` | `<base-config cleartextTrafficPermitted="false"><trust-anchors><certificates src="system"/></trust-anchors></base-config>` |
| `src/debug` only | a `debug-overrides` block that trusts the user CA (for the mitmproxy capture) and allows `10.0.2.2`; release MUST NOT contain it |
| iOS | App Transport Security default: no `NSAppTransportSecurity` key; `NSAllowsArbitraryLoads` stays forbidden; no new Info.plist key; `UIBackgroundModes` unchanged |

## 11. Privacy test contract (SC-004, FR-011)

| Item | Rule |
|------|------|
| Fake server seam | `package:directory_client/testing.dart` exports `FakeDirectoryServer` (loopback `HttpServer.bindSecure` with a test certificate, records every request as `RequestRecord{method, uri, sortedHeaders, body}`) and `DirectoryConfig.forTest(host, port, SecurityContext)`. `EgressPolicy` still runs in tests (host and port compared with the test values). The boundary scan forbids importing `testing.dart` from any `lib/` |
| Grammar checker | `RequestGrammar.violations(RequestRecord)` uses the section 3 table, the header set and a decimal-degree scan; it is also run on the server side of the fake |
| Property 1 (same cell) | for any two coordinates in the same cell, the ordered request set (method, URL, headers, body) of every flow is byte-identical |
| Property 2 (device state) | the same flow under two different simulated device states (locale, time zone, install time, preferences, device model) yields byte-identical request logs |
| Canary | a test-only seam sends a request with a fine coordinate (`?lat=-7.00712&lon=110.44581` and a 6-character cell path) straight to the checker and to the fake; the checker MUST report violations and the test fails if it does not, so the test cannot pass vacuously |
| Fuzz | 20,000 seeded random coordinates (seed printed) plus poles, +-180, +-90, exact cell edges, `-0.0`, `NaN`, 15 decimals, Null Island, and random query text (Unicode, 1 to 100 characters, URL metacharacters), through every flow; every URL must match the grammar; a `NaN` or out-of-range coordinate must throw before any request |
| Real traffic | mitmproxy captures the debug build in the nightly and release emulator job; DNS stub fails any other hostname; the HAR is archived with the release (R-24) |
| Server-down | Phase 0 suites run with the server returning 500, hanging, or the network off (section 13) |

## 12. Changes to `tools/license_scan` and Phase 0 documents

`tools/license_scan/bin/check_network.dart` is rewritten from "no INTERNET" to "INTERNET only in the one allowed place":

| Rule | Check |
|------|-------|
| a | INTERNET allowed in the main manifest only; `ACCESS_NETWORK_STATE` and the other forbidden permissions still fail; `usesCleartextTraffic="false"` and the network security config file are required |
| b | Dart import-boundary scan over `apps/**/lib` and `packages/**/lib`: network symbols (`HttpClient`, `Socket`, `WebSocket`, `package:http`, `dio`, `web_socket_channel`, `cronet_http`, `cupertino_http`) only under `packages/directory_client/lib`; `prayer_engine`, `schedule_planner` and `masjid_schedule` have no `dart:io` at all (they compile to JavaScript) |
| c | `pub deps --json`: http-class packages reachable from `apps/mobile` only through `directory_client` |
| d | URL-literal scan (`https?://`) in `lib/`: only the base-URL constant and an allow-listed set of attribution links (ODbL, OSM, GeoNames) opened in the system browser |
| e | allow-list file `tools/license_scan/network_allowlist.yaml` (hosts, permissions), reviewed in pull requests |
| f | merged release manifest check once Gradle builds exist: permissions equal Phase 0 set plus INTERNET |
| g | tracker denylist kept; the test in `test/scanner_test.dart` that asserts INTERNET is forbidden (line 177) flips |

Phase 0 documents to revise: constitution principle 9 (phase list) and Technology Constraints (PostGIS wording), Exceptions Register rows; `specs/001-offline-worship-app/spec.md` line 9, FR-001, FR-002, SC-007; `plan.md` of 001 (Summary, Technical Context, Constitution Check 1 and 4); `release/store-notes.md` sections 1 to 3; 001 `research.md` R-A7 and R-I7 ("collect" now includes IP and a 5 km cell); `content/privacy/privacy-policy.md` (four languages); l10n `about.json` lines 17 and 43, `setup.json` lines 138, 288, 467, `settings_data.json`; `README.md` line 4; `CONTRIBUTING.md` line 23; `.github/pull_request_template.md` item 1; the main `AndroidManifest.xml` comment; the `check_network.dart` header comment.

## 13. Phase 0 regression guard (FR-001, SC-003)

1. `apps/mobile/test/flutter_test_config.dart` installs a global `HttpOverrides` guard driven by `--dart-define=DEEN_TEST_NET=off|fail|hang|garbage`. `off` (default) throws on any socket and fails any test that did not opt in, proving Phase 0 features make zero requests. CI runs the whole existing `flutter test --exclude-tags golden` under `off`, `fail` and `hang`.
2. Provider-level: override `directoryClientProvider` with `ThrowingDirectoryClient`, corrupt or delete `directory.db`; `AppShell`, `HomePage`, setup and `ScheduleCoordinator.rebuild` still succeed and the plan equals the Phase 0 plan byte for byte (`PlannedAlert.toJson`) when `scheduleSource=calculated`.
3. Identity: `MasjidScheduleEngine(source: null)` equals the wrapped engine on every `fixtures_gen` oracle vector; all existing `planning_*.json`, `arbiter.json`, `alert_ids.json`, `recording_mapping.json` pass unchanged (additions only in the Phase 1 pull request).
4. Instrumented Android run with airplane mode and a build with empty `DEEN_DIRECTORY_BASE_URL` pass the same suites.

## 14. Issues found

| # | Contradiction | Recommendation |
|---|---------------|----------------|
| 1 | R6 gives path forms `/v1/c/..`, `/v1/g/..` with integer grid ids; R7 gives `/v1/regions/{cc}/{cell}`, `/v1/schedules/{masjidId}.json` (a per-Masjid path would reveal the Masjid). | R-29 geohash paths only (section 3). |
| 2 | R6 and R-07 mention an Ed25519-signed manifest and per-file sha256; R-07 later says no signatures in Phase 1. | No signatures; integrity is TLS plus `cv`. |
| 3 | R6 caps manifest checks at one per 24 h; R-28 says 12 h. | 12 h. |
| 4 | R-28 skips all revalidation when gens are unchanged, which would let a stable schedule go stale after 30 days. | Manifest confirmation counts as a sync (section 8); owner to confirm. |
| 5 | R6 sends `Accept-Encoding: gzip`; static-files and R-21 offer brotli sidecars. dart:io cannot decode brotli. | App asks for gzip only; padding classes are defined on gzip size (static-files.md section 5). |
| 6 | The brief lists two POSTs only; `openapi.yaml` adds `GET /v1/public/pow-challenge` (stateless Altcha) and field names differ from my first draft (`masjid_id`, `body`, `cell_id`, `country_code`, `proposed_name`, `proposed_address`, `terms_version`, kind `new_masjid`, `fake_masjid`). | Contract follows `openapi.yaml` (sections 3 and 4). The API also accepts an optional `contact_email`; the app never sends it. |
| 7 | The brief defines only `DEEN_DIRECTORY_BASE_URL`; POSTs go to another host. | Added `DEEN_DIRECTORY_API_URL`. |
| 8 | "Whole country" and "Manual" are not defined in R-28 beyond one line. | Country summary only; Manual uses the Area flow (section 9). |
| 9 | R-30 says the 9-cell set is atomic; a flaky link makes that all-or-nothing and costs about 40 KB per retry. | Keep atomic (padding classes 4, 16, 64, 256, 512 KB keep a retry near 40 KB). |
| 10 | Spec FR-011 forbids anything finer than a 5 km cell; the sched request names a 39 by 19 km area for each followed Masjid, and "widen" and Area reveal larger sets. | Coarser, so allowed; disclosed in the consent text. |

## 15. Validation

| Proves | Test |
|--------|------|
| EgressPolicy table | about 150 allow and deny vectors in `egress_vectors.json`, run in Dart: coordinates in path, query, header, body; 6-character cell; `%`; userinfo; fragment; wrong host; POST to the data host; redirect to another host |
| Single choke point | `check_network.dart` rules a to g with tests in `scanner_test.dart` |
| Header set and no cookies | fake-server integration test asserts the exact header set, `DeenDirectory/1`, no `Cookie` |
| Properties, canary, fuzz | section 11, every pull request; mitmproxy HAR nightly and per release |
| Atomic commit | test that kills the process between parts, serves a mixed-`cv` set and a 404 part; stored data never changes |
| Cadence and back-off | fake clock tests: 12-hour manifest rule, jitter bounds, 429 with `Retry-After`, 3 parallel downloads |
| Staleness | fake clock: base 90 days, schedule 30 days, manifest confirmation extends `syncedAt`, `min_app` and unsupported `rf` |
| Kill switch | empty base URL: no `HttpClient` constructed (override counts zero sockets) |
| Phase 0 guard | section 13 under `DEEN_TEST_NET=off|fail|hang` in CI |
| Platform config | Android merged-manifest check, `network_security_config` present, iOS plist has no ATS keys |
