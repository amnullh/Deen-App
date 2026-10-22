/// Chooses which alternate names go into the database.
library;

import 'geonames_rows.dart';
import 'normalize.dart';

/// The language part of an `isolanguage` value: `ar-SA` and `ur-PK` give
/// `ar` and `ur`; `link`, `post` and similar codes are left as they are.
String baseLanguage(String isoLanguage) => isoLanguage.split('-').first;

/// An alternate name kept for the search table.
class AlternateName {
  const AlternateName({
    required this.geonameId,
    required this.language,
    required this.name,
    this.isPreferred = false,
  });

  final int geonameId;
  final String language;
  final String name;
  final bool isPreferred;
}

/// Streams through alternate-name rows and keeps the useful ones.
///
/// Kept: names in [languages] for cities in [cityIds] that are neither
/// historic nor colloquial, are not empty, and are not a duplicate (after
/// normalisation) of a name already kept for the same city. At most
/// [maxPerLanguage] names are kept per city and language, preferred names
/// first, so a few unusual spellings cannot bloat the database.
class AlternateNameSelector {
  AlternateNameSelector({
    required this.cityIds,
    required this.languages,
    this.maxPerLanguage = 6,
  });

  final Set<int> cityIds;
  final Set<String> languages;
  final int maxPerLanguage;

  final Map<(int, String), List<AlternateName>> _byKey = {};
  final Set<(int, String)> _seen = {};

  /// Considers [row]; returns true when it was kept.
  bool offer(AlternateNameRow row) {
    final language = baseLanguage(row.language);
    if (!languages.contains(language)) return false;
    if (!cityIds.contains(row.geonameId)) return false;
    if (row.isHistoric || row.isColloquial) return false;
    final normalized = normalizeSearchText(row.name);
    if (normalized.isEmpty) return false;
    if (!_seen.add((row.geonameId, normalized))) return false;
    _byKey
        .putIfAbsent((row.geonameId, row.language), () => [])
        .add(
          AlternateName(
            geonameId: row.geonameId,
            language: language,
            name: row.name,
            isPreferred: row.isPreferred,
          ),
        );
    return true;
  }

  /// The kept names ordered by city id, then language, then preferred first
  /// (ties in input order), capped per city and language.
  List<AlternateName> result() {
    final keys = _byKey.keys.toList()
      ..sort((a, b) {
        final byId = a.$1.compareTo(b.$1);
        return byId != 0 ? byId : a.$2.compareTo(b.$2);
      });
    final out = <AlternateName>[];
    for (final key in keys) {
      final names = _byKey[key]!;
      final preferred = names.where((n) => n.isPreferred);
      final others = names.where((n) => !n.isPreferred);
      out.addAll([...preferred, ...others].take(maxPerLanguage));
    }
    return out;
  }
}
