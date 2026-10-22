// The end-to-end setup scenario of task T036, written once so that it can run
// both as a host test and as the integration test.
import 'package:deen_mobile/app/providers/setup_providers.dart';
import 'package:deen_mobile/domain/entities/enums.dart';
import 'package:deen_mobile/domain/permissions/permission_gateways.dart';
import 'package:deen_mobile/l10n/generated/app_localizations.dart';
import 'package:deen_mobile/platform/location_service.dart';
import 'package:deen_mobile/ui/home/home_page.dart';
import 'package:deen_mobile/ui/setup/setup_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prayer_engine/prayer_engine.dart';

import 'setup_test_support.dart';

/// What the app shell does with the setup providers: show setup until it is
/// complete, then the home page.
class _Shell extends ConsumerWidget {
  const _Shell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final complete = ref.watch(setupCompleteProvider).value;
    if (complete == null) return const SizedBox.shrink();
    return complete ? const HomePage() : const SetupFlow();
  }
}

Future<void> _tap(WidgetTester tester, String key) async {
  final finder = find.byKey(Key(key));
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await settle(tester, rounds: 4);
}

/// Task T036: skip the phone's location, choose a manual city, refuse every
/// permission, and reach today's prayer times. Shared by the host test
/// `test/ui/setup_scenario_test.dart` and `integration_test/setup_flow_test.dart`.
Future<void> skipLocationRefuseEverythingScenario(WidgetTester tester) async {
  final world = TestWorld(
    notifications: PermissionOutcome.permanentlyDenied,
    exactAlarm: PermissionOutcome.denied,
    location: const LocationUnavailable(LocationFailure.permissionDenied),
    now: DateTime.utc(2026, 10, 21, 8),
  );
  await pumpApp(tester, world, const _Shell(), size: const Size(400, 900));
  final l10n = lookupAppLocalizations(const Locale('en'));

  // Language: keep English.
  expect(find.text(l10n.setupLanguageTitle), findsOneWidget);
  await _tap(tester, 'setup-next');

  // Location: the phone's location is refused; a city from the offline list
  // is enough. The refusal is explained and nothing crashes.
  await _tap(tester, 'location-precise');
  expect(find.text(l10n.setupProblemLocationDenied), findsOneWidget);
  expect(
    tester.widget<FilledButton>(find.byKey(const Key('setup-next'))).onPressed,
    isNull,
    reason: 'a place is still needed',
  );
  await tester.enterText(find.byKey(const Key('city-search')), 'Mec');
  await settle(tester, rounds: 3);
  await _tap(tester, 'city-104515');
  await _tap(tester, 'setup-next');

  // Method: the regional suggestion for Saudi Arabia, kept as it is.
  expect(
    find.text(l10n.setupMethodSuggested(l10n.methodUmmAlQura)),
    findsOneWidget,
  );
  await _tap(tester, 'setup-next');

  // Notifications, exact alarms: both refused.
  await _tap(tester, 'notifications-allow');
  expect(find.text(l10n.setupNotificationsDenied), findsOneWidget);
  await _tap(tester, 'setup-next');
  await _tap(tester, 'exact-check');
  expect(find.text(l10n.setupExactDenied), findsOneWidget);
  await _tap(tester, 'setup-next');

  // Battery guide, then privacy with the list of what will not work.
  await _tap(tester, 'setup-next');
  expect(find.text(l10n.setupPrivacyNoData), findsOneWidget);
  expect(find.text(l10n.setupSummaryAlerts), findsOneWidget);
  expect(find.text(l10n.setupSummaryExact), findsOneWidget);
  await tester.ensureVisible(find.byKey(const Key('setup-next')));
  await tester.tap(find.byKey(const Key('setup-next')));
  await settle(tester, rounds: 8);

  // Home: today's six times and the next prayer, with the refusals shown as
  // banners that lead back to the settings.
  expect(find.byKey(const Key('home-page')), findsOneWidget);
  for (final prayer in Prayer.values) {
    expect(find.byKey(Key('row-${prayer.name}')), findsOneWidget);
  }
  expect(find.byKey(const Key('next-prayer-card')), findsOneWidget);
  expect(find.text('Mecca'), findsOneWidget);
  expect(find.byKey(const Key('permission-banner-alerts')), findsOneWidget);
  expect(
    find.byKey(const Key('permission-banner-exactTiming')),
    findsOneWidget,
  );
  expect(find.byKey(const Key('region-suggestion-banner')), findsNothing);
  expect(tester.takeException(), isNull);

  // What was saved.
  final settings = await tester.runAsync(
    () => world.db.select(world.db.prayerSettingsTable).getSingle(),
  );
  expect(settings!.method, CalculationMethod.ummAlQura);
  expect(settings.asrMethod, AsrMethod.standard);
  final global = await tester.runAsync(
    () => world.db.select(world.db.globalSettingsTable).getSingle(),
  );
  expect(global!.setupCompleted, isTrue);
  expect(global.notificationPermissionState, PermissionState.denied);

  await unmount(tester, world.db);
}
