import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/settings.dart';
import '../../domain/result.dart';
import '../../l10n/generated/app_localizations.dart';
import 'alert_labels.dart';
import 'alert_options_page.dart';
import 'exact_alarm_flow.dart';
import 'silent_switch_notice.dart';
import 'voice_picker_page.dart';

/// Per-prayer alert choices (spec Story 3, scenario 1): off, silent
/// notification, vibrate, short tone or full Azaan, plus the prayer's voice and
/// its "ignore quiet hours" switch.
class AlertSettingsPage extends ConsumerWidget {
  const AlertSettingsPage({super.key});

  /// Saves [preference]; says so in a message when it cannot.
  static Future<void> save(
    BuildContext context,
    WidgetRef ref,
    AlertPreference preference,
  ) async {
    final result = await ref
        .read(alertPreferenceRepositoryProvider)
        .save(preference);
    if (result is Err && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).alertSaveFailed)),
      );
    }
  }

  Future<void> _choose(
    BuildContext context,
    WidgetRef ref,
    AlertPreference current,
    AlertType type,
  ) async {
    if (type == current.type) return;
    // Exact alarms are needed for any audible alert, so ask before saving.
    if (isAudible(type)) await ExactAlarmFlow.ensure(context, ref);
    if (!context.mounted) return;
    await save(context, ref, current.copyWith(type: type));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final preferences = ref.watch(alertPreferencesProvider);
    return Scaffold(
      key: const Key('alert-settings-page'),
      appBar: AppBar(title: Text(l10n.alertSettingsTitle)),
      body: SafeArea(
        child: preferences.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(child: Text(l10n.errorGeneric)),
          data: (items) => ListView(
            padding: const EdgeInsetsDirectional.only(bottom: 24),
            children: [
              const SilentSwitchNotice(),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 8),
                child: Text(l10n.alertSettingsIntro),
              ),
              for (final preference in items)
                _PrayerCard(
                  preference: preference,
                  onChoose: (type) => _choose(context, ref, preference, type),
                  onIgnoreQuietHours: (value) => save(
                    context,
                    ref,
                    preference.copyWith(ignoreQuietHours: value),
                  ),
                ),
              ListTile(
                key: const Key('alert-options-tile'),
                title: Text(l10n.alertOptionsTile),
                subtitle: Text(l10n.alertOptionsTileHint),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AlertOptionsPage(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrayerCard extends StatelessWidget {
  const _PrayerCard({
    required this.preference,
    required this.onChoose,
    required this.onIgnoreQuietHours,
  });

  final AlertPreference preference;
  final ValueChanged<AlertType> onChoose;
  final ValueChanged<bool> onIgnoreQuietHours;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = prayerName(l10n, preference.prayer);
    final key = preference.prayer.name;
    return Card(
      key: Key('prayer-card-$key'),
      margin: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 8),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 0),
              child: Semantics(
                header: true,
                child: Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            Semantics(
              label: l10n.alertTypeGroupLabel(name),
              container: true,
              child: RadioGroup<AlertType>(
                groupValue: preference.type,
                onChanged: (type) {
                  if (type != null) onChoose(type);
                },
                child: Column(
                  children: [
                    for (final type in AlertType.values)
                      RadioListTile<AlertType>(
                        key: Key('type-$key-${type.name}'),
                        value: type,
                        dense: true,
                        title: Text(alertTypeName(l10n, type)),
                      ),
                  ],
                ),
              ),
            ),
            if (isAudible(preference.type))
              SwitchListTile(
                key: Key('ignore-quiet-$key'),
                value: preference.ignoreQuietHours,
                onChanged: onIgnoreQuietHours,
                title: Text(l10n.alertIgnoreQuietHours),
                subtitle: Text(l10n.alertIgnoreQuietHoursHint),
              ),
            if (preference.type == AlertType.fullAzaan)
              ListTile(
                key: Key('voice-tile-$key'),
                title: Text(l10n.alertVoiceTile),
                subtitle: Text(
                  l10n.alertVoiceTileValue(
                    voiceName(l10n, preference.voiceId),
                    variantName(l10n, preference.variant),
                  ),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => VoicePickerPage(prayer: preference.prayer),
                  ),
                ),
              ),
            if (preference.preReminderMinutes case final minutes?)
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 16, 8),
                child: Text(l10n.alertReminderSummary(minutes)),
              ),
          ],
        ),
      ),
    );
  }
}
