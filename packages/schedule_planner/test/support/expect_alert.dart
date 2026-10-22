import 'package:schedule_planner/schedule_planner.dart';
import 'package:test/test.dart';

/// Checks only the fields present in a vector's expected item.
void expectAlertMatches(PlannedAlert actual, Map<String, Object?> expected) {
  final id = expected['alertId'];
  if (id != null) expect(actual.alertId, id);
  final label = actual.alertId;
  if (expected['fireAt'] != null) {
    expect(
      actual.fireAt,
      DateTime.parse(expected['fireAt']! as String),
      reason: '$label fireAt',
    );
  }
  if (expected.containsKey('deliveryType')) {
    expect(actual.deliveryType.name, expected['deliveryType'], reason: label);
  }
  if (expected.containsKey('audioRef')) {
    expect(actual.audioRef, expected['audioRef'], reason: '$label audioRef');
  }
  if (expected.containsKey('preciseAllowed')) {
    expect(actual.preciseAllowed, expected['preciseAllowed'], reason: label);
  }
  if (expected.containsKey('reasons')) {
    expect(
      actual.reasons.map((r) => r.name).toList(),
      expected['reasons'],
      reason: '$label reasons',
    );
  }
}
