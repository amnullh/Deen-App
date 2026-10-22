import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/drift_tasbih_repository.dart';
import '../../domain/repositories/tasbih_repository.dart';
import '../../domain/tasbih/tasbih_controller.dart';
import '../../domain/tasbih/tasbih_state.dart';
import '../../platform/volume_key_service.dart';
import '../../ui/tasbih/device_services.dart';
import '../providers.dart';

final tasbihRepositoryProvider = Provider<TasbihRepository>(
  (ref) => DriftTasbihRepository(ref.watch(appDatabaseProvider)),
);

final tasbihControllerProvider = Provider<TasbihController>(
  (ref) => TasbihController(
    repository: ref.watch(tasbihRepositoryProvider),
    clock: ref.watch(clockProvider),
  ),
);

/// The counter and its options.
final tasbihStateProvider = StreamProvider<TasbihState>(
  (ref) => ref.watch(tasbihRepositoryProvider).watch(),
);

/// Daily totals, newest first.
final tasbihDaysProvider = StreamProvider<List<TasbihDay>>(
  (ref) => ref.watch(tasbihRepositoryProvider).watchDays(),
);

/// Total counted on today's local date.
final tasbihTodayTotalProvider = Provider<int>((ref) {
  final today = TasbihController.localDate(ref.watch(clockProvider)());
  final days = ref.watch(tasbihDaysProvider).value ?? const <TasbihDay>[];
  for (final day in days) {
    if (day.date == today) return day.total;
  }
  return 0;
});

final volumeKeyServiceProvider = Provider<VolumeKeyService>(
  (ref) => PigeonVolumeKeyService(),
);

final keepAwakeServiceProvider = Provider<KeepAwakeService>(
  (ref) => const WakelockKeepAwake(),
);

final tickPlayerProvider = Provider<TickPlayer>((ref) {
  final player = JustAudioTickPlayer();
  ref.onDispose(player.dispose);
  return player;
});
