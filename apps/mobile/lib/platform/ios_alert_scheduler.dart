import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;

import '../domain/alerts/alert_log_entry.dart';
import 'alert_scheduler.dart';
import 'ios_journal.dart';

/// The alert id (and, for a full Azaan, the recording) a notification carries,
/// so a tap can start playback even on a cold start, before the schedule has
/// been rebuilt. Plain text is read as an alert id alone.
class IosNotificationPayload {
  const IosNotificationPayload({required this.alertId, this.audioRef});

  final String alertId;
  final String? audioRef;

  String encode() => audioRef == null
      ? alertId
      : jsonEncode({'alertId': alertId, 'audioRef': audioRef});

  factory IosNotificationPayload.decode(String? text) {
    if (text == null) return const IosNotificationPayload(alertId: '');
    if (text.startsWith('{')) {
      try {
        final map = jsonDecode(text) as Map<String, Object?>;
        return IosNotificationPayload(
          alertId: map['alertId']! as String,
          audioRef: map['audioRef'] as String?,
        );
      } on Object {
        return IosNotificationPayload(alertId: text);
      }
    }
    return IosNotificationPayload(alertId: text);
  }
}

/// One pending local notification request.
class IosPendingRequest {
  const IosPendingRequest({required this.id, this.payload});

  final int id;
  final String? payload;
}

/// A request to add: a non-repeating calendar trigger with explicit zone.
class IosScheduledRequest {
  const IosScheduledRequest({
    required this.id,
    required this.alertId,
    required this.title,
    required this.body,
    required this.fireAt,
    required this.timeZoneName,
    required this.payload,
    required this.playSound,
    this.soundName,
  });

  final int id;
  final String alertId;
  final String title;
  final String body;

  /// UTC instant; the trigger is built from its components in [timeZoneName].
  final DateTime fireAt;
  final String timeZoneName;
  final String payload;

  /// False for a silent notification.
  final bool playSound;

  /// Bundled clip, or null for the system default sound.
  final String? soundName;
}

class IosNotificationSettings {
  const IosNotificationSettings({
    required this.enabled,
    required this.soundEnabled,
  });

  final bool enabled;
  final bool soundEnabled;
}

/// The part of `flutter_local_notifications` the scheduler uses, so the
/// scheduler can be tested without a device.
abstract interface class IosNotificationGateway {
  /// Prepares the plugin without asking for permission. [onTap] receives the
  /// payload of a notification the user selected while the app was running.
  Future<void> initialize({required void Function(String? payload) onTap});

  /// The payload of the notification that launched the app, if one did.
  Future<String?> launchPayloadIfAny();
  Future<void> cancelAll();
  Future<void> schedule(IosScheduledRequest request);
  Future<List<IosPendingRequest>> pending();

  /// Payloads of notifications still in the notification center.
  Future<List<String?>> deliveredPayloadList();
  Future<IosNotificationSettings> settings();
  Future<void> openSettings();
}

/// [IosNotificationGateway] over the real plugin.
class FlutterLocalNotificationsGateway implements IosNotificationGateway {
  FlutterLocalNotificationsGateway([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  @override
  Future<void> initialize({
    required void Function(String? payload) onTap,
  }) async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) => onTap(response.payload),
    );
  }

  @override
  Future<String?> launchPayloadIfAny() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details == null || !details.didNotificationLaunchApp) return null;
    return details.notificationResponse?.payload;
  }

  @override
  Future<void> cancelAll() => _plugin.cancelAll();

  @override
  Future<void> schedule(IosScheduledRequest request) {
    return _plugin.zonedSchedule(
      id: request.id,
      title: request.title,
      body: request.body,
      payload: request.payload,
      scheduledDate: tz.TZDateTime.from(request.fireAt, tz.UTC),
      notificationDetails: NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBanner: true,
          presentList: true,
          presentSound: request.playSound,
          sound: request.soundName,
          threadIdentifier: 'deen-alerts',
        ),
      ),
      // Required by the API; it is ignored on iOS.
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  @override
  Future<List<IosPendingRequest>> pending() async {
    final requests = await _plugin.pendingNotificationRequests();
    return [
      for (final r in requests) IosPendingRequest(id: r.id, payload: r.payload),
    ];
  }

  @override
  Future<List<String?>> deliveredPayloadList() async {
    final active = await _plugin.getActiveNotifications();
    return [for (final n in active) n.payload];
  }

  @override
  Future<IosNotificationSettings> settings() async {
    final options = await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.checkPermissions();
    return IosNotificationSettings(
      enabled: options?.isEnabled ?? false,
      soundEnabled: options?.isSoundEnabled ?? false,
    );
  }

  @override
  Future<void> openSettings() async {
    await _plugin.openAppNotificationSettings();
  }
}

Future<bool> _requestWithPermissionHandler() async {
  final status = await Permission.notification.request();
  return status.isGranted;
}

/// iOS [AlertScheduler], written in Dart on `flutter_local_notifications`
/// (contracts/platform-scheduling.md, "Guarantees (iOS)").
///
/// - Every request is a non-repeating calendar trigger with an explicit time
///   zone. The zone is UTC, so the trigger is the same absolute instant
///   whatever the device zone is (research R-I1; spike S2 may switch to
///   time-interval triggers, which only changes [IosNotificationGateway]).
/// - At most [maxRequests] requests: the planner already budgets them, so
///   more is a bug and is refused with `budget_exceeded` before anything is
///   cancelled.
/// - Requests are added nearest first; the planner's renewal alert is the
///   latest, so it is the last request.
class IosAlertScheduler implements AlertScheduler {
  IosAlertScheduler({
    required this._gateway,
    required this.plannedPast,
    required this._clock,
    NotificationPermissionRequest? requestPermission,
    this.refreshTimeout = const Duration(seconds: 20),
  }) : _requestPermission = requestPermission ?? _requestWithPermissionHandler;

  /// iOS's pending-request limit is 64; one slot is left spare (research R-I2).
  static const int maxRequests = 63;

  /// Sound names are `<prefix><recording>.caf`. The clips are bundled as the
  /// folder reference `Sounds`; if a device shows the folder prefix is not
  /// needed, change this one constant (unverified, spike S8).
  static const String soundPrefix = 'Sounds/';
  static const String shortToneRef = 'tone-short';
  static const String testAzaanRef = 'voice-1-standard';

  static const MethodChannel _refreshChannel = MethodChannel(
    'org.deenapp.mobile/background_refresh',
  );

  final IosNotificationGateway _gateway;
  final DateTime Function() _clock;
  final NotificationPermissionRequest _requestPermission;

  /// Rows still `planned` whose time has passed: the input to delivery
  /// inference.
  final Future<List<AlertLogEntry>> Function() plannedPast;

  /// How long the platform refresh task waits for a rebuild before it is
  /// answered anyway; the system ends the task after about 30 seconds.
  final Duration refreshTimeout;

  final List<ScheduledAlert> _scheduled = [];
  final List<AlertPlatformEvent> _buffered = [];
  late final StreamController<AlertPlatformEvent> _events =
      StreamController<AlertPlatformEvent>.broadcast(onListen: _flushBuffered);

  @override
  AlertPlatform get platform => AlertPlatform.ios;

  @override
  Stream<AlertPlatformEvent> get events => _events.stream;

  /// Prepares notifications without asking for permission and delivers the tap
  /// that launched the app, if any.
  Future<void> initialize() async {
    await _gateway.initialize(onTap: _onTap);
    final launch = await _gateway.launchPayloadIfAny();
    if (launch != null) _onTap(launch);
  }

  /// Listens for the iOS background-refresh task. The platform replies to the
  /// task when this handler returns, so it waits for the rebuild.
  void attachBackgroundRefresh() {
    _refreshChannel.setMethodCallHandler((call) async {
      if (call.method != 'onRefreshWindow' || !_events.hasListener) {
        return false;
      }
      final event = RefreshWindowEvent();
      _events.add(event);
      await event.done.future.timeout(refreshTimeout, onTimeout: () {});
      return true;
    });
  }

  void dispose() {
    _refreshChannel.setMethodCallHandler(null);
    _events.close();
  }

  void _onTap(String? payload) {
    final decoded = IosNotificationPayload.decode(payload);
    if (decoded.alertId.isEmpty) return;
    final event = NotificationTappedEvent(
      decoded.alertId,
      audioRef: decoded.audioRef,
    );
    if (_events.hasListener) {
      _events.add(event);
    } else if (_buffered.length < 20) {
      _buffered.add(event);
    }
  }

  void _flushBuffered() {
    final pending = List<AlertPlatformEvent>.of(_buffered);
    _buffered.clear();
    for (final event in pending) {
      scheduleMicrotask(() => _events.add(event));
    }
  }

  @override
  Future<SchedulerResult> replaceSchedule(List<ScheduledAlert> alerts) async {
    final now = _clock().millisecondsSinceEpoch;
    final upcoming = [
      for (final a in alerts)
        if (a.fireAtEpochMs > now) a,
    ]..sort((a, b) => a.fireAtEpochMs.compareTo(b.fireAtEpochMs));
    if (upcoming.length > maxRequests) {
      return SchedulerResult(
        ok: false,
        errorCode: 'budget_exceeded',
        message: '${upcoming.length} alerts do not fit in $maxRequests.',
      );
    }
    try {
      await _gateway.cancelAll();
      _scheduled.clear();
      if (!(await _gateway.settings()).enabled) {
        return SchedulerResult(ok: false, errorCode: 'permission_denied');
      }
      final used = <int>{};
      for (final alert in upcoming) {
        await _gateway.schedule(_requestFor(alert, used));
        _scheduled.add(alert);
      }
      return SchedulerResult(ok: true);
    } on PlatformException catch (e) {
      return SchedulerResult(
        ok: false,
        errorCode: 'invalid_argument',
        message: e.code,
      );
    }
  }

  IosScheduledRequest _requestFor(ScheduledAlert alert, Set<int> used) {
    final (:playSound, :soundName) = _soundFor(alert);
    return IosScheduledRequest(
      id: _uniqueId(alert.alertId, used),
      alertId: alert.alertId,
      title: alert.title,
      body: alert.body,
      fireAt: DateTime.fromMillisecondsSinceEpoch(
        alert.fireAtEpochMs,
        isUtc: true,
      ),
      timeZoneName: 'UTC',
      payload: IosNotificationPayload(
        alertId: alert.alertId,
        audioRef: alert.delivery == DeliveryType.fullAzaan
            ? alert.audioRef
            : null,
      ).encode(),
      playSound: playSound,
      soundName: soundName,
    );
  }

  /// Silent: no sound. Vibrate: the system default sound, because iOS cannot
  /// vibrate without a sound for a local notification; with the silent switch
  /// on it vibrates instead of sounding. Short tone and full Azaan: a bundled
  /// clip of 30 seconds or less.
  ({bool playSound, String? soundName}) _soundFor(ScheduledAlert alert) {
    switch (alert.delivery) {
      case DeliveryType.silent:
        return (playSound: false, soundName: null);
      case DeliveryType.vibrate:
        return (playSound: true, soundName: null);
      case DeliveryType.shortTone:
        return (
          playSound: true,
          soundName: '$soundPrefix${alert.audioRef ?? shortToneRef}.caf',
        );
      case DeliveryType.fullAzaan:
        final ref = alert.audioRef;
        return (
          playSound: true,
          soundName: ref == null ? null : '$soundPrefix$ref.caf',
        );
    }
  }

  /// A stable 31-bit id for the system, probing past collisions.
  static int _uniqueId(String alertId, Set<int> used) {
    var hash = 0x811c9dc5;
    for (final unit in alertId.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0x7fffffff;
    }
    while (!used.add(hash)) {
      hash = (hash + 1) & 0x7fffffff;
    }
    return hash;
  }

  @override
  Future<SchedulerResult> scheduleTestAlert({
    required int delaySeconds,
    required DeliveryType delivery,
  }) async {
    final fireAt = _clock().add(Duration(seconds: delaySeconds));
    final alertId = 'test:${fireAt.millisecondsSinceEpoch}';
    final audioRef = switch (delivery) {
      DeliveryType.fullAzaan => testAzaanRef,
      DeliveryType.shortTone => shortToneRef,
      _ => null,
    };
    final alert = ScheduledAlert(
      alertId: alertId,
      fireAtEpochMs: fireAt.millisecondsSinceEpoch,
      kind: AlertKind.prayer,
      delivery: delivery,
      audioRef: audioRef,
      title: 'Deen App',
      body: '',
      stopLabel: '',
      loudMode: false,
      volumeChoice: VolumeChoiceDto.keepCurrent,
      preciseAllowed: true,
    );
    try {
      await _gateway.schedule(_requestFor(alert, <int>{}));
      return SchedulerResult(ok: true);
    } on PlatformException catch (e) {
      return SchedulerResult(
        ok: false,
        errorCode: 'invalid_argument',
        message: e.code,
      );
    }
  }

  @override
  Future<AlertPermissions> getPermissionState() async {
    final settings = await _gateway.settings();
    return AlertPermissions(
      platform: AlertPlatform.ios,
      notificationsGranted: settings.enabled,
      soundEnabled: settings.soundEnabled,
    );
  }

  @override
  Future<bool> requestNotificationPermission() async {
    try {
      return await _requestPermission();
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<void> openExactAlarmSettings() async {}

  @override
  Future<void> openBatterySettings() async {}

  @override
  Future<void> openAppNotificationSettings() => _gateway.openSettings();

  @override
  Future<List<JournalEntry>> readJournal(int sinceEpochMs) async {
    final pending = await _gateway.pending();
    final delivered = await _gateway.deliveredPayloadList();
    return IosJournal.infer(
      plannedPast: await plannedPast(),
      pendingIds: {
        for (final r in pending)
          IosNotificationPayload.decode(r.payload).alertId,
      },
      deliveredIds: {
        for (final p in delivered) IosNotificationPayload.decode(p).alertId,
      },
    );
  }

  @override
  Future<void> clearJournal() async {}

  @override
  Future<PendingSummary> getPendingSummary() async {
    final pending = await _gateway.pending();
    final now = _clock().millisecondsSinceEpoch;
    final next = [
      for (final a in _scheduled)
        if (a.fireAtEpochMs > now) a,
    ];
    return PendingSummary(
      registeredCount: pending.length,
      snapshotCount: pending.length,
      nextAlerts: next.take(5).toList(),
      runsUntilEpochMs: _scheduled.isEmpty
          ? null
          : _scheduled.last.fireAtEpochMs,
    );
  }
}
