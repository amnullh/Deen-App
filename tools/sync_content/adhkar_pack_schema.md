# Adhkar pack schema (version 1)

`dart run tools/sync_content/bin/adhkar_pack.dart` turns the source files in `content/adhkar/source/*.json` into
the pack files in `content/adhkar/pack/*.json`. `tools/sync_content/bin/sync.dart` copies the pack to
`apps/mobile/assets/adhkar/`, where `AdhkarContentLoader` reads it.

**This repository holds no adhkar text.** Content licensing is unresolved (plan D-4; register rows `adhkar-*` are
BLOCKED). The builder and its tests use invented placeholder data only. Until real, licensed text exists the source
folder is empty and the build prints that there is nothing to do.

The build is strict on purpose: it lists every problem and writes **nothing** when there is one. Unknown field names
are errors too, so a misspelled `reviewer` cannot silently drop a rule.

## Source file (one per collection)

```json
{
  "schemaVersion": 1,
  "collection": {
    "id": "morning",
    "kind": "morning",
    "titles": { "en": "...", "ar": "...", "ur": "...", "id": "..." },
    "sourceId": "src-1"
  },
  "sources": {
    "src-1": { "title": "Name of the book or collection", "url": "https://..." }
  },
  "licenses": {
    "lic-1": { "name": "License name", "status": "cleared", "attribution": "Credit text" }
  },
  "entries": [ { "...": "see below" } ]
}
```

- `collection.id`: 1 to 64 characters of `a-z`, `0-9`, `_`, `-`; becomes the pack file name (`morning.json`). Two source
  files may not define the same id.
- `collection.kind`: one of `morning`, `evening`, `afterPrayer`, `beforeSleep`, `waking`, `other`
  (the app's `AdhkarCollectionKind`).
- `collection.titles`: optional, languages `en`, `ar`, `ur`, `id`. Project-written text; the UI has its own names
  when titles are absent.
- `collection.sourceId`: optional; when given it must exist in `sources`.
- `sources`: records keyed by source id; each needs a `title`. `url` is optional.
- `licenses`: records keyed by license id; each needs `name` and `status`. Only status `cleared` lets text into the
  pack. Anything else (`pending`, `blocked`, ...) makes every entry or translation that uses it fail the build.
  The ids should match rows in `content/LICENSES.md` or `content/register/`.

## Entry

| Field | Required | Rule |
|-------|----------|------|
| `id` | yes | `a-z`, `0-9`, `_`, `-`, unique across all source files |
| `order` | yes | integer from 1, unique inside the collection; entries are sorted by it |
| `arabic` | yes | non-blank, contains Arabic letters |
| `transliteration` | no | non-blank text when present; covered by the entry license |
| `translations` | no | object keyed `en`, `ur`, `id` (see below) |
| `repeatCount` | yes | integer from 1 |
| `reference` | yes | non-blank, for example a hadith reference |
| `sourceId` | yes | listed in `sources` |
| `licenseId` | yes | listed in `licenses` with status `cleared` |
| `reviewer` | yes | name of the reviewer; placeholders such as `TODO`, `TBD`, `unknown`, `n/a` are rejected |
| `reviewedOn` | yes | a real calendar date, `yyyy-MM-dd` |

### Translations

Each translation is its own licensed record. A language appears in the pack **only** when its record has text and a
cleared license; a record without one fails the build instead of being dropped quietly, so nobody ships an
unlicensed translation by omission and nobody loses one by accident.

```json
"translations": {
  "en": { "text": "...", "licenseId": "lic-1", "sourceId": "src-2" },
  "ur": { "text": "...", "licenseId": "lic-3" }
}
```

`sourceId` is optional here and must exist in `sources` when given. No other fields are allowed.

## Pack file (output)

One file per collection, `content/adhkar/pack/<collection id>.json`, two-space indented, UTF-8, ending with a newline,
byte-for-byte reproducible:

```json
{
  "schemaVersion": 1,
  "collections": [
    {
      "id": "morning",
      "kind": "morning",
      "titles": { "en": "..." },
      "sourceId": "src-1",
      "entries": [
        {
          "id": "...",
          "order": 1,
          "arabic": "...",
          "transliteration": "...",
          "translations": { "en": "...", "ur": "..." },
          "translationLicenseIds": { "en": "lic-1", "ur": "lic-3" },
          "repeatCount": 3,
          "reference": "...",
          "sourceId": "src-1",
          "licenseId": "lic-1",
          "reviewer": "...",
          "reviewedOn": "2026-10-21"
        }
      ]
    }
  ]
}
```

This is the shape `apps/mobile/lib/data/adhkar/adhkar_content_loader.dart` reads (`collections` list; `translations`
as plain strings per language). `titles`, `sourceId`, `transliteration`, `translations` and `translationLicenseIds`
are left out when empty. `translationLicenseIds` carries the license of each shown translation for the About screen;
the current loader ignores it.

## Commands

```
dart run tools/sync_content/bin/adhkar_pack.dart            # validate and write content/adhkar/pack/*.json
dart run tools/sync_content/bin/adhkar_pack.dart --check    # validate and fail when the pack is out of date (CI)
```

Every file under `content/` must also have a register entry (`bin/sync.dart --check` fails otherwise).
