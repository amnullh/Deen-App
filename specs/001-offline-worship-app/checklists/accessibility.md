# Accessibility Audit: Deen App (Phase 0)

**Task**: T184 (audit and fixes), T187 (device pass, still open)
**Scope of this revision**: the first table covers the screens written by the adhkar, About and settings workstream.
The second pass (section "Automated audit of every screen") covers every screen with one shared test file,
`apps/mobile/test/ui/accessibility_guidelines_test.dart`.
**Legend**: `[x]` verified by an automated widget test named in the Evidence column; `[ ]` not verified; `[~]`
checked by reading the code only (no test), so treat as unverified until a test or the device pass covers it.
Automated tests cannot replace the TalkBack and VoiceOver pass (T187, SC-006).

## Method

Every screen below is pumped in a widget test with the semantics tree on:

- **Labels**: `meetsGuideline(labeledTapTargetGuideline)`: every tappable node has a label or tooltip.
- **Touch size**: `androidTapTargetGuideline` (48 dp) and `iOSTapTargetGuideline` (44 pt).
- **Text size**: 2.0x text scale on a 360 x 640 logical screen in all four languages; any overflow fails the test.
- **Direction**: Arabic and Urdu resolve to right to left, English and Indonesian to left to right.
- **Color alone**: checked by reading each screen for state or meaning shown only by hue. Where a test can see the
  alternative cue (icon, check mark, label), it asserts it.
- **One hand**: primary actions belong in the lower half of the screen, or the screen scrolls so every control comes
  within reach of a thumb. Recorded by inspection; there is no automated guideline for it.

## Screens audited

| Screen (class) | Labels and touch size | 2.0x text, 4 languages | RTL | Not color alone | One-handed |
|---|---|---|---|---|---|
| Adhkar collections (`AdhkarCollectionsPage`) | [x] `adhkar_ui_test` accessibility group | [x] `no overflow at 2.0x text` | [~] direction asserted on the entry page only; this page has no direction-specific code | [x] each collection shows its name beside the icon; empty state is icon plus text | [~] Bookmarks and Reminders buttons moved from the app bar to the bottom (finding F1); by inspection |
| Adhkar entry (`AdhkarEntryPage`) | [x] count, undo, bookmark, previous, next all have tooltips or labels (`the counting button and progress are read aloud`) | [x] | [x] Arabic and Urdu right to left, Arabic text always right to left | [x] a finished entry shows a check icon and the word "Done"; the bookmark changes icon shape and tooltip; progress is a number as well as a bar | [~] counting, undo, bookmark and previous/next are in a bottom bar (by inspection) |
| Adhkar bookmarks (`AdhkarBookmarksPage`) | [~] list tiles; not in the guideline loop | [x] | [~] | [x] each row has an icon and text | [~] list scrolls; back is the system gesture |
| Adhkar reminders (`AdhkarReminderSettingsPage`) | [x] earlier and later buttons have tooltips; switches have text | [x] | [~] | [x] selected anchor shows a check mark in the segmented button; timing is written out ("25 min after Fajr") | [~] controls are in the card in the page flow; reachable by scrolling |
| Content credits (`ContentCreditsPage`) | [~] read-only text | [x] | [~] | [x] text only | n/a (no controls) |
| About (`AboutPage`) | [x] `about_page_test` last test | [x] | [x] interface text follows the language; license wording is forced left to right on purpose | [x] text only | [~] entries are list tiles in a scrolling list |
| Appearance (`AppearancePage`) | [x] `appearance_page_test` last test (smaller and larger buttons have tooltips); the slider's spoken percentage is set in code but not asserted ([~]) | [x] | [x] | [x] selected theme shows a check mark; high contrast is a switch with a label; the text-size value is shown as a number | [ ] see finding F2 |
| Data (`DataPage`) | [x] `data_page_test` last test | [x] | [x] | [x] warning has an icon and a border; every result message has an icon and words; the delete button has an icon and a label as well as its red fill | [~] delete confirmation buttons are at the bottom of a dialog; export and import buttons scroll into reach (by inspection) |

## Findings

- **F1 (fixed)**: the adhkar collections screen had Bookmarks and Reminders as app-bar icons in the top corner, hard to
  reach with one hand. They are now two full-width buttons at the bottom of the screen.
- **F2 (open, accepted risk until the device pass)**: on the Appearance screen the theme choice sits near the top of
  the screen, above the thumb zone on tall phones. The screen is short and scrolls, and the system back gesture is
  available, so nothing is unreachable, but a one-handed user must stretch for the theme switch. To be judged on a
  device in T187; if it proves a problem, move the theme choice below the text-size control.
- **F3 (note)**: the delete-all button uses the error color as well as a trash icon and the words "Delete all my data";
  the color is decoration, not the signal.
- **F4 (note)**: license wording (GeoNames, SIL OFL, Unicode) is English in every interface language because the
  licenses require that wording. It is marked left to right so it reads correctly inside a right-to-left screen.
- **F5 (note)**: the Arabic adhkar text uses the Amiri font and is always laid out right to left with an Arabic
  locale, so a screen reader selects an Arabic voice. Whether the voice reads diacritics acceptably is a device check.

## Screens not audited in the first table

Superseded: home, detail, prayer settings, language and location settings, alert settings, alert options, voice
picker, Reliability check, setup (all seven steps), Qibla and tasbih are covered in the next section, together with
the screens above. Any screen added later needs a row in `_screens` in the test file.

## Automated audit of every screen (T184, second pass)

**Test file**: `apps/mobile/test/ui/accessibility_guidelines_test.dart` (225 tests, all passing). Each screen is
shown inside the real `DeenApp`, so language, text size, theme and high contrast come from saved settings as in
production. Platform parts are fakes. Phone: 360 x 740 logical pixels, semantics on, bounded pumps.

| Check | How | Matrix |
|---|---|---|
| Touch size | `androidTapTargetGuideline` (48 dp) and `iOSTapTargetGuideline` (44 pt) | every screen and every setup step, English and Arabic, text 1.0x and 2.0x |
| Labels | `labeledTapTargetGuideline` | same matrix |
| No overflow | any layout exception during the pump fails the test | same matrix |
| Contrast | `textContrastGuideline` on rendered pixels | every screen and setup step in light, dark, high contrast light and high contrast dark (English, 1.0x); home in Arabic; a gallery of every banner and status line in the four themes |
| Dialogs and menu | the same tap and label guidelines after opening: delete-all dialog, tasbih custom target dialog, tasbih reset dialog, the home "more" menu | English and Arabic, 1.0x and 2.0x |
| One hand | the rule below | primary action of 12 screens plus setup Next at each step, English and Arabic, 1.0x and 2.0x |
| Not color alone | states compared in words, icon and spoken label (list below) | English, plus Arabic where the strings differ per language |
| Control | a 20 dp target, an unlabeled button and pale grey text must FAIL the guidelines | proves the checks are live |

Screens in the matrix: home (with both permission banners), detail, prayer settings, language settings, location
settings, alert settings, alert options, voice picker, Reliability check (with all three problems), Qibla (compass
running, low accuracy), tasbih, adhkar collections, appearance, data, about, and setup steps language, location
(nothing chosen and chosen), method and Asr, notifications (not asked and answered), exact alarm, battery guide,
privacy.

### One-handed rule applied

On a 360 x 740 screen the top third (y below 247) is out of easy thumb reach. A screen's primary action passes when
either (a) at least 48 dp of its height lies in the lower two thirds and inside the screen at rest ("direct"), or
(b) it sits inside a scrollable and scrolling brings it fully into view ("scrolls"). The app bar never counts as
reachable: a primary action that is only in the app bar fails. Setup Next is held to the stricter (a) at every step.

| Screen | Primary action (key) | Result at 1.0x, English | Notes |
|---|---|---|---|
| Setup, all steps | `setup-next` | direct | pinned in a bottom row at both text sizes and in Arabic |
| Home | `open-detail` | scrolls | the list is longer than the screen; see finding F6 for the app-bar buttons |
| Prayer settings | method radio | direct | |
| Language settings | language radio | scrolls | list at the top of a short scrolling page |
| Location settings | `location-precise` | direct | |
| Alert settings | prayer type radio | direct | |
| Alert options | `quiet-switch` | scrolls | |
| Voice picker | preview button | direct | |
| Reliability check | `send-test-azaan` | scrolls | at the very end of a long page; see finding F7 |
| Qibla | none | n/a | read-only compass; the test asserts it has no button hidden anywhere |
| Tasbih | `tasbih-counter` | direct | a 320 dp square; its lower half is in reach at both text sizes |
| Adhkar collections | first collection | scrolls | Bookmarks and Reminders are pinned at the bottom (F1) |
| Appearance | `appearance-theme` | scrolls | F2 still stands |
| Data | `data-export-share` | direct | |
| About | `about-privacy-policy` | direct | scrolls at 2.0x |
| Detail | none | n/a | read-only |

At 2.0x text every primary action is direct or scrolls; none is lost off the screen.

### No meaning by color alone

Each of these is asserted by a test; "differs" means the visible words differ between states and the screen
reader label contains those words.

- Permission banners (alerts, exact timing, automatic location): each has its own sentence and an icon; on the home
  screen they appear only when the permission is denied.
- `InfoBanner` information and warning: both have an icon and the message in the spoken label.
- Qibla accuracy (high, medium, low, unreliable): four different sentences and four different icons.
- Reliability check: "everything looks good" versus "needs attention" differ in words and icon; every permission row
  says "On" or "Off" and uses a different icon; upcoming alerts are read as one sentence.
- Missed alert banner: warning icon, title and the likely cause in words.
- Setup status lines: granted versus refused differ in words and icon, English and Arabic.
- Alert type choice: a radio group; each option has its own label and the chosen one is announced as checked.
- Home: the next prayer row has the word "Next" (and it is in the spoken label); the highlight is extra.
- Appearance: the selected theme shows a check mark.

### What the guidelines cannot see

- Targets that touch the screen edge are skipped by Flutter's tap-size guideline (they may be partly scrolled away).
  Full-width list tiles are therefore not measured; their heights come from Material defaults (at least 48 dp).
- Contrast is measured on the test renderer. Fonts are not the shipped fonts there, so glyph shapes differ; ratios
  depend on colors and are valid, but anti-aliasing on a phone can move a borderline ratio by a few hundredths.
  Disabled controls are exempt from the guideline.
- Reading order, focus order, announcement wording, grouping and Arabic or Urdu pronunciation need a screen reader.
  Urdu and Indonesian were not in the matrix (English and Arabic stand for left to right and right to left).
- Thumb reach is geometry on one phone size, not a real hand. Larger phones and tablets are not covered.

### Findings from this pass

No tap-size, label, contrast or color-only defect was found in `lib/ui/**` once transient animation states were
excluded (the first runs flagged Next at 3.1:1 and 4.3 to 4.5:1 only while the button was still fading from disabled
to enabled; the test now waits one second before sampling). No source file was changed.

- **F6 (open)**: home puts Prayer settings, Reliability check and the menu in the app bar, and the previous and next
  day buttons sit in the top part of the list. All are out of one-handed reach on a tall phone. Nothing is
  unreachable (they are labeled and 48 dp), and the Reliability check is one tap as FR-004 asks. The fix is a
  navigation decision (a bottom bar or a bottom sheet menu), so it belongs to the lead and `app_shell.dart`.
- **F7 (open)**: the Reliability check's "Send a test azaan" button is at the end of a page that is about two screens
  long on a 360 x 740 phone. It passes the "scrolls" rule. If the device pass shows people miss it, pin it to the
  bottom of the screen.
- **F2 (unchanged)**: Appearance theme choice is still near the top; the test records it as "scrolls".

## Still open

- **T187 [DEVICE]**: TalkBack (Android) and VoiceOver (iOS) pass on every screen, recorded here. Not done; nothing in
  this file replaces it.
- High-contrast ratios are now measured on the test renderer for every screen (see above) but not on a real phone;
  a check on real screenshots stays part of the device pass.
