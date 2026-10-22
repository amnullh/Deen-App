/// Checks used by CI to enforce constitution principles 4 and 10:
/// allowed licenses, no network permission, no tracker SDKs, and a register
/// entry for every bundled file.
library;

import 'package:yaml/yaml.dart';

import 'license_detector.dart';

/// One problem found by a check. Any finding fails CI.
class Finding {
  const Finding(this.check, this.subject, this.message);

  final String check;
  final String subject;
  final String message;

  @override
  String toString() => '[$check] $subject: $message';
}

/// A dependency listed in `pubspec.lock`.
class LockedPackage {
  const LockedPackage({
    required this.name,
    required this.version,
    required this.source,
    required this.isDirect,
  });

  final String name;
  final String version;

  /// `hosted`, `sdk`, `path` or `git`.
  final String source;
  final bool isDirect;
}

/// Parses the text of a `pubspec.lock` file.
List<LockedPackage> parsePubspecLock(String lockText) {
  final doc = loadYaml(lockText) as YamlMap;
  final packages = doc['packages'] as YamlMap? ?? YamlMap();
  final result = <LockedPackage>[];
  for (final entry in packages.entries) {
    final info = entry.value as YamlMap;
    final dependency = (info['dependency'] as String?) ?? '';
    result.add(
      LockedPackage(
        name: entry.key as String,
        version: (info['version'] as String?) ?? '',
        source: (info['source'] as String?) ?? '',
        isDirect: dependency.startsWith('direct'),
      ),
    );
  }
  result.sort((a, b) => a.name.compareTo(b.name));
  return result;
}

/// Judges the license text of each hosted package.
///
/// [licenseTextByPackage] maps a package name to the contents of its LICENSE
/// file, or null when no license file exists. Packages whose source is `sdk`
/// or `path` are not checked here (SDK packages are covered by the Flutter SDK
/// license, which is recorded in the register; path packages are our own).
List<Finding> checkPackageLicenses(
  List<LockedPackage> packages,
  Map<String, String?> licenseTextByPackage,
) {
  final findings = <Finding>[];
  for (final package in packages) {
    if (package.source != 'hosted') continue;
    final text = licenseTextByPackage[package.name];
    if (text == null) {
      findings.add(Finding('license', package.name, 'no LICENSE file found'));
      continue;
    }
    final detected = detectLicenses(text);
    switch (judge(detected)) {
      case LicenseVerdict.allowed:
        break;
      case LicenseVerdict.forbidden:
        findings.add(
          Finding('license', package.name, 'forbidden license: $detected'),
        );
      case LicenseVerdict.unknown:
        findings.add(
          Finding(
            'license',
            package.name,
            'unknown license (detected: ${detected.isEmpty ? 'none' : detected}); review by a person',
          ),
        );
    }
  }
  return findings;
}

/// Names of the direct dependencies declared in workspace member pubspecs.
///
/// A workspace lock file marks nothing as direct, so the member pubspecs are the
/// source of truth. SDK dependencies (`flutter`, `flutter_test`, ...) and
/// workspace members themselves ([memberNames]) are skipped.
Set<String> directDependencyNames(
  Iterable<String> memberPubspecTexts, {
  Set<String> memberNames = const {},
}) {
  final names = <String>{};
  for (final text in memberPubspecTexts) {
    final doc = loadYaml(text);
    if (doc is! YamlMap) continue;
    for (final section in const ['dependencies', 'dev_dependencies']) {
      final deps = doc[section];
      if (deps is! YamlMap) continue;
      for (final entry in deps.entries) {
        final value = entry.value;
        final isSdk = value is YamlMap && value.containsKey('sdk');
        final name = entry.key as String;
        if (!isSdk && !memberNames.contains(name)) names.add(name);
      }
    }
  }
  return names;
}

/// Every direct dependency must be named in the content register.
List<Finding> checkDirectDependenciesRegistered(
  Set<String> directNames,
  String registerText,
) {
  final findings = <Finding>[];
  for (final name in directNames.toList()..sort()) {
    if (!registerText.contains(name)) {
      findings.add(
        Finding(
          'register',
          name,
          'direct dependency has no row in content/LICENSES.md',
        ),
      );
    }
  }
  return findings;
}

/// Every shipped file must have an entry in the register.
///
/// A file counts as registered when the register mentions its relative path,
/// its file name, or a wildcard entry for its directory written as `dir/*`
/// (for example `apps/mobile/assets/oem_guides/*`). Merely mentioning a
/// directory does not register the files in it.
/// [ignoredPrefixes] lists paths that never need an entry (the register itself).
List<Finding> checkContentRegistered(
  List<String> relativePaths,
  String registerText, {
  Set<String> ignoredPrefixes = const {},
}) {
  final findings = <Finding>[];
  for (final path in relativePaths) {
    if (ignoredPrefixes.any(path.startsWith)) continue;
    final name = path.split('/').last;
    final wildcard = path.contains('/')
        ? '${path.substring(0, path.lastIndexOf('/'))}/*'
        : '';
    final registered =
        registerText.contains(path) ||
        registerText.contains(name) ||
        (wildcard.isNotEmpty && registerText.contains(wildcard));
    if (!registered) {
      findings.add(Finding('content', path, 'no entry in content/LICENSES.md'));
    }
  }
  return findings;
}

/// Permissions the release build must not declare (FR-001, FR-002).
const Set<String> forbiddenAndroidPermissions = {
  'android.permission.INTERNET',
  'android.permission.ACCESS_NETWORK_STATE',
  'android.permission.USE_EXACT_ALARM',
  'android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS',
  'android.permission.READ_PHONE_STATE',
  'android.permission.USE_FULL_SCREEN_INTENT',
  'com.google.android.gms.permission.AD_ID',
};

/// Checks an Android manifest (the release/main one) for forbidden permissions.
List<Finding> checkAndroidManifest(
  String manifestXml, {
  String name = 'AndroidManifest.xml',
}) {
  final findings = <Finding>[];
  final pattern = RegExp(r'<uses-permission[^>]*android:name="([^"]+)"');
  for (final match in pattern.allMatches(manifestXml)) {
    final permission = match.group(1)!;
    if (forbiddenAndroidPermissions.contains(permission)) {
      findings.add(
        Finding('network', name, 'declares forbidden permission $permission'),
      );
    }
  }
  return findings;
}

/// iOS Info.plist keys that indicate tracking or relaxed network security.
const List<String> forbiddenPlistKeys = [
  'NSUserTrackingUsageDescription',
  'NSAdvertisingAttributionReportEndpoint',
  'NSAllowsArbitraryLoads',
  'SKAdNetworkItems',
];

List<Finding> checkIosPlist(String plistXml, {String name = 'Info.plist'}) {
  final findings = <Finding>[];
  for (final key in forbiddenPlistKeys) {
    if (plistXml.contains('<key>$key</key>')) {
      findings.add(Finding('network', name, 'contains forbidden key $key'));
    }
  }
  return findings;
}

/// Matches dependency names against tracker and analytics patterns.
///
/// A pattern ending in `*` is a prefix match; otherwise it is an exact name.
/// Blank lines and lines starting with `#` are ignored.
List<Finding> checkDenylist(Iterable<String> names, String denylistText) {
  final patterns = denylistText
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty && !line.startsWith('#'))
      .toList();
  final findings = <Finding>[];
  for (final name in names) {
    for (final pattern in patterns) {
      final hit = pattern.endsWith('*')
          ? name.startsWith(pattern.substring(0, pattern.length - 1))
          : name == pattern;
      if (hit) {
        findings.add(
          Finding('tracker', name, 'matches denylist entry "$pattern"'),
        );
        break;
      }
    }
  }
  return findings;
}

/// Scans a Gradle `dependencies` report for proprietary Google libraries
/// (constitution principle 4 and the native-code clause).
List<Finding> checkGradleReport(String reportText) {
  const bannedPrefixes = [
    'com.google.android.gms',
    'com.google.firebase',
    'com.google.android.play',
    'com.google.android.datatransport',
    'com.crashlytics',
  ];
  final findings = <Finding>[];
  final seen = <String>{};
  for (final line in reportText.split('\n')) {
    for (final prefix in bannedPrefixes) {
      final index = line.indexOf(prefix);
      if (index == -1) continue;
      final coordinate = line.substring(index).split(' ').first;
      if (seen.add(coordinate)) {
        findings.add(
          Finding(
            'gms',
            coordinate,
            'proprietary library in the Android build',
          ),
        );
      }
    }
  }
  return findings;
}
