import 'dart:async';

import 'generated/scheduling.g.dart';

export 'generated/scheduling.g.dart'
    show
        AlertKind,
        DeliveryType,
        JournalEntry,
        JournalState,
        PendingSummary,
        ScheduledAlert,
        SchedulerResult,
        VolumeChoiceDto;

/// Asks the user for notification permission and returns whether it is
/// granted. Wraps `permission_handler`; replaced in tests.
typedef NotificationPermissionRequest = Future<bool> Function();

/// Which operating system's scheduler is in use.
enum AlertPlatform {
  android,
  ios,

  /// Desktop, web and tests: nothing can be scheduled.
  unsupported,
}

/// Permission and device state the Reliability check shows
/// (contracts/platform-scheduling.md, `getPermissionState`).
class AlertPermissions {
  const AlertPermissions({
    required this.platform,
    required this.notificationsGranted,
    this.exactAlarmGranted = true,
    this.batteryOptimizationIgnored = true,
    this.soundEnabled = true,
  });

  /// Nothing known yet (used before the first read and on unsupported hosts).
  const AlertPermissions.unknown()
    : platform = AlertPlatform.unsupported,
      notificationsGranted = false,
      exactAlarmGranted = true,
      batteryOptimizationIgnored = true,
      soundEnabled = true;

  final AlertPlatform platform;
  final bool notificationsGranted;

  /// Android only. On iOS and unsupported hosts this is true, meaning
  /// "nothing to fix".
  final bool exactAlarmGranted;

  /// Android only. True when the app is exempt from battery optimization; on
  /// iOS it is true, meaning "nothing to fix".
  final bool batteryOptimizationIgnored;

  /// iOS only: whether the notification settings allow sound.
  final bool soundEnabled;

  bool get exactAlarmApplicable => platform == AlertPlatform.android;

  @override
  bool operator ==(Object other) =>
      other is AlertPermissions &&
      other.platform == platform &&
      other.notificationsGranted == notificationsGranted &&
      other.exactAlarmGranted == exactAlarmGranted &&
      other.batteryOptimizationIgnored == batteryOptimizationIgnored &&
      other.soundEnabled == soundEnabled;

  @override
  int get hashCode => Object.hash(
    platform,
    notificationsGranted,
    exactAlarmGranted,
    batteryOptimizationIgnored,
    soundEnabled,
  );
}

/// Something the platform tells the Dart layer about.
sealed class AlertPlatformEvent {
  const AlertPlatformEvent();
}

/// A notification permission or exact-alarm permission changed.
class PermissionChangedEvent extends AlertPlatformEvent {
  const PermissionChangedEvent(this.permissions);

  final AlertPermissions permissions;
}

/// The user tapped the notification for [alertId]. [audioRef] is the recording
/// the notification carried (iOS), so tap-to-play works on a cold start before
/// the schedule is rebuilt.
class NotificationTappedEvent extends AlertPlatformEvent {
  const NotificationTappedEvent(this.alertId, {this.audioRef});

  final String alertId;
  final String? audioRef;
}

/// iOS background refresh fired: rebuild the schedule (contract event
/// `onRefreshWindow`). The system gives the app about 30 seconds and ends the
/// task when the platform side replies, so whoever rebuilds must complete
/// [done] as soon as the rebuild has finished (or failed).
class RefreshWindowEvent extends AlertPlatformEvent {
  RefreshWindowEvent() : done = Completer<void>();

  final Completer<void> done;
}

/// What the app asks of the operating system's alert machinery. Android uses
/// the Pigeon `SchedulerApi` (Kotlin); iOS uses `IosAlertScheduler`
/// (flutter_local_notifications). See contracts/platform-scheduling.md.
abstract interface class AlertScheduler {
  AlertPlatform get platform;

  /// Replaces every pending alert with [alerts]. After it returns only the new
  /// set is pending. Idempotent. Never throws: failures come back as
  /// `SchedulerResult.errorCode`.
  Future<SchedulerResult> replaceSchedule(List<ScheduledAlert> alerts);

  /// One alert after [delaySeconds] ("send a test Azaan in 1 minute").
  Future<SchedulerResult> scheduleTestAlert({
    required int delaySeconds,
    required DeliveryType delivery,
  });

  Future<AlertPermissions> getPermissionState();

  /// Asks for notification permission. Call only after the app explained why.
  /// Returns whether it is granted afterwards.
  Future<bool> requestNotificationPermission();

  /// Android only; a no-op elsewhere.
  Future<void> openExactAlarmSettings();

  /// Android only; a no-op elsewhere.
  Future<void> openBatterySettings();

  Future<void> openAppNotificationSettings();

  /// Entries since [sinceEpochMs]: the Android journal, or iOS inference.
  Future<List<JournalEntry>> readJournal(int sinceEpochMs);

  /// Clears what [readJournal] returned, after the app imported it.
  Future<void> clearJournal();

  /// Registered alert count, schedule end and the next five alerts.
  Future<PendingSummary> getPendingSummary();

  /// Events from the platform. A broadcast stream.
  Stream<AlertPlatformEvent> get events;
}

/// An [AlertScheduler] for hosts that cannot schedule (tests, desktop, web).
/// Every call succeeds and does nothing, so screens render without a device.
class UnsupportedAlertScheduler implements AlertScheduler {
  const UnsupportedAlertScheduler();

  @override
  AlertPlatform get platform => AlertPlatform.unsupported;

  @override
  Future<SchedulerResult> replaceSchedule(List<ScheduledAlert> alerts) async =>
      SchedulerResult(ok: true);

  @override
  Future<SchedulerResult> scheduleTestAlert({
    required int delaySeconds,
    required DeliveryType delivery,
  }) async => SchedulerResult(
    ok: false,
    errorCode: 'invalid_argument',
    message: 'This device cannot schedule alerts.',
  );

  @override
  Future<AlertPermissions> getPermissionState() async =>
      const AlertPermissions.unknown();

  @override
  Future<bool> requestNotificationPermission() async => false;

  @override
  Future<void> openExactAlarmSettings() async {}

  @override
  Future<void> openBatterySettings() async {}

  @override
  Future<void> openAppNotificationSettings() async {}

  @override
  Future<List<JournalEntry>> readJournal(int sinceEpochMs) async => const [];

  @override
  Future<void> clearJournal() async {}

  @override
  Future<PendingSummary> getPendingSummary() async =>
      PendingSummary(registeredCount: 0, snapshotCount: 0, nextAlerts: []);

  @override
  Stream<AlertPlatformEvent> get events => const Stream.empty();
}
