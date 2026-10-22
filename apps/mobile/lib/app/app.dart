import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/enums.dart';
import '../l10n/generated/app_localizations.dart';
import '../ui/app_shell.dart';
import '../ui/theme/app_theme.dart';
import 'providers.dart';

/// Root widget. Language, theme, text size and contrast come from the saved
/// settings; before setup has run the app shows English.
class DeenApp extends ConsumerWidget {
  /// [home] replaces the app shell; tests use it to exercise the theme alone.
  const DeenApp({this.home, super.key});

  final Widget? home;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(prayerSettingsProvider).value;
    final language = settings?.language ?? AppLanguage.en;
    final highContrast = settings?.highContrast ?? false;

    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      locale: localeFor(language),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: buildTheme(
        brightness: Brightness.light,
        language: language,
        highContrast: highContrast,
      ),
      darkTheme: buildTheme(
        brightness: Brightness.dark,
        language: language,
        highContrast: highContrast,
      ),
      themeMode: themeModeFor(settings?.theme ?? ThemePreference.system),
      builder: (context, child) {
        final scale = settings?.textScale ?? 1.0;
        return MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: home ?? const AppShell(),
    );
  }
}
