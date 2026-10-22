import '../entities/enums.dart';
import '../entities/settings.dart';
import '../result.dart';

/// Per-prayer alert choices and the settings shared by all alerts.
abstract interface class AlertPreferenceRepository {
  /// All five prayers in order; prayers never saved get the defaults (short
  /// tone, standard voice, loud mode off).
  Future<List<AlertPreference>> getAll();
  Stream<List<AlertPreference>> watchAll();

  /// Validates the reminder range (5..60) and that loud mode keeps a volume
  /// choice, then saves.
  Future<Result<void>> save(AlertPreference preference);

  Future<GlobalAlertSettings> getGlobal();
  Stream<GlobalAlertSettings> watchGlobal();

  /// Validates quiet-hours minutes (0..1439) and the suhoor reminder
  /// (5..180 minutes), then saves.
  Future<Result<void>> saveGlobal(GlobalAlertSettings settings);

  /// Convenience for the five prayers in display order.
  static const List<AlertPrayer> prayers = AlertPrayer.values;
}
