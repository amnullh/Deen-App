import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/prayer_providers.dart';
import '../../domain/clock_sanity.dart';
import '../../l10n/generated/app_localizations.dart';
import '../common/info_banner.dart';

/// Warns when the phone's clock looks wrong (spec Story 2, scenario 9). Shows
/// nothing when the check passes or has not finished.
class ClockWarningBanner extends ConsumerWidget {
  const ClockWarningBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final warning = ref.watch(clockSanityProvider).value;
    if (warning == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final message = switch (warning) {
      ClockWarning.beforeBuildDate => l10n.homeClockBeforeBuild,
      ClockWarning.movedBackward => l10n.homeClockMovedBack,
      ClockWarning.drifted => l10n.homeClockDrifted,
    };
    return InfoBanner(
      key: const Key('clock-warning-banner'),
      icon: Icons.schedule,
      warning: true,
      message: message,
    );
  }
}
