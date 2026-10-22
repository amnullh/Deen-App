import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Formats a UTC instant as the local time of a place whose UTC offset is
/// [offset], in the user's language and 12 or 24 hour setting.
String formatLocalTime(BuildContext context, DateTime utc, Duration offset) {
  final local = utc.toUtc().add(offset);
  return MaterialLocalizations.of(context).formatTimeOfDay(
    TimeOfDay(hour: local.hour, minute: local.minute),
    alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
  );
}

/// A civil date `YYYY-MM-DD` as a full date in the user's language, such as
/// "Friday, October 23, 2026".
String formatLocalDate(BuildContext context, String localDate) {
  final parts = localDate.split('-').map(int.parse).toList();
  return MaterialLocalizations.of(context)
      .formatFullDate(DateTime(parts[0], parts[1], parts[2]));
}

/// A countdown as HH:MM:SS with the digits of [locale].
String formatCountdown(Duration remaining, String locale) {
  final two = NumberFormat('00', locale);
  final total = remaining.inSeconds < 0 ? 0 : remaining.inSeconds;
  final hours = total ~/ 3600;
  final minutes = (total % 3600) ~/ 60;
  final seconds = total % 60;
  return '${two.format(hours)}:${two.format(minutes)}:${two.format(seconds)}';
}

/// "+5", "-3" or "0" for an adjustment, with the digits of [locale].
String formatSigned(int value, String locale) {
  final digits = NumberFormat.decimalPattern(locale).format(value.abs());
  if (value > 0) return '+$digits';
  if (value < 0) return '-$digits';
  return digits;
}

/// A whole number with the digits of [locale] and no grouping, for years and
/// days.
String formatPlain(int value, String locale) =>
    NumberFormat('#', locale).format(value);
