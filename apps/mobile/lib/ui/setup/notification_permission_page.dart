import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/setup_providers.dart';
import '../../domain/permissions/permission_gateways.dart';
import '../../l10n/generated/app_localizations.dart';
import 'setup_widgets.dart';

/// Setup step 4: explain why notifications are needed, then ask. Refusing keeps
/// setup going; the message says what will not work and where to change it.
class NotificationPermissionStep extends ConsumerWidget {
  const NotificationPermissionStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(setupControllerProvider);
    final controller = ref.read(setupControllerProvider.notifier);
    final outcome = state.notifications;
    final answered = outcome != null;
    final granted = outcome == PermissionOutcome.granted;
    return SetupStepLayout(
      title: l10n.setupNotificationsTitle,
      children: [
        Text(l10n.setupNotificationsBody),
        const SizedBox(height: 16),
        if (!granted)
          FilledButton.icon(
            key: const Key('notifications-allow'),
            onPressed: state.busy ? null : controller.requestNotifications,
            icon: const Icon(Icons.notifications_active_outlined),
            label: Text(l10n.setupNotificationsAllow),
          ),
        if (answered)
          Semantics(
            liveRegion: true,
            child: StatusLine(
              ok: granted,
              message: granted
                  ? l10n.setupNotificationsGranted
                  : l10n.setupNotificationsDenied,
            ),
          ),
        if (answered && !granted)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              key: const Key('notifications-open-settings'),
              onPressed: controller.openAppSettings,
              child: Text(l10n.setupOpenAppSettings),
            ),
          ),
      ],
    );
  }
}
