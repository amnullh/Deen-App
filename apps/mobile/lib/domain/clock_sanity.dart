import 'entities/settings.dart';

/// Why the device clock is not trusted.
enum ClockWarning {
  /// The date is earlier than the date this app was built, so it cannot be right.
  beforeBuildDate,

  /// The clock is earlier than it was the last time the app looked.
  movedBackward,

  /// The wall clock advanced much more or less than the monotonic clock since
  /// the last look, within the same boot: someone changed the clock.
  drifted,
}

/// A reading of a clock that keeps counting while the phone sleeps and cannot
/// be changed by the user, with an id for the current boot.
class MonotonicReading {
  const MonotonicReading({required this.milliseconds, required this.bootId});

  final int milliseconds;
  final String bootId;
}

/// Source of monotonic readings, for example Android's `elapsedRealtime`.
///
/// Implementations must count time spent asleep; a clock that stops in deep
/// sleep would make every long sleep look like a clock change.
abstract interface class MonotonicSource {
  /// The current reading, or null when the platform cannot provide one.
  Future<MonotonicReading?> read();
}

/// A source that never has a reading, used until a native one exists. The
/// clock check then relies on the build date and on backward jumps only.
class NoMonotonicSource implements MonotonicSource {
  const NoMonotonicSource();

  @override
  Future<MonotonicReading?> read() async => null;
}

/// What a check found and what to remember for next time.
class ClockSanityResult {
  const ClockSanityResult({this.warning, this.sampleToStore});

  final ClockWarning? warning;

  /// The sample to persist, or null to keep the previous one.
  final ClockSample? sampleToStore;
}

/// Detects a clearly wrong device clock without a network (spec Story 2,
/// scenario 9). Three signals, in this order:
///
/// 1. The clock is before the app's build date.
/// 2. The clock went backward since the last check by more than [backwardTolerance].
/// 3. Within one boot, wall and monotonic clocks disagree by more than
///    [driftTolerance].
class ClockSanityCheck {
  const ClockSanityCheck({
    required this.buildDate,
    this.backwardTolerance = const Duration(minutes: 2),
    this.driftTolerance = const Duration(minutes: 5),
  });

  /// When this build was made (UTC).
  final DateTime buildDate;

  /// Small steps back are normal (a network time correction), so only larger
  /// ones warn.
  final Duration backwardTolerance;
  final Duration driftTolerance;

  ClockSanityResult evaluate({
    required DateTime wallNow,
    required MonotonicReading? monotonic,
    required ClockSample? previous,
  }) {
    final wallMs = wallNow.millisecondsSinceEpoch;
    final sample = ClockSample(
      wallClockMs: wallMs,
      monotonicMs: monotonic?.milliseconds ?? 0,
      bootId: monotonic?.bootId ?? '',
    );

    // An obviously wrong time must not become the reference for later checks.
    if (wallNow.isBefore(buildDate)) {
      return const ClockSanityResult(warning: ClockWarning.beforeBuildDate);
    }
    if (previous == null) return ClockSanityResult(sampleToStore: sample);

    final backwardMs = previous.wallClockMs - wallMs;
    if (backwardMs > backwardTolerance.inMilliseconds) {
      return ClockSanityResult(
        warning: ClockWarning.movedBackward,
        sampleToStore: sample,
      );
    }

    final sameBoot =
        monotonic != null &&
        monotonic.bootId.isNotEmpty &&
        monotonic.bootId == previous.bootId;
    if (sameBoot) {
      final wallDelta = wallMs - previous.wallClockMs;
      final monotonicDelta = monotonic.milliseconds - previous.monotonicMs;
      if ((wallDelta - monotonicDelta).abs() > driftTolerance.inMilliseconds) {
        return ClockSanityResult(
          warning: ClockWarning.drifted,
          sampleToStore: sample,
        );
      }
    }
    return ClockSanityResult(sampleToStore: sample);
  }
}
