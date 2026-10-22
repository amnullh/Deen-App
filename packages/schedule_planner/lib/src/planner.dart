import 'package:prayer_engine/prayer_engine.dart';

import 'alert_id.dart';
import 'local_time.dart';
import 'planned_alert.dart';
import 'recording_mapping.dart';
import 'types.dart';

/// Local clock time of the Android renewal alert (09:00).
const int renewalLocalMinutes = 9 * 60;

/// How long after the last kept alert the iOS renewal alert fires.
const Duration iosRenewalDelay = Duration(minutes: 1);

/// iOS planning gives up looking for alerts after this many local days (a user
/// with a single prayer on needs 62 days to fill the budget).
const int _iosMaxHorizonDays = 120;

/// Local days planned past the day that fills the iOS budget, so a reminder
/// whose offset crosses midnight cannot be missed from the nearest set.
const int _iosExtraDays = 2;

/// Plans every alert after `input.now` that fits the platform budget, sorted by
/// `fireAt` (ties by `alertId`). Pure: the same input always gives the same
/// list. See the package README for the rules.
List<PlannedAlert> plan(PlannerInput input) {
  final planner = _Planner(input);
  if (!planner.anythingConfigured) return const [];
  final raw = switch (input.budget) {
    final AndroidBudget b => planner.android(b),
    final IosBudget b => planner.ios(b),
  };
  return [for (var i = 0; i < raw.length; i++) raw[i].withPriority(i)];
}

int _byTime(PlannedAlert a, PlannedAlert b) {
  final byTime = a.fireAt.compareTo(b.fireAt);
  return byTime != 0 ? byTime : a.alertId.compareTo(b.alertId);
}

class _Planner {
  _Planner(this.input)
    : now = input.now.toUtc(),
      clock = LocalClock(input.location.timeZoneId, input.offsets),
      prefs = {
        for (final p in input.alertPreferences)
          if (alertPrayers.contains(p.prayer)) p.prayer: p,
      };

  final PlannerInput input;
  final DateTime now;
  final LocalClock clock;
  final Map<Prayer, PlannerAlertPreference> prefs;

  bool get anythingConfigured =>
      prefs.values.any((p) => p.type != PlannerAlertType.off) ||
      input.global.suhoorReminderEnabled ||
      input.global.adhkarReminders.any((r) => r.enabled);

  // -- Budgets -------------------------------------------------------------

  List<PlannedAlert> android(AndroidBudget budget) {
    final today = clock.dateOf(now);
    final alerts = <PlannedAlert>[];
    for (var i = -1; i < budget.snapshotDays; i++) {
      alerts.addAll(_alertsOn(addDays(today, i)));
    }
    alerts.sort(_byTime);
    if (alerts.isEmpty || budget.renewalDaysBeforeEnd == 0) return alerts;
    final renewalDate = addDays(
      today,
      budget.snapshotDays - budget.renewalDaysBeforeEnd,
    );
    final renewalAt = clock.toUtc(renewalDate, renewalLocalMinutes);
    if (renewalAt.isAfter(now)) {
      alerts.add(_renewal(renewalDate, renewalAt));
      alerts.sort(_byTime);
    }
    return alerts;
  }

  List<PlannedAlert> ios(IosBudget budget) {
    final keep = budget.maxRequests - 1;
    final today = clock.dateOf(now);
    final alerts = <PlannedAlert>[];
    int? fullOnDay;
    for (var i = -1; i < _iosMaxHorizonDays; i++) {
      alerts.addAll(_alertsOn(addDays(today, i)));
      if (alerts.length >= keep) {
        fullOnDay ??= i;
        if (i >= fullOnDay + _iosExtraDays) break;
      }
    }
    if (alerts.isEmpty) return alerts;
    alerts.sort(_byTime);
    final kept = alerts.take(keep).toList();
    final last = kept.last;
    kept.add(_renewal(last.localDate, last.fireAt.add(iosRenewalDelay)));
    return kept;
  }

  // -- One local day -------------------------------------------------------

  /// The alerts of one local date that fire after now, deduplicated by id.
  List<PlannedAlert> _alertsOn(String localDate) {
    final day = input.engine.timesFor(
      latitude: input.location.latitude,
      longitude: input.location.longitude,
      timeZoneId: input.location.timeZoneId,
      localDate: localDate,
      method: input.prayerSettings.method,
      asr: input.prayerSettings.asr,
      highLatitudeRule: input.prayerSettings.highLatitudeRule,
      offsetsMinutes: input.prayerSettings.offsetsMinutes,
      imsakMinutes: input.prayerSettings.imsakMinutes,
    );
    final byId = <String, PlannedAlert>{};
    void add(PlannedAlert? alert) {
      if (alert != null && alert.fireAt.isAfter(now)) {
        byId.putIfAbsent(alert.alertId, () => alert);
      }
    }

    for (final prayer in alertPrayers) {
      final pref = prefs[prayer];
      final at = day.times[prayer];
      if (pref == null || pref.type == PlannerAlertType.off || at == null) {
        continue;
      }
      add(_prayerAlert(pref, localDate, at));
      final lead = pref.preReminderMinutes;
      if (lead != null) add(_preReminder(pref, localDate, at, lead));
    }
    add(_suhoor(day, localDate));
    for (final reminder in input.global.adhkarReminders) {
      add(_adhkar(reminder, day, localDate));
    }
    return byId.values.toList();
  }

  PlannedAlert _prayerAlert(
    PlannerAlertPreference pref,
    String localDate,
    DateTime at,
  ) => _build(
    id: alertId(pref.prayer.name, localDate),
    kind: PlannedAlertKind.prayer,
    localDate: localDate,
    fireAt: at,
    messageKey: 'alert.prayer.${pref.prayer.name}',
    prayer: pref.prayer,
    requested: pref.type,
    pref: pref,
    ignoreQuietHours: pref.ignoreQuietHours,
  );

  PlannedAlert _preReminder(
    PlannerAlertPreference pref,
    String localDate,
    DateTime prayerAt,
    int lead,
  ) => _build(
    id: alertId(pref.prayer.name, localDate, pre: true),
    kind: PlannedAlertKind.preReminder,
    localDate: localDate,
    fireAt: prayerAt.subtract(Duration(minutes: lead)),
    messageKey: 'alert.preReminder.${pref.prayer.name}',
    prayer: pref.prayer,
    leadMinutes: lead,
    requested: pref.type,
    ignoreQuietHours: pref.ignoreQuietHours,
  );

  PlannedAlert? _suhoor(DayTimes day, String localDate) {
    final global = input.global;
    final fajr = day.times[Prayer.fajr];
    if (!global.suhoorReminderEnabled ||
        fajr == null ||
        !input.isRamadan(localDate)) {
      return null;
    }
    final fajrPref = prefs[Prayer.fajr];
    return _build(
      id: alertId('suhoor', localDate),
      kind: PlannedAlertKind.suhoor,
      localDate: localDate,
      fireAt: fajr.subtract(Duration(minutes: global.suhoorReminderMinutes)),
      messageKey: 'alert.suhoor',
      prayer: Prayer.fajr,
      leadMinutes: global.suhoorReminderMinutes,
      requested: fajrPref?.type ?? PlannerAlertType.off,
      standalone: true,
      ignoreQuietHours: fajrPref?.ignoreQuietHours ?? false,
    );
  }

  PlannedAlert? _adhkar(
    PlannerAdhkarReminder reminder,
    DayTimes day,
    String localDate,
  ) {
    final prayer = switch (reminder.anchor) {
      PlannerAdhkarAnchor.fajr => Prayer.fajr,
      PlannerAdhkarAnchor.asr => Prayer.asr,
      PlannerAdhkarAnchor.maghrib => Prayer.maghrib,
    };
    final at = day.times[prayer];
    if (!reminder.enabled || at == null) return null;
    final name = reminder.kind.name;
    final anchorPref = prefs[prayer];
    return _build(
      id: alertId('adhkar-$name', localDate),
      kind: PlannedAlertKind.adhkarReminder,
      localDate: localDate,
      fireAt: at.add(Duration(minutes: reminder.offsetMinutes)),
      messageKey: 'alert.adhkar.$name',
      prayer: prayer,
      requested: anchorPref?.type ?? PlannerAlertType.off,
      standalone: true,
      ignoreQuietHours: anchorPref?.ignoreQuietHours ?? false,
    );
  }

  PlannedAlert _renewal(String localDate, DateTime at) {
    final marks = _permissionMarks();
    return PlannedAlert(
      alertId: alertId('renewal', localDate),
      kind: PlannedAlertKind.renewal,
      localDate: localDate,
      fireAt: at,
      deliveryType: PlannedDelivery.renewal,
      priority: 0,
      preciseAllowed: marks.precise,
      messageKey: 'alert.renewal',
      reasons: marks.reasons,
    );
  }

  // -- Delivery rules ------------------------------------------------------

  /// Applies the reminder rule, quiet hours and permission marks.
  ///
  /// [requested] is the prayer's own type. A [pref] means the alert is the
  /// prayer itself (voice, wording and loud mode apply); without it the alert
  /// is a reminder and never plays a full Azaan. [standalone] reminders (suhoor,
  /// adhkar) are their own opt-in, so a prayer set to off does not mute them.
  PlannedAlert _build({
    required String id,
    required PlannedAlertKind kind,
    required String localDate,
    required DateTime fireAt,
    required String messageKey,
    required Prayer prayer,
    required PlannerAlertType requested,
    required bool ignoreQuietHours,
    PlannerAlertPreference? pref,
    int? leadMinutes,
    bool standalone = false,
  }) {
    final isReminder = pref == null;
    final type = !isReminder
        ? requested
        : standalone
        ? standaloneReminderType(requested)
        : reminderType(requested);
    final tonedDown = isReminder && requested == PlannerAlertType.fullAzaan;
    final audible =
        type == PlannerAlertType.shortTone ||
        type == PlannerAlertType.fullAzaan;
    final quiet = input.global.quietHours;
    final silenced =
        audible &&
        !ignoreQuietHours &&
        quiet != null &&
        quiet.contains(clock.minutesOfDay(fireAt));

    final PlannedDelivery delivery;
    if (silenced) {
      delivery = PlannedDelivery.silent;
    } else {
      delivery = switch (type) {
        PlannerAlertType.vibrate => PlannedDelivery.vibrate,
        PlannerAlertType.shortTone => PlannedDelivery.shortTone,
        PlannerAlertType.fullAzaan => PlannedDelivery.fullAzaan,
        PlannerAlertType.silent ||
        PlannerAlertType.off => PlannedDelivery.silent,
      };
    }

    final marks = _permissionMarks();
    final reasons = <PlannedReason>{
      if (silenced) PlannedReason.silencedByQuietHours,
      ...marks.reasons,
      if (tonedDown && !silenced) PlannedReason.reminderUsesShortTone,
    }.toList()..sort((a, b) => a.index.compareTo(b.index));

    final fullAzaan = delivery == PlannedDelivery.fullAzaan;
    final loud =
        pref != null &&
        pref.loudMode &&
        (delivery == PlannedDelivery.shortTone || fullAzaan);
    return PlannedAlert(
      alertId: id,
      kind: kind,
      localDate: localDate,
      fireAt: fireAt.toUtc(),
      deliveryType: delivery,
      priority: 0,
      preciseAllowed: marks.precise,
      messageKey: messageKey,
      prayer: prayer,
      leadMinutes: leadMinutes,
      audioRef: fullAzaan
          ? recordingId(
              voiceId: pref!.voiceId,
              variant: pref.variant,
              prayer: prayer,
            )
          : delivery == PlannedDelivery.shortTone
          ? shortToneId
          : null,
      voiceId: fullAzaan ? pref!.voiceId : null,
      variant: fullAzaan ? pref!.variant : null,
      loudMode: loud,
      volumeChoice: loud ? pref.volumeChoice : PlannerVolumeChoice.keepCurrent,
      reasons: reasons,
    );
  }

  /// Marks every alert shares: exact alarms (Android only) and notifications.
  ({bool precise, List<PlannedReason> reasons}) _permissionMarks() {
    final inexact =
        input.budget is AndroidBudget &&
        input.permissions.exactAlarm == PlannerPermission.denied;
    final noNotifications =
        input.permissions.notifications == PlannerPermission.denied;
    return (
      precise: !inexact,
      reasons: [
        if (inexact) PlannedReason.inexactAlarm,
        if (noNotifications) PlannedReason.notificationsDenied,
      ],
    );
  }
}
