/// Fails (exit code 1) when a dependency has a disallowed or unknown license,
/// a direct dependency is missing from the register, or a shipped file has no
/// register entry.
///
/// Usage: `dart run tools/license_scan/bin/scan.dart` from anywhere in the repo.
library;

import 'dart:io';

import 'package:license_scan/repo_io.dart';
import 'package:license_scan/scanner.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

void main(List<String> args) {
  final root = findRepoRoot();
  final lockText = File(p.join(root.path, 'pubspec.lock')).readAsStringSync();
  final registerText = readRegisterText(root);
  final denylist = File(
    p.join(root.path, 'tools', 'license_scan', 'denylist.txt'),
  ).readAsStringSync();

  final packages = parsePubspecLock(lockText);

  // The workspace lock marks nothing as direct; read the member pubspecs.
  final rootPubspec = loadYaml(
    File(p.join(root.path, 'pubspec.yaml')).readAsStringSync(),
  ) as YamlMap;
  final memberDirs = [
    for (final member in (rootPubspec['workspace'] as YamlList? ?? YamlList()))
      member as String,
  ];
  final memberTexts = <String>[];
  final memberNames = <String>{};
  for (final dir in memberDirs) {
    final text = File(p.join(root.path, dir, 'pubspec.yaml'))
        .readAsStringSync();
    memberTexts.add(text);
    memberNames.add((loadYaml(text) as YamlMap)['name'] as String);
  }
  final directNames = directDependencyNames(
    memberTexts,
    memberNames: memberNames,
  );
  final licenseTexts = <String, String?>{
    for (final package in packages)
      if (package.source == 'hosted')
        package.name: readPackageLicense(package.name, package.version),
  };

  final findings = <Finding>[
    ...checkPackageLicenses(packages, licenseTexts),
    ...checkDirectDependenciesRegistered(directNames, registerText),
    ...checkDenylist(packages.map((package) => package.name), denylist),
    ...checkContentRegistered(
      [
        ...listFiles(root, 'content'),
        ...listFiles(root, p.join('apps', 'mobile', 'assets')),
        // Files copied into the platform projects by tools/sync_content.
        ...listFiles(
          root,
          p.join(
            'apps',
            'mobile',
            'android',
            'app',
            'src',
            'main',
            'res',
            'raw',
          ),
        ),
        ...listFiles(root, p.join('apps', 'mobile', 'ios', 'Runner', 'Sounds')),
      ],
      registerText,
      ignoredPrefixes: {'content/LICENSES.md', 'content/register/'},
    ),
  ];

  stdout.writeln(
    'Scanned ${packages.length} packages and the content register.',
  );
  if (findings.isEmpty) {
    stdout.writeln('OK: no license, register or tracker problems.');
    return;
  }
  for (final finding in findings) {
    stderr.writeln(finding);
  }
  stderr.writeln('${findings.length} problem(s) found.');
  exit(1);
}
