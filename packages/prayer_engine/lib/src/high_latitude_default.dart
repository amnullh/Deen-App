import 'types.dart';

/// Latitude (absolute value, degrees) above which a high-latitude rule is
/// applied by default.
const double highLatitudeThresholdDegrees = 48;

/// Whether [latitude] is above the default high-latitude threshold.
bool isHighLatitude(double latitude) =>
    latitude.abs() > highLatitudeThresholdDegrees;

/// The rule suggested for [latitude].
///
/// Below the threshold the middle-of-the-night rule is used (it only matters if
/// twilight fails). Above it the seventh-of-the-night rule is suggested, which
/// keeps Fajr and Isha closer to the observed sun than a half-night split.
/// The app shows an explanation whenever the high-latitude default is used.
HighLatitudeRule defaultHighLatitudeRule(double latitude) =>
    isHighLatitude(latitude)
    ? HighLatitudeRule.seventhOfNight
    : HighLatitudeRule.middleOfNight;
