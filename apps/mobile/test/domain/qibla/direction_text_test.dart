import 'package:deen_mobile/domain/qibla/direction_text.dart';
import 'package:deen_mobile/l10n/generated/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('compassPointFor', () {
    test('uses eight 45 degree sectors centred on the compass points', () {
      expect(compassPointFor(0), CompassPoint.north);
      expect(compassPointFor(22.4), CompassPoint.north);
      expect(compassPointFor(22.5), CompassPoint.northeast);
      expect(compassPointFor(45), CompassPoint.northeast);
      expect(compassPointFor(90), CompassPoint.east);
      expect(compassPointFor(135), CompassPoint.southeast);
      expect(compassPointFor(180), CompassPoint.south);
      expect(compassPointFor(212), CompassPoint.southwest);
      expect(compassPointFor(270), CompassPoint.west);
      expect(compassPointFor(315), CompassPoint.northwest);
      expect(compassPointFor(337.4), CompassPoint.northwest);
      expect(compassPointFor(337.5), CompassPoint.north);
      expect(compassPointFor(359.9), CompassPoint.north);
    });

    test('accepts angles outside 0..360', () {
      expect(compassPointFor(360), CompassPoint.north);
      expect(compassPointFor(-90), CompassPoint.west);
      expect(compassPointFor(450), CompassPoint.east);
    });
  });

  group('wholeDegrees', () {
    test('rounds and wraps so 359.6 reads as 0, never 360', () {
      expect(wholeDegrees(212.2), 212);
      expect(wholeDegrees(359.6), 0);
      expect(wholeDegrees(-0.4), 0);
      expect(wholeDegrees(359.4), 359);
    });
  });

  group('describeDirection', () {
    Future<AppLocalizations> load(String language) =>
        AppLocalizations.delegate.load(Locale(language));

    test('English reads "212 degrees, southwest"', () async {
      expect(
        describeDirection(await load('en'), 212),
        '212 degrees, southwest',
      );
    });

    test('Arabic, Urdu and Indonesian have their own words', () async {
      expect(
        describeDirection(await load('ar'), 212),
        '212 درجة، الجنوب الغربي',
      );
      expect(describeDirection(await load('ur'), 212), '212 ڈگری، جنوب مغرب');
      expect(
        describeDirection(await load('id'), 212),
        '212 derajat, barat daya',
      );
    });

    test('the point agrees with the rounded degrees shown', () async {
      final l10n = await load('en');
      expect(describeDirection(l10n, 22.4), '22 degrees, north');
      expect(describeDirection(l10n, 22.6), '23 degrees, northeast');
      expect(describeDirection(l10n, 359.7), '0 degrees, north');
    });

    test('every compass point has a name in every language', () async {
      for (final language in ['en', 'ar', 'ur', 'id']) {
        final l10n = await load(language);
        final names = CompassPoint.values
            .map((p) => localizedCompassPoint(l10n, p))
            .toSet();
        expect(names.length, CompassPoint.values.length, reason: language);
        expect(names.any((n) => n.trim().isEmpty), isFalse);
      }
    });
  });
}
