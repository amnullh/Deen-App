import 'package:geonames_build/normalize.dart';
import 'package:test/test.dart';

void main() {
  group('normalizeSearchText', () {
    test('lower-cases and trims', () {
      expect(normalizeSearchText('  Jakarta '), 'jakarta');
    });

    test('removes Latin diacritics, precomposed and combining', () {
      expect(normalizeSearchText('Zürich'), 'zurich');
      expect(normalizeSearchText('Düsseldorf'), 'dusseldorf');
      expect(normalizeSearchText('São Paulo'), 'sao paulo');
      expect(normalizeSearchText('Łódź'), 'lodz');
      expect(normalizeSearchText('Reykjavík'), 'reykjavik');
      expect(normalizeSearchText('Café'), 'cafe');
      expect(normalizeSearchText('İstanbul'), 'istanbul');
      expect(normalizeSearchText('Straße'), 'strasse');
    });

    test('treats hyphens as spaces and drops apostrophes', () {
      expect(normalizeSearchText('Saint-Denis'), 'saint denis');
      expect(normalizeSearchText("Ta'if"), 'taif');
      expect(normalizeSearchText('Ta’if'), 'taif');
      expect(normalizeSearchText('New   York'), 'new york');
    });

    test('removes Arabic diacritics and tatweel', () {
      expect(normalizeSearchText('مَكَّة'), normalizeSearchText('مكة'));
      expect(normalizeSearchText('الـرياض'), 'الرياض');
    });

    test('folds alef, yeh, kaf and heh variants', () {
      expect(normalizeSearchText('أبوظبي'), normalizeSearchText('ابوظبي'));
      expect(normalizeSearchText('إربد'), normalizeSearchText('اربد'));
      expect(normalizeSearchText('القاهرة'), normalizeSearchText('القاهره'));
      expect(normalizeSearchText('مصر'), 'مصر');
      expect(normalizeSearchText('عمّان'), 'عمان');
      // Persian/Urdu yeh and kaf fold to the Arabic letters.
      expect(normalizeSearchText('کراچی'), normalizeSearchText('كراچي'));
      // Heh goal and heh doachashmee fold to heh.
      expect(normalizeSearchText('ہند'), normalizeSearchText('هند'));
      expect(normalizeSearchText('ھند'), normalizeSearchText('هند'));
    });

    test('keeps distinct Urdu letters', () {
      expect(normalizeSearchText('ٹھٹھہ'), isNot(normalizeSearchText('تهته')));
      expect(normalizeSearchText('لاہور'), normalizeSearchText('لاهور'));
    });

    test('maps Arabic-Indic digits to ASCII digits', () {
      expect(normalizeSearchText('٣٠ ۴۵'), '30 45');
    });

    test('is idempotent', () {
      for (final input in ['Zürich', 'مَكَّة', 'Saint-Denis', 'کراچی']) {
        final once = normalizeSearchText(input);
        expect(normalizeSearchText(once), once);
      }
    });

    test('blank input gives an empty string', () {
      expect(normalizeSearchText('   '), '');
    });
  });

  group('prefixUpperBound', () {
    test('is greater than every string that starts with the prefix', () {
      final bound = prefixUpperBound('abc');
      expect('abc'.compareTo(bound), lessThan(0));
      expect('abc\u0627\u{1F600}'.compareTo(bound), lessThan(0));
      expect('abd'.compareTo(bound), greaterThanOrEqualTo(0));
    });
  });
}
