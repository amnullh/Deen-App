/// License wording that must appear as written. It stays in English in every
/// interface language because it is the wording the licenses ask for. The
/// source of truth is `content/LICENSES.md`; keep both in step.
abstract final class Attributions {
  /// GeoNames, CC BY 4.0 (attribution, license link, indication of changes).
  static const String geoNames =
      'Contains data from GeoNames (https://www.geonames.org), licensed under '
      'CC BY 4.0. Modified: filtered and recoded.';

  static const String geoNamesLicenseUrl =
      'https://creativecommons.org/licenses/by/4.0/';

  /// Fonts bundled unmodified under the SIL Open Font License 1.1.
  static const List<String> fonts = [
    'Amiri',
    'Noto Naskh Arabic',
    'Noto Sans Arabic',
    'Noto Nastaliq Urdu',
    'Noto Sans',
  ];

  static const String fontsNotice =
      'These fonts are licensed under the SIL Open Font License, Version '
      '1.1 (https://openfontlicense.org). They are included unmodified and '
      'are not sold on their own.';

  /// Unicode License V3 notice for the Hijri month-length table, which was
  /// generated from ICU4X data (originally KACST month lengths).
  static const String unicode =
      'The Hijri calendar table was generated from ICU4X data. Copyright '
      '© Unicode, Inc. Used under the Unicode License v3 '
      '(https://www.unicode.org/license.txt).';
}
