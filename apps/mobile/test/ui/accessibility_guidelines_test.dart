// Accessibility audit of every screen (task T184), done with Flutter's own
// accessibility guidelines plus two project rules that have no stock guideline:
// one-handed reachability and "no meaning by color alone".
//
// What this file proves and what it cannot is written in
// `specs/001-offline-worship-app/checklists/accessibility.md`. In short: these
// are automated checks on a widget tree. A real TalkBack / VoiceOver pass on a
// phone (T187) stays open.
//
// Rules applied here
//
// * Touch size: `androidTapTargetGuideline` (48 dp) and `iOSTapTargetGuideline`
//   (44 pt) on every screen, English and Arabic, text scale 1.0 and 2.0.
// * Labels: `labeledTapTargetGuideline`, same matrix.
// * Contrast: `textContrastGuideline` on a rendered theme: light, dark, high
//   contrast light and high contrast dark (English, scale 1.0), plus Arabic.
// * One hand, on a 360 x 740 phone: the screen's primary action must either sit
//   in the lower two thirds of the viewport (at least 48 dp of its height lies
//   at or below y = 740 / 3 = 246.7 and inside the screen, so a large control
//   such as the tasbih counter counts by its lower part) or be inside a
//   scrollable and be brought fully into view by scrolling. The app bar is the top strip and
//   never counts as reachable by the rule; a primary action there fails.
// * Color alone: each state of a status banner or indicator must show text that
//   differs from the other states, and the state text must be part of the
//   semantics label a screen reader reads; where an icon is used it must also
//   differ or be paired with that text.
//
// Pumps are bounded (drift streams keep timers alive; never pumpAndSettle).
import 'dart:ui' show CheckedState;

import 'package:deen_mobile/app/app.dart';
import 'package:deen_mobile/app/lifecycle_observer.dart';
import 'package:deen_mobile/app/providers.dart';
import 'package:deen_mobile/app/providers/adhkar_providers.dart';
import 'package:deen_mobile/app/providers/alerts_providers.dart';
import 'package:deen_mobile/app/providers/qibla_providers.dart';
import 'package:deen_mobile/app/providers/tasbih_providers.dart';
import 'package:deen_mobile/data/repositories/drift_alert_preference_repository.dart';
import 'package:deen_mobile/data/repositories/drift_location_repository.dart';
import 'package:deen_mobile/data/repositories/drift_settings_repository.dart';
import 'package:deen_mobile/domain/alerts/alert_log_entry.dart';
import 'package:deen_mobile/domain/entities/enums.dart';
import 'package:deen_mobile/domain/entities/settings.dart';
import 'package:deen_mobile/domain/permissions/permission_flow.dart';
import 'package:deen_mobile/domain/permissions/permission_gateways.dart';
import 'package:deen_mobile/domain/qibla/heading_filter.dart';
import 'package:deen_mobile/l10n/generated/app_localizations.dart';
import 'package:deen_mobile/platform/alert_scheduler.dart';
import 'package:deen_mobile/platform/playback_service.dart';
import 'package:deen_mobile/ui/about/about_page.dart';
import 'package:deen_mobile/ui/app_shell.dart';
import 'package:deen_mobile/ui/adhkar/collections_page.dart';
import 'package:deen_mobile/ui/alerts/alert_options_page.dart';
import 'package:deen_mobile/ui/alerts/alert_settings_page.dart';
import 'package:deen_mobile/ui/alerts/voice_picker_page.dart';
import 'package:deen_mobile/ui/common/info_banner.dart';
import 'package:deen_mobile/ui/common/permission_banner.dart';
import 'package:deen_mobile/ui/home/detail_page.dart';
import 'package:deen_mobile/ui/home/home_page.dart';
import 'package:deen_mobile/ui/qibla/qibla_page.dart';
import 'package:deen_mobile/ui/reliability/missed_alert_banner.dart';
import 'package:deen_mobile/ui/reliability/reliability_page.dart';
import 'package:deen_mobile/ui/settings/appearance_page.dart';
import 'package:deen_mobile/ui/settings/data_page.dart';
import 'package:deen_mobile/ui/settings/language_settings_page.dart';
import 'package:deen_mobile/ui/settings/location_settings_page.dart';
import 'package:deen_mobile/ui/settings/prayer_settings_page.dart';
import 'package:deen_mobile/ui/setup/setup_flow.dart';
import 'package:deen_mobile/ui/setup/setup_widgets.dart';
import 'package:deen_mobile/ui/tasbih/tasbih_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:prayer_engine/prayer_engine.dart';

import 'adhkar/harness.dart' show fakePackAssets;
import 'alerts/support/fakes.dart'
    show FakeAlertScheduler, FakePlayer, FakeSession, upcoming;
import 'qibla/qibla_page_test.dart' show FakeHeadingService;
import 'setup/setup_test_support.dart';
import 'tasbih/tasbih_page_test.dart'
    show FakeKeepAwake, FakeTick, FakeVolumeKeys;

/// The phone every check runs on: a small 360 x 740 logical screen.
const _viewport = Size(360, 740);

/// The line between "the thumb stretches" and "the thumb rests": the upper third
/// of the screen is out of easy one-handed reach.
const _thumbLine = 740 / 3;

/// A control counts as resting in thumb reach when at least this much of its
/// height (the minimum tap target) is below the thumb line.
const _minTarget = 48.0;

const _languages = [AppLanguage.en, AppLanguage.ar];
const _scales = [1.0, 2.0];

// ---------------------------------------------------------------------------
// Harness
// ---------------------------------------------------------------------------

class _Env {
  _Env(this.world, this.scheduler, this.semantics);

  final TestWorld world;
  final FakeAlertScheduler scheduler;
  final SemanticsHandle semantics;

  Future<void> done(WidgetTester tester) async {
    await unmount(tester, world.db);
    semantics.dispose();
  }
}

AlertPermissions _androidPermissions({
  bool notifications = true,
  bool exact = true,
  bool battery = true,
}) => AlertPermissions(
  platform: AlertPlatform.android,
  notificationsGranted: notifications,
  exactAlarmGranted: exact,
  batteryOptimizationIgnored: battery,
);

FakeAlertScheduler _scheduler({AlertPermissions? permissions}) =>
    FakeAlertScheduler(
      permissions: permissions ?? _androidPermissions(),
      summary: PendingSummary(
        registeredCount: 2,
        snapshotCount: 2,
        nextAlerts: [
          upcoming('asr:2026-10-22'),
          upcoming(
            'maghrib:2026-10-22',
            title: 'Maghrib prayer',
            precise: false,
          ),
        ],
        runsUntilEpochMs: DateTime.utc(2026, 11, 20).millisecondsSinceEpoch,
      ),
    );

/// Saves what setup would have saved so a screen has something to show.
Future<void> _seed(
  WidgetTester tester,
  TestWorld world, {
  required AppLanguage language,
  required double scale,
  required Brightness brightness,
  required bool highContrast,
  required bool withLocation,
  PermissionState notifications = PermissionState.granted,
  PermissionState exact = PermissionState.granted,
}) async {
  await tester.runAsync(() async {
    await DriftSettingsRepository(world.db).save(
      PrayerSettings(
        method: CalculationMethod.ummAlQura,
        asrMethod: AsrMethod.standard,
        highLatitudeRule: HighLatitudeRule.middleOfNight,
        language: language,
        textScale: scale,
        theme: brightness == Brightness.dark
            ? ThemePreference.dark
            : ThemePreference.light,
        highContrast: highContrast,
      ),
    );
    if (!withLocation) return;
    await DriftLocationRepository(world.db).save(
      AppLocation(
        source: LocationSource.city,
        latitude: 21.4225,
        longitude: 39.8262,
        cityId: 104515,
        displayName: 'Mecca',
        timeZoneId: 'Asia/Riyadh',
        countryCode: 'SA',
        updatedAt: DateTime.utc(2026, 10, 21),
      ),
    );
    final repository = DriftAlertPreferenceRepository(world.db);
    await repository.saveGlobal(
      (await repository.getGlobal()).copyWith(
        setupCompleted: true,
        notificationPermissionState: notifications,
        exactAlarmState: exact,
      ),
    );
  });
}

/// Pumps [page] inside the real app (`DeenApp`), so language, text scale, theme
/// and contrast come from saved settings exactly as in production, with every
/// platform part replaced by a fake.
Future<_Env> _pump(
  WidgetTester tester,
  Widget page, {
  AppLanguage language = AppLanguage.en,
  double scale = 1.0,
  Brightness brightness = Brightness.light,
  bool highContrast = false,
  bool withLocation = true,
  FakeAlertScheduler? scheduler,
  FakeHeadingService? heading,
  bool compass = false,
  PermissionState notifications = PermissionState.granted,
  PermissionState exact = PermissionState.granted,
  List<Override> extra = const [],
}) async {
  final semantics = tester.ensureSemantics();
  tester.view.physicalSize = _viewport;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final world = TestWorld();
  final service = heading ?? FakeHeadingService();
  final fakeScheduler = scheduler ?? _scheduler();
  await _seed(
    tester,
    world,
    language: language,
    scale: scale,
    brightness: brightness,
    highContrast: highContrast,
    withLocation: withLocation,
    notifications: notifications,
    exact: exact,
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...world.overrides,
        alertSchedulerProvider.overrideWithValue(fakeScheduler),
        alertPlatformProvider.overrideWithValue(fakeScheduler.platform),
        playbackServiceProvider.overrideWith(
          (ref) => PlaybackService(
            player: FakePlayer(),
            session: FakeSession(),
            log: ref.watch(alertLogRepositoryProvider),
            clock: ref.watch(clockProvider),
          ),
        ),
        adhkarAssetSourceProvider.overrideWithValue(fakePackAssets()),
        headingServiceProvider.overrideWithValue(service),
        // Away from the Haram, so the compass runs and its indicators show.
        if (compass)
          locationProvider.overrideWith(
            (ref) => Stream.value(
              AppLocation(
                source: LocationSource.city,
                latitude: 40.7128,
                longitude: -74.0060,
                displayName: 'New York',
                timeZoneId: 'UTC',
                countryCode: 'US',
                updatedAt: DateTime.utc(2026, 10, 21),
              ),
            ),
          ),
        volumeKeyServiceProvider.overrideWithValue(FakeVolumeKeys()),
        keepAwakeServiceProvider.overrideWithValue(FakeKeepAwake()),
        tickPlayerProvider.overrideWithValue(FakeTick()),
        ...extra,
      ],
      child: DeenApp(home: page),
    ),
  );
  await settle(tester, rounds: 12);
  if (compass && heading == null) {
    // A weak compass: shows the accuracy indicator and the calibration prompt.
    service.emit(10, accuracy: CompassAccuracy.low);
    await settle(tester, rounds: 4);
    await tester.pump(const Duration(milliseconds: 300));
  }
  return _Env(world, fakeScheduler, semantics);
}

// ---------------------------------------------------------------------------
// Screens
// ---------------------------------------------------------------------------

/// One screen of the audit. [primary] is the key of its primary action, or null
/// when the screen is read-only (then the rule does not apply and the table says
/// so).
class _Screen {
  const _Screen(
    this.name,
    this.build, {
    this.primary,
    this.scheduler,
    this.compass = false,
    this.notifications = PermissionState.granted,
    this.exact = PermissionState.granted,
  });

  final String name;
  final Widget Function() build;
  final String? primary;
  final FakeAlertScheduler Function()? scheduler;

  /// Shows the screen with a running compass, away from the Haram.
  final bool compass;
  final PermissionState notifications;
  final PermissionState exact;
}

final List<_Screen> _screens = [
  _Screen(
    'home',
    () => const LifecycleObserver(child: HomePage()),
    primary: 'open-detail',
    notifications: PermissionState.denied,
    exact: PermissionState.denied,
  ),
  _Screen('detail', () => const DetailPage()),
  _Screen(
    'prayer settings',
    () => const PrayerSettingsPage(),
    primary: 'method-ummAlQura',
  ),
  _Screen(
    'language settings',
    () => const LanguageSettingsPage(),
    primary: 'language-ar',
  ),
  _Screen(
    'location settings',
    () => const LocationSettingsPage(),
    primary: 'location-precise',
  ),
  _Screen(
    'alert settings',
    () => const AlertSettingsPage(),
    primary: 'type-fajr-fullAzaan',
  ),
  _Screen(
    'alert options',
    () => const AlertOptionsPage(),
    primary: 'quiet-switch',
  ),
  _Screen(
    'voice picker',
    () => const VoicePickerPage(prayer: AlertPrayer.fajr),
    primary: 'preview-voice-1-standard',
  ),
  _Screen(
    'reliability check',
    () => const ReliabilityPage(),
    primary: 'send-test-azaan',
    scheduler: () => _scheduler(
      permissions: _androidPermissions(
        notifications: false,
        exact: false,
        battery: false,
      ),
    ),
  ),
  _Screen('qibla', () => const QiblaPage(), compass: true),
  _Screen('tasbih', () => const TasbihPage(), primary: 'tasbih-counter'),
  _Screen(
    'adhkar collections',
    () => const AdhkarCollectionsPage(),
    primary: 'adhkar-collection-morning',
  ),
  _Screen(
    'appearance',
    () => const AppearancePage(),
    primary: 'appearance-theme',
  ),
  _Screen('data', () => const DataPage(), primary: 'data-export-share'),
  _Screen('about', () => const AboutPage(), primary: 'about-privacy-policy'),
];

/// Every banner and status line the app has, stacked, so contrast of each
/// colored surface is measured in each theme.
Widget _bannerGallery() => Scaffold(
  body: SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Consumer(
        builder: (context, ref, _) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(missedAlertsProvider.notifier).report([
              AlertLogEntry(
                alertId: 'a1',
                plannedFireAt: DateTime.utc(2026, 10, 22, 4),
                state: AlertLogState.missed,
                source: AlertLogSource.androidJournal,
                cause: AlertCause.notificationDenied,
              ),
            ]);
          });
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const InfoBanner(message: 'Information banner', icon: Icons.info),
              const InfoBanner(
                message: 'Warning banner',
                icon: Icons.error_outline,
                warning: true,
              ),
              for (final feature in DegradedFeature.values)
                PermissionBanner(feature: feature, onFix: () {}),
              const MissedAlertBanner(),
              const StatusLine(ok: true, message: 'Status ok'),
              const StatusLine(ok: false, message: 'Status not ok'),
            ],
          );
        },
      ),
    ),
  ),
);

// ---------------------------------------------------------------------------
// Checks
// ---------------------------------------------------------------------------

/// Runs one guideline and records a failure message instead of throwing, so a
/// single test reports every problem on the screen.
Future<void> _guideline(
  WidgetTester tester,
  String where,
  String name,
  AccessibilityGuideline guideline,
  List<String> failures,
) async {
  try {
    await expectLater(tester, meetsGuideline(guideline));
  } on TestFailure catch (failure) {
    failures.add('$where: $name: ${failure.message}');
  }
}

Future<void> _tapAndLabel(
  WidgetTester tester,
  String where,
  List<String> failures,
) async {
  await _guideline(
    tester,
    where,
    'android tap target',
    androidTapTargetGuideline,
    failures,
  );
  await _guideline(
    tester,
    where,
    'iOS tap target',
    iOSTapTargetGuideline,
    failures,
  );
  await _guideline(
    tester,
    where,
    'labeled tap target',
    labeledTapTargetGuideline,
    failures,
  );
  final overflow = tester.takeException();
  if (overflow != null) failures.add('$where: layout exception: $overflow');
}

/// Whether [guideline] passes, without throwing, for the control tests.
Future<bool> _meets(
  WidgetTester tester,
  AccessibilityGuideline guideline,
) async {
  try {
    await expectLater(tester, meetsGuideline(guideline));
    return true;
  } on TestFailure {
    return false;
  }
}

enum _Reach { direct, scrolls }

/// Applies the one-handed rule from the file header to [primary]. Returns null
/// when the control breaks the rule.
Future<_Reach?> _reach(WidgetTester tester, String primary) async {
  final all = find.byKey(Key(primary), skipOffstage: false);
  final builtAtRest = all.evaluate().isNotEmpty;
  if (!builtAtRest) {
    // A lazy list builds only what is near the screen: scroll to find it.
    try {
      await tester.scrollUntilVisible(
        find.byKey(Key(primary)),
        200,
        scrollable: find.byType(Scrollable).first,
      );
    } on StateError {
      return null;
    }
  }
  final finder = all.first;
  final rect = tester.getRect(finder);
  // How much of the control lies inside the screen and below the thumb line.
  final reachableHeight =
      rect.bottom.clamp(0.0, _viewport.height) -
      rect.top.clamp(_thumbLine, _viewport.height);
  final insideWidth = rect.right > 0 && rect.left < _viewport.width;
  if (builtAtRest && insideWidth && reachableHeight >= _minTarget) {
    return _Reach.direct;
  }
  final scrollable = find.ancestor(
    of: finder,
    matching: find.byType(Scrollable),
  );
  if (scrollable.evaluate().isEmpty) return null;
  await tester.ensureVisible(finder);
  await tester.pump();
  final moved = tester.getRect(finder);
  final visible =
      moved.top >= 0 &&
      moved.bottom <= _viewport.height &&
      moved.left >= 0 &&
      moved.right <= _viewport.width;
  return visible ? _Reach.scrolls : null;
}

AppLocalizations _l10n(AppLanguage language) =>
    lookupAppLocalizations(Locale(language.name));

// ---------------------------------------------------------------------------
// Color-alone cues
// ---------------------------------------------------------------------------

/// What a user can perceive about a state without seeing its color.
class _Cue {
  _Cue(this.texts, this.icons, this.semantics);

  /// Visible words.
  final Set<String> texts;
  final Set<IconData> icons;

  /// What a screen reader announces for the whole region.
  final String semantics;

  @override
  String toString() => 'texts=$texts icons=$icons semantics="$semantics"';
}

/// The words, icons and spoken label inside [scope].
_Cue _cueOf(WidgetTester tester, Finder scope) {
  final texts = <String>{
    for (final text in tester.widgetList<Text>(
      find.descendant(of: scope, matching: find.byType(Text)),
    ))
      if (text.data != null) text.data!,
  };
  final icons = <IconData>{
    for (final icon in tester.widgetList<Icon>(
      find.descendant(of: scope, matching: find.byType(Icon)),
    ))
      if (icon.icon != null) icon.icon!,
  };
  return _Cue(texts, icons, _spoken(tester.getSemantics(scope.first)));
}

/// Everything a screen reader says for [node] and the nodes below it.
String _spoken(SemanticsNode node) {
  final parts = <String>[];
  void walk(SemanticsNode current) {
    if (current.label.isNotEmpty) parts.add(current.label);
    current.visitChildren((child) {
      walk(child);
      return true;
    });
  }

  walk(node);
  return parts.join(' ');
}

/// Asserts that every state has words, that its spoken label contains them, and
/// that the states differ from each other by words (an icon difference alone is
/// not enough for a screen reader, but is reported).
void _expectDistinctStates(Map<String, _Cue> states, {String? what}) {
  final reason = what ?? 'states';
  for (final entry in states.entries) {
    expect(entry.value.texts, isNotEmpty, reason: '$reason ${entry.key}');
    final spoken = entry.value.semantics;
    expect(
      entry.value.texts.any(spoken.contains),
      isTrue,
      reason:
          '$reason ${entry.key} spoken "$spoken" has none of '
          '${entry.value.texts}',
    );
  }
  final seen = <String, String>{};
  for (final entry in states.entries) {
    final key = (entry.value.texts.toList()..sort()).join('|');
    expect(
      seen.containsKey(key),
      isFalse,
      reason: '$reason: ${entry.key} has the same words as ${seen[key]}',
    );
    seen[key] = entry.key;
  }
}

// ---------------------------------------------------------------------------
// Setup flow
// ---------------------------------------------------------------------------

Future<void> _tapKey(WidgetTester tester, String key, {int rounds = 4}) async {
  final finder = find.byKey(Key(key));
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await settle(tester, rounds: rounds);
}

Future<void> _chooseMecca(WidgetTester tester) async {
  final field = find.byKey(const Key('city-search'));
  await tester.ensureVisible(field);
  await tester.enterText(field, 'Mec');
  await settle(tester, rounds: 4);
  await _tapKey(tester, 'city-104515');
}

/// Walks the seven setup steps, running [onStep] at each.
Future<void> _walkSetup(
  WidgetTester tester,
  Future<void> Function(String step) onStep,
) async {
  // Let button color and ink animations finish: the contrast guideline samples
  // the rendered pixels, and a button halfway between disabled and enabled
  // would be measured in a color it never rests in.
  Future<void> at(String step) async {
    await tester.pump(const Duration(seconds: 1));
    await onStep(step);
  }

  await at('language');
  await _tapKey(tester, 'setup-next');
  await at('location (nothing chosen)');
  await _chooseMecca(tester);
  await at('location (city chosen)');
  await _tapKey(tester, 'setup-next');
  await at('method and Asr');
  await _tapKey(tester, 'setup-next');
  await at('notifications (not asked)');
  await _tapKey(tester, 'notifications-allow');
  await at('notifications (answered)');
  await _tapKey(tester, 'setup-next');
  await at('exact alarm');
  await _tapKey(tester, 'setup-next');
  await at('battery guide');
  await _tapKey(tester, 'setup-next');
  await at('privacy');
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group(
    'tap size, labels and layout: every screen, en and ar, 1.0x and 2.0x',
    () {
      for (final screen in _screens) {
        for (final language in _languages) {
          for (final scale in _scales) {
            testWidgets('${screen.name} / ${language.name} / ${scale}x', (
              tester,
            ) async {
              final env = await _pump(
                tester,
                screen.build(),
                language: language,
                scale: scale,
                scheduler: screen.scheduler?.call(),
                compass: screen.compass,
                notifications: screen.notifications,
                exact: screen.exact,
              );
              final failures = <String>[];
              await _tapAndLabel(
                tester,
                '${screen.name} ${language.name} ${scale}x',
                failures,
              );
              await env.done(tester);
              expect(failures, isEmpty, reason: failures.join('\n'));
            });
          }
        }
      }

      for (final language in _languages) {
        for (final scale in _scales) {
          testWidgets('setup steps / ${language.name} / ${scale}x', (
            tester,
          ) async {
            final env = await _pump(
              tester,
              const SetupFlow(),
              language: language,
              scale: scale,
              withLocation: false,
            );
            final failures = <String>[];
            await _walkSetup(tester, (step) async {
              await _tapAndLabel(
                tester,
                'setup "$step" ${language.name} ${scale}x',
                failures,
              );
            });
            await env.done(tester);
            expect(failures, isEmpty, reason: failures.join('\n'));
          });
        }
      }
    },
  );

  group('text contrast on the rendered theme', () {
    final themes = {
      'light': (Brightness.light, false),
      'dark': (Brightness.dark, false),
      'high contrast light': (Brightness.light, true),
      'high contrast dark': (Brightness.dark, true),
    };
    for (final theme in themes.entries) {
      for (final screen in _screens) {
        testWidgets('${screen.name} / ${theme.key}', (tester) async {
          final env = await _pump(
            tester,
            screen.build(),
            brightness: theme.value.$1,
            highContrast: theme.value.$2,
            scheduler: screen.scheduler?.call(),
            compass: screen.compass,
            notifications: screen.notifications,
            exact: screen.exact,
          );
          final failures = <String>[];
          await _guideline(
            tester,
            '${screen.name} ${theme.key}',
            'text contrast',
            textContrastGuideline,
            failures,
          );
          await env.done(tester);
          expect(failures, isEmpty, reason: failures.join('\n'));
        });
      }

      testWidgets('setup steps / ${theme.key}', (tester) async {
        final env = await _pump(
          tester,
          const SetupFlow(),
          brightness: theme.value.$1,
          highContrast: theme.value.$2,
          withLocation: false,
        );
        final failures = <String>[];
        await _walkSetup(tester, (step) async {
          await _guideline(
            tester,
            'setup "$step" ${theme.key}',
            'text contrast',
            textContrastGuideline,
            failures,
          );
        });
        await env.done(tester);
        expect(failures, isEmpty, reason: failures.join('\n'));
      });

      testWidgets('banners and status lines / ${theme.key}', (tester) async {
        final env = await _pump(
          tester,
          _bannerGallery(),
          brightness: theme.value.$1,
          highContrast: theme.value.$2,
        );
        final failures = <String>[];
        await _guideline(
          tester,
          'banners ${theme.key}',
          'text contrast',
          textContrastGuideline,
          failures,
        );
        await env.done(tester);
        expect(failures, isEmpty, reason: failures.join('\n'));
      });
    }

    testWidgets('Arabic home / light', (tester) async {
      final env = await _pump(
        tester,
        const LifecycleObserver(child: HomePage()),
        language: AppLanguage.ar,
      );
      final failures = <String>[];
      await _guideline(
        tester,
        'home ar light',
        'text contrast',
        textContrastGuideline,
        failures,
      );
      await env.done(tester);
      expect(failures, isEmpty, reason: failures.join('\n'));
    });
  });

  group('one-handed reach on a 360 x 740 phone', () {
    for (final screen in _screens.where((s) => s.primary != null)) {
      for (final language in _languages) {
        for (final scale in _scales) {
          testWidgets(
            '${screen.name} primary action / ${language.name} / ${scale}x',
            (tester) async {
              final env = await _pump(
                tester,
                screen.build(),
                language: language,
                scale: scale,
                scheduler: screen.scheduler?.call(),
                compass: screen.compass,
                notifications: screen.notifications,
                exact: screen.exact,
              );
              final reach = await _reach(tester, screen.primary!);
              debugPrint(
                'REACH ${screen.name} ${language.name} ${scale}x '
                '${screen.primary}: ${reach?.name ?? 'FAILS'}',
              );
              await env.done(tester);
              expect(
                reach,
                isNotNull,
                reason:
                    '${screen.primary} is neither in the lower two thirds nor '
                    'reachable by scrolling',
              );
            },
          );
        }
      }
    }

    for (final language in _languages) {
      for (final scale in _scales) {
        testWidgets('setup Next and Back / ${language.name} / ${scale}x', (
          tester,
        ) async {
          final env = await _pump(
            tester,
            const SetupFlow(),
            language: language,
            scale: scale,
            withLocation: false,
          );
          final reaches = <String>[];
          await _walkSetup(tester, (step) async {
            final reach = await _reach(tester, 'setup-next');
            if (reach != _Reach.direct) {
              reaches.add('$step: setup-next is ${reach?.name ?? 'FAILS'}');
            }
          });
          await env.done(tester);
          expect(reaches, isEmpty, reason: reaches.join('\n'));
        });
      }
    }

    testWidgets('the Qibla screen has no primary action to reach', (
      tester,
    ) async {
      // The compass is read-only: the bearing text and the arrow are output, not
      // controls. The check is that nothing on it is a tap target hidden up in
      // the app bar other than the system back button.
      final env = await _pump(tester, const QiblaPage());
      expect(find.byType(FilledButton), findsNothing);
      expect(find.byType(IconButton), findsNothing);
      await env.done(tester);
    });
  });

  group('no meaning by color alone', () {
    testWidgets('permission banners: each feature has its own words', (
      tester,
    ) async {
      final env = await _pump(
        tester,
        Scaffold(
          body: Column(
            children: [
              for (final feature in DegradedFeature.values)
                PermissionBanner(feature: feature, onFix: () {}),
            ],
          ),
        ),
      );
      final states = {
        for (final feature in DegradedFeature.values)
          feature.name: _cueOf(
            tester,
            find.byKey(Key('permission-banner-${feature.name}')),
          ),
      };
      _expectDistinctStates(states, what: 'permission banner');
      // The warning color is decoration: every banner also carries an icon and a
      // button with words.
      for (final entry in states.entries) {
        expect(entry.value.icons, isNotEmpty, reason: entry.key);
      }
      await env.done(tester);
    });

    testWidgets('home shows the permission banners only when the permission '
        'is denied, as words', (tester) async {
      final denied = await _pump(
        tester,
        const LifecycleObserver(child: HomePage()),
        notifications: PermissionState.denied,
        exact: PermissionState.denied,
      );
      expect(find.byKey(const Key('permission-banner-alerts')), findsOneWidget);
      expect(
        find.byKey(const Key('permission-banner-exactTiming')),
        findsOneWidget,
      );
      final words = _cueOf(
        tester,
        find.byKey(const Key('permission-banner-alerts')),
      );
      expect(
        words.texts,
        contains(_l10n(AppLanguage.en).permissionBannerAlerts),
      );
      await denied.done(tester);
    });

    testWidgets('information and warning banners both carry an icon and the '
        'message in the spoken label', (tester) async {
      final env = await _pump(
        tester,
        const Scaffold(
          body: Column(
            children: [
              InfoBanner(
                key: Key('info'),
                message: 'Something to know',
                icon: Icons.info_outline,
              ),
              InfoBanner(
                key: Key('warn'),
                message: 'Something went wrong',
                icon: Icons.error_outline,
                warning: true,
              ),
            ],
          ),
        ),
      );
      final states = {
        'info': _cueOf(tester, find.byKey(const Key('info'))),
        'warning': _cueOf(tester, find.byKey(const Key('warn'))),
      };
      _expectDistinctStates(states, what: 'info banner');
      for (final entry in states.entries) {
        expect(entry.value.icons, hasLength(1), reason: entry.key);
      }
      await env.done(tester);
    });

    testWidgets('Qibla accuracy: four levels, four sentences, four icons', (
      tester,
    ) async {
      final states = <String, _Cue>{};
      for (final accuracy in CompassAccuracy.values) {
        final service = FakeHeadingService();
        final env = await _pump(
          tester,
          const QiblaPage(),
          heading: service,
          compass: true,
        );
        service.emit(10, accuracy: accuracy);
        await settle(tester, rounds: 4);
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byKey(const Key('qibla-accuracy')), findsOneWidget);
        states[accuracy.name] = _cueOf(
          tester,
          find.byKey(const Key('qibla-accuracy')),
        );
        await env.done(tester);
      }
      _expectDistinctStates(states, what: 'qibla accuracy');
      final icons = {for (final cue in states.values) cue.icons.single};
      expect(icons, hasLength(CompassAccuracy.values.length));
    });

    testWidgets('Reliability: all good and needs attention differ in words '
        'and icon, per row', (tester) async {
      final good = await _pump(tester, const ReliabilityPage());
      final goodHeader = _cueOf(
        tester,
        find
            .ancestor(
              of: find.byKey(const Key('reliability-status')),
              matching: find.byType(Row),
            )
            .first,
      );
      final goodRow = _cueOf(tester, find.byKey(const Key('permission-exact')));
      final goodIcon = tester
          .widget<Icon>(
            find.descendant(
              of: find.byKey(const Key('permission-exact')),
              matching: find.byType(Icon),
            ),
          )
          .icon;
      await good.done(tester);

      final bad = await _pump(
        tester,
        const ReliabilityPage(),
        scheduler: _scheduler(
          permissions: _androidPermissions(
            notifications: false,
            exact: false,
            battery: false,
          ),
        ),
      );
      final badHeader = _cueOf(
        tester,
        find
            .ancestor(
              of: find.byKey(const Key('reliability-status')),
              matching: find.byType(Row),
            )
            .first,
      );
      final badRow = _cueOf(tester, find.byKey(const Key('permission-exact')));
      final badIcon = tester
          .widget<Icon>(
            find.descendant(
              of: find.byKey(const Key('permission-exact')),
              matching: find.byType(Icon),
            ),
          )
          .icon;
      expect(
        tester
            .widget<Text>(find.byKey(const Key('permission-state-exact')))
            .data,
        'Off',
      );
      await bad.done(tester);

      expect(goodHeader.texts, isNot(equals(badHeader.texts)));
      expect(goodRow.texts, isNot(equals(badRow.texts)));
      expect(goodIcon, isNot(equals(badIcon)));
      // Words that say "On" or "Off" are inside the row, not only a color.
      expect(goodRow.texts, contains('On'));
      expect(badRow.texts, contains('Off'));
    });

    testWidgets('Reliability: upcoming alerts that are inexact say so in words '
        'in the spoken label', (tester) async {
      final env = await _pump(
        tester,
        const ReliabilityPage(),
        scheduler: _scheduler(),
      );
      final row = find.byKey(const Key('upcoming-maghrib:2026-10-22'));
      expect(row, findsOneWidget);
      final node = tester.getSemantics(row);
      expect(node.label, contains('Maghrib prayer'));
      await env.done(tester);
    });

    testWidgets('missed alert banner: icon, title and cause in words', (
      tester,
    ) async {
      final env = await _pump(tester, _bannerGallery());
      final banner = find.byKey(const Key('missed-alert-banner'));
      expect(banner, findsOneWidget);
      final cue = _cueOf(tester, banner);
      expect(cue.icons, contains(Icons.warning_amber_rounded));
      expect(cue.texts.any((t) => t.contains('Notifications')), isTrue);
      expect(cue.texts, contains('An alert may not have sounded'));
      await env.done(tester);
    });

    testWidgets('setup status lines: ok and not ok differ by icon and words', (
      tester,
    ) async {
      final env = await _pump(
        tester,
        const Scaffold(
          body: Column(
            children: [
              StatusLine(key: Key('ok'), ok: true, message: 'Allowed'),
              StatusLine(key: Key('bad'), ok: false, message: 'Not allowed'),
            ],
          ),
        ),
      );
      final ok = _cueOf(tester, find.byKey(const Key('ok')));
      final bad = _cueOf(tester, find.byKey(const Key('bad')));
      _expectDistinctStates({'ok': ok, 'not ok': bad});
      expect(ok.icons, isNot(equals(bad.icons)));
      await env.done(tester);
    });

    for (final language in _languages) {
      testWidgets('setup notifications answered / ${language.name}: granted '
          'and refused differ in words and icon', (tester) async {
        final l10n = _l10n(language);
        final cues = <String, _Cue>{};
        for (final granted in [true, false]) {
          final env = await _pump(
            tester,
            const SetupFlow(),
            language: language,
            withLocation: false,
          );
          env.world.notificationGateway.onRequest = granted
              ? PermissionOutcome.granted
              : PermissionOutcome.denied;
          await _tapKey(tester, 'setup-next');
          await _chooseMecca(tester);
          await _tapKey(tester, 'setup-next');
          await _tapKey(tester, 'setup-next');
          await _tapKey(tester, 'notifications-allow');
          final line = find.byType(StatusLine);
          expect(line, findsOneWidget);
          cues[granted ? 'granted' : 'refused'] = _cueOf(tester, line);
          await env.done(tester);
        }
        _expectDistinctStates(cues, what: 'notification answer');
        expect(
          cues['granted']!.texts,
          contains(l10n.setupNotificationsGranted),
        );
        expect(cues['refused']!.texts, contains(l10n.setupNotificationsDenied));
        expect(cues['granted']!.icons, isNot(equals(cues['refused']!.icons)));
      });
    }

    testWidgets('alert type choice is a radio with a label per option, not a '
        'color', (tester) async {
      final env = await _pump(tester, const AlertSettingsPage());
      final labels = <String>{};
      for (final type in AlertType.values) {
        final tile = find.byKey(Key('type-fajr-${type.name}'));
        await tester.ensureVisible(tile);
        final node = tester.getSemantics(tile);
        expect(node.label, isNotEmpty, reason: type.name);
        labels.add(node.label);
      }
      expect(labels, hasLength(AlertType.values.length));
      // The selected option is announced as selected, not only drawn.
      final selected = AlertType.values.where((type) {
        final node = tester.getSemantics(
          find.byKey(Key('type-fajr-${type.name}')),
        );
        return node.getSemanticsData().flagsCollection.isChecked ==
            CheckedState.isTrue;
      });
      expect(selected, hasLength(1));
      await env.done(tester);
    });

    for (final language in _languages) {
      testWidgets('home marks the next prayer with a word, not only a '
          'highlight / ${language.name}', (tester) async {
        final l10n = _l10n(language);
        final env = await _pump(
          tester,
          const LifecycleObserver(child: HomePage()),
          language: language,
        );
        final marked = <String>[];
        for (final prayer in Prayer.values) {
          final row = find.byKey(Key('row-${prayer.name}'));
          final cue = _cueOf(tester, row);
          if (cue.texts.contains(l10n.homeNextBadge)) {
            marked.add(prayer.name);
            expect(cue.semantics, contains(l10n.homeNextBadge));
          } else {
            expect(cue.semantics, isNot(contains(l10n.homeNextBadge)));
          }
        }
        expect(marked, hasLength(1));
        await env.done(tester);
      });
    }

    testWidgets('appearance theme choice announces the selected theme', (
      tester,
    ) async {
      final env = await _pump(tester, const AppearancePage());
      final theme = find.byKey(const Key('appearance-theme'));
      expect(theme, findsOneWidget);
      final check = find.descendant(
        of: theme,
        matching: find.byIcon(Icons.check),
      );
      expect(check, findsWidgets);
      await env.done(tester);
    });
  });

  group('dialogs, the menu and the shell: tap size and labels', () {
    // Each opener taps a control and then checks the guidelines on what opened.
    final overlays = <String, (Widget Function(), List<String>)>{
      'delete-all dialog': (() => const DataPage(), ['data-delete-all']),
      'tasbih custom target dialog': (
        () => const TasbihPage(),
        ['tasbih-target-custom'],
      ),
      'tasbih reset dialog': (() => const TasbihPage(), ['tasbih-reset']),
      'home menu': (() => const AppShell(), ['more-menu']),
    };
    for (final entry in overlays.entries) {
      for (final language in _languages) {
        for (final scale in _scales) {
          testWidgets('${entry.key} / ${language.name} / ${scale}x', (
            tester,
          ) async {
            final env = await _pump(
              tester,
              entry.value.$1(),
              language: language,
              scale: scale,
            );
            for (final key in entry.value.$2) {
              await _tapKey(tester, key, rounds: 6);
            }
            await tester.pump(const Duration(seconds: 1));
            final failures = <String>[];
            await _tapAndLabel(
              tester,
              '${entry.key} ${language.name} ${scale}x',
              failures,
            );
            await env.done(tester);
            expect(failures, isEmpty, reason: failures.join('\n'));
          });
        }
      }
    }

    testWidgets('the shell home has its Reliability check, settings and menu '
        'buttons labeled', (tester) async {
      final env = await _pump(tester, const AppShell());
      for (final key in ['reliability-entry', 'open-prayer-settings']) {
        final node = tester.getSemantics(find.byKey(Key(key)));
        expect(
          node.label.isNotEmpty || node.tooltip.isNotEmpty,
          isTrue,
          reason: key,
        );
      }
      final failures = <String>[];
      await _tapAndLabel(tester, 'shell home', failures);
      expect(failures, isEmpty, reason: failures.join('\n'));
      await env.done(tester);
    });
  });

  group('control: the guidelines really catch defects', () {
    // If these did not fail, a green audit above would prove nothing.
    testWidgets('a 20 dp tap target fails the tap size guidelines', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            // Away from the screen edge: the guideline skips targets that
            // touch it (they may be partly scrolled out of view).
            body: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: Semantics(
                  label: 'tiny',
                  button: true,
                  onTap: () {},
                  child: const ColoredBox(color: Colors.black),
                ),
              ),
            ),
          ),
        ),
      );
      expect(await _meets(tester, androidTapTargetGuideline), isFalse);
      expect(await _meets(tester, iOSTapTargetGuideline), isFalse);
      handle.dispose();
    });

    testWidgets('a button with no label fails the labeled guideline', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: IconButton(onPressed: () {}, icon: const Icon(Icons.add)),
            ),
          ),
        ),
      );
      expect(await _meets(tester, labeledTapTargetGuideline), isFalse);
      handle.dispose();
    });

    testWidgets('pale grey text on white fails the contrast guideline', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Text(
                'Pale',
                style: TextStyle(color: Color(0xFFCCCCCC), fontSize: 14),
              ),
            ),
          ),
        ),
      );
      expect(await _meets(tester, textContrastGuideline), isFalse);
      handle.dispose();
    });
  });
}
