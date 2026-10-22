import 'package:drift/drift.dart';

import '../../domain/entities/settings.dart';
import '../../domain/repositories/location_repository.dart';
import '../../domain/result.dart';
import '../db/app_database.dart';

class DriftLocationRepository implements LocationRepository {
  DriftLocationRepository(this._db);

  final AppDatabase _db;

  @override
  Future<AppLocation?> get() async {
    final row = await _db.select(_db.locationTable).getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  @override
  Stream<AppLocation?> watch() {
    return _db
        .select(_db.locationTable)
        .watchSingleOrNull()
        .map((row) => row == null ? null : _fromRow(row));
  }

  @override
  Future<Result<void>> save(AppLocation location) async {
    // Error messages never include the coordinates themselves.
    if (location.latitude.isNaN ||
        location.latitude < -90 ||
        location.latitude > 90) {
      return const Err(
        AppError(
          ErrorCode.invalidArgument,
          'Latitude must be between -90 and 90.',
        ),
      );
    }
    if (location.longitude.isNaN ||
        location.longitude < -180 ||
        location.longitude > 180) {
      return const Err(
        AppError(
          ErrorCode.invalidArgument,
          'Longitude must be between -180 and 180.',
        ),
      );
    }
    if (location.timeZoneId.trim().isEmpty) {
      return const Err(
        AppError(ErrorCode.invalidArgument, 'A time zone is required.'),
      );
    }
    if (location.displayName.trim().isEmpty) {
      return const Err(
        AppError(ErrorCode.invalidArgument, 'A place name is required.'),
      );
    }
    await _db
        .into(_db.locationTable)
        .insertOnConflictUpdate(
          LocationTableCompanion.insert(
            id: const Value(1),
            source: location.source,
            latitude: location.latitude,
            longitude: location.longitude,
            cityId: Value(location.cityId),
            displayName: location.displayName.trim(),
            timeZoneId: location.timeZoneId.trim(),
            countryCode: location.countryCode.trim().toUpperCase(),
            updatedAtMs: location.updatedAt.millisecondsSinceEpoch,
          ),
        );
    return const Ok(null);
  }

  @override
  Future<void> clear() async {
    await _db.delete(_db.locationTable).go();
  }

  static AppLocation _fromRow(LocationTableData row) {
    return AppLocation(
      source: row.source,
      latitude: row.latitude,
      longitude: row.longitude,
      cityId: row.cityId,
      displayName: row.displayName,
      timeZoneId: row.timeZoneId,
      countryCode: row.countryCode,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        row.updatedAtMs,
        isUtc: true,
      ),
    );
  }
}
