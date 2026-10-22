import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prayer_engine/prayer_engine.dart';

import '../../app/providers.dart';
import '../../app/providers/qibla_providers.dart';
import '../../domain/entities/settings.dart';
import '../../domain/qibla/direction_text.dart';
import '../../domain/qibla/heading_filter.dart';
import '../../domain/qibla/qibla_alignment.dart';
import '../../l10n/generated/app_localizations.dart';

/// The Qibla screen: a compass arrow when the device has a compass, and the
/// bearing in degrees with plain instructions when it does not.
///
/// The compass sensors run only while this screen is visible: it is the current
/// route, its tab is selected (`TickerMode`) and the app is in the foreground.
class QiblaPage extends ConsumerStatefulWidget {
  const QiblaPage({super.key});

  @override
  ConsumerState<QiblaPage> createState() => _QiblaPageState();
}

class _QiblaPageState extends ConsumerState<QiblaPage>
    with WidgetsBindingObserver {
  bool _foreground = true;
  bool _wantedCompass = false;
  AppLocation? _wantedFor;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final foreground = state == AppLifecycleState.resumed;
    if (foreground != _foreground) setState(() => _foreground = foreground);
  }

  /// Starts or stops the sensors after the current frame (providers must not
  /// change while the widget tree is building).
  void _applyCompassWish(bool want, AppLocation? location) {
    if (want == _wantedCompass && identical(location, _wantedFor)) return;
    _wantedCompass = want;
    _wantedFor = location;
    scheduleMicrotask(() {
      if (!mounted) return;
      final controller = ref.read(compassControllerProvider.notifier);
      if (want && location != null) {
        controller.start(
          latitude: location.latitude,
          longitude: location.longitude,
        );
      } else {
        controller.stop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final location = ref.watch(locationProvider).value;
    final available = ref.watch(compassAvailableProvider);
    final compass = ref.watch(compassControllerProvider);
    final visible = TickerMode.valuesOf(context).enabled && _foreground;

    final atHaram =
        location != null && isAtHaram(location.latitude, location.longitude);
    _applyCompassWish(
      visible && !atHaram && location != null && available.value == true,
      location,
    );

    return Scaffold(
      key: const Key('qibla-page'),
      appBar: AppBar(title: Text(l10n.qiblaTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsetsDirectional.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (location == null)
                _Notice(
                  key: const Key('qibla-no-location'),
                  icon: Icons.location_off_outlined,
                  text: l10n.qiblaNoLocation,
                )
              else if (atHaram)
                _Notice(
                  key: const Key('qibla-at-haram'),
                  icon: Icons.mosque_outlined,
                  text: l10n.qiblaAtHaram,
                  liveRegion: true,
                )
              else
                ..._qiblaContent(context, location, available, compass),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _qiblaContent(
    BuildContext context,
    AppLocation location,
    AsyncValue<bool> available,
    CompassState compass,
  ) {
    final l10n = AppLocalizations.of(context);
    final bearing = qiblaBearing(location.latitude, location.longitude);
    final km =
        (distanceToKaabaMeters(location.latitude, location.longitude) / 1000)
            .round();
    final text = Theme.of(context).textTheme;

    return [
      Semantics(
        header: true,
        child: Text(
          l10n.qiblaBearingFromPlace(
            location.displayName,
            describeDirection(l10n, bearing),
          ),
          key: const Key('qibla-bearing-text'),
          style: text.headlineSmall,
          textAlign: TextAlign.center,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        l10n.qiblaNorthReference,
        style: text.bodyMedium,
        textAlign: TextAlign.center,
      ),
      Text(
        l10n.qiblaDistanceToKaaba(km),
        style: text.bodyMedium,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 16),
      ..._compassSection(context, bearing, available, compass),
    ];
  }

  List<Widget> _compassSection(
    BuildContext context,
    double bearing,
    AsyncValue<bool> available,
    CompassState compass,
  ) {
    final l10n = AppLocalizations.of(context);
    if (available.isLoading) {
      return [_Progress(label: l10n.qiblaStartingCompass)];
    }
    if (available.value != true) {
      return [_NoCompass(message: l10n.qiblaNoCompassTitle)];
    }
    if (compass.status == CompassStatus.failed) {
      return [_NoCompass(message: l10n.qiblaCompassError)];
    }
    final snapshot = compass.snapshot;
    if (snapshot == null) {
      return [_Progress(label: l10n.qiblaStartingCompass)];
    }
    return [_CompassBody(bearing: bearing, snapshot: snapshot)];
  }
}

/// The fallback when there is no usable compass: the bearing above is the
/// answer; this adds a plain explanation of how to use it.
class _NoCompass extends StatelessWidget {
  const _NoCompass({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      key: const Key('qibla-no-compass'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Notice(icon: Icons.explore_off_outlined, text: message),
        const SizedBox(height: 12),
        Text(
          l10n.qiblaNoCompassInstructions,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }
}

/// The arrow, the facing message, the accuracy indicator and the warnings.
class _CompassBody extends StatefulWidget {
  const _CompassBody({required this.bearing, required this.snapshot});

  final double bearing;
  final CompassSnapshot snapshot;

  @override
  State<_CompassBody> createState() => _CompassBodyState();
}

class _CompassBodyState extends State<_CompassBody> {
  late double _relative;

  /// The arrow angle continued across 0/360 so the animation never spins the
  /// long way round.
  late double _unwrapped;
  bool _aligned = false;

  @override
  void initState() {
    super.initState();
    _relative = _computeRelative();
    _unwrapped = _relative;
    _aligned = isAligned(_relative, wasAligned: false);
  }

  @override
  void didUpdateWidget(_CompassBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    _relative = _computeRelative();
    _unwrapped = unwrapAngle(_unwrapped, _relative);
    _aligned = isAligned(_relative, wasAligned: _aligned);
  }

  double _computeRelative() => relativeQiblaAngle(
    bearing: widget.bearing,
    heading: widget.snapshot.headingDegrees,
  );

  String _arrowDescription(AppLocalizations l10n) {
    if (_aligned) return l10n.qiblaFacingQibla;
    final degrees = turnDegrees(_relative);
    return _relative > 0
        ? l10n.qiblaTurnRight(degrees)
        : l10n.qiblaTurnLeft(degrees);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final snapshot = widget.snapshot;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Semantics(
            label: '${l10n.qiblaArrowSemantics}: ${_arrowDescription(l10n)}',
            child: ExcludeSemantics(
              child: _Dial(
                angleRadians: _unwrapped * math.pi / 180,
                aligned: _aligned,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Semantics(
          liveRegion: _aligned,
          child: Text(
            _aligned ? l10n.qiblaFacingQibla : l10n.qiblaTurnHint,
            key: _aligned
                ? const Key('qibla-facing')
                : const Key('qibla-turn-hint'),
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 16),
        _AccuracyIndicator(accuracy: snapshot.accuracy),
        if (snapshot.interference) ...[
          const SizedBox(height: 12),
          _Notice(
            key: const Key('qibla-interference-warning'),
            icon: Icons.warning_amber_rounded,
            text: l10n.qiblaInterferenceWarning,
          ),
        ],
        if (snapshot.needsCalibration) ...[
          const SizedBox(height: 12),
          _Notice(
            key: const Key('qibla-calibration-prompt'),
            icon: Icons.sync,
            text: l10n.qiblaCalibrationPrompt,
          ),
        ],
        if (!snapshot.isTrueNorth) ...[
          const SizedBox(height: 12),
          _Notice(
            key: const Key('qibla-magnetic-note'),
            icon: Icons.info_outline,
            text: l10n.qiblaMagneticNorthNote,
          ),
        ],
      ],
    );
  }
}

/// A fixed marker at the top (the way the phone points) and the Qibla arrow
/// rotating inside it.
class _Dial extends StatelessWidget {
  const _Dial({required this.angleRadians, required this.aligned});

  final double angleRadians;
  final bool aligned;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, 280.0);
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: aligned ? scheme.primary : scheme.outline,
                    // A thicker ring as well as a color change, so the aligned
                    // state is not shown by color alone.
                    width: aligned ? 6 : 2,
                  ),
                ),
                child: const SizedBox.expand(),
              ),
              PositionedDirectional(
                top: 0,
                child: Icon(
                  Icons.arrow_drop_down,
                  size: 32,
                  color: scheme.outline,
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(end: angleRadians),
                duration: const Duration(milliseconds: 150),
                builder: (context, angle, child) => Transform.rotate(
                  key: const Key('qibla-arrow'),
                  angle: angle,
                  child: child,
                ),
                child: Icon(
                  Icons.navigation,
                  size: size * 0.55,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AccuracyIndicator extends StatelessWidget {
  const _AccuracyIndicator({required this.accuracy});

  final CompassAccuracy accuracy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (label, icon) = switch (accuracy) {
      CompassAccuracy.high => (
        l10n.qiblaAccuracyHigh,
        Icons.signal_cellular_alt,
      ),
      CompassAccuracy.medium => (
        l10n.qiblaAccuracyMedium,
        Icons.signal_cellular_alt_2_bar,
      ),
      CompassAccuracy.low => (
        l10n.qiblaAccuracyLow,
        Icons.signal_cellular_alt_1_bar,
      ),
      CompassAccuracy.unreliable => (
        l10n.qiblaAccuracyUnreliable,
        Icons.signal_cellular_connected_no_internet_0_bar,
      ),
    };
    return Semantics(
      container: true,
      child: Row(
        key: const Key('qibla-accuracy'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ExcludeSemantics(child: Icon(icon)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              l10n.qiblaAccuracyLabel(label),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}

/// An icon with a sentence; never color alone.
class _Notice extends StatelessWidget {
  const _Notice({
    super.key,
    required this.icon,
    required this.text,
    this.liveRegion = false,
  });

  final IconData icon;
  final String text;
  final bool liveRegion;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: liveRegion,
      container: true,
      child: Card(
        color: scheme.secondaryContainer,
        child: Padding(
          padding: const EdgeInsetsDirectional.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: Icon(icon, color: scheme.onSecondaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(color: scheme.onSecondaryContainer),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: 24),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
