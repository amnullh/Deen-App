import 'package:prayer_engine/prayer_engine.dart';

import '../entities/enums.dart';
import '../entities/settings.dart';
import '../permissions/permission_flow.dart';
import '../permissions/permission_gateways.dart';

/// The setup screens in order. The Android-only steps are skipped elsewhere.
enum SetupStep {
  language,
  location,
  method,
  notifications,
  exactAlarm,
  battery,
  privacy;

  /// The steps shown on a platform.
  static List<SetupStep> forPlatform({required bool isAndroid}) => [
    for (final step in SetupStep.values)
      if (isAndroid || (step != exactAlarm && step != battery)) step,
  ];
}

/// A problem the setup screens explain in plain words next to the control.
enum SetupProblem {
  locationDenied,
  locationTimeout,
  locationUnavailable,
  zoneUnknown,
  saveFailed,
}

class SetupState {
  const SetupState({
    this.step = SetupStep.language,
    this.language = AppLanguage.en,
    this.location,
    this.method,
    this.asr = AsrMethod.standard,
    this.methodChosenByUser = false,
    this.notifications,
    this.exactAlarm,
    this.locationRefused = false,
    this.busy = false,
    this.problem,
    this.isAndroid = false,
  });

  final SetupStep step;
  final AppLanguage language;
  final AppLocation? location;

  /// The calculation method in use. Null until a location is chosen.
  final CalculationMethod? method;
  final AsrMethod asr;

  /// False while [method] is only the region's suggestion.
  final bool methodChosenByUser;
  final PermissionOutcome? notifications;
  final PermissionOutcome? exactAlarm;

  /// True once the user refused (or the system refused) device location.
  final bool locationRefused;

  /// True while a platform call is running.
  final bool busy;
  final SetupProblem? problem;
  final bool isAndroid;

  List<SetupStep> get steps => SetupStep.forPlatform(isAndroid: isAndroid);
  int get stepNumber => steps.indexOf(step) + 1;
  bool get isLast => step == steps.last;

  /// What will not work, given the answers so far.
  PermissionReport get report => PermissionReport(
    notifications: notifications,
    exactAlarm: exactAlarm,
    exactAlarmApplicable: isAndroid,
    locationRefused: locationRefused,
  );

  /// Whether the Next button is enabled on the current step. Only the location
  /// step can block, because without a place there are no times to show.
  bool get canContinue => step != SetupStep.location || location != null;

  SetupState copyWith({
    SetupStep? step,
    AppLanguage? language,
    AppLocation? location,
    CalculationMethod? method,
    AsrMethod? asr,
    bool? methodChosenByUser,
    PermissionOutcome? notifications,
    PermissionOutcome? exactAlarm,
    bool? locationRefused,
    bool? busy,
    SetupProblem? problem,
    bool clearProblem = false,
    bool? isAndroid,
  }) {
    return SetupState(
      step: step ?? this.step,
      language: language ?? this.language,
      location: location ?? this.location,
      method: method ?? this.method,
      asr: asr ?? this.asr,
      methodChosenByUser: methodChosenByUser ?? this.methodChosenByUser,
      notifications: notifications ?? this.notifications,
      exactAlarm: exactAlarm ?? this.exactAlarm,
      locationRefused: locationRefused ?? this.locationRefused,
      busy: busy ?? this.busy,
      problem: clearProblem ? null : (problem ?? this.problem),
      isAndroid: isAndroid ?? this.isAndroid,
    );
  }
}
