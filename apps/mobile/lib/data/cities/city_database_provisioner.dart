import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Asset key declared in `pubspec.yaml`; `tools/sync_content` copies
/// `content/cities/cities.db` there.
const String bundledCitiesAsset = 'assets/cities/cities.db';

/// Puts a readable copy of the bundled city database on disk.
///
/// SQLite needs a real file, and assets are not files, so the database is
/// copied to the app support folder. The copy is refreshed whenever its bytes
/// differ from the bundled asset, which covers app updates that ship a newer
/// city list and a copy that was damaged on disk.
class CityDatabaseProvisioner {
  CityDatabaseProvisioner({
    required this.loadAssetBytes,
    required this.supportDirectory,
  });

  /// The production wiring: the Flutter asset bundle and the app support
  /// folder.
  factory CityDatabaseProvisioner.bundled() {
    return CityDatabaseProvisioner(
      loadAssetBytes: () async {
        final data = await rootBundle.load(bundledCitiesAsset);
        return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      },
      supportDirectory: getApplicationSupportDirectory,
    );
  }

  final Future<Uint8List> Function() loadAssetBytes;
  final Future<Directory> Function() supportDirectory;

  /// Returns the path of an up-to-date copy of the database, creating or
  /// refreshing it when needed.
  Future<String> ensureDatabase() async {
    final bytes = await loadAssetBytes();
    final directory = Directory(
      p.join((await supportDirectory()).path, 'cities'),
    );
    final target = File(p.join(directory.path, 'cities.db'));
    if (await _hasContent(target, bytes)) return target.path;
    await directory.create(recursive: true);
    // Write beside the target and rename, so a crash never leaves a half
    // written database under the final name.
    final partial = File('${target.path}.tmp');
    await partial.writeAsBytes(bytes, flush: true);
    await partial.rename(target.path);
    return target.path;
  }

  Future<bool> _hasContent(File file, Uint8List expected) async {
    if (!await file.exists()) return false;
    if (await file.length() != expected.length) return false;
    final actual = await file.readAsBytes();
    for (var i = 0; i < actual.length; i++) {
      if (actual[i] != expected[i]) return false;
    }
    return true;
  }
}
