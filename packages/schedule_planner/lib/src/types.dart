import 'package:prayer_engine/prayer_engine.dart';

/// What an alert does when it fires (spec Story 3, scenario 1).
enum PlannerAlertType { off, silent, vibrate, shortTone, fullAzaan }

/// Which Azaan wording a prayer uses (spec clarification D3).
enum PlannerAzaanVariant { standard, shia }

/// Android loud-mode volume behaviour.
enum PlannerVolumeChoice { keepCurrent, gentleRamp }

/// A permission as last read from the platform. Only [denied] changes
/// planning; [unknown] is planned as if granted so a first launch is not
/// marked degraded before the app has asked.
enum PlannerPermission { unknown, granted, denied }

/// Which daily adhkar session a reminder is for.
enum PlannerAdhkarKind { morning, evening }

/// The prayer an adhkar reminder is timed against.
enum PlannerAdhkarAnchor { fajr, asr, maghrib }

/// Where the times are calculated for.
class PlannerLocation {
  const PlannerLocation({
    required this.latitude,
    required this.longitude,
    required this.timeZoneId,
    required this.countryCode,
  });

  final double latitude;
  final double longitude;

  /// IANA zone id of the location (not necessarily the device zone).
  final String timeZoneId;

  /// ISO 3166 alpha-2. Carried for the caller; planning does not use it.
  final String countryCode;
}

/// The calculation settings handed to the [PrayerTimeEngine].
class PlannerPrayerSettings {
  const PlannerPrayerSettings({
    required this.method,
    this.asr = AsrMethod.standard,
    this.highLatitudeRule = HighLatitudeRule.middleOfNight,
    this.offsetsMinutes = const {},
    this.imsakMinutes = 10,
  });

  final CalculationMethod method;
  final AsrMethod asr;
  final HighLatitudeRule highLatitudeRule;
  final Map<Prayer, int> offsetsMinutes;
  final int imsakMinutes;
}

/// One prayer's alert preference. Only fajr, dhuhr, asr, maghrib and isha carry
/// alerts; a preference for [Prayer.sunrise] is ignored. A prayer with no
/// preference in the list is planned as [PlannerAlertType.off].
class PlannerAlertPreference {
  const PlannerAlertPreference({
    required this.prayer,
    this.type = PlannerAlertType.shortTone,
    this.voiceId = 'voice-1',
    this.variant = PlannerAzaanVariant.standard,
    this.loudMode = false,
    this.volumeChoice = PlannerVolumeChoice.keepCurrent,
    this.preReminderMinutes,
    this.ignoreQuietHours = false,
  });

  final Prayer prayer;
  final PlannerAlertType type;
  final String voiceId;
  final PlannerAzaanVariant variant;
  final bool loudMode;
  final PlannerVolumeChoice volumeChoice;

  /// Minutes before the prayer for the pre-prayer reminder; null means none.
  final int? preReminderMinutes;

  /// Keeps this prayer's audible type (and its reminders) inside quiet hours.
  final bool ignoreQuietHours;
}

/// Quiet hours as minutes after midnight in the location's local time.
/// The range may cross midnight (22:00 to 05:00 is 1320 to 300).
class PlannerQuietHours {
  const PlannerQuietHours({
    required this.startMinutes,
    required this.endMinutes,
  }) : assert(startMinutes >= 0 && startMinutes < 1440),
       assert(endMinutes >= 0 && endMinutes < 1440);

  final int startMinutes;
  final int endMinutes;

  /// Start inclusive, end exclusive. Equal start and end mean no quiet hours.
  bool contains(int minutesAfterMidnight) {
    if (startMinutes == endMinutes) return false;
    if (startMinutes < endMinutes) {
      return minutesAfterMidnight >= startMinutes &&
          minutesAfterMidnight < endMinutes;
    }
    return minutesAfterMidnight >= startMinutes ||
        minutesAfterMidnight < endMinutes;
  }
}

/// One adhkar reminder (data-model AdhkarReminder). Morning reminders are
/// anchored to Fajr; evening reminders to Asr or Maghrib (spec Story 6).
class PlannerAdhkarReminder {
  const PlannerAdhkarReminder({
    required this.kind,
    required this.anchor,
    required this.offsetMinutes,
    this.enabled = true,
  }) : assert(
         kind == PlannerAdhkarKind.evening ||
             anchor == PlannerAdhkarAnchor.fajr,
         'A morning reminder is anchored to Fajr',
       ),
       assert(
         kind == PlannerAdhkarKind.morning ||
             anchor != PlannerAdhkarAnchor.fajr,
         'An evening reminder is anchored to Asr or Maghrib',
       );

  final PlannerAdhkarKind kind;
  final PlannerAdhkarAnchor anchor;

  /// Minutes after the anchor prayer; negative means before it.
  final int offsetMinutes;
  final bool enabled;
}

/// Settings shared by all alerts.
class PlannerGlobalSettings {
  const PlannerGlobalSettings({
    this.quietHours,
    this.suhoorReminderEnabled = false,
    this.suhoorReminderMinutes = 30,
    this.adhkarReminders = const [],
  });

  final PlannerQuietHours? quietHours;

  /// Only planned on dates for which `PlannerInput.isRamadan` is true.
  final bool suhoorReminderEnabled;

  /// Minutes before Fajr.
  final int suhoorReminderMinutes;
  final List<PlannerAdhkarReminder> adhkarReminders;
}

/// Permission states relevant to planning.
class PlannerPermissions {
  const PlannerPermissions({
    this.exactAlarm = PlannerPermission.unknown,
    this.notifications = PlannerPermission.unknown,
  });

  /// Android only; ignored on iOS.
  final PlannerPermission exactAlarm;
  final PlannerPermission notifications;
}

/// How far ahead the platform lets the planner schedule.
sealed class PlatformBudget {
  const PlatformBudget();

  /// A snapshot of [snapshotDays] local days with a renewal alert
  /// [renewalDaysBeforeEnd] days before its end (research R-A1). Zero means no
  /// renewal alert.
  const factory PlatformBudget.android({
    int snapshotDays,
    int renewalDaysBeforeEnd,
  }) = AndroidBudget;

  /// At most [maxRequests] pending requests, nearest first; the last one is the
  /// renewal alert (research R-I2).
  const factory PlatformBudget.ios({int maxRequests}) = IosBudget;
}

class AndroidBudget extends PlatformBudget {
  const AndroidBudget({this.snapshotDays = 60, this.renewalDaysBeforeEnd = 7})
    : assert(snapshotDays > 0),
      assert(renewalDaysBeforeEnd >= 0);

  final int snapshotDays;
  final int renewalDaysBeforeEnd;
}

class IosBudget extends PlatformBudget {
  const IosBudget({this.maxRequests = 63}) : assert(maxRequests >= 2);

  final int maxRequests;
}

bool _neverRamadan(String localDate) => false;

/// Everything [plan] needs. Nothing here is read from the system.
class PlannerInput {
  const PlannerInput({
    required this.location,
    required this.prayerSettings,
    required this.alertPreferences,
    required this.global,
    required this.now,
    required this.budget,
    required this.offsets,
    required this.engine,
    this.permissions = const PlannerPermissions(),
    this.language = 'en',
    this.isRamadan = _neverRamadan,
  });

  final PlannerLocation location;
  final PlannerPrayerSettings prayerSettings;
  final List<PlannerAlertPreference> alertPreferences;
  final PlannerGlobalSettings global;

  /// The injected current instant. The planner never reads the clock.
  final DateTime now;
  final PlatformBudget budget;

  /// Time-zone offsets: OS offsets when the location zone is the device zone,
  /// bundled data otherwise (research R-T1). Decides local dates and quiet
  /// hours; prayer instants are absolute.
  final OffsetResolver offsets;
  final PrayerTimeEngine engine;
  final PlannerPermissions permissions;

  /// The user's language. Text is not produced here, so it does not change the
  /// plan; it is kept so the input matches the contract.
  final String language;

  /// Whether a local date (`YYYY-MM-DD`, the Fajr day) is in Ramadan. Injected
  /// so the planner does not depend on the Hijri helper.
  final bool Function(String localDate) isRamadan;
}
