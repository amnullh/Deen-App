import '../alerts/alert_log_entry.dart';

/// The alert log: what was planned for each alert and what happened. It stays
/// on the device and holds no personal data beyond alert times.
abstract interface class AlertLogRepository {
  /// Makes the log's `planned` rows match [plan], the alerts the planner wants
  /// from [now] on.
  ///
  /// - An id with no row gets a `planned` row.
  /// - A `planned` row whose id is in [plan] takes the new time and cause.
  /// - A future `planned` row whose id is no longer in [plan] is removed.
  /// - A row that already has a result (fired, played, missed and so on) is
  ///   never changed: history is not rewritten, and a prayer that was already
  ///   played is not planned again (FR-005).
  Future<void> syncPlanned(
    List<PlannedAlertRecord> plan, {
    required DateTime now,
  });

  /// Inserts or replaces rows by (alert id, attempt).
  Future<void> upsertAll(List<AlertLogEntry> entries);

  /// Rows still `planned` whose time is at or before [instant].
  Future<List<AlertLogEntry>> plannedUpTo(DateTime instant);

  /// Rows for these ids (one per attempt).
  Future<List<AlertLogEntry>> forAlertIds(Iterable<String> alertIds);

  /// The newest row with a result (anything but `planned`) whose planned time
  /// is at or before [instant], or null.
  Future<AlertLogEntry?> lastResult({required DateTime instant});

  /// Newest rows first by planned time.
  Future<List<AlertLogEntry>> recent({int limit = 50});
  Stream<List<AlertLogEntry>> watchRecent({int limit = 50});

  /// Whether the arbiter ledger already holds a `played` (or later
  /// `acknowledged`) row for [alertId].
  Future<bool> hasPlayed(String alertId);

  /// Ids with a `played` or `acknowledged` row, for the arbiter's ledger.
  Future<Set<String>> playedAlertIds();

  /// Removes rows planned before [instant] so the log stays small.
  Future<void> pruneBefore(DateTime instant);

  /// Removes every row (delete-all-my-data).
  Future<void> clear();
}
