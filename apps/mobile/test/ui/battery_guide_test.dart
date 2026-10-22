import 'package:deen_mobile/app/providers/setup_providers.dart';
import 'package:deen_mobile/domain/entities/enums.dart';
import 'package:deen_mobile/domain/setup/oem_guide.dart';
import 'package:deen_mobile/l10n/generated/app_localizations.dart';
import 'package:deen_mobile/ui/setup/battery_guide_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'home/home_test_support.dart';
import 'setup/setup_test_support.dart';

class _SamsungDetector implements DeviceBrandSource {
  const _SamsungDetector();

  @override
  Future<OemBrand?> detect() async => OemBrand.samsung;
}

class _BrokenBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) => throw FlutterError('missing $key');
}

Future<OemGuide> _guide(OemBrand brand) async =>
    OemGuideRepository(DiskGuideBundle()).load(brand);

void main() {
  testWidgets('shows the general guide, then the chosen brand\'s steps', (
    tester,
  ) async {
    final world = TestWorld();
    await seedProfile(tester, world, city: testCities.first);
    await pumpApp(
      tester,
      world,
      const Scaffold(body: BatteryGuideStep()),
      size: const Size(400, 1400),
    );
    final other = (await tester.runAsync(() => _guide(OemBrand.other)))!;
    expect(find.text(other.steps[AppLanguage.en]!.first), findsOneWidget);

    await tester.tap(find.byKey(const Key('brand-xiaomi')));
    await settle(tester, rounds: 10);
    final xiaomi = (await tester.runAsync(() => _guide(OemBrand.xiaomi)))!;
    expect(find.text(xiaomi.steps[AppLanguage.en]!.first), findsOneWidget);
    expect(find.text(other.steps[AppLanguage.en]!.first), findsNothing);
    await unmount(tester, world.db);
  });

  testWidgets('the steps are shown in the app language', (tester) async {
    final world = TestWorld();
    await seedProfile(
      tester,
      world,
      city: testCities.first,
      language: AppLanguage.ar,
    );
    await pumpApp(
      tester,
      world,
      const Scaffold(body: BatteryGuideStep()),
      size: const Size(400, 1400),
    );
    final other = (await tester.runAsync(() => _guide(OemBrand.other)))!;
    expect(find.text(other.steps[AppLanguage.ar]!.first), findsOneWidget);
    await unmount(tester, world.db);
  });

  testWidgets('a detected brand is preselected and the settings link works', (
    tester,
  ) async {
    final world = TestWorld();
    await seedProfile(tester, world, city: testCities.first);
    await pumpApp(
      tester,
      world,
      const Scaffold(body: BatteryGuideStep()),
      size: const Size(400, 1400),
      extraOverrides: [
        deviceBrandSourceProvider.overrideWithValue(const _SamsungDetector()),
      ],
    );
    final chip = tester.widget<ChoiceChip>(
      find.byKey(const Key('brand-samsung')),
    );
    expect(chip.selected, isTrue);
    await tester.tap(find.byKey(const Key('battery-open-settings')));
    await tester.pump();
    expect(world.batteryGateway.opened, 1);
    await unmount(tester, world.db);
  });

  testWidgets('a guide that cannot be loaded still offers the settings', (
    tester,
  ) async {
    final world = TestWorld(guideBundle: _BrokenBundle());
    await seedProfile(tester, world, city: testCities.first);
    await pumpApp(
      tester,
      world,
      const Scaffold(body: BatteryGuideStep()),
      size: const Size(400, 1400),
    );
    expect(
      find.text(
        lookupAppLocalizations(const Locale('en')).setupBatteryGuideUnavailable,
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('battery-open-settings')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await unmount(tester, world.db);
  });
}
