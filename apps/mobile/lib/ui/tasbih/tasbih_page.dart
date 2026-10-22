import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/tasbih_providers.dart';
import '../../domain/tasbih/tasbih_controller.dart';
import '../../domain/tasbih/tasbih_state.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../platform/volume_key_service.dart';
import 'device_services.dart';

/// The Tasbih counter: a large tap target with haptic feedback, targets,
/// daily history, reset with confirmation, keep-awake, volume-key counting
/// (Android) and a tap lock.
///
/// Keep-awake and volume-key interception are active only while this screen is
/// visible: it is the current route, its tab is selected (`TickerMode`) and the
/// app is in the foreground.
class TasbihPage extends ConsumerStatefulWidget {
  const TasbihPage({super.key});

  @override
  ConsumerState<TasbihPage> createState() => _TasbihPageState();
}

class _TasbihPageState extends ConsumerState<TasbihPage>
    with WidgetsBindingObserver {
  late final KeepAwakeService _keepAwake;
  late final VolumeKeyService _volumeKeys;
  StreamSubscription<VolumeKey>? _presses;

  bool _foreground = true;
  bool _awakeWished = false;
  bool _volumeWished = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Read once: `ref` must not be used while the state is being disposed.
    _keepAwake = ref.read(keepAwakeServiceProvider);
    _volumeKeys = ref.read(volumeKeyServiceProvider);
    _presses = _volumeKeys.presses.listen((_) => _count(TapSource.volumeKey));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_presses?.cancel());
    // Leave the device as the app found it.
    unawaited(_keepAwake.setEnabled(false));
    unawaited(_volumeKeys.setEnabled(false));
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final foreground = state == AppLifecycleState.resumed;
    if (foreground != _foreground) setState(() => _foreground = foreground);
  }

  /// Switches the wake lock and the volume keys to match the options and the
  /// visibility, after the current frame.
  void _applyDeviceWishes(TasbihState state, {required bool visible}) {
    final awake = visible && state.keepAwake;
    final volume = visible && state.volumeKeys && _volumeKeys.isSupported;
    if (awake != _awakeWished) {
      _awakeWished = awake;
      scheduleMicrotask(() => _keepAwake.setEnabled(awake));
    }
    if (volume != _volumeWished) {
      _volumeWished = volume;
      scheduleMicrotask(() => _volumeKeys.setEnabled(volume));
    }
  }

  Future<void> _count(TapSource source) async {
    final state = ref.read(tasbihStateProvider).value;
    if (state == null) return;
    if (state.lock && source == TapSource.touch) return;

    // Feedback first, so it is instant; saving follows.
    if (state.haptics) unawaited(HapticFeedback.lightImpact());
    if (state.sound) unawaited(ref.read(tickPlayerProvider).play());

    try {
      final outcome = await ref
          .read(tasbihControllerProvider)
          .tap(source: source);
      if (!mounted || !outcome.roundCompleted) return;
      if (state.haptics) unawaited(HapticFeedback.heavyImpact());
      final target =
          ref.read(tasbihStateProvider).value?.target ?? state.target;
      unawaited(
        SemanticsService.sendAnnouncement(
          View.of(context),
          AppLocalizations.of(context).tasbihTargetReached(target),
          Directionality.of(context),
        ),
      );
    } on Object {
      _showMessage(AppLocalizations.of(context).tasbihSaveError);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final stateValue = ref.watch(tasbihStateProvider);
    final visible = TickerMode.valuesOf(context).enabled && _foreground;
    final state = stateValue.value;
    if (state != null) _applyDeviceWishes(state, visible: visible);

    return Scaffold(
      key: const Key('tasbih-page'),
      appBar: AppBar(title: Text(l10n.tasbihTitle)),
      body: SafeArea(
        child: state == null
            ? Center(
                child: stateValue.hasError
                    ? Text(l10n.tasbihSaveError)
                    : const CircularProgressIndicator(),
              )
            : SingleChildScrollView(
                padding: const EdgeInsetsDirectional.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Counter(
                      state: state,
                      onTap: () => _count(TapSource.touch),
                    ),
                    const SizedBox(height: 12),
                    _Summary(state: state),
                    if (state.lock) ...[
                      const SizedBox(height: 12),
                      _UnlockButton(
                        onShortPress: () =>
                            _showMessage(l10n.tasbihUnlockPressHint),
                        onUnlock: () =>
                            ref.read(tasbihControllerProvider).setLock(false),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _TargetPicker(state: state),
                    const SizedBox(height: 8),
                    const _ResetButton(),
                    const Divider(height: 32),
                    _Options(
                      state: state,
                      volumeSupported: _volumeKeys.isSupported,
                    ),
                    const Divider(height: 32),
                    const _History(),
                  ],
                ),
              ),
      ),
    );
  }
}

/// The big round tap target with the count and progress ring.
class _Counter extends StatelessWidget {
  const _Counter({required this.state, required this.onTap});

  final TasbihState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, 320.0);
        return Center(
          child: Semantics(
            key: const Key('tasbih-counter'),
            button: true,
            enabled: !state.lock,
            label: state.lock
                ? '${l10n.tasbihCountLabel(state.count, state.target)}. ${l10n.tasbihLockedMessage}'
                : l10n.tasbihCountLabel(state.count, state.target),
            hint: state.lock ? null : l10n.tasbihCountHint,
            onTap: state.lock ? null : onTap,
            excludeSemantics: true,
            child: SizedBox(
              width: size,
              height: size,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: state.progress,
                    strokeWidth: 10,
                    backgroundColor: scheme.surfaceContainerHighest,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Material(
                      color: scheme.primaryContainer,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: state.lock ? null : onTap,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (state.lock)
                                  Icon(
                                    Icons.lock_outline,
                                    color: scheme.onPrimaryContainer,
                                  ),
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      '${state.count}',
                                      key: const Key('tasbih-count'),
                                      style: theme.textTheme.displayLarge
                                          ?.copyWith(
                                            color: scheme.onPrimaryContainer,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                ),
                                Text(
                                  l10n.tasbihOfTarget(state.target),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: scheme.onPrimaryContainer,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Rounds finished and today's total.
class _Summary extends ConsumerWidget {
  const _Summary({required this.state});

  final TasbihState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final style = Theme.of(context).textTheme.titleMedium;
    final today = ref.watch(tasbihTodayTotalProvider);
    return Column(
      children: [
        if (state.roundsCompleted > 0)
          Text(
            l10n.tasbihRounds(state.roundsCompleted),
            style: style,
            textAlign: TextAlign.center,
          ),
        Text(
          l10n.tasbihTodayTotal(today),
          style: style,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _UnlockButton extends StatelessWidget {
  const _UnlockButton({required this.onShortPress, required this.onUnlock});

  final VoidCallback onShortPress;
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.tasbihLockedMessage,
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          key: const Key('tasbih-unlock'),
          // A short press must not unlock: that is the stray touch the lock
          // is there to absorb.
          onPressed: onShortPress,
          onLongPress: onUnlock,
          icon: const Icon(Icons.lock_open),
          label: Text(l10n.tasbihUnlock),
        ),
      ],
    );
  }
}

class _TargetPicker extends ConsumerWidget {
  const _TargetPicker({required this.state});

  final TasbihState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(tasbihControllerProvider);

    Widget preset(int target) {
      return Semantics(
        label: l10n.tasbihTargetOptionLabel(target),
        button: true,
        selected: state.target == target,
        excludeSemantics: true,
        onTap: () => controller.setTarget(target),
        child: ChoiceChip(
          key: Key('tasbih-target-$target'),
          label: Text('$target'),
          selected: state.target == target,
          onSelected: (_) => controller.setTarget(target),
        ),
      );
    }

    final customSelected = !state.isPresetTarget;
    final customLabel = customSelected
        ? '${l10n.tasbihTargetCustom}: ${state.target}'
        : l10n.tasbihTargetCustom;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            l10n.tasbihTargetHeading,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final target in TasbihState.presetTargets) preset(target),
            Semantics(
              label: customSelected
                  ? l10n.tasbihTargetCustomLabel(state.target)
                  : l10n.tasbihTargetCustom,
              button: true,
              selected: customSelected,
              excludeSemantics: true,
              onTap: () => _askCustomTarget(context, controller, state.target),
              child: ChoiceChip(
                key: const Key('tasbih-target-custom'),
                label: Text(customLabel),
                selected: customSelected,
                onSelected: (_) =>
                    _askCustomTarget(context, controller, state.target),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _askCustomTarget(
    BuildContext context,
    TasbihController controller,
    int current,
  ) async {
    final target = await showDialog<int>(
      context: context,
      builder: (context) => _CustomTargetDialog(initial: current),
    );
    if (target != null) await controller.setTarget(target);
  }
}

/// Asks for a whole number from 1 to 100000 and keeps asking until it gets one.
class _CustomTargetDialog extends StatefulWidget {
  const _CustomTargetDialog({required this.initial});

  final int initial;

  @override
  State<_CustomTargetDialog> createState() => _CustomTargetDialogState();
}

class _CustomTargetDialogState extends State<_CustomTargetDialog> {
  late final TextEditingController _field = TextEditingController(
    text: TasbihState.presetTargets.contains(widget.initial)
        ? ''
        : '${widget.initial}',
  );
  bool _invalid = false;

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  void _save() {
    final value = int.tryParse(_field.text.trim());
    if (value == null || !TasbihState.isValidTarget(value)) {
      setState(() => _invalid = true);
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.tasbihTargetCustomTitle),
      content: TextField(
        key: const Key('tasbih-custom-field'),
        controller: _field,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          labelText: l10n.tasbihTargetCustomField,
          errorText: _invalid ? l10n.tasbihTargetInvalid : null,
        ),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.tasbihCancel),
        ),
        FilledButton(onPressed: _save, child: Text(l10n.tasbihSave)),
      ],
    );
  }
}

class _ResetButton extends ConsumerWidget {
  const _ResetButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: OutlinedButton.icon(
        key: const Key('tasbih-reset'),
        onPressed: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(l10n.tasbihResetTitle),
              content: Text(l10n.tasbihResetBody),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(l10n.tasbihCancel),
                ),
                FilledButton(
                  key: const Key('tasbih-reset-confirm'),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(l10n.tasbihReset),
                ),
              ],
            ),
          );
          await ref
              .read(tasbihControllerProvider)
              .reset(confirmed: confirmed ?? false);
        },
        icon: const Icon(Icons.restart_alt),
        label: Text(l10n.tasbihReset),
      ),
    );
  }
}

class _Options extends ConsumerWidget {
  const _Options({required this.state, required this.volumeSupported});

  final TasbihState state;
  final bool volumeSupported;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(tasbihControllerProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            l10n.tasbihOptionsTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        SwitchListTile(
          key: const Key('tasbih-haptics-switch'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.tasbihHaptics),
          value: state.haptics,
          onChanged: controller.setHaptics,
        ),
        SwitchListTile(
          key: const Key('tasbih-sound-switch'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.tasbihSound),
          value: state.sound,
          onChanged: controller.setSound,
        ),
        SwitchListTile(
          key: const Key('tasbih-awake-switch'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.tasbihKeepAwake),
          value: state.keepAwake,
          onChanged: controller.setKeepAwake,
        ),
        if (volumeSupported)
          SwitchListTile(
            key: const Key('tasbih-volume-switch'),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.tasbihVolumeKeys),
            subtitle: Text(l10n.tasbihVolumeKeysHint),
            value: state.volumeKeys,
            onChanged: controller.setVolumeKeys,
          ),
        SwitchListTile(
          key: const Key('tasbih-lock-switch'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.tasbihLock),
          subtitle: Text(l10n.tasbihLockHint),
          value: state.lock,
          onChanged: controller.setLock,
        ),
      ],
    );
  }
}

class _History extends ConsumerWidget {
  const _History();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final days = ref.watch(tasbihDaysProvider).value ?? const <TasbihDay>[];
    final dates = MaterialLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            l10n.tasbihHistoryTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        if (days.isEmpty)
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 8),
            child: Text(l10n.tasbihHistoryEmpty),
          )
        else
          for (final day in days)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(dates.formatMediumDate(DateTime.parse(day.date))),
              trailing: Text(
                '${day.total}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
      ],
    );
  }
}
