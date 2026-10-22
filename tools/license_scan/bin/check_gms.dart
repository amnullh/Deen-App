/// Fails (exit code 1) when the Android Gradle dependency report contains a
/// proprietary Google library (Play Services, Firebase, Play Core).
///
/// Usage:
///   cd apps/mobile/android && ./gradlew :app:dependencies --configuration releaseRuntimeClasspath > /tmp/deps.txt
///   dart run tools/license_scan/bin/check_gms.dart /tmp/deps.txt
library;

import 'dart:io';

import 'package:license_scan/scanner.dart';

void main(List<String> args) {
  if (args.length != 1) {
    stderr.writeln('Usage: check_gms.dart <gradle-dependencies-report.txt>');
    exit(64);
  }
  final file = File(args.single);
  if (!file.existsSync()) {
    stderr.writeln('Report not found: ${args.single}');
    exit(66);
  }
  final findings = checkGradleReport(file.readAsStringSync());
  if (findings.isEmpty) {
    stdout.writeln('OK: no proprietary Google libraries in the Android build.');
    return;
  }
  for (final finding in findings) {
    stderr.writeln(finding);
  }
  stderr.writeln('${findings.length} proprietary librar(ies) found.');
  exit(1);
}
