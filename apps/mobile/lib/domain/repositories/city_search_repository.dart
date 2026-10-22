import '../entities/city.dart';

/// Searches the bundled offline city list. Works with no network.
abstract interface class CitySearchRepository {
  /// Cities whose name (or an Arabic, Urdu or Indonesian alternate name) starts
  /// with [query], ignoring case and diacritics, most populous first. An empty
  /// or blank [query] returns an empty list.
  Future<List<CityRecord>> search(String query, {int limit = 20});

  /// The city with [geonameId], or null.
  Future<CityRecord?> byId(int geonameId);
}
