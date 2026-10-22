import '../entities/enums.dart';
import '../result.dart';

/// Opt-in daily adhkar reminder (spec Story 6, scenario 4). The planner and
/// the alerts layer read these settings; nothing is scheduled unless
/// [enabled] is true.
class AdhkarReminder {
  const AdhkarReminder({
    required this.kind,
    required this.anchor,
    required this.offsetMinutes,
    this.enabled = false,
  });

  /// Smallest and largest offset from the anchor prayer, in minutes. Negative
  /// means before the prayer.
  static const int minOffsetMinutes = -120;
  static const int maxOffsetMinutes = 120;

  /// Defaults while the user has not chosen: morning shortly after Fajr and
  /// evening right after Asr, both off.
  factory AdhkarReminder.defaultFor(AdhkarReminderKind kind) {
    switch (kind) {
      case AdhkarReminderKind.morning:
        return const AdhkarReminder(
          kind: AdhkarReminderKind.morning,
          anchor: ReminderAnchor.fajr,
          offsetMinutes: 30,
        );
      case AdhkarReminderKind.evening:
        return const AdhkarReminder(
          kind: AdhkarReminderKind.evening,
          anchor: ReminderAnchor.asr,
          offsetMinutes: 0,
        );
    }
  }

  final AdhkarReminderKind kind;
  final ReminderAnchor anchor;
  final int offsetMinutes;
  final bool enabled;

  /// Anchors a reminder of [kind] may use: morning follows Fajr, evening
  /// follows Asr or Maghrib.
  static List<ReminderAnchor> anchorsFor(AdhkarReminderKind kind) {
    switch (kind) {
      case AdhkarReminderKind.morning:
        return const [ReminderAnchor.fajr];
      case AdhkarReminderKind.evening:
        return const [ReminderAnchor.asr, ReminderAnchor.maghrib];
    }
  }

  AdhkarReminder copyWith({
    ReminderAnchor? anchor,
    int? offsetMinutes,
    bool? enabled,
  }) {
    return AdhkarReminder(
      kind: kind,
      anchor: anchor ?? this.anchor,
      offsetMinutes: offsetMinutes ?? this.offsetMinutes,
      enabled: enabled ?? this.enabled,
    );
  }

  /// The problem with this reminder, or null when it is valid.
  AppError? validate() {
    if (!anchorsFor(kind).contains(anchor)) {
      return AppError(
        ErrorCode.invalidArgument,
        'A ${kind.name} reminder cannot be timed against ${anchor.name}.',
      );
    }
    if (offsetMinutes < minOffsetMinutes || offsetMinutes > maxOffsetMinutes) {
      return const AppError(
        ErrorCode.invalidArgument,
        'The reminder offset must be between -120 and 120 minutes.',
      );
    }
    return null;
  }
}
