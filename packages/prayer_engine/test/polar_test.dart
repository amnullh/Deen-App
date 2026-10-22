// Polar day, polar night and high-latitude notices (spec Story 2, T068).
import 'package:prayer_engine/prayer_engine.dart';
import 'package:test/test.dart';

DayTimes _day(
  String date, {
  double latitude = 69.6492,
  double longitude = 18.9553,
  String zone = 'Europe/Oslo',
  CalculationMethod method = CalculationMethod.muslimWorldLeague,
  HighLatitudeRule? rule,
}) {
  return AdhanDartEngine().timesFor(
    latitude: latitude,
    longitude: longitude,
    timeZoneId: zone,
    localDate: date,
    method: method,
    asr: AsrMethod.standard,
    highLatitudeRule: rule ?? defaultHighLatitudeRule(latitude),
    offsetsMinutes: const {},
    imsakMinutes: 10,
  );
}

bool _hasNoEvent(DayTimes day, Prayer prayer) =>
    day.notices.contains(Notice(NoticeCode.polarNoEvent, prayer));

void main() {
  group('Tromso in June (midnight sun)', () {
    final day = _day('2026-06-21');

    test('sunrise, Maghrib, Fajr and Isha do not occur and say so', () {
      for (final prayer in [
        Prayer.sunrise,
        Prayer.maghrib,
        Prayer.fajr,
        Prayer.isha,
      ]) {
        expect(day.times[prayer], isNull, reason: prayer.name);
        expect(_hasNoEvent(day, prayer), isTrue, reason: prayer.name);
      }
    });

    test('Dhuhr and Asr still exist, in order, and have no notice', () {
      final dhuhr = day.times[Prayer.dhuhr];
      final asr = day.times[Prayer.asr];
      expect(dhuhr, isNotNull);
      expect(asr, isNotNull);
      expect(asr!.isAfter(dhuhr!), isTrue);
      expect(_hasNoEvent(day, Prayer.dhuhr), isFalse);
      expect(_hasNoEvent(day, Prayer.asr), isFalse);
    });

    test(
      'imsak, midnight and last third are null without Fajr and Maghrib',
      () {
        expect(day.imsak, isNull);
        expect(day.midnight, isNull);
        expect(day.lastThirdOfNight, isNull);
      },
    );
  });

  group('Tromso in December (polar night)', () {
    final day = _day('2026-12-21');

    test('sunrise and Maghrib do not occur and say so', () {
      expect(day.times[Prayer.sunrise], isNull);
      expect(day.times[Prayer.maghrib], isNull);
      expect(_hasNoEvent(day, Prayer.sunrise), isTrue);
      expect(_hasNoEvent(day, Prayer.maghrib), isTrue);
    });

    test(
      'Dhuhr exists; Asr does not because the Sun stays below the horizon',
      () {
        expect(day.times[Prayer.dhuhr], isNotNull);
        expect(day.times[Prayer.asr], isNull);
        expect(_hasNoEvent(day, Prayer.asr), isTrue);
      },
    );

    test(
      'Fajr and Isha exist from the twilight angles and are not clamped',
      () {
        final fajr = day.times[Prayer.fajr];
        final isha = day.times[Prayer.isha];
        expect(fajr, isNotNull);
        expect(isha, isNotNull);
        expect(fajr!.isBefore(day.times[Prayer.dhuhr]!), isTrue);
        expect(isha!.isAfter(day.times[Prayer.dhuhr]!), isTrue);
        expect(
          day.notices.any((n) => n.code == NoticeCode.highLatitudeRuleApplied),
          isFalse,
        );
      },
    );

    test('a method that sets Isha by a fixed interval has no Isha', () {
      final umm = _day('2026-12-21', method: CalculationMethod.ummAlQura);
      expect(umm.times[Prayer.isha], isNull);
      expect(_hasNoEvent(umm, Prayer.isha), isTrue);
    });
  });

  group('Southern polar day', () {
    test('78 S in December has no sunrise or sunset', () {
      final day = _day(
        '2026-12-21',
        latitude: -78,
        longitude: 166,
        zone: 'Antarctica/McMurdo',
      );
      expect(day.times[Prayer.sunrise], isNull);
      expect(day.times[Prayer.maghrib], isNull);
      expect(day.times[Prayer.dhuhr], isNotNull);
    });
  });

  group('Oslo (high latitude, sun always rises and sets)', () {
    test('June: Fajr and Isha exist only through the high-latitude rule', () {
      final day = _day(
        '2026-06-21',
        latitude: 59.9139,
        longitude: 10.7522,
        rule: HighLatitudeRule.seventhOfNight,
      );
      for (final prayer in Prayer.values) {
        expect(day.times[prayer], isNotNull, reason: prayer.name);
      }
      expect(
        day.notices,
        containsAll([
          const Notice(NoticeCode.highLatitudeRuleApplied, Prayer.fajr),
          const Notice(NoticeCode.highLatitudeRuleApplied, Prayer.isha),
        ]),
      );
      expect(
        day.notices.where((n) => n.code == NoticeCode.polarNoEvent),
        isEmpty,
      );
    });

    test('June with seventh of the night: Fajr is 1/7 of the night before sunrise', () {
      final day = _day(
        '2026-06-21',
        latitude: 59.9139,
        longitude: 10.7522,
        rule: HighLatitudeRule.seventhOfNight,
      );
      final sunset = day.times[Prayer.maghrib]!;
      final sunrise = day.times[Prayer.sunrise]!;
      final isha = day.times[Prayer.isha]!;
      final fajr = day.times[Prayer.fajr]!;
      // Night is sunset to the next sunrise, about 5 h 10 min in Oslo in June;
      // nearly the same as sunset to this sunrise plus a day. One seventh is
      // about 44 minutes, within a minute or two of the day-to-day change.
      expect(isha.difference(sunset).inMinutes, inInclusiveRange(40, 48));
      expect(sunrise.difference(fajr).inMinutes, inInclusiveRange(40, 48));
    });

    test('the rule is reported per prayer, so a different rule can differ', () {
      final seventh = _day(
        '2026-06-21',
        latitude: 59.9139,
        longitude: 10.7522,
        rule: HighLatitudeRule.seventhOfNight,
      );
      final middle = _day(
        '2026-06-21',
        latitude: 59.9139,
        longitude: 10.7522,
        rule: HighLatitudeRule.middleOfNight,
      );
      expect(
        middle.times[Prayer.isha]!.isAfter(seventh.times[Prayer.isha]!),
        isTrue,
      );
    });

    test('March at 60 N needs no rule for Isha when twilight really ends', () {
      final day = _day(
        '2026-03-20',
        latitude: 59.9139,
        longitude: 10.7522,
        rule: HighLatitudeRule.middleOfNight,
      );
      expect(
        day.notices.where((n) => n.prayer == Prayer.isha),
        isEmpty,
        reason: 'natural Isha is well before the middle of the night',
      );
    });
  });

  group('Mid latitudes', () {
    test('Makkah has no notices all year (sampled)', () {
      for (final date in [
        '2026-01-15',
        '2026-04-15',
        '2026-07-15',
        '2026-10-15',
      ]) {
        final day = _day(
          date,
          latitude: 21.4225,
          longitude: 39.8262,
          zone: 'Asia/Riyadh',
          method: CalculationMethod.ummAlQura,
          rule: HighLatitudeRule.middleOfNight,
        );
        expect(day.notices, isEmpty, reason: date);
      }
    });
  });

  group('Day before the Sun stops setting', () {
    test('every non-null time stays in order across the whole year', () {
      final engine = AdhanDartEngine();
      var date = DateTime.utc(2026, 1, 1);
      for (var i = 0; i < 365; i++) {
        final text =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final day = engine.timesFor(
          latitude: 69.6492,
          longitude: 18.9553,
          timeZoneId: 'Europe/Oslo',
          localDate: text,
          method: CalculationMethod.muslimWorldLeague,
          asr: AsrMethod.standard,
          highLatitudeRule: HighLatitudeRule.seventhOfNight,
          offsetsMinutes: const {},
          imsakMinutes: 10,
        );
        final sunrise = day.times[Prayer.sunrise];
        final dhuhr = day.times[Prayer.dhuhr]!;
        final maghrib = day.times[Prayer.maghrib];
        if (sunrise != null) {
          expect(sunrise.isBefore(dhuhr), isTrue, reason: text);
        }
        if (maghrib != null) {
          expect(maghrib.isAfter(dhuhr), isTrue, reason: text);
        }
        final fajr = day.times[Prayer.fajr];
        if (fajr != null && sunrise != null) {
          expect(fajr.isBefore(sunrise), isTrue, reason: text);
        }
        final isha = day.times[Prayer.isha];
        if (isha != null && maghrib != null) {
          expect(isha.isAfter(maghrib), isTrue, reason: text);
        }
        // A missing time always comes with a notice.
        for (final prayer in Prayer.values) {
          if (day.times[prayer] == null) {
            expect(
              _hasNoEvent(day, prayer),
              isTrue,
              reason: '$text ${prayer.name}',
            );
          }
        }
        date = date.add(const Duration(days: 1));
      }
    });
  });
}
