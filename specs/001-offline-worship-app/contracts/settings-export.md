# Contract: Settings Export and Import File

**File**: `deen-settings-<yyyymmdd>.json`, UTF-8, written by the user through the system share or save sheet and
read back through the system file picker. The app never transmits it.

## Schema (version 1)

```json
{
  "format": "deen-app-settings",
  "version": 1,
  "exportedAt": "2026-10-21T08:00:00Z",
  "appVersion": "0.1.0",
  "language": "en",
  "appearance": { "theme": "system", "textScale": 1.0, "highContrast": false },
  "location": { "source": "city", "latitude": 21.4225, "longitude": 39.8262, "cityId": 104515,
                "displayName": "Mecca", "timeZoneId": "Asia/Riyadh", "countryCode": "SA" },
  "prayer": { "method": "ummAlQura", "asr": "standard", "highLatitudeRule": "middleOfNight",
              "offsetsMinutes": { "fajr": 0, "sunrise": 0, "dhuhr": 0, "asr": 0, "maghrib": 0, "isha": 0 },
              "imsakMinutes": 10, "hijriAdjustment": 0 },
  "alerts": {
    "perPrayer": { "fajr": { "type": "shortTone", "voiceId": "voice-1", "variant": "standard",
                             "loudMode": false, "volumeChoice": "keepCurrent",
                             "preReminderMinutes": null, "ignoreQuietHours": false } },
    "audioOutput": "speaker",
    "quietHours": { "start": "22:00", "end": "05:00" },
    "suhoorReminder": { "enabled": false, "minutes": 30 }
  },
  "tasbih": { "target": 33, "keepAwake": false, "volumeKeys": false, "lock": false,
              "haptics": true, "sound": false },
  "adhkar": { "bookmarks": ["entry-id"], "reminders": [] }
}
```

## Rules

- `format` and `version` are required. An unknown `format` or a `version` newer than the app's is rejected with a
  plain message and nothing is applied.
- Import is all-or-nothing: validate every field range from [data-model.md](../data-model.md) first, then apply in
  one transaction, then rebuild the schedule.
- Unknown keys are ignored (forward compatibility). Missing optional keys keep current values.
- Excluded: alert log, tasbih daily history, permission states, device identifiers. The file contains location,
  so the export screen warns the user in plain words before sharing.
- Android-only fields (`loudMode`, `volumeChoice`, `volumeKeys`) are ignored on iOS and kept in the file.
- A language or time zone different from the importing device is allowed; planning always uses the file's
  location time zone.
- `delete all my data` does not delete files the user saved outside the app; the confirmation says so.

## Versioning

Increase `version` only for incompatible changes and keep an importer for every released version. The PATCH-level
addition of an optional key does not change `version`.
