// The build tool is a sibling workspace package the app does not depend on, so
// the test reaches it by path.
// ignore_for_file: avoid_relative_lib_imports

import 'dart:io';
import 'dart:typed_data';

import 'package:deen_mobile/data/cities/city_database_provisioner.dart';
import 'package:deen_mobile/data/cities/city_repository.dart';
import 'package:deen_mobile/data/cities/name_normalizer.dart' as app;
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

// The test database is written by the same code that builds the shipped file.
import '../../../../tools/geonames_build/lib/alternate_names.dart';
import '../../../../tools/geonames_build/lib/city_database_builder.dart';
import '../../../../tools/geonames_build/lib/geonames_rows.dart';
import '../../../../tools/geonames_build/lib/normalize.dart' as tool;

GeoCity _city(int id, String name, String ascii, int population, String cc) {
  return GeoCity(
    geonameId: id,
    name: name,
    asciiName: ascii,
    latitude: 10.5,
    longitude: 20.25,
    countryCode: cc,
    timeZoneId: 'Etc/UTC',
    population: population,
  );
}

final _cities = [
  _city(104515, 'Makkah', 'Makkah', 1323624, 'SA'),
  _city(108410, 'Riyadh', 'Riyadh', 5188286, 'SA'),
  _city(1642911, 'Jakarta', 'Jakarta', 8540121, 'ID'),
  _city(1174872, 'Karachi', 'Karachi', 11624219, 'PK'),
  _city(2657896, 'Zürich', 'Zurich', 341730, 'CH'),
  _city(3000, 'Zurich Heights', 'Zurich Heights', 900, 'US'),
  _city(2988507, 'Saint-Denis', 'Saint-Denis', 111135, 'FR'),
  _city(8001, 'Salt Lake', 'Salt Lake', 50, 'US'),
  _city(8002, 'Salem', 'Salem', 1500, 'US'),
  _city(8003, 'Salinas', 'Salinas', 900000, 'US'),
];

const _alternates = [
  AlternateName(
    geonameId: 104515,
    language: 'ar',
    name: 'مكة المكرمة',
    isPreferred: true,
  ),
  AlternateName(geonameId: 104515, language: 'id', name: 'Mekkah'),
  AlternateName(
    geonameId: 108410,
    language: 'ar',
    name: 'الرياض',
    isPreferred: true,
  ),
  AlternateName(geonameId: 1642911, language: 'id', name: 'Djakarta'),
  AlternateName(geonameId: 1642911, language: 'ar', name: 'جاكرتا'),
  AlternateName(geonameId: 1174872, language: 'ur', name: 'کراچی'),
  AlternateName(geonameId: 1174872, language: 'ar', name: 'كراتشي'),
];

Future<Directory> _tempDir() async {
  final dir = await Directory.systemTemp.createTemp('city_search_test');
  addTearDown(() => dir.delete(recursive: true));
  return dir;
}

Future<String> _buildDb(Directory dir, {String name = 'cities.db'}) async {
  final path = p.join(dir.path, name);
  buildCityDatabase(
    path: path,
    cities: _cities,
    alternateNames: _alternates,
    metadata: const CityDatabaseMetadata(
      sourceUrl: 'test',
      buildDate: '2026-10-21',
    ),
  );
  return path;
}

Future<CityRepository> _repository() async {
  final path = await _buildDb(await _tempDir());
  final repository = CityRepository(() async => path);
  addTearDown(repository.close);
  return repository;
}

void main() {
  group('CityRepository.search', () {
    late CityRepository repository;
    setUp(() async => repository = await _repository());

    Future<List<int>> ids(String query, {int limit = 20}) async => [
      for (final c in await repository.search(query, limit: limit)) c.geonameId,
    ];

    test('ignores case', () async {
      expect(await ids('MAKKAH'), [104515]);
      expect(await ids('jAkArTa'), [1642911]);
    });

    test('ignores diacritics in the query and in the data', () async {
      expect(await ids('zurich'), [2657896, 3000]);
      expect(await ids('Zürich'), [2657896, 3000]);
      expect(await ids('ZURICH H'), [3000]);
    });

    test('treats hyphens like spaces', () async {
      expect(await ids('saint denis'), [2988507]);
      expect(await ids('Saint-Den'), [2988507]);
    });

    test(
      'finds Arabic names, ignoring diacritics and letter variants',
      () async {
        expect(await ids('الرياض'), [108410]);
        expect(await ids('مكه'), [104515]);
        expect(await ids('مَكَّة'), [104515]);
        expect(await ids('جاكرتا'), [1642911]);
      },
    );

    test('finds Urdu names', () async {
      expect(await ids('کراچی'), [1174872]);
      expect(await ids('کرا'), [1174872]);
    });

    test('finds Indonesian names and reports which name matched', () async {
      final results = await repository.search('Djak');
      expect(results.single.geonameId, 1642911);
      expect(results.single.name, 'Jakarta');
      expect(results.single.matchedName, 'Djakarta');
    });

    test('matchedName is null when the primary name matched', () async {
      final results = await repository.search('Jak');
      expect(results.single.matchedName, isNull);
    });

    test('matchedName shows the Arabic name for an Arabic query', () async {
      final results = await repository.search('مكة');
      expect(results.single.matchedName, 'مكة المكرمة');
    });

    test('matches the start of a name only', () async {
      expect(await ids('karta'), isEmpty);
      expect(await ids('akarta'), isEmpty);
    });

    test('orders by population, most populous first', () async {
      expect(await ids('sal'), [8003, 8002, 8001]);
    });

    test('returns each city once even when several names match', () async {
      // "Zurich Heights" matches through its name and its ASCII name.
      final results = await ids('zurich');
      expect(results.toSet().length, results.length);
    });

    test('honours the limit', () async {
      expect(await ids('sal', limit: 2), [8003, 8002]);
      expect(await ids('sal', limit: 0), isEmpty);
    });

    test('returns nothing for an empty or blank query', () async {
      expect(await ids(''), isEmpty);
      expect(await ids('   '), isEmpty);
    });

    test('copes with quotes and wildcards in the query', () async {
      expect(await ids("sal'; DROP TABLE cities; --"), isEmpty);
      expect(await ids('%'), isEmpty);
      expect(await ids('_'), isEmpty);
      expect(await ids('sal%'), isEmpty);
    });

    test('maps every field of the city record', () async {
      final city = (await repository.search('makkah')).single;
      expect(city.geonameId, 104515);
      expect(city.name, 'Makkah');
      expect(city.latitude, 10.5);
      expect(city.longitude, 20.25);
      expect(city.countryCode, 'SA');
      expect(city.timeZoneId, 'Etc/UTC');
      expect(city.population, 1323624);
    });
  });

  group('CityRepository.byId', () {
    test('returns the city or null', () async {
      final repository = await _repository();
      expect((await repository.byId(1174872))?.name, 'Karachi');
      expect((await repository.byId(1174872))?.matchedName, isNull);
      expect(await repository.byId(42), isNull);
    });
  });

  group('database access', () {
    test('the database is opened read-only', () async {
      final path = await _buildDb(await _tempDir());
      final repository = CityRepository(() async => path);
      addTearDown(repository.close);
      await repository.byId(1);
      final writer = sqlite3.open(path, mode: OpenMode.readOnly);
      addTearDown(writer.close);
      expect(
        () => writer.execute('DELETE FROM cities'),
        throwsA(isA<SqliteException>()),
      );
    });

    test('rejects a database from a newer schema', () async {
      final dir = await _tempDir();
      final path = await _buildDb(dir);
      final db = sqlite3.open(path);
      db.execute('PRAGMA user_version = 99');
      db.close();
      final repository = CityRepository(() async => path);
      addTearDown(repository.close);
      expect(
        () => repository.search('mak'),
        throwsA(isA<CityDatabaseException>()),
      );
    });
  });

  group('name normaliser parity with the build tool', () {
    test('agrees on every code point of the Latin and Arabic ranges', () {
      for (var rune = 0x20; rune <= 0x2FFF; rune++) {
        final s = 'a${String.fromCharCode(rune)}b';
        expect(app.normalizeSearchText(s), tool.normalizeSearchText(s));
      }
      for (var rune = 0xFB50; rune <= 0xFEFF; rune++) {
        final s = 'a${String.fromCharCode(rune)}b';
        expect(app.normalizeSearchText(s), tool.normalizeSearchText(s));
      }
    });

    test('agrees on sample names and the version number', () {
      for (final s in ['Zürich', 'مَكَّة', 'کراچی', "Ta'if", ' New  York ']) {
        expect(app.normalizeSearchText(s), tool.normalizeSearchText(s));
      }
      expect(app.normalizationVersion, tool.normalizationVersion);
    });
  });

  group('CityDatabaseProvisioner', () {
    Future<(CityDatabaseProvisioner, Directory, int Function())> setUpProv(
      Future<Uint8List> Function() loadAsset,
    ) async {
      final support = await _tempDir();
      var loads = 0;
      final provisioner = CityDatabaseProvisioner(
        loadAssetBytes: () {
          loads++;
          return loadAsset();
        },
        supportDirectory: () async => support,
      );
      return (provisioner, support, () => loads);
    }

    test('copies the bundled database on first use', () async {
      final source = await _buildDb(await _tempDir());
      final bytes = File(source).readAsBytesSync();
      final (provisioner, support, _) = await setUpProv(() async => bytes);
      final path = await provisioner.ensureDatabase();
      expect(path.startsWith(support.path), isTrue);
      expect(File(path).readAsBytesSync(), bytes);
    });

    test('leaves an identical copy alone and replaces a changed one', () async {
      final dir = await _tempDir();
      final first = File(await _buildDb(dir)).readAsBytesSync();
      var current = first;
      final (provisioner, _, _) = await setUpProv(() async => current);
      final path = await provisioner.ensureDatabase();
      final stamp = File(path).lastModifiedSync();
      await provisioner.ensureDatabase();
      expect(File(path).lastModifiedSync(), stamp);

      current = Uint8List.fromList([...first, 0]);
      await provisioner.ensureDatabase();
      expect(File(path).readAsBytesSync(), current);
    });

    test('repairs a damaged copy', () async {
      final bytes = File(await _buildDb(await _tempDir())).readAsBytesSync();
      final (provisioner, _, _) = await setUpProv(() async => bytes);
      final path = await provisioner.ensureDatabase();
      File(path).writeAsBytesSync([1, 2, 3]);
      await provisioner.ensureDatabase();
      expect(File(path).readAsBytesSync(), bytes);
    });

    test('a repository can search through a provisioned copy', () async {
      final bytes = File(await _buildDb(await _tempDir())).readAsBytesSync();
      final (provisioner, _, _) = await setUpProv(() async => bytes);
      final repository = CityRepository(provisioner.ensureDatabase);
      addTearDown(repository.close);
      expect((await repository.search('kara')).single.name, 'Karachi');
    });
  });
}
