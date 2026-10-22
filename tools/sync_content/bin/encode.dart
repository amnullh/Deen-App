/// Encodes the six Azaan recordings for each platform (T100).
///
/// Android: Ogg Vorbis (or Opus) into `content/audio/android`.
/// iOS: IMA4 CAF clips shorter than 30 seconds into `content/audio/ios`.
/// Uses `ffmpeg` and `afconvert` as dev-time tools (never linked into the
/// app). Then checks the results; `bin/sync.dart --check` repeats the iOS
/// length check in CI. Details: `tools/sync_content/encode_audio.md`.
///
/// Run from anywhere inside the repository:
///   dart run tools/sync_content/bin/encode.dart --dry-run
library;

import 'dart:io';

import 'package:license_scan/repo_io.dart';
import 'package:path/path.dart' as p;
import 'package:sync_content/encode_plan.dart';

Future<void> main(List<String> args) async {
  final EncodeOptions options;
  try {
    options = parseEncodeArgs(args);
  } on FormatException catch (e) {
    stderr.writeln(e.message);
    exit(64);
  }
  final root = findRepoRoot();
  final inputDir = Directory(p.join(root.path, options.inputDir));
  final files = inputDir.existsSync()
      ? [
          for (final entity in inputDir.listSync())
            if (entity is File) p.basename(entity.path),
        ]
      : <String>[];

  final names = options.only == null ? azaanNames : [options.only!];
  final match = findMasters(names, files);
  if (match.masters.isEmpty || match.ambiguous.isNotEmpty) {
    _explainMasters(options, inputDir, match);
    exit(1);
  }
  if (match.missing.isNotEmpty) {
    stderr.writeln(
      'Not found in ${options.inputDir} (skipped): '
      '${match.missing.join(', ')}',
    );
  }

  final tempDir = Directory.systemTemp.createTempSync('deen_encode_');
  try {
    final jobs = planEncodeJobs(options, match.masters, tempDir: tempDir.path);
    final missingTools = <String>[
      for (final tool in requiredTools(jobs))
        if (!await _toolAvailable(tool)) tool,
    ];
    if (options.dryRun) {
      for (final job in jobs) {
        for (final step in job.steps) {
          stdout.writeln(step);
        }
      }
      for (final tool in missingTools) {
        stderr.writeln('Note: ${missingToolMessage(tool)}');
      }
      return;
    }
    if (missingTools.isNotEmpty) {
      for (final tool in missingTools) {
        stderr.writeln(missingToolMessage(tool));
      }
      exit(2);
    }
    final encoders = await _ffmpegEncoders();
    final missingEncoders = requiredEncoders(jobs).difference(encoders);
    if (missingEncoders.isNotEmpty) {
      for (final encoder in missingEncoders) {
        stderr.writeln(missingEncoderMessage(encoder));
      }
      exit(2);
    }
    final failures = await _runJobs(jobs, root, options);
    if (failures > 0) {
      stderr.writeln('$failures problem(s); see above.');
      exit(1);
    }
    stdout.writeln(
      'Encoded ${jobs.length} file(s). Next: dart run '
      'tools/sync_content/bin/sync.dart --check',
    );
  } finally {
    tempDir.deleteSync(recursive: true);
  }
}

void _explainMasters(
  EncodeOptions options,
  Directory inputDir,
  MasterMatch match,
) {
  if (match.ambiguous.isNotEmpty) {
    stderr.writeln(
      'More than one file matches: ${match.ambiguous.join(', ')}. Keep one '
      'master per recording in ${options.inputDir}.',
    );
    return;
  }
  stderr.writeln(
    'No master recordings found in ${inputDir.path}.\n'
    'Put the licensed recordings there, named exactly '
    '${azaanNames.join(', ')} with an extension such as .wav or .flac. '
    'Recordings must be cleared in content/LICENSES.md first.',
  );
}

/// Runs every job and verifies its output; returns the number of problems.
Future<int> _runJobs(
  List<EncodeJob> jobs,
  Directory root,
  EncodeOptions options,
) async {
  var problems = 0;
  for (final job in jobs) {
    Directory(p.dirname(p.join(root.path, job.outputPath)))
        .createSync(recursive: true);
    var ok = true;
    for (final step in job.steps) {
      stdout.writeln(step);
      final result = await Process.run(
        step.tool,
        step.args,
        workingDirectory: root.path,
      );
      if (result.exitCode != 0) {
        stderr.writeln(
          '${step.tool} failed (${result.exitCode}): '
          '${result.stderr}',
        );
        ok = false;
        break;
      }
    }
    if (!ok) {
      problems++;
      continue;
    }
    final bytes = File(p.join(root.path, job.outputPath)).readAsBytesSync();
    final problem = job.platform == EncodeTarget.ios
        ? verifyIosClip(bytes, maxSeconds: options.iosMaxSeconds)
        : verifyAndroidFile(bytes);
    if (problem != null) {
      stderr.writeln('${job.outputPath} $problem');
      problems++;
    }
  }
  return problems;
}

/// Names of the encoders this ffmpeg build offers.
Future<Set<String>> _ffmpegEncoders() async {
  final result = await Process.run('ffmpeg', ['-hide_banner', '-encoders']);
  final names = <String>{};
  for (final line in '${result.stdout}'.split('\n')) {
    final parts = line.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts.first.length == 6) names.add(parts[1]);
  }
  return names;
}

Future<bool> _toolAvailable(String tool) async {
  try {
    final lookup = Platform.isWindows ? 'where' : 'which';
    final result = await Process.run(lookup, [tool]);
    return result.exitCode == 0;
  } on ProcessException {
    return false;
  }
}
