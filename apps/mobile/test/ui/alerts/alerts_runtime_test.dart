import 'package:deen_mobile/data/db/app_database.dart';
import 'package:deen_mobile/app/providers/alerts_providers.dart';
import 'package:deen_mobile/data/repositories/drift_location_repository.dart';
import 'package:deen_mobile/domain/alerts/schedule_plan.dart';
import 'package:deen_mobile/domain/entities/enums.dart';
import 'package:deen_mobile/domain/entities/settings.dart';
import 'package:deen_mobile/platform/alert_scheduler.dart';
import 'package:deen_mobile/platform/playback_service.dart';
import 'package:deen_mobile/ui/alerts/alerts_runtime.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

class _CountingBuilder implements PlanBuilder {
  int builds = 0;

  @override
  Future<AlertPlan> build(PlanRequest request) async {
    builds++;
    return const AlertPlan(alerts: [], records: [], runsUntil: null);
  }
}

void main() {
  Future<void> saveLocation(WidgetTester tester, AppDatabase db) async {
    await tester.runAsync(
      () => DriftLocationRepository(db).save(
        AppLocation(
          source: LocationSource.city,
          latitude: 21.4,
          longitude: 39.8,
          displayName: 'Mecca',
          timeZoneId: 'Asia/Riyadh',
          countryCode: 'SA',
          updatedAt: DateTime.utc(2026, 10, 21),
        ),
      ),
    );
  }

  testWidgets('rebuilds the schedule when the app starts', (tester) async {
    final db = await newDatabase();
    await saveLocation(tester, db);
    final builder = _CountingBuilder();
    final scheduler = FakeAlertScheduler();
    await pumpPage(
      tester,
      const AlertsRuntime(child: Scaffold(body: Text('home'))),
      db: db,
      scheduler: scheduler,
      overrides: [planBuilderProvider.overrideWithValue(builder)],
    );
    expect(find.text('home'), findsOneWidget);
    expect(builder.builds, greaterThanOrEqualTo(1));
    expect(scheduler.replaced, isNotEmpty);
    await unmount(tester, db);
  });

  testWidgets('does nothing harmful before setup has a location', (
    tester,
  ) async {
    final db = await newDatabase();
    final builder = _CountingBuilder();
    final scheduler = FakeAlertScheduler();
    await pumpPage(
      tester,
      const AlertsRuntime(child: Scaffold(body: Text('home'))),
      db: db,
      scheduler: scheduler,
      overrides: [planBuilderProvider.overrideWithValue(builder)],
    );
    expect(builder.builds, 0);
    expect(scheduler.replaced, isEmpty);
    await unmount(tester, db);
  });

  testWidgets('a location saved later triggers a rebuild', (tester) async {
    final db = await newDatabase();
    final builder = _CountingBuilder();
    await pumpPage(
      tester,
      const AlertsRuntime(child: Scaffold(body: Text('home'))),
      db: db,
      overrides: [planBuilderProvider.overrideWithValue(builder)],
    );
    expect(builder.builds, 0);
    await saveLocation(tester, db);
    await settle(tester);
    expect(builder.builds, greaterThanOrEqualTo(1));
    await unmount(tester, db);
  });

  testWidgets('returning to the foreground checks the schedule again', (
    tester,
  ) async {
    final db = await newDatabase();
    await saveLocation(tester, db);
    final builder = _CountingBuilder();
    await pumpPage(
      tester,
      const AlertsRuntime(child: Scaffold(body: Text('home'))),
      db: db,
      scheduler: FakeAlertScheduler(platform: AlertPlatform.ios),
      overrides: [planBuilderProvider.overrideWithValue(builder)],
    );
    final before = builder.builds;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await settle(tester);
    // iPhone rebuilds on every foreground.
    expect(builder.builds, greaterThan(before));
    await unmount(tester, db);
  });

  testWidgets('says so when a tapped Azaan cannot be played', (tester) async {
    final db = await newDatabase();
    await pumpPage(
      tester,
      const AlertsRuntime(child: Scaffold(body: Text('home'))),
      db: db,
    );
    ProviderScope.containerOf(tester.element(find.byType(AlertsRuntime)))
        .read(lastPlayOutcomeProvider.notifier)
        .record(PlayOutcome.failed);
    await settle(tester);
    expect(find.text('This recording could not be played.'), findsOneWidget);
    await unmount(tester, db);
  });
}
