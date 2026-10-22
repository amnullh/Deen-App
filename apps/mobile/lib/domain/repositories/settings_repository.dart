import '../entities/settings.dart';
import '../result.dart';

/// Calculation, language and appearance settings. Null means setup has not run.
abstract interface class SettingsRepository {
  Future<PrayerSettings?> get();
  Stream<PrayerSettings?> watch();

  /// Validates ranges (offsets -60..60, Hijri -2..2, Imsak 0..120, text scale
  /// 0.8..2.0) and saves, or returns an [Err] without changing anything.
  Future<Result<void>> save(PrayerSettings settings);
}
