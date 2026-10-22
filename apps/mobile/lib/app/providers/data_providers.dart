import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/export/drift_app_data_store.dart';
import '../../data/export/export_file_io.dart';
import '../../data/export/settings_export_service.dart';
import '../../data/export/tasbih_settings_store.dart';
import '../../domain/delete_all_data.dart';
import '../providers.dart';
import 'adhkar_providers.dart';

/// Version shown in About and written into exports. The lead overrides it
/// with the real package version in `main`.
final appVersionProvider = Provider<String>((ref) => '0.1.0');

/// Address of the published privacy policy, or null until it exists (plan
/// D-5). The About screen shows a placeholder while it is null.
final privacyPolicyUrlProvider = Provider<String?>((ref) => null);

final exportFileSinkProvider = Provider<ExportFileSink>(
  (ref) => PlatformExportFileSink(),
);

final importFileSourceProvider = Provider<ImportFileSource>(
  (ref) => FilePickerImportSource(),
);

final tasbihSettingsStoreProvider = Provider<TasbihSettingsStore>(
  (ref) => DriftTasbihSettingsStore(ref.watch(appDatabaseProvider)),
);

/// Rebuilds the alert schedule after a settings import. The alerts layer
/// overrides it; the default does nothing.
final afterSettingsImportProvider = Provider<Future<void> Function()>(
  (ref) => () async {},
);

/// Cancels every scheduled alert for "delete all my data". The alerts layer
/// overrides it; the default does nothing.
final cancelAllScheduledAlertsProvider = Provider<Future<void> Function()>(
  (ref) => () async {},
);

/// Removes the Android alert snapshot and journal. The platform layer
/// overrides it; the default (used on iOS and in tests) has nothing to remove.
final nativeAlertFilesProvider = Provider<NativeAlertFiles>(
  (ref) => const _NoNativeAlertFiles(),
);

final settingsExportServiceProvider = Provider<SettingsExportService>((ref) {
  return SettingsExportService(
    db: ref.watch(appDatabaseProvider),
    settings: ref.watch(settingsRepositoryProvider),
    location: ref.watch(locationRepositoryProvider),
    alerts: ref.watch(alertPreferenceRepositoryProvider),
    tasbih: ref.watch(tasbihSettingsStoreProvider),
    bookmarks: ref.watch(adhkarBookmarkRepositoryProvider),
    reminders: ref.watch(adhkarReminderRepositoryProvider),
    clock: ref.watch(clockProvider),
    appVersion: ref.watch(appVersionProvider),
    onImported: ref.watch(afterSettingsImportProvider),
  );
});

final deleteAllDataProvider = Provider<DeleteAllData>((ref) {
  return DeleteAllData(
    appData: DriftAppDataStore(ref.watch(appDatabaseProvider)),
    cancelAlerts: ref.watch(cancelAllScheduledAlertsProvider),
    nativeFiles: ref.watch(nativeAlertFilesProvider),
    exportFiles: ref.watch(exportFileSinkProvider),
  );
});

class _NoNativeAlertFiles implements NativeAlertFiles {
  const _NoNativeAlertFiles();

  @override
  Future<void> deleteSnapshotAndJournal() async {}
}
