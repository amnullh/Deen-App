import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/delete_all_data.dart';

/// Hands the settings file to the user. Wrapped in an interface so tests and
/// the UI never touch the platform.
abstract interface class ExportFileSink implements ExportFileCleaner {
  /// Opens the system share sheet with the file. Returns false when the user
  /// dismissed it. [origin] anchors the sheet on iPad.
  Future<bool> share(String fileName, String content, {Rect? origin});

  /// Opens the system save dialog. Returns false when the user cancelled.
  Future<bool> saveToDevice(String fileName, String content);
}

/// Reads a settings file chosen by the user.
abstract interface class ImportFileSource {
  /// The text of the chosen file, or null when the user cancelled. Throws
  /// [FormatException] when the file is too large or not UTF-8 text.
  Future<String?> pickSettingsFile();
}

/// Share and save through share_plus and file_picker. The share copy lives in
/// the app's temporary folder, which "delete all my data" empties.
class PlatformExportFileSink implements ExportFileSink {
  static const String _folderName = 'deen-export';

  Future<Directory> _folder() async {
    final base = await getTemporaryDirectory();
    final dir = Directory(p.join(base.path, _folderName));
    return dir.create(recursive: true);
  }

  @override
  Future<bool> share(String fileName, String content, {Rect? origin}) async {
    // Remove the previous copy first so only one export file ever exists.
    await deleteExportFiles();
    final file = File(p.join((await _folder()).path, fileName));
    await file.writeAsString(content, flush: true);
    final result = await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/json')],
        sharePositionOrigin: origin,
      ),
    );
    return result.status != ShareResultStatus.dismissed;
  }

  @override
  Future<bool> saveToDevice(String fileName, String content) async {
    final location = await FilePicker.saveFile(
      fileName: fileName,
      bytes: utf8.encode(content),
      mimeType: 'application/json',
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    return location != null;
  }

  @override
  Future<void> deleteExportFiles() async {
    final base = await getTemporaryDirectory();
    final dir = Directory(p.join(base.path, _folderName));
    if (await dir.exists()) await dir.delete(recursive: true);
  }
}

class FilePickerImportSource implements ImportFileSource {
  /// A settings file is a few kilobytes; anything near this size is not one.
  static const int maxBytes = 1024 * 1024;

  @override
  Future<String?> pickSettingsFile() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    if (file == null) return null;
    final length = await file.length();
    if (length != null && length > maxBytes) {
      throw const FormatException('The file is too large.');
    }
    return utf8.decode(await file.readAsBytes());
  }
}
