import 'dart:async';

import 'package:deen_mobile/domain/qibla/heading_filter.dart';
import 'package:deen_mobile/platform/generated/device.g.dart';
import 'package:deen_mobile/platform/heading_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeHeadingApi implements HeadingApi {
  _FakeHeadingApi({this.available = true, this.startError});

  final bool available;
  final Object? startError;
  final List<String> calls = [];

  @override
  Future<bool> isAvailable() async {
    calls.add('isAvailable');
    return available;
  }

  @override
  Future<void> start(double latitude, double longitude) async {
    calls.add('start');
    if (startError != null) throw startError!;
  }

  @override
  Future<void> stop() async {
    calls.add('stop');
  }

  @override
  // ignore: non_constant_identifier_names
  String get pigeonVar_messageChannelSuffix => '';

  @override
  // ignore: non_constant_identifier_names
  BinaryMessenger? get pigeonVar_binaryMessenger => null;
}

HeadingSample _sample(
  double heading, {
  HeadingAccuracy accuracy = HeadingAccuracy.high,
}) {
  return HeadingSample(
    headingDegrees: heading,
    isTrueNorth: true,
    accuracy: accuracy,
    fieldStrengthMicroTesla: 47,
    interferenceSuspected: false,
    needsCalibration: false,
  );
}

Future<void> _flush() => Future<void>.delayed(Duration.zero);

void main() {
  test('sensors start only when the stream is listened to', () async {
    final api = _FakeHeadingApi();
    final events = StreamController<HeadingSample>.broadcast();
    final service = PigeonHeadingService(
      api: api,
      samples: () => events.stream,
    );

    final stream = service.readings(latitude: 21.4, longitude: 39.8);
    await _flush();
    expect(api.calls, isEmpty);

    final subscription = stream.listen((_) {});
    await _flush();
    expect(api.calls, ['start']);

    await subscription.cancel();
    await _flush();
    expect(api.calls, ['start', 'stop']);
    await events.close();
  });

  test('samples are mapped to domain readings', () async {
    final events = StreamController<HeadingSample>.broadcast();
    final service = PigeonHeadingService(
      api: _FakeHeadingApi(),
      samples: () => events.stream,
    );
    final received = <HeadingReading>[];
    final subscription = service
        .readings(latitude: 0, longitude: 0)
        .listen(received.add);
    await _flush();

    events.add(_sample(212, accuracy: HeadingAccuracy.low));
    await _flush();

    expect(received, hasLength(1));
    expect(received.single.headingDegrees, 212);
    expect(received.single.accuracy, CompassAccuracy.low);
    expect(received.single.isTrueNorth, isTrue);
    expect(received.single.fieldStrengthMicroTesla, 47);
    await subscription.cancel();
    await events.close();
  });

  test('every accuracy level has a domain equivalent', () {
    expect(
      HeadingAccuracy.values.map(compassAccuracyFrom),
      CompassAccuracy.values,
    );
  });

  test('a failure to start becomes a stream error, not a crash', () async {
    final api = _FakeHeadingApi(startError: PlatformException(code: 'denied'));
    final service = PigeonHeadingService(
      api: api,
      samples: () => const Stream<HeadingSample>.empty(),
    );
    final errors = <Object>[];
    final done = Completer<void>();
    service
        .readings(latitude: 0, longitude: 0)
        .listen((_) {}, onError: errors.add, onDone: done.complete);
    await done.future.timeout(const Duration(seconds: 1));
    expect(errors, hasLength(1));
    expect(api.calls, contains('stop'));
  });

  test(
    'isAvailable is false when the platform has no compass or no plugin',
    () async {
      final none = PigeonHeadingService(
        api: _FakeHeadingApi(available: false),
        samples: () => const Stream<HeadingSample>.empty(),
      );
      expect(await none.isAvailable(), isFalse);

      final broken = PigeonHeadingService(
        api: _ThrowingAvailabilityApi(),
        samples: () => const Stream<HeadingSample>.empty(),
      );
      expect(await broken.isAvailable(), isFalse);
    },
  );

  test('can be listened to again after a cancel', () async {
    final api = _FakeHeadingApi();
    final events = StreamController<HeadingSample>.broadcast();
    final service = PigeonHeadingService(
      api: api,
      samples: () => events.stream,
    );

    for (var i = 0; i < 2; i++) {
      final s = service.readings(latitude: 0, longitude: 0).listen((_) {});
      await _flush();
      await s.cancel();
      await _flush();
    }
    expect(api.calls, ['start', 'stop', 'start', 'stop']);
    await events.close();
  });
}

class _ThrowingAvailabilityApi extends _FakeHeadingApi {
  @override
  Future<bool> isAvailable() async => throw MissingPluginException();
}
