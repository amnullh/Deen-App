import '../../domain/delete_all_data.dart';
import '../db/app_database.dart';

/// Empties every table in one transaction, so a failure leaves the data as it
/// was. The schema stays, so setup can run again straight away.
class DriftAppDataStore implements AppDataStore {
  DriftAppDataStore(this._db);

  final AppDatabase _db;

  @override
  Future<void> deleteAll() {
    return _db.transaction(() async {
      for (final table in _db.allTables) {
        await _db.delete(table).go();
      }
    });
  }
}
