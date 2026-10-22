import '../entities/settings.dart';
import '../result.dart';

/// The saved location. It never leaves the device and is never logged.
abstract interface class LocationRepository {
  Future<AppLocation?> get();
  Stream<AppLocation?> watch();

  /// Validates latitude (-90..90), longitude (-180..180) and a non-empty zone
  /// id and country code, then saves.
  Future<Result<void>> save(AppLocation location);

  /// Removes the saved location (used by delete-all-data).
  Future<void> clear();
}
