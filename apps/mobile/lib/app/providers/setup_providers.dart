import 'dart:io' show Platform;
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/permissions/permission_gateways.dart';
import '../../domain/permissions/platform_gateways.dart';
import '../../domain/repositories/city_search_repository.dart';
import '../../domain/resolve_timezone.dart';
import '../../domain/setup/oem_guide.dart';
import '../../domain/setup/profile_service.dart';
import '../../domain/setup/setup_controller.dart';
import '../../domain/setup/setup_state.dart';
import '../../platform/location_service.dart';
import '../providers.dart';

/// Counts how many times something that changes the alert schedule changed:
/// the location, the calculation settings, the language or setup finishing.
///
/// The alerts workstream listens to this (`ref.listen(scheduleInvalidationProvider,
/// ...)`) and rebuilds the schedule. It only ever goes up.
class ScheduleInvalidation extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state = state + 1;
}

final scheduleInvalidationProvider =
    NotifierProvider<ScheduleInvalidation, int>(ScheduleInvalidation.new);

/// True on Android. Overridden in tests.
final isAndroidProvider = Provider<bool>((ref) => Platform.isAndroid);

final notificationPermissionGatewayProvider =
    Provider<NotificationPermissionGateway>(
      (ref) => const PermissionHandlerNotificationGateway(),
    );

final exactAlarmGatewayProvider = Provider<ExactAlarmGateway>(
  (ref) => SchedulerExactAlarmGateway(isAndroid: ref.watch(isAndroidProvider)),
);

final batterySettingsGatewayProvider = Provider<BatterySettingsGateway>(
  (ref) =>
      IntentBatterySettingsGateway(isAndroid: ref.watch(isAndroidProvider)),
);

final locationServiceProvider = Provider<LocationService>(
  (ref) => PigeonLocationService(),
);

final deviceZoneSourceProvider = Provider<DeviceZoneSource>(
  (ref) => const FlutterDeviceZoneSource(),
);

/// The two-letter region the phone is set to (for example `SA`), used only when
/// a position's country cannot be found from its time zone.
final deviceRegionProvider = Provider<String?>(
  (ref) => PlatformDispatcher.instance.locale.countryCode,
);

/// Source of the phone brand for the battery guide. The default cannot detect
/// it, so the user chooses; replace with a native-backed source when one exists.
final deviceBrandSourceProvider = Provider<DeviceBrandSource>(
  (ref) => const NoDeviceBrandSource(),
);

final oemGuideRepositoryProvider = Provider<OemGuideRepository>(
  (ref) => OemGuideRepository(rootBundle),
);

/// The offline city search. Must be overridden by the app with the real
/// implementation (the city-data workstream provides it); tests use a fake.
final citySearchRepositoryProvider = Provider<CitySearchRepository>((ref) {
  throw StateError('citySearchRepositoryProvider must be overridden.');
});

final profileServiceProvider = Provider<ProfileService>(
  (ref) => ProfileService(
    settings: ref.watch(settingsRepositoryProvider),
    locations: ref.watch(locationRepositoryProvider),
    alerts: ref.watch(alertPreferenceRepositoryProvider),
    onChanged: () => ref.read(scheduleInvalidationProvider.notifier).bump(),
  ),
);

/// Whether first-run setup has been finished. Loading until the database has
/// answered, so the shell can wait instead of flashing the setup screens.
final setupCompleteProvider = Provider<AsyncValue<bool>>(
  (ref) => ref
      .watch(globalAlertSettingsProvider)
      .whenData((global) => global.setupCompleted),
);

/// The setup flow's state and actions.
final setupControllerProvider = NotifierProvider<SetupController, SetupState>(
  SetupController.new,
);
