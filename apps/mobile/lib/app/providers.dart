import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import '../data/repositories/drift_alert_preference_repository.dart';
import '../data/repositories/drift_location_repository.dart';
import '../data/repositories/drift_settings_repository.dart';
import '../domain/entities/settings.dart';
import '../domain/repositories/alert_preference_repository.dart';
import '../domain/repositories/location_repository.dart';
import '../domain/repositories/settings_repository.dart';

/// Source of "now". Injected so tests and the countdown never read the system
/// clock directly (the prayer-time engine and planner are pure for the same reason).
typedef Clock = DateTime Function();

final clockProvider = Provider<Clock>((ref) => DateTime.now);

/// The database. Overridden in `main` with the on-device file and in tests with
/// an in-memory database.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  throw StateError('appDatabaseProvider must be overridden before use.');
});

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => DriftSettingsRepository(ref.watch(appDatabaseProvider)),
);

final locationRepositoryProvider = Provider<LocationRepository>(
  (ref) => DriftLocationRepository(ref.watch(appDatabaseProvider)),
);

final alertPreferenceRepositoryProvider = Provider<AlertPreferenceRepository>(
  (ref) => DriftAlertPreferenceRepository(ref.watch(appDatabaseProvider)),
);

/// Settings, or null before setup has run.
final prayerSettingsProvider = StreamProvider<PrayerSettings?>(
  (ref) => ref.watch(settingsRepositoryProvider).watch(),
);

/// The saved location, or null before setup has run.
final locationProvider = StreamProvider<AppLocation?>(
  (ref) => ref.watch(locationRepositoryProvider).watch(),
);

final alertPreferencesProvider = StreamProvider<List<AlertPreference>>(
  (ref) => ref.watch(alertPreferenceRepositoryProvider).watchAll(),
);

final globalAlertSettingsProvider = StreamProvider<GlobalAlertSettings>(
  (ref) => ref.watch(alertPreferenceRepositoryProvider).watchGlobal(),
);
