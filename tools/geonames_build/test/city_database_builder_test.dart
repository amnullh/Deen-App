import 'dart:io';

import 'package:geonames_build/alternate_names.dart';
import 'package:geonames_build/city_database_builder.dart';
import 'package:geonames_build/geonames_rows.dart';
import 'package:geonames_build/normalize.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

const _cities = [
  GeoCity(
    geonameId: 104515,
    name: 'Makkah',
    asciiName: 'Makkah',
    latitude: 21.42664,
    longitude: 39.82563,
    countryCode: 'SA',
    timeZoneId: 'Asia/Riyadh',
    population: 1323624,
  ),
  GeoCity(
    geonameId: 1,
    name: 'Zürich',
    asciiName: 'Zurich',
    latitude: 47.36667,
    longitude: 8.55,
    countryCode: 'CH',
    timeZoneId: 'Europe/Zurich',
    population: 341730,
  ),
];

const _names = [
  AlternateName(
    geonameId: 104515,
    language: 'ar',
    name: 'مكة',
    isPreferred: true,
  ),
  AlternateName(geonameId: 104515, language: 'ur', name: 'مکہ'),
  AlternateName(geonameId: 104515, language: 'id', name: 'Mekkah'),
];

void main() {
  late Directory dir;
  late String path;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('city_db_test');
    path = p.join(dir.path, 'cities.db');
  });
  tearDown(() => dir.deleteSync(recursive: true));

  BuildReport build({List<GeoCity> cities = _cities}) => buildCityDatabase(
    path: path,
    cities: cities,
    alternateNames: _names,
    metadata: const CityDatabaseMetadata(
      sourceUrl: 'https://download.geonames.org/export/dump/',
      buildDate: '2026-10-21',
    ),
  );

  test('stores cities with every field the app needs', () {
    build();
    final db = sqlite3.open(path, mode: OpenMode.readOnly);
    addTearDown(db.close);
    final row = db
        .select('SELECT * FROM cities WHERE geoname_id = 104515')
        .single;
    expect(row['name'], 'Makkah');
    expect(row['ascii_name'], 'Makkah');
    expect(row['latitude'], closeTo(21.42664, 1e-9));
    expect(row['longitude'], closeTo(39.82563, 1e-9));
    expect(row['country_code'], 'SA');
    expect(row['time_zone_id'], 'Asia/Riyadh');
    expect(row['population'], 1323624);
  });

  test('search table holds normalised primary, ascii and alternate names', () {
    build();
    final db = sqlite3.open(path, mode: OpenMode.readOnly);
    addTearDown(db.close);
    final names = db
        .select(
          'SELECT normalized FROM city_names WHERE city_id = 1 ORDER BY 1',
        )
        .map((r) => r['normalized'] as String)
        .toList();
    expect(names, ['zurich']);
    final makkah = db
        .select(
          'SELECT normalized, language, priority FROM city_names '
          'WHERE city_id = 104515 ORDER BY priority, normalized',
        )
        .map((r) => '${r['normalized']}|${r['language']}|${r['priority']}')
        .toList();
    expect(makkah, contains('makkah|und|0'));
    expect(makkah, contains('${normalizeSearchText('مكة')}|ar|2'));
    expect(makkah, contains('mekkah|id|3'));
  });

  test('writes metadata with source, license, attribution and build date', () {
    build();
    final db = sqlite3.open(path, mode: OpenMode.readOnly);
    addTearDown(db.close);
    final meta = {
      for (final r in db.select('SELECT key, value FROM metadata'))
        r['key'] as String: r['value'] as String,
    };
    expect(meta['license'], 'CC BY 4.0');
    expect(meta['build_date'], '2026-10-21');
    expect(meta['source'], contains('geonames.org'));
    expect(meta['attribution'], geonamesAttribution);
    expect(
      geonamesAttribution,
      'Contains data from GeoNames (https://www.geonames.org), licensed under '
      'CC BY 4.0 (https://creativecommons.org/licenses/by/4.0/). Modified: '
      'filtered and recoded.',
    );
    expect(meta['city_count'], '2');
  });

  test('build is reproducible: same input gives identical bytes', () {
    build();
    final first = File(path).readAsBytesSync();
    File(path).deleteSync();
    build(cities: _cities.reversed.toList());
    expect(File(path).readAsBytesSync(), first);
  });

  test('replaces an existing file and reports counts', () {
    build();
    final report = build();
    expect(report.cityCount, 2);
    // Makkah, its Arabic name (the Urdu spelling folds to the same text and is
    // dropped), its Indonesian name, and Zürich.
    expect(report.nameCount, 4);
  });
}
