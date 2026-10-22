/// Writes the project-created sounds into `content/audio/shared/`:
/// `tone-short.wav` (T099) and `tasbih-tick.wav` (T155).
///
/// Usage: `dart run tools/sync_content/bin/make_tones.dart [output-dir]`
/// The output directory defaults to `content/audio/shared` in the repository.
library;

import 'dart:io';

import 'package:license_scan/repo_io.dart';
import 'package:path/path.dart' as p;
import 'package:sync_content/tone_synth.dart';

void main(List<String> args) {
  final outDir = Directory(
    args.isNotEmpty
        ? args.first
        : p.join(findRepoRoot().path, 'content', 'audio', 'shared'),
  )..createSync(recursive: true);
  final files = {
    'tone-short.wav': synthAlertTone(),
    'tasbih-tick.wav': synthTasbihTick(),
  };
  files.forEach((name, bytes) {
    final file = File(p.join(outDir.path, name))..writeAsBytesSync(bytes);
    stdout.writeln('Wrote ${file.path} (${bytes.length} bytes)');
  });
}
