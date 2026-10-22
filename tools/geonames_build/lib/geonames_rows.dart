/// Parsing of GeoNames dump rows (tab separated, UTF-8). Pure functions: no
/// file or network access, so they are unit tested with literal rows.
library;

/// One row of `cities15000.txt`, reduced to what the app stores.
class GeoCity {
  const GeoCity({
    required this.geonameId,
    required this.name,
    required this.asciiName,
    required this.latitude,
    required this.longitude,
    required this.countryCode,
    required this.timeZoneId,
    required this.population,
  });

  final int geonameId;
  final String name;
  final String asciiName;
  final double latitude;
  final double longitude;

  /// ISO 3166-1 alpha-2, upper case.
  final String countryCode;

  /// IANA time zone id.
  final String timeZoneId;
  final int population;
}

/// One row of `alternateNamesV2.txt` with the flags this build looks at.
class AlternateNameRow {
  const AlternateNameRow({
    required this.geonameId,
    required this.language,
    required this.name,
    required this.isPreferred,
    required this.isColloquial,
    required this.isHistoric,
  });

  final int geonameId;

  /// The `isolanguage` column (`ar`, `ur`, `id`, `link`, `post`, empty ...).
  final String language;
  final String name;
  final bool isPreferred;
  final bool isColloquial;
  final bool isHistoric;
}

/// Parses a `cities15000.txt` line, or returns null when the row is unusable
/// (too few columns, bad numbers, coordinates out of range, no time zone).
GeoCity? parseCityRow(String line) {
  final c = line.split('\t');
  if (c.length < 19) return null;
  final geonameId = int.tryParse(c[0]);
  final latitude = double.tryParse(c[4]);
  final longitude = double.tryParse(c[5]);
  if (geonameId == null || latitude == null || longitude == null) return null;
  if (latitude < -90 || latitude > 90) return null;
  if (longitude < -180 || longitude > 180) return null;
  final name = c[1].trim();
  final countryCode = c[8].trim().toUpperCase();
  final timeZoneId = c[17].trim();
  if (name.isEmpty || countryCode.isEmpty || timeZoneId.isEmpty) return null;
  final ascii = c[2].trim();
  return GeoCity(
    geonameId: geonameId,
    name: name,
    asciiName: ascii.isEmpty ? name : ascii,
    latitude: latitude,
    longitude: longitude,
    countryCode: countryCode,
    timeZoneId: timeZoneId,
    population: int.tryParse(c[14]) ?? 0,
  );
}

/// Parses an `alternateNamesV2.txt` line, or returns null when malformed.
/// Columns: id, geonameid, isolanguage, name, isPreferredName, isShortName,
/// isColloquial, isHistoric, from, to.
AlternateNameRow? parseAlternateNameRow(String line) {
  final c = line.split('\t');
  if (c.length < 8) return null;
  final geonameId = int.tryParse(c[1]);
  if (geonameId == null) return null;
  return AlternateNameRow(
    geonameId: geonameId,
    language: c[2].trim(),
    name: c[3].trim(),
    isPreferred: c[4].trim() == '1',
    isColloquial: c[6].trim() == '1',
    isHistoric: c[7].trim() == '1',
  );
}
