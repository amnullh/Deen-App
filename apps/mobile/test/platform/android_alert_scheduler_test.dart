import 'package:deen_mobile/platform/alert_scheduler.dart';
import 'package:deen_mobile/platform/android_alert_scheduler.dart';
import 'package:deen_mobile/platform/generated/scheduling.g.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

ScheduledAlert _alert(String id) => ScheduledAlert(
  alertId: id,
  fireAtEpochMs: 1,
  kind: AlertKind.prayer,
  delivery: DeliveryType.shortTone,
  title: 't',
  body: 'b',
  stopLabel: 's',
  loudMode: false,
  volumeChoice: VolumeChoiceDto.keepCurrent,
  preciseAllowed: true,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeApi api;
  late AndroidAlertScheduler scheduler;

  setUp(() {
    api = _FakeApi();
    scheduler = AndroidAlertScheduler(
      api: api,
      requestNotificationPermissionOverride: () async => true,
    );
  });

  tearDown(() => scheduler.dispose());

  test('replaceSchedule hands the alerts to native code unchanged', () async {
    final result = await scheduler.replaceSchedule([_alert('a'), _alert('b')]);
    expect(result.ok, isTrue);
    expect(api.replaced.single.map((a) => a.alertId), ['a', 'b']);
  });

  test('a native error code is passed on', () async {
    api.nextResult = SchedulerResult(ok: false, errorCode: 'budget_exceeded');
    final result = await scheduler.replaceSchedule([_alert('a')]);
    expect(result.errorCode, 'budget_exceeded');
  });

  test(
    'a missing native side becomes a failed result, not an exception',
    () async {
      api.throwPlatform = true;
      final result = await scheduler.replaceSchedule([_alert('a')]);
      expect(result.ok, isFalse);
      expect(result.errorCode, 'platform_error');
      final test = await scheduler.scheduleTestAlert(
        delaySeconds: 60,
        delivery: DeliveryType.fullAzaan,
      );
      expect(test.ok, isFalse);
    },
  );

  test('test alerts pass the delay and delivery type', () async {
    await scheduler.scheduleTestAlert(
      delaySeconds: 60,
      delivery: DeliveryType.fullAzaan,
    );
    expect(api.tests, [(60, DeliveryType.fullAzaan)]);
  });

  test('permissions map from the native snapshot', () async {
    api.permissions = PermissionSnapshot(
      notificationsGranted: true,
      exactAlarmGranted: false,
      batteryOptimizationIgnored: true,
    );
    final state = await scheduler.getPermissionState();
    expect(state.platform, AlertPlatform.android);
    expect(state.notificationsGranted, isTrue);
    expect(state.exactAlarmGranted, isFalse);
    expect(state.batteryOptimizationIgnored, isTrue);
  });

  test(
    'if permissions cannot be read, everything is reported as off',
    () async {
      api.throwPlatform = true;
      final state = await scheduler.getPermissionState();
      expect(state.notificationsGranted, isFalse);
      expect(state.exactAlarmGranted, isFalse);
    },
  );

  test('journal and summary survive a native failure', () async {
    api.throwPlatform = true;
    expect(await scheduler.readJournal(0), isEmpty);
    expect((await scheduler.getPendingSummary()).registeredCount, 0);
    await scheduler.clearJournal();
    await scheduler.openExactAlarmSettings();
    await scheduler.openBatterySettings();
    await scheduler.openAppNotificationSettings();
  });

  test('journal entries come straight from native code', () async {
    api.journal = [
      JournalEntry(
        alertId: 'a',
        plannedAtEpochMs: 5,
        state: JournalState.fired,
      ),
    ];
    expect((await scheduler.readJournal(0)).single.alertId, 'a');
  });

  test('settings pages open through native code', () async {
    await scheduler.openExactAlarmSettings();
    await scheduler.openBatterySettings();
    expect(api.opened, ['exact', 'battery']);
  });

  test('notification permission is requested through the override', () async {
    expect(await scheduler.requestNotificationPermission(), isTrue);
  });

  test('native events become platform events', () async {
    final events = <AlertPlatformEvent>[];
    final sub = scheduler.events.listen(events.add);
    scheduler.onNotificationTapped('fajr:2026-10-22');
    scheduler.onPermissionChanged(
      PermissionSnapshot(
        notificationsGranted: false,
        exactAlarmGranted: true,
        batteryOptimizationIgnored: false,
      ),
    );
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();
    expect((events[0] as NotificationTappedEvent).alertId, 'fajr:2026-10-22');
    final changed = events[1] as PermissionChangedEvent;
    expect(changed.permissions.notificationsGranted, isFalse);
  });
}

class _FakeApi implements SchedulerApi {
  final List<List<ScheduledAlert>> replaced = [];
  final List<(int, DeliveryType)> tests = [];
  final List<String> opened = [];
  SchedulerResult nextResult = SchedulerResult(ok: true);
  bool throwPlatform = false;
  List<JournalEntry> journal = [];
  PermissionSnapshot permissions = PermissionSnapshot(
    notificationsGranted: true,
    exactAlarmGranted: true,
    batteryOptimizationIgnored: false,
  );

  void _maybeThrow() {
    if (throwPlatform) throw PlatformException(code: 'channel-error');
  }

  @override
  Future<SchedulerResult> replaceSchedule(List<ScheduledAlert> alerts) async {
    _maybeThrow();
    replaced.add(alerts);
    return nextResult;
  }

  @override
  Future<SchedulerResult> scheduleTestAlert(
    int delaySeconds,
    DeliveryType delivery,
  ) async {
    _maybeThrow();
    tests.add((delaySeconds, delivery));
    return SchedulerResult(ok: true);
  }

  @override
  Future<PermissionSnapshot> getPermissionState() async {
    _maybeThrow();
    return permissions;
  }

  @override
  Future<void> openExactAlarmSettings() async {
    _maybeThrow();
    opened.add('exact');
  }

  @override
  Future<void> openBatterySettings() async {
    _maybeThrow();
    opened.add('battery');
  }

  @override
  Future<void> openAppNotificationSettings() async {
    _maybeThrow();
    opened.add('notifications');
  }

  @override
  Future<List<JournalEntry>> readJournal(int sinceEpochMs) async {
    _maybeThrow();
    return journal;
  }

  @override
  Future<void> clearJournal() async {
    _maybeThrow();
  }

  @override
  Future<PendingSummary> getPendingSummary() async {
    _maybeThrow();
    return PendingSummary(registeredCount: 3, snapshotCount: 3, nextAlerts: []);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
