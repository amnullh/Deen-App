/// Imsak, midnight and the last third of the night.
///
/// Convention (stated here because scholars differ): the night runs from the
/// day's displayed Maghrib to the next day's displayed Fajr. Midnight is the
/// midpoint of that span and the last third begins two thirds of the way
/// through it. Some schools measure the night to sunrise instead, and Jafari
/// jurisprudence measures to Fajr as well; the app shows its convention next
/// to the times. Imsak is Fajr minus a configurable number of minutes.
library;

/// Fajr minus [minutes], or null when there is no Fajr.
///
/// Throws [ArgumentError] for a negative [minutes].
DateTime? imsakFor(DateTime? fajr, int minutes) {
  if (minutes < 0) {
    throw ArgumentError.value(minutes, 'imsakMinutes', 'Must not be negative');
  }
  return fajr?.subtract(Duration(minutes: minutes));
}

/// The part of a night that [midnight] and [lastThird] derive from.
class NightTimes {
  const NightTimes({required this.midnight, required this.lastThird});

  /// The midpoint of the night.
  final DateTime midnight;

  /// The start of the last third of the night.
  final DateTime lastThird;
}

/// Midnight and the last third for a night from [maghrib] to [nextFajr].
/// Null when either end is missing or the night has no positive length.
NightTimes? nightTimes(DateTime? maghrib, DateTime? nextFajr) {
  if (maghrib == null || nextFajr == null || !nextFajr.isAfter(maghrib)) {
    return null;
  }
  final micros = nextFajr.difference(maghrib).inMicroseconds;
  return NightTimes(
    midnight: maghrib.add(Duration(microseconds: micros ~/ 2)),
    lastThird: maghrib.add(Duration(microseconds: (micros * 2) ~/ 3)),
  );
}
