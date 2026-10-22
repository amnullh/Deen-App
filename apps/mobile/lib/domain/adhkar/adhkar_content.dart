import '../entities/enums.dart';

/// The kinds of adhkar collections (spec Story 6, scenario 1).
enum AdhkarCollectionKind {
  morning,
  evening,
  afterPrayer,
  beforeSleep,
  waking,
  other,
}

/// One text to recite. Every entry carries its source, license and reviewer
/// because no religious text may ship without them (FR-008).
class AdhkarEntry {
  const AdhkarEntry({
    required this.id,
    required this.order,
    required this.arabic,
    required this.repeatCount,
    required this.reference,
    required this.sourceId,
    required this.licenseId,
    required this.reviewer,
    required this.reviewedOn,
    this.transliteration,
    this.translations = const {},
  });

  final String id;

  /// Position inside its collection, starting at 1.
  final int order;
  final String arabic;
  final String? transliteration;

  /// Translations by app language. Only languages the pack provides appear.
  final Map<AppLanguage, String> translations;
  final int repeatCount;

  /// Where the text comes from, for example a hadith reference.
  final String reference;

  /// Ids into the content register (`content/LICENSES.md`).
  final String sourceId;
  final String licenseId;
  final String reviewer;

  /// ISO date of the review, as written in the pack.
  final String reviewedOn;

  /// The translation to show for [language]: the user's language when the pack
  /// has it, otherwise English, otherwise nothing. Arabic readers see only the
  /// Arabic text. The returned language tells the UI which script and
  /// direction the text is in.
  ({AppLanguage language, String text})? translationFor(AppLanguage language) {
    if (language == AppLanguage.ar) return null;
    final own = translations[language];
    if (own != null && own.trim().isNotEmpty) {
      return (language: language, text: own);
    }
    final english = translations[AppLanguage.en];
    if (english != null && english.trim().isNotEmpty) {
      return (language: AppLanguage.en, text: english);
    }
    return null;
  }
}

/// A named group of entries such as the morning adhkar.
class AdhkarCollection {
  AdhkarCollection({
    required this.id,
    required this.kind,
    required List<AdhkarEntry> entries,
    this.titles = const {},
    this.sourceId,
  }) : entries = List.unmodifiable(
         [...entries]..sort((a, b) => a.order.compareTo(b.order)),
       );

  final String id;
  final AdhkarCollectionKind kind;

  /// Titles from the pack by language. The UI falls back to its own name for
  /// the [kind] when the pack has none.
  final Map<AppLanguage, String> titles;
  final String? sourceId;
  final List<AdhkarEntry> entries;

  AdhkarEntry? entryById(String entryId) {
    for (final entry in entries) {
      if (entry.id == entryId) return entry;
    }
    return null;
  }
}

/// Source and reviewer of one text, as listed in the About screen (Story 6,
/// scenario 5).
class AdhkarCredit {
  const AdhkarCredit({
    required this.collectionId,
    required this.entryId,
    required this.order,
    required this.reference,
    required this.sourceId,
    required this.licenseId,
    required this.reviewer,
    required this.reviewedOn,
  });

  final String collectionId;
  final String entryId;
  final int order;
  final String reference;
  final String sourceId;
  final String licenseId;
  final String reviewer;
  final String reviewedOn;
}

/// Everything the bundled content pack provides. An empty pack is valid: it is
/// what ships until the content gate is cleared (plan D-4).
class AdhkarPack {
  const AdhkarPack({required this.collections, this.problems = const []});

  const AdhkarPack.empty() : collections = const [], problems = const [];

  final List<AdhkarCollection> collections;

  /// Why records were skipped while loading, for developers. Never shown as
  /// religious content.
  final List<String> problems;

  bool get isEmpty => collections.every((c) => c.entries.isEmpty);

  AdhkarCollection? collectionById(String id) {
    for (final collection in collections) {
      if (collection.id == id) return collection;
    }
    return null;
  }

  /// The collection and entry for [entryId], or null.
  ({AdhkarCollection collection, AdhkarEntry entry})? findEntry(
    String entryId,
  ) {
    for (final collection in collections) {
      final entry = collection.entryById(entryId);
      if (entry != null) return (collection: collection, entry: entry);
    }
    return null;
  }

  /// One credit per entry, in collection and entry order.
  List<AdhkarCredit> get credits => [
    for (final collection in collections)
      for (final entry in collection.entries)
        AdhkarCredit(
          collectionId: collection.id,
          entryId: entry.id,
          order: entry.order,
          reference: entry.reference,
          sourceId: entry.sourceId,
          licenseId: entry.licenseId,
          reviewer: entry.reviewer,
          reviewedOn: entry.reviewedOn,
        ),
  ];
}
