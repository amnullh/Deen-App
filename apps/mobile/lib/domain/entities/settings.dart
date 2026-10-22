import 'package:prayer_engine/prayer_engine.dart';

import 'enums.dart';

/// The saved location. Stored on the device only.
class AppLocation {
  const AppLocation({
    required this.source,
    required this.latitude,
    required this.longitude,
    required this.displayName,
    required this.timeZoneId,
    required this.countryCode,
    required this.updatedAt,
    this.cityId,
  });

  final LocationSource source;
  final double latitude;
  final double longitude;
  final int? cityId;
  final String displayName;

  /// IANA time zone id, for example `Asia/Riyadh`.
  final String timeZoneId;

  /// ISO 3166-1 alpha-2, upper case.
  final String countryCode;
  final DateTime updatedAt;

  Region get region => regionOf(countryCode);
}

/// Calculation, language and appearance settings.
class PrayerSettings {
  const PrayerSettings({
    required this.method,
    required this.asrMethod,
    required this.highLatitudeRule,
    required this.language,
    this.offsetsMinutes = const {},
    this.imsakMinutes = defaultImsakMinutes,
    this.hijriAdjustment = 0,
    this.dismissedSuggestionRegions = const {},
    this.theme = ThemePreference.system,
    this.textScale = 1.0,
    this.highContrast = false,
  });

  static const int defaultImsakMinutes = 10;
  static const int minOffset = -60;
  static const int maxOffset = 60;
  static const int minHijriAdjustment = -2;
  static const int maxHijriAdjustment = 2;

  final CalculationMethod method;
  final AsrMethod asrMethod;
  final HighLatitudeRule highLatitudeRule;
  final AppLanguage language;

  /// Minutes added to each prayer, -60 to +60. Missing keys mean 0.
  final Map<Prayer, int> offsetsMinutes;
  final int imsakMinutes;
  final int hijriAdjustment;

  /// Regions for which the "suggested method" banner was dismissed.
  final Set<Region> dismissedSuggestionRegions;
  final ThemePreference theme;
  final double textScale;
  final bool highContrast;

  PrayerSettings copyWith({
    CalculationMethod? method,
    AsrMethod? asrMethod,
    HighLatitudeRule? highLatitudeRule,
    AppLanguage? language,
    Map<Prayer, int>? offsetsMinutes,
    int? imsakMinutes,
    int? hijriAdjustment,
    Set<Region>? dismissedSuggestionRegions,
    ThemePreference? theme,
    double? textScale,
    bool? highContrast,
  }) {
    return PrayerSettings(
      method: method ?? this.method,
      asrMethod: asrMethod ?? this.asrMethod,
      highLatitudeRule: highLatitudeRule ?? this.highLatitudeRule,
      language: language ?? this.language,
      offsetsMinutes: offsetsMinutes ?? this.offsetsMinutes,
      imsakMinutes: imsakMinutes ?? this.imsakMinutes,
      hijriAdjustment: hijriAdjustment ?? this.hijriAdjustment,
      dismissedSuggestionRegions:
          dismissedSuggestionRegions ?? this.dismissedSuggestionRegions,
      theme: theme ?? this.theme,
      textScale: textScale ?? this.textScale,
      highContrast: highContrast ?? this.highContrast,
    );
  }
}

/// The alert chosen for one of the five prayers.
class AlertPreference {
  const AlertPreference({
    required this.prayer,
    this.type = AlertType.shortTone,
    this.voiceId = defaultVoiceId,
    this.variant = AzaanVariant.standard,
    this.loudMode = false,
    this.volumeChoice = VolumeChoice.keepCurrent,
    this.preReminderMinutes,
    this.ignoreQuietHours = false,
  });

  static const String defaultVoiceId = 'voice-1';
  static const int minReminderMinutes = 5;
  static const int maxReminderMinutes = 60;

  final AlertPrayer prayer;
  final AlertType type;
  final String voiceId;
  final AzaanVariant variant;

  /// Android only: let the Azaan override silent mode. Off by default.
  final bool loudMode;
  final VolumeChoice volumeChoice;

  /// Minutes before the prayer, 5 to 60, or null for no reminder.
  final int? preReminderMinutes;
  final bool ignoreQuietHours;

  AlertPreference copyWith({
    AlertType? type,
    String? voiceId,
    AzaanVariant? variant,
    bool? loudMode,
    VolumeChoice? volumeChoice,
    int? preReminderMinutes,
    bool clearPreReminder = false,
    bool? ignoreQuietHours,
  }) {
    return AlertPreference(
      prayer: prayer,
      type: type ?? this.type,
      voiceId: voiceId ?? this.voiceId,
      variant: variant ?? this.variant,
      loudMode: loudMode ?? this.loudMode,
      volumeChoice: volumeChoice ?? this.volumeChoice,
      preReminderMinutes: clearPreReminder
          ? null
          : (preReminderMinutes ?? this.preReminderMinutes),
      ignoreQuietHours: ignoreQuietHours ?? this.ignoreQuietHours,
    );
  }
}

/// A local time range expressed in minutes after midnight. The range may cross
/// midnight (for example 22:00 to 05:00).
class QuietHours {
  const QuietHours({required this.startMinutes, required this.endMinutes});

  final int startMinutes;
  final int endMinutes;

  /// Whether [minutesAfterMidnight] falls inside the range (start inclusive,
  /// end exclusive).
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

/// Settings shared by all alerts, plus bookkeeping the Reliability check reads.
class GlobalAlertSettings {
  const GlobalAlertSettings({
    this.audioOutput = AudioOutput.speaker,
    this.quietHours,
    this.suhoorReminderEnabled = false,
    this.suhoorReminderMinutes = 30,
    this.exactAlarmState = PermissionState.unknown,
    this.notificationPermissionState = PermissionState.unknown,
    this.silentSwitchExplained = false,
    this.setupCompleted = false,
    this.clockSample,
    this.scheduleRunsUntil,
  });

  final AudioOutput audioOutput;
  final QuietHours? quietHours;
  final bool suhoorReminderEnabled;
  final int suhoorReminderMinutes;
  final PermissionState exactAlarmState;
  final PermissionState notificationPermissionState;
  final bool silentSwitchExplained;
  final bool setupCompleted;
  final ClockSample? clockSample;
  final DateTime? scheduleRunsUntil;

  GlobalAlertSettings copyWith({
    AudioOutput? audioOutput,
    QuietHours? quietHours,
    bool clearQuietHours = false,
    bool? suhoorReminderEnabled,
    int? suhoorReminderMinutes,
    PermissionState? exactAlarmState,
    PermissionState? notificationPermissionState,
    bool? silentSwitchExplained,
    bool? setupCompleted,
    ClockSample? clockSample,
    DateTime? scheduleRunsUntil,
  }) {
    return GlobalAlertSettings(
      audioOutput: audioOutput ?? this.audioOutput,
      quietHours: clearQuietHours ? null : (quietHours ?? this.quietHours),
      suhoorReminderEnabled:
          suhoorReminderEnabled ?? this.suhoorReminderEnabled,
      suhoorReminderMinutes:
          suhoorReminderMinutes ?? this.suhoorReminderMinutes,
      exactAlarmState: exactAlarmState ?? this.exactAlarmState,
      notificationPermissionState:
          notificationPermissionState ?? this.notificationPermissionState,
      silentSwitchExplained:
          silentSwitchExplained ?? this.silentSwitchExplained,
      setupCompleted: setupCompleted ?? this.setupCompleted,
      clockSample: clockSample ?? this.clockSample,
      scheduleRunsUntil: scheduleRunsUntil ?? this.scheduleRunsUntil,
    );
  }
}

/// Wall-clock and monotonic readings taken together, used to notice clock jumps.
class ClockSample {
  const ClockSample({
    required this.wallClockMs,
    required this.monotonicMs,
    required this.bootId,
  });

  final int wallClockMs;
  final int monotonicMs;

  /// Identifies the current boot so monotonic readings are only compared within
  /// one boot.
  final String bootId;
}
