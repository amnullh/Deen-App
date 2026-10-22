import 'package:deen_mobile/app/lifecycle_observer.dart';
import 'package:deen_mobile/app/providers/prayer_providers.dart';
import 'package:deen_mobile/app/providers/setup_providers.dart';
import 'package:deen_mobile/data/repositories/drift_alert_preference_repository.dart';
import 'package:deen_mobile/domain/entities/enums.dart';
import 'package:deen_mobile/domain/permissions/permission_gateways.dart';
import 'package:deen_mobile/ui/home/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../ui/home/home_test_support.dart';
import '../ui/setup/setup_test_support.dart';

Future<void> _resume(WidgetTester tester) async {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  await settle(tester, rounds: 6);
}

void main() {
  Future<TestWorld> pump(
    WidgetTester tester, {
    required PermissionOutcome notificationsNow,
    List<Override> extra = const [],
  }) async {
    final world = TestWorld(
      notifications: notificationsNow,
      now: DateTime.utc(2026, 10, 21, 8),
    );
    await seedProfile(tester, world, city: testCities.first);
    await tester.runAsync(() async {
      final repo = DriftAlertPreferenceRepository(world.db);
      await repo.saveGlobal(
        (await repo.getGlobal()).copyWith(
          setupCompleted: true,
          notificationPermissionState: PermissionState.denied,
          exactAlarmState: PermissionState.granted,
        ),
      );
    });
    await pumpApp(
      tester,
      world,
      const LifecycleObserver(child: HomePage()),
      size: const Size(400, 900),
      extraOverrides: extra,
    );
    return world;
  }

  testWidgets(
    'a permission granted in system settings is picked up on resume',
    (tester) async {
      final world = await pump(
        tester,
        notificationsNow: PermissionOutcome.granted,
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byKey(const Key('home-page'))),
      );
      expect(find.byKey(const Key('permission-banner-alerts')), findsOneWidget);
      final before = container.read(scheduleInvalidationProvider);

      await _resume(tester);

      expect(find.byKey(const Key('permission-banner-alerts')), findsNothing);
      final global = await tester.runAsync(
        () => DriftAlertPreferenceRepository(world.db).getGlobal(),
      );
      expect(global!.notificationPermissionState, PermissionState.granted);
      expect(
        container.read(scheduleInvalidationProvider),
        greaterThan(before),
        reason: 'a permission change rebuilds the alert schedule',
      );
      await unmount(tester, world.db);
    },
  );

  testWidgets('an unchanged permission does not rebuild the schedule', (
    tester,
  ) async {
    final world = await pump(
      tester,
      notificationsNow: PermissionOutcome.denied,
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byKey(const Key('home-page'))),
    );
    final before = container.read(scheduleInvalidationProvider);
    await _resume(tester);
    expect(container.read(scheduleInvalidationProvider), before);
    expect(find.byKey(const Key('permission-banner-alerts')), findsOneWidget);
    await unmount(tester, world.db);
  });

  testWidgets('a change of the phone\'s UTC offset recomputes the day', (
    tester,
  ) async {
    var offset = const Duration(hours: 3);
    final world = await pump(
      tester,
      notificationsNow: PermissionOutcome.granted,
      extra: [localUtcOffsetProvider.overrideWithValue(() => offset)],
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byKey(const Key('home-page'))),
    );
    Future<void> tick() async {
      world.clock = world.clock.add(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
    }

    await tick();
    final epoch = container.read(recomputeEpochProvider);
    final invalidations = container.read(scheduleInvalidationProvider);

    // Same offset on the next tick: nothing happens.
    await tick();
    expect(container.read(recomputeEpochProvider), epoch);

    // The phone moves to another zone (or daylight saving starts).
    offset = const Duration(hours: 4);
    await tick();
    expect(container.read(recomputeEpochProvider), greaterThan(epoch));
    expect(
      container.read(scheduleInvalidationProvider),
      greaterThan(invalidations),
      reason: 'a zone change moves the alert times',
    );
    await unmount(tester, world.db);
  });
}
