# Register rows: prayer engine workstream (W1)

Same table format as `content/LICENSES.md` section 4 (Datasets). Fold these rows into the main file when the
workstreams are merged.

## 4. Datasets

| Id | Description | Source | License | Attribution | Status |
|----|-------------|--------|---------|-------------|--------|
| ummalqura-table | Hijri month lengths 1300-1600 AH (301 years: month lengths and the Gregorian start day of each year), generated into `packages/prayer_engine/lib/src/hijri/umm_al_qura_table.dart` by `tools/hijri_table_gen/bin/gen.dart` | ICU4X `components/calendar/src/cal/hijri/ummalqura_data.rs` at commit `0455cbc76805bcace221573f242e2a7a82d10322` (https://github.com/unicode-org/icu4x), which took it from ICU4C `islamcal.cpp`, which took it from the KACST Umm al-Qura calendar | Unicode License V3 (SPDX: Unicode-3.0), data file header and repository LICENSE read (V) | The full Unicode License V3 notice is reproduced in the header of the generated file and must stay there; the generator re-emits it. Spot-checked against published dates (spike S5, see `specs/001-offline-worship-app/spike-results-engine.md`) | generated; validated for internal consistency and four published dates; official KACST table not reachable from the build environment |
| horizons-samples | About 30 instants (sunrise, sunset, twilight, Asr) used as test expectations in `packages/prayer_engine/test/asr_shadow_test.dart`, `horizons_events_test.dart` and `tools/fixtures_gen/test/oracle_test.dart` | Derived by us from NASA/JPL Horizons System (DE441) ephemeris queries made 2026-10-21 (https://ssd.jpl.nasa.gov/horizons/); only the derived instants are stored, no ephemeris tables | NASA/JPL data (public information); exact terms page not re-read (U) | credit "NASA/JPL Horizons System" in the test comments | test data only, never bundled in the app; confirm terms before any redistribution |
| qibla-reference | 12 sanity bearings in `packages/prayer_engine/test/qibla_test.dart` | computed by an independent vector implementation in the test; adhan-js published values (Washington 56.56, New York 58.4817, London 118.987, Islamabad 255.882, Tokyo 293.021) used as a sanity check only | n/a (facts) | n/a | test data only |
