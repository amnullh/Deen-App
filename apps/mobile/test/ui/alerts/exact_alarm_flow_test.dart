import 'package:deen_mobile/platform/alert_scheduler.dart';
import 'package:deen_mobile/ui/alerts/exact_alarm_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

AlertPermissions _android({required bool exact}) => AlertPermissions(
  platform: AlertPlatform.android,
  notificationsGranted: true,
  exactAlarmGranted: exact,
);

/// A button that runs the flow and shows its outcome as text.
class _Host extends ConsumerStatefulWidget {
  const _Host();

  @override
  ConsumerState<_Host> createState() => _HostState();
}

class _HostState extends ConsumerState<_Host> {
  String result = 'none';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TextButton(
            key: const Key('run'),
            onPressed: () async {
              final outcome = await ExactAlarmFlow.ensure(context, ref);
              if (mounted) setState(() => result = outcome.name);
            },
            child: const Text('run'),
          ),
          Text(result, key: const Key('result')),
        ],
      ),
    );
  }
}

String _result(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('result'))).data!;

void main() {
  testWidgets('does nothing when exact alarms are already allowed', (
    tester,
  ) async {
    final db = await newDatabase();
    await pumpPage(
      tester,
      const _Host(),
      db: db,
      scheduler: FakeAlertScheduler(permissions: _android(exact: true)),
    );
    await tester.tap(find.byKey(const Key('run')));
    await settle(tester);
    expect(find.byKey(const Key('exact-alarm-dialog')), findsNothing);
    expect(_result(tester), 'notNeeded');
    await unmount(tester, db);
  });

  testWidgets('does nothing on iPhone', (tester) async {
    final db = await newDatabase();
    await pumpPage(
      tester,
      const _Host(),
      db: db,
      scheduler: FakeAlertScheduler(platform: AlertPlatform.ios),
    );
    await tester.tap(find.byKey(const Key('run')));
    await settle(tester);
    expect(_result(tester), 'notNeeded');
    await unmount(tester, db);
  });

  testWidgets('explains, opens the setting and confirms when it is granted', (
    tester,
  ) async {
    final db = await newDatabase();
    final scheduler = FakeAlertScheduler(permissions: _android(exact: false))
      ..afterOpeningExactSettings = _android(exact: true);
    await pumpPage(tester, const _Host(), db: db, scheduler: scheduler);
    await tester.tap(find.byKey(const Key('run')));
    await settle(tester);
    expect(find.textContaining('Alarms & reminders'), findsOneWidget);

    await tester.tap(find.byKey(const Key('exact-alarm-open')));
    await settle(tester);
    expect(scheduler.calls, contains('openExact'));

    await tester.tap(find.byKey(const Key('exact-alarm-check')));
    await settle(tester);
    expect(find.byKey(const Key('exact-alarm-dialog')), findsNothing);
    expect(_result(tester), 'granted');
    await unmount(tester, db);
  });

  testWidgets('still off after the setting: says so and lets the user go on', (
    tester,
  ) async {
    final db = await newDatabase();
    final scheduler = FakeAlertScheduler(permissions: _android(exact: false));
    await pumpPage(tester, const _Host(), db: db, scheduler: scheduler);
    await tester.tap(find.byKey(const Key('run')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('exact-alarm-open')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('exact-alarm-check')));
    await settle(tester);
    expect(find.byKey(const Key('exact-alarm-dialog')), findsOneWidget);
    expect(find.textContaining('timing may be less precise'), findsOneWidget);

    await tester.tap(find.byKey(const Key('exact-alarm-skip')));
    await settle(tester);
    expect(_result(tester), 'declined');
    await unmount(tester, db);
  });
}
