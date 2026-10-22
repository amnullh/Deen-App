import 'package:deen_mobile/domain/alerts/alert_log_entry.dart';
import 'package:deen_mobile/domain/alerts/reliability_snapshot.dart';
import 'package:deen_mobile/platform/alert_scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime.utc(2026, 10, 22, 12);

ScheduledAlert _alert(String id, {bool precise = true}) => ScheduledAlert(
  alertId: id,
  fireAtEpochMs: _now.add(const Duration(hours: 1)).millisecondsSinceEpoch,
  kind: AlertKind.prayer,
  delivery: DeliveryType.shortTone,
  title: id,
  body: '',
  stopLabel: '',
  loudMode: false,
  volumeChoice: VolumeChoiceDto.keepCurrent,
  preciseAllowed: precise,
);

ReliabilitySnapshot _snapshot(
  AlertPermissions permissions, {
  List<ScheduledAlert>? next,
  DateTime? runsUntil,
  Map<String, AlertCause?> causes = const {},
}) {
  return ReliabilitySnapshot.from(
    permissions: permissions,
    summary: PendingSummary(
      registeredCount: 1,
      snapshotCount: 1,
      nextAlerts: next ?? [_alert('a')],
    ),
    causes: causes,
    runsUntil: runsUntil ?? _now.add(const Duration(days: 40)),
    lastResult: null,
    now: _now,
  );
}

void main() {
  const goodAndroid = AlertPermissions(
    platform: AlertPlatform.android,
    notificationsGranted: true,
  );

  test('a healthy Android phone has no problems', () {
    expect(_snapshot(goodAndroid).allGood, isTrue);
  });

  test('problems are listed in a stable order', () {
    final snapshot = _snapshot(
      const AlertPermissions(
        platform: AlertPlatform.android,
        notificationsGranted: false,
        exactAlarmGranted: false,
        batteryOptimizationIgnored: false,
      ),
    );
    expect(snapshot.problems, [
      ReliabilityProblem.notificationsOff,
      ReliabilityProblem.exactAlarmOff,
      ReliabilityProblem.batteryRestricted,
    ]);
  });

  test('iPhone only has notification and sound problems', () {
    final snapshot = _snapshot(
      const AlertPermissions(
        platform: AlertPlatform.ios,
        notificationsGranted: true,
        soundEnabled: false,
      ),
    );
    expect(snapshot.problems, [ReliabilityProblem.soundOff]);
  });

  test('an empty schedule or an ended one is a problem', () {
    expect(_snapshot(goodAndroid, next: const []).problems, [
      ReliabilityProblem.nothingScheduled,
    ]);
    expect(
      _snapshot(
        goodAndroid,
        runsUntil: _now.subtract(const Duration(days: 1)),
      ).problems,
      [ReliabilityProblem.nothingScheduled],
    );
  });

  test('only five upcoming alerts are kept, with their causes', () {
    final snapshot = _snapshot(
      goodAndroid,
      next: [for (var i = 0; i < 8; i++) _alert('a$i')],
      causes: {'a1': AlertCause.quietHours},
    );
    expect(snapshot.next, hasLength(5));
    expect(snapshot.next[1].silencedByQuietHours, isTrue);
    expect(snapshot.next[0].silencedByQuietHours, isFalse);
  });

  test('an alert registered inexactly is flagged', () {
    final snapshot = _snapshot(
      goodAndroid,
      next: [_alert('a', precise: false)],
    );
    expect(snapshot.next.single.inexact, isTrue);
  });

  test('without a saved end date the platform summary supplies it', () {
    final end = _now.add(const Duration(days: 20));
    final snapshot = ReliabilitySnapshot.from(
      permissions: goodAndroid,
      summary: PendingSummary(
        registeredCount: 1,
        snapshotCount: 1,
        nextAlerts: [_alert('a')],
        runsUntilEpochMs: end.millisecondsSinceEpoch,
      ),
      causes: const {},
      runsUntil: null,
      lastResult: null,
      now: _now,
    );
    expect(snapshot.runsUntil, end);
  });

  test('a host that cannot schedule has nothing to report', () {
    final snapshot = _snapshot(
      const AlertPermissions.unknown(),
      next: const [],
    );
    expect(snapshot.problems, isEmpty);
  });
}
