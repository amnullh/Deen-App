import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prayer_engine/prayer_engine.dart';

import '../../domain/clock_sanity.dart';
import '../../domain/entities/settings.dart';
import '../../domain/os_offset_resolver.dart';
import '../../domain/prayer/day_times_usecase.dart';
import '../../domain/prayer/hijri_source.dart';
import '../../domain/prayer/next_prayer.dart';
import '../../domain/prayer/region_suggestion.dart';
import '../../domain/tz_rules_notice.dart';
import '../providers.dart';
import 'setup_providers.dart';

/// Ticks once per second with the injected clock. The home countdown reads it;
/// tests override [clockProvider] and pump time.
final nowProvider = StreamProvider<DateTime>((ref) {
  final clock = ref.watch(clockProvider);
  final controller = StreamController<DateTime>()..add(clock());
  final timer = Timer.periodic(
    const Duration(seconds: 1),
    (_) => controller.add(clock()),
  );
  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });
  return controller.stream;
});

/// The phone's UTC offset right now. The lifecycle observer compares it from one
/// tick to the next to notice a time-zone or daylight-saving change while the app
/// is open.
final localUtcOffsetProvider = Provider<Duration Function()>((ref) {
  final clock = ref.watch(clockProvider);
  return () => clock().toLocal().timeZoneOffset;
});

/// Counts "recompute everything" events: the app came back to the foreground, or
/// the phone's time zone changed. Day schedules depend on it, so DST and zone
/// rule changes show up without user action (spec Story 2, scenario 8).
class RecomputeEpoch extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state = state + 1;
}

final recomputeEpochProvider = NotifierProvider<RecomputeEpoch, int>(
  RecomputeEpoch.new,
);

/// The phone's current time zone id. Invalidate to read it again.
final deviceZoneIdProvider = FutureProvider<String?>(
  (ref) => ref.watch(deviceZoneSourceProvider).deviceZoneId(),
);

final bundledOffsetResolverProvider = Provider<OffsetResolver>(
  (ref) => BundledOffsetResolver(),
);

/// Offsets from the phone for its own zone and from bundled data otherwise
/// (research R-T1).
final offsetResolverProvider = Provider<OsOffsetResolver>((ref) {
  ref.watch(recomputeEpochProvider);
  return OsOffsetResolver(
    deviceZoneId: ref.watch(deviceZoneIdProvider).value,
    bundled: ref.watch(bundledOffsetResolverProvider),
  );
});

final prayerEngineProvider = Provider<PrayerTimeEngine>(
  (ref) => AdhanDartEngine(offsetResolver: ref.watch(offsetResolverProvider)),
);

/// Converts to Hijri with the Umm al-Qura table. A null source (or a date outside
/// the table) makes the detail page say the Hijri date is not available.
final hijriSourceProvider = Provider<HijriSource?>(
  (ref) => const EngineHijriSource(),
);

final dayTimesUseCaseProvider = Provider<DayTimesUseCase>(
  (ref) => DayTimesUseCase(
    engine: ref.watch(prayerEngineProvider),
    offsets: ref.watch(offsetResolverProvider),
    hijri: ref.watch(hijriSourceProvider),
  ),
);

/// The local date at the saved location, `YYYY-MM-DD`. It changes only when the
/// date does, so everything that depends on it stays still between midnights.
final todayLocalDateProvider = Provider<String?>((ref) {
  final location = ref.watch(locationProvider).value;
  final useCase = ref.watch(dayTimesUseCaseProvider);
  if (location == null) return null;
  return ref.watch(
    nowProvider.select((now) {
      final instant = now.value;
      if (instant == null) return null;
      try {
        return useCase.localDateOf(instant, location.timeZoneId);
      } on ArgumentError {
        return null;
      }
    }),
  );
});

/// How many days the home screen is away from today (negative is the past).
class SelectedDayOffset extends Notifier<int> {
  @override
  int build() => 0;

  void previous() => state = state - 1;
  void next() => state = state + 1;
  void today() => state = 0;
}

final selectedDayOffsetProvider = NotifierProvider<SelectedDayOffset, int>(
  SelectedDayOffset.new,
);

/// The date the home screen shows.
final selectedLocalDateProvider = Provider<String?>((ref) {
  final today = ref.watch(todayLocalDateProvider);
  if (today == null) return null;
  return ref
      .watch(dayTimesUseCaseProvider)
      .shiftDate(today, ref.watch(selectedDayOffsetProvider));
});

/// The times for one local date at the saved location with the saved settings.
/// Data is null before a location and settings exist. Because it watches the
/// settings stream, a change in method, Asr, rule, offsets or Hijri adjustment
/// reaches every screen that shows times at the same moment.
final daySchedulesProvider = Provider.autoDispose
    .family<AsyncValue<DaySchedule?>, String>((ref, localDate) {
      final location = ref.watch(locationProvider).value;
      final settings = ref.watch(prayerSettingsProvider).value;
      final useCase = ref.watch(dayTimesUseCaseProvider);
      if (location == null || settings == null) {
        return const AsyncValue.data(null);
      }
      try {
        return AsyncValue.data(
          useCase.scheduleFor(
            location: location,
            settings: settings,
            localDate: localDate,
          ),
        );
      } on Object catch (error, stackTrace) {
        return AsyncValue.error(error, stackTrace);
      }
    });

/// The schedule of the day on screen.
final selectedScheduleProvider = Provider.autoDispose<AsyncValue<DaySchedule?>>(
  (ref) {
    final date = ref.watch(selectedLocalDateProvider);
    if (date == null) return const AsyncValue.data(null);
    return ref.watch(daySchedulesProvider(date));
  },
);

/// The next prayer, whichever day is on screen. Recomputed every second from
/// two cached day schedules, so the engine runs once per date, not per tick.
final nextPrayerProvider = Provider.autoDispose<NextPrayer?>((ref) {
  final today = ref.watch(todayLocalDateProvider);
  final now = ref.watch(nowProvider).value;
  if (today == null || now == null) return null;
  final useCase = ref.watch(dayTimesUseCaseProvider);
  final first = ref.watch(daySchedulesProvider(today)).value;
  final second = ref
      .watch(daySchedulesProvider(useCase.shiftDate(today, 1)))
      .value;
  if (first == null || second == null) return null;
  return findNextPrayer(today: first.raw, tomorrow: second.raw, now: now);
});

/// The suggestion banner's content, or null when none applies.
final regionSuggestionProvider = Provider.autoDispose<RegionSuggestion?>((ref) {
  final location = ref.watch(locationProvider).value;
  final settings = ref.watch(prayerSettingsProvider).value;
  if (location == null || settings == null) return null;
  return regionSuggestionFor(location: location, settings: settings);
});

// Clock and time-zone checks ---------------------------------------------

/// The date this build was made. Pass `--dart-define=BUILD_DATE=2026-11-02` in
/// release builds; the fallback is the project's start, so a wildly wrong clock
/// is still caught.
final appBuildDateProvider = Provider<DateTime>((ref) {
  const defined = String.fromEnvironment('BUILD_DATE');
  return DateTime.tryParse(defined)?.toUtc() ?? DateTime.utc(2026, 10, 21);
});

final monotonicSourceProvider = Provider<MonotonicSource>(
  (ref) => const NoMonotonicSource(),
);

/// Runs the clock-sanity check, stores the new clock sample, and returns the
/// warning, if any. Invalidate to run it again (on resume).
final clockSanityProvider = FutureProvider<ClockWarning?>((ref) async {
  final alerts = ref.read(alertPreferenceRepositoryProvider);
  final global = await alerts.getGlobal();
  final monotonic = await ref.read(monotonicSourceProvider).read();
  final result = ClockSanityCheck(buildDate: ref.read(appBuildDateProvider))
      .evaluate(
        wallNow: ref.read(clockProvider)(),
        monotonic: monotonic,
        previous: global.clockSample,
      );
  final sample = result.sampleToStore;
  if (sample != null) {
    await alerts.saveGlobal(global.copyWith(clockSample: sample));
  }
  return result.warning;
});

/// True when the phone's time-zone rules and the bundled ones disagree for the
/// saved zone in the next 60 days (research R-T1).
final tzRulesNoticeProvider = Provider<bool>((ref) {
  final location = ref.watch(locationProvider).value;
  if (location == null) return false;
  return timeZoneRulesDisagree(
    zoneId: location.timeZoneId,
    os: ref.watch(offsetResolverProvider),
    bundled: ref.watch(bundledOffsetResolverProvider),
    now: ref.read(clockProvider)(),
  );
});

/// Settings and location for pages that need both, or null while either is
/// missing.
typedef PrayerContext = ({AppLocation location, PrayerSettings settings});

final prayerContextProvider = Provider.autoDispose<PrayerContext?>((ref) {
  final location = ref.watch(locationProvider).value;
  final settings = ref.watch(prayerSettingsProvider).value;
  if (location == null || settings == null) return null;
  return (location: location, settings: settings);
});
