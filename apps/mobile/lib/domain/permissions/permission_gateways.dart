/// The result of asking about or requesting a permission.
enum PermissionOutcome {
  granted,

  /// Refused, but the system will show the prompt again.
  denied,

  /// Refused for good; only the app settings can change it.
  permanentlyDenied,

  /// The permission does not exist on this platform (exact alarms off Android).
  notApplicable,
}

extension PermissionOutcomeX on PermissionOutcome {
  /// True when the feature works: granted, or nothing to grant.
  bool get isSatisfied =>
      this == PermissionOutcome.granted ||
      this == PermissionOutcome.notApplicable;
}

/// Notification permission. Wrapped so setup is testable without a device.
abstract interface class NotificationPermissionGateway {
  Future<PermissionOutcome> status();

  /// Shows the system prompt. Call it only after explaining why.
  Future<PermissionOutcome> request();

  /// Opens the app's page in system settings: the way back after a refusal.
  Future<void> openAppSettings();
}

/// The Android exact-alarm permission. Only meaningful on Android.
abstract interface class ExactAlarmGateway {
  /// Whether this platform has the permission at all.
  bool get isApplicable;

  /// [PermissionOutcome.notApplicable] off Android. On Android the permission
  /// is granted in system settings, so it is never "permanently" denied.
  Future<PermissionOutcome> status();

  /// Opens the system exact-alarm setting. A no-op where not applicable.
  Future<void> openSettings();
}

/// Opens the system battery settings list (Android).
abstract interface class BatterySettingsGateway {
  Future<void> openBatterySettings();
}
