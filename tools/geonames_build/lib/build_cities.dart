/// Orchestrates the whole build from the two GeoNames zips to `cities.db`.
library;

import 'dart:io';

import 'alternate_names.dart';
import 'city_database_builder.dart';
import 'geonames_download.dart';
import 'geonames_rows.dart';

/// Languages whose alternate names are kept (ISO 639-1): Arabic, Urdu,
/// Indonesian, the app's interface languages besides English.
const Set<String> defaultLanguages = {'ar', 'ur', 'id'};

/// Parses every row of [lines] with [parse], collecting the results and
/// counting rows that could not be parsed.
Future<(List<T>, int)> collectRows<T extends Object>(
  Stream<String> lines,
  T? Function(String line) parse,
) async {
  final rows = <T>[];
  var skipped = 0;
  await for (final line in lines) {
    if (line.isEmpty) continue;
    final row = parse(line);
    if (row == null) {
      skipped++;
    } else {
      rows.add(row);
    }
  }
  return (rows, skipped);
}

/// Runs the build; [log] receives progress lines.
Future<BuildReport> buildFromGeonames({
  required Directory cacheDir,
  required String outputPath,
  required String buildDate,
  Set<String> languages = defaultLanguages,
  void Function(String message)? log,
}) async {
  final citiesZip = await ensureDownloaded(
    'cities15000.zip',
    cacheDir,
    log: log,
  );
  final alternateZip = await ensureDownloaded(
    'alternateNamesV2.zip',
    cacheDir,
    log: log,
  );

  final (cities, skippedCities) = await collectRows(
    zipEntryLines(citiesZip, 'cities15000.txt'),
    parseCityRow,
  );
  log?.call('Read ${cities.length} cities ($skippedCities unusable rows).');

  final selector = AlternateNameSelector(
    cityIds: {for (final city in cities) city.geonameId},
    languages: languages,
  );
  var scanned = 0;
  await for (final line in zipEntryLines(
    alternateZip,
    'alternateNamesV2.txt',
  )) {
    scanned++;
    final row = parseAlternateNameRow(line);
    if (row != null) selector.offer(row);
  }
  final alternates = selector.result();
  log?.call('Scanned $scanned alternate-name rows; kept ${alternates.length}.');

  final languageList = (languages.toList()..sort()).join(',');
  return buildCityDatabase(
    path: outputPath,
    cities: cities,
    alternateNames: alternates,
    metadata: CityDatabaseMetadata(
      sourceUrl: geonamesDumpUrl,
      buildDate: buildDate,
      extra: {'languages': languageList},
    ),
  );
}
