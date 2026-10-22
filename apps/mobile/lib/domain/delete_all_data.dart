import 'result.dart';

/// Removes everything the app stores in its database.
abstract interface class AppDataStore {
  Future<void> deleteAll();
}

/// The Android alert snapshot and journal, kept in device-protected storage so
/// alarms survive a reboot. A platform-channel implementation is wired in by
/// the alerts layer; on iOS there is nothing to delete.
abstract interface class NativeAlertFiles {
  Future<void> deleteSnapshotAndJournal();
}

/// Files the app itself wrote for export. Copies the user saved elsewhere with
/// the system save sheet are outside the app and stay.
abstract interface class ExportFileCleaner {
  Future<void> deleteExportFiles();
}

/// The parts of "delete all my data", in the order they run.
enum DeleteStep { scheduledAlerts, nativeAlertFiles, database, exportFiles }

/// Some parts of the deletion failed. The others still ran.
class DeleteAllFailure extends AppError {
  DeleteAllFailure(this.failedSteps)
    : super(
        ErrorCode.unknown,
        'Some data could not be removed: '
        '${failedSteps.map((s) => s.name).join(', ')}.',
      );

  final List<DeleteStep> failedSteps;
}

/// "Delete all my data" (data-model.md, validation rules; spec Story 7).
///
/// Scheduled alerts are cancelled first so nothing fires from data that is
/// about to disappear. Every step runs even when an earlier one fails, so the
/// user is left with as little data as possible, and the failure names what
/// remains.
class DeleteAllData {
  DeleteAllData({
    required this.appData,
    required this.cancelAlerts,
    required this.nativeFiles,
    required this.exportFiles,
  });

  final AppDataStore appData;

  /// Cancels every scheduled alert (notifications and exact alarms).
  final Future<void> Function() cancelAlerts;
  final NativeAlertFiles nativeFiles;
  final ExportFileCleaner exportFiles;

  Future<Result<void>> call() async {
    final failed = <DeleteStep>[];
    Future<void> run(DeleteStep step, Future<void> Function() action) async {
      try {
        await action();
      } on Object catch (_) {
        failed.add(step);
      }
    }

    await run(DeleteStep.scheduledAlerts, cancelAlerts);
    await run(
      DeleteStep.nativeAlertFiles,
      nativeFiles.deleteSnapshotAndJournal,
    );
    await run(DeleteStep.database, appData.deleteAll);
    await run(DeleteStep.exportFiles, exportFiles.deleteExportFiles);
    return failed.isEmpty ? const Ok(null) : Err(DeleteAllFailure(failed));
  }
}
