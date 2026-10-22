import 'dart:async';

import 'package:deen_mobile/domain/alerts/alert_log_entry.dart';
import 'package:deen_mobile/domain/entities/enums.dart';
import 'package:deen_mobile/platform/alert_scheduler.dart';
import 'package:deen_mobile/platform/ios_alert_scheduler.dart';
import 'package:deen_mobile/platform/ios_journal.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime.utc(2026, 10, 22, 12);

ScheduledAlert _alert(
  String id,
  Duration after, {
  AlertKind kind = AlertKind.prayer,
  DeliveryType delivery = DeliveryType.shortTone,
  String? audioRef,
}) => ScheduledAlert(
  alertId: id,
  fireAtEpochMs: _now.add(after).millisecondsSinceEpoch,
  kind: kind,
  delivery: delivery,
  audioRef: audioRef,
  title: 'T $id',
  body: 'B $id',
  stopLabel: 'Stop',
  loudMode: false,
  volumeChoice: VolumeChoiceDto.keepCurrent,
  preciseAllowed: true,
);

AlertLogEntry _planned(String id, Duration after) => AlertLogEntry(
  alertId: id,
  plannedFireAt: _now.add(after),
  state: AlertLogState.planned,
  source: AlertLogSource.inApp,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeGateway gateway;
  late List<AlertLogEntry> plannedRows;
  late IosAlertScheduler scheduler;

  setUp(() {
    gateway = _FakeGateway();
    plannedRows = [];
    scheduler = IosAlertScheduler(
      gateway: gateway,
      plannedPast: () async => plannedRows,
      clock: () => _now,
      requestPermission: () async => true,
    );
  });

  tearDown(() => scheduler.dispose());

  group('replaceSchedule', () {
    test('cancels everything then adds requests nearest first', () async {
      final result = await scheduler.replaceSchedule([
        _alert('b', const Duration(hours: 5)),
        _alert('a', const Duration(hours: 2)),
      ]);
      expect(result.ok, isTrue);
      expect(gateway.log.first, 'cancelAll');
      expect(gateway.scheduled.map((r) => r.alertId), ['a', 'b']);
    });

    test('uses an explicit UTC time zone and the exact instant', () async {
      await scheduler.replaceSchedule([_alert('a', const Duration(hours: 2))]);
      final request = gateway.scheduled.single;
      expect(request.fireAt.isUtc, isTrue);
      expect(request.fireAt, _now.add(const Duration(hours: 2)));
      expect(request.timeZoneName, 'UTC');
    });

    test('accepts exactly 63 requests and refuses 64', () async {
      final fits = [
        for (var i = 0; i < 63; i++) _alert('a$i', Duration(hours: i + 1)),
      ];
      expect((await scheduler.replaceSchedule(fits)).ok, isTrue);
      expect(gateway.scheduled, hasLength(63));

      gateway.log.clear();
      final tooMany = [...fits, _alert('a63', const Duration(hours: 99))];
      final result = await scheduler.replaceSchedule(tooMany);
      expect(result.ok, isFalse);
      expect(result.errorCode, 'budget_exceeded');
      expect(gateway.log, isNot(contains('cancelAll')));
    });

    test('keeps the renewal alert as the last request', () async {
      await scheduler.replaceSchedule([
        _alert(
          'renewal:2026-11-01',
          const Duration(days: 9),
          kind: AlertKind.renewal,
        ),
        _alert('a', const Duration(hours: 2)),
        _alert('b', const Duration(days: 8)),
      ]);
      expect(gateway.scheduled.last.alertId, 'renewal:2026-11-01');
    });

    test('skips alerts whose time has already passed', () async {
      await scheduler.replaceSchedule([
        _alert('past', const Duration(minutes: -5)),
        _alert('future', const Duration(minutes: 5)),
      ]);
      expect(gateway.scheduled.map((r) => r.alertId), ['future']);
    });

    test('carries the alert id and recording in the payload', () async {
      await scheduler.replaceSchedule([
        _alert(
          'fajr:2026-10-23',
          const Duration(hours: 9),
          delivery: DeliveryType.fullAzaan,
          audioRef: 'voice-1-fajr',
        ),
      ]);
      final payload = IosNotificationPayload.decode(
        gateway.scheduled.single.payload,
      );
      expect(payload.alertId, 'fajr:2026-10-23');
      expect(payload.audioRef, 'voice-1-fajr');
    });

    test('maps delivery types to sounds', () async {
      await scheduler.replaceSchedule([
        _alert(
          'silent',
          const Duration(hours: 1),
          delivery: DeliveryType.silent,
        ),
        _alert(
          'vibrate',
          const Duration(hours: 2),
          delivery: DeliveryType.vibrate,
        ),
        _alert('tone', const Duration(hours: 3), audioRef: 'tone-short'),
        _alert(
          'azaan',
          const Duration(hours: 4),
          delivery: DeliveryType.fullAzaan,
          audioRef: 'voice-1-standard',
        ),
      ]);
      final byId = {for (final r in gateway.scheduled) r.alertId: r};
      expect(byId['silent']!.playSound, isFalse);
      expect(byId['silent']!.soundName, isNull);
      expect(byId['vibrate']!.playSound, isTrue);
      expect(byId['vibrate']!.soundName, isNull);
      expect(
        byId['tone']!.soundName,
        '${IosAlertScheduler.soundPrefix}tone-short.caf',
      );
      expect(
        byId['azaan']!.soundName,
        '${IosAlertScheduler.soundPrefix}voice-1-standard.caf',
      );
    });

    test('ids of different alerts never collide', () async {
      final alerts = [
        for (var d = 0; d < 20; d++)
          for (final p in ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'])
            _alert('$p:2026-11-${d + 1}', Duration(hours: d * 5 + 1)),
      ];
      await scheduler.replaceSchedule(alerts.take(63).toList());
      final ids = gateway.scheduled.map((r) => r.id).toSet();
      expect(ids, hasLength(63));
    });

    test('a platform error is returned, not thrown', () async {
      gateway.failOnSchedule = true;
      final result = await scheduler.replaceSchedule([
        _alert('a', const Duration(hours: 1)),
      ]);
      expect(result.ok, isFalse);
      expect(result.errorCode, 'invalid_argument');
    });

    test(
      'with notifications refused it clears pending and reports it',
      () async {
        gateway.enabled = false;
        final result = await scheduler.replaceSchedule([
          _alert('a', const Duration(hours: 1)),
        ]);
        expect(result.errorCode, 'permission_denied');
        expect(gateway.scheduled, isEmpty);
      },
    );
  });

  test('scheduleTestAlert schedules one request after the delay', () async {
    final result = await scheduler.scheduleTestAlert(
      delaySeconds: 60,
      delivery: DeliveryType.fullAzaan,
    );
    expect(result.ok, isTrue);
    final request = gateway.scheduled.single;
    expect(request.fireAt, _now.add(const Duration(seconds: 60)));
    expect(
      IosNotificationPayload.decode(request.payload).alertId,
      startsWith('test:'),
    );
    expect(request.soundName, isNotNull);
  });

  test('a test alert does not cancel the real schedule', () async {
    await scheduler.replaceSchedule([_alert('a', const Duration(hours: 1))]);
    await scheduler.scheduleTestAlert(
      delaySeconds: 60,
      delivery: DeliveryType.shortTone,
    );
    expect(gateway.log.where((e) => e == 'cancelAll'), hasLength(1));
    expect(gateway.scheduled, hasLength(2));
  });

  group('permissions', () {
    test('maps the notification settings', () async {
      gateway.enabled = true;
      gateway.soundEnabled = false;
      final state = await scheduler.getPermissionState();
      expect(state.platform, AlertPlatform.ios);
      expect(state.notificationsGranted, isTrue);
      expect(state.soundEnabled, isFalse);
      expect(state.exactAlarmApplicable, isFalse);
    });

    test('requestNotificationPermission delegates', () async {
      expect(await scheduler.requestNotificationPermission(), isTrue);
    });

    test('Android-only settings are no-ops', () async {
      await scheduler.openExactAlarmSettings();
      await scheduler.openBatterySettings();
      expect(gateway.log, isNot(contains('openSettings')));
    });

    test('openAppNotificationSettings opens settings', () async {
      await scheduler.openAppNotificationSettings();
      expect(gateway.log, contains('openSettings'));
    });
  });

  group('pending summary', () {
    test('lists the next five alerts and the end of the schedule', () async {
      await scheduler.replaceSchedule([
        for (var i = 0; i < 8; i++) _alert('a$i', Duration(hours: i + 1)),
      ]);
      final summary = await scheduler.getPendingSummary();
      expect(summary.registeredCount, 8);
      expect(summary.nextAlerts.map((a) => a.alertId), [
        'a0',
        'a1',
        'a2',
        'a3',
        'a4',
      ]);
      expect(
        summary.runsUntilEpochMs,
        _now.add(const Duration(hours: 8)).millisecondsSinceEpoch,
      );
    });

    test('without a schedule built it still counts pending requests', () async {
      gateway.pendingFromOutside = [
        const IosPendingRequest(id: 1, payload: 'x'),
      ];
      final summary = await scheduler.getPendingSummary();
      expect(summary.registeredCount, 1);
      expect(summary.nextAlerts, isEmpty);
    });
  });

  group('journal inference', () {
    test('delivered alerts that are no longer pending become fired', () async {
      plannedRows = [
        _planned('a', const Duration(hours: -3)),
        _planned('b', const Duration(hours: -2)),
        _planned('c', const Duration(hours: -1)),
      ];
      gateway.deliveredPayloads = [
        IosNotificationPayload(alertId: 'a').encode(),
      ];
      gateway.pendingFromOutside = [
        IosPendingRequest(
          id: 9,
          payload: IosNotificationPayload(alertId: 'c').encode(),
        ),
      ];
      final entries = await scheduler.readJournal(0);
      expect(entries.map((e) => e.alertId), ['a']);
      expect(entries.single.state, JournalState.fired);
    });

    test(
      'undelivered alerts yield no entry, so they read as possibly missed',
      () {
        final entries = IosJournal.infer(
          plannedPast: [_planned('a', const Duration(hours: -3))],
          pendingIds: const {},
          deliveredIds: const {},
        );
        expect(entries, isEmpty);
      },
    );

    test('clearJournal does nothing and does not fail', () async {
      await scheduler.clearJournal();
    });
  });

  group('events', () {
    test(
      'a tap becomes a NotificationTappedEvent with the recording',
      () async {
        await scheduler.initialize();
        final events = <AlertPlatformEvent>[];
        final sub = scheduler.events.listen(events.add);
        gateway.tap(
          IosNotificationPayload(
            alertId: 'a',
            audioRef: 'voice-1-shia',
          ).encode(),
        );
        await Future<void>.delayed(Duration.zero);
        await sub.cancel();
        final tap = events.single as NotificationTappedEvent;
        expect(tap.alertId, 'a');
        expect(tap.audioRef, 'voice-1-shia');
      },
    );

    test('a plain-text payload is read as the alert id', () {
      expect(
        IosNotificationPayload.decode('fajr:2026-10-22').alertId,
        'fajr:2026-10-22',
      );
      expect(IosNotificationPayload.decode('fajr:2026-10-22').audioRef, isNull);
    });

    test('the launch tap is delivered once a listener attaches', () async {
      gateway.launchPayload = IosNotificationPayload(alertId: 'a').encode();
      await scheduler.initialize();
      final first = await scheduler.events.first;
      expect((first as NotificationTappedEvent).alertId, 'a');
    });
  });

  group('background refresh channel', () {
    const channel = MethodChannel('org.deenapp.mobile/background_refresh');

    Future<Object?> call() async {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final completer = Completer<ByteData?>();
      await messenger.handlePlatformMessage(
        channel.name,
        channel.codec.encodeMethodCall(const MethodCall('onRefreshWindow')),
        completer.complete,
      );
      final reply = await completer.future;
      return reply == null ? null : channel.codec.decodeEnvelope(reply);
    }

    test('waits for the rebuild and replies true', () async {
      scheduler.attachBackgroundRefresh();
      final rebuilt = Completer<void>();
      scheduler.events.listen((event) {
        if (event is RefreshWindowEvent) {
          rebuilt.future.then((_) => event.done.complete());
        }
      });
      var replied = false;
      final reply = call().then((value) {
        replied = true;
        return value;
      });
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(replied, isFalse);
      rebuilt.complete();
      expect(await reply, isTrue);
    });

    test('replies false when nobody listens', () async {
      scheduler.attachBackgroundRefresh();
      expect(await call(), isFalse);
    });

    test('replies after the timeout when the rebuild never finishes', () async {
      final quick = IosAlertScheduler(
        gateway: gateway,
        plannedPast: () async => const [],
        clock: () => _now,
        requestPermission: () async => true,
        refreshTimeout: const Duration(milliseconds: 30),
      )..attachBackgroundRefresh();
      quick.events.listen((_) {});
      expect(await call(), isTrue);
      quick.dispose();
    });
  });
}

class _FakeGateway implements IosNotificationGateway {
  final List<String> log = [];
  final List<IosScheduledRequest> scheduled = [];
  List<IosPendingRequest> pendingFromOutside = [];
  List<String?> deliveredPayloads = [];
  bool enabled = true;
  bool soundEnabled = true;
  bool failOnSchedule = false;
  String? launchPayload;
  void Function(String? payload)? _onTap;

  void tap(String? payload) => _onTap?.call(payload);

  @override
  Future<void> initialize({
    required void Function(String? payload) onTap,
  }) async {
    _onTap = onTap;
  }

  @override
  Future<String?> launchPayloadIfAny() async => launchPayload;

  @override
  Future<void> cancelAll() async {
    log.add('cancelAll');
    scheduled.clear();
    pendingFromOutside = [];
  }

  @override
  Future<void> schedule(IosScheduledRequest request) async {
    if (failOnSchedule) throw PlatformException(code: 'bad');
    log.add('schedule');
    scheduled.add(request);
  }

  @override
  Future<List<IosPendingRequest>> pending() async => [
    for (final r in scheduled) IosPendingRequest(id: r.id, payload: r.payload),
    ...pendingFromOutside,
  ];

  @override
  Future<List<String?>> deliveredPayloadList() async => deliveredPayloads;

  @override
  Future<IosNotificationSettings> settings() async =>
      IosNotificationSettings(enabled: enabled, soundEnabled: soundEnabled);

  @override
  Future<void> openSettings() async => log.add('openSettings');
}
