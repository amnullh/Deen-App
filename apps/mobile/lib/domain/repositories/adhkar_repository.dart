import '../adhkar/adhkar_bookmark.dart';
import '../adhkar/adhkar_progress.dart';
import '../adhkar/adhkar_reminder.dart';
import '../entities/enums.dart';
import '../result.dart';

/// Saved progress through adhkar sessions. Stays on the device.
abstract interface class AdhkarProgressRepository {
  /// Saves [records], replacing earlier rows for the same session and entry.
  /// Returns an [Err] and saves nothing when a count is negative.
  Future<Result<void>> saveAll(List<AdhkarProgressRecord> records);

  Future<List<AdhkarProgressRecord>> recordsForSession(String sessionId);

  /// Records of the newest session of [collectionId] that has not finished, or
  /// an empty list. The reader resumes that session.
  Future<List<AdhkarProgressRecord>> unfinishedSession(String collectionId);

  /// Removes every saved session (used by delete-all-data).
  Future<void> clear();
}

/// Entries the user saved for later.
abstract interface class AdhkarBookmarkRepository {
  Future<List<AdhkarBookmark>> getAll();
  Stream<List<AdhkarBookmark>> watchAll();

  /// Adds the bookmark when absent and removes it when present. Returns true
  /// when the entry is bookmarked afterwards.
  Future<bool> toggle(String entryId, {required DateTime now});

  /// Replaces all bookmarks in one step (settings import).
  Future<void> replaceAll(List<AdhkarBookmark> bookmarks);

  Future<void> clear();
}

/// The morning and evening reminder settings.
abstract interface class AdhkarReminderRepository {
  /// Both reminders in order (morning, evening); a kind never saved gets its
  /// default, switched off.
  Future<List<AdhkarReminder>> getAll();
  Stream<List<AdhkarReminder>> watchAll();

  /// Validates the anchor for the kind and the offset range, then saves.
  Future<Result<void>> save(AdhkarReminder reminder);

  /// Saves several reminders in one step (settings import). Returns an [Err]
  /// and changes nothing when any of them is invalid.
  Future<Result<void>> saveAll(List<AdhkarReminder> reminders);

  Future<void> clear();

  static const List<AdhkarReminderKind> kinds = AdhkarReminderKind.values;
}
