import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/alerts_providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../platform/alert_scheduler.dart';

/// How the exact-alarm question ended.
enum ExactAlarmOutcome {
  /// Not Android, or exact alarms were already allowed: nothing was asked.
  notNeeded,

  /// The user allowed exact alarms.
  granted,

  /// The user continued without them; alerts fall back to inexact timing.
  declined,
}

/// The re-prompt shown when the user turns on an audible alert or a reminder
/// while Android exact alarms are not allowed (spec Story 3, scenario 7a).
///
/// It explains why, links to the system setting, and, if the user refuses,
/// says plainly that timing may be less precise. Refusing never blocks the
/// choice the user was making.
class ExactAlarmFlow {
  const ExactAlarmFlow._();

  static Future<ExactAlarmOutcome> ensure(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final scheduler = ref.read(alertSchedulerProvider);
    if (scheduler.platform != AlertPlatform.android) {
      return ExactAlarmOutcome.notNeeded;
    }
    final permissions = await scheduler.getPermissionState();
    if (permissions.exactAlarmGranted) return ExactAlarmOutcome.notNeeded;
    if (!context.mounted) return ExactAlarmOutcome.declined;

    final outcome = await showDialog<ExactAlarmOutcome>(
      context: context,
      builder: (_) => _ExactAlarmDialog(scheduler: scheduler),
    );
    final result = outcome ?? ExactAlarmOutcome.declined;
    if (result == ExactAlarmOutcome.declined && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).alertExactInexact),
          duration: const Duration(seconds: 8),
        ),
      );
    }
    return result;
  }
}

class _ExactAlarmDialog extends StatefulWidget {
  const _ExactAlarmDialog({required this.scheduler});

  final AlertScheduler scheduler;

  @override
  State<_ExactAlarmDialog> createState() => _ExactAlarmDialogState();
}

class _ExactAlarmDialogState extends State<_ExactAlarmDialog> {
  /// True once the settings page was opened, so the next step is to check.
  bool _openedSettings = false;
  bool _stillOff = false;

  Future<void> _openSettings() async {
    await widget.scheduler.openExactAlarmSettings();
    if (mounted) setState(() => _openedSettings = true);
  }

  Future<void> _check() async {
    final permissions = await widget.scheduler.getPermissionState();
    if (!mounted) return;
    if (permissions.exactAlarmGranted) {
      Navigator.of(context).pop(ExactAlarmOutcome.granted);
    } else {
      setState(() => _stillOff = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      key: const Key('exact-alarm-dialog'),
      title: Text(l10n.alertExactTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.alertExactBody),
            if (_stillOff) ...[
              const SizedBox(height: 12),
              Text(l10n.alertExactInexact),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const Key('exact-alarm-skip'),
          onPressed: () =>
              Navigator.of(context).pop(ExactAlarmOutcome.declined),
          child: Text(l10n.alertExactSkip),
        ),
        if (_openedSettings)
          FilledButton(
            key: const Key('exact-alarm-check'),
            onPressed: _check,
            child: Text(l10n.alertExactCheck),
          )
        else
          FilledButton(
            key: const Key('exact-alarm-open'),
            onPressed: _openSettings,
            child: Text(l10n.alertExactOpen),
          ),
      ],
    );
  }
}
