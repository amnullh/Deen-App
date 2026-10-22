/// Prints a Markdown table of every hosted package in `pubspec.lock` with the
/// licenses detected in its LICENSE file. Used to fill and audit
/// `content/LICENSES.md` (task T033). Does not fail; `scan.dart` enforces.
///
/// Usage: `dart run tools/license_scan/bin/report.dart [--direct]`
library;

import 'dart:io';

import 'package:license_scan/license_detector.dart';
import 'package:license_scan/repo_io.dart';
import 'package:license_scan/scanner.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

void main(List<String> args) {
  final directOnly = args.contains('--direct');
  final root = findRepoRoot();
  final packages = parsePubspecLock(
    File(p.join(root.path, 'pubspec.lock')).readAsStringSync(),
  );

  final rootPubspec = loadYaml(
    File(p.join(root.path, 'pubspec.yaml')).readAsStringSync(),
  ) as YamlMap;
  final memberTexts = <String>[];
  final memberNames = <String>{};
  for (final dir in (rootPubspec['workspace'] as YamlList? ?? YamlList())) {
    final text = File(p.join(root.path, dir as String, 'pubspec.yaml'))
        .readAsStringSync();
    memberTexts.add(text);
    memberNames.add((loadYaml(text) as YamlMap)['name'] as String);
  }
  final direct = directDependencyNames(memberTexts, memberNames: memberNames);

  stdout.writeln('| Package | Version | Detected license | Direct |');
  stdout.writeln('|---------|---------|------------------|--------|');
  for (final package in packages) {
    if (package.source != 'hosted') continue;
    final isDirect = direct.contains(package.name);
    if (directOnly && !isDirect) continue;
    final text = readPackageLicense(package.name, package.version);
    final detected = text == null ? <String>{} : detectLicenses(text);
    stdout.writeln(
      '| ${package.name} | ${package.version} | '
      '${detected.isEmpty ? (text == null ? 'NO LICENSE FILE' : 'UNKNOWN') : (detected.toList()..sort()).join(' + ')} | '
      '${isDirect ? 'yes' : 'no'} |',
    );
  }
}
