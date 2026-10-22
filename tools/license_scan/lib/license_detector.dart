/// Identifies SPDX licenses from the text of a LICENSE file.
///
/// Detection is signature based and deliberately conservative: text that does
/// not match a known signature is reported as unknown, which CI treats as a
/// failure, so a human must look at it.
library;

/// Licenses allowed for code and data linked into or shipped with the app.
const Set<String> allowedLicenses = {
  'MIT',
  'BSD-2-Clause',
  'BSD-3-Clause',
  'Apache-2.0',
  'ISC',
  'MPL-2.0',
  'Unicode-3.0',
  'Unicode-DFS-2016',
  'Zlib',
  'BlueOak-1.0.0',
};

/// Licenses allowed for fonts only.
const Set<String> allowedFontLicenses = {'OFL-1.1'};

/// Licenses that must never appear (copyleft or not open source).
const Set<String> forbiddenLicenses = {
  'GPL',
  'LGPL',
  'AGPL',
  'BUSL',
  'SSPL',
  'RSAL',
  'FSL',
  'CC-BY-NC',
  'CC-BY-ND',
  'CC-BY-SA',
};

class _Signature {
  const _Signature(this.spdx, this.all, [this.none = const []]);

  final String spdx;
  final List<String> all;
  final List<String> none;
}

const List<_Signature> _signatures = [
  _Signature('MIT', ['permission is hereby granted, free of charge']),
  _Signature('BSD-3-Clause', [
    'redistributions of source code must retain',
    'redistributions in binary form must reproduce',
    'neither the name of',
  ]),
  _Signature(
    'BSD-2-Clause',
    [
      'redistributions of source code must retain',
      'redistributions in binary form must reproduce',
    ],
    ['neither the name of'],
  ),
  _Signature('Apache-2.0', ['apache license', 'version 2.0']),
  _Signature('ISC', [
    'permission to use, copy, modify, and/or distribute this software',
  ]),
  _Signature('MPL-2.0', ['mozilla public license version 2.0']),
  _Signature('Unicode-3.0', ['unicode license v3']),
  _Signature('Unicode-DFS-2016', ['unicode, inc. license agreement']),
  _Signature('Zlib', ['this software is provided \'as-is\'', 'zlib']),
  _Signature('OFL-1.1', ['sil open font license', 'version 1.1']),
  _Signature('AGPL', ['gnu affero general public license']),
  _Signature('LGPL', ['gnu lesser general public license']),
  _Signature(
    'GPL',
    ['gnu general public license'],
    ['gnu lesser general public license', 'gnu affero general public license'],
  ),
  _Signature('BUSL', ['business source license']),
  _Signature('SSPL', ['server side public license']),
  _Signature('FSL', ['functional source license']),
];

/// Returns the SPDX identifiers found in [text] (empty when none matched).
///
/// A file that concatenates several licenses (for example MIT plus Apache-2.0)
/// yields all of them; every one must be allowed.
Set<String> detectLicenses(String text) {
  var normalized = text.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  // The MPL-2.0 text defines "Secondary Licenses" by naming the GPL family. That
  // sentence is not a grant of those licenses, so remove it before matching.
  normalized = normalized.replaceAll(
    RegExp(
      r'means either the gnu general public license, version 2\.0, the gnu '
      r'lesser general public license, version 2\.1, the gnu affero general '
      r'public license, version 3\.0, or any later versions of those licenses',
    ),
    '',
  );
  final found = <String>{};
  for (final signature in _signatures) {
    final matches = signature.all.every(normalized.contains);
    final excluded = signature.none.any(normalized.contains);
    if (matches && !excluded) {
      found.add(signature.spdx);
    }
  }
  // A BSD-3 text also contains the BSD-2 phrases; keep only the stricter match.
  if (found.contains('BSD-3-Clause')) {
    found.remove('BSD-2-Clause');
  }
  return found;
}

/// Result of judging a set of detected licenses.
enum LicenseVerdict { allowed, forbidden, unknown }

/// Judges [detected] against the allowlist. [fontOnly] enables the font
/// allowlist (SIL OFL 1.1).
LicenseVerdict judge(Set<String> detected, {bool fontOnly = false}) {
  if (detected.isEmpty) return LicenseVerdict.unknown;
  if (detected.any(forbiddenLicenses.contains)) return LicenseVerdict.forbidden;
  final allowed = {...allowedLicenses, if (fontOnly) ...allowedFontLicenses};
  return detected.every(allowed.contains)
      ? LicenseVerdict.allowed
      : LicenseVerdict.unknown;
}
