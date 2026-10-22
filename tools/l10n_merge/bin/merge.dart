/// Regenerates `apps/mobile/lib/l10n/app_*.arb` from the fragments.
///
/// Usage: `dart run tools/l10n_merge/bin/merge.dart [--check]`
/// `--check` only verifies that the ARB files are up to date (used in CI).
library;

import 'dart:io';

import 'package:l10n_merge/merge.dart';
import 'package:path/path.dart' as p;

void main(List<String> args) {
  final check = args.contains('--check');
  var dir = Directory.current.absolute;
  while (!File(p.join(dir.path, 'apps', 'mobile', 'l10n.yaml')).existsSync()) {
    if (dir.parent.path == dir.path) {
      stderr.writeln('Run this from inside the repository.');
      exit(64);
    }
    dir = dir.parent;
  }
  final l10n = Directory(p.join(dir.path, 'apps', 'mobile', 'lib', 'l10n'));
  final fragmentDir = Directory(p.join(l10n.path, 'fragments'));
  final fragments = <String, String>{
    for (final file in fragmentDir.listSync().whereType<File>())
      if (file.path.endsWith('.json'))
        p.basename(file.path): file.readAsStringSync(),
  };

  final result = mergeFragments(fragments);
  if (!result.ok) {
    result.problems.forEach(stderr.writeln);
    exit(1);
  }

  var stale = false;
  for (final language in languages) {
    final target = File(p.join(l10n.path, 'app_$language.arb'));
    final current = target.existsSync() ? target.readAsStringSync() : '';
    if (current != result.arbByLanguage[language]) {
      stale = true;
      if (!check) target.writeAsStringSync(result.arbByLanguage[language]!);
    }
  }
  if (check && stale) {
    stderr.writeln(
      'ARB files are out of date; run tools/l10n_merge/bin/merge.dart',
    );
    exit(1);
  }
  stdout.writeln(
    stale ? 'Updated ARB files.' : 'ARB files already up to date.',
  );
}
