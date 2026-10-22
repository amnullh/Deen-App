import 'package:geonames_build/alternate_names.dart';
import 'package:geonames_build/geonames_rows.dart';
import 'package:test/test.dart';

/// Builds a 19-column cities15000 row.
String cityRow({
  String id = '104515',
  String name = 'Makkah',
  String ascii = 'Makkah',
  String alternates = 'Mecca,Makka',
  String lat = '21.42664',
  String lon = '39.82563',
  String cc = 'SA',
  String population = '1323624',
  String tz = 'Asia/Riyadh',
}) {
  return [
    id,
    name,
    ascii,
    alternates,
    lat,
    lon,
    'P',
    'PPLA',
    cc,
    '',
    '14',
    '',
    '',
    '',
    population,
    '',
    '277',
    tz,
    '2024-01-01',
  ].join('\t');
}

String altRow({
  String id = '1',
  String geonameId = '104515',
  String language = 'ar',
  String name = 'مكة',
  String preferred = '',
  String short = '',
  String colloquial = '',
  String historic = '',
}) {
  return [
    id,
    geonameId,
    language,
    name,
    preferred,
    short,
    colloquial,
    historic,
    '',
    '',
  ].join('\t');
}

void main() {
  group('parseCityRow', () {
    test('reads the fields the app needs', () {
      final city = parseCityRow(cityRow());
      expect(city, isNotNull);
      expect(city!.geonameId, 104515);
      expect(city.name, 'Makkah');
      expect(city.asciiName, 'Makkah');
      expect(city.latitude, closeTo(21.42664, 1e-9));
      expect(city.longitude, closeTo(39.82563, 1e-9));
      expect(city.countryCode, 'SA');
      expect(city.timeZoneId, 'Asia/Riyadh');
      expect(city.population, 1323624);
    });

    test('rejects rows that are short or have bad numbers', () {
      expect(parseCityRow('1\tonly\tthree'), isNull);
      expect(parseCityRow(cityRow(id: 'x')), isNull);
      expect(parseCityRow(cityRow(lat: 'north')), isNull);
      expect(parseCityRow(cityRow(lat: '91')), isNull);
      expect(parseCityRow(cityRow(lon: '181')), isNull);
    });

    test('rejects rows without a time zone or country', () {
      expect(parseCityRow(cityRow(tz: '')), isNull);
      expect(parseCityRow(cityRow(cc: '')), isNull);
    });

    test('falls back to the name when the ascii name is empty', () {
      expect(parseCityRow(cityRow(ascii: ''))!.asciiName, 'Makkah');
    });

    test('treats a missing population as zero', () {
      expect(parseCityRow(cityRow(population: ''))!.population, 0);
    });
  });

  group('parseAlternateNameRow', () {
    test('reads language, flags and the name', () {
      final row = parseAlternateNameRow(altRow(preferred: '1'));
      expect(row, isNotNull);
      expect(row!.geonameId, 104515);
      expect(row.language, 'ar');
      expect(row.name, 'مكة');
      expect(row.isPreferred, isTrue);
      expect(row.isColloquial, isFalse);
      expect(row.isHistoric, isFalse);
    });

    test('rejects malformed rows', () {
      expect(parseAlternateNameRow('1\t2'), isNull);
      expect(parseAlternateNameRow(altRow(geonameId: 'abc')), isNull);
    });
  });

  group('AlternateNameSelector', () {
    AlternateNameRow? row(String line) => parseAlternateNameRow(line);

    test('keeps only wanted languages for wanted cities', () {
      final selector = AlternateNameSelector(
        cityIds: {104515},
        languages: {'ar', 'ur', 'id'},
      );
      expect(selector.offer(row(altRow(language: 'ar'))!), isTrue);
      expect(
        selector.offer(row(altRow(language: 'fr', name: 'La Mecque'))!),
        isFalse,
      );
      expect(
        selector.offer(row(altRow(geonameId: '1', language: 'ar'))!),
        isFalse,
      );
    });

    test('accepts country variants of a wanted language', () {
      final selector = AlternateNameSelector(
        cityIds: {104515},
        languages: {'ar'},
      );
      expect(selector.offer(row(altRow(language: 'ar-SA'))!), isTrue);
      expect(selector.result().single.language, 'ar');
    });

    test('skips historic and colloquial names and link-only languages', () {
      final selector = AlternateNameSelector(
        cityIds: {104515},
        languages: {'ar'},
      );
      expect(
        selector.offer(row(altRow(historic: '1', name: 'قديم'))!),
        isFalse,
      );
      expect(
        selector.offer(row(altRow(colloquial: '1', name: 'عامي'))!),
        isFalse,
      );
      expect(
        selector.offer(row(altRow(language: 'link', name: 'http://x'))!),
        isFalse,
      );
    });

    test('skips names with no letters and duplicates', () {
      final selector = AlternateNameSelector(
        cityIds: {104515},
        languages: {'ar'},
      );
      expect(selector.offer(row(altRow(name: '  '))!), isFalse);
      expect(selector.offer(row(altRow(name: 'مكة'))!), isTrue);
      expect(
        selector.offer(row(altRow(id: '2', name: 'مكة المكرمة'))!),
        isTrue,
      );
      // Same name once diacritics and heh variants are folded.
      expect(selector.offer(row(altRow(id: '4', name: 'مَكَّه'))!), isFalse);
      expect(selector.offer(row(altRow(id: '3', name: 'مكة'))!), isFalse);
    });

    test(
      'result lists the preferred name first and caps names per language',
      () {
        final selector = AlternateNameSelector(
          cityIds: {104515},
          languages: {'ar'},
          maxPerLanguage: 2,
        );
        selector.offer(row(altRow(id: '1', name: 'ألف'))!);
        selector.offer(row(altRow(id: '2', name: 'باء', preferred: '1'))!);
        selector.offer(row(altRow(id: '3', name: 'جيم'))!);
        final names = selector.result();
        expect(names.map((n) => n.name), ['باء', 'ألف']);
        expect(names.first.isPreferred, isTrue);
      },
    );

    test('result is ordered by city id then language for reproducibility', () {
      final selector = AlternateNameSelector(
        cityIds: {5, 3},
        languages: {'ar', 'id'},
      );
      selector.offer(
        row(altRow(geonameId: '5', language: 'id', name: 'Lima'))!,
      );
      selector.offer(
        row(altRow(geonameId: '3', language: 'ar', name: 'ثلاثة'))!,
      );
      selector.offer(
        row(altRow(geonameId: '5', language: 'ar', name: 'خمسة'))!,
      );
      expect(selector.result().map((n) => '${n.geonameId}${n.language}'), [
        '3ar',
        '5ar',
        '5id',
      ]);
    });
  });
}
