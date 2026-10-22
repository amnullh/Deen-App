/// File-system helpers shared by the license scan command line tools.
library;

import 'dart:io';

import 'package:path/path.dart' as p;

/// Finds the repository root: the nearest parent directory containing both
/// `pubspec.lock` and `content/LICENSES.md`, starting from [start].
Directory findRepoRoot([Directory? start]) {
  var dir = (start ?? Directory.current).absolute;
  while (true) {
    final hasLock = File(p.join(dir.path, 'pubspec.lock')).existsSync();
    final hasRegister = File(p.join(dir.path, 'content', 'LICENSES.md'))
        .existsSync();
    if (hasLock && hasRegister) return dir;
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError(
        'Repository root not found (needs pubspec.lock and content/LICENSES.md). '
        'Run `dart pub get` first.',
      );
    }
    dir = parent;
  }
}

/// The pub cache directory (`PUB_CACHE` or `~/.pub-cache`).
Directory pubCacheDir() {
  final env = Platform.environment;
  final override = env['PUB_CACHE'];
  if (override != null && override.isNotEmpty) return Directory(override);
  final home = env['HOME'] ?? env['USERPROFILE'] ?? '';
  return Directory(p.join(home, '.pub-cache'));
}

/// Reads the LICENSE file of a hosted package from the pub cache, or null.
String? readPackageLicense(String name, String version) {
  final base = Directory(
    p.join(pubCacheDir().path, 'hosted', 'pub.dev', '$name-$version'),
  );
  if (!base.existsSync()) return null;
  const candidates = [
    'LICENSE',
    'LICENSE.md',
    'LICENSE.txt',
    'LICENCE',
    'COPYING',
    'license',
  ];
  final buffer = StringBuffer();
  var found = false;
  for (final name in candidates) {
    final file = File(p.join(base.path, name));
    if (file.existsSync()) {
      buffer.writeln(file.readAsStringSync());
      found = true;
    }
  }
  return found ? buffer.toString() : null;
}

/// Lists files under [relativeDir] as repo-relative POSIX paths.
List<String> listFiles(Directory root, String relativeDir) {
  final dir = Directory(p.join(root.path, relativeDir));
  if (!dir.existsSync()) return const [];
  final files = <String>[];
  for (final entity in dir.listSync(recursive: true, followLinks: false)) {
    if (entity is! File) continue;
    final relative = p.relative(entity.path, from: root.path);
    final posix = p.posix.joinAll(p.split(relative));
    final base = p.basename(posix);
    if (base == '.DS_Store' || base == '.gitkeep') continue;
    files.add(posix);
  }
  files.sort();
  return files;
}

/// The content register: `content/LICENSES.md` plus every Markdown file under
/// `content/register/`. Parallel work adds its rows as separate files there so
/// no two people edit the same file; the scan treats them as one register.
String readRegisterText(Directory root) {
  final buffer = StringBuffer(
    File(p.join(root.path, 'content', 'LICENSES.md')).readAsStringSync(),
  );
  final extra = Directory(p.join(root.path, 'content', 'register'));
  if (extra.existsSync()) {
    final files =
        extra
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.md'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    for (final file in files) {
      buffer
        ..writeln()
        ..writeln(file.readAsStringSync());
    }
  }
  return buffer.toString();
}
