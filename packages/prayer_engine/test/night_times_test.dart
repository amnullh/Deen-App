// Imsak, midnight and last third of the night (T067).
//
// Convention (documented in DayTimes): the night runs from the day's displayed
// Maghrib to the next day's displayed Fajr. Midnight is its midpoint and the
// last third starts two thirds of the way through it. Imsak is Fajr minus the
// configured number of minutes.
import 'package:prayer_engine/prayer_engine.dart';
import 'package:test/test.dart';

DayTimes _day(
  String date, {
  int imsakMinutes = 10,
  Map<Prayer, int> offsets = const {},
  double latitude = 21.4225,
  double longitude = 39.8262,
  String zone = 'Asia/Riyadh',
}) {
  return AdhanDartEngine().timesFor(
    latitude: latitude,
    longitude: longitude,
    timeZoneId: zone,
    localDate: date,
    method: CalculationMethod.ummAlQura,
    asr: AsrMethod.standard,
    highLatitudeRule: HighLatitudeRule.middleOfNight,
    offsetsMinutes: offsets,
    imsakMinutes: imsakMinutes,
  );
}

void main() {
  group('Imsak', () {
    test('is Fajr minus ten minutes by default', () {
      final day = _day('2026-03-20');
      expect(
        day.times[Prayer.fajr]!.difference(day.imsak!),
        const Duration(minutes: 10),
      );
    });

    test('follows the configured number of minutes', () {
      expect(
        _day('2026-03-20', imsakMinutes: 15).times[Prayer.fajr]!.difference(
          _day('2026-03-20', imsakMinutes: 15).imsak!,
        ),
        const Duration(minutes: 15),
      );
      final none = _day('2026-03-20', imsakMinutes: 0);
      expect(none.imsak, none.times[Prayer.fajr]);
    });

    test('follows a Fajr offset set by the user', () {
      final base = _day('2026-03-20');
      final shifted = _day('2026-03-20', offsets: {Prayer.fajr: 3});
      expect(
        shifted.imsak!.difference(base.imsak!),
        const Duration(minutes: 3),
      );
    });

    test('rejects a negative number of minutes', () {
      expect(() => _day('2026-03-20', imsakMinutes: -1), throwsArgumentError);
    });
  });

  group('Midnight and last third of the night', () {
    final today = _day('2026-03-20');
    final tomorrow = _day('2026-03-21');
    final start = today.times[Prayer.maghrib]!;
    final end = tomorrow.times[Prayer.fajr]!;
    final night = end.difference(start);

    test('midnight is the midpoint of Maghrib to the next Fajr', () {
      expect(
        today.midnight!.difference(start).inSeconds,
        closeTo(night.inSeconds / 2, 1),
      );
    });

    test('the last third starts two thirds of the way through the night', () {
      expect(
        today.lastThirdOfNight!.difference(start).inSeconds,
        closeTo(night.inSeconds * 2 / 3, 1),
      );
    });

    test('order is Isha, midnight, last third, next Fajr', () {
      expect(today.times[Prayer.isha]!.isBefore(today.midnight!), isTrue);
      expect(today.midnight!.isBefore(today.lastThirdOfNight!), isTrue);
      expect(today.lastThirdOfNight!.isBefore(end), isTrue);
    });

    test('are UTC instants', () {
      expect(today.midnight!.isUtc, isTrue);
      expect(today.lastThirdOfNight!.isUtc, isTrue);
      expect(today.imsak!.isUtc, isTrue);
    });

    test('use the displayed Maghrib, so a Maghrib offset moves the night', () {
      final shifted = _day('2026-03-20', offsets: {Prayer.maghrib: 6});
      final shiftedNight = end.difference(shifted.times[Prayer.maghrib]!);
      expect(
        shifted.midnight!.difference(shifted.times[Prayer.maghrib]!).inSeconds,
        closeTo(shiftedNight.inSeconds / 2, 1),
      );
      expect(shiftedNight, night - const Duration(minutes: 6));
    });

    test('the night crosses the year end correctly', () {
      final day = _day('2026-12-31');
      final next = _day('2027-01-01');
      expect(day.midnight!.isAfter(day.times[Prayer.maghrib]!), isTrue);
      expect(day.lastThirdOfNight!.isBefore(next.times[Prayer.fajr]!), isTrue);
    });
  });
}
