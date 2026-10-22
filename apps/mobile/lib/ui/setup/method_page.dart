import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prayer_engine/prayer_engine.dart';

import '../../app/providers/setup_providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../common/prayer_labels.dart';
import 'setup_widgets.dart';

/// All calculation methods as a single choice. Shared by setup and the prayer
/// settings page.
class MethodPicker extends StatelessWidget {
  const MethodPicker({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final CalculationMethod? selected;
  final ValueChanged<CalculationMethod> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return RadioGroup<CalculationMethod>(
      groupValue: selected,
      onChanged: (value) {
        if (value != null) onSelected(value);
      },
      child: Column(
        children: [
          for (final method in CalculationMethod.values)
            RadioListTile<CalculationMethod>(
              key: Key('method-${method.name}'),
              value: method,
              title: Text(l10n.methodName(method)),
            ),
        ],
      ),
    );
  }
}

/// Standard or Hanafi, each with a plain explanation. Shared by setup and the
/// prayer settings page.
class AsrPicker extends StatelessWidget {
  const AsrPicker({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final AsrMethod selected;
  final ValueChanged<AsrMethod> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return RadioGroup<AsrMethod>(
      groupValue: selected,
      onChanged: (value) {
        if (value != null) onSelected(value);
      },
      child: Column(
        children: [
          for (final asr in AsrMethod.values)
            RadioListTile<AsrMethod>(
              key: Key('asr-${asr.name}'),
              value: asr,
              title: Text(l10n.asrName(asr)),
              subtitle: Text(l10n.asrDescription(asr)),
            ),
        ],
      ),
    );
  }
}

/// Setup step 3: the calculation method (suggested for the region) and Asr.
class MethodStep extends ConsumerWidget {
  const MethodStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(setupControllerProvider);
    final controller = ref.read(setupControllerProvider.notifier);
    final suggested = controller.suggestedMethodForLocation;
    final theme = Theme.of(context);
    return SetupStepLayout(
      title: l10n.setupMethodTitle,
      children: [
        if (suggested != null)
          Semantics(
            liveRegion: true,
            child: Text(
              l10n.setupMethodSuggested(l10n.methodName(suggested)),
              style: theme.textTheme.titleMedium,
            ),
          ),
        if (controller.suggestionIsGeneral)
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 8),
            child: Text(l10n.setupMethodGeneral),
          ),
        Padding(
          padding: const EdgeInsetsDirectional.only(top: 8),
          child: Text(l10n.setupMethodChange),
        ),
        MethodPicker(
          selected: state.method,
          onSelected: controller.chooseMethod,
        ),
        const Divider(),
        Semantics(
          header: true,
          child: Text(l10n.setupAsrTitle, style: theme.textTheme.titleLarge),
        ),
        const SizedBox(height: 4),
        Text(l10n.setupAsrIntro),
        AsrPicker(selected: state.asr, onSelected: controller.chooseAsr),
      ],
    );
  }
}
