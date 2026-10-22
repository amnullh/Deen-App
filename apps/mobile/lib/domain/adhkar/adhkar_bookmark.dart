import 'adhkar_content.dart';

/// A saved entry. Mirrors a row of the `adhkar_bookmark` table.
class AdhkarBookmark {
  const AdhkarBookmark({required this.entryId, required this.createdAt});

  final String entryId;
  final DateTime createdAt;
}

/// A bookmark resolved against the content pack.
class BookmarkedEntry {
  const BookmarkedEntry({
    required this.bookmark,
    required this.collection,
    required this.entry,
  });

  final AdhkarBookmark bookmark;
  final AdhkarCollection collection;
  final AdhkarEntry entry;
}

/// The bookmarks that still match an entry in [pack], newest first. A bookmark
/// whose entry is gone (the pack changed) is skipped, not an error.
List<BookmarkedEntry> bookmarkedEntries(
  AdhkarPack pack,
  Iterable<AdhkarBookmark> bookmarks,
) {
  final resolved = <BookmarkedEntry>[];
  for (final bookmark in bookmarks) {
    final found = pack.findEntry(bookmark.entryId);
    if (found == null) continue;
    resolved.add(
      BookmarkedEntry(
        bookmark: bookmark,
        collection: found.collection,
        entry: found.entry,
      ),
    );
  }
  resolved.sort((a, b) => b.bookmark.createdAt.compareTo(a.bookmark.createdAt));
  return resolved;
}
