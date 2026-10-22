import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override, ProviderListenable;

import '../../data/repositories/drift_alert_log_repository.dart';
import '../../domain/alerts/alert_event_router.dart';
import '../../domain/alerts/alert_log_entry.dart';
import '../../domain/alerts/alert_reconciler.dart';
import '../../domain/alerts/planner_plan_builder.dart';
import '../../domain/alerts/reliability_snapshot.dart';
import '../../domain/alerts/renewal_handler.dart';
import '../../domain/alerts/schedule_coordinator.dart';
import '../../domain/alerts/schedule_plan.dart';
import '../../domain/clock_sanity.dart';
import '../../domain/delete_all_data.dart';
import '../../domain/repositories/alert_log_repository.dart';
import '../../platform/alert_scheduler.dart';
import '../../platform/android_alert_scheduler.dart';
import '../../platform/ios_alert_scheduler.dart';
import '../../platform/playback_service.dart';
import '../providers.dart';
import 'adhkar_providers.dart';
import 'data_providers.dart';
import 'prayer_providers.dart';
import 'setup_providers.dart';

/// Which operating system's scheduler to use. Overridden in tests.
final alertPlatformProvider = Provider<AlertPlatform>((ref) {
  if (Platform.isAndroid) return AlertPlatform.android;
  if (Platform.isIOS) return AlertPlatform.ios;
  return AlertPlatform.unsupported;
});

final alertLogRepositoryProvider = Provider<AlertLogRepository>(
  (ref) => DriftAlertLogRepository(ref.watch(appDatabaseProvider)),
);

/// The platform scheduler: Kotlin through Pigeon on Android, Dart on
/// `flutter_local_notifications` on iPhone, and a harmless no-op elsewhere.
final alertSchedulerProvider = Provider<AlertScheduler>((ref) {
  switch (ref.watch(alertPlatformProvider)) {
    case AlertPlatform.android:
      final scheduler = AndroidAlertScheduler();
      ref.onDispose(scheduler.dispose);
      return scheduler;
    case AlertPlatform.ios:
      final log = ref.watch(alertLogRepositoryProvider);
      final clock = ref.watch(clockProvider);
      final scheduler = IosAlertScheduler(
        gateway: FlutterLocalNotificationsGateway(),
        plannedPast: () => log.plannedUpTo(clock()),
        clock: clock,
      );
      scheduler.attachBackgroundRefresh();
      unawaited(scheduler.initialize());
      ref.onDispose(scheduler.dispose);
      return scheduler;
    case AlertPlatform.unsupported:
      return const UnsupportedAlertScheduler();
  }
});

/// Real in-app playback. Created on first use.
final playbackServiceProvider = Provider<PlaybackService>((ref) {
  final service = PlaybackService(
    player: JustAudioAzaanPlayer(),
    session: AudioSessionPlaybackSession(),
    log: ref.watch(alertLogRepositoryProvider),
    clock: ref.watch(clockProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

final planBuilderProvider = Provider<PlanBuilder>(
  (ref) => PlannerPlanBuilder(
    engine: ref.watch(prayerEngineProvider),
    offsets: ref.watch(offsetResolverProvider),
    hijri: ref.watch(hijriSourceProvider),
  ),
);

/// Alerts found missed or possibly missed since the user last looked. The
/// banner shows them; dismissing clears them.
class MissedAlerts extends Notifier<List<AlertLogEntry>> {
  @override
  List<AlertLogEntry> build() => const [];

  void report(List<AlertLogEntry> found) {
    if (found.isEmpty) return;
    state = [...state, ...found];
  }

  void dismiss() => state = const [];
}

final missedAlertsProvider =
    NotifierProvider<MissedAlerts, List<AlertLogEntry>>(MissedAlerts.new);

/// The outcome of the latest schedule rebuild, or null before the first.
class LastRebuild extends Notifier<RebuildReport?> {
  @override
  RebuildReport? build() => null;

  void record(RebuildReport report) => state = report;
}

final lastRebuildProvider = NotifierProvider<LastRebuild, RebuildReport?>(
  LastRebuild.new,
);

/// The latest tap-to-play outcome, so the app can say when a recording could
/// not be played.
class LastPlayOutcome extends Notifier<PlayOutcome?> {
  @override
  PlayOutcome? build() => null;

  void record(PlayOutcome outcome) => state = outcome;
}

final lastPlayOutcomeProvider = NotifierProvider<LastPlayOutcome, PlayOutcome?>(
  LastPlayOutcome.new,
);

/// Whether the device clock was changed since the last look. It reads the
/// clock-sanity check the home screen already runs, so the two never compare
/// against each other's stored sample, and it reports each warning once.
Future<bool> Function() _clockChangeProbe(Ref ref) {
  Object? handled;
  return () async {
    final warning = await ref.read(clockSanityProvider.future);
    final isChange =
        warning == ClockWarning.movedBackward ||
        warning == ClockWarning.drifted;
    final value = ref.read(clockSanityProvider);
    if (!isChange || identical(value, handled)) return false;
    handled = value;
    return true;
  };
}

/// Builds and keeps the alert schedule fresh. It listens to every input of the
/// plan; the app must read it once at start (see `AlertsRuntime`).
final scheduleCoordinatorProvider = Provider<ScheduleCoordinator>((ref) {
  final scheduler = ref.watch(alertSchedulerProvider);
  final log = ref.watch(alertLogRepositoryProvider);
  final coordinator = ScheduleCoordinator(
    scheduler: scheduler,
    planBuilder: ref.watch(planBuilderProvider),
    settings: ref.watch(settingsRepositoryProvider),
    locations: ref.watch(locationRepositoryProvider),
    alerts: ref.watch(alertPreferenceRepositoryProvider),
    adhkarReminders: ref.watch(adhkarReminderRepositoryProvider),
    log: log,
    clock: ref.watch(clockProvider),
    reconciler: AlertReconciler(scheduler: scheduler, log: log),
    deviceZone: ref.watch(deviceZoneSourceProvider).deviceZoneId,
    clockChanged: _clockChangeProbe(ref),
    onMissed: ref.read(missedAlertsProvider.notifier).report,
    onReport: ref.read(lastRebuildProvider.notifier).record,
  )..start();
  ref.onDispose(coordinator.dispose);

  void rebuildOn<T>(
    ProviderListenable<T> source,
    RebuildTrigger Function(T? previous, T next) trigger,
  ) {
    ref.listen<T>(source, (previous, next) {
      unawaited(coordinator.rebuild(trigger(previous, next)));
    });
  }

  rebuildOn(
    prayerSettingsProvider,
    (previous, next) => previous?.value?.language != next.value?.language
        ? RebuildTrigger.languageChanged
        : RebuildTrigger.settingsChanged,
  );
  rebuildOn(locationProvider, (_, _) => RebuildTrigger.locationChanged);
  rebuildOn(alertPreferencesProvider, (_, _) => RebuildTrigger.settingsChanged);
  rebuildOn(
    globalAlertSettingsProvider,
    (_, _) => RebuildTrigger.settingsChanged,
  );
  rebuildOn(scheduleInvalidationProvider, (_, _) => RebuildTrigger.manual);
  return coordinator;
});

final renewalHandlerProvider = Provider<RenewalHandler>(
  (ref) => RenewalHandler(ref.watch(scheduleCoordinatorProvider)),
);

/// Routes notification taps. Started by `AlertsRuntime`.
final alertEventRouterProvider = Provider<AlertEventRouter>((ref) {
  final router = AlertEventRouter(
    scheduler: ref.watch(alertSchedulerProvider),
    playback: () => ref.read(playbackServiceProvider),
    renewal: ref.watch(renewalHandlerProvider),
    onPlayOutcome: ref.read(lastPlayOutcomeProvider.notifier).record,
  );
  ref.onDispose(router.dispose);
  return router;
});

/// Everything the Reliability check shows, read fresh. Invalidate to check
/// again.
final reliabilitySnapshotProvider =
    FutureProvider.autoDispose<ReliabilitySnapshot>((ref) async {
      final scheduler = ref.watch(alertSchedulerProvider);
      final log = ref.watch(alertLogRepositoryProvider);
      final now = ref.read(clockProvider)();
      final permissions = await scheduler.getPermissionState();
      final summary = await scheduler.getPendingSummary();
      final rows = await log.forAlertIds([
        for (final alert in summary.nextAlerts) alert.alertId,
      ]);
      final global = await ref
          .read(alertPreferenceRepositoryProvider)
          .getGlobal();
      return ReliabilitySnapshot.from(
        permissions: permissions,
        summary: summary,
        causes: {
          for (final row in rows)
            if (row.attempt == 0) row.alertId: row.cause,
        },
        runsUntil: global.scheduleRunsUntil,
        lastResult: await log.lastResult(instant: now),
        now: now,
      );
    });

/// The next alert-log rows, newest first, for screens that list history.
final recentAlertLogProvider = StreamProvider.autoDispose<List<AlertLogEntry>>(
  (ref) => ref.watch(alertLogRepositoryProvider).watchRecent(),
);

/// Removes the Android alert snapshot and journal by replacing the schedule
/// with nothing; there is nothing to remove on iPhone.
class SchedulerNativeAlertFiles implements NativeAlertFiles {
  const SchedulerNativeAlertFiles(this._scheduler);

  final AlertScheduler _scheduler;

  @override
  Future<void> deleteSnapshotAndJournal() async {
    await _scheduler.replaceSchedule(const []);
    await _scheduler.clearJournal();
  }
}

/// Overrides that connect shared hooks to the alert layer: rebuild after a
/// settings import, cancel everything for "delete all my data", and remove the
/// Android snapshot and journal. Add them to the app's `ProviderScope`.
final List<Override> alertsProviderOverrides = [
  afterSettingsImportProvider.overrideWith((ref) {
    final coordinator = ref.watch(scheduleCoordinatorProvider);
    return () async {
      await coordinator.rebuild(RebuildTrigger.manual);
    };
  }),
  cancelAllScheduledAlertsProvider.overrideWith((ref) {
    final scheduler = ref.watch(alertSchedulerProvider);
    return () async {
      await scheduler.replaceSchedule(const []);
    };
  }),
  nativeAlertFilesProvider.overrideWith(
    (ref) => SchedulerNativeAlertFiles(ref.watch(alertSchedulerProvider)),
  ),
];
