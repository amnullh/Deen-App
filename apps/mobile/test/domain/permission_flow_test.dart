import 'package:deen_mobile/app/providers.dart';
import 'package:deen_mobile/app/providers/setup_providers.dart';
import 'package:deen_mobile/domain/entities/enums.dart';
import 'package:deen_mobile/domain/permissions/permission_flow.dart';
import 'package:deen_mobile/domain/permissions/permission_gateways.dart';
import 'package:deen_mobile/domain/setup/setup_state.dart';
import 'package:deen_mobile/platform/location_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prayer_engine/prayer_engine.dart';

import '../ui/setup/setup_test_support.dart';

/// Runs setup up to the privacy step with the given answers and finishes it.
Future<({TestWorld world, ProviderContainer container})> _runSetup({
  bool isAndroid = true,
  PermissionOutcome notifications = PermissionOutcome.granted,
  PermissionOutcome exactAlarm = PermissionOutcome.granted,
  bool skipNotificationPrompt = false,
}) async {
  final world = TestWorld(
    isAndroid: isAndroid,
    notifications: notifications,
    exactAlarm: exactAlarm,
  );
  addTearDown(world.db.close);
  final container = world.container();
  final controller = container.read(setupControllerProvider.notifier);
  await controller.load();
  await controller.chooseLanguage(AppLanguage.en);
  await controller.chooseCity(testCities.first);
  if (!skipNotificationPrompt) await controller.requestNotifications();
  await controller.declineExactAlarm();
  return (world: world, container: container);
}

Future<bool> _finish(ProviderContainer container) =>
    container.read(setupControllerProvider.notifier).finish();

void main() {
  group('refusing each permission leaves setup finishable', () {
    test('notifications denied', () async {
      final run = await _runSetup(notifications: PermissionOutcome.denied);
      final state = run.container.read(setupControllerProvider);
      expect(state.report.degraded, [DegradedFeature.alerts]);
      expect(await _finish(run.container), isTrue);
      final global = await run.container
          .read(alertPreferenceRepositoryProvider)
          .getGlobal();
      expect(global.setupCompleted, isTrue);
      expect(global.notificationPermissionState, PermissionState.denied);
    });

    test('notifications permanently denied', () async {
      final run = await _runSetup(
        notifications: PermissionOutcome.permanentlyDenied,
      );
      expect(
        run.container.read(setupControllerProvider).report.degraded,
        contains(DegradedFeature.alerts),
      );
      expect(await _finish(run.container), isTrue);
    });

    test('exact alarm denied', () async {
      final run = await _runSetup(exactAlarm: PermissionOutcome.denied);
      final state = run.container.read(setupControllerProvider);
      expect(state.report.degraded, [DegradedFeature.exactTiming]);
      expect(await _finish(run.container), isTrue);
      final global = await run.container
          .read(alertPreferenceRepositoryProvider)
          .getGlobal();
      expect(global.exactAlarmState, PermissionState.denied);
      expect(global.setupCompleted, isTrue);
    });

    test('location denied, a manual city still finishes setup', () async {
      final world = TestWorld(
        location: const LocationUnavailable(LocationFailure.permissionDenied),
      );
      addTearDown(world.db.close);
      final container = world.container();
      final controller = container.read(setupControllerProvider.notifier);
      await controller.load();
      controller.next();
      await controller.useDeviceLocation(
        approximate: false,
        displayName: 'Current location',
      );
      var state = container.read(setupControllerProvider);
      expect(state.location, isNull);
      expect(state.problem, SetupProblem.locationDenied);
      expect(state.locationRefused, isTrue);
      expect(state.canContinue, isFalse, reason: 'a place is still needed');

      await controller.chooseCity(testCities.first);
      await controller.requestNotifications();
      await controller.declineExactAlarm();
      state = container.read(setupControllerProvider);
      expect(state.canContinue, isTrue);
      expect(state.report.degraded, [DegradedFeature.automaticLocation]);
      expect(await controller.finish(), isTrue);
    });

    test('every permission refused at once', () async {
      final world = TestWorld(
        notifications: PermissionOutcome.permanentlyDenied,
        exactAlarm: PermissionOutcome.denied,
        location: const LocationUnavailable(LocationFailure.permissionDenied),
      );
      addTearDown(world.db.close);
      final container = world.container();
      final controller = container.read(setupControllerProvider.notifier);
      await controller.load();
      await controller.useDeviceLocation(
        approximate: true,
        displayName: 'Approximate location',
      );
      await controller.chooseCity(testCities.first);
      await controller.requestNotifications();
      await controller.declineExactAlarm();
      expect(container.read(setupControllerProvider).report.degraded, [
        DegradedFeature.alerts,
        DegradedFeature.exactTiming,
        DegradedFeature.automaticLocation,
      ]);
      expect(await controller.finish(), isTrue);
      expect(
        (await container.read(alertPreferenceRepositoryProvider).getGlobal())
            .setupCompleted,
        isTrue,
      );
    });

    test('skipping the notification prompt counts as not allowed', () async {
      final run = await _runSetup(skipNotificationPrompt: true);
      expect(
        run.container.read(setupControllerProvider).report.degraded,
        contains(DegradedFeature.alerts),
      );
      expect(run.world.notificationGateway.requests, 0);
      expect(await _finish(run.container), isTrue);
    });
  });

  group('platform differences', () {
    test(
      'iPhone has no exact-alarm or battery step and nothing to list',
      () async {
        final run = await _runSetup(isAndroid: false);
        final state = run.container.read(setupControllerProvider);
        expect(state.steps, isNot(contains(SetupStep.exactAlarm)));
        expect(state.steps, isNot(contains(SetupStep.battery)));
        expect(state.report.degraded, isEmpty);
      },
    );

    test('Android has every step in order', () async {
      final run = await _runSetup();
      expect(
        run.container.read(setupControllerProvider).steps,
        SetupStep.values,
      );
    });
  });

  group('way back', () {
    test('opens the app settings after a refusal', () async {
      final run = await _runSetup(notifications: PermissionOutcome.denied);
      await run.container
          .read(setupControllerProvider.notifier)
          .openAppSettings();
      expect(run.world.notificationGateway.settingsOpened, 1);
    });

    test('opens the exact-alarm settings and re-reads the answer', () async {
      final run = await _runSetup(exactAlarm: PermissionOutcome.denied);
      final controller = run.container.read(setupControllerProvider.notifier);
      await controller.openExactAlarmSettings();
      expect(run.world.exactGateway.settingsOpened, 1);
      run.world.exactGateway.outcome = PermissionOutcome.granted;
      await controller.refreshPermissions();
      expect(
        run.container.read(setupControllerProvider).exactAlarm,
        PermissionOutcome.granted,
      );
    });
  });

  group('state machine', () {
    test('Next moves through the steps and Back returns', () async {
      final run = await _runSetup();
      final controller = run.container.read(setupControllerProvider.notifier);
      expect(
        run.container.read(setupControllerProvider).step,
        SetupStep.language,
      );
      controller.next();
      expect(
        run.container.read(setupControllerProvider).step,
        SetupStep.location,
      );
      controller.back();
      expect(
        run.container.read(setupControllerProvider).step,
        SetupStep.language,
      );
    });

    test('the location step does not advance without a place', () async {
      final world = TestWorld();
      addTearDown(world.db.close);
      final container = world.container();
      final controller = container.read(setupControllerProvider.notifier);
      await controller.load();
      controller.next();
      expect(container.read(setupControllerProvider).step, SetupStep.location);
      controller.next();
      expect(
        container.read(setupControllerProvider).step,
        SetupStep.location,
        reason: 'no location chosen yet',
      );
    });

    test('finishing without a location is refused', () async {
      final world = TestWorld();
      addTearDown(world.db.close);
      final container = world.container();
      expect(
        await container.read(setupControllerProvider.notifier).finish(),
        isFalse,
      );
    });
  });

  group('choices are saved as they are made', () {
    test('the region method is suggested and Asr is Standard', () async {
      final run = await _runSetup();
      final settings = await run.container
          .read(settingsRepositoryProvider)
          .get();
      expect(settings!.method, CalculationMethod.ummAlQura);
      expect(settings.asrMethod, AsrMethod.standard);
      expect(
        run.container.read(setupControllerProvider).method,
        CalculationMethod.ummAlQura,
      );
    });

    test('a method the user chose is kept when the city changes', () async {
      final run = await _runSetup();
      final controller = run.container.read(setupControllerProvider.notifier);
      await controller.chooseMethod(CalculationMethod.egypt);
      await controller.chooseCity(
        testCities.firstWhere((c) => c.countryCode == 'PK'),
      );
      final settings = await run.container
          .read(settingsRepositoryProvider)
          .get();
      expect(settings!.method, CalculationMethod.egypt);
    });

    test('finishing marks the region as already suggested', () async {
      final run = await _runSetup();
      await run.container
          .read(setupControllerProvider.notifier)
          .chooseMethod(CalculationMethod.karachi);
      await _finish(run.container);
      final settings = await run.container
          .read(settingsRepositoryProvider)
          .get();
      expect(settings!.dismissedSuggestionRegions, {Region.arabianPeninsula});
    });

    test('every change asks the alert schedule to be rebuilt', () async {
      final run = await _runSetup();
      final before = run.container.read(scheduleInvalidationProvider);
      expect(before, greaterThan(0));
      await _finish(run.container);
      expect(
        run.container.read(scheduleInvalidationProvider),
        greaterThan(before),
      );
    });
  });
}
