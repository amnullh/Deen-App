import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/providers/setup_providers.dart';
import '../../domain/entities/enums.dart';
import '../../l10n/generated/app_localizations.dart';
import '../setup/language_page.dart';

/// Change the language after setup. The app switches at once and the schedule
/// is rebuilt, because alert texts are written in the chosen language.
class LanguageSettingsPage extends ConsumerWidget {
  const LanguageSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final current =
        ref.watch(prayerSettingsProvider).value?.language ?? AppLanguage.en;
    return Scaffold(
      key: const Key('language-settings-page'),
      appBar: AppBar(title: Text(l10n.languageSettingsTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsetsDirectional.all(16),
          children: [
            LanguagePicker(
              selected: current,
              onSelected: (language) =>
                  ref.read(profileServiceProvider).saveLanguage(language),
            ),
          ],
        ),
      ),
    );
  }
}
