import 'dart:async';

import 'package:deen_mobile/data/db/app_database.dart';
import 'package:deen_mobile/data/repositories/drift_alert_log_repository.dart';
import 'package:deen_mobile/domain/alerts/alert_log_entry.dart';
import 'package:deen_mobile/domain/entities/enums.dart';
import 'package:deen_mobile/platform/playback_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schedule_planner/schedule_planner.dart' show ArbiterDecision;

final _now = DateTime.utc(2026, 10, 22, 12);

void main() {
  late AppDatabase db;
  late DriftAlertLogRepository log;
  late _FakePlayer player;
  late _FakeSession session;
  late PlaybackService service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    log = DriftAlertLogRepository(db);
    player = _FakePlayer();
    session = _FakeSession();
    service = PlaybackService(
      player: player,
      session: session,
      log: log,
      clock: () => _now,
      assetFor: (ref) => 'assets/audio/$ref.m4a',
    );
  });

  tearDown(() async {
    await service.dispose();
    await db.close();
  });

  test('configures the playback session before playing', () async {
    final outcome = await service.playFullAzaan(
      alertId: 'fajr:2026-10-22',
      audioRef: 'voice-1-fajr',
    );
    expect(outcome, PlayOutcome.started);
    expect(session.calls, ['activate']);
    expect(player.loaded, 'assets/audio/voice-1-fajr.m4a');
    expect(player.playing, isTrue);
  });

  test('records played, with the planned time kept', () async {
    final planned = _now.subtract(const Duration(seconds: 20));
    await log.syncPlanned([
      PlannedAlertRecord(alertId: 'a', fireAt: planned),
    ], now: planned.subtract(const Duration(hours: 1)));
    await service.playFullAzaan(alertId: 'a', audioRef: 'r');
    final row = (await log.forAlertIds(['a'])).single;
    expect(row.state, AlertLogState.played);
    expect(row.source, AlertLogSource.inApp);
    expect(row.plannedFireAt, planned);
    expect(row.firedAt, _now);
  });

  test('a second play for the same alert is refused', () async {
    await service.playFullAzaan(alertId: 'a', audioRef: 'r');
    await service.stop();
    player.loaded = null;
    final outcome = await service.playFullAzaan(alertId: 'a', audioRef: 'r');
    expect(outcome, PlayOutcome.alreadyPlayed);
    expect(player.loaded, isNull);
  });

  test('a suppressed verdict does not play', () async {
    final suppressedService = PlaybackService(
      player: player,
      session: session,
      log: log,
      clock: () => _now,
      arbiter: (id, ledger, {required suppressed}) =>
          ArbiterDecision.skipSuppressed,
      assetFor: (ref) => ref,
    );
    final outcome = await suppressedService.playFullAzaan(
      alertId: 'a',
      audioRef: 'r',
    );
    expect(outcome, PlayOutcome.suppressed);
    expect(player.playing, isFalse);
    expect(await log.hasPlayed('a'), isFalse);
  });

  test('a recording that cannot load fails without marking played', () async {
    player.failLoad = true;
    final outcome = await service.playFullAzaan(alertId: 'a', audioRef: 'r');
    expect(outcome, PlayOutcome.failed);
    expect(await log.hasPlayed('a'), isFalse);
    expect(session.calls.last, 'deactivate');
  });

  test(
    'stopping marks the alert acknowledged and releases the session',
    () async {
      await service.playFullAzaan(alertId: 'a', audioRef: 'r');
      await service.stop();
      expect(player.playing, isFalse);
      expect(session.calls.last, 'deactivate');
      expect(
        (await log.forAlertIds(['a'])).single.state,
        AlertLogState.acknowledged,
      );
    },
  );

  test('finishing the recording releases the session', () async {
    await service.playFullAzaan(alertId: 'a', audioRef: 'r');
    player.finish();
    await Future<void>.delayed(Duration.zero);
    expect(session.calls.last, 'deactivate');
    expect((await log.forAlertIds(['a'])).single.state, AlertLogState.played);
  });

  test('a call interrupting playback pauses it and logs suppressed', () async {
    await service.playFullAzaan(alertId: 'a', audioRef: 'r');
    session.interrupt(PlaybackInterruption.pause);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(player.playing, isFalse);
    final row = (await log.forAlertIds(['a'])).single;
    expect(row.state, AlertLogState.suppressed);
    expect(row.cause, AlertCause.callInProgress);
  });

  test('a suppressed alert may be played again by the user', () async {
    await service.playFullAzaan(alertId: 'a', audioRef: 'r');
    session.interrupt(PlaybackInterruption.pause);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final outcome = await service.playFullAzaan(alertId: 'a', audioRef: 'r');
    expect(outcome, PlayOutcome.started);
  });

  test('ducking lowers the volume and the end restores it', () async {
    await service.playFullAzaan(alertId: 'a', audioRef: 'r');
    session.interrupt(PlaybackInterruption.duck);
    await Future<void>.delayed(Duration.zero);
    expect(player.volume, lessThan(1.0));
    session.interrupt(PlaybackInterruption.end);
    await Future<void>.delayed(Duration.zero);
    expect(player.volume, 1.0);
    expect(player.playing, isTrue);
  });

  test('unplugging headphones stops playback', () async {
    await service.playFullAzaan(alertId: 'a', audioRef: 'r');
    session.unplug();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(player.playing, isFalse);
  });

  test('previews are not logged and ignore the arbiter', () async {
    await service.playFullAzaan(alertId: 'a', audioRef: 'r');
    await service.stop();
    await service.preview('voice-2-shia');
    expect(player.loaded, 'assets/audio/voice-2-shia.m4a');
    expect(player.playing, isTrue);
    await service.stopPreview();
    expect(player.playing, isFalse);
    expect((await log.recent()).length, 1);
  });

  test('a preview of a missing recording reports failure', () async {
    player.failLoad = true;
    expect(await service.preview('missing'), isFalse);
  });

  test('a preview does not count as played', () async {
    await service.preview('r');
    expect(await log.playedAlertIds(), isEmpty);
  });

  test('a new play replaces one already running', () async {
    await service.playFullAzaan(alertId: 'a', audioRef: 'r1');
    await service.playFullAzaan(alertId: 'b', audioRef: 'r2');
    expect(player.loaded, 'assets/audio/r2.m4a');
    expect(player.stops, greaterThan(0));
  });
}

class _FakePlayer implements AzaanPlayer {
  String? loaded;
  bool playing = false;
  bool failLoad = false;
  double volume = 1.0;
  int stops = 0;
  final StreamController<void> _done = StreamController<void>.broadcast();

  void finish() {
    playing = false;
    _done.add(null);
  }

  @override
  Stream<void> get completed => _done.stream;

  @override
  Future<void> load(String asset) async {
    if (failLoad) throw StateError('no such asset');
    loaded = asset;
  }

  @override
  Future<void> play() async => playing = true;

  @override
  Future<void> pause() async => playing = false;

  @override
  Future<void> stop() async {
    stops++;
    playing = false;
  }

  @override
  Future<void> setVolume(double value) async => volume = value;

  @override
  Future<void> dispose() async => _done.close();
}

class _FakeSession implements PlaybackSession {
  final List<String> calls = [];
  final StreamController<PlaybackInterruption> _interruptions =
      StreamController<PlaybackInterruption>.broadcast();
  final StreamController<void> _noisy = StreamController<void>.broadcast();

  void interrupt(PlaybackInterruption event) => _interruptions.add(event);
  void unplug() => _noisy.add(null);

  @override
  Stream<PlaybackInterruption> get interruptions => _interruptions.stream;

  @override
  Stream<void> get becomingNoisy => _noisy.stream;

  @override
  Future<void> activate() async => calls.add('activate');

  @override
  Future<void> deactivate() async => calls.add('deactivate');
}
