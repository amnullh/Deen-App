import 'package:sqlite3/sqlite3.dart';

import '../../domain/entities/city.dart';
import '../../domain/repositories/city_search_repository.dart';
import 'city_database_provisioner.dart';
import 'name_normalizer.dart';

/// The newest table layout this code reads (`PRAGMA user_version`).
const int supportedCityDatabaseVersion = 1;

/// The bundled city database cannot be used (wrong layout or rules).
class CityDatabaseException implements Exception {
  CityDatabaseException(this.message);

  final String message;

  @override
  String toString() => 'CityDatabaseException: $message';
}

/// Offline city search over the read-only `cities.db` built by
/// `tools/geonames_build`. Works with no network.
///
/// Queries are normalised with [normalizeSearchText] (case, diacritics,
/// Arabic and Urdu letter variants) and matched as a prefix of any stored name
/// (primary, ASCII, Arabic, Urdu, Indonesian). Each city appears once, most
/// populous first.
class CityRepository implements CitySearchRepository {
  /// [openPath] returns the path of the database file; it is called once, on
  /// first use.
  CityRepository(this._openPath);

  /// Reads the database bundled with the app, copied to the support folder.
  factory CityRepository.bundled() {
    return CityRepository(CityDatabaseProvisioner.bundled().ensureDatabase);
  }

  final Future<String> Function() _openPath;
  Future<Database>? _database;

  Future<Database> _db() async {
    final pending = _database ??= _open();
    try {
      return await pending;
    } catch (_) {
      // Do not cache a failure: the next call tries again (for example after
      // the provisioner replaced a damaged copy).
      if (identical(_database, pending)) _database = null;
      rethrow;
    }
  }

  Future<Database> _open() async {
    final path = await _openPath();
    final db = sqlite3.open(path, mode: OpenMode.readOnly);
    try {
      _checkCompatible(db);
    } catch (_) {
      db.close();
      rethrow;
    }
    return db;
  }

  void _checkCompatible(Database db) {
    final layout = db.select('PRAGMA user_version').single.values.first as int;
    if (layout > supportedCityDatabaseVersion) {
      throw CityDatabaseException(
        'City database layout $layout is newer than this app understands '
        '($supportedCityDatabaseVersion).',
      );
    }
    final rules = db.select(
      "SELECT value FROM metadata WHERE key = 'normalization_version'",
    );
    if (rules.isEmpty || rules.single['value'] != '$normalizationVersion') {
      throw CityDatabaseException(
        'City database was built with different name-matching rules.',
      );
    }
  }

  @override
  Future<List<CityRecord>> search(String query, {int limit = 20}) async {
    final normalized = normalizeSearchText(query);
    if (normalized.isEmpty || limit <= 0) return const [];
    final db = await _db();
    // Range scan on the indexed normalised name; MIN(priority) makes SQLite
    // return the best-ranked matching name of each city in `matched_name`.
    final rows = db.select(
      '''
      SELECT c.geoname_id, c.name, c.latitude, c.longitude, c.country_code,
             c.time_zone_id, c.population,
             n.name AS matched_name, MIN(n.priority) AS matched_priority
      FROM city_names n
      JOIN cities c ON c.geoname_id = n.city_id
      WHERE n.normalized >= ?1 AND n.normalized < ?2
      GROUP BY c.geoname_id
      ORDER BY c.population DESC, c.geoname_id
      LIMIT ?3
      ''',
      [normalized, prefixUpperBound(normalized), limit],
    );
    return [
      for (final row in rows)
        _toRecord(
          row,
          matchedName: row['matched_priority'] == 0
              ? null
              : row['matched_name'] as String,
        ),
    ];
  }

  @override
  Future<CityRecord?> byId(int geonameId) async {
    final db = await _db();
    final rows = db.select(
      '''
      SELECT geoname_id, name, latitude, longitude, country_code,
             time_zone_id, population
      FROM cities WHERE geoname_id = ?
      ''',
      [geonameId],
    );
    return rows.isEmpty ? null : _toRecord(rows.single);
  }

  CityRecord _toRecord(Row row, {String? matchedName}) {
    return CityRecord(
      geonameId: row['geoname_id'] as int,
      name: row['name'] as String,
      latitude: (row['latitude'] as num).toDouble(),
      longitude: (row['longitude'] as num).toDouble(),
      countryCode: row['country_code'] as String,
      timeZoneId: row['time_zone_id'] as String,
      population: row['population'] as int,
      matchedName: matchedName,
    );
  }

  /// Closes the database. Safe to call when it was never opened.
  Future<void> close() async {
    final pending = _database;
    _database = null;
    if (pending == null) return;
    try {
      (await pending).close();
    } catch (_) {
      // Opening had failed; there is nothing to close.
    }
  }
}
