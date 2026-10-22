import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/lifecycle_observer.dart';
import '../app/providers/setup_providers.dart';
import '../l10n/generated/app_localizations.dart';
import 'about/about_page.dart';
import 'adhkar/collections_page.dart';
import 'alerts/alert_settings_page.dart';
import 'alerts/alerts_runtime.dart';
import 'home/home_page.dart';
import 'qibla/qibla_page.dart';
import 'reliability/reliability_page.dart';
import 'settings/appearance_page.dart';
import 'settings/data_page.dart';
import 'setup/setup_flow.dart';
import 'tasbih/tasbih_page.dart';

/// The root of the app. First-run setup is shown until it has been finished;
/// after that the home screen, with the Reliability check one tap away
/// (FR-004) and every other feature in the menu.
class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setupComplete = ref.watch(setupCompleteProvider);
    return setupComplete.when(
      loading: () => const _Loading(),
      // The database could not be read; setup is the safe place to land, and it
      // rewrites the settings.
      error: (_, _) => const SetupFlow(),
      data: (complete) => complete ? const _MainShell() : const SetupFlow(),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    final label = AppLocalizations.of(context).loading;
    return Scaffold(
      body: Center(
        child: Semantics(
          label: label,
          child: const CircularProgressIndicator(),
        ),
      ),
    );
  }
}

/// The signed-in-equivalent part of the app: alerts keep running and the clock
/// and time zone are watched for as long as it is shown.
class _MainShell extends StatelessWidget {
  const _MainShell();

  @override
  Widget build(BuildContext context) {
    return const AlertsRuntime(
      child: LifecycleObserver(
        child: HomePage(extraActions: [_ReliabilityButton(), _MoreMenu()]),
      ),
    );
  }
}

class _ReliabilityButton extends StatelessWidget {
  const _ReliabilityButton();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return IconButton(
      key: const Key('reliability-entry'),
      tooltip: l10n.reliabilityCheckTitle,
      icon: const Icon(Icons.verified_outlined),
      onPressed: () => _open(context, const ReliabilityPage()),
    );
  }
}

enum _Destination { qibla, tasbih, adhkar, alerts, appearance, data, about }

class _MoreMenu extends StatelessWidget {
  const _MoreMenu();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    String label(_Destination d) => switch (d) {
      _Destination.qibla => l10n.qiblaTitle,
      _Destination.tasbih => l10n.tasbihTitle,
      _Destination.adhkar => l10n.adhkarTitle,
      _Destination.alerts => l10n.alertSettingsTitle,
      _Destination.appearance => l10n.settingsAppearanceTitle,
      _Destination.data => l10n.settingsDataTitle,
      _Destination.about => l10n.aboutTitle,
    };
    Widget page(_Destination d) => switch (d) {
      _Destination.qibla => const QiblaPage(),
      _Destination.tasbih => const TasbihPage(),
      _Destination.adhkar => const AdhkarCollectionsPage(),
      _Destination.alerts => const AlertSettingsPage(),
      _Destination.appearance => const AppearancePage(),
      _Destination.data => const DataPage(),
      _Destination.about => const AboutPage(),
    };
    return PopupMenuButton<_Destination>(
      key: const Key('more-menu'),
      tooltip: l10n.settingsTitle,
      onSelected: (destination) => _open(context, page(destination)),
      itemBuilder: (context) => [
        for (final destination in _Destination.values)
          PopupMenuItem<_Destination>(
            key: Key('menu-${destination.name}'),
            value: destination,
            child: Text(label(destination)),
          ),
      ],
    );
  }
}

void _open(BuildContext context, Widget page) {
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
}
