import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/setup_providers.dart';
import '../../domain/permissions/permission_gateways.dart';
import '../../l10n/generated/app_localizations.dart';
import 'setup_widgets.dart';

/// Setup step 5 (Android only): explain exact alarms and open the system
/// setting. Refusing never blocks setup; the reduced-precision message is shown
/// and the Reliability check repeats it.
class ExactAlarmStep extends ConsumerWidget {
  const ExactAlarmStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(setupControllerProvider);
    final controller = ref.read(setupControllerProvider.notifier);
    final outcome = state.exactAlarm;
    final granted = outcome == PermissionOutcome.granted;
    return SetupStepLayout(
      title: l10n.setupExactTitle,
      children: [
        Text(l10n.setupExactBody),
        const SizedBox(height: 16),
        if (!granted) ...[
          FilledButton.icon(
            key: const Key('exact-open-settings'),
            onPressed: controller.openExactAlarmSettings,
            icon: const Icon(Icons.alarm),
            label: Text(l10n.setupExactOpen),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            key: const Key('exact-check'),
            onPressed: controller.refreshPermissions,
            child: Text(l10n.setupExactCheck),
          ),
        ],
        if (outcome != null)
          Semantics(
            liveRegion: true,
            child: StatusLine(
              ok: granted,
              message: granted ? l10n.setupExactGranted : l10n.setupExactDenied,
            ),
          ),
      ],
    );
  }
}
