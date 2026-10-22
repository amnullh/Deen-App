import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/qibla/heading_filter.dart';
import '../../platform/heading_service.dart';

/// The compass. Replaced by a fake in tests.
final headingServiceProvider = Provider<HeadingService>(
  (ref) => PigeonHeadingService(),
);

/// Whether this device has a usable compass.
final compassAvailableProvider = FutureProvider.autoDispose<bool>(
  (ref) => ref.watch(headingServiceProvider).isAvailable(),
);

enum CompassStatus {
  /// Sensors are off.
  idle,

  /// Sensors were started; no reading yet.
  starting,

  /// Readings are arriving.
  running,

  /// The sensors could not be started or failed; the screen shows the bearing
  /// in degrees instead.
  failed,
}

class CompassState {
  const CompassState(this.status, [this.snapshot]);

  static const CompassState idle = CompassState(CompassStatus.idle);

  final CompassStatus status;

  /// The latest smoothed reading, once one has arrived.
  final CompassSnapshot? snapshot;
}

/// Owns the sensor subscription. The Qibla screen calls [start] while it is
/// visible and [stop] otherwise; disposing the provider stops the sensors too.
class CompassController extends Notifier<CompassState> {
  StreamSubscription<HeadingReading>? _subscription;
  final HeadingTracker _tracker = HeadingTracker();
  ({double latitude, double longitude})? _startedAt;

  @override
  CompassState build() {
    ref.onDispose(() {
      unawaited(_subscription?.cancel());
      _subscription = null;
    });
    return CompassState.idle;
  }

  /// Starts the sensors for a location. Does nothing when already started for
  /// this location, and nothing after a failure until [stop] has been called,
  /// so a broken sensor is not retried on every rebuild.
  void start({required double latitude, required double longitude}) {
    final startedAt = _startedAt;
    if (startedAt != null) {
      final moved =
          (startedAt.latitude - latitude).abs() > 0.5 ||
          (startedAt.longitude - longitude).abs() > 0.5;
      if (!moved) return;
      stop();
    }
    _startedAt = (latitude: latitude, longitude: longitude);
    _tracker.reset();
    state = const CompassState(CompassStatus.starting);
    _subscription = ref
        .read(headingServiceProvider)
        .readings(latitude: latitude, longitude: longitude)
        .listen(_onReading, onError: _onError);
  }

  /// Stops the sensors and clears the last reading.
  void stop() {
    final subscription = _subscription;
    _subscription = null;
    _startedAt = null;
    if (subscription != null) unawaited(subscription.cancel());
    state = CompassState.idle;
  }

  void _onReading(HeadingReading reading) {
    final snapshot = _tracker.add(reading);
    if (snapshot == null) return;
    state = CompassState(CompassStatus.running, snapshot);
  }

  void _onError(Object error) {
    state = const CompassState(CompassStatus.failed);
  }
}

final compassControllerProvider =
    NotifierProvider.autoDispose<CompassController, CompassState>(
      CompassController.new,
    );
