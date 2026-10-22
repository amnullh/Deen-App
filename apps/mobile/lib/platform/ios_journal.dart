import '../domain/alerts/alert_log_entry.dart';
import '../domain/entities/enums.dart';
import 'alert_scheduler.dart';

/// What iOS lets the app learn about delivery (research R-I4): it cannot be
/// told when a local notification fired, only which ones are still pending
/// and which ones are still in the notification center.
class IosJournal {
  const IosJournal._();

  /// Journal entries for alerts that were planned in the past.
  ///
  /// An alert still in the notification center was delivered, so it becomes a
  /// `fired` entry (no fire time: iOS does not say when). An alert that is no
  /// longer pending and is not in the notification center yields no entry: the
  /// user may have swiped it away, so the detector reports it as "possibly
  /// missed", never as missed. An alert that is still pending although its
  /// time has passed did not fire, and yields no entry either.
  ///
  /// Rows the app already resolved itself (for example `played` after a tap)
  /// are not in [plannedPast] and so never come back here.
  static List<JournalEntry> infer({
    required List<AlertLogEntry> plannedPast,
    required Set<String> pendingIds,
    required Set<String> deliveredIds,
  }) {
    return [
      for (final row in plannedPast)
        if (row.state == AlertLogState.planned &&
            deliveredIds.contains(row.alertId) &&
            !pendingIds.contains(row.alertId))
          JournalEntry(
            alertId: row.alertId,
            plannedAtEpochMs: row.plannedFireAt.millisecondsSinceEpoch,
            state: JournalState.fired,
          ),
    ];
  }
}
