import 'types.dart';

/// Regions used to suggest a default calculation method (clarification D1).
enum Region {
  europe,
  farEast,
  northAmerica,
  arabianPeninsula,
  middleEastAndAfrica,
  southAsia,
  turkey,
  southeastAsia,

  /// Any country not listed above (for example Central Asia, Latin America,
  /// Oceania). It falls back to Muslim World League and the app says so.
  other,
}

const Set<String> _arabianPeninsula = {
  'SA',
  'YE',
  'OM',
  'AE',
  'QA',
  'BH',
  'KW',
};

const Set<String> _northAmerica = {'US', 'CA', 'MX'};

const Set<String> _southAsia = {'PK', 'IN', 'BD', 'LK', 'NP', 'BT', 'MV', 'AF'};

const Set<String> _southeastAsia = {
  'SG',
  'MY',
  'ID',
  'BN',
  'TH',
  'PH',
  'VN',
  'KH',
  'LA',
  'MM',
  'TL',
};

// Middle East outside the Arabian Peninsula. Iran and Iraq are included, so
// they default to Egypt; Shia users can choose Tehran or Jafari manually.
const Set<String> _middleEast = {'IQ', 'IR', 'SY', 'JO', 'LB', 'PS', 'IL'};

const Set<String> _africa = {
  'DZ',
  'AO',
  'BJ',
  'BW',
  'BF',
  'BI',
  'CV',
  'CM',
  'CF',
  'TD',
  'KM',
  'CG',
  'CD',
  'CI',
  'DJ',
  'EG',
  'GQ',
  'ER',
  'SZ',
  'ET',
  'GA',
  'GM',
  'GH',
  'GN',
  'GW',
  'KE',
  'LS',
  'LR',
  'LY',
  'MG',
  'MW',
  'ML',
  'MR',
  'MU',
  'MA',
  'MZ',
  'NA',
  'NE',
  'NG',
  'RW',
  'ST',
  'SN',
  'SC',
  'SL',
  'SO',
  'ZA',
  'SS',
  'SD',
  'TZ',
  'TG',
  'TN',
  'UG',
  'ZM',
  'ZW',
  'EH',
};

const Set<String> _europe = {
  'AL',
  'AD',
  'AT',
  'BY',
  'BE',
  'BA',
  'BG',
  'HR',
  'CY',
  'CZ',
  'DK',
  'EE',
  'FI',
  'FR',
  'DE',
  'GR',
  'HU',
  'IS',
  'IE',
  'IT',
  'XK',
  'LV',
  'LI',
  'LT',
  'LU',
  'MT',
  'MD',
  'MC',
  'ME',
  'NL',
  'MK',
  'NO',
  'PL',
  'PT',
  'RO',
  'RU',
  'SM',
  'RS',
  'SK',
  'SI',
  'ES',
  'SE',
  'CH',
  'UA',
  'GB',
  'VA',
};

const Set<String> _farEast = {'CN', 'JP', 'KR', 'KP', 'MN', 'TW', 'HK', 'MO'};

/// The region of an ISO 3166-1 alpha-2 [countryCode] (case-insensitive).
Region regionOf(String countryCode) {
  final code = countryCode.trim().toUpperCase();
  if (code == 'TR') return Region.turkey;
  if (_arabianPeninsula.contains(code)) return Region.arabianPeninsula;
  if (_northAmerica.contains(code)) return Region.northAmerica;
  if (_southAsia.contains(code)) return Region.southAsia;
  if (_southeastAsia.contains(code)) return Region.southeastAsia;
  if (_middleEast.contains(code) || _africa.contains(code)) {
    return Region.middleEastAndAfrica;
  }
  if (_europe.contains(code)) return Region.europe;
  if (_farEast.contains(code)) return Region.farEast;
  return Region.other;
}

/// The calculation method suggested for [region]. The user can always override.
CalculationMethod suggestedMethodForRegion(Region region) {
  switch (region) {
    case Region.europe:
    case Region.farEast:
    case Region.other:
      return CalculationMethod.muslimWorldLeague;
    case Region.northAmerica:
      return CalculationMethod.isna;
    case Region.arabianPeninsula:
      return CalculationMethod.ummAlQura;
    case Region.middleEastAndAfrica:
      return CalculationMethod.egypt;
    case Region.southAsia:
      return CalculationMethod.karachi;
    case Region.turkey:
      return CalculationMethod.diyanet;
    case Region.southeastAsia:
      return CalculationMethod.singapore;
  }
}

/// The calculation method suggested for an ISO 3166-1 alpha-2 [countryCode].
/// Unknown or empty codes fall back to Muslim World League.
CalculationMethod suggestedMethod(String countryCode) =>
    suggestedMethodForRegion(regionOf(countryCode));
