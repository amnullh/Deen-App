import 'package:deen_mobile/app/providers/alerts_providers.dart';
import 'package:deen_mobile/data/repositories/drift_alert_log_repository.dart';
import 'package:deen_mobile/domain/alerts/alert_log_entry.dart';
import 'package:deen_mobile/domain/alerts/schedule_coordinator.dart';
import 'package:deen_mobile/domain/entities/enums.dart';
import 'package:deen_mobile/platform/alert_scheduler.dart';
import 'package:deen_mobile/ui/reliability/reliability_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../alerts/support/fakes.dart';

AlertPermissions _android({
  bool notifications = true,
  bool exact = true,
  bool battery = true,
}) => AlertPermissions(
  platform: AlertPlatform.android,
  notificationsGranted: notifications,
  exactAlarmGranted: exact,
  batteryOptimizationIgnored: battery,
);

PendingSummary _summary(List<ScheduledAlert> next, {DateTime? until}) =>
    PendingSummary(
      registeredCount: next.length,
      snapshotCount: next.length,
      nextAlerts: next,
      runsUntilEpochMs: until?.millisecondsSinceEpoch,
    );

void main() {
  void tall(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  testWidgets('all good: says so and shows nothing to fix', (tester) async {
    tall(tester);
    final db = await newDatabase();
    await pumpPage(
      tester,
      const ReliabilityPage(),
      db: db,
      scheduler: FakeAlertScheduler(
        permissions: _android(),
        summary: _summary([upcoming('asr:2026-10-22')]),
      ),
    );
    expect(find.text('Everything looks good.'), findsOneWidget);
    expect(find.byKey(const Key('permission-fix-notifications')), findsNothing);
    expect(find.byKey(const Key('permission-fix-exact')), findsNothing);
    expect(find.byKey(const Key('permission-fix-battery')), findsNothing);
    await unmount(tester, db);
  });

  testWidgets('Android: each problem has a plain fix and an action', (
    tester,
  ) async {
    tall(tester);
    final db = await newDatabase();
    final scheduler = FakeAlertScheduler(
      permissions: _android(notifications: false, exact: false, battery: false),
      summary: _summary([upcoming('asr:2026-10-22')]),
    )..grantOnRequest = false;
    await pumpPage(
      tester,
      const ReliabilityPage(),
      db: db,
      scheduler: scheduler,
    );
    expect(find.text('Something needs your attention.'), findsOneWidget);
    expect(find.textContaining('Notifications are off'), findsOneWidget);
    expect(find.textContaining('a few minutes late'), findsOneWidget);
    expect(
      find.textContaining('battery saving can stop alerts'),
      findsOneWidget,
    );
    for (final row in ['notifications', 'exact', 'battery']) {
      expect(find.byKey(Key('permission-state-$row')), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(Key('permission-state-$row'))).data,
        'Off',
      );
    }

    await tester.tap(find.byKey(const Key('permission-fix-exact')));
    await tester.tap(find.byKey(const Key('permission-fix-battery')));
    await settle(tester);
    expect(scheduler.calls, containsAll(['openExact', 'openBattery']));

    // Notification permission: ask, and when refused send the user to settings.
    await tester.tap(find.byKey(const Key('permission-fix-notifications')));
    await settle(tester);
    expect(
      scheduler.calls,
      containsAllInOrder(['requestNotifications', 'openNotificationSettings']),
    );
    await unmount(tester, db);
  });

  testWidgets('iPhone: sound setting and the silent-switch tip', (
    tester,
  ) async {
    tall(tester);
    final db = await newDatabase();
    await pumpPage(
      tester,
      const ReliabilityPage(),
      db: db,
      scheduler: FakeAlertScheduler(
        platform: AlertPlatform.ios,
        permissions: const AlertPermissions(
          platform: AlertPlatform.ios,
          notificationsGranted: true,
          soundEnabled: false,
        ),
        summary: _summary([upcoming('asr:2026-10-22')]),
      ),
    );
    expect(find.byKey(const Key('permission-sound')), findsOneWidget);
    expect(find.textContaining('alerts will be silent'), findsOneWidget);
    expect(find.textContaining("silent switch is on"), findsWidgets);
    // Android-only rows are absent.
    expect(find.byKey(const Key('permission-exact')), findsNothing);
    expect(find.byKey(const Key('permission-battery')), findsNothing);
    await unmount(tester, db);
  });

  testWidgets('lists the next five alerts with their flags', (tester) async {
    tall(tester);
    final db = await newDatabase();
    final log = DriftAlertLogRepository(db);
    final at = DateTime.utc(2026, 10, 22, 12);
    await tester.runAsync(
      () => log.syncPlanned([
        PlannedAlertRecord(
          alertId: 'isha:2026-10-22',
          fireAt: at,
          cause: AlertCause.quietHours,
        ),
      ], now: at.subtract(const Duration(days: 1))),
    );
    final scheduler = FakeAlertScheduler(
      permissions: _android(),
      summary: _summary([
        upcoming('asr:2026-10-22', title: 'Asr prayer', precise: false),
        upcoming(
          'isha:2026-10-22',
          title: 'Isha prayer',
          delivery: DeliveryType.silent,
        ),
        upcoming('x1', title: 'Fajr prayer'),
        upcoming('x2', title: 'Dhuhr prayer'),
        upcoming('x3', title: 'Asr prayer'),
        upcoming('x4', title: 'Maghrib prayer'),
      ]),
    );
    await pumpPage(
      tester,
      const ReliabilityPage(),
      db: db,
      scheduler: scheduler,
    );
    expect(find.text('Next 5 alerts'), findsOneWidget);
    expect(find.byKey(const Key('upcoming-asr:2026-10-22')), findsOneWidget);
    expect(find.byKey(const Key('upcoming-x3')), findsOneWidget);
    // Only five are shown.
    expect(find.byKey(const Key('upcoming-x4')), findsNothing);
    expect(find.text('Timing may be a few minutes late'), findsOneWidget);
    expect(find.text('Silenced by quiet hours'), findsOneWidget);
    await unmount(tester, db);
  });

  testWidgets('shows when alerts run until', (tester) async {
    tall(tester);
    final db = await newDatabase();
    await pumpPage(
      tester,
      const ReliabilityPage(),
      db: db,
      scheduler: FakeAlertScheduler(
        permissions: _android(),
        summary: _summary([
          upcoming('asr:2026-10-22'),
        ], until: DateTime.utc(2026, 12, 20, 12)),
      ),
    );
    final text = tester.widget<Text>(find.byKey(const Key('runs-until'))).data!;
    expect(text, contains('2026'));
    expect(text, contains('December'));
    await unmount(tester, db);
  });

  testWidgets('with nothing scheduled it says so and flags it', (tester) async {
    tall(tester);
    final db = await newDatabase();
    await pumpPage(
      tester,
      const ReliabilityPage(),
      db: db,
      scheduler: FakeAlertScheduler(permissions: _android()),
    );
    expect(find.text('No alerts are scheduled yet.'), findsOneWidget);
    expect(find.text('Nothing is scheduled.'), findsOneWidget);
    expect(find.text('Something needs your attention.'), findsOneWidget);
    await unmount(tester, db);
  });

  testWidgets('shows the last alert result', (tester) async {
    tall(tester);
    final db = await newDatabase();
    await tester.runAsync(
      () => DriftAlertLogRepository(db).upsertAll([
        AlertLogEntry(
          alertId: 'fajr:2026-10-21',
          plannedFireAt: DateTime.utc(2026, 10, 21, 2, 30),
          state: AlertLogState.played,
          source: AlertLogSource.androidJournal,
        ),
      ]),
    );
    await pumpPage(
      tester,
      const ReliabilityPage(),
      db: db,
      scheduler: FakeAlertScheduler(
        permissions: _android(),
        summary: _summary([upcoming('asr:2026-10-22')]),
      ),
    );
    final text = tester
        .widget<Text>(find.byKey(const Key('last-result')))
        .data!;
    expect(text, endsWith('Azaan played'));
    await unmount(tester, db);
  });

  testWidgets('says plainly when no alert has fired', (tester) async {
    tall(tester);
    final db = await newDatabase();
    await pumpPage(
      tester,
      const ReliabilityPage(),
      db: db,
      scheduler: FakeAlertScheduler(permissions: _android()),
    );
    expect(find.text('No alert has fired yet.'), findsOneWidget);
    await unmount(tester, db);
  });

  testWidgets('the test button schedules a full Azaan in one minute', (
    tester,
  ) async {
    tall(tester);
    final db = await newDatabase();
    final scheduler = FakeAlertScheduler(
      permissions: _android(),
      summary: _summary([upcoming('asr:2026-10-22')]),
    );
    await pumpPage(
      tester,
      const ReliabilityPage(),
      db: db,
      scheduler: scheduler,
    );
    await tester.tap(find.byKey(const Key('send-test-azaan')));
    await settle(tester);
    expect(scheduler.calls, ['test:60:fullAzaan']);
    expect(find.byKey(const Key('test-message')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('test-message'))).data,
      startsWith('Test Azaan set for'),
    );
    await unmount(tester, db);
  });

  testWidgets('the test button explains a refusal', (tester) async {
    tall(tester);
    final db = await newDatabase();
    final scheduler = FakeAlertScheduler(
      permissions: _android(),
      summary: _summary([upcoming('asr:2026-10-22')]),
    )..testResult = SchedulerResult(ok: false, errorCode: 'exact_alarm_denied');
    await pumpPage(
      tester,
      const ReliabilityPage(),
      db: db,
      scheduler: scheduler,
    );
    await tester.tap(find.byKey(const Key('send-test-azaan')));
    await settle(tester);
    expect(
      tester.widget<Text>(find.byKey(const Key('test-message'))).data,
      contains('Exact alarms are not allowed'),
    );
    await unmount(tester, db);
  });

  testWidgets('the test needs notifications and does not schedule without', (
    tester,
  ) async {
    tall(tester);
    final db = await newDatabase();
    final scheduler = FakeAlertScheduler(
      permissions: _android(notifications: false),
      summary: _summary([upcoming('asr:2026-10-22')]),
    );
    await pumpPage(
      tester,
      const ReliabilityPage(),
      db: db,
      scheduler: scheduler,
    );
    await tester.tap(find.byKey(const Key('send-test-azaan')));
    await settle(tester);
    expect(scheduler.calls, isEmpty);
    expect(
      find.text('Allow notifications first, then try again.'),
      findsOneWidget,
    );
    await unmount(tester, db);
  });

  testWidgets('a failed schedule rebuild is reported', (tester) async {
    tall(tester);
    final db = await newDatabase();
    await pumpPage(
      tester,
      const ReliabilityPage(),
      db: db,
      scheduler: FakeAlertScheduler(
        permissions: _android(),
        summary: _summary([upcoming('asr:2026-10-22')]),
      ),
      overrides: [lastRebuildProvider.overrideWith(_FailedRebuild.new)],
    );
    expect(find.textContaining('could not be updated'), findsOneWidget);
    await unmount(tester, db);
  });

  testWidgets('shows the missed-alert notice when one was found', (
    tester,
  ) async {
    tall(tester);
    final db = await newDatabase();
    final harness = await pumpPage(
      tester,
      const ReliabilityPage(),
      db: db,
      scheduler: FakeAlertScheduler(permissions: _android()),
    );
    expect(find.byKey(const Key('missed-alert-banner')), findsNothing);
    ProviderScope.containerOf(
      tester.element(find.byKey(const Key('reliability-page'))),
    ).read(missedAlertsProvider.notifier).report([
      AlertLogEntry(
        alertId: 'fajr:2026-10-22',
        plannedFireAt: DateTime.utc(2026, 10, 22, 2, 30),
        state: AlertLogState.missed,
        source: AlertLogSource.androidJournal,
        cause: AlertCause.batteryRestricted,
      ),
    ]);
    await settle(tester);
    expect(find.byKey(const Key('missed-alert-banner')), findsOneWidget);
    expect(
      find.textContaining('Battery saving may have stopped it'),
      findsOneWidget,
    );
    expect(harness.scheduler.calls, isEmpty);
    await unmount(tester, db);
  });

  testWidgets('a device that cannot schedule shows a plain message', (
    tester,
  ) async {
    tall(tester);
    final db = await newDatabase();
    await pumpPage(
      tester,
      const ReliabilityPage(),
      db: db,
      scheduler: FakeAlertScheduler(platform: AlertPlatform.unsupported),
    );
    expect(find.textContaining('cannot schedule alerts'), findsOneWidget);
    await unmount(tester, db);
  });

  testWidgets('fits at the largest text size in Arabic and Urdu', (
    tester,
  ) async {
    for (final language in [AppLanguage.ar, AppLanguage.ur]) {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      final db = await newDatabase(language: language);
      await pumpPage(
        tester,
        const ReliabilityPage(),
        db: db,
        language: language,
        textScale: 2.0,
        scheduler: FakeAlertScheduler(
          permissions: _android(
            notifications: false,
            exact: false,
            battery: false,
          ),
          summary: _summary([upcoming('asr:2026-10-22')]),
        ),
      );
      expect(tester.takeException(), isNull);
      await unmount(tester, db);
    }
    addTearDown(tester.view.reset);
  });
}

class _FailedRebuild extends LastRebuild {
  @override
  RebuildReport? build() => const RebuildReport(
    trigger: RebuildTrigger.launch,
    status: RebuildStatus.failed,
    errorCode: 'budget_exceeded',
  );
}
