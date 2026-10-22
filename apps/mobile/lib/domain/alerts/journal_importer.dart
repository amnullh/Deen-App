import '../../platform/alert_scheduler.dart';
import '../entities/enums.dart';
import '../repositories/alert_log_repository.dart';
import 'alert_log_entry.dart';

/// Turns native journal entries into alert-log rows.
class JournalImporter {
  const JournalImporter._();

  /// Folds [entries] into one row per alert id.
  ///
  /// Several entries can describe one alert (fired, then played, then
  /// acknowledged). The furthest state wins, the earliest fire time is kept,
  /// and the planned time and any planning cause (quiet hours, inexact alarm)
  /// of the [existing] row are kept. A row already further along than the
  /// journal (for example `played` recorded by the app after a tap) is never
  /// downgraded.
  static List<AlertLogEntry> fold(
    List<JournalEntry> entries, {
    required AlertLogSource source,
    required Map<String, AlertLogEntry> existing,
  }) {
    final byId = <String, List<JournalEntry>>{};
    for (final entry in entries) {
      byId.putIfAbsent(entry.alertId, () => []).add(entry);
    }
    return [
      for (final MapEntry(key: id, value: group) in byId.entries)
        _foldOne(id, group, source, existing[id]),
    ];
  }

  static AlertLogEntry _foldOne(
    String id,
    List<JournalEntry> group,
    AlertLogSource source,
    AlertLogEntry? existing,
  ) {
    final best = group.reduce(
      (a, b) => _rank(_stateOf(b.state)) > _rank(_stateOf(a.state)) ? b : a,
    );
    final firedTimes = [
      for (final e in group)
        if (e.firedAtEpochMs != null) e.firedAtEpochMs!,
    ]..sort();
    final journalCause =
        AlertCause.fromWire(best.cause) ??
        group
            .map((e) => AlertCause.fromWire(e.cause))
            .whereType<AlertCause>()
            .firstOrNull;

    final plannedAt =
        existing?.plannedFireAt ??
        DateTime.fromMillisecondsSinceEpoch(best.plannedAtEpochMs, isUtc: true);
    final firedAt = firedTimes.isEmpty
        ? existing?.firedAt
        : DateTime.fromMillisecondsSinceEpoch(firedTimes.first, isUtc: true);
    final cause = journalCause ?? existing?.cause;
    final state = _stateOf(best.state);

    if (existing != null &&
        existing.state != AlertLogState.planned &&
        _rank(existing.state) > _rank(state)) {
      return existing;
    }
    return AlertLogEntry(
      alertId: id,
      plannedFireAt: plannedAt,
      state: state,
      source: source,
      firedAt: firedAt,
      cause: cause,
    );
  }

  static AlertLogState _stateOf(JournalState state) => switch (state) {
    JournalState.fired => AlertLogState.fired,
    JournalState.played => AlertLogState.played,
    JournalState.acknowledged => AlertLogState.acknowledged,
    JournalState.suppressed => AlertLogState.suppressed,
    JournalState.failed => AlertLogState.failed,
  };

  static int _rank(AlertLogState state) => switch (state) {
    AlertLogState.acknowledged => 6,
    AlertLogState.played => 5,
    AlertLogState.failed => 4,
    AlertLogState.suppressed => 3,
    AlertLogState.fired => 2,
    AlertLogState.possiblyMissed => 1,
    AlertLogState.missed => 1,
    AlertLogState.planned => 0,
  };
}

/// Reads the platform journal, records it in the alert log and clears it.
class JournalImportService {
  const JournalImportService({required this.scheduler, required this.log});

  final AlertScheduler scheduler;
  final AlertLogRepository log;

  /// Imports everything the platform has and returns how many rows changed.
  /// The native journal is cleared only after the rows are saved, so a crash
  /// in between re-imports the same entries (saving is idempotent).
  Future<int> importNew() async {
    final entries = await scheduler.readJournal(0);
    if (entries.isEmpty) return 0;
    final source = scheduler.platform == AlertPlatform.ios
        ? AlertLogSource.iosInferred
        : AlertLogSource.androidJournal;
    final existing = await log.forAlertIds({
      for (final e in entries) e.alertId,
    });
    final rows = JournalImporter.fold(
      entries,
      source: source,
      existing: {
        for (final row in existing)
          if (row.attempt == 0) row.alertId: row,
      },
    );
    await log.upsertAll(rows);
    await scheduler.clearJournal();
    return rows.length;
  }
}
