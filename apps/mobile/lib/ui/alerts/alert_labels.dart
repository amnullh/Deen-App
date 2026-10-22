import 'package:flutter/material.dart';

import '../../domain/alerts/alert_log_entry.dart';
import '../../domain/entities/enums.dart';
import '../../l10n/generated/app_localizations.dart';

/// Localized names shared by the alert and Reliability screens.

String prayerName(AppLocalizations l10n, AlertPrayer prayer) =>
    switch (prayer) {
      AlertPrayer.fajr => l10n.prayerFajr,
      AlertPrayer.dhuhr => l10n.prayerDhuhr,
      AlertPrayer.asr => l10n.prayerAsr,
      AlertPrayer.maghrib => l10n.prayerMaghrib,
      AlertPrayer.isha => l10n.prayerIsha,
    };

String alertTypeName(AppLocalizations l10n, AlertType type) => switch (type) {
  AlertType.off => l10n.alertTypeOff,
  AlertType.silent => l10n.alertTypeSilent,
  AlertType.vibrate => l10n.alertTypeVibrate,
  AlertType.shortTone => l10n.alertTypeShortTone,
  AlertType.fullAzaan => l10n.alertTypeFullAzaan,
};

/// Whether the alert makes a sound, so quiet hours, loud mode and exact alarms
/// matter for it.
bool isAudible(AlertType type) =>
    type == AlertType.shortTone || type == AlertType.fullAzaan;

String voiceName(AppLocalizations l10n, String voiceId) {
  final number = int.tryParse(voiceId.split('-').last) ?? 1;
  return l10n.alertVoiceName(number);
}

String variantName(AppLocalizations l10n, AzaanVariant variant) =>
    switch (variant) {
      AzaanVariant.standard => l10n.alertVariantStandard,
      AzaanVariant.shia => l10n.alertVariantShia,
    };

String outputName(AppLocalizations l10n, AudioOutput output) =>
    switch (output) {
      AudioOutput.speaker => l10n.alertOutputSpeaker,
      AudioOutput.headphones => l10n.alertOutputHeadphones,
      AudioOutput.bluetooth => l10n.alertOutputBluetooth,
    };

/// The plain-language reason an alert did not do what was asked.
String causeText(AppLocalizations l10n, AlertCause? cause) => switch (cause) {
  AlertCause.exactAlarmDenied => l10n.alertCauseExactAlarmDenied,
  AlertCause.notificationDenied => l10n.alertCauseNotificationDenied,
  AlertCause.fgsBlocked => l10n.alertCauseFgsBlocked,
  AlertCause.callInProgress => l10n.alertCauseCallInProgress,
  AlertCause.quietHours => l10n.alertCauseQuietHours,
  AlertCause.silentMode => l10n.alertCauseSilentMode,
  AlertCause.batteryRestricted => l10n.alertCauseBatteryRestricted,
  AlertCause.appNotRun => l10n.alertCauseAppNotRun,
  AlertCause.scheduleEnded => l10n.alertCauseScheduleEnded,
  AlertCause.unknown || null => l10n.alertCauseUnknown,
};

String resultName(AppLocalizations l10n, AlertLogState state) =>
    switch (state) {
      AlertLogState.planned => l10n.reliabilityResultPlanned,
      AlertLogState.fired => l10n.reliabilityResultFired,
      AlertLogState.played => l10n.reliabilityResultPlayed,
      AlertLogState.acknowledged => l10n.reliabilityResultAcknowledged,
      AlertLogState.missed => l10n.reliabilityResultMissed,
      AlertLogState.possiblyMissed => l10n.reliabilityResultPossiblyMissed,
      AlertLogState.suppressed => l10n.reliabilityResultSuppressed,
      AlertLogState.failed => l10n.reliabilityResultFailed,
    };

/// "Thu 22 Oct, 5:12 AM" in the phone's own time zone and language.
String whenText(BuildContext context, DateTime instant) {
  final material = MaterialLocalizations.of(context);
  final local = instant.toLocal();
  return '${material.formatMediumDate(local)}, '
      '${material.formatTimeOfDay(TimeOfDay.fromDateTime(local))}';
}

/// A time of day from minutes after midnight.
String minutesText(BuildContext context, int minutes) {
  return MaterialLocalizations.of(context)
      .formatTimeOfDay(TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60));
}
