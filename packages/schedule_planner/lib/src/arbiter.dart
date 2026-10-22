/// The record of which alerts have already played. The caller owns it (a drift
/// table in the app, the journal on Android).
abstract interface class PlaybackLedger {
  bool hasPlayed(String alertId);
  void markPlayed(String alertId, DateTime at);
}

/// What to do when an alert is about to play.
enum ArbiterDecision { play, skipAlreadyPlayed, skipSuppressed }

/// Decides whether [alertId] may play. At most one `play` per alert id.
///
/// `skipAlreadyPlayed` wins over `skipSuppressed`: a played alert never plays
/// again whatever else is going on. This function never writes to the
/// [ledger]; the caller marks the alert played after playback starts.
ArbiterDecision decide(
  String alertId,
  PlaybackLedger ledger, {
  required bool suppressed,
}) {
  if (ledger.hasPlayed(alertId)) return ArbiterDecision.skipAlreadyPlayed;
  if (suppressed) return ArbiterDecision.skipSuppressed;
  return ArbiterDecision.play;
}

/// A ledger held in memory, for tests and for callers that persist elsewhere.
class InMemoryPlaybackLedger implements PlaybackLedger {
  InMemoryPlaybackLedger([Iterable<String> played = const []]) {
    for (final id in played) {
      _played[id] = null;
    }
  }

  final Map<String, DateTime?> _played = {};

  @override
  bool hasPlayed(String alertId) => _played.containsKey(alertId);

  @override
  void markPlayed(String alertId, DateTime at) => _played[alertId] = at;

  /// When [alertId] was marked played; null if never or seeded without a time.
  DateTime? playedAt(String alertId) => _played[alertId];
}
