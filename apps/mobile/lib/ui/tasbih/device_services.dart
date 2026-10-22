import 'dart:async';

import 'package:just_audio/just_audio.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Keeps the screen on. Behind an interface so tests do not touch the platform.
abstract interface class KeepAwakeService {
  Future<void> setEnabled(bool enabled);
}

/// [KeepAwakeService] over `wakelock_plus`.
class WakelockKeepAwake implements KeepAwakeService {
  const WakelockKeepAwake();

  @override
  Future<void> setEnabled(bool enabled) async {
    try {
      await WakelockPlus.toggle(enable: enabled);
    } on Object {
      // A device that cannot hold a wake lock simply lets the screen time out.
    }
  }
}

/// The optional tap sound.
abstract interface class TickPlayer {
  Future<void> play();
  Future<void> dispose();
}

/// Plays the bundled tick with `just_audio`. The asset is optional: if it is
/// missing, or the audio plugin is unavailable, [play] does nothing instead of
/// throwing, and does not try again.
class JustAudioTickPlayer implements TickPlayer {
  JustAudioTickPlayer({
    this.assetPath = 'assets/audio/tasbih-tick.wav',
    this.loadTimeout = const Duration(seconds: 5),
  });

  final String assetPath;

  /// A plugin that never answers must not leave every tap waiting.
  final Duration loadTimeout;
  AudioPlayer? _player;
  Future<bool>? _loading;
  bool _broken = false;

  /// Loads the clip. The audio plugin can also fail asynchronously from inside
  /// the player (for example while it initializes), so the work runs in a guarded
  /// zone and any error counts as "no sound".
  Future<bool> _load() {
    final done = Completer<bool>();
    void fail(Object error, StackTrace stackTrace) {
      _broken = true;
      if (!done.isCompleted) done.complete(false);
    }

    runZonedGuarded(() async {
      final player = AudioPlayer();
      _player = player;
      await player.setAsset(assetPath).timeout(loadTimeout);
      if (!done.isCompleted) done.complete(true);
    }, fail);
    return done.future;
  }

  @override
  Future<void> play() async {
    if (_broken) return;
    final ready = await (_loading ??= _load());
    final player = _player;
    if (!ready || player == null) return;
    try {
      await player.seek(Duration.zero);
      // `play` completes when the clip ends; the tick does not wait for it.
      unawaited(player.play().catchError((Object _) {}));
    } on Object {
      _broken = true;
    }
  }

  @override
  Future<void> dispose() async {
    final player = _player;
    _player = null;
    try {
      await player?.dispose().timeout(loadTimeout);
    } on Object {
      // Nothing left to release.
    }
  }
}
