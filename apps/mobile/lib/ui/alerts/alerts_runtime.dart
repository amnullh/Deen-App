import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/alerts_providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../platform/playback_service.dart';

/// Keeps alerts running while the app is open: it rebuilds the schedule at
/// launch and on every return to the foreground, starts routing notification
/// taps (tap-to-play, renewal notice), and says so when a tapped Azaan cannot
/// be played.
///
/// Wrap it around the app's home route, inside `MaterialApp`, so it can show
/// messages.
class AlertsRuntime extends ConsumerStatefulWidget {
  const AlertsRuntime({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AlertsRuntime> createState() => _AlertsRuntimeState();
}

class _AlertsRuntimeState extends ConsumerState<AlertsRuntime>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(alertEventRouterProvider).start();
      unawaited(ref.read(scheduleCoordinatorProvider).onLaunch());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(ref.read(scheduleCoordinatorProvider).onForeground());
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watching (not just reading) keeps these providers, and the streams they
    // listen to, active for as long as the app is on screen.
    ref
      ..watch(scheduleCoordinatorProvider)
      ..watch(alertEventRouterProvider);
    ref.listen(lastPlayOutcomeProvider, (_, outcome) {
      if (outcome != PlayOutcome.failed) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).alertPreviewFailed),
        ),
      );
    });
    return widget.child;
  }
}
