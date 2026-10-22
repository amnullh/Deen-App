# Encoding the Azaan recordings (T100)

The app plays six Azaan recordings: two voices, each in the standard, Fajr (with the tathwib addition) and
Shia wording. They are named `voice1-standard`, `voice1-fajr`, `voice1-shia`, `voice2-standard`, `voice2-fajr`
and `voice2-shia`. This note explains how to turn the licensed master recordings into the files each
platform needs. `ffmpeg` and `afconvert` are dev-time tools run on a developer machine; they are not linked
into the app and not needed in CI.

**No recordings exist yet.** The recordings must be cleared in `content/LICENSES.md` (section 2) before they
are encoded or committed. The script and its tests were exercised only with a synthetic tone as a stand-in.

## What each platform needs

| Platform | Format | Folder | Why |
|----------|--------|--------|-----|
| Android | Ogg Vorbis (default) or Ogg Opus | `content/audio/android/` | Small files; played through a notification channel sound or by the foreground player. Android raw resource names allow only `a-z`, `0-9`, `_`, so `voice1-fajr` becomes `voice1_fajr.ogg` (see `sync_plan.dart`). |
| iOS | IMA4 in a CAF file, each shorter than 30 seconds | `content/audio/ios/` | iOS plays a custom notification sound only when it is shorter than 30 seconds (research R-I3); a longer file silently falls back to the default sound. IMA4 CAF is a format Apple lists for notification sounds. |

The iOS clips are cut from the full recordings. The default cap is **28 seconds**, a 2 second margin under the
limit. The last 0.75 seconds fade out so a cut does not end with a click. The cut point is a religious
decision as well as a technical one: the scholar reviewer approves it (register row `ios-clips`), so use
`--max-seconds` and, if needed, trim the master by hand first.

## Steps

1. Put the masters in `content/audio/master/`, named exactly as above with a supported extension (`wav`, `flac`,
   `aif`, `aiff`, `caf`, `m4a`, `mp3`, `ogg`, `opus`, `webm`). The folder is not copied into the app. Register each
   master in `content/LICENSES.md` or `content/register/`.
2. Preview the commands without running anything:

   ```
   dart run tools/sync_content/bin/encode.dart --dry-run
   ```

3. Encode and verify:

   ```
   dart run tools/sync_content/bin/encode.dart
   ```

   Options: `--platform android|ios|all`, `--android-codec vorbis|opus`, `--max-seconds N` (above 0, below 30),
   `--only voice1-fajr`, `--input`, `--android-out`, `--ios-out`.

4. Register the encoded files (derived from a master, same license), then verify everything, including the
   register and the iOS clip lengths:

   ```
   dart run tools/sync_content/bin/sync.dart --check
   ```

   `sync.dart` reads each iOS clip header with `audioDurationSeconds` (WAV, AIFF, CAF; IMA4 handled) and fails
   when a clip is 30 seconds or longer or its length cannot be read. `encode.dart` runs the same check right
   after encoding, against the stricter `--max-seconds` cap, and checks each Android file starts with an Ogg
   header. The Android duration is not read by Dart; to see it, run
   `ffprobe -v error -show_entries format=duration -of csv=p=0 content/audio/android/voice1_fajr.ogg`.

5. Copy into the app with `dart run tools/sync_content/bin/sync.dart` (Android `res/raw`, iOS `Runner/Sounds`).

## What the script runs

Android, per recording (Vorbis):

```
ffmpeg -y -i content/audio/master/voice1-fajr.wav -vn -map_metadata -1 -c:a libvorbis -q:a 4 content/audio/android/voice1_fajr.ogg
```

With `--android-codec opus` it uses `-c:a libopus -b:a 64k` in the same Ogg container.

iOS, per recording, in two steps through a temporary WAV:

```
ffmpeg -y -i content/audio/master/voice1-fajr.wav -vn -map_metadata -1 -t 28 -af afade=t=out:st=27.25:d=0.75 -c:a pcm_s16le /tmp/voice1-fajr.wav
afconvert -f caff -d ima4 /tmp/voice1-fajr.wav content/audio/ios/voice1-fajr.caf
```

A master shorter than 27.25 seconds is not changed by the fade.

## Missing tools

The script checks for the tools it needs before it runs anything and explains what to do:

- No `ffmpeg`: install it (macOS `brew install ffmpeg`, Debian or Ubuntu `apt install ffmpeg`).
- No `libvorbis` in your ffmpeg: some builds omit it (the Homebrew build tried while writing this note had
  `libopus` but not `libvorbis`). Use a build that includes it, or pass `--android-codec opus`. Do not use ffmpeg's
  native `vorbis` encoder (poor quality).
- No `afconvert`: it ships with macOS only, so iOS clips must be encoded on a Mac. On another system run with
  `--platform android` and encode the iOS clips later on a Mac.

## Not verified yet

- Opus in Ogg is documented as supported from Android 5.0; whether the notification channel sound path on every
  supported device plays it has not been tested. Vorbis is the default for that reason.
- Playback of the IMA4 CAF clips as notification sounds on a real iPhone has not been tested (no device here).
- Whether `afconvert` accepts every master format: it reads WAV, AIFF, CAF and several others, so the script
  always feeds it the temporary 16-bit WAV that ffmpeg writes.
