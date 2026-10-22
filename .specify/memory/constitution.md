<!--
SYNC IMPACT REPORT (latest)
Version change: 1.1.0 → 1.2.0 (MINOR: one Exceptions Register entry widened, no principle changed)
Modified sections: Exceptions Register (GitHub row now also covers GitHub Pages for the privacy-policy page,
  decided 2026-10-22, plan D-5); Amendment Changelog (new entry).

PREVIOUS REPORT (1.1.0)
Version change: 1.0.0 → 1.1.0 (MINOR: materially expanded guidance, no principle removed or redefined)
Modified principles: none renamed; no principle text changed
Modified sections:
  - Technology Constraints, Mobile bullet: native Swift/Kotlin scope widened from "only for
    AudioSession, Live Activities and foreground services" to a defined list plus a contract rule
    (feature plan 001, decision D-1)
  - Exceptions Register: GitHub row widened to cover repository hosting (Actions free tier stays
    optional)
Added sections: Amendment Changelog
Removed sections: none
Deferred items:
  - GitHub Pages (or any hosting for the privacy-policy URL) is NOT added to the Exceptions
    Register; plan decision D-5 is still open. Add by amendment once decided.
  - TODO(FRAMEWORK_CHOICE) from 1.0.0 is resolved: Flutter is named in Technology Constraints.
Templates requiring updates: none (templates read this file at runtime)

PREVIOUS REPORT (1.0.0)
Version change: 1.0.0 (unreleased generic draft) → 1.0.0 (full rewrite, as instructed)
  Note: the earlier 1.0.0 was a placeholder draft that was never released or committed, so the
  version was not bumped. Any later change to this file follows the semver rules in Governance.
Modified principles (old → new):
  - I. Authentic & Sourced Content → folded into 3 (scholar-reviewed sources) and 10 (licensing)
  - II. Privacy & Respect by Default → 4. Privacy by design
  - III. Offline-First Mobile Experience → 1. Local-first reliability
  - IV. Accessibility & Localization → 11. Accessibility and localization
  - V. Test-First & Simplicity → split into 8. Testing and quality gates, 9. Simplicity and scope
Added sections: Product Mission; principles 2, 5, 6, 7, 10; Technology Constraints;
  Exceptions Register
Removed sections: Platform & Technical Constraints; Development Workflow & Quality Gates
  (content moved into principle 8 and Technology Constraints)
Deferred / follow-up items:
  - Exceptions Register entry for GitHub Actions free tier was added because principle 8 names it
    while principle 10 forbids freemium SaaS. Confirm it, or switch CI to self-hosted runners.
  - Targets required by principle 6 (concurrent listeners per prayer window, monthly cost
    ceiling) are mandated but not yet set. Set them in the first Phase 1 spec.
  - Sources, licenses and scholar reviewers (principle 3) and LICENSES/NOTICE (principle 10)
    must be created before any content ships.
Templates requiring updates: none (templates read this file at runtime)
-->

# Deen App Constitution

## Product Mission

Help Muslims never miss a prayer call, with the Azaan of their own Masjid where possible.
Reliability, trust and respect for the user's religious practice outrank feature count. The
project is built entirely on open-source, unpaid software so that a community can run, audit
and sustain it.

Scope: a Flutter mobile app (Android and iOS) with a Node.js (TypeScript) backend, delivering
reliable Azaan alerts, live Azaan broadcasts from verified Masjids, and daily worship tools.

## Core Principles

### 1. Local-first reliability
- The baseline Azaan MUST work with no network and no server: prayer times calculated
  on-device, Azaan played from a locally scheduled alarm or notification with bundled audio.
- Live streaming and push wake are enhancements. A feature that makes the baseline depend on a
  server round-trip MUST be rejected.
- If a live stream fails or drops for more than 3 seconds, the client MUST fall back to the
  bundled Azaan. It MUST restart from the beginning or seek to the estimated offset, and MUST
  NOT join mid-file at the wrong position.

Rationale: a missed Azaan is the one failure this product exists to prevent.

### 2. Platform honesty
- iOS:
  - MUST NOT use VoIP/PushKit push for non-call purposes.
  - MUST NOT assume silent pushes start audio.
  - MUST NOT claim programmatic Focus/DND control.
  - Critical Alerts (about 30 seconds, bundled sound, requires Apple approval) MAY be offered as
    an optional bonus and MUST NOT be a dependency.
  - Live Activities MUST show static Masjid info and a listen action, not a live waveform.
- Android:
  - MUST use USAGE_ALARM for the alarm-stream override and MUST NOT use USAGE_EMERGENCY.
  - MUST request ACCESS_NOTIFICATION_POLICY only for the optional post-Azaan DND feature, and
    MUST restore the user's prior DND state.
  - MUST use audio focus, not READ_PHONE_STATE, for in-call handling.
  - MUST declare the mediaPlayback foreground service type.
  - MUST account for Doze and OEM battery killers.
- Every platform-specific claim in a spec MUST cite the platform doc or Play/App Store policy
  it relies on.

Rationale: features built on unsupported OS behavior fail silently or get the app rejected.

### 3. User consent and respect
- Overriding silent/DND MUST be opt-in, per prayer, off by default, with a gentle volume ramp
  and a quiet-hours option.
- The user MUST confirm their Masjid. The app MUST NOT auto-select one silently. It MUST show
  the Masjid's madhhab/calculation settings and Azaan variant.
- The app MUST suppress phone playback when the user is within about 150 m of the broadcasting
  Masjid, so it does not echo the real Azaan.
- Azaan audio and Quran/Adhkar text MUST come from sources reviewed by a qualified scholar. Each
  source, its license and the reviewer MUST be recorded.

Rationale: worship is personal, and the app must never impose on it or misstate it.

### 4. Privacy by design
- Religious affiliation combined with location is special-category data (GDPR and similar) and
  MUST be handled as such.
- The server MUST NOT store per-user location. Location stays on-device and the app subscribes
  to per-Masjid push topics.
- The system MUST collect the minimum data needed, MUST NOT include third-party ad, tracking or
  analytics SDKs, and MUST provide account and data deletion.
- Telemetry, if any, MUST be opt-in, anonymous and self-hosted.

Rationale: a server that never holds location cannot leak it or be compelled to disclose it.

### 5. Broadcast security and trust
- A hijacked live stream plays through silent mode on thousands of phones, so broadcasting is a
  privileged action.
- Broadcasters MUST pass verification (documents, committee or phone validation) and MFA (TOTP
  via open-source libraries, no paid SMS providers). Their devices MUST be bound using Play
  Integrity or App Attest within free quotas.
- Publish tokens MUST be short-lived and room-scoped.
- The system MUST have an operator kill switch, a 5-10 second moderation delay on live streams,
  rate limits, and alerts for broadcasts outside expected prayer windows.
- A broadcast MUST auto-cut-off after a configurable 3-5 minutes.
- The scheduled backup Azaan MUST be offered if the Muazzin has not started within 3 minutes of
  the Masjid's scheduled time.

Rationale: one bad broadcast can reach a whole community at once, so abuse must be hard to start
and quick to stop.

### 6. Audio quality and delivery
- Capture MUST disable echo cancellation, noise suppression and AGC. Audio MUST be Opus mono at
  32-48 kbps with in-band FEC on and DTX off.
- USB audio-class input MUST be tested on each supported broadcaster device.
- The self-hosted open-source SFU SHOULD be used only where it pays for itself. The default
  delivery for the general audience MUST be LL-HLS served from self-hosted infrastructure.
- Multi-device sync MUST use RTCP/NTP timestamps and a deliberate fixed playout buffer. Specs
  MUST NOT claim sub-500 ms latency and cross-device sync together.
- Design and load tests MUST cover the five-times-daily thundering herd, with a stated target of
  concurrent listeners per prayer window and a stated cost ceiling.

Rationale: the recitation must sound true, and free software still runs on paid hardware.

### 7. Religious and cultural correctness
- Prayer-time methods (Umm al-Qura, ISNA, MWL, Karachi and others), Asr juristic method,
  high-latitude rules, Hijri calendar and moon-sighting differences MUST be configurable and
  MUST be tested against published reference tables.
- The app MUST NOT present a contested ruling as the only option, and MUST respect Sunni/Shia
  and madhhab differences in Azaan wording and times.

Rationale: the community is diverse, and a wrong or one-sided default erodes trust.

### 8. Testing and quality gates
- Prayer-time calculation, scheduling, fallback logic and token authorization MUST be
  developed test-first.
- Backend APIs MUST have contract tests. The broadcast, drop and fallback flow MUST have
  integration tests.
- A real-device matrix MUST cover Pixel, Samsung, Xiaomi, and iPhone on the current and previous
  iOS, for background and locked-screen playback, silent mode, DND, force-quit and battery saver.
  A feature touching background audio MUST NOT be marked done until it passes this matrix.
- CI MUST run lint, unit, contract and license-scan checks using free tooling (self-hosted
  runners, or GitHub Actions free tier per the Exceptions Register).
- Releases MUST have a manual device-matrix sign-off.

Rationale: background-audio behavior varies by device and cannot be proven by emulators.

### 9. Simplicity and scope control
- Delivery MUST be phased:
  - Phase 0: local Azaan, prayer times, Masjid picker, Qibla.
  - Phase 1: hardened live broadcast, piloted with 3-5 Masjids.
  - Phase 2: push-triggered wake (Android first, rich notification on iOS).
  - Later: community board and Quran hub.
- No feature MAY start before its predecessor phase meets its exit criteria.
- Payments, donations and Zakat are out of scope, because they need paid processors and a
  separate legal workstream that conflicts with principle 10. Reopening them MUST go through a
  constitutional amendment.
- Boring, proven tools SHOULD be preferred. gRPC, microservices or new infrastructure MUST NOT
  be added without a written justification. The SFU handles real-time signaling; the rest of
  the backend MUST use REST and webhooks.

Rationale: a small community team can only keep a few things reliable at once.

### 10. Open source and zero licensing cost
- Every library, framework, tool and self-hosted service MUST be open source under an
  OSI-approved license and MUST be free to use with no paid tier, seat, usage or feature gates.
  This covers the app, backend, build, CI and test tooling.
- Libraries linked into the mobile app MUST use permissive licenses (MIT, BSD, Apache-2.0, ISC,
  MPL-2.0). GPL, AGPL and LGPL code MUST NOT be linked into the app.
- Copyleft is allowed only for separately run server-side processes such as FFmpeg or Icecast.
  AGPL components MUST NOT be modified without publishing the changes.
- Source-available or restricted licenses (BUSL, SSPL, RSAL, FSL and similar) are not open
  source and MUST NOT be used.
- Paid or freemium SaaS (hosted SFU clouds, paid CDNs, paid maps, error trackers and similar)
  MUST NOT be used. An open-source equivalent MUST be self-hosted instead.
- The only exceptions are unavoidable platform dependencies recorded in the Exceptions Register
  with rationale. An open-source push alternative (UnifiedPush) SHOULD be offered on Android as
  an optional, non-default path where feasible.
- Data and content (Quran text, translations, fonts, audio, map tiles) MUST carry licenses that
  allow free redistribution, with attribution tracked in a LICENSES/NOTICE file.
- The project's own code MUST use a permissive open-source license (default: Apache-2.0).
- Every new dependency MUST enter through a PR that records its license, maintainer health and
  alternatives considered. CI MUST fail on a disallowed or unknown license.
- Specs MUST state the expected infrastructure cost, and the system MUST run on a single modest
  VPS (or a free-tier-friendly self-hosted setup) at pilot scale.

Rationale: a community can only audit and sustain what it can freely run, and hosting is the
one real cost.

### 11. Accessibility and localization
- The app MUST support RTL (Arabic, Urdu), large text and screen readers. The broadcaster's
  large "Start Azaan" control MUST be usable one-handed.
- All user-facing strings MUST be localizable from day one. Initial languages: English, Arabic,
  Urdu, Bahasa Indonesia.

Rationale: the audience is global, multilingual and spans all ages and abilities.

## Technology Constraints

All choices are subject to principle 10. Any deviation requires an amendment under Governance.

- Mobile: Flutter (BSD), with native Swift/Kotlin modules only where no OSI-licensed
  Flutter plugin meets the requirement. Allowed native areas: audio session and playback,
  foreground services, exact-alarm scheduling and boot/time receivers, the on-device alert
  journal, location and heading sensors, and Live Activities. Each native module MUST have a
  written platform-channel contract in the feature's contracts folder and MUST NOT depend on
  proprietary Google Play Services libraries. Prayer times via an open-source library such as adhan-dart
  (MIT) or an in-house implementation. Maps, if needed, via MapLibre with OpenStreetMap data and
  no Google or Mapbox SDKs.
- Real-time audio: self-hosted LiveKit (Apache-2.0, with its Flutter client SDK) or mediasoup
  (ISC). LiveKit Cloud is forbidden. LL-HLS packaging with FFmpeg and nginx, or Icecast, run as
  separate server processes.
- Backend: Node.js (TypeScript), PostgreSQL + PostGIS for the Masjid directory (5 km radius
  search), Valkey (BSD) for live broadcast state (use GEOSEARCH, not deprecated GEORADIUS; Redis
  is excluded because of its license changes), REST + webhooks.
- Push: FCM and APNs under the Exceptions Register, using per-Masjid topics.
- Observability and errors: self-hosted open-source tools only (e.g. Prometheus, Grafana,
  GlitchTip, Loki), with no PII.

## Exceptions Register

Allowed exceptions to principle 10. Each entry needs rationale; add entries only by amendment.

| Dependency | Rationale |
|------------|-----------|
| Firebase Cloud Messaging, APNs | Only supported push channels on Android and iOS; free, proprietary |
| Play Integrity, App Attest | Only platform attestation for broadcaster device binding; free quotas |
| Apple Developer Program, Google Play developer fees | Required to publish on the stores |
| GitHub (repository hosting; Actions free tier, optional; Pages for the privacy-policy page) | Source hosting, CI convenience and a free static page for the store-required privacy-policy URL; the repository can be mirrored, CI replaced by self-hosted runners and the page moved to any static host |

## Amendment Changelog

| Version | Date | Change | Rationale |
|---------|------|--------|-----------|
| 1.2.0 | 2026-10-22 | Exceptions Register: GitHub entry also covers GitHub Pages for the privacy-policy page | Both stores require a privacy-policy URL and the owner chose GitHub Pages (plan D-5) |
| 1.1.0 | 2026-10-21 | Widened the native-code clause (Technology Constraints) and the GitHub entry in the Exceptions Register | Phase 0 needs native alarm, journal, location and heading code for reliable alerts; GitHub already hosts the repository |
| 1.0.0 | 2026-10-21 | Initial ratification: 11 principles, technology constraints, exceptions register, governance | Project start |

## Governance

- The constitution supersedes specs, plans and tasks. Each spec and plan MUST include a
  "Constitution check" listing which principles apply and how they are met.
- Amendments MUST include a written rationale, a version bump and a dated changelog entry.
  Semver applies: MAJOR for removed or redefined principles, MINOR for added principles or
  materially expanded guidance, PATCH for wording.
- Violations MUST have a documented exception with an owner and an expiry date. License
  violations (principle 10) cannot be excepted except through the Exceptions Register.
- Compliance MUST be checked in every plan (Constitution check) and every code review.

**Version**: 1.2.0 | **Ratified**: 2026-10-21 | **Last Amended**: 2026-10-22
