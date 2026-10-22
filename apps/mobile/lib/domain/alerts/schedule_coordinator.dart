import 'dart:async';

import '../../platform/alert_scheduler.dart';
import '../entities/enums.dart';
import '../entities/settings.dart';
import '../repositories/adhkar_repository.dart';
import '../repositories/alert_log_repository.dart';
import '../repositories/alert_preference_repository.dart';
import '../repositories/location_repository.dart';
import '../repositories/settings_repository.dart';
import 'alert_log_entry.dart';
import 'alert_reconciler.dart';
import 'schedule_plan.dart';

/// Why the schedule is being rebuilt (spec Story 3, scenario 9; FR-010).
enum RebuildTrigger {
  /// The app started. Always rebuilds, so a stale schedule never survives an
  /// update or a long absence.
  launch,

  /// The app came back to the foreground and something may have changed.
  foreground,
  settingsChanged,
  locationChanged,
  languageChanged,
  permissionChanged,
  timeZoneChanged,
  clockChanged,

  /// The schedule is close to running out.
  windowRunningLow,

  /// The iOS background refresh task fired.
  platformRefresh,

  /// The user tapped the "open the app" notice.
  renewalTapped,

  /// Rebuilt on request (for example after a settings import).
  manual;

  /// Edits made by the user are skipped when nothing relevant changed, so a
  /// bookkeeping write never causes a rebuild loop.
  bool get skipsWhenUnchanged =>
      this == settingsChanged ||
      this == locationChanged ||
      this == languageChanged;

  /// Triggers that read the journal and judge missed alerts.
  bool get reconciles =>
      this == launch ||
      this == foreground ||
      this == platformRefresh ||
      this == renewalTapped ||
      this == manual;
}

enum RebuildStatus {
  rebuilt,

  /// Nothing relevant changed since the last rebuild.
  skippedUnchanged,

  /// No saved location yet: setup has not finished, so there is nothing to plan.
  skippedNoLocation,

  /// Planning or the platform failed; [RebuildReport.errorCode] says how.
  failed,
}

class RebuildReport {
  const RebuildReport({
    required this.trigger,
    required this.status,
    this.alertCount = 0,
    this.runsUntil,
    this.errorCode,
  });

  final RebuildTrigger trigger;
  final RebuildStatus status;
  final int alertCount;
  final DateTime? runsUntil;

  /// A platform error code (`permission_denied`, `budget_exceeded`, ...) or
  /// `planning_failed`.
  final String? errorCode;
}

/// Builds the plan, hands it to the platform scheduler and keeps it fresh.
///
/// Rebuilds are serialized, and requests that arrive while one is running are
/// merged into a single follow-up rebuild that reads the newest settings.
class ScheduleCoordinator {
  ScheduleCoordinator({
    required this.scheduler,
    required this.planBuilder,
    required this.settings,
    required this.locations,
    required this.alerts,
    required this.log,
    required this.clock,
    required this.reconciler,
    this.adhkarReminders,
    this.deviceZone,
    this.clockChanged,
    this.onMissed,
    this.onReport,
    this.lowWindowAndroid = const Duration(days: 30),
    this.lowWindowIos = const Duration(days: 3),
  });

  final AlertScheduler scheduler;
  final PlanBuilder planBuilder;
  final SettingsRepository settings;
  final LocationRepository locations;
  final AlertPreferenceRepository alerts;
  final AlertLogRepository log;
  final DateTime Function() clock;
  final AlertReconciler reconciler;

  /// Optional: the adhkar reminders to plan.
  final AdhkarReminderRepository? adhkarReminders;

  /// The phone's current time-zone id, or null when unknown.
  final Future<String?> Function()? deviceZone;

  /// Whether the device clock was changed since it was last looked at.
  final Future<bool> Function()? clockChanged;

  /// Told about alerts found missed or possibly missed (for the banner).
  final void Function(List<AlertLogEntry> missed)? onMissed;

  /// Told the outcome of every rebuild (for the Reliability check).
  final void Function(RebuildReport report)? onReport;

  /// How little schedule may remain before a foreground rebuilds it.
  final Duration lowWindowAndroid;
  final Duration lowWindowIos;

  StreamSubscription<AlertPlatformEvent>? _events;
  Future<RebuildReport> _tail = Future.value(
    const RebuildReport(
      trigger: RebuildTrigger.launch,
      status: RebuildStatus.skippedUnchanged,
    ),
  );
  Future<RebuildReport>? _waiting;
  RebuildTrigger? _waitingTrigger;

  String? _lastFingerprint;
  String? _lastBuildDay;
  String? _lastZone;
  DateTime? _runsUntil;

  /// Starts listening to the platform: permission changes and the iOS
  /// background refresh.
  void start() {
    _events ??= scheduler.events.listen(_onEvent);
  }

  Future<void> dispose() async {
    await _events?.cancel();
    _events = null;
  }

  void _onEvent(AlertPlatformEvent event) {
    switch (event) {
      case PermissionChangedEvent():
        unawaited(rebuild(RebuildTrigger.permissionChanged));
      case RefreshWindowEvent(:final done):
        unawaited(
          rebuild(RebuildTrigger.platformRefresh).whenComplete(() {
            if (!done.isCompleted) done.complete();
          }),
        );
      case NotificationTappedEvent():
        break;
    }
  }

  /// The app started.
  Future<RebuildReport> onLaunch() => rebuild(RebuildTrigger.launch);

  /// The app came to the foreground. Rebuilds when the time zone or clock
  /// changed, when the schedule runs low, or on iOS always (research R-I1).
  Future<RebuildReport> onForeground() async {
    final trigger = await _foregroundTrigger();
    return rebuild(trigger);
  }

  Future<RebuildTrigger> _foregroundTrigger() async {
    final zone = await deviceZone?.call();
    if (zone != null) {
      final changed = _lastZone != null && _lastZone != zone;
      _lastZone = zone;
      if (changed) return RebuildTrigger.timeZoneChanged;
    }
    if (await (clockChanged?.call() ?? Future.value(false))) {
      return RebuildTrigger.clockChanged;
    }
    if (_isWindowLow()) return RebuildTrigger.windowRunningLow;
    return RebuildTrigger.foreground;
  }

  bool _isWindowLow() {
    final runsUntil = _runsUntil;
    if (runsUntil == null) return false;
    final threshold = scheduler.platform == AlertPlatform.ios
        ? lowWindowIos
        : lowWindowAndroid;
    return runsUntil.difference(clock()) < threshold;
  }

  /// Rebuilds now (or after the rebuild that is running). Never throws.
  Future<RebuildReport> rebuild(RebuildTrigger trigger) {
    final waiting = _waiting;
    if (waiting != null) {
      _waitingTrigger = _stronger(_waitingTrigger!, trigger);
      return waiting;
    }
    _waitingTrigger = trigger;
    final next = _tail.then((_) {
      final chosen = _waitingTrigger!;
      _waiting = null;
      return _execute(chosen);
    });
    _waiting = next;
    _tail = next;
    return next;
  }

  /// When requests merge, keep the one that forces the most work.
  static RebuildTrigger _stronger(RebuildTrigger a, RebuildTrigger b) {
    if (a.skipsWhenUnchanged && !b.skipsWhenUnchanged) return b;
    return a;
  }

  Future<RebuildReport> _execute(RebuildTrigger trigger) async {
    RebuildReport report;
    try {
      report = await _run(trigger);
    } on Object {
      // A broken platform or planner must never crash the app; the
      // Reliability check reports the failure.
      report = RebuildReport(
        trigger: trigger,
        status: RebuildStatus.failed,
        errorCode: 'planning_failed',
      );
    }
    onReport?.call(report);
    return report;
  }

  Future<RebuildReport> _run(RebuildTrigger trigger) async {
    final now = clock();
    final permissions = await scheduler.getPermissionState();
    var global = await alerts.getGlobal();

    if (trigger.reconciles) {
      final missed = await reconciler.reconcile(
        now: now,
        permissions: permissions,
        scheduleRunsUntil: global.scheduleRunsUntil,
      );
      if (missed.isNotEmpty) onMissed?.call(missed);
    }

    final location = await locations.get();
    final prayerSettings = await settings.get();
    if (location == null || prayerSettings == null) {
      return RebuildReport(
        trigger: trigger,
        status: RebuildStatus.skippedNoLocation,
      );
    }

    global = await _rememberPermissions(global, permissions);
    final preferences = await alerts.getAll();
    final reminders = await adhkarReminders?.getAll() ?? const [];
    final request = PlanRequest(
      settings: prayerSettings,
      location: location,
      preferences: preferences,
      global: global,
      permissions: permissions,
      now: now,
      adhkarReminders: reminders,
    );

    final fingerprint = _fingerprint(request);
    if (_maySkip(trigger, request.platform, now) &&
        fingerprint == _lastFingerprint) {
      return RebuildReport(
        trigger: trigger,
        status: RebuildStatus.skippedUnchanged,
        runsUntil: _runsUntil,
      );
    }

    final plan = await planBuilder.build(request);
    final result = await scheduler.replaceSchedule(plan.alerts);
    if (!result.ok) {
      return RebuildReport(
        trigger: trigger,
        status: RebuildStatus.failed,
        errorCode: result.errorCode ?? 'unknown',
      );
    }

    await log.syncPlanned(plan.records, now: now);
    await alerts.saveGlobal(
      (await alerts.getGlobal()).copyWith(scheduleRunsUntil: plan.runsUntil),
    );
    _lastFingerprint = fingerprint;
    _lastBuildDay = _dayKey(now);
    _runsUntil = plan.runsUntil;
    return RebuildReport(
      trigger: trigger,
      status: RebuildStatus.rebuilt,
      alertCount: plan.alerts.length,
      runsUntil: plan.runsUntil,
    );
  }

  /// Whether [trigger] may be answered with "nothing changed". User edits may.
  /// A foreground on Android may too, within the day the schedule was built:
  /// native code keeps its own window topped up. iOS rebuilds on every
  /// foreground because nothing else refreshes its short window (research R-I5).
  bool _maySkip(RebuildTrigger trigger, AlertPlatform platform, DateTime now) {
    if (trigger.skipsWhenUnchanged) return true;
    return trigger == RebuildTrigger.foreground &&
        platform == AlertPlatform.android &&
        _lastBuildDay == _dayKey(now);
  }

  /// Saves what the platform said about permissions so other screens and the
  /// next launch see it without asking again.
  Future<GlobalAlertSettings> _rememberPermissions(
    GlobalAlertSettings global,
    AlertPermissions permissions,
  ) async {
    PermissionState of(bool granted) =>
        granted ? PermissionState.granted : PermissionState.denied;
    final notifications = of(permissions.notificationsGranted);
    final exact = permissions.exactAlarmApplicable
        ? of(permissions.exactAlarmGranted)
        : global.exactAlarmState;
    if (notifications == global.notificationPermissionState &&
        exact == global.exactAlarmState) {
      return global;
    }
    final updated = global.copyWith(
      notificationPermissionState: notifications,
      exactAlarmState: exact,
    );
    await alerts.saveGlobal(updated);
    return updated;
  }

  /// A text that changes exactly when something the plan depends on changes.
  /// Bookkeeping fields (permission states, schedule end, clock sample, setup
  /// flags) are left out, so saving them never triggers another rebuild.
  String _fingerprint(PlanRequest r) {
    final s = r.settings;
    final offsets = s.offsetsMinutes.entries.toList()
      ..sort((a, b) => a.key.index.compareTo(b.key.index));
    final loc = r.location;
    final g = r.global;
    return [
      'platform=${r.platform.name}',
      'notifications=${r.permissions.notificationsGranted}',
      'exact=${r.permissions.exactAlarmGranted}',
      'method=${s.method.name}/${s.asrMethod.name}/${s.highLatitudeRule.name}',
      'lang=${s.language.name}',
      'offsets=${[for (final e in offsets) '${e.key.name}:${e.value}']}',
      'imsak=${s.imsakMinutes} hijri=${s.hijriAdjustment}',
      'loc=${loc.latitude},${loc.longitude},${loc.timeZoneId}',
      'quiet=${g.quietHours?.startMinutes}-${g.quietHours?.endMinutes}',
      'suhoor=${g.suhoorReminderEnabled}/${g.suhoorReminderMinutes}',
      'output=${g.audioOutput.name}',
      for (final p in r.preferences)
        'pref=${p.prayer.name}/${p.type.name}/${p.voiceId}/${p.variant.name}/'
            '${p.loudMode}/${p.volumeChoice.name}/${p.preReminderMinutes}/'
            '${p.ignoreQuietHours}',
      for (final a in r.adhkarReminders)
        'adhkar=${a.kind.name}/${a.anchor.name}/${a.offsetMinutes}/${a.enabled}',
    ].join('|');
  }

  static String _dayKey(DateTime t) {
    final u = t.toUtc();
    return '${u.year}-${u.month}-${u.day}';
  }
}
