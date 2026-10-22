import 'package:prayer_engine/prayer_engine.dart';
import 'package:test/test.dart';

const Map<Prayer, int> _noOffsets = {};

DayTimes _compute(
  PrayerTimeEngine engine, {
  double latitude = 21.4225,
  double longitude = 39.8262,
  String localDate = '2026-03-20',
  CalculationMethod method = CalculationMethod.ummAlQura,
  AsrMethod asr = AsrMethod.standard,
  Map<Prayer, int> offsets = _noOffsets,
}) {
  return engine.timesFor(
    latitude: latitude,
    longitude: longitude,
    timeZoneId: 'Asia/Riyadh',
    localDate: localDate,
    method: method,
    asr: asr,
    highLatitudeRule: HighLatitudeRule.middleOfNight,
    offsetsMinutes: offsets,
    imsakMinutes: 10,
  );
}

void main() {
  final PrayerTimeEngine engine = AdhanDartEngine();

  group('PrayerTimeEngine contract', () {
    test('is deterministic for the same inputs', () {
      final a = _compute(engine);
      final b = _compute(engine);
      for (final prayer in Prayer.values) {
        expect(a.times[prayer], b.times[prayer]);
      }
    });

    test('returns UTC instants in daily order for a normal location', () {
      final day = _compute(engine);
      final ordered = Prayer.values.map((p) => day.times[p]!).toList();
      for (final t in ordered) {
        expect(t.isUtc, isTrue);
      }
      for (var i = 1; i < ordered.length; i++) {
        expect(
          ordered[i].isAfter(ordered[i - 1]),
          isTrue,
          reason: '${Prayer.values[i]} must follow ${Prayer.values[i - 1]}',
        );
      }
    });

    test('reports the requested local date', () {
      expect(_compute(engine).localDate, '2026-03-20');
    });

    test('applies offsets after calculation, per prayer', () {
      final base = _compute(engine);
      final shifted = _compute(
        engine,
        offsets: {Prayer.fajr: 5, Prayer.isha: -7},
      );
      expect(
        shifted.times[Prayer.fajr]!.difference(base.times[Prayer.fajr]!),
        const Duration(minutes: 5),
      );
      expect(
        shifted.times[Prayer.isha]!.difference(base.times[Prayer.isha]!),
        const Duration(minutes: -7),
      );
      expect(shifted.times[Prayer.dhuhr], base.times[Prayer.dhuhr]);
    });

    test('Hanafi Asr is later than standard Asr', () {
      final standard = _compute(engine);
      final hanafi = _compute(engine, asr: AsrMethod.hanafi);
      expect(
        hanafi.times[Prayer.asr]!.isAfter(standard.times[Prayer.asr]!),
        isTrue,
      );
    });

    test('computes every method without throwing', () {
      for (final method in CalculationMethod.values) {
        final day = _compute(engine, method: method);
        expect(day.times[Prayer.fajr], isNotNull, reason: '$method');
      }
    });

    test('rejects malformed or impossible dates', () {
      expect(
        () => _compute(engine, localDate: '2026-3-20'),
        throwsFormatException,
      );
      expect(
        () => _compute(engine, localDate: '2026-02-30'),
        throwsFormatException,
      );
    });

    test('never returns a value for a missing event as a fake time', () {
      // Near the pole in midsummer the sun does not set: the engine must not
      // throw, and any missing event must be null with a notice, not garbage.
      final day = _compute(
        engine,
        latitude: 78.2232,
        longitude: 15.6267,
        localDate: '2026-06-21',
      );
      for (final entry in day.times.entries) {
        final t = entry.value;
        if (t == null) {
          expect(
            day.notices.any((n) => n.code == NoticeCode.polarNoEvent),
            isTrue,
          );
        } else {
          expect(t.millisecondsSinceEpoch.isNaN, isFalse);
        }
      }
    });
  });
}
