import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/prayer_providers.dart';
import '../../app/providers/setup_providers.dart';
import '../../domain/prayer/region_suggestion.dart';
import '../../l10n/generated/app_localizations.dart';
import '../common/info_banner.dart';
import '../common/prayer_labels.dart';

/// Offers, once per region, to switch to the method that region usually uses. The
/// chosen method stays unless the user accepts.
class RegionSuggestionBanner extends ConsumerWidget {
  const RegionSuggestionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestion = ref.watch(regionSuggestionProvider);
    if (suggestion == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final method = l10n.methodName(suggestion.suggested);
    final profile = ref.read(profileServiceProvider);
    return InfoBanner(
      key: const Key('region-suggestion-banner'),
      icon: Icons.travel_explore,
      message: suggestion.isGeneralDefault
          ? l10n.homeRegionSuggestionGeneral(method)
          : l10n.homeRegionSuggestion(method),
      actionLabel: l10n.homeRegionSuggestionSwitch(method),
      onAction: () =>
          profile.updateSettings((s) => acceptSuggestion(s, suggestion)),
      dismissLabel: l10n.homeBannerDismiss,
      onDismiss: () =>
          profile.updateSettings((s) => dismissSuggestion(s, suggestion)),
    );
  }
}
