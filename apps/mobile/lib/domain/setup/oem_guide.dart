import 'dart:convert';

import 'package:flutter/services.dart';

import '../entities/enums.dart';

/// Phone brands that need their own battery instructions (spec Story 1,
/// scenario 7). [other] is the generic guide for every other brand.
enum OemBrand { xiaomi, oppo, vivo, huawei, samsung, oneplus, other }

/// Maps the manufacturer string the phone reports (for example `Redmi`,
/// `realme`, `HONOR`) to the brand whose guide fits, or null when none does.
///
/// Sub-brands that share their parent's system are folded in: Redmi and POCO
/// run Xiaomi's system, realme runs Oppo's, iQOO runs Vivo's, Honor was part
/// of Huawei.
OemBrand? brandFromManufacturer(String manufacturer) {
  final name = manufacturer.trim().toLowerCase();
  if (name.isEmpty) return null;
  const families = {
    OemBrand.xiaomi: ['xiaomi', 'redmi', 'poco'],
    OemBrand.oppo: ['oppo', 'realme'],
    OemBrand.vivo: ['vivo', 'iqoo'],
    OemBrand.huawei: ['huawei', 'honor'],
    OemBrand.samsung: ['samsung'],
    OemBrand.oneplus: ['oneplus'],
  };
  for (final entry in families.entries) {
    if (entry.value.any(name.contains)) return entry.key;
  }
  return OemBrand.other;
}

/// The phone's brand, if the platform can tell. The default has no native
/// source, so the user picks their brand from a list.
abstract interface class DeviceBrandSource {
  Future<OemBrand?> detect();
}

class NoDeviceBrandSource implements DeviceBrandSource {
  const NoDeviceBrandSource();

  @override
  Future<OemBrand?> detect() async => null;
}

/// The steps for one brand, in one language.
class OemGuide {
  const OemGuide({required this.brand, required this.steps});

  final OemBrand brand;
  final Map<AppLanguage, List<String>> steps;

  /// Steps in [language], falling back to English if that language is missing.
  List<String> stepsFor(AppLanguage language) =>
      steps[language] ?? steps[AppLanguage.en] ?? const [];
}

/// Loads the guides written for this project from `assets/oem_guides/`.
class OemGuideRepository {
  OemGuideRepository(this._bundle);

  final AssetBundle _bundle;

  static String assetPath(OemBrand brand) =>
      'assets/oem_guides/${brand.name}.json';

  /// The guide for [brand]. Throws if the asset is missing or malformed; callers
  /// show a generic message and the settings button instead.
  Future<OemGuide> load(OemBrand brand) async {
    final text = await _bundle.loadString(assetPath(brand));
    return parse(text);
  }

  /// Parses one guide file.
  static OemGuide parse(String json) {
    final data = jsonDecode(json) as Map<String, Object?>;
    final brand = OemBrand.values.byName(data['brand']! as String);
    final steps = data['steps']! as Map<String, Object?>;
    return OemGuide(
      brand: brand,
      steps: {
        for (final language in AppLanguage.values)
          if (steps[language.name] != null)
            language: [
              for (final step in steps[language.name]! as List<Object?>)
                step as String,
            ],
      },
    );
  }
}
