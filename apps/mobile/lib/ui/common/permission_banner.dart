import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/providers/setup_providers.dart';
import '../../domain/entities/enums.dart';
import '../../domain/permissions/permission_flow.dart';
import '../../l10n/generated/app_localizations.dart';
import 'info_banner.dart';

/// One message about a refused permission, with the way back to it.
///
/// Nothing is ever blocked by a refusal; this only says what will not work and
/// opens the place where the permission can be changed (FR-011).
class PermissionBanner extends StatelessWidget {
  const PermissionBanner({
    required this.feature,
    required this.onFix,
    super.key,
  });

  final DegradedFeature feature;

  /// Opens the app settings (or the exact-alarm page).
  final VoidCallback onFix;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final message = switch (feature) {
      DegradedFeature.alerts => l10n.permissionBannerAlerts,
      DegradedFeature.exactTiming => l10n.permissionBannerExact,
      DegradedFeature.automaticLocation => l10n.permissionBannerLocation,
    };
    return InfoBanner(
      key: Key('permission-banner-${feature.name}'),
      icon: Icons.notifications_off_outlined,
      warning: true,
      message: message,
      actionLabel: l10n.permissionBannerAction,
      onAction: onFix,
    );
  }
}

/// The permission banners that apply right now, from the states the app last
/// read from the system. Shows nothing when everything is allowed.
class PermissionBanners extends ConsumerWidget {
  const PermissionBanners({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final global = ref.watch(globalAlertSettingsProvider).value;
    final setupComplete = global?.setupCompleted ?? false;
    if (global == null || !setupComplete) return const SizedBox.shrink();
    final isAndroid = ref.watch(isAndroidProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (global.notificationPermissionState == PermissionState.denied)
          PermissionBanner(
            feature: DegradedFeature.alerts,
            onFix: () => ref
                .read(notificationPermissionGatewayProvider)
                .openAppSettings(),
          ),
        if (isAndroid && global.exactAlarmState == PermissionState.denied)
          PermissionBanner(
            feature: DegradedFeature.exactTiming,
            onFix: () => ref.read(exactAlarmGatewayProvider).openSettings(),
          ),
      ],
    );
  }
}
