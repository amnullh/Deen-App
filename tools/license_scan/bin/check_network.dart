/// Fails (exit code 1) when the app could reach the network or track users:
/// the release Android manifest declares INTERNET or other forbidden
/// permissions, the iOS Info.plist has tracking or relaxed-network keys, or a
/// tracker SDK appears among the dependencies (FR-001, FR-002, principle 4).
///
/// The debug and profile manifests are not checked because Flutter adds
/// INTERNET there for hot reload; only the main manifest ships.
library;

import 'dart:io';

import 'package:license_scan/repo_io.dart';
import 'package:license_scan/scanner.dart';
import 'package:path/path.dart' as p;

void main(List<String> args) {
  final root = findRepoRoot();
  final findings = <Finding>[];

  final manifest = File(
    p.join(
      root.path,
      'apps',
      'mobile',
      'android',
      'app',
      'src',
      'main',
      'AndroidManifest.xml',
    ),
  );
  if (manifest.existsSync()) {
    findings.addAll(
      checkAndroidManifest(
        manifest.readAsStringSync(),
        name: 'android/app/src/main/AndroidManifest.xml',
      ),
    );
  } else {
    findings.add(
      const Finding('network', 'AndroidManifest.xml', 'file not found'),
    );
  }

  final plist = File(
    p.join(root.path, 'apps', 'mobile', 'ios', 'Runner', 'Info.plist'),
  );
  if (plist.existsSync()) {
    findings.addAll(
      checkIosPlist(plist.readAsStringSync(), name: 'ios/Runner/Info.plist'),
    );
  }

  final lock = File(p.join(root.path, 'pubspec.lock'));
  final denylist = File(
    p.join(root.path, 'tools', 'license_scan', 'denylist.txt'),
  );
  if (lock.existsSync() && denylist.existsSync()) {
    final names = parsePubspecLock(lock.readAsStringSync()).map((e) => e.name);
    findings.addAll(checkDenylist(names, denylist.readAsStringSync()));
  }

  if (findings.isEmpty) {
    stdout.writeln('OK: no network permission, tracking key or tracker SDK.');
    return;
  }
  for (final finding in findings) {
    stderr.writeln(finding);
  }
  stderr.writeln('${findings.length} problem(s) found.');
  exit(1);
}
