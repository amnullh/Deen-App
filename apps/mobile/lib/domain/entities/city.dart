/// A place from the bundled offline city list (GeoNames, population over
/// 15,000). The list is read-only; see `content/LICENSES.md` for attribution.
class CityRecord {
  const CityRecord({
    required this.geonameId,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.countryCode,
    required this.timeZoneId,
    required this.population,
    this.matchedName,
  });

  final int geonameId;

  /// Primary (English or ASCII) name.
  final String name;
  final double latitude;
  final double longitude;

  /// ISO 3166-1 alpha-2, upper case.
  final String countryCode;

  /// IANA time zone id, for example `Asia/Riyadh`.
  final String timeZoneId;
  final int population;

  /// The alternate name (Arabic, Urdu or Indonesian) that matched the query,
  /// when it differs from [name]; shown beside the result.
  final String? matchedName;
}
