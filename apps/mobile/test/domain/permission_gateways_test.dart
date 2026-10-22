import 'package:deen_mobile/domain/permissions/permission_gateways.dart';
import 'package:deen_mobile/domain/permissions/platform_gateways.dart';
import 'package:deen_mobile/platform/generated/scheduling.g.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeScheduler extends SchedulerApi {
  _FakeScheduler({this.granted = true, this.throws = false});

  final bool granted;
  final bool throws;
  int opened = 0;

  @override
  Future<PermissionSnapshot> getPermissionState() async {
    if (throws) throw PlatformException(code: 'boom');
    return PermissionSnapshot(
      notificationsGranted: true,
      exactAlarmGranted: granted,
      batteryOptimizationIgnored: false,
    );
  }

  @override
  Future<void> openExactAlarmSettings() async {
    if (throws) throw PlatformException(code: 'boom');
    opened++;
  }
}

void main() {
  group('SchedulerExactAlarmGateway', () {
    test('reports granted and denied on Android', () async {
      expect(
        await SchedulerExactAlarmGateway(
          isAndroid: true,
          api: _FakeScheduler(),
        ).status(),
        PermissionOutcome.granted,
      );
      expect(
        await SchedulerExactAlarmGateway(
          isAndroid: true,
          api: _FakeScheduler(granted: false),
        ).status(),
        PermissionOutcome.denied,
      );
    });

    test('is not applicable elsewhere and never calls the platform', () async {
      final api = _FakeScheduler();
      final gateway = SchedulerExactAlarmGateway(isAndroid: false, api: api);
      expect(gateway.isApplicable, isFalse);
      expect(await gateway.status(), PermissionOutcome.notApplicable);
      await gateway.openSettings();
      expect(api.opened, 0);
    });

    test('opens the settings on Android', () async {
      final api = _FakeScheduler();
      await SchedulerExactAlarmGateway(
        isAndroid: true,
        api: api,
      ).openSettings();
      expect(api.opened, 1);
    });

    test('a channel failure counts as denied and never throws', () async {
      final gateway = SchedulerExactAlarmGateway(
        isAndroid: true,
        api: _FakeScheduler(throws: true),
      );
      expect(await gateway.status(), PermissionOutcome.denied);
      await gateway.openSettings();
    });
  });

  group('without a platform plugin nothing throws', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    test('notifications read as denied', () async {
      const gateway = PermissionHandlerNotificationGateway();
      expect(await gateway.status(), PermissionOutcome.denied);
      expect(await gateway.request(), PermissionOutcome.denied);
      await gateway.openAppSettings();
    });

    test('battery settings do nothing off Android and never throw', () async {
      await const IntentBatterySettingsGateway(isAndroid: false)
          .openBatterySettings();
      await const IntentBatterySettingsGateway(isAndroid: true)
          .openBatterySettings();
    });
  });

  test('only granted and not-applicable satisfy a permission', () {
    expect(PermissionOutcome.granted.isSatisfied, isTrue);
    expect(PermissionOutcome.notApplicable.isSatisfied, isTrue);
    expect(PermissionOutcome.denied.isSatisfied, isFalse);
    expect(PermissionOutcome.permanentlyDenied.isSatisfied, isFalse);
  });
}
