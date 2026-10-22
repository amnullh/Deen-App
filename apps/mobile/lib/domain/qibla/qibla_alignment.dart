import 'heading_filter.dart';

/// Degrees within which the phone counts as pointing at the Qibla.
const double alignedEnterDegrees = 3;

/// Once aligned, the phone stays aligned until it is off by more than this, so
/// the "facing the Qibla" message does not flicker (and is not announced over
/// and over by a screen reader) at the edge.
const double alignedExitDegrees = 6;

/// How far to turn to face the Qibla: positive means turn right (clockwise),
/// negative left, in -180 up to 180. This is also the rotation of the arrow
/// relative to the top of the screen.
double relativeQiblaAngle({required double bearing, required double heading}) =>
    angleDelta(heading, bearing);

/// Whether [relativeDegrees] is close enough to zero to say "you are facing the
/// Qibla", with hysteresis through [wasAligned].
bool isAligned(double relativeDegrees, {required bool wasAligned}) {
  final limit = wasAligned ? alignedExitDegrees : alignedEnterDegrees;
  return relativeDegrees.abs() <= limit;
}

/// The whole number of degrees to turn, for "turn 20 degrees to the right".
int turnDegrees(double relativeDegrees) => relativeDegrees.abs().round();
