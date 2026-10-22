// Pigeon definition for the Android alert scheduler (contracts/platform-scheduling.md).
//
// iOS scheduling is written in Dart on top of flutter_local_notifications, so
// this file generates Dart and Kotlin only. Regenerate with:
//   dart run pigeon --input pigeons/scheduling.dart
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/platform/generated/scheduling.g.dart',
    dartOptions: DartOptions(),
    kotlinOut:
        'android/app/src/main/kotlin/org/deenapp/mobile/generated/Scheduling.g.kt',
    kotlinOptions: KotlinOptions(package: 'org.deenapp.mobile.generated'),
  ),
)
enum AlertKind { prayer, preReminder, suhoor, adhkarReminder, renewal }

enum DeliveryType { silent, vibrate, shortTone, fullAzaan }

enum VolumeChoiceDto { keepCurrent, gentleRamp }

enum AudioOutputDto { speaker, headphones, bluetooth }

enum JournalState { fired, played, acknowledged, suppressed, failed }

/// One alert the planner wants delivered. Text is already localized.
class ScheduledAlert {
  ScheduledAlert({
    required this.alertId,
    required this.fireAtEpochMs,
    required this.kind,
    required this.delivery,
    required this.title,
    required this.body,
    required this.stopLabel,
    required this.loudMode,
    required this.volumeChoice,
    required this.preciseAllowed,
    this.audioRef,
    this.audioOutput,
  });

  String alertId;
  int fireAtEpochMs;
  AlertKind kind;
  DeliveryType delivery;
  String? audioRef;
  String title;
  String body;
  String stopLabel;
  bool loudMode;
  VolumeChoiceDto volumeChoice;

  /// False when exact alarms are not allowed and the alert is registered
  /// inexactly.
  bool preciseAllowed;

  /// Preferred output device for playback; null means the speaker.
  AudioOutputDto? audioOutput;
}

/// One thing the native layer did (or failed to do) for an alert.
class JournalEntry {
  JournalEntry({
    required this.alertId,
    required this.plannedAtEpochMs,
    required this.state,
    this.firedAtEpochMs,
    this.cause,
  });

  String alertId;
  int plannedAtEpochMs;
  int? firedAtEpochMs;
  JournalState state;

  /// One of the causes in data-model.md (for example `fgs_blocked`).
  String? cause;
}

class PermissionSnapshot {
  PermissionSnapshot({
    required this.notificationsGranted,
    required this.exactAlarmGranted,
    required this.batteryOptimizationIgnored,
  });

  bool notificationsGranted;
  bool exactAlarmGranted;
  bool batteryOptimizationIgnored;
}

class PendingSummary {
  PendingSummary({
    required this.registeredCount,
    required this.snapshotCount,
    required this.nextAlerts,
    this.runsUntilEpochMs,
  });

  /// Alarms currently registered with the system (the 14-day window).
  int registeredCount;

  /// Alerts held in the snapshot (about 60 days).
  int snapshotCount;
  List<ScheduledAlert> nextAlerts;

  /// End of the last alert in the snapshot.
  int? runsUntilEpochMs;
}

/// Result of an operation; native code never throws across the channel.
class SchedulerResult {
  SchedulerResult({required this.ok, this.errorCode, this.message});

  bool ok;

  /// `permission_denied`, `exact_alarm_denied`, `service_start_blocked`,
  /// `invalid_argument`.
  String? errorCode;
  String? message;
}

@HostApi()
abstract class SchedulerApi {
  /// Replaces the whole snapshot and re-registers the first 14 days.
  @async
  SchedulerResult replaceSchedule(List<ScheduledAlert> alerts);

  @async
  SchedulerResult scheduleTestAlert(int delaySeconds, DeliveryType delivery);

  PermissionSnapshot getPermissionState();

  void openExactAlarmSettings();

  void openBatterySettings();

  void openAppNotificationSettings();

  List<JournalEntry> readJournal(int sinceEpochMs);

  void clearJournal();

  PendingSummary getPendingSummary();
}

@FlutterApi()
abstract class SchedulerEvents {
  void onPermissionChanged(PermissionSnapshot snapshot);

  void onNotificationTapped(String alertId);
}
