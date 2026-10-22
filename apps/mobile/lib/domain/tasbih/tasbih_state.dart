/// The single active tasbih counter and its options.
class TasbihState {
  const TasbihState({
    required this.count,
    required this.target,
    required this.keepAwake,
    required this.volumeKeys,
    required this.lock,
    required this.haptics,
    required this.sound,
  });

  /// What a fresh install shows: 0 of 33, vibration on, everything else off.
  static const TasbihState initial = TasbihState(
    count: 0,
    target: defaultTarget,
    keepAwake: false,
    volumeKeys: false,
    lock: false,
    haptics: true,
    sound: false,
  );

  static const int defaultTarget = 33;
  static const int minTarget = 1;
  static const int maxTarget = 100000;

  /// The two traditional targets offered as one-tap choices.
  static const List<int> presetTargets = [33, 99];

  static bool isValidTarget(int target) =>
      target >= minTarget && target <= maxTarget;

  /// Taps since the last reset. It keeps counting past [target].
  final int count;
  final int target;

  /// Keep the screen on while the Tasbih screen is open.
  final bool keepAwake;

  /// Count with the volume keys while the screen is open (Android only).
  final bool volumeKeys;

  /// Ignore touches on the counter (volume keys still count).
  final bool lock;
  final bool haptics;
  final bool sound;

  /// How many times the target has been reached since the last reset.
  int get roundsCompleted => count ~/ target;

  /// Position inside the current round, 0 only at the very start. A finished
  /// round reads as [target], not 0, so the progress bar shows full.
  int get countInRound {
    if (count == 0) return 0;
    final remainder = count % target;
    return remainder == 0 ? target : remainder;
  }

  /// 0..1 progress through the current round.
  double get progress => countInRound / target;

  bool get isPresetTarget => presetTargets.contains(target);

  TasbihState copyWith({
    int? count,
    int? target,
    bool? keepAwake,
    bool? volumeKeys,
    bool? lock,
    bool? haptics,
    bool? sound,
  }) {
    return TasbihState(
      count: count ?? this.count,
      target: target ?? this.target,
      keepAwake: keepAwake ?? this.keepAwake,
      volumeKeys: volumeKeys ?? this.volumeKeys,
      lock: lock ?? this.lock,
      haptics: haptics ?? this.haptics,
      sound: sound ?? this.sound,
    );
  }
}

/// How many counts were made on one local date.
class TasbihDay {
  const TasbihDay(this.date, this.total);

  /// Local date as `YYYY-MM-DD`.
  final String date;
  final int total;
}
