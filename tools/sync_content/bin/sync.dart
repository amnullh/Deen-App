/// Copies content into the app and verifies it.
///
/// Fails (exit code 1) when a content file has no entry in
/// `content/LICENSES.md`, or an iOS notification clip is 30 seconds or longer
/// (or its length cannot be read).
///
/// Usage: `dart run tools/sync_content/bin/sync.dart [--check]`
/// `--check` verifies only and copies nothing (used in CI).
library;

import 'dart:io';

import 'package:license_scan/repo_io.dart';
import 'package:license_scan/scanner.dart';
import 'package:path/path.dart' as p;
import 'package:sync_content/audio_duration.dart';
import 'package:sync_content/sync_plan.dart';

void main(List<String> args) {
  final checkOnly = args.contains('--check');
  final root = findRepoRoot();
  final registerText = readRegisterText(root);

  final sources = listFiles(root, 'content');
  final findings = <Finding>[
    ...checkContentRegistered(
      sources,
      registerText,
      ignoredPrefixes: {'content/LICENSES.md', 'content/register/'},
    ),
  ];

  final actions = <CopyAction>[for (final source in sources) ?planCopy(source)];

  for (final action in actions) {
    if (action.source.startsWith('content/audio/ios/')) {
      final bytes = File(p.join(root.path, action.source)).readAsBytesSync();
      final seconds = audioDurationSeconds(bytes);
      if (seconds == null) {
        findings.add(
          Finding(
            'audio',
            action.source,
            'cannot read the duration; use WAV, AIFF or CAF (linear PCM or IMA4)',
          ),
        );
      } else if (seconds >= iosNotificationSoundLimitSeconds) {
        findings.add(
          Finding(
            'audio',
            action.source,
            'is ${seconds.toStringAsFixed(1)} s; iOS plays notification sounds '
                'only when shorter than 30 s',
          ),
        );
      }
    }
  }

  if (findings.isNotEmpty) {
    for (final finding in findings) {
      stderr.writeln(finding);
    }
    stderr.writeln('${findings.length} problem(s) found; nothing was copied.');
    exit(1);
  }

  if (checkOnly) {
    stdout.writeln('OK: ${actions.length} content file(s) verified.');
    return;
  }

  for (final action in actions) {
    final target = File(p.join(root.path, action.destination));
    target.parent.createSync(recursive: true);
    File(p.join(root.path, action.source)).copySync(target.path);
    stdout.writeln(action);
  }
  stdout.writeln('Copied ${actions.length} file(s).');
}
