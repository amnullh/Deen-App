/// App language. Arabic and Urdu are right-to-left.
enum AppLanguage {
  en,
  ar,
  ur,
  id;

  bool get isRtl => this == AppLanguage.ar || this == AppLanguage.ur;
}

/// How the saved location was chosen.
enum LocationSource { precise, approximate, city }

/// Theme preference.
enum ThemePreference { system, light, dark }

/// What an alert does when it fires (spec Story 3, scenario 1).
enum AlertType { off, silent, vibrate, shortTone, fullAzaan }

/// Which Azaan wording the user prefers (spec D3).
enum AzaanVariant { standard, shia }

/// Android loud-mode volume behavior (spec D7).
enum VolumeChoice { keepCurrent, gentleRamp }

/// Preferred audio output for the Azaan (spec Story 3, scenario 8).
enum AudioOutput { speaker, headphones, bluetooth }

/// State of a runtime permission as last read from the platform.
enum PermissionState { unknown, granted, denied }

/// The five daily prayers that carry an alert preference.
enum AlertPrayer { fajr, dhuhr, asr, maghrib, isha }

/// Where an alert stands in its life (data-model.md, alert state machine).
enum AlertLogState {
  planned,
  fired,
  played,
  acknowledged,
  missed,
  possiblyMissed,
  suppressed,
  failed,
}

/// Where a log entry came from.
enum AlertLogSource { androidJournal, iosInferred, inApp }

/// The prayer an adhkar reminder is timed against.
enum ReminderAnchor { fajr, asr, maghrib }

/// Which daily adhkar reminder a row configures.
enum AdhkarReminderKind { morning, evening }
