import 'package:prayer_engine/prayer_engine.dart';

import 'os_offset_resolver.dart';

/// How far ahead the comparison looks (research R-T1).
const int tzRulesLookaheadDays = 60;

/// Whether the phone's time-zone rules and the app's bundled rules disagree for
/// the saved zone during the next [tzRulesLookaheadDays] days.
///
/// A disagreement usually means a government changed the rules after this app
/// was built, so a "time-zone rules may have changed; update the app" notice is
/// shown and the phone's offsets are used. The check only applies when the saved
/// zone is the phone's zone: for any other zone only bundled data exists and
/// there is nothing to compare.
///
/// Offsets are sampled every six hours, which catches any change of at least
/// one hour that lasts more than six hours.
bool timeZoneRulesDisagree({
  required String zoneId,
  required OsOffsetResolver os,
  required OffsetResolver bundled,
  required DateTime now,
}) {
  if (!os.usesOsFor(zoneId)) return false;
  final start = now.toUtc();
  const step = Duration(hours: 6);
  final end = start.add(const Duration(days: tzRulesLookaheadDays));
  try {
    for (var t = start; !t.isAfter(end); t = t.add(step)) {
      if (os.offsetAt(zoneId, t) != bundled.offsetAt(zoneId, t)) return true;
    }
  } on ArgumentError {
    // The bundled data has no such zone, so there is nothing to compare with.
    return false;
  }
  return false;
}
