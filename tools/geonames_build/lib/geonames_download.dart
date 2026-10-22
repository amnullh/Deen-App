/// Download and streaming access to the GeoNames dump files.
///
/// Dev-time only; never linked into the app. The 205 MB alternate-names zip is
/// downloaded once into a cache folder outside the repository and read as a
/// stream through the system `unzip -p`, so it is never held in memory or
/// unpacked to disk.
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

const String geonamesDumpUrl = 'https://download.geonames.org/export/dump/';

/// Thrown for problems the user can fix (missing `unzip`, failed download).
class BuildToolException implements Exception {
  BuildToolException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Downloads [fileName] from the GeoNames dump folder into [cacheDir] unless
/// it is already there, and returns the local file. The download goes to a
/// `.part` file first so an interrupted run never leaves a truncated zip.
Future<File> ensureDownloaded(
  String fileName,
  Directory cacheDir, {
  void Function(String message)? log,
}) async {
  final target = File(p.join(cacheDir.path, fileName));
  if (target.existsSync() && target.lengthSync() > 0) {
    log?.call('Using cached ${target.path}');
    return target;
  }
  cacheDir.createSync(recursive: true);
  final partial = File('${target.path}.part');
  final client = HttpClient();
  try {
    log?.call('Downloading $geonamesDumpUrl$fileName ...');
    final request = await client.getUrl(Uri.parse('$geonamesDumpUrl$fileName'));
    final response = await request.close();
    if (response.statusCode != 200) {
      throw BuildToolException(
        'Download of $fileName failed: HTTP ${response.statusCode}',
      );
    }
    final sink = partial.openWrite();
    await response.pipe(sink);
    partial.renameSync(target.path);
  } on SocketException catch (e) {
    throw BuildToolException('Cannot reach geonames.org: ${e.message}');
  } finally {
    client.close();
  }
  return target;
}

/// Streams the lines of [entryName] inside [zip] using the system `unzip`.
Stream<String> zipEntryLines(File zip, String entryName) async* {
  final Process process;
  try {
    process = await Process.start('unzip', ['-p', zip.path, entryName]);
  } on ProcessException {
    throw BuildToolException(
      'The `unzip` command was not found. Install it (it ships with macOS '
      'and most Linux distributions) and run the build again.',
    );
  }
  final stderrDone = process.stderr.drain<void>();
  yield* process.stdout.transform(utf8.decoder).transform(const LineSplitter());
  await stderrDone;
  final code = await process.exitCode;
  if (code != 0) {
    throw BuildToolException(
      'unzip failed with exit code $code for $entryName in ${zip.path}',
    );
  }
}
