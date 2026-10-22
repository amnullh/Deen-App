import 'package:prayer_engine/prayer_engine.dart';

import 'types.dart';

/// What an alert is for.
enum PlannedAlertKind { prayer, preReminder, suhoor, adhkarReminder, renewal }

/// How an alert is delivered after quiet-hours and reminder rules.
enum PlannedDelivery { silent, vibrate, shortTone, fullAzaan, renewal }

/// Why an alert differs from what the user asked for. The Reliability check
/// turns these into plain explanations.
enum PlannedReason {
  /// Audible type delivered as silent because it falls in quiet hours.
  silencedByQuietHours,

  /// Android exact alarms are denied; the alert is registered inexactly.
  inexactAlarm,

  /// Notifications are denied; the alert is planned but will not be shown.
  notificationsDenied,

  /// A reminder asked for a full Azaan and is delivered as a short tone.
  reminderUsesShortTone,
}

/// One alert the platform layer should deliver.
class PlannedAlert {
  const PlannedAlert({
    required this.alertId,
    required this.kind,
    required this.localDate,
    required this.fireAt,
    required this.deliveryType,
    required this.priority,
    required this.preciseAllowed,
    required this.messageKey,
    this.prayer,
    this.leadMinutes,
    this.audioRef,
    this.voiceId,
    this.variant,
    this.loudMode = false,
    this.volumeChoice = PlannerVolumeChoice.keepCurrent,
    this.reasons = const [],
  });

  /// Stable id, for example `fajr:2026-10-22` (see `alertId`).
  final String alertId;
  final PlannedAlertKind kind;

  /// The local date (in the location's zone) the id is built from.
  final String localDate;

  /// Absolute UTC instant.
  final DateTime fireAt;
  final PlannedDelivery deliveryType;

  /// Lower is nearer: the index in the final list sorted by [fireAt].
  final int priority;

  /// False when exact alarms are denied on Android.
  final bool preciseAllowed;

  /// Stable key the app localizes into title and body, for example
  /// `alert.prayer.fajr`, `alert.preReminder.asr`, `alert.suhoor`,
  /// `alert.adhkar.morning`, `alert.adhkar.evening`, `alert.renewal`.
  final String messageKey;

  /// The prayer behind the alert: the prayer itself, the prayer a pre-reminder
  /// precedes, Fajr for suhoor, the anchor for adhkar. Null for renewal.
  final Prayer? prayer;

  /// Minutes before the prayer (pre-reminder, suhoor) for the message text.
  final int? leadMinutes;

  /// Recording id for a full Azaan (`<voice>-fajr`, `<voice>-standard`,
  /// `<voice>-shia`) or the tone id (`tone-short`) for a short tone. Null for
  /// silent, vibrate and renewal.
  final String? audioRef;

  /// Voice and wording of a full Azaan; null for every other delivery.
  final String? voiceId;
  final PlannerAzaanVariant? variant;

  /// Android loud mode; only true for an audible prayer alert.
  final bool loudMode;
  final PlannerVolumeChoice volumeChoice;

  /// Ordered by [PlannedReason] index; empty when nothing was changed.
  final List<PlannedReason> reasons;

  /// A copy with a different [priority].
  PlannedAlert withPriority(int priority) => PlannedAlert(
    alertId: alertId,
    kind: kind,
    localDate: localDate,
    fireAt: fireAt,
    deliveryType: deliveryType,
    priority: priority,
    preciseAllowed: preciseAllowed,
    messageKey: messageKey,
    prayer: prayer,
    leadMinutes: leadMinutes,
    audioRef: audioRef,
    voiceId: voiceId,
    variant: variant,
    loudMode: loudMode,
    volumeChoice: volumeChoice,
    reasons: reasons,
  );

  /// JSON for the persisted snapshot and for test vectors. Instants are UTC
  /// ISO-8601 strings; enums are their names.
  Map<String, Object?> toJson() => {
    'alertId': alertId,
    'kind': kind.name,
    'localDate': localDate,
    'fireAt': fireAt.toUtc().toIso8601String(),
    'deliveryType': deliveryType.name,
    'priority': priority,
    'preciseAllowed': preciseAllowed,
    'messageKey': messageKey,
    'prayer': prayer?.name,
    'leadMinutes': leadMinutes,
    'audioRef': audioRef,
    'voiceId': voiceId,
    'variant': variant?.name,
    'loudMode': loudMode,
    'volumeChoice': volumeChoice.name,
    'reasons': [for (final r in reasons) r.name],
  };

  /// Inverse of [toJson]. Throws [FormatException] or [ArgumentError] on a
  /// malformed map.
  factory PlannedAlert.fromJson(Map<String, Object?> json) {
    T byName<T extends Enum>(List<T> values, Object? name) =>
        values.byName(name! as String);
    T? optByName<T extends Enum>(List<T> values, Object? name) =>
        name == null ? null : values.byName(name as String);
    return PlannedAlert(
      alertId: json['alertId']! as String,
      kind: byName(PlannedAlertKind.values, json['kind']),
      localDate: json['localDate']! as String,
      fireAt: DateTime.parse(json['fireAt']! as String).toUtc(),
      deliveryType: byName(PlannedDelivery.values, json['deliveryType']),
      priority: json['priority']! as int,
      preciseAllowed: json['preciseAllowed']! as bool,
      messageKey: json['messageKey']! as String,
      prayer: optByName(Prayer.values, json['prayer']),
      leadMinutes: json['leadMinutes'] as int?,
      audioRef: json['audioRef'] as String?,
      voiceId: json['voiceId'] as String?,
      variant: optByName(PlannerAzaanVariant.values, json['variant']),
      loudMode: json['loudMode']! as bool,
      volumeChoice: byName(PlannerVolumeChoice.values, json['volumeChoice']),
      reasons: [
        for (final r in json['reasons']! as List<Object?>)
          byName(PlannedReason.values, r),
      ],
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PlannedAlert &&
      other.alertId == alertId &&
      other.fireAt == fireAt &&
      other.deliveryType == deliveryType &&
      other.priority == priority &&
      other.preciseAllowed == preciseAllowed &&
      other.audioRef == audioRef &&
      other.voiceId == voiceId &&
      other.variant == variant &&
      other.kind == kind &&
      other.messageKey == messageKey &&
      other.prayer == prayer &&
      other.leadMinutes == leadMinutes &&
      other.loudMode == loudMode &&
      other.volumeChoice == volumeChoice &&
      other.reasons.length == reasons.length &&
      Iterable<int>.generate(reasons.length)
          .every((i) => other.reasons[i] == reasons[i]);

  @override
  int get hashCode =>
      Object.hash(alertId, fireAt, deliveryType, priority, audioRef, kind);

  @override
  String toString() =>
      'PlannedAlert($alertId ${fireAt.toIso8601String()} ${deliveryType.name}'
      '${reasons.isEmpty ? '' : ' $reasons'})';
}
