import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prayer_engine/prayer_engine.dart';

import '../../app/providers/prayer_providers.dart';
import '../../domain/entities/settings.dart';
import '../../domain/prayer/day_times_usecase.dart';
import '../../domain/prayer/next_prayer.dart';
import '../../l10n/generated/app_localizations.dart';
import '../common/info_banner.dart';
import '../common/permission_banner.dart';
import '../common/prayer_labels.dart';
import '../common/time_format.dart';
import '../settings/location_settings_page.dart';
import '../settings/prayer_settings_page.dart';
import 'clock_warning_banner.dart';
import 'detail_page.dart';
import 'region_suggestion_banner.dart';
import 'tz_rules_banner.dart';

/// The home screen: today's six times, the next prayer with a live countdown,
/// and previous and next day navigation.
///
/// [extraActions] are placed in the app bar beside the prayer settings button,
/// for example the Reliability check entry the app shell owns.
class HomePage extends ConsumerWidget {
  const HomePage({this.extraActions = const [], super.key});

  final List<Widget> extraActions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(prayerContextProvider);
    return Scaffold(
      key: const Key('home-page'),
      appBar: AppBar(
        title: Text(l10n.homeTitle),
        actions: [
          IconButton(
            key: const Key('open-prayer-settings'),
            tooltip: l10n.prayerSettingsTitle,
            icon: const Icon(Icons.tune),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const PrayerSettingsPage(),
              ),
            ),
          ),
          ...extraActions,
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsetsDirectional.all(16),
          children: [
            const ClockWarningBanner(),
            const TzRulesBanner(),
            const RegionSuggestionBanner(),
            const PermissionBanners(),
            if (profile == null)
              const _NoLocation()
            else ...[
              _DayHeader(location: profile.location),
              const NextPrayerCard(),
              const SizedBox(height: 8),
              _DayList(profile: profile),
            ],
          ],
        ),
      ),
    );
  }
}

class _NoLocation extends StatelessWidget {
  const _NoLocation();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: 32),
      child: Column(
        children: [
          Text(
            l10n.homeNoLocation,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('home-choose-location'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const LocationSettingsPage(),
              ),
            ),
            child: Text(l10n.homeChooseLocation),
          ),
        ],
      ),
    );
  }
}

/// Place, date, and the previous and next day buttons.
class _DayHeader extends ConsumerWidget {
  const _DayHeader({required this.location});

  final AppLocation location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final date = ref.watch(selectedLocalDateProvider);
    final offset = ref.watch(selectedDayOffsetProvider);
    final days = ref.read(selectedDayOffsetProvider.notifier);
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              key: const Key('previous-day'),
              tooltip: l10n.homePreviousDay,
              icon: const Icon(Icons.chevron_left),
              onPressed: days.previous,
            ),
            Expanded(
              child: Semantics(
                container: true,
                child: Column(
                  children: [
                    Text(
                      location.displayName,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (date != null)
                      Text(
                        key: const Key('home-date'),
                        formatLocalDate(context, date),
                        textAlign: TextAlign.center,
                      ),
                    if (offset == 0)
                      Text(
                        l10n.homeToday,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                  ],
                ),
              ),
            ),
            IconButton(
              key: const Key('next-day'),
              tooltip: l10n.homeNextDay,
              icon: const Icon(Icons.chevron_right),
              onPressed: days.next,
            ),
          ],
        ),
        if (offset != 0)
          TextButton(
            key: const Key('back-to-today'),
            onPressed: days.today,
            child: Text(l10n.homeBackToToday),
          ),
      ],
    );
  }
}

/// The next prayer and the time left, ticking every second.
class NextPrayerCard extends ConsumerWidget {
  const NextPrayerCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final next = ref.watch(nextPrayerProvider);
    final now = ref.watch(nowProvider).value;
    final profile = ref.watch(prayerContextProvider);
    if (next == null || now == null || profile == null) {
      return const SizedBox.shrink();
    }
    final useCase = ref.watch(dayTimesUseCaseProvider);
    final nextDate = useCase.localDateOf(
      next.time,
      profile.location.timeZoneId,
    );
    final jumuah = next.prayer == Prayer.dhuhr && useCase.isFriday(nextDate);
    final name = l10n.prayerName(next.prayer, jumuah: jumuah);
    final remaining = next.remaining(now);
    final locale = Localizations.localeOf(context).toString();
    final spoken = l10n.homeCountdownSemantics(
      name,
      remaining.inHours,
      remaining.inMinutes % 60,
    );
    return Card(
      key: const Key('next-prayer-card'),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(16),
        child: Semantics(
          container: true,
          label: '${l10n.nextPrayerLabel}: $spoken',
          excludeSemantics: true,
          child: Column(
            children: [
              Text(
                l10n.nextPrayerLabel,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              Text(
                name,
                key: const Key('next-prayer-name'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Text(
                formatCountdown(remaining, locale),
                key: const Key('countdown'),
                textDirection: TextDirection.ltr,
                style: Theme.of(context).textTheme.displaySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayList extends ConsumerWidget {
  const _DayList({required this.profile});

  final PrayerContext profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final schedule = ref.watch(selectedScheduleProvider);
    final next = ref.watch(nextPrayerProvider);
    final useCase = ref.watch(dayTimesUseCaseProvider);
    return schedule.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => InfoBanner(
        key: const Key('home-error'),
        icon: Icons.error_outline,
        warning: true,
        message: l10n.homeError,
      ),
      data: (day) {
        if (day == null) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final entry in day.entries)
              _PrayerRow(
                entry: entry,
                isNext: _isNext(entry, next),
                offset: entry.time == null
                    ? Duration.zero
                    : useCase.offsetAt(
                        profile.location.timeZoneId,
                        entry.time!,
                      ),
              ),
            const SizedBox(height: 8),
            _HighLatitudeNotice(day: day, profile: profile),
            TextButton.icon(
              key: const Key('open-detail'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const DetailPage()),
              ),
              icon: const Icon(Icons.more_time),
              label: Text(l10n.homeMoreTimes),
            ),
          ],
        );
      },
    );
  }

  bool _isNext(PrayerEntry entry, NextPrayer? next) =>
      next != null &&
      entry.time != null &&
      entry.prayer == next.prayer &&
      entry.time == next.time;
}

class _PrayerRow extends StatelessWidget {
  const _PrayerRow({
    required this.entry,
    required this.isNext,
    required this.offset,
  });

  final PrayerEntry entry;
  final bool isNext;
  final Duration offset;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final name = l10n.prayerName(entry.prayer, jumuah: entry.isJumuah);
    final time = entry.time == null
        ? l10n.homeTimeNotAvailable
        : formatLocalTime(context, entry.time!, offset);
    final label = entry.time == null
        ? '$name: $time'
        : l10n.homeTimeSemantics(name, time);
    return Semantics(
      container: true,
      label: isNext ? '${l10n.homeNextBadge}: $label' : label,
      excludeSemantics: true,
      child: Container(
        key: Key('row-${entry.prayer.name}'),
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        margin: const EdgeInsetsDirectional.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: isNext ? theme.colorScheme.primaryContainer : null,
          border: Border.all(
            color: isNext
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            width: isNext ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(name, style: theme.textTheme.titleMedium),
                  if (isNext)
                    Text(
                      l10n.homeNextBadge,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(time, style: theme.textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}

/// Explains the high-latitude rule when it applies to this place or day.
class _HighLatitudeNotice extends StatelessWidget {
  const _HighLatitudeNotice({required this.day, required this.profile});

  final DaySchedule day;
  final PrayerContext profile;

  @override
  Widget build(BuildContext context) {
    final applies =
        isHighLatitude(profile.location.latitude) ||
        day.notices.any((n) => n.code == NoticeCode.highLatitudeRuleApplied);
    if (!applies) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return InfoBanner(
      key: const Key('high-latitude-notice'),
      message: l10n.highLatApplied(
        l10n.highLatitudeRuleName(profile.settings.highLatitudeRule),
      ),
    );
  }
}
