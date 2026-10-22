import 'package:prayer_engine/prayer_engine.dart';

import '../entities/settings.dart';

/// A one-time offer to switch to the method usually used in the region the
/// user is now in (spec Clarifications: the chosen method is kept; the app only
/// suggests, once per new region).
class RegionSuggestion {
  const RegionSuggestion({
    required this.region,
    required this.suggested,
    required this.current,
  });

  final Region region;
  final CalculationMethod suggested;
  final CalculationMethod current;

  /// True when the region has no regional default and the suggestion is the
  /// general Muslim World League method, which the banner says plainly.
  bool get isGeneralDefault => region == Region.other;
}

/// The suggestion to show for [location], or null when there is none: the
/// region's method is already in use, or the user dismissed (or accepted) the
/// suggestion for this region before.
RegionSuggestion? regionSuggestionFor({
  required AppLocation location,
  required PrayerSettings settings,
}) {
  final region = location.region;
  if (settings.dismissedSuggestionRegions.contains(region)) return null;
  final suggested = suggestedMethodForRegion(region);
  if (suggested == settings.method) return null;
  return RegionSuggestion(
    region: region,
    suggested: suggested,
    current: settings.method,
  );
}

/// [settings] after the user dismissed [suggestion]: the method stays, and the
/// region is remembered so it is not offered again.
PrayerSettings dismissSuggestion(
  PrayerSettings settings,
  RegionSuggestion suggestion,
) {
  return settings.copyWith(
    dismissedSuggestionRegions: {
      ...settings.dismissedSuggestionRegions,
      suggestion.region,
    },
  );
}

/// [settings] after the user accepted [suggestion]: the region's method is used
/// and the region is remembered.
PrayerSettings acceptSuggestion(
  PrayerSettings settings,
  RegionSuggestion suggestion,
) {
  return dismissSuggestion(
    settings,
    suggestion,
  ).copyWith(method: suggestion.suggested);
}
