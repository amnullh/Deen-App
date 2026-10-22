import 'dart:async';

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import 'alert_scheduler.dart';
import 'generated/scheduling.g.dart';

Future<bool> _requestWithPermissionHandler() async {
  final status = await Permission.notification.request();
  return status.isGranted;
}

/// Android [AlertScheduler]: the Pigeon [SchedulerApi] implemented in Kotlin.
///
/// Native code never throws across the channel, but a missing or crashed
/// native side still surfaces as a [PlatformException]; every call turns that
/// into a failed [SchedulerResult] or a safe default so the UI never crashes.
class AndroidAlertScheduler implements AlertScheduler, SchedulerEvents {
  AndroidAlertScheduler({
    SchedulerApi? api,
    NotificationPermissionRequest? requestNotificationPermissionOverride,
    BinaryMessenger? binaryMessenger,
  }) : _api = api ?? SchedulerApi(binaryMessenger: binaryMessenger),
       _request =
           requestNotificationPermissionOverride ??
           _requestWithPermissionHandler {
    SchedulerEvents.setUp(this, binaryMessenger: binaryMessenger);
  }

  final SchedulerApi _api;
  final NotificationPermissionRequest _request;
  final StreamController<AlertPlatformEvent> _events =
      StreamController<AlertPlatformEvent>.broadcast();

  @override
  AlertPlatform get platform => AlertPlatform.android;

  @override
  Stream<AlertPlatformEvent> get events => _events.stream;

  /// Stops listening for native events.
  void dispose() {
    SchedulerEvents.setUp(null);
    _events.close();
  }

  Future<SchedulerResult> _guard(
    Future<SchedulerResult> Function() call,
  ) async {
    try {
      return await call();
    } on PlatformException catch (e) {
      return SchedulerResult(
        ok: false,
        errorCode: 'platform_error',
        message: e.code,
      );
    }
  }

  @override
  Future<SchedulerResult> replaceSchedule(List<ScheduledAlert> alerts) =>
      _guard(() => _api.replaceSchedule(alerts));

  @override
  Future<SchedulerResult> scheduleTestAlert({
    required int delaySeconds,
    required DeliveryType delivery,
  }) => _guard(() => _api.scheduleTestAlert(delaySeconds, delivery));

  @override
  Future<AlertPermissions> getPermissionState() async {
    try {
      return _fromSnapshot(await _api.getPermissionState());
    } on PlatformException {
      return const AlertPermissions(
        platform: AlertPlatform.android,
        notificationsGranted: false,
        exactAlarmGranted: false,
        batteryOptimizationIgnored: false,
      );
    }
  }

  static AlertPermissions _fromSnapshot(PermissionSnapshot snapshot) {
    return AlertPermissions(
      platform: AlertPlatform.android,
      notificationsGranted: snapshot.notificationsGranted,
      exactAlarmGranted: snapshot.exactAlarmGranted,
      batteryOptimizationIgnored: snapshot.batteryOptimizationIgnored,
    );
  }

  @override
  Future<bool> requestNotificationPermission() async {
    try {
      return await _request();
    } on PlatformException {
      return false;
    }
  }

  Future<void> _ignoringPlatformErrors(Future<void> Function() call) async {
    try {
      await call();
    } on PlatformException {
      // The settings screen could not be opened; the Reliability check keeps
      // showing the problem, so there is nothing more to do here.
    }
  }

  @override
  Future<void> openExactAlarmSettings() =>
      _ignoringPlatformErrors(_api.openExactAlarmSettings);

  @override
  Future<void> openBatterySettings() =>
      _ignoringPlatformErrors(_api.openBatterySettings);

  @override
  Future<void> openAppNotificationSettings() =>
      _ignoringPlatformErrors(_api.openAppNotificationSettings);

  @override
  Future<List<JournalEntry>> readJournal(int sinceEpochMs) async {
    try {
      return await _api.readJournal(sinceEpochMs);
    } on PlatformException {
      return const [];
    }
  }

  @override
  Future<void> clearJournal() => _ignoringPlatformErrors(_api.clearJournal);

  @override
  Future<PendingSummary> getPendingSummary() async {
    try {
      return await _api.getPendingSummary();
    } on PlatformException {
      return PendingSummary(
        registeredCount: 0,
        snapshotCount: 0,
        nextAlerts: [],
      );
    }
  }

  // Events from Kotlin (SchedulerEvents).

  @override
  void onPermissionChanged(PermissionSnapshot snapshot) {
    _events.add(PermissionChangedEvent(_fromSnapshot(snapshot)));
  }

  @override
  void onNotificationTapped(String alertId) {
    _events.add(NotificationTappedEvent(alertId));
  }
}
