import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/permissions/permission_flow.dart';
import 'providers.dart';

import 'providers/prayer_providers.dart';
import 'providers/setup_providers.dart';

/// Recomputes times and re-runs the clock and zone checks when the app returns
/// to the foreground, and when the phone's UTC offset changes while the app is
/// open (time zone or daylight-saving change). Wrap the app's home with it.
///
/// A zone or rule change moves the schedule, so it also bumps
/// [scheduleInvalidationProvider] for the alerts workstream.
class LifecycleObserver extends ConsumerStatefulWidget {
  const LifecycleObserver({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<LifecycleObserver> createState() => _LifecycleObserverState();
}

class _LifecycleObserverState extends ConsumerState<LifecycleObserver>
    with WidgetsBindingObserver {
  Duration? _lastOffset;

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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh(scheduleChanged: false);
      _syncPermissions();
    }
  }

  /// The user may have changed a permission in the system settings while the app
  /// was in the background (the "way back" from a refusal). Read them again and
  /// store the new answer, which also rebuilds the schedule when it changed.
  Future<void> _syncPermissions() async {
    final global = ref.read(globalAlertSettingsProvider).value;
    if (global == null || !global.setupCompleted) return;
    final notifications = await ref
        .read(notificationPermissionGatewayProvider)
        .status();
    final exact = ref.read(isAndroidProvider)
        ? await ref.read(exactAlarmGatewayProvider).status()
        : null;
    final changed = await ref
        .read(profileServiceProvider)
        .savePermissionStates(
          notifications: storedStateFor(notifications),
          exactAlarm: exact == null ? null : storedStateFor(exact),
        );
    if (changed && mounted) {
      ref.read(scheduleInvalidationProvider.notifier).bump();
    }
  }

  /// Re-reads the zone, re-runs the checks and recomputes the day schedules.
  void _refresh({required bool scheduleChanged}) {
    ref.invalidate(deviceZoneIdProvider);
    ref.invalidate(clockSanityProvider);
    ref.read(recomputeEpochProvider.notifier).bump();
    if (scheduleChanged) ref.read(scheduleInvalidationProvider.notifier).bump();
  }

  @override
  Widget build(BuildContext context) {
    // The clock ticks every second; a different UTC offset between two ticks
    // means the zone or daylight saving changed under the app.
    ref.listen(nowProvider, (previous, next) {
      if (next.value == null) return;
      final offset = ref.read(localUtcOffsetProvider)();
      final last = _lastOffset;
      _lastOffset = offset;
      if (last != null && last != offset) _refresh(scheduleChanged: true);
    });
    return widget.child;
  }
}
