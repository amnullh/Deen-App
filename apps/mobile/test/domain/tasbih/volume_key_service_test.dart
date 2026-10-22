import 'package:deen_mobile/platform/generated/device.g.dart';
import 'package:deen_mobile/platform/volume_key_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeVolumeKeyApi implements VolumeKeyApi {
  _FakeVolumeKeyApi({this.fail = false});

  final bool fail;
  final List<bool> calls = [];

  @override
  Future<void> setEnabled(bool enabled) async {
    calls.add(enabled);
    if (fail) throw MissingPluginException();
  }

  @override
  // ignore: non_constant_identifier_names
  String get pigeonVar_messageChannelSuffix => '';

  @override
  // ignore: non_constant_identifier_names
  BinaryMessenger? get pigeonVar_binaryMessenger => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('does nothing where volume keys are not supported', () async {
    final api = _FakeVolumeKeyApi();
    final service = PigeonVolumeKeyService(api: api, supported: false);
    expect(service.isSupported, isFalse);
    await service.setEnabled(true);
    expect(api.calls, isEmpty);
  });

  test('enabling and disabling is forwarded to the platform', () async {
    final api = _FakeVolumeKeyApi();
    final service = PigeonVolumeKeyService(api: api, supported: true);
    await service.setEnabled(true);
    await service.setEnabled(false);
    expect(api.calls, [true, false]);
  });

  test('asking for the same state twice is sent once', () async {
    final api = _FakeVolumeKeyApi();
    final service = PigeonVolumeKeyService(api: api, supported: true);
    await service.setEnabled(true);
    await service.setEnabled(true);
    expect(api.calls, [true]);
  });

  test('presses are delivered only while enabled', () async {
    final service = PigeonVolumeKeyService(
      api: _FakeVolumeKeyApi(),
      supported: true,
    );
    final presses = <VolumeKey>[];
    final subscription = service.presses.listen(presses.add);

    service.onVolumeKey('up');
    await Future<void>.delayed(Duration.zero);
    expect(presses, isEmpty);

    await service.setEnabled(true);
    service.onVolumeKey('up');
    service.onVolumeKey('down');
    service.onVolumeKey('sideways');
    await Future<void>.delayed(Duration.zero);
    expect(presses, [VolumeKey.up, VolumeKey.down]);

    await service.setEnabled(false);
    service.onVolumeKey('up');
    await Future<void>.delayed(Duration.zero);
    expect(presses, hasLength(2));
    await subscription.cancel();
  });

  test('a platform failure is swallowed and leaves the keys off', () async {
    final service = PigeonVolumeKeyService(
      api: _FakeVolumeKeyApi(fail: true),
      supported: true,
    );
    await service.setEnabled(true);
    final presses = <VolumeKey>[];
    service.presses.listen(presses.add);
    service.onVolumeKey('up');
    await Future<void>.delayed(Duration.zero);
    expect(presses, isEmpty);
  });
}
