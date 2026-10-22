import '../repositories/tasbih_repository.dart';
import '../result.dart';

/// Where a count came from.
enum TapSource { touch, volumeKey }

/// What a tap did.
class TapOutcome {
  const TapOutcome._({
    required this.counted,
    required this.ignoredByLock,
    required this.count,
    required this.roundCompleted,
  });

  const TapOutcome.ignoredByLock(int count)
    : this._(
        counted: false,
        ignoredByLock: true,
        count: count,
        roundCompleted: false,
      );

  const TapOutcome.counted(int count, {required bool roundCompleted})
    : this._(
        counted: true,
        ignoredByLock: false,
        count: count,
        roundCompleted: roundCompleted,
      );

  final bool counted;

  /// A touch was ignored because the tap lock is on.
  final bool ignoredByLock;

  /// The count after the tap.
  final int count;

  /// This tap reached the target (or a later multiple of it).
  final bool roundCompleted;
}

/// Counting rules for the Tasbih screen. The screen decides what to feel and
/// hear for each [TapOutcome]; this class decides what is counted and saved.
class TasbihController {
  /// [clock] returns "now"; it is injected so tests never read the system
  /// clock. The daily total uses the date on the device's local clock.
  TasbihController({required this._repository, required this._clock});

  final TasbihRepository _repository;
  final DateTime Function() _clock;

  /// Adds one. Touches are ignored while the tap lock is on; volume keys are
  /// not, because the lock exists to stop stray touches, not deliberate presses.
  Future<TapOutcome> tap({TapSource source = TapSource.touch}) async {
    final before = await _repository.get();
    if (before.lock && source == TapSource.touch) {
      return TapOutcome.ignoredByLock(before.count);
    }
    final after = await _repository.increment(localDate(_clock()));
    return TapOutcome.counted(
      after.count,
      roundCompleted: after.count % after.target == 0,
    );
  }

  /// Sets the count to 0, but only when the user has confirmed. Returns whether
  /// it was reset.
  Future<bool> reset({required bool confirmed}) async {
    if (!confirmed) return false;
    await _repository.resetCount();
    return true;
  }

  /// Sets the target: 33, 99 or any whole number from 1 to 100000.
  Future<Result<void>> setTarget(int target) => _repository.setTarget(target);

  Future<void> setHaptics(bool value) => _repository.setOptions(haptics: value);
  Future<void> setSound(bool value) => _repository.setOptions(sound: value);
  Future<void> setKeepAwake(bool value) =>
      _repository.setOptions(keepAwake: value);
  Future<void> setVolumeKeys(bool value) =>
      _repository.setOptions(volumeKeys: value);
  Future<void> setLock(bool value) => _repository.setOptions(lock: value);

  /// `YYYY-MM-DD` on the local calendar. A UTC value is converted first.
  static String localDate(DateTime moment) {
    final local = moment.isUtc ? moment.toLocal() : moment;
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year.toString().padLeft(4, '0')}-$month-$day';
  }
}
