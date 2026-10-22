import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/alerts_providers.dart';
import '../../domain/entities/enums.dart';
import '../../l10n/generated/app_localizations.dart';
import '../alerts/alert_labels.dart';

/// Tells the user, at next app open, that an alert did not sound and gives the
/// likely cause (spec Story 3, scenario 12). It takes no space when nothing was
/// missed, so it can sit on the home screen and on the Reliability check.
class MissedAlertBanner extends ConsumerWidget {
  const MissedAlertBanner({this.onOpenReliabilityCheck, super.key});

  /// Shown as a button when set (on the home screen); leave null on the
  /// Reliability check itself.
  final VoidCallback? onOpenReliabilityCheck;

  /// How many alerts are listed before "and N more".
  static const int maxListed = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missed = ref.watch(missedAlertsProvider);
    if (missed.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final sorted = [...missed]
      ..sort((a, b) => b.plannedFireAt.compareTo(a.plannedFireAt));
    final listed = sorted.take(maxListed).toList();
    final extra = sorted.length - listed.length;
    final possibly = missed.any((e) => e.state == AlertLogState.possiblyMissed);
    final scheme = Theme.of(context).colorScheme;

    return Card(
      key: const Key('missed-alert-banner'),
      color: scheme.errorContainer,
      margin: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 8),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              liveRegion: true,
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: scheme.onErrorContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      missed.length == 1
                          ? l10n.alertMissedTitle
                          : l10n.alertMissedTitleMany,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(color: scheme.onErrorContainer),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            DefaultTextStyle.merge(
              style: TextStyle(color: scheme.onErrorContainer),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final entry in listed)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(bottom: 4),
                      child: Text(
                        l10n.alertMissedLine(
                          whenText(context, entry.plannedFireAt),
                          causeText(l10n, entry.cause),
                        ),
                      ),
                    ),
                  if (extra > 0) Text(l10n.alertMissedMore(extra)),
                  if (possibly) ...[
                    const SizedBox(height: 4),
                    Text(l10n.alertMissedPossibly),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                TextButton(
                  key: const Key('missed-alert-dismiss'),
                  onPressed: () =>
                      ref.read(missedAlertsProvider.notifier).dismiss(),
                  child: Text(l10n.alertMissedDismiss),
                ),
                if (onOpenReliabilityCheck != null)
                  TextButton(
                    key: const Key('missed-alert-open-check'),
                    onPressed: onOpenReliabilityCheck,
                    child: Text(l10n.alertMissedOpenCheck),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
