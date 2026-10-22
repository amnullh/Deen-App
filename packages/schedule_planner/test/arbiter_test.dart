import 'package:schedule_planner/schedule_planner.dart';
import 'package:test/test.dart';

import 'support/fakes.dart';

class _CountingLedger extends InMemoryPlaybackLedger {
  int writes = 0;

  @override
  void markPlayed(String alertId, DateTime at) {
    writes++;
    super.markPlayed(alertId, at);
  }
}

void main() {
  final vectors = loadVector('arbiter.json');

  group('shared vectors: cases', () {
    for (final c in vectors['cases']! as List<Object?>) {
      final json = c! as Map<String, Object?>;
      test(json['name']! as String, () {
        final ledger = InMemoryPlaybackLedger([
          for (final id in json['ledger']! as List<Object?>) id! as String,
        ]);
        final decision = decide(
          json['alertId']! as String,
          ledger,
          suppressed: json['suppressed']! as bool,
        );
        expect(decision.name, json['expected']);
      });
    }
  });

  group('shared vectors: sequences', () {
    for (final s in vectors['sequences']! as List<Object?>) {
      final json = s! as Map<String, Object?>;
      test(json['name']! as String, () {
        final ledger = InMemoryPlaybackLedger();
        var step = 0;
        for (final raw in json['steps']! as List<Object?>) {
          final stepJson = raw! as Map<String, Object?>;
          final id = stepJson['alertId']! as String;
          final decision = decide(
            id,
            ledger,
            suppressed: stepJson['suppressed']! as bool,
          );
          expect(decision.name, stepJson['expected'], reason: 'step $step');
          if (stepJson['markPlayed']! as bool) {
            ledger.markPlayed(id, DateTime.utc(2026, 10, 22));
          }
          step++;
        }
      });
    }
  });

  group('rules', () {
    test('decide never writes to the ledger', () {
      final ledger = _CountingLedger();
      decide('fajr:2026-10-22', ledger, suppressed: false);
      decide('fajr:2026-10-22', ledger, suppressed: true);
      expect(ledger.writes, 0);
      expect(ledger.hasPlayed('fajr:2026-10-22'), isFalse);
    });

    test('exactly one play for any number of attempts', () {
      final ledger = InMemoryPlaybackLedger();
      var plays = 0;
      for (var i = 0; i < 5; i++) {
        if (decide('isha:2026-10-22', ledger, suppressed: false) ==
            ArbiterDecision.play) {
          plays++;
          ledger.markPlayed('isha:2026-10-22', DateTime.utc(2026, 10, 22));
        }
      }
      expect(plays, 1);
    });

    test('in-memory ledger remembers when an alert played', () {
      final ledger = InMemoryPlaybackLedger(['a']);
      expect(ledger.playedAt('a'), isNull);
      ledger.markPlayed('b', DateTime.utc(2026, 1, 1));
      expect(ledger.playedAt('b'), DateTime.utc(2026, 1, 1));
      expect(ledger.hasPlayed('a'), isTrue);
      expect(ledger.hasPlayed('c'), isFalse);
    });
  });
}
