import 'package:drift/drift.dart';

import '../db/app_database.dart';

/// The tasbih options that travel with an exported settings file. The counter
/// value and daily history are not part of it.
class TasbihSettings {
  const TasbihSettings({
    this.target = 33,
    this.keepAwake = false,
    this.volumeKeys = false,
    this.lock = false,
    this.haptics = true,
    this.sound = false,
  });

  static const int minTarget = 1;
  static const int maxTarget = 100000;

  final int target;
  final bool keepAwake;
  final bool volumeKeys;
  final bool lock;
  final bool haptics;
  final bool sound;

  TasbihSettings copyWith({
    int? target,
    bool? keepAwake,
    bool? volumeKeys,
    bool? lock,
    bool? haptics,
    bool? sound,
  }) {
    return TasbihSettings(
      target: target ?? this.target,
      keepAwake: keepAwake ?? this.keepAwake,
      volumeKeys: volumeKeys ?? this.volumeKeys,
      lock: lock ?? this.lock,
      haptics: haptics ?? this.haptics,
      sound: sound ?? this.sound,
    );
  }
}

/// Reads and writes [TasbihSettings] without touching the running count.
abstract interface class TasbihSettingsStore {
  Future<TasbihSettings> read();
  Future<void> write(TasbihSettings settings);
}

/// Stores the options in the single `tasbih_state` row.
class DriftTasbihSettingsStore implements TasbihSettingsStore {
  DriftTasbihSettingsStore(this._db);

  final AppDatabase _db;

  @override
  Future<TasbihSettings> read() async {
    final row = await _db.select(_db.tasbihStateTable).getSingleOrNull();
    if (row == null) return const TasbihSettings();
    return TasbihSettings(
      target: row.target,
      keepAwake: row.keepAwake,
      volumeKeys: row.volumeKeys,
      lock: row.lock,
      haptics: row.haptics,
      sound: row.sound,
    );
  }

  @override
  Future<void> write(TasbihSettings settings) async {
    // Only the option columns are named, so an existing count survives.
    await _db
        .into(_db.tasbihStateTable)
        .insertOnConflictUpdate(
          TasbihStateTableCompanion(
            id: const Value(1),
            target: Value(settings.target),
            keepAwake: Value(settings.keepAwake),
            volumeKeys: Value(settings.volumeKeys),
            lock: Value(settings.lock),
            haptics: Value(settings.haptics),
            sound: Value(settings.sound),
          ),
        );
  }
}
