/// Builds `content/cities/cities.db` from GeoNames `cities15000` and the
/// language-filtered `alternateNamesV2` dumps.
///
/// Usage:
///   dart run tools/geonames_build/bin/build.dart [options]
///
/// Options:
///   --out FILE         output database (default content/cities/cities.db)
///   --cache-dir DIR    where the zips are downloaded once (default: a
///                        folder in the system temp directory, outside the repo)
///   --build-date DATE  yyyy-MM-dd stored in the metadata (default: today,
///                        UTC); pass it to rebuild a byte-identical file
///   --languages LIST   comma separated ISO 639-1 codes (default ar,ur,id)
library;

import 'dart:io';

import 'package:geonames_build/build_cities.dart';
import 'package:geonames_build/geonames_download.dart';
import 'package:path/path.dart' as p;

Future<void> main(List<String> args) async {
  final options = _parseArgs(args);
  if (options == null) {
    stderr.writeln(
      'Usage: dart run tools/geonames_build/bin/build.dart '
      '[--out file] [--cache-dir dir] [--build-date yyyy-MM-dd] '
      '[--languages ar,ur,id]',
    );
    exit(64);
  }
  final root = _findRepoRoot();
  final outputPath =
      options['out'] ?? p.join(root.path, 'content', 'cities', 'cities.db');
  final cacheDir = Directory(
    options['cache-dir'] ??
        p.join(Directory.systemTemp.path, 'deen_geonames_cache'),
  );
  final buildDate = options['build-date'] ?? _today();
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(buildDate)) {
    stderr.writeln('--build-date must look like 2026-10-21');
    exit(64);
  }
  final languages = options['languages'] == null
      ? defaultLanguages
      : options['languages']!.split(',').map((s) => s.trim()).toSet();

  try {
    final report = await buildFromGeonames(
      cacheDir: cacheDir,
      outputPath: outputPath,
      buildDate: buildDate,
      languages: languages,
      log: stdout.writeln,
    );
    final size = File(outputPath).lengthSync();
    stdout.writeln(
      'Wrote $outputPath: ${report.cityCount} cities, ${report.nameCount} '
      'search names, ${(size / 1024 / 1024).toStringAsFixed(2)} MB.',
    );
  } on BuildToolException catch (e) {
    stderr.writeln(e);
    exit(1);
  }
}

Map<String, String>? _parseArgs(List<String> args) {
  const known = {'out', 'cache-dir', 'build-date', 'languages'};
  final result = <String, String>{};
  for (var i = 0; i < args.length; i += 2) {
    final flag = args[i];
    if (!flag.startsWith('--') || i + 1 >= args.length) return null;
    final name = flag.substring(2);
    if (!known.contains(name)) return null;
    result[name] = args[i + 1];
  }
  return result;
}

String _today() {
  final now = DateTime.now().toUtc();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${now.year}-${two(now.month)}-${two(now.day)}';
}

/// The repository root: the nearest parent folder that has `content/`.
Directory _findRepoRoot() {
  var dir = Directory.current.absolute;
  while (true) {
    if (Directory(p.join(dir.path, 'content')).existsSync() &&
        File(p.join(dir.path, 'pubspec.yaml')).existsSync()) {
      return dir;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) return Directory.current;
    dir = parent;
  }
}
