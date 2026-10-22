import '../../platform/alert_scheduler.dart';
import '../repositories/alert_log_repository.dart';
import 'alert_log_entry.dart';
import 'journal_importer.dart';
import 'missed_alert_detector.dart';

/// At app open: import what the platform recorded, then decide which planned
/// alerts did not happen. Returns the ones to tell the user about.
class AlertReconciler {
  const AlertReconciler({
    required this.scheduler,
    required this.log,
    this.detector = const MissedAlertDetector(),
  });

  final AlertScheduler scheduler;
  final AlertLogRepository log;
  final MissedAlertDetector detector;

  /// [scheduleRunsUntil] is the end of the schedule the app last built.
  Future<List<AlertLogEntry>> reconcile({
    required DateTime now,
    required AlertPermissions permissions,
    DateTime? scheduleRunsUntil,
  }) async {
    await JournalImportService(scheduler: scheduler, log: log).importNew();
    final result = detector.detect(
      now: now,
      pastPlanned: await log.plannedUpTo(now),
      permissions: permissions,
      scheduleRunsUntil: scheduleRunsUntil,
    );
    if (result.updates.isEmpty) return const [];

    final ended = result.scheduleEnded;
    final alreadyReported = ended == null
        ? const <AlertLogEntry>[]
        : await log.forAlertIds([ended.alertId]);
    await log.upsertAll(result.updates);

    return [
      for (final entry in result.newlyMissed)
        if (entry != ended || alreadyReported.isEmpty) entry,
    ];
  }
}
