import 'dart:async';

import 'package:deen_mobile/app/providers.dart';
import 'package:deen_mobile/app/providers/tasbih_providers.dart';
import 'package:deen_mobile/domain/tasbih/tasbih_state.dart';
import 'package:deen_mobile/l10n/generated/app_localizations.dart';
import 'package:deen_mobile/platform/volume_key_service.dart';
import 'package:deen_mobile/ui/tasbih/device_services.dart';
import 'package:deen_mobile/ui/tasbih/tasbih_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/tasbih/fake_tasbih_repository.dart';

class FakeVolumeKeys implements VolumeKeyService {
  FakeVolumeKeys({this.supported = true});

  final bool supported;
  final List<bool> calls = [];
  final StreamController<VolumeKey> _presses =
      StreamController<VolumeKey>.broadcast();
  bool enabled = false;

  @override
  bool get isSupported => supported;

  @override
  Stream<VolumeKey> get presses => _presses.stream;

  @override
  Future<void> setEnabled(bool value) async {
    enabled = value;
    calls.add(value);
  }

  void press(VolumeKey key) {
    if (enabled) _presses.add(key);
  }
}

class FakeKeepAwake implements KeepAwakeService {
  final List<bool> calls = [];

  bool get on => calls.isNotEmpty && calls.last;

  @override
  Future<void> setEnabled(bool enabled) async => calls.add(enabled);
}

class FakeTick implements TickPlayer {
  int plays = 0;

  @override
  Future<void> play() async => plays++;

  @override
  Future<void> dispose() async {}
}

class Harness {
  Harness({
    TasbihState initial = TasbihState.initial,
    bool volumeSupported = true,
  }) : repository = FakeTasbihRepository(initial),
       volumeKeys = FakeVolumeKeys(supported: volumeSupported);

  final FakeTasbihRepository repository;
  final FakeVolumeKeys volumeKeys;
  final FakeKeepAwake keepAwake = FakeKeepAwake();
  final FakeTick tick = FakeTick();
  final ValueNotifier<bool> active = ValueNotifier<bool>(true);
  final List<String> haptics = [];

  Future<void> pump(
    WidgetTester tester, {
    String language = 'en',
    double textScale = 1.0,
  }) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        // Flutter's own long-press feedback calls vibrate() without a type.
        if (call.method == 'HapticFeedback.vibrate' &&
            call.arguments is String) {
          haptics.add(call.arguments as String);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tasbihRepositoryProvider.overrideWithValue(repository),
          clockProvider.overrideWithValue(() => DateTime(2026, 10, 21, 9)),
          volumeKeyServiceProvider.overrideWithValue(volumeKeys),
          keepAwakeServiceProvider.overrideWithValue(keepAwake),
          tickPlayerProvider.overrideWithValue(tick),
        ],
        child: MaterialApp(
          locale: Locale(language),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: ValueListenableBuilder<bool>(
            valueListenable: active,
            builder: (context, isActive, _) =>
                TickerMode(enabled: isActive, child: const TasbihPage()),
          ),
        ),
      ),
    );
    await settle(tester);
  }
}

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> tapCounter(WidgetTester tester, [int times = 1]) async {
  for (var i = 0; i < times; i++) {
    await tester.tap(find.byKey(const Key('tasbih-counter')));
    await settle(tester);
  }
}

Finder get _count => find.byKey(const Key('tasbih-count'));

String _countText(WidgetTester tester) => tester.widget<Text>(_count).data!;

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).first,
  );
}

void main() {
  group('counting', () {
    testWidgets('starts at 0 of 33 and each tap adds one', (tester) async {
      final h = Harness();
      await h.pump(tester);
      expect(_countText(tester), '0');
      expect(find.text('Count: 0 of 33'), findsNothing);

      await tapCounter(tester, 3);
      expect(_countText(tester), '3');
      expect((await h.repository.get()).count, 3);
    });

    testWidgets('the tap target has a screen reader label and hint', (
      tester,
    ) async {
      final h = Harness();
      await h.pump(tester);
      await tapCounter(tester, 2);
      final node = tester.getSemantics(find.byKey(const Key('tasbih-counter')));
      expect(node.label, 'Count: 2 of 33');
      expect(node.hint, 'Adds one to the count');
    });

    testWidgets('the tap target is large', (tester) async {
      final h = Harness();
      await h.pump(tester);
      final size = tester.getSize(find.byKey(const Key('tasbih-counter')));
      expect(size.width, greaterThanOrEqualTo(200));
      expect(size.height, greaterThanOrEqualTo(200));
    });

    testWidgets('today\'s total and the history are shown', (tester) async {
      final h = Harness();
      h.repository.seedDay('2026-10-20', 120);
      await h.pump(tester);
      await tapCounter(tester, 2);
      expect(find.text('Today: 2'), findsOneWidget);
      await _scrollTo(tester, find.text('History'));
      expect(find.text('120'), findsOneWidget);
      expect(find.text('2'), findsWidgets);
    });

    testWidgets('an empty history says so', (tester) async {
      final h = Harness();
      await h.pump(tester);
      await _scrollTo(tester, find.text('History'));
      expect(
        find.text('No counts yet. Your daily totals appear here.'),
        findsOneWidget,
      );
    });
  });

  group('feedback', () {
    testWidgets('vibrates lightly on each count and heavily on a round', (
      tester,
    ) async {
      final h = Harness(initial: TasbihState.initial.copyWith(target: 2));
      await h.pump(tester);
      await tapCounter(tester, 2);
      expect(h.haptics, contains('HapticFeedbackType.lightImpact'));
      expect(h.haptics, contains('HapticFeedbackType.heavyImpact'));
    });

    testWidgets('no vibration when switched off', (tester) async {
      final h = Harness(initial: TasbihState.initial.copyWith(haptics: false));
      await h.pump(tester);
      await tapCounter(tester, 2);
      expect(h.haptics, isEmpty);
    });

    testWidgets('the sound plays only when switched on', (tester) async {
      final off = Harness();
      await off.pump(tester);
      await tapCounter(tester);
      expect(off.tick.plays, 0);

      final on = Harness(initial: TasbihState.initial.copyWith(sound: true));
      await on.pump(tester);
      await tapCounter(tester, 2);
      expect(on.tick.plays, 2);
    });

    testWidgets('announces when the target is reached', (tester) async {
      final h = Harness(initial: TasbihState.initial.copyWith(target: 1));
      await h.pump(tester);
      final announcements = <String>[];
      tester.binding.defaultBinaryMessenger
          .setMockDecodedMessageHandler<dynamic>(SystemChannels.accessibility, (
            message,
          ) async {
            final map = message as Map<dynamic, dynamic>;
            if (map['type'] == 'announce') {
              announcements.add((map['data'] as Map)['message'] as String);
            }
            return null;
          });
      await tapCounter(tester);
      expect(announcements, ['Target of 1 reached']);
    });
  });

  group('target', () {
    testWidgets('33 and 99 are one tap', (tester) async {
      final h = Harness();
      await h.pump(tester);
      await tester.tap(find.byKey(const Key('tasbih-target-99')));
      await settle(tester);
      expect((await h.repository.get()).target, 99);
      expect(find.text('of 99'), findsOneWidget);
      await tester.tap(find.byKey(const Key('tasbih-target-33')));
      await settle(tester);
      expect((await h.repository.get()).target, 33);
    });

    testWidgets('a custom target from 1 to 100000 can be typed', (
      tester,
    ) async {
      final h = Harness();
      await h.pump(tester);
      await tester.tap(find.byKey(const Key('tasbih-target-custom')));
      await settle(tester);
      await tester.enterText(
        find.byKey(const Key('tasbih-custom-field')),
        '250',
      );
      await tester.tap(find.text('Save'));
      await settle(tester);
      expect((await h.repository.get()).target, 250);
      expect(find.text('of 250'), findsOneWidget);
    });

    for (final bad in ['0', '100001', '']) {
      testWidgets('"$bad" is refused with a message and the dialog stays', (
        tester,
      ) async {
        final h = Harness();
        await h.pump(tester);
        await tester.tap(find.byKey(const Key('tasbih-target-custom')));
        await settle(tester);
        await tester.enterText(
          find.byKey(const Key('tasbih-custom-field')),
          bad,
        );
        await tester.tap(find.text('Save'));
        await settle(tester);
        expect(
          find.text('Enter a whole number from 1 to 100000.'),
          findsOneWidget,
        );
        expect((await h.repository.get()).target, 33);
        await tester.tap(find.text('Cancel'));
        await settle(tester);
        expect(find.byKey(const Key('tasbih-custom-field')), findsNothing);
      });
    }
  });

  group('reset', () {
    testWidgets('asks first; cancel keeps the count', (tester) async {
      final h = Harness(initial: TasbihState.initial.copyWith(count: 5));
      await h.pump(tester);
      await tester.tap(find.byKey(const Key('tasbih-reset')));
      await settle(tester);
      expect(find.text('Reset the counter?'), findsOneWidget);
      expect(
        find.text('The count goes back to 0. Your daily totals are kept.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Cancel'));
      await settle(tester);
      expect((await h.repository.get()).count, 5);
      expect(_countText(tester), '5');
    });

    testWidgets('confirming sets the count to 0', (tester) async {
      final h = Harness(initial: TasbihState.initial.copyWith(count: 5));
      await h.pump(tester);
      await tester.tap(find.byKey(const Key('tasbih-reset')));
      await settle(tester);
      await tester.tap(find.byKey(const Key('tasbih-reset-confirm')));
      await settle(tester);
      expect((await h.repository.get()).count, 0);
      expect(_countText(tester), '0');
    });
  });

  group('tap lock', () {
    testWidgets(
      'locked touches do not count; a short press on unlock only explains',
      (tester) async {
        final h = Harness(initial: TasbihState.initial.copyWith(lock: true));
        await h.pump(tester);
        expect(
          find.text('Locked. Touches on the counter are ignored.'),
          findsOneWidget,
        );

        await tapCounter(tester, 2);
        expect((await h.repository.get()).count, 0);

        await tester.tap(find.byKey(const Key('tasbih-unlock')));
        await settle(tester);
        expect(
          find.text('Press and hold the button to unlock.'),
          findsOneWidget,
        );
        expect((await h.repository.get()).lock, isTrue);
      },
    );

    testWidgets('a long press unlocks', (tester) async {
      final h = Harness(initial: TasbihState.initial.copyWith(lock: true));
      await h.pump(tester);
      await tester.longPress(find.byKey(const Key('tasbih-unlock')));
      await settle(tester);
      expect((await h.repository.get()).lock, isFalse);
      await tapCounter(tester);
      expect((await h.repository.get()).count, 1);
    });

    testWidgets('the switch turns the lock on', (tester) async {
      final h = Harness();
      await h.pump(tester);
      await _scrollTo(tester, find.byKey(const Key('tasbih-lock-switch')));
      await tester.tap(find.byKey(const Key('tasbih-lock-switch')));
      await settle(tester);
      expect((await h.repository.get()).lock, isTrue);
    });
  });

  group('volume keys', () {
    testWidgets('count while enabled and visible, and are off otherwise', (
      tester,
    ) async {
      final h = Harness(
        initial: TasbihState.initial.copyWith(volumeKeys: true),
      );
      await h.pump(tester);
      expect(h.volumeKeys.enabled, isTrue);

      h.volumeKeys.press(VolumeKey.up);
      h.volumeKeys.press(VolumeKey.down);
      await settle(tester);
      expect((await h.repository.get()).count, 2);

      h.active.value = false;
      await settle(tester);
      expect(h.volumeKeys.enabled, isFalse);

      h.active.value = true;
      await settle(tester);
      expect(h.volumeKeys.enabled, isTrue);

      await tester.pumpWidget(const SizedBox());
      await settle(tester);
      expect(h.volumeKeys.enabled, isFalse);
    });

    testWidgets('stay off when the option is off', (tester) async {
      final h = Harness();
      await h.pump(tester);
      expect(h.volumeKeys.enabled, isFalse);
    });

    testWidgets('still count while touches are locked', (tester) async {
      final h = Harness(
        initial: TasbihState.initial.copyWith(volumeKeys: true, lock: true),
      );
      await h.pump(tester);
      h.volumeKeys.press(VolumeKey.up);
      await settle(tester);
      expect((await h.repository.get()).count, 1);
    });

    testWidgets('the switch is hidden where unsupported', (tester) async {
      final h = Harness(volumeSupported: false);
      await h.pump(tester);
      await _scrollTo(tester, find.byKey(const Key('tasbih-lock-switch')));
      expect(find.byKey(const Key('tasbih-volume-switch')), findsNothing);
      expect(h.volumeKeys.enabled, isFalse);
    });
  });

  group('keep awake', () {
    testWidgets('on only while the option is on and the screen is visible', (
      tester,
    ) async {
      final h = Harness(initial: TasbihState.initial.copyWith(keepAwake: true));
      await h.pump(tester);
      expect(h.keepAwake.on, isTrue);

      h.active.value = false;
      await settle(tester);
      expect(h.keepAwake.on, isFalse);

      h.active.value = true;
      await settle(tester);
      expect(h.keepAwake.on, isTrue);

      await tester.pumpWidget(const SizedBox());
      await settle(tester);
      expect(h.keepAwake.on, isFalse);
    });

    testWidgets('never switched on when the option is off', (tester) async {
      final h = Harness();
      await h.pump(tester);
      expect(h.keepAwake.calls.where((c) => c), isEmpty);
    });
  });

  group('layout and languages', () {
    testWidgets('Arabic is right to left with Arabic labels', (tester) async {
      final h = Harness();
      await h.pump(tester, language: 'ar');
      final context = tester.element(find.byKey(const Key('tasbih-page')));
      expect(Directionality.of(context), TextDirection.rtl);
      expect(find.text('المسبحة'), findsOneWidget);
      final node = tester.getSemantics(find.byKey(const Key('tasbih-counter')));
      expect(node.label, 'العدد: 0 من 33');
      expect(tester.takeException(), isNull);
    });

    for (final language in ['en', 'ar', 'ur', 'id']) {
      testWidgets('survives 2.0x text scale on a small phone ($language)', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        final h = Harness(
          initial: TasbihState.initial.copyWith(
            count: 123456,
            target: 100000,
            lock: true,
          ),
        );
        h.repository.seedDay('2026-10-20', 99999);
        await h.pump(tester, language: language, textScale: 2.0);
        await _scrollTo(tester, find.byKey(const Key('tasbih-lock-switch')));
        expect(tester.takeException(), isNull);
      });
    }
  });
}
