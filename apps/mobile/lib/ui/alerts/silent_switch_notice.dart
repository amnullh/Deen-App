import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/providers/alerts_providers.dart';
import '../../domain/entities/enums.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../platform/alert_scheduler.dart';
import 'alert_labels.dart';

/// The one-time iPhone explanation of the silent switch (spec Story 3,
/// scenario 5): the notification sound is muted by the switch, vibration is
/// offered, and tapping the notification plays the full Azaan.
///
/// It shows only on iPhone and only until the user has seen it once; it takes
/// no space otherwise, so it can be placed on any screen.
class SilentSwitchNotice extends ConsumerWidget {
  const SilentSwitchNotice({super.key});

  Future<void> _markExplained(WidgetRef ref) async {
    final repo = ref.read(alertPreferenceRepositoryProvider);
    final global = await repo.getGlobal();
    await repo.saveGlobal(global.copyWith(silentSwitchExplained: true));
  }

  /// Switches every audible prayer to vibration, then records that the notice
  /// was seen.
  Future<void> _useVibration(WidgetRef ref) async {
    final repo = ref.read(alertPreferenceRepositoryProvider);
    for (final preference in await repo.getAll()) {
      if (isAudible(preference.type)) {
        await repo.save(preference.copyWith(type: AlertType.vibrate));
      }
    }
    await _markExplained(ref);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final platform = ref.watch(alertPlatformProvider);
    final explained = ref.watch(globalAlertSettingsProvider).value;
    if (platform != AlertPlatform.ios ||
        explained == null ||
        explained.silentSwitchExplained) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    return Card(
      key: const Key('silent-switch-notice'),
      margin: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 8),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.alertSilentSwitchTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            Text(l10n.alertSilentSwitchBody),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  key: const Key('silent-switch-got-it'),
                  onPressed: () => _markExplained(ref),
                  child: Text(l10n.alertSilentSwitchGotIt),
                ),
                OutlinedButton(
                  key: const Key('silent-switch-vibrate'),
                  onPressed: () => _useVibration(ref),
                  child: Text(l10n.alertSilentSwitchVibrate),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
