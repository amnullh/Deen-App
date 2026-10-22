# Register rows: setup and home workstream (W3)

Same table format as `content/LICENSES.md` section 3 (Text content). Fold these rows into the main file when the
workstreams are merged.

## 3. Text content

| Id | Description | Source | License | Reviewer | Status |
|----|-------------|--------|---------|----------|--------|
| oem-guides | Battery "how to fix" steps per phone brand in English, Arabic, Urdu and Bahasa Indonesia: `apps/mobile/assets/oem_guides/*` (`xiaomi.json`, `oppo.json`, `vivo.json`, `huawei.json`, `samsung.json`, `oneplus.json`, `other.json`) | written by the project from the generic Android battery-settings paths; no text copied from any vendor or third-party guide | project license (Apache-2.0) | TODO: native speaker for ar, ur and id; steps not yet verified on the owned devices (task T060 stays open, record in `apps/mobile/assets/oem_guides/verified.md`) | written; unverified on devices |
| ui-setup-home | Setup, home, detail and prayer-settings strings in `apps/mobile/lib/l10n/fragments/setup.json` and `home.json` (including the 14 method names, Asr and high-latitude explanations) | written by the project | project license (Apache-2.0) | TODO: native speaker per language (tasks T059, T089); scholar sign-off on the method names and the high-latitude explanation text (T089) | written; review open |
