import 'package:flutter_riverpod/misc.dart' show Override;

import '../data/cities/city_repository.dart';
import '../data/db/app_database.dart';
import '../domain/alerts/schedule_coordinator.dart';
import 'providers.dart';
import 'providers/alerts_providers.dart';
import 'providers/data_providers.dart';
import 'providers/setup_providers.dart';

/// Everything the running app plugs into the providers: the on-device database,
/// the bundled city list and the alert scheduler hooks used by settings import
/// and "delete all my data". Tests override the same providers with fakes.
List<Override> appOverrides({required AppDatabase database}) {
  return [
    appDatabaseProvider.overrideWithValue(database),
    citySearchRepositoryProvider.overrideWith((ref) {
      final repository = CityRepository.bundled();
      ref.onDispose(repository.close);
      return repository;
    }),
    afterSettingsImportProvider.overrideWith((ref) {
      final coordinator = ref.watch(scheduleCoordinatorProvider);
      final alerts = ref.watch(alertPreferenceRepositoryProvider);
      final settings = ref.watch(settingsRepositoryProvider);
      final locations = ref.watch(locationRepositoryProvider);
      return () async {
        // An import carries the location and settings but not the permission
        // states, so a fresh phone would otherwise be sent back through setup.
        // Treat setup as done when both are present; the Reliability check then
        // shows (and offers to fix) any permission this phone still lacks.
        final hasProfile =
            await settings.get() != null && await locations.get() != null;
        if (hasProfile) {
          final global = await alerts.getGlobal();
          if (!global.setupCompleted) {
            await alerts.saveGlobal(global.copyWith(setupCompleted: true));
          }
        }
        await coordinator.rebuild(RebuildTrigger.manual);
      };
    }),
    cancelAllScheduledAlertsProvider.overrideWith((ref) {
      final scheduler = ref.watch(alertSchedulerProvider);
      return () async {
        await scheduler.replaceSchedule(const []);
      };
    }),
    nativeAlertFilesProvider.overrideWith(
      (ref) => SchedulerNativeAlertFiles(ref.watch(alertSchedulerProvider)),
    ),
  ];
}
