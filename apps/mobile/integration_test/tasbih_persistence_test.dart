// State survives an app restart (US5, T154).
//
// The "restart" is closing the drift database and opening the same file again
// with a new repository and controller, which is what a process kill and
// relaunch does to the data. It uses a real SQLite file, not an in-memory
// database. It needs no device, so it also runs with
// `flutter test integration_test/tasbih_persistence_test.dart`; the final
// kill-and-reboot check on hardware stays a manual device task.
import 'dart:io';

import 'package:deen_mobile/data/db/app_database.dart';
import 'package:deen_mobile/data/repositories/drift_tasbih_repository.dart';
import 'package:deen_mobile/domain/tasbih/tasbih_controller.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

AppDatabase _open(File file) => AppDatabase(NativeDatabase(file));

void main() {
  late Directory directory;
  late File file;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('tasbih_persistence');
    file = File(p.join(directory.path, 'app.db'));
  });

  tearDown(() {
    if (directory.existsSync()) directory.deleteSync(recursive: true);
  });

  test('count, target, options and history survive a restart', () async {
    var now = DateTime(2026, 10, 21, 20);

    // First run: count, change the target and options, count across midnight.
    var db = _open(file);
    var controller = TasbihController(
      repository: DriftTasbihRepository(db),
      clock: () => now,
    );
    await controller.setTarget(99);
    await controller.setSound(true);
    await controller.setLock(true);
    await controller.setLock(false);
    for (var i = 0; i < 12; i++) {
      await controller.tap();
    }
    now = DateTime(2026, 10, 22, 0, 5);
    for (var i = 0; i < 3; i++) {
      await controller.tap();
    }
    await db.close();
    expect(file.existsSync(), isTrue, reason: 'a real file on disk');

    // Second run: a new process opens the same file.
    db = _open(file);
    final repository = DriftTasbihRepository(db);
    final state = await repository.get();
    expect(state.count, 15);
    expect(state.target, 99);
    expect(state.sound, isTrue);
    expect(state.lock, isFalse);
    final days = await repository.watchDays().first;
    expect(days.map((d) => (d.date, d.total)), [
      ('2026-10-22', 3),
      ('2026-10-21', 12),
    ]);

    // Counting carries on from the saved value.
    controller = TasbihController(repository: repository, clock: () => now);
    expect((await controller.tap()).count, 16);

    // A confirmed reset is also saved.
    await controller.reset(confirmed: true);
    await db.close();

    db = _open(file);
    final afterReset = await DriftTasbihRepository(db).get();
    expect(afterReset.count, 0);
    expect(afterReset.target, 99);
    await db.close();
  });
}
