import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app_database.dart';

/// Opens the on-device database file (`app.db` in the app documents directory).
/// The file never leaves the device.
AppDatabase openAppDatabase() {
  return AppDatabase(
    LazyDatabase(() async {
      final directory = await getApplicationDocumentsDirectory();
      return NativeDatabase.createInBackground(
        File(p.join(directory.path, 'app.db')),
      );
    }),
  );
}
