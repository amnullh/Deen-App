import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/providers/alerts_providers.dart';
import '../../domain/alerts/reliability_snapshot.dart';
import '../../domain/alerts/schedule_coordinator.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../platform/alert_scheduler.dart';
import '../alerts/alert_labels.dart';
import '../alerts/silent_switch_notice.dart';
import 'missed_alert_banner.dart';

/// The Reliability check (FR-004; spec Story 3, scenario 11): permission states,
/// the next five alerts, the last result, the date alerts run until, a test
/// Azaan in one minute, and a plain fix for each problem.
class ReliabilityPage extends ConsumerStatefulWidget {
  const ReliabilityPage({super.key});

  @override
  ConsumerState<ReliabilityPage> createState() => _ReliabilityPageState();
}

class _ReliabilityPageState extends ConsumerState<ReliabilityPage>
    with WidgetsBindingObserver {
  /// Message from the last test button press.
  String? _testMessage;
  bool _testing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Coming back from a system settings page: read everything again.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(reliabilitySnapshotProvider);
    }
  }

  Future<void> _sendTest(AlertScheduler scheduler) async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _testing = true;
      _testMessage = null;
    });
    final permissions = await scheduler.getPermissionState();
    String message;
    if (!permissions.notificationsGranted) {
      message = l10n.reliabilityTestNeedsNotifications;
    } else {
      final result = await scheduler.scheduleTestAlert(
        delaySeconds: 60,
        delivery: DeliveryType.fullAzaan,
      );
      if (!mounted) return;
      message = result.ok
          ? l10n.reliabilityTestScheduled(
              MaterialLocalizations.of(context).formatTimeOfDay(
                TimeOfDay.fromDateTime(
                  ref.read(clockProvider)().add(const Duration(seconds: 60)),
                ),
              ),
            )
          : l10n.reliabilityTestFailed(_errorText(l10n, result.errorCode));
    }
    if (!mounted) return;
    setState(() {
      _testing = false;
      _testMessage = message;
    });
    ref.invalidate(reliabilitySnapshotProvider);
  }

  Future<void> _allowNotifications(AlertScheduler scheduler) async {
    final granted = await scheduler.requestNotificationPermission();
    // A refusal cannot be asked again, so the way back is the settings page.
    if (!granted) await scheduler.openAppNotificationSettings();
    ref.invalidate(reliabilitySnapshotProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheduler = ref.watch(alertSchedulerProvider);
    final snapshot = ref.watch(reliabilitySnapshotProvider);

    return Scaffold(
      key: const Key('reliability-page'),
      appBar: AppBar(
        title: Text(l10n.reliabilityCheckTitle),
        actions: [
          IconButton(
            key: const Key('reliability-refresh'),
            tooltip: l10n.reliabilityRefresh,
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(reliabilitySnapshotProvider),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsetsDirectional.only(bottom: 24),
          children: [
            const MissedAlertBanner(),
            const SilentSwitchNotice(),
            _RebuildFailure(report: ref.watch(lastRebuildProvider)),
            snapshot.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => Padding(
                padding: const EdgeInsetsDirectional.all(16),
                child: Text(l10n.reliabilityLoadFailed),
              ),
              data: (data) => _Content(
                snapshot: data,
                testing: _testing,
                testMessage: _testMessage,
                onTest: () => _sendTest(scheduler),
                onAllowNotifications: () => _allowNotifications(scheduler),
                scheduler: scheduler,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _errorText(AppLocalizations l10n, String? code) => switch (code) {
  'permission_denied' => l10n.reliabilityErrorPermissionDenied,
  'exact_alarm_denied' => l10n.reliabilityErrorExactDenied,
  'service_start_blocked' => l10n.reliabilityErrorServiceBlocked,
  'budget_exceeded' => l10n.reliabilityErrorBudget,
  'invalid_argument' => l10n.reliabilityErrorInvalid,
  _ => l10n.reliabilityErrorPlatform,
};

class _RebuildFailure extends StatelessWidget {
  const _RebuildFailure({required this.report});

  final RebuildReport? report;

  @override
  Widget build(BuildContext context) {
    final report = this.report;
    if (report == null || report.status != RebuildStatus.failed) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline),
          const SizedBox(width: 8),
          Expanded(
            child: Semantics(
              liveRegion: true,
              child: Text(
                l10n.reliabilityRebuildFailed(
                  _errorText(l10n, report.errorCode),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.snapshot,
    required this.testing,
    required this.testMessage,
    required this.onTest,
    required this.onAllowNotifications,
    required this.scheduler,
  });

  final ReliabilitySnapshot snapshot;
  final bool testing;
  final String? testMessage;
  final VoidCallback onTest;
  final VoidCallback onAllowNotifications;
  final AlertScheduler scheduler;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final permissions = snapshot.permissions;

    if (permissions.platform == AlertPlatform.unsupported) {
      return Padding(
        padding: const EdgeInsetsDirectional.all(16),
        child: Text(l10n.reliabilityUnsupported),
      );
    }
    final android = permissions.platform == AlertPlatform.android;

    Widget heading(String text) => Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 24, 16, 8),
      child: Semantics(
        header: true,
        child: Text(text, style: theme.textTheme.titleMedium),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatusHeader(allGood: snapshot.allGood),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 0),
          child: Text(l10n.reliabilityIntro),
        ),
        heading(l10n.reliabilityPermissionsTitle),
        _PermissionTile(
          rowKey: 'notifications',
          title: l10n.reliabilityNotifications,
          ok: permissions.notificationsGranted,
          fix: l10n.reliabilityNotificationsFix,
          actionLabel: l10n.reliabilityNotificationsAllow,
          onAction: onAllowNotifications,
        ),
        if (android) ...[
          _PermissionTile(
            rowKey: 'exact',
            title: l10n.reliabilityExact,
            ok: permissions.exactAlarmGranted,
            fix: l10n.reliabilityExactFix,
            actionLabel: l10n.reliabilityExactOpen,
            onAction: scheduler.openExactAlarmSettings,
          ),
          _PermissionTile(
            rowKey: 'battery',
            title: l10n.reliabilityBattery,
            ok: permissions.batteryOptimizationIgnored,
            okText: l10n.reliabilityBatteryOk,
            fix: l10n.reliabilityBatteryFix,
            actionLabel: l10n.reliabilityBatteryOpen,
            onAction: scheduler.openBatterySettings,
          ),
        ] else ...[
          _PermissionTile(
            rowKey: 'sound',
            title: l10n.reliabilitySound,
            ok: permissions.soundEnabled,
            fix: l10n.reliabilitySoundFix,
            actionLabel: l10n.reliabilityNotificationsSettings,
            onAction: scheduler.openAppNotificationSettings,
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 0),
            child: Text(l10n.reliabilitySilentSwitchTip),
          ),
        ],
        heading(l10n.reliabilityRunsUntilTitle),
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                snapshot.runsUntil == null
                    ? l10n.reliabilityRunsUntilNone
                    : MaterialLocalizations.of(context)
                          .formatFullDate(snapshot.runsUntil!.toLocal()),
                key: const Key('runs-until'),
                style: theme.textTheme.bodyLarge,
              ),
              if (snapshot.runsUntil != null) ...[
                const SizedBox(height: 4),
                Text(
                  android
                      ? l10n.reliabilityRunsUntilHint
                      : l10n.reliabilityIosRefreshNote,
                ),
              ],
              const SizedBox(height: 4),
              Text(l10n.reliabilityRegistered(snapshot.registeredCount)),
            ],
          ),
        ),
        heading(l10n.reliabilityNextTitle),
        if (snapshot.next.isEmpty)
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
            child: Text(l10n.reliabilityNextNone),
          )
        else
          for (final upcoming in snapshot.next) _UpcomingTile(upcoming),
        heading(l10n.reliabilityLastTitle),
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
          child: Text(
            snapshot.lastResult == null
                ? l10n.reliabilityLastNone
                : l10n.reliabilityLastLine(
                    whenText(context, snapshot.lastResult!.plannedFireAt),
                    resultName(l10n, snapshot.lastResult!.state),
                  ),
            key: const Key('last-result'),
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 24, 16, 0),
          child: FilledButton.icon(
            key: const Key('send-test-azaan'),
            onPressed: testing ? null : onTest,
            icon: const Icon(Icons.volume_up_outlined),
            label: Text(l10n.reliabilityTestButton),
          ),
        ),
        if (testMessage != null)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 0),
            child: Semantics(
              liveRegion: true,
              child: Text(testMessage!, key: const Key('test-message')),
            ),
          ),
      ],
    );
  }
}

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({required this.allGood});

  final bool allGood;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = allGood
        ? l10n.reliabilityAllGood
        : l10n.reliabilityProblemsFound;
    // The words and the icon shape carry the state; color only reinforces it.
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 8),
      child: Semantics(
        header: true,
        child: Row(
          children: [
            Icon(allGood ? Icons.check_circle : Icons.error_outline),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                key: const Key('reliability-status'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.rowKey,
    required this.title,
    required this.ok,
    required this.fix,
    required this.actionLabel,
    required this.onAction,
    this.okText,
  });

  final String rowKey;
  final String title;
  final bool ok;
  final String? okText;
  final String fix;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ok ? l10n.reliabilityStateOn : l10n.reliabilityStateOff;
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 16,
        vertical: 4,
      ),
      child: Column(
        key: Key('permission-$rowKey'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(ok ? Icons.check_circle_outline : Icons.error_outline),
              const SizedBox(width: 8),
              Expanded(child: Text(title)),
              Text(state, key: Key('permission-state-$rowKey')),
            ],
          ),
          if (ok && okText != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 32),
              child: Text(okText!),
            ),
          if (!ok) ...[
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 32, top: 4),
              child: Text(fix),
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: 24),
                child: TextButton(
                  key: Key('permission-fix-$rowKey'),
                  onPressed: onAction,
                  child: Text(actionLabel),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _UpcomingTile extends StatelessWidget {
  const _UpcomingTile(this.upcoming);

  final UpcomingAlert upcoming;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final alert = upcoming.alert;
    final when = whenText(
      context,
      DateTime.fromMillisecondsSinceEpoch(alert.fireAtEpochMs, isUtc: true),
    );
    final type = _deliveryName(l10n, alert);
    final flags = [
      if (upcoming.silencedByQuietHours) l10n.reliabilityFlagSilenced,
      if (upcoming.inexact) l10n.reliabilityFlagInexact,
    ];
    return Semantics(
      label: l10n.reliabilityNextRow(alert.title, type, when),
      excludeSemantics: true,
      child: ListTile(
        key: Key('upcoming-${alert.alertId}'),
        title: Text(alert.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$type, $when'),
            for (final flag in flags)
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 16),
                  const SizedBox(width: 4),
                  Expanded(child: Text(flag)),
                ],
              ),
          ],
        ),
      ),
    );
  }

  static String _deliveryName(AppLocalizations l10n, ScheduledAlert alert) {
    if (alert.kind == AlertKind.renewal) return l10n.reliabilityKindRenewal;
    return switch (alert.delivery) {
      DeliveryType.silent => l10n.alertTypeSilent,
      DeliveryType.vibrate => l10n.alertTypeVibrate,
      DeliveryType.shortTone => l10n.alertTypeShortTone,
      DeliveryType.fullAzaan => l10n.alertTypeFullAzaan,
    };
  }
}
