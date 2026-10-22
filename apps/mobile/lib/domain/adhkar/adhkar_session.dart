import 'adhkar_content.dart';
import 'adhkar_progress.dart';

/// One run through a collection: how many times each entry has been recited.
///
/// Immutable. Taps return a new session, so the UI can keep the old one for
/// undo and tests need no mocks.
class AdhkarSession {
  AdhkarSession._({
    required this.sessionId,
    required this.collection,
    required this.startedAt,
    required Map<String, int> counts,
    required this.finishedAt,
  }) : _counts = Map.unmodifiable(counts);

  /// A new session with nothing done.
  factory AdhkarSession.start({
    required String sessionId,
    required AdhkarCollection collection,
    required DateTime startedAt,
  }) {
    return AdhkarSession._(
      sessionId: sessionId,
      collection: collection,
      startedAt: startedAt,
      counts: const {},
      finishedAt: null,
    );
  }

  /// Rebuilds a session from saved [records] (which must not be empty). Records
  /// for entries the pack no longer has are dropped and counts are clamped to
  /// the entry's repeat count, so a changed pack never breaks a saved session.
  factory AdhkarSession.restore({
    required AdhkarCollection collection,
    required List<AdhkarProgressRecord> records,
  }) {
    assert(records.isNotEmpty, 'restore needs at least one record');
    final counts = <String, int>{};
    for (final record in records) {
      final entry = collection.entryById(record.entryId);
      if (entry == null) continue;
      counts[entry.id] = record.completedCount.clamp(0, entry.repeatCount);
    }
    final first = records.first;
    final session = AdhkarSession._(
      sessionId: first.sessionId,
      collection: collection,
      startedAt: records
          .map((r) => r.startedAt)
          .reduce((a, b) => a.isBefore(b) ? a : b),
      counts: counts,
      finishedAt: null,
    );
    if (!_allComplete(collection, counts)) return session;
    final saved = records.map((r) => r.finishedAt).whereType<DateTime>();
    return session._copy(
      finishedAt: saved.isEmpty ? session.startedAt : saved.first,
    );
  }

  final String sessionId;
  final AdhkarCollection collection;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final Map<String, int> _counts;

  int countFor(String entryId) => _counts[entryId] ?? 0;

  bool isEntryComplete(String entryId) {
    final entry = collection.entryById(entryId);
    return entry != null && countFor(entryId) >= entry.repeatCount;
  }

  int get totalEntries => collection.entries.length;

  int get completedEntryCount =>
      collection.entries.where((e) => isEntryComplete(e.id)).length;

  /// Share of entries completed, 0 to 1.
  double get fraction =>
      totalEntries == 0 ? 0 : completedEntryCount / totalEntries;

  bool get isFinished => finishedAt != null;

  /// The first entry still to recite, or null when all are complete.
  String? get firstIncompleteEntryId {
    for (final entry in collection.entries) {
      if (!isEntryComplete(entry.id)) return entry.id;
    }
    return null;
  }

  /// Counts one recitation of [entryId]. Entries not in the collection and
  /// entries already at their repeat count are left unchanged.
  AdhkarSession tap(String entryId, {required DateTime now}) {
    final entry = collection.entryById(entryId);
    if (entry == null || countFor(entryId) >= entry.repeatCount) return this;
    final counts = {..._counts, entryId: countFor(entryId) + 1};
    return _copy(
      counts: counts,
      finishedAt: _allComplete(collection, counts) ? now : null,
    );
  }

  /// Takes back one recitation of [entryId]; a finished session becomes open
  /// again.
  AdhkarSession undo(String entryId) {
    final current = countFor(entryId);
    if (current == 0) return this;
    return _copy(counts: {..._counts, entryId: current - 1}, finishedAt: null);
  }

  /// Records to save: one per entry that has progress.
  List<AdhkarProgressRecord> toRecords() => [
    for (final entry in collection.entries)
      if (countFor(entry.id) > 0)
        AdhkarProgressRecord(
          sessionId: sessionId,
          collectionId: collection.id,
          entryId: entry.id,
          completedCount: countFor(entry.id),
          startedAt: startedAt,
          finishedAt: finishedAt,
        ),
  ];

  /// The record for one entry, also when it has no progress. Saving it after
  /// an undo overwrites the earlier count with zero.
  AdhkarProgressRecord recordFor(String entryId) => AdhkarProgressRecord(
    sessionId: sessionId,
    collectionId: collection.id,
    entryId: entryId,
    completedCount: countFor(entryId),
    startedAt: startedAt,
    finishedAt: finishedAt,
  );

  AdhkarSession _copy({
    Map<String, int>? counts,
    required DateTime? finishedAt,
  }) {
    return AdhkarSession._(
      sessionId: sessionId,
      collection: collection,
      startedAt: startedAt,
      counts: counts ?? _counts,
      finishedAt: finishedAt,
    );
  }

  static bool _allComplete(
    AdhkarCollection collection,
    Map<String, int> counts,
  ) {
    if (collection.entries.isEmpty) return false;
    return collection.entries.every(
      (e) => (counts[e.id] ?? 0) >= e.repeatCount,
    );
  }
}
