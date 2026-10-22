/// Plans how the six Azaan recordings are encoded for each platform.
///
/// Pure logic (argument parsing, file matching, command lines, verification);
/// `bin/encode.dart` runs the commands. `ffmpeg` and `afconvert` are dev-time
/// tools and are never linked into the app. See `encode_audio.md`.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'audio_duration.dart';
import 'sync_plan.dart';

/// The six recordings: two voices, each in the standard, Fajr (with the
/// tathwib addition) and Shia wording. Masters and outputs use these names.
const List<String> azaanNames = [
  'voice1-standard',
  'voice1-fajr',
  'voice1-shia',
  'voice2-standard',
  'voice2-fajr',
  'voice2-shia',
];

/// File extensions accepted for a master recording.
const Set<String> masterExtensions = {
  'wav',
  'flac',
  'aif',
  'aiff',
  'caf',
  'm4a',
  'mp3',
  'ogg',
  'opus',
  'webm',
};

enum EncodeTarget { android, ios }

enum AndroidCodec { vorbis, opus }

/// Seconds subtracted from iOS's 30 second limit by default, so a rounding
/// difference in the encoder can never push a clip over it.
const double defaultIosMaxSeconds = 28;

/// Options of `bin/encode.dart`.
class EncodeOptions {
  const EncodeOptions({
    required this.inputDir,
    required this.androidDir,
    required this.iosDir,
    required this.platforms,
    required this.androidCodec,
    required this.iosMaxSeconds,
    required this.dryRun,
    required this.only,
  });

  final String inputDir;
  final String androidDir;
  final String iosDir;
  final Set<EncodeTarget> platforms;
  final AndroidCodec androidCodec;
  final double iosMaxSeconds;
  final bool dryRun;

  /// One recording name, or null for all six.
  final String? only;
}

const String encodeUsage = '''
Usage: dart run tools/sync_content/bin/encode.dart [options]
  --input DIR           master recordings named like voice1-fajr.wav
                        (default content/audio/master)
  --android-out DIR     default content/audio/android
  --ios-out DIR         default content/audio/ios
  --platform NAME       android, ios or all (default all)
  --android-codec NAME  vorbis (default) or opus
  --max-seconds N       iOS clip length cap, above 0 and below 30 (default 28)
  --only NAME           encode one recording, for example voice1-fajr
  --dry-run             print the commands and run nothing''';

/// Parses command line [args]; throws [FormatException] with a clear message.
EncodeOptions parseEncodeArgs(List<String> args) {
  final values = <String, String>{};
  var dryRun = false;
  for (var i = 0; i < args.length; i++) {
    final flag = args[i];
    if (flag == '--dry-run') {
      dryRun = true;
      continue;
    }
    const withValue = {
      '--input',
      '--android-out',
      '--ios-out',
      '--platform',
      '--android-codec',
      '--max-seconds',
      '--only',
    };
    if (!withValue.contains(flag)) {
      throw FormatException('Unknown option $flag.\n$encodeUsage');
    }
    if (i + 1 >= args.length) {
      throw FormatException('$flag needs a value.');
    }
    values[flag] = args[++i];
  }

  final platform = values['--platform'] ?? 'all';
  final Set<EncodeTarget> platforms = switch (platform) {
    'android' => {EncodeTarget.android},
    'ios' => {EncodeTarget.ios},
    'all' => {EncodeTarget.android, EncodeTarget.ios},
    _ => throw FormatException(
      '--platform must be android, ios or all, not "$platform".',
    ),
  };
  final codec = values['--android-codec'] ?? 'vorbis';
  final AndroidCodec androidCodec = switch (codec) {
    'vorbis' => AndroidCodec.vorbis,
    'opus' => AndroidCodec.opus,
    _ => throw FormatException(
      '--android-codec must be vorbis or opus, not "$codec".',
    ),
  };
  final maxSeconds = values.containsKey('--max-seconds')
      ? double.tryParse(values['--max-seconds']!)
      : defaultIosMaxSeconds;
  if (maxSeconds == null ||
      maxSeconds <= 0 ||
      maxSeconds >= iosNotificationSoundLimitSeconds) {
    throw const FormatException(
      '--max-seconds must be a number above 0 and below 30: iOS plays a '
      'notification sound only when it is shorter than 30 seconds.',
    );
  }
  final only = values['--only'];
  if (only != null && !azaanNames.contains(only)) {
    throw FormatException(
      '--only must be one of ${azaanNames.join(', ')}, not "$only".',
    );
  }
  return EncodeOptions(
    inputDir: values['--input'] ?? 'content/audio/master',
    androidDir: values['--android-out'] ?? 'content/audio/android',
    iosDir: values['--ios-out'] ?? 'content/audio/ios',
    platforms: platforms,
    androidCodec: androidCodec,
    iosMaxSeconds: maxSeconds,
    dryRun: dryRun,
    only: only,
  );
}

/// Result of matching recording names to files in the input folder.
class MasterMatch {
  const MasterMatch(this.masters, this.missing, this.ambiguous);

  /// Recording name to master file name.
  final Map<String, String> masters;
  final List<String> missing;

  /// Names with more than one candidate file (extension differs).
  final List<String> ambiguous;
}

/// Matches each of [names] to one file of [fileNames] by base name and a
/// supported extension (case-insensitive).
MasterMatch findMasters(List<String> names, List<String> fileNames) {
  final masters = <String, String>{};
  final missing = <String>[];
  final ambiguous = <String>[];
  for (final name in names) {
    final candidates = [
      for (final file in fileNames)
        if (_isMasterFor(file, name)) file,
    ];
    if (candidates.isEmpty) {
      missing.add(name);
    } else if (candidates.length > 1) {
      ambiguous.add(name);
    } else {
      masters[name] = candidates.single;
    }
  }
  return MasterMatch(masters, missing, ambiguous);
}

bool _isMasterFor(String file, String name) {
  final dot = file.lastIndexOf('.');
  if (dot <= 0) return false;
  return file.substring(0, dot) == name &&
      masterExtensions.contains(file.substring(dot + 1).toLowerCase());
}

/// One command to run.
class EncodeStep {
  const EncodeStep(this.tool, this.args);

  final String tool;
  final List<String> args;

  @override
  String toString() => '$tool ${args.map(_quote).join(' ')}';

  static String _quote(String arg) =>
      RegExp(r'^[A-Za-z0-9_./:=@%+,-]+$').hasMatch(arg) ? arg : "'$arg'";
}

/// All commands that produce one output file.
class EncodeJob {
  const EncodeJob({
    required this.name,
    required this.platform,
    required this.outputPath,
    required this.steps,
  });

  final String name;
  final EncodeTarget platform;
  final String outputPath;
  final List<EncodeStep> steps;
}

/// The jobs for [masters] (name to file name in `options.inputDir`), ordered
/// by recording and then platform. [tempDir] holds the intermediate WAV of an
/// iOS clip.
List<EncodeJob> planEncodeJobs(
  EncodeOptions options,
  Map<String, String> masters, {
  required String tempDir,
}) {
  final jobs = <EncodeJob>[];
  for (final name in azaanNames) {
    final master = masters[name];
    if (master == null) continue;
    if (options.only != null && options.only != name) continue;
    final input = '${options.inputDir}/$master';
    if (options.platforms.contains(EncodeTarget.android)) {
      jobs.add(_androidJob(options, name, input));
    }
    if (options.platforms.contains(EncodeTarget.ios)) {
      jobs.add(_iosJob(options, name, input, tempDir));
    }
  }
  return jobs;
}

EncodeJob _androidJob(EncodeOptions options, String name, String input) {
  final output = '${options.androidDir}/${androidResourceName('$name.ogg')}';
  final codec = options.androidCodec == AndroidCodec.vorbis
      ? ['-c:a', 'libvorbis', '-q:a', '4']
      : ['-c:a', 'libopus', '-b:a', '64k'];
  return EncodeJob(
    name: name,
    platform: EncodeTarget.android,
    outputPath: output,
    steps: [
      EncodeStep('ffmpeg', [
        '-y',
        '-loglevel',
        'error',
        '-i',
        input,
        '-vn',
        '-map_metadata',
        '-1',
        ...codec,
        output,
      ]),
    ],
  );
}

EncodeJob _iosJob(
  EncodeOptions options,
  String name,
  String input,
  String tempDir,
) {
  final output = '${options.iosDir}/$name.caf';
  final intermediate = '$tempDir/$name.wav';
  final limit = _formatSeconds(options.iosMaxSeconds);
  final fadeStart = _formatSeconds(
    (options.iosMaxSeconds - 0.75).clamp(0, double.infinity),
  );
  return EncodeJob(
    name: name,
    platform: EncodeTarget.ios,
    outputPath: output,
    steps: [
      // Cap the length and fade the last 0.75 s so a cut clip does not end
      // with a click. A shorter recording is not touched by the fade.
      EncodeStep('ffmpeg', [
        '-y',
        '-loglevel',
        'error',
        '-i',
        input,
        '-vn',
        '-map_metadata',
        '-1',
        '-t',
        limit,
        '-af',
        'afade=t=out:st=$fadeStart:d=0.75',
        '-c:a',
        'pcm_s16le',
        intermediate,
      ]),
      EncodeStep('afconvert', [
        '-f',
        'caff',
        '-d',
        'ima4',
        intermediate,
        output,
      ]),
    ],
  );
}

String _formatSeconds(num seconds) {
  final text = seconds.toStringAsFixed(2);
  return text.replaceFirst(RegExp(r'\.?0+$'), '');
}

/// The command line tools the plan needs.
Set<String> requiredTools(List<EncodeJob> jobs) => {
  for (final job in jobs)
    for (final step in job.steps) step.tool,
};

/// The external ffmpeg encoders (such as `libvorbis`) the plan relies on.
/// Distributions of ffmpeg differ in which ones they were built with.
Set<String> requiredEncoders(List<EncodeJob> jobs) => {
  for (final job in jobs)
    for (final step in job.steps)
      if (step.tool == 'ffmpeg')
        for (var i = 0; i + 1 < step.args.length; i++)
          if (step.args[i] == '-c:a' && step.args[i + 1].startsWith('lib'))
            step.args[i + 1],
};

/// What to tell the person when this ffmpeg lacks [encoder].
String missingEncoderMessage(String encoder) {
  final other = encoder == 'libvorbis' ? 'opus' : 'vorbis';
  return 'Your ffmpeg was built without $encoder. Use an ffmpeg build that '
      'includes it (for example your Linux distribution\'s package, or one '
      'configured with --enable-$encoder), or run again with '
      '--android-codec $other. Do not use ffmpeg\'s experimental native '
      '"vorbis" encoder: its quality is poor.';
}

/// What to tell the person when [tool] is not installed.
String missingToolMessage(String tool) {
  switch (tool) {
    case 'ffmpeg':
      return 'ffmpeg was not found. Please install it (macOS: brew install '
          'ffmpeg; Debian or Ubuntu: apt install ffmpeg) and run this again. '
          'It is a dev-time tool and is not part of the app.';
    case 'afconvert':
      return 'afconvert was not found. It ships with macOS and is the only '
          'tool this script uses to write IMA4 CAF files, so the iOS clips '
          'must be encoded on a Mac. Run with --platform android elsewhere, '
          'or follow the manual steps in tools/sync_content/encode_audio.md.';
    default:
      return '$tool was not found.';
  }
}

/// Null when the iOS clip [bytes] is acceptable, otherwise the problem.
String? verifyIosClip(Uint8List bytes, {required double maxSeconds}) {
  final seconds = audioDurationSeconds(bytes);
  if (seconds == null) {
    return 'cannot read the duration; expected WAV, AIFF or CAF';
  }
  if (seconds > maxSeconds) {
    return 'is ${seconds.toStringAsFixed(1)} s, longer than the '
        '${maxSeconds.toStringAsFixed(1)} s cap (iOS needs under 30 s)';
  }
  return null;
}

/// Null when [bytes] look like an Ogg file, otherwise the problem. A full
/// duration check needs `ffprobe` (see `encode_audio.md`).
String? verifyAndroidFile(Uint8List bytes) {
  if (bytes.isEmpty) return 'is empty';
  if (bytes.length < 4 || latin1.decode(bytes.sublist(0, 4)) != 'OggS') {
    return 'is not an Ogg file (missing OggS header)';
  }
  return null;
}
