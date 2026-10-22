import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/adhkar/adhkar_content_loader.dart';
import '../../data/repositories/drift_adhkar_repository.dart';
import '../../domain/adhkar/adhkar_bookmark.dart';
import '../../domain/adhkar/adhkar_content.dart';
import '../../domain/adhkar/adhkar_reminder.dart';
import '../../domain/adhkar/adhkar_session.dart';
import '../../domain/repositories/adhkar_repository.dart';
import '../providers.dart';

/// Where the pack comes from. Tests override it with a fake.
final adhkarAssetSourceProvider = Provider<AdhkarAssetSource>(
  (ref) => BundleAdhkarAssetSource(rootBundle),
);

/// The bundled adhkar pack. Empty until the content gate is cleared.
final adhkarPackProvider = FutureProvider<AdhkarPack>(
  (ref) => AdhkarContentLoader(ref.watch(adhkarAssetSourceProvider)).load(),
);

final adhkarProgressRepositoryProvider = Provider<AdhkarProgressRepository>(
  (ref) => DriftAdhkarProgressRepository(ref.watch(appDatabaseProvider)),
);

final adhkarBookmarkRepositoryProvider = Provider<AdhkarBookmarkRepository>(
  (ref) => DriftAdhkarBookmarkRepository(ref.watch(appDatabaseProvider)),
);

/// The planner and alert layers read reminder settings through this.
final adhkarReminderRepositoryProvider = Provider<AdhkarReminderRepository>(
  (ref) => DriftAdhkarReminderRepository(ref.watch(appDatabaseProvider)),
);

final adhkarBookmarksProvider = StreamProvider<List<AdhkarBookmark>>(
  (ref) => ref.watch(adhkarBookmarkRepositoryProvider).watchAll(),
);

/// Morning and evening reminder settings, in that order.
final adhkarRemindersProvider = StreamProvider<List<AdhkarReminder>>(
  (ref) => ref.watch(adhkarReminderRepositoryProvider).watchAll(),
);

/// The running session of one collection (the argument is the collection id).
/// It resumes an unfinished saved session and saves after every change. The
/// value is null when the collection is not in the pack.
final adhkarSessionProvider =
    AsyncNotifierProvider.family<
      AdhkarSessionController,
      AdhkarSession?,
      String
    >(AdhkarSessionController.new);

class AdhkarSessionController extends AsyncNotifier<AdhkarSession?> {
  AdhkarSessionController(this.collectionId);

  final String collectionId;

  @override
  Future<AdhkarSession?> build() async {
    final pack = await ref.watch(adhkarPackProvider.future);
    final collection = pack.collectionById(collectionId);
    if (collection == null) return null;
    final saved = await ref
        .read(adhkarProgressRepositoryProvider)
        .unfinishedSession(collectionId);
    if (saved.isNotEmpty) {
      final restored = AdhkarSession.restore(
        collection: collection,
        records: saved,
      );
      if (!restored.isFinished) return restored;
    }
    return _fresh(collection);
  }

  AdhkarSession _fresh(AdhkarCollection collection) {
    final now = ref.read(clockProvider)();
    return AdhkarSession.start(
      sessionId: '${collection.id}-${now.millisecondsSinceEpoch}',
      collection: collection,
      startedAt: now,
    );
  }

  /// Counts one recitation of [entryId].
  Future<void> tap(String entryId) async {
    final before = state.value;
    if (before == null) return;
    final after = before.tap(entryId, now: ref.read(clockProvider)());
    await _commit(before, after, entryId);
  }

  /// Takes back one recitation of [entryId].
  Future<void> undo(String entryId) async {
    final before = state.value;
    if (before == null) return;
    await _commit(before, before.undo(entryId), entryId);
  }

  /// Begins a new session once the current one is finished.
  void restart() {
    final current = state.value;
    if (current == null || !current.isFinished) return;
    state = AsyncData(_fresh(current.collection));
  }

  Future<void> _commit(
    AdhkarSession before,
    AdhkarSession after,
    String entryId,
  ) async {
    if (identical(before, after)) return;
    state = AsyncData(after);
    // When the session finishes or reopens, every row carries the new finish
    // time, so all of them are saved; otherwise only the changed entry.
    final records = {
      if (before.isFinished != after.isFinished)
        for (final r in after.toRecords()) r.entryId: r,
      entryId: after.recordFor(entryId),
    };
    await ref
        .read(adhkarProgressRepositoryProvider)
        .saveAll(records.values.toList());
  }
}
