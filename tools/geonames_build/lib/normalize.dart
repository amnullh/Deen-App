/// Search-text normalisation for city names.
///
/// The offline city search compares a normalised query with normalised names,
/// so typing "zurich", "Zürich", "مكه" or "مَكَّة" finds the right city. The
/// same rules exist in `apps/mobile/lib/data/cities/name_normalizer.dart`
/// (the app cannot depend on this tool); a test in the app compares the two
/// on the same inputs, and the database records [normalizationVersion] so a
/// mismatch is detectable.
library;

/// Bump when the rules below change; stored in the database metadata.
const int normalizationVersion = 1;

/// Lower-case, accent-free, script-folded form of [input] used for matching.
String normalizeSearchText(String input) {
  final buffer = StringBuffer();
  var lastWasSpace = true;
  for (final rune in input.toLowerCase().runes) {
    final mapped = _foldRune(rune);
    if (mapped == null) continue;
    if (mapped == ' ') {
      if (lastWasSpace) continue;
      lastWasSpace = true;
    } else {
      lastWasSpace = false;
    }
    buffer.write(mapped);
  }
  final text = buffer.toString();
  return text.endsWith(' ') ? text.substring(0, text.length - 1) : text;
}

/// An exclusive upper bound for a range scan over every string starting with
/// [prefix]: `name >= prefix AND name < prefixUpperBound(prefix)`.
String prefixUpperBound(String prefix) => '$prefix\u{10FFFF}';

/// Folds one code point; null drops it, otherwise the replacement text.
String? _foldRune(int rune) {
  // Combining marks (accents written as separate code points).
  if (rune >= 0x0300 && rune <= 0x036F) return null;
  // Arabic: harakat, superscript alef, Quranic annotation marks, tatweel.
  if (rune >= 0x064B && rune <= 0x065F) return null;
  if (rune == 0x0670 || rune == 0x0640) return null;
  if (rune >= 0x06D6 && rune <= 0x06ED) return null;
  // Invisible direction and joiner marks.
  if (rune == 0x200C ||
      rune == 0x200D ||
      rune == 0x200E ||
      rune == 0x200F ||
      rune == 0x061C ||
      rune == 0xFEFF) {
    return null;
  }
  // Apostrophes and modifier letters (Ta'if, 'Ayn) are dropped.
  if (rune == 0x27 ||
      rune == 0x2018 ||
      rune == 0x2019 ||
      rune == 0x02BB ||
      rune == 0x02BC ||
      rune == 0x02BE ||
      rune == 0x02BF ||
      rune == 0x60) {
    return null;
  }
  // Separators.
  if (rune == 0x2D ||
      rune == 0x2010 ||
      rune == 0x2011 ||
      rune == 0x2013 ||
      rune == 0x2014 ||
      rune == 0x5F ||
      rune == 0x2E ||
      rune == 0x2C ||
      rune == 0x09 ||
      rune == 0x0A ||
      rune == 0xA0) {
    return ' ';
  }
  final arabic = _arabicFold[rune];
  if (arabic != null) return arabic;
  // Arabic-Indic and Extended Arabic-Indic digits.
  if (rune >= 0x0660 && rune <= 0x0669) {
    return String.fromCharCode(0x30 + rune - 0x0660);
  }
  if (rune >= 0x06F0 && rune <= 0x06F9) {
    return String.fromCharCode(0x30 + rune - 0x06F0);
  }
  if (rune < 0x80) return String.fromCharCode(rune);
  return _latinFold[rune] ?? String.fromCharCode(rune);
}

/// Arabic and Urdu letter variants folded to one letter each.
final Map<int, String> _arabicFold = {
  // Alef with madda, hamza above or below, wasla -> bare alef.
  0x0622: 'ا',
  0x0623: 'ا',
  0x0625: 'ا',
  0x0671: 'ا',
  // Alef maksura, Farsi yeh, yeh barree, yeh with hamza -> yeh.
  0x0649: 'ي',
  0x06CC: 'ي',
  0x06D2: 'ي',
  0x06D3: 'ي',
  0x0626: 'ي',
  // Farsi and Sindhi kaf -> kaf.
  0x06A9: 'ك',
  0x06AA: 'ك',
  // Teh marbuta, heh goal, heh doachashmee, ae -> heh.
  0x0629: 'ه',
  0x06C1: 'ه',
  0x06BE: 'ه',
  0x06D5: 'ه',
  // Waw with hamza -> waw.
  0x0624: 'و',
  // Noon ghunna -> noon.
  0x06BA: 'ن',
};

/// Latin letters with marks mapped to plain ASCII, built from a compact list.
final Map<int, String> _latinFold = _buildLatinFold();

Map<int, String> _buildLatinFold() {
  const groups = <String, String>{
    'a': 'àáâãäåāăąǎǟǡǻȁȃȧạảấầẩẫậắằẳẵặ',
    'c': 'çćĉċč',
    'd': 'ďđḍ',
    'e': 'èéêëēĕėęěȅȇȩẹẻẽếềểễệ',
    'g': 'ĝğġģǧ',
    'h': 'ĥħḥ',
    'i': 'ìíîïĩīĭįıǐȉȋịỉ',
    'j': 'ĵ',
    'k': 'ķ',
    'l': 'ĺļľŀłḷ',
    'n': 'ñńņňŉŋṇ',
    'o': 'òóôõöøōŏőǒǫȍȏọỏốồổỗộớờởỡợ',
    'r': 'ŕŗřṛ',
    's': 'śŝşšșṣ',
    't': 'ţťŧțṭ',
    'u': 'ùúûüũūŭůűųǔȕȗụủứừửữự',
    'w': 'ŵ',
    'y': 'ýÿŷỳỵỷỹ',
    'z': 'źżžẓ',
  };
  const multi = <int, String>{
    0x00DF: 'ss', // ß
    0x00E6: 'ae', // æ
    0x0153: 'oe', // œ
    0x00F0: 'd', // ð
    0x00FE: 'th', // þ
    0x0133: 'ij', // ĳ
  };
  final map = <int, String>{...multi};
  groups.forEach((base, accented) {
    for (final rune in accented.runes) {
      map[rune] = base;
    }
  });
  return map;
}
