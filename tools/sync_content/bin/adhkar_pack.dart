/// Builds the adhkar pack from `content/adhkar/source/*.json` into
/// `content/adhkar/pack/*.json` and validates every entry (T165).
///
/// Fails (exit code 1) and writes nothing when any entry lacks Arabic text, a
/// reference, a source id, a cleared license, a reviewer name or a review
/// date, or has a translation without a cleared license.
///
/// Usage: `dart run tools/sync_content/bin/adhkar_pack.dart [--check]`
///   --check   validate and compare with the committed pack; write nothing
///   --source DIR, --out DIR   override the folders (used by tests)
///
/// Format: `tools/sync_content/adhkar_pack_schema.md`.
library;

import 'dart:io';

import 'package:license_scan/repo_io.dart';
import 'package:path/path.dart' as p;
import 'package:sync_content/adhkar_pack.dart';

void main(List<String> args) {
  var check = false;
  String? sourceArg;
  String? outArg;
  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--check':
        check = true;
      case '--source' when i + 1 < args.length:
        sourceArg = args[++i];
      case '--out' when i + 1 < args.length:
        outArg = args[++i];
      default:
        stderr.writeln(
          'Unknown or incomplete option ${args[i]}.\n'
          'Usage: adhkar_pack.dart [--check] [--source DIR] [--out DIR]',
        );
        exit(64);
    }
  }
  final root = findRepoRoot();
  final sourceDir = Directory(
    sourceArg ?? p.join(root.path, 'content', 'adhkar', 'source'),
  );
  final outDir = Directory(
    outArg ?? p.join(root.path, 'content', 'adhkar', 'pack'),
  );

  final sources = <String, String>{};
  if (sourceDir.existsSync()) {
    for (final entity in sourceDir.listSync()) {
      if (entity is File && entity.path.endsWith('.json')) {
        sources[p.basename(entity.path)] = entity.readAsStringSync();
      }
    }
  }
  if (sources.isEmpty) {
    stdout.writeln(
      'No adhkar source files in ${sourceDir.path}; nothing to build. '
      '(Adhkar content is not cleared yet, plan D-4.)',
    );
    return;
  }

  final result = buildAdhkarPack(sources);
  if (result.issues.isNotEmpty) {
    for (final issue in result.issues) {
      stderr.writeln(issue);
    }
    stderr.writeln('${result.issues.length} problem(s); no pack was written.');
    exit(1);
  }

  var stale = 0;
  for (final entry in result.packFiles.entries) {
    final target = File(p.join(outDir.path, entry.key));
    if (check) {
      if (!target.existsSync() || target.readAsStringSync() != entry.value) {
        stderr.writeln('${target.path} is out of date; run without --check.');
        stale++;
      }
    } else {
      outDir.createSync(recursive: true);
      target.writeAsStringSync(entry.value);
      stdout.writeln('Wrote ${target.path}');
    }
  }
  if (stale > 0) exit(1);
  stdout.writeln(
    check
        ? 'OK: ${result.packFiles.length} pack file(s) are up to date.'
        : 'Built ${result.packFiles.length} pack file(s).',
  );
}
