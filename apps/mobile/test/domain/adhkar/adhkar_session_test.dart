import 'package:deen_mobile/domain/adhkar/adhkar_progress.dart';
import 'package:deen_mobile/domain/adhkar/adhkar_session.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

final _t0 = DateTime.utc(2026, 10, 21, 5);
final _t1 = DateTime.utc(2026, 10, 21, 5, 4);

AdhkarSession _start() => AdhkarSession.start(
  sessionId: 's1',
  collection: fakeCollection(),
  startedAt: _t0,
);

void main() {
  group('AdhkarSession', () {
    test('starts with nothing done', () {
      final s = _start();
      expect(s.completedEntryCount, 0);
      expect(s.totalEntries, 3);
      expect(s.fraction, 0);
      expect(s.isFinished, isFalse);
      expect(s.countFor('e1'), 0);
      expect(s.firstIncompleteEntryId, 'e1');
    });

    test('counts taps up to the entry repeat count and stops there', () {
      var s = _start();
      s = s.tap('e1', now: _t0);
      s = s.tap('e1', now: _t0);
      expect(s.countFor('e1'), 2);
      expect(s.isEntryComplete('e1'), isFalse);
      s = s.tap('e1', now: _t0);
      expect(s.isEntryComplete('e1'), isTrue);
      final again = s.tap('e1', now: _t0);
      expect(again.countFor('e1'), 3, reason: 'never above the repeat count');
      expect(s.completedEntryCount, 1);
      expect(s.firstIncompleteEntryId, 'e2');
    });

    test('ignores an entry that is not in the collection', () {
      final s = _start().tap('missing', now: _t0);
      expect(s.completedEntryCount, 0);
      expect(s.toRecords(), isEmpty);
    });

    test('finishes when every entry is complete and records the time', () {
      var s = _start();
      for (final id in ['e1', 'e1', 'e1', 'e2', 'e3', 'e3']) {
        expect(s.isFinished, isFalse);
        s = s.tap(id, now: _t1);
      }
      expect(s.isFinished, isTrue);
      expect(s.finishedAt, _t1);
      expect(s.fraction, 1);
      expect(s.firstIncompleteEntryId, isNull);
    });

    test('undo removes one tap and reopens a finished session', () {
      var s = _start();
      for (final id in ['e1', 'e1', 'e1', 'e2', 'e3', 'e3']) {
        s = s.tap(id, now: _t1);
      }
      s = s.undo('e3');
      expect(s.countFor('e3'), 1);
      expect(s.isFinished, isFalse);
      expect(s.finishedAt, isNull);
      expect(s.undo('e1').undo('e1').undo('e1').undo('e1').countFor('e1'), 0);
    });

    test(
      'toRecords lists only entries with progress and carries finish time',
      () {
        var s = _start().tap('e2', now: _t0);
        var records = s.toRecords();
        expect(records, hasLength(1));
        expect(records.single.sessionId, 's1');
        expect(records.single.collectionId, 'morning');
        expect(records.single.entryId, 'e2');
        expect(records.single.completedCount, 1);
        expect(records.single.startedAt, _t0);
        expect(records.single.finishedAt, isNull);

        for (final id in ['e1', 'e1', 'e1', 'e3', 'e3']) {
          s = s.tap(id, now: _t1);
        }
        records = s.toRecords();
        expect(records, hasLength(3));
        expect(records.every((r) => r.finishedAt == _t1), isTrue);
      },
    );

    test('restore rebuilds the session and drops entries no longer in the '
        'pack', () {
      final restored = AdhkarSession.restore(
        collection: fakeCollection(),
        records: [
          AdhkarProgressRecord(
            sessionId: 's9',
            collectionId: 'morning',
            entryId: 'e1',
            completedCount: 2,
            startedAt: _t0,
          ),
          AdhkarProgressRecord(
            sessionId: 's9',
            collectionId: 'morning',
            entryId: 'gone',
            completedCount: 5,
            startedAt: _t0,
          ),
          AdhkarProgressRecord(
            sessionId: 's9',
            collectionId: 'morning',
            entryId: 'e2',
            completedCount: 99,
            startedAt: _t0,
          ),
        ],
      );
      expect(restored.sessionId, 's9');
      expect(restored.startedAt, _t0);
      expect(restored.countFor('e1'), 2);
      expect(restored.countFor('gone'), 0);
      expect(restored.countFor('e2'), 1, reason: 'clamped to the repeat count');
    });

    test('an empty collection is never "finished"', () {
      final s = AdhkarSession.start(
        sessionId: 's',
        collection: fakeCollection(entries: const []),
        startedAt: _t0,
      );
      expect(s.isFinished, isFalse);
      expect(s.fraction, 0);
    });
  });
}
