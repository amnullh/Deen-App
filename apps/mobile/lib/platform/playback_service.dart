import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:schedule_planner/schedule_planner.dart' as planner;

import '../domain/alerts/alert_log_entry.dart';
import '../domain/entities/enums.dart';
import '../domain/repositories/alert_log_repository.dart';

/// What [PlaybackService.playFullAzaan] did.
enum PlayOutcome {
  started,

  /// The arbiter found a `played` entry for this alert id (FR-005).
  alreadyPlayed,

  /// The arbiter suppressed the alert.
  suppressed,

  /// The recording could not be loaded or started; nothing was recorded as
  /// played.
  failed,
}

/// What the audio session reports while the Azaan plays.
enum PlaybackInterruption {
  /// A call, Siri or another app took over: stop sounding.
  pause,

  /// Another sound wants to be heard over ours: play quieter.
  duck,

  /// The interruption is over.
  end,
}

/// The player, reduced to what playback needs. Real: `just_audio`.
abstract interface class AzaanPlayer {
  Future<void> load(String asset);
  Future<void> play();
  Future<void> pause();
  Future<void> stop();
  Future<void> setVolume(double value);

  /// Emits when the recording plays to its end.
  Stream<void> get completed;
  Future<void> dispose();
}

/// The audio session, reduced to what playback needs. Real: `audio_session`.
abstract interface class PlaybackSession {
  /// Configures the `.playback` category and takes audio focus.
  Future<void> activate();
  Future<void> deactivate();
  Stream<PlaybackInterruption> get interruptions;

  /// Headphones were unplugged or the route otherwise changed under us.
  Stream<void> get becomingNoisy;
}

class JustAudioAzaanPlayer implements AzaanPlayer {
  JustAudioAzaanPlayer([AudioPlayer? player])
    : _player = player ?? AudioPlayer();

  final AudioPlayer _player;

  @override
  Future<void> load(String asset) async {
    await _player.setAsset(asset);
  }

  // just_audio's play() completes when playback ends; the service does not
  // await it, so it is started without waiting here either.
  @override
  Future<void> play() async {
    unawaited(_player.play());
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> setVolume(double value) => _player.setVolume(value);

  @override
  Stream<void> get completed => _player.processingStateStream.where(
    (state) => state == ProcessingState.completed,
  );

  @override
  Future<void> dispose() => _player.dispose();
}

/// `.playback` category on iOS (in-app media plays despite the silent switch,
/// research R-I3) and a media-usage transient-focus request on Android.
class AudioSessionPlaybackSession implements PlaybackSession {
  AudioSessionPlaybackSession([Future<AudioSession>? session])
    : _session = session ?? AudioSession.instance;

  final Future<AudioSession> _session;

  @override
  Future<void> activate() async {
    final session = await _session;
    await session.configure(
      const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionMode: AVAudioSessionMode.defaultMode,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.music,
          usage: AndroidAudioUsage.media,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransient,
      ),
    );
    await session.setActive(true);
  }

  @override
  Future<void> deactivate() async {
    final session = await _session;
    await session.setActive(false);
  }

  @override
  Stream<PlaybackInterruption> get interruptions async* {
    final session = await _session;
    yield* session.interruptionEventStream.map((event) {
      if (!event.begin) return PlaybackInterruption.end;
      return event.type == AudioInterruptionType.duck
          ? PlaybackInterruption.duck
          : PlaybackInterruption.pause;
    });
  }

  @override
  Stream<void> get becomingNoisy async* {
    final session = await _session;
    yield* session.becomingNoisyEventStream;
  }
}

/// Decides whether an alert may play: the planner's `decide`, replaceable in
/// tests.
typedef ArbiterCheck = planner.ArbiterDecision Function(
  String alertId,
  planner.PlaybackLedger ledger, {
  required bool suppressed,
});

/// Maps a recording id (for example `voice-1-fajr`) to a Flutter asset path.
typedef AzaanAssetResolver = String Function(String audioRef);

String defaultAzaanAsset(String audioRef) => 'assets/audio/$audioRef.m4a';

/// In-app Azaan playback: tap-to-play on iOS and previews everywhere.
///
/// Before playing it asks the arbiter, using the alert log as the ledger, so
/// two triggers for one prayer never give two Azaans. An alert is recorded as
/// `played` once its recording has loaded, so a missing recording does not use
/// up the one allowed play.
class PlaybackService {
  PlaybackService({
    required this._player,
    required this._session,
    required this._log,
    required this._clock,
    this._arbiter = planner.decide,
    this._assetFor = defaultAzaanAsset,
  }) {
    _subscriptions
      ..add(_session.interruptions.listen(_onInterruption))
      ..add(_session.becomingNoisy.listen((_) => _pauseForInterruption()))
      ..add(_player.completed.listen((_) => _onCompleted()));
  }

  /// Volume while another sound is on top of the Azaan.
  static const double duckedVolume = 0.3;

  final AzaanPlayer _player;
  final PlaybackSession _session;
  final AlertLogRepository _log;
  final DateTime Function() _clock;
  final ArbiterCheck _arbiter;
  final AzaanAssetResolver _assetFor;
  final List<StreamSubscription<void>> _subscriptions = [];

  String? _activeAlertId;
  bool _active = false;

  /// Plays the full Azaan for [alertId] unless the arbiter refuses.
  Future<PlayOutcome> playFullAzaan({
    required String alertId,
    required String audioRef,
  }) async {
    final played = await _log.playedAlertIds();
    final decision = _arbiter(
      alertId,
      planner.InMemoryPlaybackLedger(played),
      suppressed: false,
    );
    switch (decision) {
      case planner.ArbiterDecision.skipAlreadyPlayed:
        return PlayOutcome.alreadyPlayed;
      case planner.ArbiterDecision.skipSuppressed:
        return PlayOutcome.suppressed;
      case planner.ArbiterDecision.play:
        break;
    }

    await _haltCurrent();
    try {
      await _session.activate();
      await _player.load(_assetFor(audioRef));
    } on Object {
      // A missing recording or a refused audio session must not crash the app;
      // the caller shows a plain message.
      await _release();
      return PlayOutcome.failed;
    }
    final now = _clock();
    await _recordPlayed(alertId, now);
    _activeAlertId = alertId;
    _active = true;
    await _player.setVolume(1);
    await _player.play();
    return PlayOutcome.started;
  }

  Future<void> _recordPlayed(String alertId, DateTime now) async {
    final existing = (await _log.forAlertIds([alertId]))
        .where((e) => e.attempt == 0)
        .firstOrNull;
    await _log.upsertAll([
      AlertLogEntry(
        alertId: alertId,
        plannedFireAt: existing?.plannedFireAt ?? now,
        state: AlertLogState.played,
        source: AlertLogSource.inApp,
        firedAt: now,
        cause: existing?.cause,
      ),
    ]);
  }

  /// Stops any playback. An alert that was playing is recorded as
  /// acknowledged: the user ended it.
  Future<void> stop() async {
    final alertId = _activeAlertId;
    await _haltCurrent();
    if (alertId != null) await _setState(alertId, AlertLogState.acknowledged);
  }

  /// Plays [audioRef] for the voice list. Previews are not alerts: they are
  /// not logged and do not consult the arbiter.
  /// Returns false when the recording could not be played.
  Future<bool> preview(String audioRef) async {
    await _haltCurrent();
    try {
      await _session.activate();
      await _player.load(_assetFor(audioRef));
      _active = true;
      await _player.setVolume(1);
      await _player.play();
      return true;
    } on Object {
      await _release();
      return false;
    }
  }

  Future<void> stopPreview() => _haltCurrent();

  Future<void> _haltCurrent() async {
    _activeAlertId = null;
    if (!_active) return;
    await _player.stop();
    await _release();
  }

  Future<void> _release() async {
    _active = false;
    try {
      await _session.deactivate();
    } on Object {
      // Releasing the session is best effort.
    }
  }

  void _onCompleted() {
    _activeAlertId = null;
    if (_active) unawaited(_release());
  }

  void _onInterruption(PlaybackInterruption event) {
    if (!_active) return;
    switch (event) {
      case PlaybackInterruption.pause:
        unawaited(_pauseForInterruption());
      case PlaybackInterruption.duck:
        unawaited(_player.setVolume(duckedVolume));
      case PlaybackInterruption.end:
        unawaited(_player.setVolume(1));
    }
  }

  /// A call or similar took the audio: stop, record why, and leave the alert
  /// playable again so the user can tap it once the call is over.
  Future<void> _pauseForInterruption() async {
    if (!_active) return;
    final alertId = _activeAlertId;
    await _player.pause();
    await _release();
    _activeAlertId = null;
    if (alertId != null) {
      await _setState(
        alertId,
        AlertLogState.suppressed,
        cause: AlertCause.callInProgress,
      );
    }
  }

  Future<void> _setState(
    String alertId,
    AlertLogState state, {
    AlertCause? cause,
  }) async {
    final rows = await _log.forAlertIds([alertId]);
    final row = rows.where((e) => e.attempt == 0).firstOrNull;
    if (row == null) return;
    await _log.upsertAll([row.copyWith(state: state, cause: cause)]);
  }

  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _player.dispose();
  }
}
