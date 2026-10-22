/// Writes the offline city database (`cities.db`).
///
/// Tables:
/// - `cities`: one row per place with the fields of the app's `CityRecord`.
/// - `city_names`: the search table. One row per distinct normalised name of a
///   city (primary name, ASCII name, Arabic/Urdu/Indonesian alternates), with a
///   `priority` that decides which spelling is shown beside a result:
///   0 primary, 1 ASCII, 2 preferred alternate, 3 other alternate.
/// - `metadata`: source, license, attribution, build date, counts.
///
/// The output is reproducible: the same input and build date produce the same
/// bytes, so the file can be rebuilt instead of stored in git.
library;

import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

import 'alternate_names.dart';
import 'geonames_rows.dart';
import 'normalize.dart';

/// The attribution text required by CC BY 4.0 for the bundled data.
const String geonamesAttribution =
    'Contains data from GeoNames (https://www.geonames.org), licensed under '
    'CC BY 4.0 (https://creativecommons.org/licenses/by/4.0/). Modified: '
    'filtered and recoded.';

/// Version of the table layout; the app refuses a newer layout.
const int cityDatabaseSchemaVersion = 1;

/// Facts recorded in the `metadata` table.
class CityDatabaseMetadata {
  const CityDatabaseMetadata({
    required this.sourceUrl,
    required this.buildDate,
    this.extra = const {},
  });

  /// Where the dumps came from.
  final String sourceUrl;

  /// ISO date (`yyyy-MM-dd`) of the build; passed in so builds are repeatable.
  final String buildDate;

  /// Additional keys, for example the languages kept.
  final Map<String, String> extra;
}

/// Counts of what was written.
class BuildReport {
  const BuildReport({required this.cityCount, required this.nameCount});

  final int cityCount;
  final int nameCount;
}

/// Builds the database at [path], replacing any existing file.
BuildReport buildCityDatabase({
  required String path,
  required Iterable<GeoCity> cities,
  required Iterable<AlternateName> alternateNames,
  required CityDatabaseMetadata metadata,
}) {
  final file = File(path);
  if (file.existsSync()) file.deleteSync();
  file.parent.createSync(recursive: true);

  final sortedCities = cities.toList()
    ..sort((a, b) => a.geonameId.compareTo(b.geonameId));
  final namesByCity = <int, List<AlternateName>>{};
  for (final alternate in alternateNames) {
    namesByCity.putIfAbsent(alternate.geonameId, () => []).add(alternate);
  }

  final db = sqlite3.open(path);
  try {
    db.execute('PRAGMA journal_mode = DELETE');
    db.execute('''
      CREATE TABLE cities (
        geoname_id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        ascii_name TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        country_code TEXT NOT NULL,
        time_zone_id TEXT NOT NULL,
        population INTEGER NOT NULL
      )''');
    db.execute('''
      CREATE TABLE city_names (
        city_id INTEGER NOT NULL REFERENCES cities (geoname_id),
        name TEXT NOT NULL,
        normalized TEXT NOT NULL,
        language TEXT NOT NULL,
        priority INTEGER NOT NULL,
        PRIMARY KEY (city_id, normalized)
      ) WITHOUT ROWID''');
    db.execute('CREATE INDEX city_names_normalized ON city_names (normalized)');
    db.execute(
      'CREATE TABLE metadata (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
    );

    var nameCount = 0;
    db.execute('BEGIN');
    final insertCity = db.prepare(
      'INSERT INTO cities VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
    );
    final insertName = db.prepare(
      'INSERT INTO city_names VALUES (?, ?, ?, ?, ?)',
    );
    for (final city in sortedCities) {
      insertCity.execute([
        city.geonameId,
        city.name,
        city.asciiName,
        city.latitude,
        city.longitude,
        city.countryCode,
        city.timeZoneId,
        city.population,
      ]);
      for (final name in _searchNames(city, namesByCity[city.geonameId])) {
        insertName.execute([
          city.geonameId,
          name.display,
          name.normalized,
          name.language,
          name.priority,
        ]);
        nameCount++;
      }
    }
    insertCity.close();
    insertName.close();

    final values = <String, String>{
      'schema_version': '$cityDatabaseSchemaVersion',
      'normalization_version': '$normalizationVersion',
      'source':
          'GeoNames cities15000 and alternateNamesV2 (${metadata.sourceUrl})',
      'license': 'CC BY 4.0',
      'attribution': geonamesAttribution,
      'build_date': metadata.buildDate,
      'city_count': '${sortedCities.length}',
      'name_count': '$nameCount',
      ...metadata.extra,
    };
    final insertMeta = db.prepare('INSERT INTO metadata VALUES (?, ?)');
    for (final key in values.keys.toList()..sort()) {
      insertMeta.execute([key, values[key]]);
    }
    insertMeta.close();
    db.execute('PRAGMA user_version = $cityDatabaseSchemaVersion');
    db.execute('COMMIT');
    db.execute('VACUUM');
    return BuildReport(cityCount: sortedCities.length, nameCount: nameCount);
  } finally {
    db.close();
  }
}

class _SearchName {
  const _SearchName(
    this.display,
    this.normalized,
    this.language,
    this.priority,
  );

  final String display;
  final String normalized;
  final String language;
  final int priority;
}

/// The distinct normalised names of [city], lowest priority winning, in a
/// fixed order.
List<_SearchName> _searchNames(GeoCity city, List<AlternateName>? alternates) {
  final byNormalized = <String, _SearchName>{};
  void add(String display, String language, int priority) {
    final normalized = normalizeSearchText(display);
    if (normalized.isEmpty) return;
    final existing = byNormalized[normalized];
    if (existing == null || priority < existing.priority) {
      byNormalized[normalized] = _SearchName(
        display,
        normalized,
        language,
        priority,
      );
    }
  }

  add(city.name, 'und', 0);
  add(city.asciiName, 'und', 1);
  for (final alternate in alternates ?? const <AlternateName>[]) {
    add(alternate.name, alternate.language, alternate.isPreferred ? 2 : 3);
  }
  return byNormalized.values.toList()..sort((a, b) {
    final byPriority = a.priority.compareTo(b.priority);
    return byPriority != 0 ? byPriority : a.normalized.compareTo(b.normalized);
  });
}
