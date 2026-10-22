import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/providers/setup_providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../setup/location_page.dart';

/// Change the location after setup, with the same choices as in setup. The
/// chosen method is kept; the home screen offers the region's method once.
class LocationSettingsPage extends ConsumerStatefulWidget {
  const LocationSettingsPage({super.key});

  @override
  ConsumerState<LocationSettingsPage> createState() =>
      _LocationSettingsPageState();
}

class _LocationSettingsPageState extends ConsumerState<LocationSettingsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(setupControllerProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(setupControllerProvider);
    final controller = ref.read(setupControllerProvider.notifier);
    final saved = ref.watch(locationProvider).value;
    ref.listen(locationProvider, (previous, next) {
      final changed = next.value != null && previous?.value != next.value;
      if (changed && previous?.value != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.locationSettingsSaved)));
      }
    });
    return Scaffold(
      key: const Key('location-settings-page'),
      appBar: AppBar(title: Text(l10n.locationSettingsTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsetsDirectional.all(16),
          children: [
            Text(
              saved == null
                  ? l10n.locationSettingsNone
                  : l10n.locationSettingsCurrent(saved.displayName),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            LocationChooser(
              current: null,
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
          ],
        ),
      ),
    );
  }
}
