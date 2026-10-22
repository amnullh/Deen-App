import 'dart:io';

import 'package:deen_mobile/domain/entities/enums.dart';
import 'package:deen_mobile/domain/setup/oem_guide.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('shipped guides', () {
    for (final brand in OemBrand.values) {
      test('${brand.name} has steps in all four languages', () {
        final file = File(OemGuideRepository.assetPath(brand));
        expect(file.existsSync(), isTrue);
        final guide = OemGuideRepository.parse(file.readAsStringSync());
        expect(guide.brand, brand);
        for (final language in AppLanguage.values) {
          final steps = guide.steps[language];
          expect(steps, isNotNull, reason: language.name);
          expect(steps!.length, greaterThanOrEqualTo(3), reason: language.name);
          expect(steps.every((s) => s.trim().length > 10), isTrue);
        }
        // The same number of steps in every language, so "step 2" means the same.
        expect(
          {for (final l in AppLanguage.values) guide.steps[l]!.length}.length,
          1,
        );
      });
    }
  });

  group('brandFromManufacturer', () {
    test('maps sub-brands to the system they run', () {
      expect(brandFromManufacturer('Xiaomi'), OemBrand.xiaomi);
      expect(brandFromManufacturer('Redmi'), OemBrand.xiaomi);
      expect(brandFromManufacturer('POCO'), OemBrand.xiaomi);
      expect(brandFromManufacturer('realme'), OemBrand.oppo);
      expect(brandFromManufacturer('OPPO'), OemBrand.oppo);
      expect(brandFromManufacturer('iQOO'), OemBrand.vivo);
      expect(brandFromManufacturer('vivo'), OemBrand.vivo);
      expect(brandFromManufacturer('HUAWEI'), OemBrand.huawei);
      expect(brandFromManufacturer('HONOR'), OemBrand.huawei);
      expect(brandFromManufacturer('samsung'), OemBrand.samsung);
      expect(brandFromManufacturer('OnePlus'), OemBrand.oneplus);
    });

    test('other brands get the general guide, unknown input none', () {
      expect(brandFromManufacturer('Google'), OemBrand.other);
      expect(brandFromManufacturer('Motorola'), OemBrand.other);
      expect(brandFromManufacturer('  '), isNull);
    });
  });

  test('stepsFor falls back to English', () {
    const guide = OemGuide(
      brand: OemBrand.other,
      steps: {
        AppLanguage.en: ['a'],
      },
    );
    expect(guide.stepsFor(AppLanguage.ur), ['a']);
  });
}
