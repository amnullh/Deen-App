/// The 20 reference cities used to validate prayer times (spec SC-003).
///
/// They cover every regional default, both hemispheres, the equator, a high
/// latitude with twilight problems, a place with polar day and night, and a
/// zone on the far side of the date line.
library;

class ReferenceCity {
  const ReferenceCity({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.timeZoneId,
    required this.countryCode,
    this.note = '',
  });

  final String name;
  final double latitude;
  final double longitude;
  final String timeZoneId;
  final String countryCode;
  final String note;
}

const List<ReferenceCity> referenceCities = [
  ReferenceCity(
    name: 'Makkah',
    latitude: 21.4225,
    longitude: 39.8262,
    timeZoneId: 'Asia/Riyadh',
    countryCode: 'SA',
    note: 'Arabian Peninsula, Umm al-Qura',
  ),
  ReferenceCity(
    name: 'Cairo',
    latitude: 30.0444,
    longitude: 31.2357,
    timeZoneId: 'Africa/Cairo',
    countryCode: 'EG',
    note: 'Middle East and Africa; DST',
  ),
  ReferenceCity(
    name: 'Istanbul',
    latitude: 41.0082,
    longitude: 28.9784,
    timeZoneId: 'Europe/Istanbul',
    countryCode: 'TR',
    note: 'Diyanet',
  ),
  ReferenceCity(
    name: 'Karachi',
    latitude: 24.8607,
    longitude: 67.0011,
    timeZoneId: 'Asia/Karachi',
    countryCode: 'PK',
    note: 'South Asia',
  ),
  ReferenceCity(
    name: 'Dhaka',
    latitude: 23.8103,
    longitude: 90.4125,
    timeZoneId: 'Asia/Dhaka',
    countryCode: 'BD',
    note: 'South Asia, near the Tropic of Cancer',
  ),
  ReferenceCity(
    name: 'Jakarta',
    latitude: -6.2088,
    longitude: 106.8456,
    timeZoneId: 'Asia/Jakarta',
    countryCode: 'ID',
    note: 'Southeast Asia, southern hemisphere',
  ),
  ReferenceCity(
    name: 'Singapore',
    latitude: 1.3521,
    longitude: 103.8198,
    timeZoneId: 'Asia/Singapore',
    countryCode: 'SG',
    note: 'Equator',
  ),
  ReferenceCity(
    name: 'Kuala Lumpur',
    latitude: 3.139,
    longitude: 101.6869,
    timeZoneId: 'Asia/Kuala_Lumpur',
    countryCode: 'MY',
    note: 'Southeast Asia',
  ),
  ReferenceCity(
    name: 'London',
    latitude: 51.5074,
    longitude: -0.1278,
    timeZoneId: 'Europe/London',
    countryCode: 'GB',
    note: 'Europe; DST; above 48 degrees',
  ),
  ReferenceCity(
    name: 'Paris',
    latitude: 48.8566,
    longitude: 2.3522,
    timeZoneId: 'Europe/Paris',
    countryCode: 'FR',
    note: 'Europe; DST; UOIF',
  ),
  ReferenceCity(
    name: 'Oslo',
    latitude: 59.9139,
    longitude: 10.7522,
    timeZoneId: 'Europe/Oslo',
    countryCode: 'NO',
    note: 'High latitude; twilight never ends in summer',
  ),
  ReferenceCity(
    name: 'Reykjavik',
    latitude: 64.1466,
    longitude: -21.9426,
    timeZoneId: 'Atlantic/Reykjavik',
    countryCode: 'IS',
    note: 'Very high latitude; no DST',
  ),
  ReferenceCity(
    name: 'Tromso',
    latitude: 69.6492,
    longitude: 18.9553,
    timeZoneId: 'Europe/Oslo',
    countryCode: 'NO',
    note: 'Polar day and polar night',
  ),
  ReferenceCity(
    name: 'New York',
    latitude: 40.7128,
    longitude: -74.006,
    timeZoneId: 'America/New_York',
    countryCode: 'US',
    note: 'North America; DST',
  ),
  ReferenceCity(
    name: 'Los Angeles',
    latitude: 34.0522,
    longitude: -118.2437,
    timeZoneId: 'America/Los_Angeles',
    countryCode: 'US',
    note: 'North America west',
  ),
  ReferenceCity(
    name: 'Sydney',
    latitude: -33.8688,
    longitude: 151.2093,
    timeZoneId: 'Australia/Sydney',
    countryCode: 'AU',
    note: 'Southern hemisphere; DST in the other season',
  ),
  ReferenceCity(
    name: 'Johannesburg',
    latitude: -26.2041,
    longitude: 28.0473,
    timeZoneId: 'Africa/Johannesburg',
    countryCode: 'ZA',
    note: 'Southern hemisphere, Africa',
  ),
  ReferenceCity(
    name: 'Casablanca',
    latitude: 33.5731,
    longitude: -7.5898,
    timeZoneId: 'Africa/Casablanca',
    countryCode: 'MA',
    note: 'Offset changes around Ramadan',
  ),
  ReferenceCity(
    name: 'Tehran',
    latitude: 35.6892,
    longitude: 51.389,
    timeZoneId: 'Asia/Tehran',
    countryCode: 'IR',
    note: 'Tehran and Jafari methods',
  ),
  ReferenceCity(
    name: 'Apia',
    latitude: -13.8333,
    longitude: -171.7667,
    timeZoneId: 'Pacific/Apia',
    countryCode: 'WS',
    note: 'Far side of the date line (UTC+13)',
  ),
];
