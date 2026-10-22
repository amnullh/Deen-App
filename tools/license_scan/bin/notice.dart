/// Writes `LICENSES/NOTICE` from `pubspec.lock` and the content register.
///
/// Usage: `dart run tools/license_scan/bin/notice.dart [--check]`
/// `--check` fails when the file on disk is out of date (used in CI).
library;

import 'dart:io';

import 'package:license_scan/notice.dart';
import 'package:license_scan/repo_io.dart';
import 'package:license_scan/scanner.dart';
import 'package:path/path.dart' as p;

void main(List<String> args) {
  final check = args.contains('--check');
  final root = findRepoRoot();
  final packages = parsePubspecLock(
    File(p.join(root.path, 'pubspec.lock')).readAsStringSync(),
  );
  final notice = buildNotice(
    packages: noticePackages(
      packages,
      (package) => readPackageLicense(package.name, package.version),
    ),
    registerText: readRegisterText(root),
    // A fixed date would make the file stale on every run; the register's own
    // content changes whenever something worth noting changes, so the notice is
    // generated without a timestamp that varies between runs.
    generatedOn: 'the last change to pubspec.lock or content/LICENSES.md',
  );
  final target = File(p.join(root.path, 'LICENSES', 'NOTICE'));
  if (check) {
    final current = target.existsSync() ? target.readAsStringSync() : '';
    if (current != notice) {
      stderr.writeln('LICENSES/NOTICE is out of date; run notice.dart.');
      exit(1);
    }
    stdout.writeln('LICENSES/NOTICE is up to date.');
    return;
  }
  target.parent.createSync(recursive: true);
  target.writeAsStringSync(notice);
  stdout.writeln('Wrote ${target.path} (${packages.length} packages).');
}
