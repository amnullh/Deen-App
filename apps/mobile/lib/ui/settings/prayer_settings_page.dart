import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prayer_engine/prayer_engine.dart';

import '../../app/providers.dart';
import '../../app/providers/setup_providers.dart';
import '../../domain/entities/settings.dart';
import '../../l10n/generated/app_localizations.dart';
import '../common/info_banner.dart';
import '../common/prayer_labels.dart';
import '../common/time_format.dart';
import '../setup/method_page.dart';

/// Calculation method, Asr, high-latitude rule, per-prayer offsets and the Hijri
/// adjustment. Every change is saved at once and reaches every screen and the
/// alert schedule.
class PrayerSettingsPage extends ConsumerWidget {
  const PrayerSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(prayerSettingsProvider).value;
    final location = ref.watch(locationProvider).value;
    final profile = ref.read(profileServiceProvider);
    final theme = Theme.of(context);
    Widget heading(String text) => Padding(
      padding: const EdgeInsetsDirectional.only(top: 16, bottom: 8),
      child: Semantics(
        header: true,
        child: Text(text, style: theme.textTheme.titleLarge),
      ),
    );
    return Scaffold(
      key: const Key('prayer-settings-page'),
      appBar: AppBar(title: Text(l10n.prayerSettingsTitle)),
      body: SafeArea(
        child: settings == null
            ? Padding(
                padding: const EdgeInsetsDirectional.all(16),
                child: Text(l10n.prayerSettingsNoLocation),
              )
            : SingleChildScrollView(
                padding: const EdgeInsetsDirectional.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    heading(l10n.setupMethodTitle),
                    MethodPicker(
                      selected: settings.method,
                      onSelected: (method) => profile.updateSettings(
                        (s) => s.copyWith(method: method),
                      ),
                    ),
                    heading(l10n.setupAsrTitle),
                    AsrPicker(
                      selected: settings.asrMethod,
                      onSelected: (asr) => profile.updateSettings(
                        (s) => s.copyWith(asrMethod: asr),
                      ),
                    ),
                    heading(l10n.prayerSettingsHighLatTitle),
                    Text(l10n.prayerSettingsHighLatIntro),
                    const SizedBox(height: 8),
                    _HighLatitudePicker(
                      selected: settings.highLatitudeRule,
                      onSelected: (rule) => profile.updateSettings(
                        (s) => s.copyWith(highLatitudeRule: rule),
                      ),
                    ),
                    if (location != null && isHighLatitude(location.latitude))
                      InfoBanner(
                        key: const Key('settings-high-latitude-notice'),
                        message: l10n.highLatApplied(
                          l10n.highLatitudeRuleName(settings.highLatitudeRule),
                        ),
                      ),
                    heading(l10n.prayerSettingsOffsetsTitle),
                    Text(l10n.prayerSettingsOffsetsIntro),
                    for (final prayer in Prayer.values)
                      _OffsetRow(
                        key: Key('offset-${prayer.name}'),
                        prayer: prayer,
                        minutes: settings.offsetsMinutes[prayer] ?? 0,
                        onChanged: (change) => profile.updateSettings(
                          (s) => s.copyWith(
                            offsetsMinutes: {
                              ...s.offsetsMinutes,
                              prayer: change(s.offsetsMinutes[prayer] ?? 0),
                            },
                          ),
                        ),
                      ),
                    heading(l10n.prayerSettingsHijriTitle),
                    _HijriRow(
                      days: settings.hijriAdjustment,
                      onChanged: (delta) => profile.updateSettings(
                        (s) => s.copyWith(
                          hijriAdjustment: (s.hijriAdjustment + delta).clamp(
                            PrayerSettings.minHijriAdjustment,
                            PrayerSettings.maxHijriAdjustment,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _HighLatitudePicker extends StatelessWidget {
  const _HighLatitudePicker({required this.selected, required this.onSelected});

  final HighLatitudeRule selected;
  final ValueChanged<HighLatitudeRule> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return RadioGroup<HighLatitudeRule>(
      groupValue: selected,
      onChanged: (value) {
        if (value != null) onSelected(value);
      },
      child: Column(
        children: [
          for (final rule in HighLatitudeRule.values)
            RadioListTile<HighLatitudeRule>(
              key: Key('high-lat-${rule.name}'),
              value: rule,
              title: Text(l10n.highLatitudeRuleName(rule)),
              subtitle: Text(l10n.highLatitudeRuleDescription(rule)),
            ),
        ],
      ),
    );
  }
}

/// A prayer's offset: minus and plus buttons for single minutes and a slider for
/// larger moves. The slider saves when released, not on every drag step.
class _OffsetRow extends StatefulWidget {
  const _OffsetRow({
    required this.prayer,
    required this.minutes,
    required this.onChanged,
    super.key,
  });

  final Prayer prayer;
  final int minutes;

  /// Called with a function from the saved minutes to the new minutes, so a
  /// step is applied to the latest saved value.
  final void Function(int Function(int current) change) onChanged;

  @override
  State<_OffsetRow> createState() => _OffsetRowState();
}

class _OffsetRowState extends State<_OffsetRow> {
  double? _dragging;

  int get _shown => (_dragging ?? widget.minutes.toDouble()).round();

  void _step(int delta) => widget.onChanged(
    (current) => (current + delta).clamp(
      PrayerSettings.minOffset,
      PrayerSettings.maxOffset,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final name = l10n.prayerName(widget.prayer);
    final value = l10n.prayerSettingsOffsetValue(formatSigned(_shown, locale));
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                key: Key('offset-less-${widget.prayer.name}'),
                tooltip: l10n.prayerSettingsOffsetLess(name),
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: widget.minutes > PrayerSettings.minOffset
                    ? () => _step(-1)
                    : null,
              ),
              Text(value),
              IconButton(
                key: Key('offset-more-${widget.prayer.name}'),
                tooltip: l10n.prayerSettingsOffsetMore(name),
                icon: const Icon(Icons.add_circle_outline),
                onPressed: widget.minutes < PrayerSettings.maxOffset
                    ? () => _step(1)
                    : null,
              ),
            ],
          ),
          Slider(
            key: Key('offset-slider-${widget.prayer.name}'),
            min: PrayerSettings.minOffset.toDouble(),
            max: PrayerSettings.maxOffset.toDouble(),
            divisions: PrayerSettings.maxOffset - PrayerSettings.minOffset,
            value: (_dragging ?? widget.minutes.toDouble()),
            label: value,
            semanticFormatterCallback: (_) => value,
            onChanged: (v) => setState(() => _dragging = v),
            onChangeEnd: (v) {
              setState(() => _dragging = null);
              widget.onChanged((_) => v.round());
            },
          ),
        ],
      ),
    );
  }
}

class _HijriRow extends StatelessWidget {
  const _HijriRow({required this.days, required this.onChanged});

  final int days;

  /// Called with +1 or -1.
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          key: const Key('hijri-less'),
          tooltip: l10n.prayerSettingsHijriLess,
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: days > PrayerSettings.minHijriAdjustment
              ? () => onChanged(-1)
              : null,
        ),
        Flexible(
          child: Text(
            key: const Key('hijri-value'),
            l10n.prayerSettingsHijriValue(formatSigned(days, locale)),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        IconButton(
          key: const Key('hijri-more'),
          tooltip: l10n.prayerSettingsHijriMore,
          icon: const Icon(Icons.add_circle_outline),
          onPressed: days < PrayerSettings.maxHijriAdjustment
              ? () => onChanged(1)
              : null,
        ),
      ],
    );
  }
}
