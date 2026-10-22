import 'dart:async';

import 'package:deen_mobile/domain/repositories/tasbih_repository.dart';
import 'package:deen_mobile/domain/result.dart';
import 'package:deen_mobile/domain/tasbih/tasbih_state.dart';

/// An in-memory [TasbihRepository] with the same rules as the drift one, for
/// tests of the controller and the screen (no timers, no database).
class FakeTasbihRepository implements TasbihRepository {
  FakeTasbihRepository([TasbihState initial = TasbihState.initial])
    : _state = initial;

  TasbihState _state;
  final Map<String, int> _days = {};
  final _stateChanges = StreamController<TasbihState>.broadcast();
  final _dayChanges = StreamController<void>.broadcast();

  @override
  Future<TasbihState> get() async => _state;

  @override
  Stream<TasbihState> watch() async* {
    yield _state;
    yield* _stateChanges.stream;
  }

  void _set(TasbihState state) {
    _state = state;
    _stateChanges.add(state);
  }

  @override
  Future<TasbihState> increment(String localDate) async {
    _days[localDate] = (_days[localDate] ?? 0) + 1;
    _dayChanges.add(null);
    _set(_state.copyWith(count: _state.count + 1));
    return _state;
  }

  @override
  Future<TasbihState> resetCount() async {
    _set(_state.copyWith(count: 0));
    return _state;
  }

  @override
  Future<Result<void>> setTarget(int target) async {
    if (!TasbihState.isValidTarget(target)) {
      return const Err(AppError(ErrorCode.invalidArgument, 'bad target'));
    }
    _set(_state.copyWith(target: target));
    return const Ok(null);
  }

  @override
  Future<void> setOptions({
    bool? keepAwake,
    bool? volumeKeys,
    bool? lock,
    bool? haptics,
    bool? sound,
  }) async {
    _set(
      _state.copyWith(
        keepAwake: keepAwake,
        volumeKeys: volumeKeys,
        lock: lock,
        haptics: haptics,
        sound: sound,
      ),
    );
  }

  List<TasbihDay> _daysNewestFirst(int limit) {
    final dates = _days.keys.toList()..sort((a, b) => b.compareTo(a));
    return [
      for (final date in dates.take(limit)) TasbihDay(date, _days[date]!),
    ];
  }

  @override
  Stream<List<TasbihDay>> watchDays({int limit = 30}) async* {
    yield _daysNewestFirst(limit);
    yield* _dayChanges.stream.map((_) => _daysNewestFirst(limit));
  }

  /// Seeds a daily total for screen tests.
  void seedDay(String date, int total) {
    _days[date] = total;
    _dayChanges.add(null);
  }
}
