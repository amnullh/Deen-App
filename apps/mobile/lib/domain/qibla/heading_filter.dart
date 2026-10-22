import 'dart:collection';

/// How trustworthy the platform says the compass is.
enum CompassAccuracy { high, medium, low, unreliable }

/// One raw compass sample, independent of the platform channel types so the
/// filtering logic can be tested with synthetic sensor streams.
class HeadingReading {
  const HeadingReading({
    required this.headingDegrees,
    required this.isTrueNorth,
    required this.accuracy,
    required this.interferenceSuspected,
    required this.needsCalibration,
    this.fieldStrengthMicroTesla,
  });

  /// Clockwise from north (true north when [isTrueNorth]), 0..360.
  final double headingDegrees;
  final bool isTrueNorth;
  final CompassAccuracy accuracy;

  /// Magnetometer magnitude; null where the platform does not report it (iOS).
  final double? fieldStrengthMicroTesla;
  final bool interferenceSuspected;
  final bool needsCalibration;
}

/// What the screen shows: a smoothed heading plus debounced warnings.
class CompassSnapshot {
  const CompassSnapshot({
    required this.headingDegrees,
    required this.isTrueNorth,
    required this.accuracy,
    required this.interference,
    required this.needsCalibration,
    this.fieldStrengthMicroTesla,
  });

  /// Smoothed heading, 0 up to (but not including) 360.
  final double headingDegrees;
  final bool isTrueNorth;
  final CompassAccuracy accuracy;
  final double? fieldStrengthMicroTesla;

  /// Magnetic interference is suspected; the arrow may be wrong.
  final bool interference;

  /// The user should be asked to calibrate (move the phone in a figure eight).
  final bool needsCalibration;
}

/// Maps any angle to 0 up to (but not including) 360.
double normalizeDegrees(double degrees) => ((degrees % 360) + 360) % 360;

/// Signed shortest rotation from [from] to [to], in -180 up to 180. This is
/// what makes 359 to 1 a step of +2 degrees instead of -358.
double angleDelta(double from, double to) =>
    ((to - from + 540) % 360 + 360) % 360 - 180;

/// Returns [next] expressed as an angle that continues [previous] without a
/// jump of more than half a turn. Rotation animations use it so the arrow never
/// spins the long way round when the heading crosses north.
double unwrapAngle(double previous, double next) =>
    previous + angleDelta(previous, next);

/// Turns raw readings into a [CompassSnapshot].
///
/// * Smoothing is an exponential filter on the circle, so it is correct across
///   the 359 to 1 wrap. A large change is followed faster so the arrow does not
///   lag behind a real turn.
/// * Interference and calibration need several consecutive samples to switch
///   on and a longer clean run to switch off, so the warnings do not flicker.
///   At the platform's ten samples a second, five samples is half a second.
class HeadingTracker {
  HeadingTracker();

  static const double _slowAlpha = 0.25;
  static const double _fastAlpha = 0.6;
  static const double _fastThresholdDegrees = 30;

  /// Expected geomagnetic field at the Earth's surface, in microtesla.
  static const double _minNormalField = 25;
  static const double _maxNormalField = 65;

  static const int _jitterWindow = 10;
  static const double _jitterStepDegrees = 20;
  static const int _jitterReversals = 4;

  double? _smoothed;
  double? _lastRaw;
  final Queue<double> _recentSteps = Queue<double>();
  final _Latch _interference = _Latch(enterAfter: 5, exitAfter: 15);
  final _Latch _calibration = _Latch(enterAfter: 5, exitAfter: 15);

  /// Adds [reading]. Returns null (and changes nothing) when the heading is not
  /// a finite number.
  CompassSnapshot? add(HeadingReading reading) {
    final raw = reading.headingDegrees;
    if (!raw.isFinite) return null;

    _smoothed = _smooth(_smoothed, normalizeDegrees(raw));
    final interference = _interference.update(
      reading.interferenceSuspected ||
          _fieldOutOfRange(reading.fieldStrengthMicroTesla) ||
          _isJittering(raw),
    );
    final needsCalibration = _calibration.update(
      reading.needsCalibration ||
          reading.accuracy == CompassAccuracy.low ||
          reading.accuracy == CompassAccuracy.unreliable,
    );

    return CompassSnapshot(
      headingDegrees: _smoothed!,
      isTrueNorth: reading.isTrueNorth,
      accuracy: reading.accuracy,
      fieldStrengthMicroTesla: reading.fieldStrengthMicroTesla,
      interference: interference,
      needsCalibration: needsCalibration,
    );
  }

  /// Forgets all state; the next reading starts a fresh filter.
  void reset() {
    _smoothed = null;
    _lastRaw = null;
    _recentSteps.clear();
    _interference.reset();
    _calibration.reset();
  }

  static double _smooth(double? previous, double next) {
    if (previous == null) return next;
    final delta = angleDelta(previous, next);
    final alpha = delta.abs() > _fastThresholdDegrees ? _fastAlpha : _slowAlpha;
    return normalizeDegrees(previous + alpha * delta);
  }

  static bool _fieldOutOfRange(double? microTesla) =>
      microTesla != null &&
      (microTesla < _minNormalField || microTesla > _maxNormalField);

  /// A phone that is being turned moves one way; a disturbed compass jumps
  /// back and forth by large angles. Count the direction reversals among the
  /// recent large steps.
  bool _isJittering(double raw) {
    final last = _lastRaw;
    _lastRaw = raw;
    if (last == null) return false;
    _recentSteps.addLast(angleDelta(last, raw));
    if (_recentSteps.length > _jitterWindow) _recentSteps.removeFirst();

    var reversals = 0;
    double? previousStep;
    for (final step in _recentSteps) {
      if (step.abs() < _jitterStepDegrees) continue;
      if (previousStep != null && previousStep.sign != step.sign) reversals++;
      previousStep = step;
    }
    return reversals >= _jitterReversals;
  }
}

/// A switch that turns on after [enterAfter] consecutive true samples and off
/// after [exitAfter] consecutive false samples.
class _Latch {
  _Latch({required this.enterAfter, required this.exitAfter});

  final int enterAfter;
  final int exitAfter;
  bool _on = false;
  int _opposite = 0;

  bool update(bool condition) {
    if (condition == _on) {
      _opposite = 0;
      return _on;
    }
    _opposite++;
    if (_opposite >= (_on ? exitAfter : enterAfter)) {
      _on = condition;
      _opposite = 0;
    }
    return _on;
  }

  void reset() {
    _on = false;
    _opposite = 0;
  }
}
