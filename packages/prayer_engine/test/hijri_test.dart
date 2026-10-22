// Umm al-Qura Hijri conversion (T070, spike S5).
//
// Reference dates and where they come from:
//
// * 1 Ramadan 1447 AH = Wednesday 2026-02-18. Published by the Umm al-Qura
//   calendar of Saudi Arabia (https://www.ummulqura.org.sa/yearcalender.aspx?y=1447,
//   now redirecting to https://umq.kacst.gov.sa/ar/annual-reference) and
//   quoted from it, accessed 2026-02-17, by Muhammadiyah:
//   https://en.muhammadiyah.or.id/in-line-with-muhammadiyah-umm-al-qura-in-saudi-arabia-also-sets-1-ramadan-1447-on-february-18-2026/
// * 1 Ramadan 1448 AH = Monday 2027-02-08 and 1 Muharram 1448 AH = Tuesday
//   2026-06-16, from the Umm al-Qura calendar as listed by
//   https://makkahlive.net/en/tools/islamic-calendar (secondary source,
//   accessed 2026-10-21); 1 Ramadan 1448 is also given by Muhammadiyah
//   ("The First Day of Ramadan 1448 AH Falls on February 8, 2027").
// * The first day of the table, 1 Muharram 1300 AH = 1882-11-12, and the start
//   of 1447 AH are the values in the ICU4X source data
//   (components/calendar/src/cal/hijri/ummalqura_data.rs). That source is not
//   independent of the generated table; those checks only prove the generator
//   copied the data faithfully.
//
// The official tables could not be fetched from the official site in this
// environment, so only the dates above are asserted. Saudi authorities
// announce Ramadan, Shawwal and Dhu al-Hijjah by moon sighting and these can
// differ from the calendar by one day; the app shows the calendar date and
// offers the -2..+2 adjustment for that reason.
import 'package:prayer_engine/prayer_engine.dart';
import 'package:test/test.dart';

void main() {
  group('toHijri', () {
    test('1 Ramadan 1447 AH is 2026-02-18', () {
      final d = toHijri('2026-02-18');
      expect((d.year, d.month, d.day), (1447, 9, 1));
    });

    test('the day before is the last day of Sha\'ban 1447', () {
      final d = toHijri('2026-02-17');
      expect(d.year, 1447);
      expect(d.month, 8);
      expect(d.day, anyOf(29, 30));
    });

    test('1 Muharram 1448 AH is 2026-06-16', () {
      final d = toHijri('2026-06-16');
      expect((d.year, d.month, d.day), (1448, 1, 1));
    });

    test('1 Ramadan 1448 AH is 2027-02-08', () {
      final d = toHijri('2027-02-08');
      expect((d.year, d.month, d.day), (1448, 9, 1));
    });

    test('the first day of the table is 1 Muharram 1300 AH = 1882-11-12', () {
      final d = toHijri('1882-11-12');
      expect((d.year, d.month, d.day), (1300, 1, 1));
    });

    test('1 Muharram 1447 AH is 2025-06-26 (ICU4X data)', () {
      final d = toHijri('2025-06-26');
      expect((d.year, d.month, d.day), (1447, 1, 1));
    });

    test('dates outside the table throw a RangeError', () {
      expect(() => toHijri('1882-11-11'), throwsRangeError);
      expect(() => toHijri('2200-01-01'), throwsRangeError);
    });

    test('a malformed date throws a FormatException', () {
      expect(() => toHijri('2026/02/18'), throwsFormatException);
      expect(() => toHijri('2026-02-30'), throwsFormatException);
    });
  });

  group('adjustment of -2 to +2 days', () {
    test('+1 moves the Hijri date one day later', () {
      final d = toHijri('2026-02-17', adjustmentDays: 1);
      expect((d.year, d.month, d.day), (1447, 9, 1));
    });

    test('-1 moves the Hijri date one day earlier', () {
      final d = toHijri('2026-02-19', adjustmentDays: -1);
      expect((d.year, d.month, d.day), (1447, 9, 1));
    });

    test('every adjustment from -2 to +2 equals converting the shifted date', () {
      for (var adj = -2; adj <= 2; adj++) {
        final shifted = DateTime.utc(2026, 2, 18 + adj);
        final text =
            '${shifted.year}-${shifted.month.toString().padLeft(2, '0')}-${shifted.day.toString().padLeft(2, '0')}';
        expect(
          toHijri('2026-02-18', adjustmentDays: adj),
          toHijri(text),
          reason: 'adjustment $adj',
        );
      }
    });

    test('crosses a month and a year boundary', () {
      final d = toHijri('2026-06-15', adjustmentDays: 2);
      expect((d.year, d.month, d.day), (1448, 1, 2));
      expect(toHijri('2026-06-16', adjustmentDays: -1).year, 1447);
      expect(toHijri('2026-06-16', adjustmentDays: -1).month, 12);
    });

    test('rejects an adjustment outside -2..+2', () {
      expect(
        () => toHijri('2026-02-18', adjustmentDays: 3),
        throwsArgumentError,
      );
      expect(
        () => toHijri('2026-02-18', adjustmentDays: -3),
        throwsArgumentError,
      );
    });
  });

  group('fromHijri', () {
    test('is the reverse of toHijri on the reference dates', () {
      expect(fromHijri(1447, 9, 1), '2026-02-18');
      expect(fromHijri(1448, 1, 1), '2026-06-16');
      expect(fromHijri(1300, 1, 1), '1882-11-12');
    });

    test('round-trips every day of 1300 to 1600 AH, with and without adjustment', () {
      var date = DateTime.utc(1882, 11, 12);
      final end = DateTime.utc(2174, 11, 1);
      while (date.isBefore(end)) {
        final text =
            '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final h = toHijri(text);
        expect(fromHijri(h.year, h.month, h.day), text);
        date = date.add(const Duration(days: 1));
      }
      final h = toHijri('2026-02-18', adjustmentDays: 2);
      expect(
        fromHijri(h.year, h.month, h.day, adjustmentDays: 2),
        '2026-02-18',
      );
    });

    test('rejects a day that does not exist in that month', () {
      // 1447 AH month 9 has 29 or 30 days, never 31.
      expect(() => fromHijri(1447, 9, 31), throwsArgumentError);
      expect(() => fromHijri(1447, 13, 1), throwsArgumentError);
      expect(() => fromHijri(1447, 0, 1), throwsArgumentError);
      expect(() => fromHijri(1299, 1, 1), throwsRangeError);
    });
  });

  group('calendar structure (all of 1300-1600 AH)', () {
    test('months have 29 or 30 days and years 354 or 355', () {
      for (var year = 1300; year <= 1600; year++) {
        var days = 0;
        for (var month = 1; month <= 12; month++) {
          final length = hijriMonthLength(year, month);
          expect(length, anyOf(29, 30), reason: '$year-$month');
          days += length;
        }
        expect(days, anyOf(354, 355), reason: '$year');
      }
    });

    test('consecutive Hijri days map to consecutive Gregorian days', () {
      var previous = DateTime.utc(1882, 11, 12);
      var previousDate = (year: 1300, month: 1, day: 1);
      for (var i = 0; i < 400; i++) {
        final next = previous.add(const Duration(days: 1));
        final text =
            '${next.year}-${next.month.toString().padLeft(2, '0')}-${next.day.toString().padLeft(2, '0')}';
        final h = toHijri(text);
        final sameMonth =
            h.year == previousDate.year && h.month == previousDate.month;
        if (sameMonth) {
          expect(h.day, previousDate.day + 1);
        } else {
          expect(h.day, 1);
          expect(
            previousDate.day,
            hijriMonthLength(previousDate.year, previousDate.month),
          );
        }
        previous = next;
        previousDate = (year: h.year, month: h.month, day: h.day);
      }
    });
  });

  group('isRamadan', () {
    test('is true for all of Ramadan 1447 and false just outside it', () {
      expect(isRamadan('2026-02-18'), isTrue);
      expect(isRamadan('2026-03-10'), isTrue);
      expect(isRamadan('2026-02-17'), isFalse);
      final last = fromHijri(1447, 9, hijriMonthLength(1447, 9));
      expect(isRamadan(last), isTrue);
      expect(isRamadan(fromHijri(1447, 10, 1)), isFalse);
    });

    test('follows the user adjustment', () {
      expect(isRamadan('2026-02-17', adjustmentDays: 1), isTrue);
      expect(isRamadan('2026-02-18', adjustmentDays: -1), isFalse);
    });

    test('is false, not an error, outside the table', () {
      expect(isRamadan('2300-03-01'), isFalse);
    });
  });
}
