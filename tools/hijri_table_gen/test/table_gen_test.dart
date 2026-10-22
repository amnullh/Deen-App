import 'package:hijri_table_gen/table_gen.dart';
import 'package:test/test.dart';

const _sample = '''
    let l = true; // long
    let s = false; // short
    &[
        PackedHijriYearData::try_new(1300, [l, s, l, s, l, s, l, s, l, s, l, s], gregorian(1882, 11, 12)).unwrap(),
        PackedHijriYearData::try_new(1301, [l, l, s, l, s, l, s, l, s, l, s, s], gregorian(1883, 11, 1)).unwrap(),
    ]
''';

void main() {
  group('parseIcu4xTable', () {
    test('reads years, month lengths and start dates', () {
      final rows = parseIcu4xTable(_sample);
      expect(rows, hasLength(2));
      expect(rows.first.year, 1300);
      expect(rows.first.monthIsLong, [
        true,
        false,
        true,
        false,
        true,
        false,
        true,
        false,
        true,
        false,
        true,
        false,
      ]);
      expect(
        rows.first.startDay,
        DateTime.utc(1882, 11, 12).millisecondsSinceEpoch ~/ 86400000,
      );
    });

    test('rejects a row that does not have 12 months', () {
      expect(
        () => parseIcu4xTable(
          'PackedHijriYearData::try_new(1300, [l, s], gregorian(1882, 11, 12))',
        ),
        throwsFormatException,
      );
    });
  });

  group('validateTable', () {
    test('accepts consecutive years whose start dates follow the lengths', () {
      // 1300 has 6 long and 6 short months = 354 days; 1301 starts 354 days later.
      final rows = parseIcu4xTable(_sample);
      final first = rows.first;
      final next = HijriYearRow(
        year: 1301,
        monthIsLong: rows[1].monthIsLong,
        startDay: first.startDay + 354,
      );
      expect(() => validateTable([first, next]), returnsNormally);
    });

    test('rejects a gap between a year and the next', () {
      final rows = parseIcu4xTable(_sample);
      final bad = HijriYearRow(
        year: 1301,
        monthIsLong: rows[1].monthIsLong,
        startDay: rows.first.startDay + 355,
      );
      expect(() => validateTable([rows.first, bad]), throwsStateError);
    });

    test('rejects years that are not consecutive', () {
      final rows = parseIcu4xTable(_sample);
      final bad = HijriYearRow(
        year: 1303,
        monthIsLong: rows[1].monthIsLong,
        startDay: rows.first.startDay + 354,
      );
      expect(() => validateTable([rows.first, bad]), throwsStateError);
    });
  });

  group('renderDartTable', () {
    test('keeps the Unicode license notice and the source', () {
      final text = renderDartTable(
        parseIcu4xTable(_sample),
        sourceUrl: 'https://example.test/x.rs',
      );
      expect(text, contains('UNICODE LICENSE V3'));
      expect(text, contains('https://example.test/x.rs'));
      expect(text, contains('const int ummAlQuraFirstYear = 1300;'));
      expect(text, contains('ummAlQuraMonthMasks'));
    });
  });
}
