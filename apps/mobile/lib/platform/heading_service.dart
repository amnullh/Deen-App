import 'dart:async';

import '../domain/qibla/heading_filter.dart';
import 'generated/device.g.dart';

/// The compass, as the Qibla screen sees it.
abstract interface class HeadingService {
  /// False when the device has no usable compass (or the platform code is
  /// missing); the screen then shows the bearing in degrees with instructions.
  Future<bool> isAvailable();

  /// Raw readings, about ten per second. The sensors run only while somebody
  /// listens: listening starts them, cancelling stops them, so the screen only
  /// has to cancel when it is not visible (battery, plan D-6).
  Stream<HeadingReading> readings({
    required double latitude,
    required double longitude,
  });
}

/// [HeadingService] over the generated Pigeon [HeadingApi] and its
/// `streamHeadings` event channel.
class PigeonHeadingService implements HeadingService {
  /// [api] and [samples] can be replaced in tests.
  PigeonHeadingService({
    HeadingApi? api,
    Stream<HeadingSample> Function()? samples,
  }) : _api = api ?? HeadingApi(),
       _openSamples = samples ?? streamHeadings;

  final HeadingApi _api;
  final Stream<HeadingSample> Function() _openSamples;

  /// The generated function documents that it must be called once per channel.
  late final Stream<HeadingSample> _samples = _openSamples();

  @override
  Future<bool> isAvailable() async {
    try {
      return await _api.isAvailable();
    } on Object {
      // No plugin code on this platform counts as "no compass".
      return false;
    }
  }

  @override
  Stream<HeadingReading> readings({
    required double latitude,
    required double longitude,
  }) {
    late final StreamController<HeadingReading> controller;
    StreamSubscription<HeadingSample>? subscription;

    Future<void> stopSensors() async {
      await subscription?.cancel();
      subscription = null;
      try {
        await _api.stop();
      } on Object {
        // Stopping must never throw into the UI; the sensors are off anyway
        // once the listener is gone.
      }
    }

    controller = StreamController<HeadingReading>(
      onListen: () async {
        subscription = _samples.listen(
          (sample) => controller.add(_toReading(sample)),
          onError: controller.addError,
        );
        try {
          await _api.start(latitude, longitude);
        } on Object catch (error, stackTrace) {
          controller.addError(error, stackTrace);
          await stopSensors();
          await controller.close();
        }
      },
      onCancel: stopSensors,
    );
    return controller.stream;
  }

  HeadingReading _toReading(HeadingSample sample) {
    return HeadingReading(
      headingDegrees: sample.headingDegrees,
      isTrueNorth: sample.isTrueNorth,
      accuracy: compassAccuracyFrom(sample.accuracy),
      fieldStrengthMicroTesla: sample.fieldStrengthMicroTesla,
      interferenceSuspected: sample.interferenceSuspected,
      needsCalibration: sample.needsCalibration,
    );
  }
}

/// Maps the platform accuracy to the domain one.
CompassAccuracy compassAccuracyFrom(HeadingAccuracy accuracy) {
  switch (accuracy) {
    case HeadingAccuracy.high:
      return CompassAccuracy.high;
    case HeadingAccuracy.medium:
      return CompassAccuracy.medium;
    case HeadingAccuracy.low:
      return CompassAccuracy.low;
    case HeadingAccuracy.unreliable:
      return CompassAccuracy.unreliable;
  }
}
