import 'dart:ui' show Locale;

import 'package:prayer_engine/prayer_engine.dart';
import 'package:schedule_planner/schedule_planner.dart' as planner;

import '../../l10n/generated/app_localizations.dart';
import '../../platform/alert_scheduler.dart';
import '../adhkar/adhkar_reminder.dart';
import '../entities/enums.dart';
import '../entities/settings.dart';
import '../prayer/hijri_source.dart';
import 'alert_log_entry.dart';
import 'schedule_plan.dart';

/// [PlanBuilder] over the pure-Dart `schedule_planner` package: maps the app's
/// settings to the planner's input, and its output to localized platform alerts.
class PlannerPlanBuilder implements PlanBuilder {
  PlannerPlanBuilder({required this.engine, required this.offsets, this.hijri});

  final PrayerTimeEngine engine;
  final OffsetResolver offsets;

  /// Used to know when it is Ramadan (suhoor reminders). Without it suhoor is
  /// never planned.
  final HijriSource? hijri;

  @override
  Future<AlertPlan> build(PlanRequest request) async {
    final budget = switch (request.platform) {
      AlertPlatform.android => const planner.PlatformBudget.android(),
      AlertPlatform.ios => const planner.PlatformBudget.ios(),
      AlertPlatform.unsupported => null,
    };
    if (budget == null) {
      return const AlertPlan(alerts: [], records: [], runsUntil: null);
    }

    final planned = planner.plan(_input(request, budget));
    final texts = lookupAppLocalizations(
      Locale(request.settings.language.name),
    );
    final alerts = [for (final a in planned) _toScheduled(a, texts)];
    final records = [
      for (final a in planned)
        PlannedAlertRecord(
          alertId: a.alertId,
          fireAt: a.fireAt,
          cause: _causeOf(a),
        ),
    ];
    return AlertPlan(
      alerts: alerts,
      records: records,
      runsUntil: planned.isEmpty ? null : planned.last.fireAt,
    );
  }

  planner.PlannerInput _input(
    PlanRequest request,
    planner.PlatformBudget budget,
  ) {
    final settings = request.settings;
    final location = request.location;
    final global = request.global;
    final quiet = global.quietHours;
    return planner.PlannerInput(
      location: planner.PlannerLocation(
        latitude: location.latitude,
        longitude: location.longitude,
        timeZoneId: location.timeZoneId,
        countryCode: location.countryCode,
      ),
      prayerSettings: planner.PlannerPrayerSettings(
        method: settings.method,
        asr: settings.asrMethod,
        highLatitudeRule: settings.highLatitudeRule,
        offsetsMinutes: settings.offsetsMinutes,
        imsakMinutes: settings.imsakMinutes,
      ),
      alertPreferences: [for (final p in request.preferences) _preference(p)],
      global: planner.PlannerGlobalSettings(
        quietHours: quiet == null
            ? null
            : planner.PlannerQuietHours(
                startMinutes: quiet.startMinutes,
                endMinutes: quiet.endMinutes,
              ),
        suhoorReminderEnabled: global.suhoorReminderEnabled,
        suhoorReminderMinutes: global.suhoorReminderMinutes,
        adhkarReminders: [for (final r in request.adhkarReminders) _adhkar(r)],
      ),
      now: request.now,
      budget: budget,
      offsets: offsets,
      engine: engine,
      permissions: planner.PlannerPermissions(
        notifications: _permission(request.permissions.notificationsGranted),
        exactAlarm: request.permissions.exactAlarmApplicable
            ? _permission(request.permissions.exactAlarmGranted)
            : planner.PlannerPermission.unknown,
      ),
      language: settings.language.name,
      isRamadan: (localDate) =>
          hijri
              ?.convert(localDate, adjustmentDays: settings.hijriAdjustment)
              ?.month ==
          9,
    );
  }

  static planner.PlannerPermission _permission(bool granted) => granted
      ? planner.PlannerPermission.granted
      : planner.PlannerPermission.denied;

  static Prayer _prayer(AlertPrayer prayer) => switch (prayer) {
    AlertPrayer.fajr => Prayer.fajr,
    AlertPrayer.dhuhr => Prayer.dhuhr,
    AlertPrayer.asr => Prayer.asr,
    AlertPrayer.maghrib => Prayer.maghrib,
    AlertPrayer.isha => Prayer.isha,
  };

  static planner.PlannerAlertPreference _preference(AlertPreference p) {
    return planner.PlannerAlertPreference(
      prayer: _prayer(p.prayer),
      type: planner.PlannerAlertType.values.byName(p.type.name),
      voiceId: p.voiceId,
      variant: planner.PlannerAzaanVariant.values.byName(p.variant.name),
      loudMode: p.loudMode,
      volumeChoice: planner.PlannerVolumeChoice.values.byName(
        p.volumeChoice.name,
      ),
      preReminderMinutes: p.preReminderMinutes,
      ignoreQuietHours: p.ignoreQuietHours,
    );
  }

  static planner.PlannerAdhkarReminder _adhkar(AdhkarReminder r) {
    return planner.PlannerAdhkarReminder(
      kind: planner.PlannerAdhkarKind.values.byName(r.kind.name),
      anchor: planner.PlannerAdhkarAnchor.values.byName(r.anchor.name),
      offsetMinutes: r.offsetMinutes,
      enabled: r.enabled,
    );
  }

  /// What the alert log should remember about a planned alert: a quiet-hours
  /// silence wins over an inexact alarm because it explains the whole alert.
  static AlertCause? _causeOf(planner.PlannedAlert alert) {
    if (alert.reasons.contains(planner.PlannedReason.silencedByQuietHours)) {
      return AlertCause.quietHours;
    }
    if (alert.reasons.contains(planner.PlannedReason.inexactAlarm)) {
      return AlertCause.exactAlarmDenied;
    }
    return null;
  }

  /// The platform's delivery type. The renewal notice has no delivery of its
  /// own; it goes out as `vibrate` (the system's default sound on iPhone) and
  /// native code picks its channel from the alert kind.
  static DeliveryType _delivery(planner.PlannedDelivery delivery) =>
      switch (delivery) {
        planner.PlannedDelivery.silent => DeliveryType.silent,
        planner.PlannedDelivery.vibrate => DeliveryType.vibrate,
        planner.PlannedDelivery.shortTone => DeliveryType.shortTone,
        planner.PlannedDelivery.fullAzaan => DeliveryType.fullAzaan,
        planner.PlannedDelivery.renewal => DeliveryType.vibrate,
      };

  static ScheduledAlert _toScheduled(
    planner.PlannedAlert alert,
    AppLocalizations texts,
  ) {
    final text = alertText(alert, texts);
    return ScheduledAlert(
      alertId: alert.alertId,
      fireAtEpochMs: alert.fireAt.millisecondsSinceEpoch,
      kind: AlertKind.values.byName(alert.kind.name),
      delivery: _delivery(alert.deliveryType),
      audioRef: alert.audioRef,
      title: text.title,
      body: text.body,
      stopLabel: texts.alertNotifStopLabel,
      loudMode: alert.loudMode,
      volumeChoice: alert.volumeChoice == planner.PlannerVolumeChoice.gentleRamp
          ? VolumeChoiceDto.gentleRamp
          : VolumeChoiceDto.keepCurrent,
      preciseAllowed: alert.preciseAllowed,
    );
  }
}

/// Title and body of one planned alert, in the language of [texts].
({String title, String body}) alertText(
  planner.PlannedAlert alert,
  AppLocalizations texts,
) {
  final prayerName = _prayerName(alert.prayer, texts);
  switch (alert.kind) {
    case planner.PlannedAlertKind.prayer:
      return (
        title: texts.alertNotifPrayerTitle(prayerName),
        body: texts.alertNotifPrayerBody(prayerName),
      );
    case planner.PlannedAlertKind.preReminder:
      return (
        title: texts.alertNotifPreTitle(prayerName, alert.leadMinutes ?? 0),
        body: texts.alertNotifPreBody(prayerName),
      );
    case planner.PlannedAlertKind.suhoor:
      return (
        title: texts.alertNotifSuhoorTitle,
        body: texts.alertNotifSuhoorBody(alert.leadMinutes ?? 0),
      );
    case planner.PlannedAlertKind.adhkarReminder:
      return alert.messageKey == 'alert.adhkar.evening'
          ? (
              title: texts.alertNotifAdhkarEveningTitle,
              body: texts.alertNotifAdhkarEveningBody,
            )
          : (
              title: texts.alertNotifAdhkarMorningTitle,
              body: texts.alertNotifAdhkarMorningBody,
            );
    case planner.PlannedAlertKind.renewal:
      return (
        title: texts.alertNotifRenewalTitle,
        body: texts.alertNotifRenewalBody,
      );
  }
}

String _prayerName(Prayer? prayer, AppLocalizations texts) => switch (prayer) {
  Prayer.fajr => texts.prayerFajr,
  Prayer.sunrise => texts.prayerSunrise,
  Prayer.dhuhr => texts.prayerDhuhr,
  Prayer.asr => texts.prayerAsr,
  Prayer.maghrib => texts.prayerMaghrib,
  Prayer.isha => texts.prayerIsha,
  null => '',
};
