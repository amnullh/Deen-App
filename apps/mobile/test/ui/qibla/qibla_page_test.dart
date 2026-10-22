import 'dart:async';
import 'dart:math' as math;

import 'package:deen_mobile/app/providers.dart';
import 'package:deen_mobile/app/providers/qibla_providers.dart';
import 'package:deen_mobile/domain/entities/enums.dart';
import 'package:deen_mobile/domain/entities/settings.dart';
import 'package:deen_mobile/domain/qibla/heading_filter.dart';
import 'package:deen_mobile/l10n/generated/app_localizations.dart';
import 'package:deen_mobile/platform/heading_service.dart';
import 'package:deen_mobile/ui/qibla/qibla_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// A compass that records when the sensors are started and stopped.
class FakeHeadingService implements HeadingService {
  FakeHeadingService({this.available = true, this.failToStart = false});

  final bool available;
  final bool failToStart;
  int starts = 0;
  int stops = 0;
  StreamController<HeadingReading>? _controller;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Stream<HeadingReading> readings({
    required double latitude,
    required double longitude,
  }) {
    final controller = StreamController<HeadingReading>(
      onListen: () {
        starts++;
        if (failToStart) _controller?.addError(StateError('no sensor'));
      },
      onCancel: () => stops++,
    );
    _controller = controller;
    return controller.stream;
  }

  void emit(
    double heading, {
    int times = 12,
    CompassAccuracy accuracy = CompassAccuracy.high,
    double? field = 45,
    bool isTrueNorth = true,
  }) {
    for (var i = 0; i < times; i++) {
      _controller!.add(
        HeadingReading(
          headingDegrees: heading,
          isTrueNorth: isTrueNorth,
          accuracy: accuracy,
          fieldStrengthMicroTesla: field,
          interferenceSuspected: false,
          needsCalibration: false,
        ),
      );
    }
  }
}

AppLocation _location(
  double latitude,
  double longitude, [
  String name = 'Home',
]) {
  return AppLocation(
    source: LocationSource.city,
    latitude: latitude,
    longitude: longitude,
    displayName: name,
    timeZoneId: 'UTC',
    countryCode: 'US',
    updatedAt: DateTime.utc(2026, 10, 21),
  );
}

/// New York: the Qibla bearing is about 58.5 degrees (northeast).
final _newYork = _location(40.7128, -74.0060, 'New York');

/// Inside the Haram, a few metres from the Kaaba.
final _mecca = _location(21.4226, 39.8263, 'Makkah');

final _active = ValueNotifier<bool>(true);

Future<void> _pump(
  WidgetTester tester, {
  required FakeHeadingService service,
  AppLocation? location,
  String language = 'en',
  double textScale = 1.0,
}) async {
  _active.value = true;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        headingServiceProvider.overrideWithValue(service),
        locationProvider.overrideWith((ref) => Stream.value(location)),
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
          valueListenable: _active,
          builder: (context, active, _) =>
              TickerMode(enabled: active, child: const QiblaPage()),
        ),
      ),
    ),
  );
  await _settle(tester);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

double _arrowAngle(WidgetTester tester) {
  final transform = tester.widget<Transform>(
    find.byKey(const Key('qibla-arrow')),
  );
  return math.atan2(
    transform.transform.entry(1, 0),
    transform.transform.entry(0, 0),
  );
}

void main() {
  testWidgets('shows the bearing as text with degrees and direction', (
    tester,
  ) async {
    final service = FakeHeadingService();
    await _pump(tester, service: service, location: _newYork);

    expect(
      find.text('Qibla from New York: 58 degrees, northeast'),
      findsOneWidget,
    );
    // The same text is what a screen reader announces.
    expect(
      find.bySemanticsLabel(RegExp('58 degrees, northeast')),
      findsWidgets,
    );
    expect(find.text('Measured clockwise from true north'), findsOneWidget);
    expect(find.textContaining('km to the Kaaba'), findsOneWidget);
  });

  testWidgets('the arrow turns by bearing minus heading', (tester) async {
    final service = FakeHeadingService();
    await _pump(tester, service: service, location: _newYork);
    service.emit(30);
    await _settle(tester);
    await tester.pump(const Duration(milliseconds: 300));

    expect(_arrowAngle(tester) * 180 / math.pi, closeTo(58.5 - 30, 0.6));
    expect(
      find.text('Turn until the arrow points straight up'),
      findsOneWidget,
    );
    expect(find.textContaining('Turn 28 degrees to the right'), findsNothing);
    expect(
      find.bySemanticsLabel(RegExp('Turn 28 degrees to the right')),
      findsOneWidget,
    );
  });

  testWidgets('the arrow takes the short way across north', (tester) async {
    final service = FakeHeadingService();
    await _pump(tester, service: service, location: _newYork);
    service.emit(350);
    await _settle(tester);
    service.emit(10);
    await _settle(tester);
    await tester.pump(const Duration(milliseconds: 300));

    // The arrow goes from 68.5 to 48.5 degrees; it must not swing through a
    // full turn when the heading crosses north.
    expect(_arrowAngle(tester).abs(), lessThan(math.pi));
  });

  testWidgets('says so when the phone points at the Qibla', (tester) async {
    final service = FakeHeadingService();
    await _pump(tester, service: service, location: _newYork);
    service.emit(58.5);
    await _settle(tester);

    expect(find.byKey(const Key('qibla-facing')), findsOneWidget);
    expect(find.text('You are facing the Qibla'), findsOneWidget);
  });

  testWidgets('sensors run only while the screen is visible', (tester) async {
    final service = FakeHeadingService();
    await _pump(tester, service: service, location: _newYork);
    expect(service.starts, 1);
    expect(service.stops, 0);

    _active.value = false;
    await _settle(tester);
    expect(service.stops, 1);

    _active.value = true;
    await _settle(tester);
    expect(service.starts, 2);

    await tester.pumpWidget(const SizedBox());
    await _settle(tester);
    expect(service.stops, 2);
  });

  testWidgets('sensors stop when the app goes to the background', (
    tester,
  ) async {
    final service = FakeHeadingService();
    await _pump(tester, service: service, location: _newYork);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await _settle(tester);
    expect(service.stops, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await _settle(tester);
    expect(service.starts, 2);
  });

  testWidgets('shows accuracy as a word', (tester) async {
    final service = FakeHeadingService();
    await _pump(tester, service: service, location: _newYork);
    service.emit(10, accuracy: CompassAccuracy.medium);
    await _settle(tester);
    expect(find.text('Compass accuracy: Medium'), findsOneWidget);
  });

  testWidgets('prompts to calibrate when accuracy stays low', (tester) async {
    final service = FakeHeadingService();
    await _pump(tester, service: service, location: _newYork);
    service.emit(10, accuracy: CompassAccuracy.low);
    await _settle(tester);

    expect(find.byKey(const Key('qibla-calibration-prompt')), findsOneWidget);
    expect(find.textContaining('figure eight'), findsOneWidget);
    expect(find.text('Compass accuracy: Low'), findsOneWidget);
  });

  testWidgets('warns about magnetic interference', (tester) async {
    final service = FakeHeadingService();
    await _pump(tester, service: service, location: _newYork);
    service.emit(10, field: 140);
    await _settle(tester);

    expect(find.byKey(const Key('qibla-interference-warning')), findsOneWidget);
    expect(find.textContaining('Magnetic interference'), findsOneWidget);
  });

  testWidgets('mentions magnetic north when true north is unavailable', (
    tester,
  ) async {
    final service = FakeHeadingService();
    await _pump(tester, service: service, location: _newYork);
    service.emit(10, isTrueNorth: false);
    await _settle(tester);
    expect(find.byKey(const Key('qibla-magnetic-note')), findsOneWidget);
  });

  testWidgets('at the Haram the compass is not started', (tester) async {
    final service = FakeHeadingService();
    await _pump(tester, service: service, location: _mecca);

    expect(find.byKey(const Key('qibla-at-haram')), findsOneWidget);
    expect(find.textContaining('You are at the Haram'), findsOneWidget);
    expect(find.byKey(const Key('qibla-arrow')), findsNothing);
    expect(service.starts, 0);
  });

  testWidgets('without a compass shows degrees and plain instructions', (
    tester,
  ) async {
    final service = FakeHeadingService(available: false);
    await _pump(tester, service: service, location: _newYork);

    expect(find.byKey(const Key('qibla-no-compass')), findsOneWidget);
    expect(find.text('No compass on this device'), findsOneWidget);
    expect(find.textContaining('turn clockwise from north'), findsOneWidget);
    expect(
      find.text('Qibla from New York: 58 degrees, northeast'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('qibla-arrow')), findsNothing);
    expect(service.starts, 0);
  });

  testWidgets('a sensor failure falls back to the degrees view', (
    tester,
  ) async {
    final service = _FailingService();
    await _pump(tester, service: service, location: _newYork);

    expect(
      find.text(
        'The compass could not be started. The direction is shown in degrees instead.',
      ),
      findsOneWidget,
    );
    expect(
      find.text('Qibla from New York: 58 degrees, northeast'),
      findsOneWidget,
    );
  });

  testWidgets('without a saved location asks for one', (tester) async {
    final service = FakeHeadingService();
    await _pump(tester, service: service);
    expect(find.byKey(const Key('qibla-no-location')), findsOneWidget);
    expect(service.starts, 0);
  });

  testWidgets('Arabic is right to left with Arabic direction text', (
    tester,
  ) async {
    final service = FakeHeadingService();
    await _pump(tester, service: service, location: _newYork, language: 'ar');
    service.emit(10);
    await _settle(tester);

    final context = tester.element(find.byKey(const Key('qibla-page')));
    expect(Directionality.of(context), TextDirection.rtl);
    expect(
      find.text('القبلة من New York: 58 درجة، الشمال الشرقي'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  for (final language in ['ur', 'id']) {
    testWidgets('renders in $language without errors', (tester) async {
      final service = FakeHeadingService();
      await _pump(
        tester,
        service: service,
        location: _newYork,
        language: language,
      );
      service.emit(10, accuracy: CompassAccuracy.low, field: 140);
      await _settle(tester);
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('qibla-calibration-prompt')), findsOneWidget);
    });
  }

  for (final language in ['en', 'ar', 'ur']) {
    testWidgets('survives 2.0x text scale on a small phone ($language)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final service = FakeHeadingService();
      await _pump(
        tester,
        service: service,
        location: _newYork,
        language: language,
        textScale: 2.0,
      );
      service.emit(
        10,
        accuracy: CompassAccuracy.low,
        field: 140,
        isTrueNorth: false,
      );
      await _settle(tester);

      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const Key('qibla-interference-warning')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('qibla-calibration-prompt')), findsOneWidget);
    });
  }
}

class _FailingService extends FakeHeadingService {
  @override
  Stream<HeadingReading> readings({
    required double latitude,
    required double longitude,
  }) => Stream<HeadingReading>.error(StateError('no sensor'));
}
