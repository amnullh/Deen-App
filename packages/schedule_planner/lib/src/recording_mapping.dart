import 'package:prayer_engine/prayer_engine.dart';

import 'types.dart';

/// The recording id for a full Azaan (data-model recording mapping table).
///
/// Standard wording: `<voice>-fajr` at Fajr, `<voice>-standard` at the other
/// four. Shia wording: `<voice>-shia` at every prayer.
String recordingId({
  required String voiceId,
  required PlannerAzaanVariant variant,
  required Prayer prayer,
}) {
  final suffix = switch (variant) {
    PlannerAzaanVariant.shia => 'shia',
    PlannerAzaanVariant.standard => prayer == Prayer.fajr ? 'fajr' : 'standard',
  };
  return '$voiceId-$suffix';
}

/// The id of the bundled short tone.
const String shortToneId = 'tone-short';

/// The type a reminder (pre-prayer, suhoor, adhkar) uses given its prayer's
/// type: a reminder never plays a full Azaan, so `fullAzaan` becomes
/// `shortTone` (plan D-15). Other types are unchanged.
PlannerAlertType reminderType(PlannerAlertType prayerType) =>
    prayerType == PlannerAlertType.fullAzaan
    ? PlannerAlertType.shortTone
    : prayerType;

/// The type for a reminder that is its own opt-in (suhoor, adhkar). It follows
/// [reminderType], and a prayer set to `off` still gets `shortTone` because the
/// user switched the reminder on explicitly.
PlannerAlertType standaloneReminderType(PlannerAlertType prayerType) =>
    prayerType == PlannerAlertType.off
    ? PlannerAlertType.shortTone
    : reminderType(prayerType);
