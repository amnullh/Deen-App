import 'dart:async';

import 'package:flutter/foundation.dart';

import 'generated/device.g.dart';

enum VolumeKey { up, down }

/// Volume keys as counting buttons on the Tasbih screen (Android only).
abstract interface class VolumeKeyService {
  /// False off Android, where the platform offers no such interception.
  bool get isSupported;

  /// Key presses. Nothing is delivered unless [setEnabled] was called with true.
  Stream<VolumeKey> get presses;

  /// Turns interception on or off. The screen enables it only while it is
  /// visible, so the system volume is never changed without the user's
  /// opt-in. Never throws.
  Future<void> setEnabled(bool enabled);
}

/// [VolumeKeyService] over the generated [VolumeKeyApi] (commands) and
/// [VolumeKeyEvents] (presses pushed from the platform).
class PigeonVolumeKeyService implements VolumeKeyService, VolumeKeyEvents {
  /// [api] and [supported] can be replaced in tests.
  PigeonVolumeKeyService({VolumeKeyApi? api, bool? supported})
    : _api = api ?? VolumeKeyApi(),
      isSupported =
          supported ?? defaultTargetPlatform == TargetPlatform.android;

  final VolumeKeyApi _api;
  final StreamController<VolumeKey> _presses =
      StreamController<VolumeKey>.broadcast();
  bool _enabled = false;

  @override
  final bool isSupported;

  @override
  Stream<VolumeKey> get presses => _presses.stream;

  @override
  Future<void> setEnabled(bool enabled) async {
    if (!isSupported || enabled == _enabled) return;
    try {
      await _api.setEnabled(enabled);
      _enabled = enabled;
      VolumeKeyEvents.setUp(enabled ? this : null);
    } on Object {
      // No platform code (or it failed): the keys keep their normal job.
      _enabled = false;
    }
  }

  /// Called by the platform channel for each intercepted key press.
  @override
  void onVolumeKey(String direction) {
    if (!_enabled) return;
    switch (direction) {
      case 'up':
        _presses.add(VolumeKey.up);
      case 'down':
        _presses.add(VolumeKey.down);
    }
  }
}
