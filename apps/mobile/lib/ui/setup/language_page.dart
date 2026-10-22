import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/setup_providers.dart';
import '../../domain/entities/enums.dart';
import '../../l10n/generated/app_localizations.dart';
import '../common/prayer_labels.dart';
import 'setup_widgets.dart';

/// The four languages as a single choice. Each is written in its own language so
/// a reader can find theirs whatever the app currently shows. Shared by setup and
/// the language settings page.
class LanguagePicker extends StatelessWidget {
  const LanguagePicker({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final AppLanguage selected;
  final ValueChanged<AppLanguage> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return RadioGroup<AppLanguage>(
      groupValue: selected,
      onChanged: (value) {
        if (value != null) onSelected(value);
      },
      child: Column(
        children: [
          for (final language in AppLanguage.values)
            RadioListTile<AppLanguage>(
              key: Key('language-${language.name}'),
              value: language,
              title: Text(l10n.languageName(language)),
            ),
        ],
      ),
    );
  }
}

/// Setup step 1: choose the language. The whole app switches at once.
class LanguageStep extends ConsumerWidget {
  const LanguageStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(setupControllerProvider);
    return SetupStepLayout(
      title: l10n.setupLanguageTitle,
      children: [
        Text(l10n.setupLanguageBody),
        const SizedBox(height: 8),
        LanguagePicker(
          selected: state.language,
          onSelected: (language) => ref
              .read(setupControllerProvider.notifier)
              .chooseLanguage(language),
        ),
        if (state.problem != null)
          StatusLine(
            ok: false,
            message: setupProblemMessage(l10n, state.problem!),
          ),
      ],
    );
  }
}
