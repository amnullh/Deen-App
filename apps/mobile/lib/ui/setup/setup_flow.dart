import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/setup_providers.dart';
import '../../domain/setup/setup_state.dart';
import '../../l10n/generated/app_localizations.dart';
import 'battery_guide_page.dart';
import 'exact_alarm_page.dart';
import 'language_page.dart';
import 'location_page.dart';
import 'method_page.dart';
import 'notification_permission_page.dart';
import 'privacy_page.dart';

/// First-run setup: language, location, method, notifications, (Android) exact
/// alarms and battery, privacy. Place it where the app shows the home screen
/// while `setupCompleteProvider` is false; [onFinished] runs after setup is saved.
class SetupFlow extends ConsumerStatefulWidget {
  const SetupFlow({this.onFinished, super.key});

  final VoidCallback? onFinished;

  @override
  ConsumerState<SetupFlow> createState() => _SetupFlowState();
}

class _SetupFlowState extends ConsumerState<SetupFlow>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() => ref.read(setupControllerProvider.notifier).load());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Coming back from the system settings: read the permissions again so the
  /// screen shows what the user just changed.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final step = ref.read(setupControllerProvider).step;
    if (state == AppLifecycleState.resumed &&
        (step == SetupStep.notifications || step == SetupStep.exactAlarm)) {
      ref.read(setupControllerProvider.notifier).refreshPermissions();
    }
  }

  Future<void> _finish() async {
    final done = await ref.read(setupControllerProvider.notifier).finish();
    if (done && mounted) widget.onFinished?.call();
  }

  Widget _page(SetupStep step) {
    switch (step) {
      case SetupStep.language:
        return const LanguageStep();
      case SetupStep.location:
        return const LocationStep();
      case SetupStep.method:
        return const MethodStep();
      case SetupStep.notifications:
        return const NotificationPermissionStep();
      case SetupStep.exactAlarm:
        return const ExactAlarmStep();
      case SetupStep.battery:
        return const BatteryGuideStep();
      case SetupStep.privacy:
        return const PrivacyStep();
    }
  }

  /// "Not now" while a permission question is still unanswered, otherwise "Next".
  String _nextLabel(AppLocalizations l10n, SetupState state) {
    if (state.isLast) return l10n.setupFinish;
    final unanswered =
        (state.step == SetupStep.notifications &&
            state.notifications == null) ||
        (state.step == SetupStep.exactAlarm && state.exactAlarm == null);
    return unanswered ? l10n.setupNotNow : l10n.setupNext;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(setupControllerProvider);
    final controller = ref.read(setupControllerProvider.notifier);
    final first = state.step == state.steps.first;
    return Scaffold(
      key: const Key('setup-flow'),
      appBar: AppBar(title: Text(l10n.setupTitle)),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.setupProgress(state.stepNumber, state.steps.length),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: state.stepNumber / state.steps.length,
                    semanticsLabel: l10n.setupProgress(
                      state.stepNumber,
                      state.steps.length,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _page(state.step)),
            Padding(
              padding: const EdgeInsetsDirectional.all(16),
              child: Row(
                children: [
                  if (!first) ...[
                    Expanded(
                      child: OutlinedButton(
                        key: const Key('setup-back'),
                        onPressed: state.busy ? null : controller.back,
                        child: Text(l10n.setupBack),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: FilledButton(
                      key: const Key('setup-next'),
                      onPressed: state.busy || !state.canContinue
                          ? null
                          : (state.isLast ? _finish : controller.next),
                      child: Text(_nextLabel(l10n, state)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
