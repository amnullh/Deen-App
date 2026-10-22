import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/setup_providers.dart';
import '../../domain/permissions/permission_flow.dart';
import '../../l10n/generated/app_localizations.dart';
import 'setup_widgets.dart';

/// Setup step 7: the privacy summary, and a list of anything that will not work
/// because a permission was refused, with the way back to it.
class PrivacyStep extends ConsumerWidget {
  const PrivacyStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(setupControllerProvider);
    final controller = ref.read(setupControllerProvider.notifier);
    final degraded = state.report.degraded;
    return SetupStepLayout(
      title: l10n.setupPrivacyTitle,
      children: [
        StatusLine(ok: true, message: l10n.setupPrivacyNoData),
        StatusLine(ok: true, message: l10n.setupPrivacyOnDevice),
        StatusLine(ok: true, message: l10n.setupPrivacyNoTracking),
        if (degraded.isNotEmpty) ...[
          const Divider(height: 32),
          Semantics(
            header: true,
            child: Text(
              l10n.setupSummaryTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          for (final feature in degraded)
            StatusLine(
              ok: false,
              message: switch (feature) {
                DegradedFeature.alerts => l10n.setupSummaryAlerts,
                DegradedFeature.exactTiming => l10n.setupSummaryExact,
                DegradedFeature.automaticLocation => l10n.setupSummaryLocation,
              },
            ),
          Text(l10n.setupSummaryWayBack),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              key: const Key('privacy-open-settings'),
              onPressed: controller.openAppSettings,
              child: Text(l10n.setupOpenAppSettings),
            ),
          ),
        ],
      ],
    );
  }
}
