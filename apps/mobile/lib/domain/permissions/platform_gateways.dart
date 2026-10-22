import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart' as handler;

import '../../platform/generated/scheduling.g.dart';
import 'permission_gateways.dart';

/// Notification permission through `permission_handler`.
class PermissionHandlerNotificationGateway
    implements NotificationPermissionGateway {
  const PermissionHandlerNotificationGateway();

  @override
  Future<PermissionOutcome> status() async {
    try {
      return _map(await handler.Permission.notification.status);
    } on Object {
      // A missing plugin is reported as "not granted", never as a crash.
      return PermissionOutcome.denied;
    }
  }

  @override
  Future<PermissionOutcome> request() async {
    try {
      return _map(await handler.Permission.notification.request());
    } on Object {
      return PermissionOutcome.denied;
    }
  }

  @override
  Future<void> openAppSettings() async {
    try {
      await handler.openAppSettings();
    } on Object {
      // Nothing more can be done if the settings page cannot open.
    }
  }

  static PermissionOutcome _map(handler.PermissionStatus status) {
    if (status.isGranted || status.isLimited || status.isProvisional) {
      return PermissionOutcome.granted;
    }
    if (status.isPermanentlyDenied || status.isRestricted) {
      return PermissionOutcome.permanentlyDenied;
    }
    return PermissionOutcome.denied;
  }
}

/// Exact-alarm state and settings through the Android-only `SchedulerApi`.
/// Off Android it reports [PermissionOutcome.notApplicable] and does nothing.
class SchedulerExactAlarmGateway implements ExactAlarmGateway {
  SchedulerExactAlarmGateway({required this.isAndroid, SchedulerApi? api})
    : scheduler = api ?? SchedulerApi();

  final bool isAndroid;
  final SchedulerApi scheduler;

  @override
  bool get isApplicable => isAndroid;

  @override
  Future<PermissionOutcome> status() async {
    if (!isAndroid) return PermissionOutcome.notApplicable;
    try {
      final snapshot = await scheduler.getPermissionState();
      return snapshot.exactAlarmGranted
          ? PermissionOutcome.granted
          : PermissionOutcome.denied;
    } on PlatformException {
      return PermissionOutcome.denied;
    } on MissingPluginException {
      return PermissionOutcome.denied;
    }
  }

  @override
  Future<void> openSettings() async {
    if (!isAndroid) return;
    try {
      await scheduler.openExactAlarmSettings();
    } on PlatformException {
      // The setting could not be opened; the caller keeps the app usable.
    } on MissingPluginException {
      // Same as above.
    }
  }
}

/// Opens the system's battery-optimization list with `android_intent_plus`.
/// It only opens the list; it never asks the system to ignore optimization.
class IntentBatterySettingsGateway implements BatterySettingsGateway {
  const IntentBatterySettingsGateway({required this.isAndroid});

  final bool isAndroid;

  @override
  Future<void> openBatterySettings() async {
    if (!isAndroid) return;
    try {
      await const AndroidIntent(
        action: 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS',
      ).launch();
    } on Object {
      // Some phones do not offer this page. Setup continues; the on-screen
      // steps describe the same path through the settings app.
    }
  }
}
