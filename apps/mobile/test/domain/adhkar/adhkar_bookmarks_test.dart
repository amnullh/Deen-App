import 'package:deen_mobile/domain/adhkar/adhkar_bookmark.dart';
import 'package:deen_mobile/domain/adhkar/adhkar_content.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

void main() {
  group('bookmarkedEntries', () {
    final pack = fakePack();

    test('lists bookmarked entries, newest bookmark first', () {
      final result = bookmarkedEntries(pack, [
        AdhkarBookmark(entryId: 'e1', createdAt: DateTime.utc(2026, 1, 1)),
        AdhkarBookmark(entryId: 'e3', createdAt: DateTime.utc(2026, 1, 3)),
        AdhkarBookmark(entryId: 'e2', createdAt: DateTime.utc(2026, 1, 2)),
      ]);
      expect(result.map((b) => b.entry.id), ['e3', 'e2', 'e1']);
      expect(result.first.collection.id, 'morning');
    });

    test('drops bookmarks whose entry is no longer in the pack', () {
      final result = bookmarkedEntries(pack, [
        AdhkarBookmark(entryId: 'gone', createdAt: DateTime.utc(2026, 1, 1)),
        AdhkarBookmark(entryId: 'e1', createdAt: DateTime.utc(2026, 1, 1)),
      ]);
      expect(result.map((b) => b.entry.id), ['e1']);
    });

    test('is empty for an empty pack', () {
      expect(
        bookmarkedEntries(const AdhkarPack(collections: []), [
          AdhkarBookmark(entryId: 'e1', createdAt: DateTime.utc(2026)),
        ]),
        isEmpty,
      );
    });
  });
}
