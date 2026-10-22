import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/providers/alerts_providers.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/settings.dart';
import '../../domain/result.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../platform/alert_scheduler.dart';
import 'alert_labels.dart';
import 'alert_settings_page.dart';
import 'exact_alarm_flow.dart';

/// Reminder lengths offered in the menus (spec: 5 to 60 minutes).
const List<int> reminderChoices = [5, 10, 15, 20, 30, 45, 60];

/// Suhoor reminder lengths offered, in minutes before Fajr.
const List<int> suhoorChoices = [10, 15, 20, 30, 45, 60, 90];

/// Loud mode, quiet hours, audio output, pre-prayer reminders and the Ramadan
/// suhoor reminder (spec Story 3, scenarios 3, 4, 6, 7 and 8).
class AlertOptionsPage extends ConsumerWidget {
  const AlertOptionsPage({super.key});

  Future<void> _saveGlobal(
    BuildContext context,
    WidgetRef ref,
    GlobalAlertSettings Function(GlobalAlertSettings) change,
  ) async {
    final repo = ref.read(alertPreferenceRepositoryProvider);
    final result = await repo.saveGlobal(change(await repo.getGlobal()));
    if (result is Err && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).alertSaveFailed)),
      );
    }
  }

  Future<void> _pickTime(
    BuildContext context,
    WidgetRef ref, {
    required bool start,
    required QuietHours current,
  }) async {
    final initial = start ? current.startMinutes : current.endMinutes;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initial ~/ 60, minute: initial % 60),
    );
    if (picked == null || !context.mounted) return;
    final minutes = picked.hour * 60 + picked.minute;
    await _saveGlobal(
      context,
      ref,
      (g) => g.copyWith(
        quietHours: QuietHours(
          startMinutes: start ? minutes : current.startMinutes,
          endMinutes: start ? current.endMinutes : minutes,
        ),
      ),
    );
  }

  Future<void> _setReminder(
    BuildContext context,
    WidgetRef ref,
    AlertPreference preference,
    int? minutes,
  ) async {
    // A reminder is an audible alert too, so exact alarms matter here.
    if (minutes != null) await ExactAlarmFlow.ensure(context, ref);
    if (!context.mounted) return;
    await AlertSettingsPage.save(
      context,
      ref,
      minutes == null
          ? preference.copyWith(clearPreReminder: true)
          : preference.copyWith(preReminderMinutes: minutes),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final preferences = ref.watch(alertPreferencesProvider).value;
    final global = ref.watch(globalAlertSettingsProvider).value;
    final isAndroid = ref.watch(alertPlatformProvider) == AlertPlatform.android;
    final theme = Theme.of(context);

    Widget heading(String text) => Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 24, 16, 4),
      child: Semantics(
        header: true,
        child: Text(text, style: theme.textTheme.titleMedium),
      ),
    );
    Widget body(String text) => Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 8),
      child: Text(text, style: theme.textTheme.bodyMedium),
    );

    return Scaffold(
      key: const Key('alert-options-page'),
      appBar: AppBar(title: Text(l10n.alertOptionsTitle)),
      body: SafeArea(
        child: (preferences == null || global == null)
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsetsDirectional.only(bottom: 24),
                children: [
                  heading(l10n.alertLoudTitle),
                  if (isAndroid) ...[
                    body(l10n.alertLoudIntro),
                    for (final p in preferences) _loudSection(context, ref, p),
                  ] else
                    body(l10n.alertLoudAndroidOnly),
                  heading(l10n.alertQuietTitle),
                  body(l10n.alertQuietIntro),
                  _quietSection(context, ref, global),
                  heading(l10n.alertAudioTitle),
                  body(l10n.alertAudioIntro),
                  RadioGroup<AudioOutput>(
                    groupValue: global.audioOutput,
                    onChanged: (value) {
                      if (value == null) return;
                      _saveGlobal(
                        context,
                        ref,
                        (g) => g.copyWith(audioOutput: value),
                      );
                    },
                    child: Column(
                      children: [
                        for (final output in AudioOutput.values)
                          RadioListTile<AudioOutput>(
                            key: Key('output-${output.name}'),
                            value: output,
                            title: Text(outputName(l10n, output)),
                          ),
                      ],
                    ),
                  ),
                  heading(l10n.alertReminderTitle),
                  body(l10n.alertReminderIntro),
                  for (final p in preferences) _reminderRow(context, ref, p),
                  heading(l10n.alertSuhoorTitle),
                  body(l10n.alertSuhoorIntro),
                  SwitchListTile(
                    key: const Key('suhoor-switch'),
                    value: global.suhoorReminderEnabled,
                    title: Text(l10n.alertSuhoorSwitch),
                    onChanged: (value) async {
                      if (value) await ExactAlarmFlow.ensure(context, ref);
                      if (!context.mounted) return;
                      await _saveGlobal(
                        context,
                        ref,
                        (g) => g.copyWith(suhoorReminderEnabled: value),
                      );
                    },
                  ),
                  if (global.suhoorReminderEnabled)
                    _suhoorMinutes(context, ref, global),
                ],
              ),
      ),
    );
  }

  Widget _loudSection(
    BuildContext context,
    WidgetRef ref,
    AlertPreference preference,
  ) {
    final l10n = AppLocalizations.of(context);
    final key = preference.prayer.name;
    final name = prayerName(l10n, preference.prayer);
    return Column(
      key: Key('loud-section-$key'),
      children: [
        SwitchListTile(
          key: Key('loud-$key'),
          value: preference.loudMode,
          title: Text(l10n.alertLoudSwitch(name)),
          onChanged: (value) => AlertSettingsPage.save(
            context,
            ref,
            preference.copyWith(loudMode: value),
          ),
        ),
        if (preference.loudMode)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 16),
            child: RadioGroup<VolumeChoice>(
              groupValue: preference.volumeChoice,
              onChanged: (value) {
                if (value == null) return;
                AlertSettingsPage.save(
                  context,
                  ref,
                  preference.copyWith(volumeChoice: value),
                );
              },
              child: Column(
                children: [
                  RadioListTile<VolumeChoice>(
                    key: Key('volume-$key-keep'),
                    value: VolumeChoice.keepCurrent,
                    title: Text(l10n.alertVolumeKeep),
                  ),
                  RadioListTile<VolumeChoice>(
                    key: Key('volume-$key-ramp'),
                    value: VolumeChoice.gentleRamp,
                    title: Text(l10n.alertVolumeRamp),
                    subtitle: Text(l10n.alertVolumeRampHint),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _quietSection(
    BuildContext context,
    WidgetRef ref,
    GlobalAlertSettings global,
  ) {
    final l10n = AppLocalizations.of(context);
    final quiet = global.quietHours;
    return Column(
      children: [
        SwitchListTile(
          key: const Key('quiet-switch'),
          value: quiet != null,
          title: Text(l10n.alertQuietSwitch),
          subtitle: quiet == null
              ? null
              : Text(
                  l10n.alertQuietRange(
                    minutesText(context, quiet.startMinutes),
                    minutesText(context, quiet.endMinutes),
                  ),
                ),
          onChanged: (value) => _saveGlobal(
            context,
            ref,
            (g) => value
                // 22:00 to 05:00 is a common night; the user can change it.
                ? g.copyWith(
                    quietHours: const QuietHours(
                      startMinutes: 22 * 60,
                      endMinutes: 5 * 60,
                    ),
                  )
                : g.copyWith(clearQuietHours: true),
          ),
        ),
        if (quiet != null) ...[
          ListTile(
            key: const Key('quiet-start'),
            title: Text(l10n.alertQuietStart),
            trailing: Text(minutesText(context, quiet.startMinutes)),
            onTap: () => _pickTime(context, ref, start: true, current: quiet),
          ),
          ListTile(
            key: const Key('quiet-end'),
            title: Text(l10n.alertQuietEnd),
            trailing: Text(minutesText(context, quiet.endMinutes)),
            onTap: () => _pickTime(context, ref, start: false, current: quiet),
          ),
        ],
      ],
    );
  }

  Widget _reminderRow(
    BuildContext context,
    WidgetRef ref,
    AlertPreference preference,
  ) {
    final l10n = AppLocalizations.of(context);
    final name = prayerName(l10n, preference.prayer);
    return ListTile(
      key: Key('reminder-${preference.prayer.name}'),
      title: Text(name),
      trailing: Semantics(
        label: l10n.alertReminderFor(name),
        child: DropdownButton<int?>(
          key: Key('reminder-menu-${preference.prayer.name}'),
          value: preference.preReminderMinutes,
          items: [
            DropdownMenuItem<int?>(child: Text(l10n.alertReminderNone)),
            for (final minutes in reminderChoices)
              DropdownMenuItem<int?>(
                value: minutes,
                child: Text(l10n.alertReminderMinutes(minutes)),
              ),
          ],
          onChanged: (minutes) =>
              _setReminder(context, ref, preference, minutes),
        ),
      ),
    );
  }

  Widget _suhoorMinutes(
    BuildContext context,
    WidgetRef ref,
    GlobalAlertSettings global,
  ) {
    final l10n = AppLocalizations.of(context);
    final choices = {...suhoorChoices, global.suhoorReminderMinutes}.toList()
      ..sort();
    return ListTile(
      key: const Key('suhoor-minutes'),
      title: Text(l10n.alertSuhoorTitle),
      trailing: DropdownButton<int>(
        value: global.suhoorReminderMinutes,
        items: [
          for (final minutes in choices)
            DropdownMenuItem<int>(
              value: minutes,
              child: Text(l10n.alertSuhoorMinutes(minutes)),
            ),
        ],
        onChanged: (minutes) {
          if (minutes == null) return;
          _saveGlobal(
            context,
            ref,
            (g) => g.copyWith(suhoorReminderMinutes: minutes),
          );
        },
      ),
    );
  }
}
