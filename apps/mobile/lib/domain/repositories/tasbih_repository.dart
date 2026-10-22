import '../result.dart';
import '../tasbih/tasbih_state.dart';

/// Persistence for the tasbih counter. Everything stays on the device.
abstract interface class TasbihRepository {
  /// The counter, or the defaults before the first change.
  Future<TasbihState> get();
  Stream<TasbihState> watch();

  /// Adds one to the count and one to the total of [localDate] (`YYYY-MM-DD`)
  /// in a single transaction, so a crash can never leave them disagreeing.
  Future<TasbihState> increment(String localDate);

  /// Sets the count back to 0. The target, options and daily totals stay.
  Future<TasbihState> resetCount();

  /// Saves the target (1..100000); anything else is refused.
  Future<Result<void>> setTarget(int target);

  /// Changes only the options that are given.
  Future<void> setOptions({
    bool? keepAwake,
    bool? volumeKeys,
    bool? lock,
    bool? haptics,
    bool? sound,
  });

  /// Daily totals, newest date first, at most [limit] days.
  Stream<List<TasbihDay>> watchDays({int limit = 30});
}
