import 'package:schedule_planner/schedule_planner.dart';
import 'package:test/test.dart';

import 'support/fakes.dart';

void main() {
  final vectors = loadVector('alert_ids.json');

  group('alertId (shared vectors)', () {
    for (final c in vectors['build']! as List<Object?>) {
      final json = c! as Map<String, Object?>;
      final kind = json['kind']! as String;
      final date = json['localDate']! as String;
      final pre = json['pre']! as bool;
      final expected = json['expected'] as String?;
      test('$kind $date pre=$pre', () {
        if (expected == null) {
          expect(
            () => alertId(kind, date, pre: pre),
            throwsA(isA<ArgumentError>()),
          );
        } else {
          expect(alertId(kind, date, pre: pre), expected);
        }
      });
    }
  });

  group('parseAlertId (shared vectors)', () {
    for (final c in vectors['parse']! as List<Object?>) {
      final json = c! as Map<String, Object?>;
      final id = json['id']! as String;
      final expected = json['expected'] as Map<String, Object?>?;
      test('"$id"', () {
        final parsed = parseAlertId(id);
        if (expected == null) {
          expect(parsed, isNull);
        } else {
          expect(
            parsed,
            ParsedAlertId(
              kind: expected['kind']! as String,
              localDate: expected['localDate']! as String,
              pre: expected['pre']! as bool,
            ),
          );
        }
      });
    }
  });

  test('every built id parses back to its parts', () {
    for (final kind in [
      'fajr',
      'dhuhr',
      'asr',
      'maghrib',
      'isha',
      'suhoor',
      'adhkar-morning',
      'adhkar-evening',
      'renewal',
    ]) {
      final id = alertId(kind, '2026-10-22');
      expect(
        parseAlertId(id),
        ParsedAlertId(kind: kind, localDate: '2026-10-22', pre: false),
      );
    }
  });

  test('alertPrayers are the five alert prayers in daily order', () {
    expect(alertPrayers.map((p) => p.name), [
      'fajr',
      'dhuhr',
      'asr',
      'maghrib',
      'isha',
    ]);
  });
}
