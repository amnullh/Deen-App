import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/providers/prayer_providers.dart';
import '../../domain/prayer/day_times_usecase.dart';
import '../../l10n/generated/app_localizations.dart';
import '../common/prayer_labels.dart';
import '../common/time_format.dart';

/// The extra times for the day on screen: Imsak, midnight, the last third of the
/// night, and the Hijri date. It follows the day chosen on the home screen.
class DetailPage extends ConsumerWidget {
  const DetailPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final schedule = ref.watch(selectedScheduleProvider).value;
    final location = ref.watch(locationProvider).value;
    final settings = ref.watch(prayerSettingsProvider).value;
    final useCase = ref.watch(dayTimesUseCaseProvider);
    return Scaffold(
      key: const Key('detail-page'),
      appBar: AppBar(title: Text(l10n.homeMoreTimes)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsetsDirectional.all(16),
          children: [
            if (schedule == null || location == null || settings == null)
              Text(l10n.homeNoLocation)
            else ...[
              Text(
                formatLocalDate(context, schedule.localDate),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _TimeRow(
                label: l10n.detailImsak,
                time: schedule.imsak,
                zone: location.timeZoneId,
                useCase: useCase,
              ),
              _TimeRow(
                label: l10n.detailMidnight,
                time: schedule.midnight,
                zone: location.timeZoneId,
                useCase: useCase,
              ),
              _TimeRow(
                label: l10n.detailLastThird,
                time: schedule.lastThirdOfNight,
                zone: location.timeZoneId,
                useCase: useCase,
              ),
              const Divider(height: 32),
              _HijriBlock(
                schedule: schedule,
                adjustment: settings.hijriAdjustment,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.label,
    required this.time,
    required this.zone,
    required this.useCase,
  });

  final String label;
  final DateTime? time;
  final String zone;
  final DayTimesUseCase useCase;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = time == null
        ? l10n.homeTimeNotAvailable
        : formatLocalTime(context, time!, useCase.offsetAt(zone, time!));
    final style = Theme.of(context).textTheme.titleMedium;
    return Semantics(
      container: true,
      label: time == null
          ? '$label: $text'
          : l10n.homeTimeSemantics(label, text),
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsetsDirectional.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(child: Text(label, style: style)),
            const SizedBox(width: 8),
            Text(text, style: style),
          ],
        ),
      ),
    );
  }
}

class _HijriBlock extends StatelessWidget {
  const _HijriBlock({required this.schedule, required this.adjustment});

  final DaySchedule schedule;
  final int adjustment;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final hijri = schedule.hijri;
    final locale = Localizations.localeOf(context).toString();
    return Semantics(
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              l10n.detailHijriTitle,
              style: theme.textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 8),
          if (hijri == null)
            Text(l10n.detailHijriUnavailable)
          else ...[
            Text(
              key: const Key('hijri-date'),
              l10n.detailHijriValue(
                formatPlain(hijri.day, locale),
                l10n.hijriMonthName(hijri.month),
                formatPlain(hijri.year, locale),
              ),
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              adjustment == 0
                  ? l10n.detailHijriDefault
                  : l10n.detailHijriAdjusted(formatSigned(adjustment, locale)),
            ),
          ],
        ],
      ),
    );
  }
}
