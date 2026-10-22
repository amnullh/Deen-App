import 'dart:async';

import '../../platform/alert_scheduler.dart';
import '../../platform/playback_service.dart';
import 'renewal_handler.dart';

/// Sends platform events to the code that handles them: a tap on the renewal
/// notice rebuilds the schedule, and a tap on a full-Azaan notification plays
/// the Azaan in the app (iPhone tap-to-play, spec Story 3, scenario 5).
class AlertEventRouter {
  AlertEventRouter({
    required this.scheduler,
    required this.playback,
    required this.renewal,
    this.onPlayOutcome,
  });

  final AlertScheduler scheduler;

  /// Looked up on the first tap, so no audio player exists until needed.
  final PlaybackService Function() playback;
  final RenewalHandler renewal;

  /// Told what happened to a tap-to-play, so the UI can say when it failed.
  final void Function(PlayOutcome outcome)? onPlayOutcome;

  StreamSubscription<AlertPlatformEvent>? _subscription;

  void start() {
    _subscription ??= scheduler.events.listen((event) {
      if (event is NotificationTappedEvent) unawaited(_onTap(event));
    });
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  Future<void> _onTap(NotificationTappedEvent event) async {
    if (await renewal.onTapped(event.alertId)) return;
    final audioRef = event.audioRef;
    // Only a full Azaan carries a recording; Android plays it natively and a
    // tap there just opens the app.
    if (audioRef == null) return;
    onPlayOutcome?.call(
      await playback().playFullAzaan(
        alertId: event.alertId,
        audioRef: audioRef,
      ),
    );
  }
}
