import '../../l10n/generated/app_localizations.dart';
import 'heading_filter.dart';

/// The eight compass points. Eight (not sixteen) keeps the spoken text short
/// and the names common to all four languages; the exact degrees are always
/// spoken with them.
enum CompassPoint {
  north,
  northeast,
  east,
  southeast,
  south,
  southwest,
  west,
  northwest,
}

/// The compass point whose 45 degree sector contains [degrees] (clockwise from
/// north). North covers 337.5 up to 22.5.
CompassPoint compassPointFor(double degrees) {
  final sector = ((normalizeDegrees(degrees) + 22.5) / 45).floor() % 8;
  return CompassPoint.values[sector];
}

/// [degrees] rounded to a whole number in 0..359, so 359.6 reads "0" and never
/// "360".
int wholeDegrees(double degrees) => normalizeDegrees(degrees).round() % 360;

/// The localized lower-case name of [point].
String localizedCompassPoint(AppLocalizations l10n, CompassPoint point) {
  switch (point) {
    case CompassPoint.north:
      return l10n.qiblaDirectionNorth;
    case CompassPoint.northeast:
      return l10n.qiblaDirectionNortheast;
    case CompassPoint.east:
      return l10n.qiblaDirectionEast;
    case CompassPoint.southeast:
      return l10n.qiblaDirectionSoutheast;
    case CompassPoint.south:
      return l10n.qiblaDirectionSouth;
    case CompassPoint.southwest:
      return l10n.qiblaDirectionSouthwest;
    case CompassPoint.west:
      return l10n.qiblaDirectionWest;
    case CompassPoint.northwest:
      return l10n.qiblaDirectionNorthwest;
  }
}

/// A sentence a screen reader reads naturally, such as "212 degrees,
/// southwest". The point is taken from the rounded degrees so the two always
/// agree.
String describeDirection(AppLocalizations l10n, double degrees) {
  final whole = wholeDegrees(degrees);
  final point = compassPointFor(whole.toDouble());
  return l10n.qiblaDirectionDescription(
    whole,
    localizedCompassPoint(l10n, point),
  );
}
