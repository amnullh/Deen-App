import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/settings.dart';
import '../../l10n/generated/app_localizations.dart';

/// Theme, text size and high contrast. Changes are saved at once through the
/// settings repository and the whole app follows (spec Story 7, scenario 1).
class AppearancePage extends ConsumerStatefulWidget {
  const AppearancePage({super.key});

  /// Text size limits and step, as fractions of the normal size.
  static const double minScale = 0.8;
  static const double maxScale = 2.0;
  static const double scaleStep = 0.1;

  @override
  ConsumerState<AppearancePage> createState() => _AppearancePageState();
}

class _AppearancePageState extends ConsumerState<AppearancePage> {
  /// Text size while the slider is being dragged; null otherwise.
  double? _dragScale;

  Future<void> _save(PrayerSettings changed) async {
    final result = await ref.read(settingsRepositoryProvider).save(changed);
    if (!result.isOk && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).settingsSaveError)),
      );
    }
  }

  static double _snap(double value) {
    final steps = (value / AppearancePage.scaleStep).round();
    return (steps * AppearancePage.scaleStep).clamp(
      AppearancePage.minScale,
      AppearancePage.maxScale,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(prayerSettingsProvider).value;

    return Scaffold(
      key: const Key('appearance-page'),
      appBar: AppBar(title: Text(l10n.settingsAppearanceTitle)),
      body: SafeArea(
        child: settings == null
            ? Padding(
                padding: const EdgeInsetsDirectional.all(24),
                child: Text(
                  l10n.settingsAppearanceNeedsSetup,
                  key: const Key('appearance-needs-setup'),
                ),
              )
            : ListView(
                padding: const EdgeInsetsDirectional.all(16),
                children: [
                  _themeSection(l10n, settings),
                  const SizedBox(height: 24),
                  _textSizeSection(context, l10n, settings),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    key: const Key('appearance-high-contrast'),
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.settingsHighContrast),
                    subtitle: Text(l10n.settingsHighContrastHint),
                    value: settings.highContrast,
                    onChanged: (value) =>
                        _save(settings.copyWith(highContrast: value)),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _themeSection(AppLocalizations l10n, PrayerSettings settings) {
    final labels = {
      ThemePreference.system: (l10n.settingsThemeSystem, Icons.brightness_auto),
      ThemePreference.light: (l10n.settingsThemeLight, Icons.light_mode),
      ThemePreference.dark: (l10n.settingsThemeDark, Icons.dark_mode),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            l10n.settingsThemeLabel,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 8),
        // The selected segment shows a check mark as well as a fill, so the
        // choice never depends on color alone.
        SegmentedButton<ThemePreference>(
          key: const Key('appearance-theme'),
          showSelectedIcon: true,
          segments: [
            for (final entry in labels.entries)
              ButtonSegment(
                value: entry.key,
                label: Text(entry.value.$1),
                icon: Icon(entry.value.$2),
              ),
          ],
          selected: {settings.theme},
          onSelectionChanged: (selection) =>
              _save(settings.copyWith(theme: selection.single)),
        ),
      ],
    );
  }

  Widget _textSizeSection(
    BuildContext context,
    AppLocalizations l10n,
    PrayerSettings settings,
  ) {
    final theme = Theme.of(context);
    final scale = _dragScale ?? settings.textScale;
    final percent = (scale * 100).round();
    final divisions =
        ((AppearancePage.maxScale - AppearancePage.minScale) /
                AppearancePage.scaleStep)
            .round();

    void step(double delta) =>
        _save(settings.copyWith(textScale: _snap(scale + delta)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            l10n.settingsTextSizeLabel,
            style: theme.textTheme.titleMedium,
          ),
        ),
        Row(
          children: [
            IconButton(
              key: const Key('appearance-text-smaller'),
              tooltip: l10n.settingsTextSizeSmaller,
              icon: const Icon(Icons.text_decrease),
              onPressed: scale <= AppearancePage.minScale
                  ? null
                  : () => step(-AppearancePage.scaleStep),
            ),
            Expanded(
              child: Slider(
                key: const Key('appearance-text-size'),
                min: AppearancePage.minScale,
                max: AppearancePage.maxScale,
                divisions: divisions,
                value: scale.clamp(
                  AppearancePage.minScale,
                  AppearancePage.maxScale,
                ),
                label: l10n.settingsTextSizeValue(percent),
                semanticFormatterCallback: (v) =>
                    l10n.settingsTextSizeValue((v * 100).round()),
                onChanged: (v) => setState(() => _dragScale = _snap(v)),
                onChangeEnd: (v) async {
                  await _save(settings.copyWith(textScale: _snap(v)));
                  if (mounted) setState(() => _dragScale = null);
                },
              ),
            ),
            IconButton(
              key: const Key('appearance-text-larger'),
              tooltip: l10n.settingsTextSizeLarger,
              icon: const Icon(Icons.text_increase),
              onPressed: scale >= AppearancePage.maxScale
                  ? null
                  : () => step(AppearancePage.scaleStep),
            ),
          ],
        ),
        Center(
          child: Text(
            l10n.settingsTextSizeValue(percent),
            key: const Key('appearance-text-size-value'),
            style: theme.textTheme.titleSmall,
          ),
        ),
        const SizedBox(height: 8),
        Text(l10n.settingsTextSizeSample, key: const Key('appearance-sample')),
      ],
    );
  }
}
