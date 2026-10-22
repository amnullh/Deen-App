import 'package:deen_mobile/app/providers/alerts_providers.dart';
import 'package:deen_mobile/domain/alerts/alert_log_entry.dart';
import 'package:deen_mobile/domain/entities/enums.dart';
import 'package:deen_mobile/platform/alert_scheduler.dart';
import 'package:deen_mobile/ui/reliability/missed_alert_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../alerts/support/fakes.dart';

AlertLogEntry _missed(
  int hour, {
  AlertCause cause = AlertCause.unknown,
  AlertLogState state = AlertLogState.missed,
}) => AlertLogEntry(
  alertId: 'a$hour',
  plannedFireAt: DateTime.utc(2026, 10, 22, hour),
  state: state,
  source: AlertLogSource.androidJournal,
  cause: cause,
);

Future<ProviderContainer> _show(
  WidgetTester tester,
  List<AlertLogEntry> entries, {
  VoidCallback? onOpen,
  AlertPlatform platform = AlertPlatform.android,
}) async {
  final db = await newDatabase();
  addTearDown(() => unmount(tester, db));
  await pumpPage(
    tester,
    Scaffold(body: MissedAlertBanner(onOpenReliabilityCheck: onOpen)),
    db: db,
    scheduler: FakeAlertScheduler(platform: platform),
  );
  final container = ProviderScope.containerOf(
    tester.element(find.byType(Scaffold)),
  );
  container.read(missedAlertsProvider.notifier).report(entries);
  await settle(tester);
  return container;
}

void main() {
  testWidgets('takes no space when nothing was missed', (tester) async {
    await _show(tester, const []);
    expect(find.byKey(const Key('missed-alert-banner')), findsNothing);
  });

  testWidgets('one missed alert: title and the likely cause', (tester) async {
    await _show(tester, [_missed(2, cause: AlertCause.notificationDenied)]);
    expect(find.text('An alert may not have sounded'), findsOneWidget);
    expect(
      find.textContaining('Notifications were turned off.'),
      findsOneWidget,
    );
  });

  testWidgets('several: plural title, newest first, "and N more"', (
    tester,
  ) async {
    await _show(tester, [
      for (var h = 1; h <= 5; h++) _missed(h, cause: AlertCause.callInProgress),
    ]);
    expect(find.text('Some alerts may not have sounded'), findsOneWidget);
    expect(find.text('and 2 more'), findsOneWidget);
    expect(
      find.textContaining('A phone call was in progress.'),
      findsNWidgets(3),
    );
  });

  testWidgets('the schedule-ended cause is explained', (tester) async {
    await _show(tester, [_missed(3, cause: AlertCause.scheduleEnded)]);
    expect(
      find.textContaining('the app was not opened for a long time'),
      findsOneWidget,
    );
  });

  testWidgets('possibly missed alerts explain that iPhone cannot confirm', (
    tester,
  ) async {
    await _show(tester, [
      _missed(3, state: AlertLogState.possiblyMissed),
    ], platform: AlertPlatform.ios);
    expect(find.textContaining('cannot confirm delivery'), findsOneWidget);
  });

  testWidgets('dismissing clears it', (tester) async {
    final container = await _show(tester, [_missed(2)]);
    await tester.tap(find.byKey(const Key('missed-alert-dismiss')));
    await settle(tester);
    expect(find.byKey(const Key('missed-alert-banner')), findsNothing);
    expect(container.read(missedAlertsProvider), isEmpty);
  });

  testWidgets('offers to open the Reliability check when asked', (
    tester,
  ) async {
    var opened = false;
    await _show(tester, [_missed(2)], onOpen: () => opened = true);
    await tester.tap(find.byKey(const Key('missed-alert-open-check')));
    expect(opened, isTrue);
  });

  testWidgets('has no open button unless asked', (tester) async {
    await _show(tester, [_missed(2)]);
    expect(find.byKey(const Key('missed-alert-open-check')), findsNothing);
  });
}
