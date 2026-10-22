import 'package:prayer_engine/prayer_engine.dart';

/// The result of [parseAlertId].
class ParsedAlertId {
  const ParsedAlertId({
    required this.kind,
    required this.localDate,
    required this.pre,
  });

  /// `fajr`, `dhuhr`, `asr`, `maghrib`, `isha`, `suhoor`, `adhkar-morning`,
  /// `adhkar-evening` or `renewal`.
  final String kind;
  final String localDate;

  /// True for the pre-prayer reminder (`:pre`).
  final bool pre;

  @override
  bool operator ==(Object other) =>
      other is ParsedAlertId &&
      other.kind == kind &&
      other.localDate == localDate &&
      other.pre == pre;

  @override
  int get hashCode => Object.hash(kind, localDate, pre);

  @override
  String toString() => 'ParsedAlertId($kind, $localDate, pre: $pre)';
}

/// Builds a stable alert id: `fajr:2026-10-22`, `fajr:2026-10-22:pre`,
/// `suhoor:2026-10-22`, `adhkar-morning:2026-10-22`, `renewal:2026-10-22`.
///
/// Throws [ArgumentError] for an unknown [kind], a malformed [localDate], or
/// [pre] on anything but a prayer.
String alertId(String kind, String localDate, {bool pre = false}) {
  if (!_kinds.contains(kind)) {
    throw ArgumentError.value(kind, 'kind', 'Unknown alert kind');
  }
  if (!_isLocalDate(localDate)) {
    throw ArgumentError.value(localDate, 'localDate', 'Expected YYYY-MM-DD');
  }
  if (pre && !_prayerKinds.contains(kind)) {
    throw ArgumentError.value(pre, 'pre', 'Only a prayer has a pre-reminder');
  }
  return '$kind:$localDate${pre ? ':pre' : ''}';
}

/// Inverse of [alertId]; null when [id] is not a well-formed alert id.
ParsedAlertId? parseAlertId(String id) {
  final parts = id.split(':');
  if (parts.length < 2 || parts.length > 3) return null;
  final kind = parts[0];
  final pre = parts.length == 3;
  if (pre && parts[2] != 'pre') return null;
  if (!_kinds.contains(kind) || !_isLocalDate(parts[1])) return null;
  if (pre && !_prayerKinds.contains(kind)) return null;
  return ParsedAlertId(kind: kind, localDate: parts[1], pre: pre);
}

final Set<String> _prayerKinds = {for (final p in alertPrayers) p.name};

final Set<String> _kinds = {
  ..._prayerKinds,
  'suhoor',
  'adhkar-morning',
  'adhkar-evening',
  'renewal',
};

bool _isLocalDate(String value) {
  try {
    parseLocalDate(value);
    return true;
  } on FormatException {
    return false;
  }
}

/// The five prayers that carry alerts, in daily order.
const List<Prayer> alertPrayers = [
  Prayer.fajr,
  Prayer.dhuhr,
  Prayer.asr,
  Prayer.maghrib,
  Prayer.isha,
];
