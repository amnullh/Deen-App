import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/setup_providers.dart';
import '../../domain/entities/enums.dart';
import '../../domain/setup/oem_guide.dart';
import '../../l10n/generated/app_localizations.dart';
import 'setup_widgets.dart';

/// The guide for a brand, loaded once per brand.
final oemGuideProvider = FutureProvider.family<OemGuide, OemBrand>(
  (ref, brand) => ref.watch(oemGuideRepositoryProvider).load(brand),
);

String _brandName(AppLocalizations l10n, OemBrand brand) {
  switch (brand) {
    case OemBrand.xiaomi:
      return l10n.oemBrandXiaomi;
    case OemBrand.oppo:
      return l10n.oemBrandOppo;
    case OemBrand.vivo:
      return l10n.oemBrandVivo;
    case OemBrand.huawei:
      return l10n.oemBrandHuawei;
    case OemBrand.samsung:
      return l10n.oemBrandSamsung;
    case OemBrand.oneplus:
      return l10n.oemBrandOneplus;
    case OemBrand.other:
      return l10n.oemBrandOther;
  }
}

/// Setup step 6 (Android only): a "how to fix" guide for the phone's brand, and a
/// link to the system battery list. The app never asks to be exempted itself.
class BatteryGuideStep extends ConsumerStatefulWidget {
  const BatteryGuideStep({super.key});

  @override
  ConsumerState<BatteryGuideStep> createState() => _BatteryGuideStepState();
}

class _BatteryGuideStepState extends ConsumerState<BatteryGuideStep> {
  OemBrand _brand = OemBrand.other;
  bool _chosenByUser = false;

  @override
  void initState() {
    super.initState();
    _detect();
  }

  Future<void> _detect() async {
    final detected = await ref.read(deviceBrandSourceProvider).detect();
    if (!mounted || _chosenByUser || detected == null) return;
    setState(() => _brand = detected);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final appLanguage = AppLanguage.values.firstWhere(
      (l) => l.name == language,
      orElse: () => AppLanguage.en,
    );
    final guide = ref.watch(oemGuideProvider(_brand));
    return SetupStepLayout(
      title: l10n.setupBatteryTitle,
      children: [
        Text(l10n.setupBatteryBody),
        const SizedBox(height: 16),
        Semantics(
          header: true,
          child: Text(
            l10n.setupBatteryBrandLabel,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final brand in OemBrand.values)
              ChoiceChip(
                key: Key('brand-${brand.name}'),
                label: Text(_brandName(l10n, brand)),
                selected: brand == _brand,
                onSelected: (_) => setState(() {
                  _brand = brand;
                  _chosenByUser = true;
                }),
              ),
          ],
        ),
        const SizedBox(height: 16),
        guide.when(
          data: (data) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (index, step) in data.stepsFor(appLanguage).indexed)
                Semantics(
                  label: l10n.setupBatteryStep(index + 1, step),
                  excludeSemantics: true,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(radius: 14, child: Text('${index + 1}')),
                        const SizedBox(width: 12),
                        Expanded(child: Text(step)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) =>
              StatusLine(ok: false, message: l10n.setupBatteryGuideUnavailable),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          key: const Key('battery-open-settings'),
          onPressed: ref
              .read(setupControllerProvider.notifier)
              .openBatterySettings,
          icon: const Icon(Icons.battery_saver),
          label: Text(l10n.setupBatteryOpenSettings),
        ),
      ],
    );
  }
}
