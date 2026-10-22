import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prayer_engine/prayer_engine.dart' show Prayer;
import 'package:schedule_planner/schedule_planner.dart' as planner;

import '../../app/providers.dart';
import '../../app/providers/alerts_providers.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/settings.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../platform/playback_service.dart';
import 'alert_labels.dart';
import 'alert_settings_page.dart';

/// The two voices that ship at launch (spec Story 3, scenario 2).
const List<String> bundledVoiceIds = ['voice-1', 'voice-2'];

/// Chooses the voice and wording of the full Azaan for one prayer.
///
/// Each voice lists all three recordings, every one with a preview button: the
/// standard version, the Fajr version (which includes "as-salatu khayrun min
/// an-nawm") and the Shia-wording version. The Shia wording is a visible,
/// clearly labelled choice, never hidden.
class VoicePickerPage extends ConsumerStatefulWidget {
  const VoicePickerPage({required this.prayer, super.key});

  final AlertPrayer prayer;

  @override
  ConsumerState<VoicePickerPage> createState() => _VoicePickerPageState();
}

class _VoicePickerPageState extends ConsumerState<VoicePickerPage> {
  /// The recording being previewed, if any.
  String? _playing;

  /// Kept so the page can stop its own preview when it closes, without
  /// creating a player just to do so.
  PlaybackService? _service;

  Future<void> _toggle(String audioRef) async {
    final playback = ref.read(playbackServiceProvider);
    _service = playback;
    if (_playing == audioRef) {
      await playback.stopPreview();
      if (mounted) setState(() => _playing = null);
      return;
    }
    setState(() => _playing = audioRef);
    final ok = await playback.preview(audioRef);
    if (!mounted) return;
    if (!ok) {
      setState(() => _playing = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).alertPreviewFailed),
        ),
      );
    }
  }

  @override
  void dispose() {
    // Do not leave a preview playing after leaving the page.
    if (_playing != null) _service?.stopPreview();
    super.dispose();
  }

  Future<void> _select(
    AlertPreference current,
    String voiceId,
    AzaanVariant variant,
  ) {
    return AlertSettingsPage.save(
      context,
      ref,
      current.copyWith(voiceId: voiceId, variant: variant),
    );
  }

  static String _selection(String voiceId, AzaanVariant variant) =>
      '$voiceId/${variant.name}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final preference = ref
        .watch(alertPreferencesProvider)
        .value
        ?.firstWhere(
          (p) => p.prayer == widget.prayer,
          orElse: () => AlertPreference(prayer: widget.prayer),
        );
    return Scaffold(
      key: const Key('voice-picker-page'),
      appBar: AppBar(title: Text(l10n.alertVoiceTitle)),
      body: SafeArea(
        child: preference == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsetsDirectional.only(bottom: 24),
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      16,
                      16,
                      16,
                      4,
                    ),
                    child: Text(l10n.alertVoiceIntro),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 8),
                    child: Text(
                      l10n.alertVoiceForPrayer(prayerName(l10n, widget.prayer)),
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                  RadioGroup<String>(
                    groupValue: _selection(
                      preference.voiceId,
                      preference.variant,
                    ),
                    onChanged: (value) {
                      if (value == null) return;
                      final parts = value.split('/');
                      _select(
                        preference,
                        parts.first,
                        AzaanVariant.values.byName(parts.last),
                      );
                    },
                    child: Column(
                      children: [
                        for (final voiceId in bundledVoiceIds)
                          _VoiceCard(
                            voiceId: voiceId,
                            playing: _playing,
                            onToggle: _toggle,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _VoiceCard extends StatelessWidget {
  const _VoiceCard({
    required this.voiceId,
    required this.playing,
    required this.onToggle,
  });

  final String voiceId;
  final String? playing;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final standardRef = planner.recordingId(
      voiceId: voiceId,
      variant: planner.PlannerAzaanVariant.standard,
      prayer: Prayer.dhuhr,
    );
    final fajrRef = planner.recordingId(
      voiceId: voiceId,
      variant: planner.PlannerAzaanVariant.standard,
      prayer: Prayer.fajr,
    );
    final shiaRef = planner.recordingId(
      voiceId: voiceId,
      variant: planner.PlannerAzaanVariant.shia,
      prayer: Prayer.dhuhr,
    );
    return Card(
      key: Key('voice-card-$voiceId'),
      margin: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 0),
            child: Semantics(
              header: true,
              child: Text(
                voiceName(l10n, voiceId),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          _RecordingRow(
            rowKey: '$voiceId-standard',
            title: l10n.alertVariantStandard,
            hint: l10n.alertVariantStandardHint,
            audioRef: standardRef,
            playing: playing == standardRef,
            onToggle: onToggle,
            selectionValue: '$voiceId/${AzaanVariant.standard.name}',
          ),
          _RecordingRow(
            rowKey: '$voiceId-fajr',
            title: l10n.alertVariantFajr,
            hint: l10n.alertVariantFajrHint,
            audioRef: fajrRef,
            playing: playing == fajrRef,
            onToggle: onToggle,
          ),
          _RecordingRow(
            rowKey: '$voiceId-shia',
            title: l10n.alertVariantShia,
            hint: l10n.alertVariantShiaHint,
            audioRef: shiaRef,
            playing: playing == shiaRef,
            onToggle: onToggle,
            selectionValue: '$voiceId/${AzaanVariant.shia.name}',
          ),
        ],
      ),
    );
  }
}

/// One recording: a preview button, its name and wording, and, for the two
/// that can be chosen, a radio button.
class _RecordingRow extends StatelessWidget {
  const _RecordingRow({
    required this.rowKey,
    required this.title,
    required this.hint,
    required this.audioRef,
    required this.playing,
    required this.onToggle,
    this.selectionValue,
  });

  final String rowKey;
  final String title;
  final String hint;
  final String audioRef;
  final bool playing;
  final ValueChanged<String> onToggle;

  /// The radio value, or null for a recording that is not chosen directly.
  final String? selectionValue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      key: Key('recording-$rowKey'),
      leading: IconButton(
        key: Key('preview-$rowKey'),
        tooltip: playing ? l10n.alertPreviewStop : l10n.alertPreviewPlay(title),
        icon: Icon(playing ? Icons.stop_circle_outlined : Icons.play_circle),
        onPressed: () => onToggle(audioRef),
      ),
      title: Text(title),
      subtitle: Text(hint),
      trailing: selectionValue == null
          ? null
          : Semantics(
              label: title,
              child: Radio<String>(
                key: Key('select-$rowKey'),
                value: selectionValue!,
              ),
            ),
    );
  }
}
