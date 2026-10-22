import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/adhkar_providers.dart';
import '../../domain/adhkar/adhkar_reminder.dart';
import '../../domain/entities/enums.dart';
import '../../l10n/generated/app_localizations.dart';

/// Opt-in morning and evening reminders, timed from a prayer. Settings are
/// saved on every change; the planner and alert layers read them from the
/// `adhkar_reminder` table (via `adhkarReminderRepositoryProvider`).
class AdhkarReminderSettingsPage extends ConsumerWidget {
  const AdhkarReminderSettingsPage({super.key});

  /// How far one press of the earlier/later buttons moves a reminder.
  static const int stepMinutes = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final reminders = ref.watch(adhkarRemindersProvider).value;
    return Scaffold(
      key: const Key('adhkar-reminders-page'),
      appBar: AppBar(title: Text(l10n.adhkarRemindersTitle)),
      body: SafeArea(
        child: reminders == null
            ? Center(
                child: Semantics(
                  label: l10n.loading,
                  child: const CircularProgressIndicator(),
                ),
              )
            : ListView(
                padding: const EdgeInsetsDirectional.all(16),
                children: [
                  for (final reminder in reminders)
                    _ReminderCard(reminder: reminder),
                  const SizedBox(height: 8),
                  Text(l10n.adhkarReminderNote),
                ],
              ),
      ),
    );
  }
}

class _ReminderCard extends ConsumerWidget {
  const _ReminderCard({required this.reminder});

  final AdhkarReminder reminder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final kind = reminder.kind.name;
    final heading = reminder.kind == AdhkarReminderKind.morning
        ? l10n.adhkarReminderMorning
        : l10n.adhkarReminderEvening;
    final anchors = AdhkarReminder.anchorsFor(reminder.kind);

    Future<void> save(AdhkarReminder changed) async {
      final result = await ref
          .read(adhkarReminderRepositoryProvider)
          .save(changed);
      if (!result.isOk && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.adhkarReminderSaveError)));
      }
    }

    int clamp(int minutes) => minutes.clamp(
      AdhkarReminder.minOffsetMinutes,
      AdhkarReminder.maxOffsetMinutes,
    );

    return Card(
      margin: const EdgeInsetsDirectional.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                heading,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            SwitchListTile(
              key: Key('adhkar-reminder-$kind-enabled'),
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.adhkarReminderEnable),
              value: reminder.enabled,
              onChanged: (value) => save(reminder.copyWith(enabled: value)),
            ),
            if (anchors.length == 1)
              Text(l10n.adhkarReminderFajrOnly)
            else ...[
              Text(l10n.adhkarReminderAnchor),
              const SizedBox(height: 8),
              SegmentedButton<ReminderAnchor>(
                key: Key('adhkar-reminder-$kind-anchor'),
                showSelectedIcon: true,
                segments: [
                  for (final anchor in anchors)
                    ButtonSegment(
                      value: anchor,
                      label: Text(_anchorName(l10n, anchor)),
                    ),
                ],
                selected: {reminder.anchor},
                onSelectionChanged: (selection) =>
                    save(reminder.copyWith(anchor: selection.single)),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  key: Key('adhkar-reminder-$kind-earlier'),
                  tooltip: l10n.adhkarReminderEarlier,
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed:
                      reminder.offsetMinutes <= AdhkarReminder.minOffsetMinutes
                      ? null
                      : () => save(
                          reminder.copyWith(
                            offsetMinutes: clamp(
                              reminder.offsetMinutes -
                                  AdhkarReminderSettingsPage.stepMinutes,
                            ),
                          ),
                        ),
                ),
                Expanded(
                  child: Text(
                    _timing(l10n, reminder),
                    key: Key('adhkar-reminder-$kind-timing'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  key: Key('adhkar-reminder-$kind-later'),
                  tooltip: l10n.adhkarReminderLater,
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed:
                      reminder.offsetMinutes >= AdhkarReminder.maxOffsetMinutes
                      ? null
                      : () => save(
                          reminder.copyWith(
                            offsetMinutes: clamp(
                              reminder.offsetMinutes +
                                  AdhkarReminderSettingsPage.stepMinutes,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _anchorName(AppLocalizations l10n, ReminderAnchor anchor) {
    switch (anchor) {
      case ReminderAnchor.fajr:
        return l10n.prayerFajr;
      case ReminderAnchor.asr:
        return l10n.prayerAsr;
      case ReminderAnchor.maghrib:
        return l10n.prayerMaghrib;
    }
  }

  static String _timing(AppLocalizations l10n, AdhkarReminder r) {
    final prayer = _anchorName(l10n, r.anchor);
    final minutes = r.offsetMinutes;
    if (minutes == 0) return l10n.adhkarReminderAt(prayer);
    return minutes > 0
        ? l10n.adhkarReminderAfter(minutes, prayer)
        : l10n.adhkarReminderBefore(-minutes, prayer);
  }
}
