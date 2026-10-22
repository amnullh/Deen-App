import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/setup_providers.dart';
import '../../domain/entities/city.dart';
import '../../domain/entities/settings.dart';
import '../../domain/setup/setup_state.dart';
import '../../l10n/generated/app_localizations.dart';
import 'setup_widgets.dart';

/// The location choices: precise, approximate, or a city from the offline list.
/// Shared by setup and the location settings page, which supply the actions.
class LocationChooser extends ConsumerStatefulWidget {
  const LocationChooser({
    required this.current,
    required this.busy,
    required this.problem,
    required this.onUsePrecise,
    required this.onUseApproximate,
    required this.onCityChosen,
    required this.onOpenSettings,
    super.key,
  });

  final AppLocation? current;
  final bool busy;
  final SetupProblem? problem;
  final VoidCallback onUsePrecise;
  final VoidCallback onUseApproximate;
  final ValueChanged<CityRecord> onCityChosen;

  /// Opens the app settings, offered when location was refused.
  final VoidCallback onOpenSettings;

  @override
  ConsumerState<LocationChooser> createState() => _LocationChooserState();
}

class _LocationChooserState extends ConsumerState<LocationChooser> {
  final TextEditingController _query = TextEditingController();
  List<CityRecord> _results = const [];
  bool _searched = false;

  /// Guards against an older, slower search replacing a newer one.
  int _searchId = 0;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _search(String text) async {
    final id = ++_searchId;
    if (text.trim().isEmpty) {
      setState(() {
        _results = const [];
        _searched = false;
      });
      return;
    }
    final found = await ref.read(citySearchRepositoryProvider).search(text);
    if (!mounted || id != _searchId) return;
    setState(() {
      _results = found;
      _searched = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final current = widget.current;
    final problem = widget.problem;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StatusLine(ok: true, message: l10n.setupLocationPrivacy),
        const SizedBox(height: 8),
        FilledButton.icon(
          key: const Key('location-precise'),
          onPressed: widget.busy ? null : widget.onUsePrecise,
          icon: const Icon(Icons.my_location),
          label: Text(l10n.setupLocationPrecise),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: const Key('location-approximate'),
          onPressed: widget.busy ? null : widget.onUseApproximate,
          icon: const Icon(Icons.location_searching),
          label: Text(l10n.setupLocationApproximate),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.only(top: 4),
          child: Text(
            l10n.setupLocationApproximateHint,
            style: theme.textTheme.bodySmall,
          ),
        ),
        if (widget.busy)
          Semantics(
            liveRegion: true,
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(vertical: 12),
              child: Row(
                children: [
                  const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(l10n.setupLocationFinding)),
                ],
              ),
            ),
          ),
        if (problem != null) ...[
          StatusLine(ok: false, message: setupProblemMessage(l10n, problem)),
          if (problem == SetupProblem.locationDenied)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                key: const Key('location-open-settings'),
                onPressed: widget.onOpenSettings,
                child: Text(l10n.setupOpenAppSettings),
              ),
            ),
        ],
        const SizedBox(height: 16),
        TextField(
          key: const Key('city-search'),
          controller: _query,
          onChanged: _search,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            labelText: l10n.setupLocationSearchLabel,
            hintText: l10n.setupLocationSearchHint,
            prefixIcon: const Icon(Icons.search),
            border: const OutlineInputBorder(),
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.only(top: 4),
          child: Text(
            l10n.setupLocationOfflineNote,
            style: theme.textTheme.bodySmall,
          ),
        ),
        if (_searched && _results.isEmpty)
          StatusLine(ok: false, message: l10n.setupLocationSearchEmpty),
        for (final city in _results)
          ListTile(
            key: Key('city-${city.geonameId}'),
            title: Text(city.name),
            subtitle: Text(
              city.matchedName == null
                  ? city.countryCode
                  : '${city.matchedName} · ${city.countryCode}',
            ),
            onTap: widget.busy
                ? null
                : () {
                    FocusScope.of(context).unfocus();
                    widget.onCityChosen(city);
                  },
          ),
        if (current != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 16),
            child: Semantics(
              liveRegion: true,
              child: StatusLine(
                ok: true,
                message: l10n.setupLocationSelected(current.displayName),
              ),
            ),
          ),
      ],
    );
  }
}

/// Setup step 2: where the user is.
class LocationStep extends ConsumerWidget {
  const LocationStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(setupControllerProvider);
    final controller = ref.read(setupControllerProvider.notifier);
    return SetupStepLayout(
      title: l10n.setupLocationTitle,
      children: [
        LocationChooser(
          current: state.location,
          busy: state.busy,
          problem: state.problem,
          onUsePrecise: () => controller.useDeviceLocation(
            approximate: false,
            displayName: l10n.setupLocationCurrentName,
          ),
          onUseApproximate: () => controller.useDeviceLocation(
            approximate: true,
            displayName: l10n.setupLocationApproximateName,
          ),
          onCityChosen: controller.chooseCity,
          onOpenSettings: controller.openLocationSettings,
        ),
        if (state.location == null)
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 16),
            child: Text(l10n.setupLocationNeeded),
          ),
      ],
    );
  }
}
