/// How far one entry has got in one session. Mirrors a row of the
/// `adhkar_progress` table.
class AdhkarProgressRecord {
  const AdhkarProgressRecord({
    required this.sessionId,
    required this.collectionId,
    required this.entryId,
    required this.completedCount,
    required this.startedAt,
    this.finishedAt,
  });

  final String sessionId;
  final String collectionId;
  final String entryId;
  final int completedCount;
  final DateTime startedAt;

  /// Set on every record of a session once all its entries are complete.
  final DateTime? finishedAt;
}
