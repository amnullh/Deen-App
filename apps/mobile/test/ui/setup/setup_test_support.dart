import 'dart:io';

import 'package:deen_mobile/app/providers.dart';
import 'package:deen_mobile/app/providers/prayer_providers.dart';
import 'package:deen_mobile/app/providers/setup_providers.dart';
import 'package:deen_mobile/domain/os_offset_resolver.dart';
import 'package:prayer_engine/prayer_engine.dart';
import 'package:deen_mobile/data/db/app_database.dart';
import 'package:deen_mobile/domain/entities/city.dart';
import 'package:deen_mobile/domain/permissions/permission_gateways.dart';
import 'package:deen_mobile/domain/repositories/city_search_repository.dart';
import 'package:deen_mobile/domain/resolve_timezone.dart';
import 'package:deen_mobile/domain/setup/oem_guide.dart';
import 'package:deen_mobile/l10n/generated/app_localizations.dart';
import 'package:deen_mobile/platform/location_service.dart';
import 'package:deen_mobile/ui/theme/app_theme.dart';
import 'package:deen_mobile/domain/entities/enums.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

/// A few cities, enough for the setup and settings tests.
const List<CityRecord> testCities = [
  CityRecord(
    geonameId: 104515,
    name: 'Mecca',
    latitude: 21.42664,
    longitude: 39.82563,
    countryCode: 'SA',
    timeZoneId: 'Asia/Riyadh',
    population: 1578722,
  ),
  CityRecord(
    geonameId: 108410,
    name: 'Riyadh',
    latitude: 24.68773,
    longitude: 46.72185,
    countryCode: 'SA',
    timeZoneId: 'Asia/Riyadh',
    population: 4205961,
  ),
  CityRecord(
    geonameId: 1642911,
    name: 'Jakarta',
    latitude: -6.21462,
    longitude: 106.84513,
    countryCode: 'ID',
    timeZoneId: 'Asia/Jakarta',
    population: 8540121,
    matchedName: 'Jakarta Raya',
  ),
  CityRecord(
    geonameId: 1174872,
    name: 'Karachi',
    latitude: 24.8608,
    longitude: 67.0104,
    countryCode: 'PK',
    timeZoneId: 'Asia/Karachi',
    population: 14910352,
  ),
  CityRecord(
    geonameId: 2643743,
    name: 'London',
    latitude: 51.50853,
    longitude: -0.12574,
    countryCode: 'GB',
    timeZoneId: 'Europe/London',
    population: 8961989,
  ),
  CityRecord(
    geonameId: 3137469,
    name: 'Tromsø',
    latitude: 69.6496,
    longitude: 18.95508,
    countryCode: 'NO',
    timeZoneId: 'Europe/Oslo',
    population: 52436,
  ),
];

/// Offline city search over [testCities]: prefix match on the name, population
/// first. The real implementation lives in the data layer.
class FakeCitySearch implements CitySearchRepository {
  const FakeCitySearch();

  @override
  Future<List<CityRecord>> search(String query, {int limit = 20}) async {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return const [];
    final found =
        testCities
            .where((c) => c.name.toLowerCase().startsWith(needle))
            .toList()
          ..sort((a, b) => b.population.compareTo(a.population));
    return found.take(limit).toList();
  }

  @override
  Future<CityRecord?> byId(int geonameId) async {
    for (final city in testCities) {
      if (city.geonameId == geonameId) return city;
    }
    return null;
  }
}

class FakeNotificationGateway implements NotificationPermissionGateway {
  FakeNotificationGateway(this.onRequest);

  PermissionOutcome onRequest;
  int requests = 0;
  int settingsOpened = 0;

  @override
  Future<PermissionOutcome> status() async => onRequest;

  @override
  Future<PermissionOutcome> request() async {
    requests++;
    return onRequest;
  }

  @override
  Future<void> openAppSettings() async => settingsOpened++;
}

class FakeExactAlarmGateway implements ExactAlarmGateway {
  FakeExactAlarmGateway({this.applicable = true, this.outcome});

  final bool applicable;
  PermissionOutcome? outcome;
  int settingsOpened = 0;

  @override
  bool get isApplicable => applicable;

  @override
  Future<PermissionOutcome> status() async => !applicable
      ? PermissionOutcome.notApplicable
      : (outcome ?? PermissionOutcome.denied);

  @override
  Future<void> openSettings() async => settingsOpened++;
}

class FakeBatteryGateway implements BatterySettingsGateway {
  int opened = 0;

  @override
  Future<void> openBatterySettings() async => opened++;
}

class FakeLocationService implements LocationService {
  FakeLocationService(this.outcome);

  LocationOutcome outcome;
  int located = 0;
  int settingsOpened = 0;

  @override
  Future<LocationOutcome> locate({int timeoutSeconds = 15}) async {
    located++;
    return outcome;
  }

  @override
  Future<void> openSettings() async => settingsOpened++;
}

class FakeZone implements DeviceZoneSource {
  const FakeZone(this.id);

  final String? id;

  @override
  Future<String?> deviceZoneId() async => id;
}

/// An asset bundle that serves the real `assets/oem_guides` files from disk, so
/// tests read the shipped text even though the asset is not declared in the
/// pubspec of the test run.
class DiskGuideBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final file = File(key);
    if (!file.existsSync()) throw FlutterError('Unable to load asset: $key');
    final bytes = await file.readAsBytes();
    return ByteData.sublistView(Uint8List.fromList(bytes));
  }
}

/// Everything a setup or settings test can vary.
class TestWorld {
  TestWorld({
    this.isAndroid = true,
    PermissionOutcome notifications = PermissionOutcome.granted,
    this.exactAlarm = PermissionOutcome.granted,
    LocationOutcome? location,
    this.zone = 'Asia/Riyadh',
    this.osOffset,
    AssetBundle? guideBundle,
    DateTime? now,
  }) : db = AppDatabase(NativeDatabase.memory()),
       notificationGateway = FakeNotificationGateway(notifications),
       locationService = FakeLocationService(
         location ??
             const LocationFound(
               GpsReading(latitude: 24.7136, longitude: 46.6753),
             ),
       ),
       guideBundle = guideBundle ?? DiskGuideBundle(),
       clock = now ?? DateTime.utc(2026, 10, 21, 8) {
    // Each test opens its own in-memory database.
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  }

  final bool isAndroid;
  final PermissionOutcome exactAlarm;
  final String? zone;
  final AssetBundle guideBundle;

  /// What the phone says the offset of [zone] is; defaults to the bundled data.
  final Duration Function(DateTime utc)? osOffset;
  final AppDatabase db;
  final FakeNotificationGateway notificationGateway;
  final FakeLocationService locationService;
  final FakeBatteryGateway batteryGateway = FakeBatteryGateway();
  late final FakeExactAlarmGateway exactGateway = FakeExactAlarmGateway(
    applicable: isAndroid,
    outcome: exactAlarm,
  );
  DateTime clock;

  List<Override> get overrides => [
    appDatabaseProvider.overrideWithValue(db),
    isAndroidProvider.overrideWithValue(isAndroid),
    notificationPermissionGatewayProvider.overrideWithValue(
      notificationGateway,
    ),
    exactAlarmGatewayProvider.overrideWithValue(exactGateway),
    batterySettingsGatewayProvider.overrideWithValue(batteryGateway),
    locationServiceProvider.overrideWithValue(locationService),
    deviceZoneSourceProvider.overrideWithValue(FakeZone(zone)),
    deviceRegionProvider.overrideWithValue('SA'),
    citySearchRepositoryProvider.overrideWithValue(const FakeCitySearch()),
    oemGuideRepositoryProvider.overrideWithValue(
      OemGuideRepository(guideBundle),
    ),
    clockProvider.overrideWithValue(() => clock),
    // The phone's rules equal the bundled ones unless a test says otherwise, and
    // the result does not depend on the zone of the machine running the tests.
    offsetResolverProvider.overrideWithValue(
      OsOffsetResolver(
        deviceZoneId: zone,
        bundled: _bundled,
        osOffset: osOffset ?? (utc) => _bundled.offsetAt(zone ?? 'UTC', utc),
      ),
    ),
  ];

  static final BundledOffsetResolver _bundled = BundledOffsetResolver();

  ProviderContainer container() {
    final container = ProviderContainer(overrides: overrides);
    addTearDown(container.dispose);
    return container;
  }
}

/// A stand-in for the app shell: language and text size come from saved
/// settings exactly as in `DeenApp`.
class TestApp extends ConsumerWidget {
  const TestApp({required this.home, this.textScale = 1.0, super.key});

  final Widget home;
  final double textScale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language =
        ref.watch(prayerSettingsProvider).value?.language ?? AppLanguage.en;
    return MaterialApp(
      locale: localeFor(language),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: buildTheme(brightness: Brightness.light, language: language),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child ?? const SizedBox.shrink(),
      ),
      home: home,
    );
  }
}

Future<void> pumpApp(
  WidgetTester tester,
  TestWorld world,
  Widget home, {
  double textScale = 1.0,
  Size? size,
  List<Override> extraOverrides = const [],
}) async {
  if (size != null) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }
  await tester.pumpWidget(
    ProviderScope(
      overrides: [...world.overrides, ...extraOverrides],
      child: TestApp(home: home, textScale: textScale),
    ),
  );
  await settle(tester);
}

/// Drift streams keep timers alive, so pumpAndSettle would never return. Pump a
/// bounded number of frames instead.
Future<void> settle(WidgetTester tester, {int rounds = 10}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Unmounts the app and closes the database inside the test body, so drift's
/// stream clean-up timer fires before the framework checks for pending timers.
Future<void> unmount(WidgetTester tester, AppDatabase db) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 10));
  await tester.runAsync(db.close);
  await tester.pump(const Duration(seconds: 1));
}
