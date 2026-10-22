import 'package:flutter/material.dart';

import '../../domain/entities/enums.dart';

/// Font family for interface text in each language. Arabic and Urdu use fonts
/// designed for their scripts; English and Bahasa Indonesia use Noto Sans.
String uiFontFamily(AppLanguage language) {
  switch (language) {
    case AppLanguage.ar:
      return 'NotoNaskhArabic';
    case AppLanguage.ur:
      return 'NotoNastaliqUrdu';
    case AppLanguage.en:
    case AppLanguage.id:
      return 'NotoSans';
  }
}

/// Font family for Quran and adhkar text in Arabic.
const String arabicTextFontFamily = 'Amiri';

/// Locale for an [AppLanguage].
Locale localeFor(AppLanguage language) => Locale(language.name);

/// Builds the Material theme.
///
/// [highContrast] raises contrast by using pure black or white text on the
/// background and heavier outlines; no information is conveyed by color alone
/// anywhere in the app, so the theme only changes appearance.
ThemeData buildTheme({
  required Brightness brightness,
  required AppLanguage language,
  bool highContrast = false,
}) {
  final base = ColorScheme.fromSeed(
    seedColor: const Color(0xFF1B6B5A),
    brightness: brightness,
  );
  final scheme = highContrast
      ? base.copyWith(
          onSurface: brightness == Brightness.dark
              ? Colors.white
              : Colors.black,
          surface: brightness == Brightness.dark ? Colors.black : Colors.white,
          outline: brightness == Brightness.dark ? Colors.white : Colors.black,
        )
      : base;

  final family = uiFontFamily(language);
  final text =
      (brightness == Brightness.dark
              ? ThemeData.dark().textTheme
              : ThemeData.light().textTheme)
          .apply(fontFamily: family);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: family,
    textTheme: text,
    scaffoldBackgroundColor: scheme.surface,
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
    ),
  );
}

/// Maps the stored theme preference to a [ThemeMode].
ThemeMode themeModeFor(ThemePreference preference) {
  switch (preference) {
    case ThemePreference.system:
      return ThemeMode.system;
    case ThemePreference.light:
      return ThemeMode.light;
    case ThemePreference.dark:
      return ThemeMode.dark;
  }
}
