import 'package:flutter/material.dart';

import '../../domain/adhkar/adhkar_content.dart';
import '../../domain/entities/enums.dart';
import '../../l10n/generated/app_localizations.dart';

/// The app language in effect for [context].
AppLanguage appLanguageOf(BuildContext context) {
  final code = Localizations.localeOf(context).languageCode;
  return AppLanguage.values.firstWhere(
    (l) => l.name == code,
    orElse: () => AppLanguage.en,
  );
}

/// The interface name of a collection kind.
String kindTitle(AppLocalizations l10n, AdhkarCollectionKind kind) {
  switch (kind) {
    case AdhkarCollectionKind.morning:
      return l10n.adhkarCollectionMorning;
    case AdhkarCollectionKind.evening:
      return l10n.adhkarCollectionEvening;
    case AdhkarCollectionKind.afterPrayer:
      return l10n.adhkarCollectionAfterPrayer;
    case AdhkarCollectionKind.beforeSleep:
      return l10n.adhkarCollectionBeforeSleep;
    case AdhkarCollectionKind.waking:
      return l10n.adhkarCollectionWaking;
    case AdhkarCollectionKind.other:
      return l10n.adhkarCollectionOther;
  }
}

/// The title from the pack in the user's language, else the interface name for
/// the collection's kind.
String collectionTitle(BuildContext context, AdhkarCollection collection) {
  return collection.titles[appLanguageOf(context)] ??
      kindTitle(AppLocalizations.of(context), collection.kind);
}

/// An icon that stands in for a collection kind. It never carries meaning
/// alone: the title is always shown beside it.
IconData kindIcon(AdhkarCollectionKind kind) {
  switch (kind) {
    case AdhkarCollectionKind.morning:
      return Icons.wb_sunny_outlined;
    case AdhkarCollectionKind.evening:
      return Icons.wb_twilight;
    case AdhkarCollectionKind.afterPrayer:
      return Icons.self_improvement;
    case AdhkarCollectionKind.beforeSleep:
      return Icons.bedtime_outlined;
    case AdhkarCollectionKind.waking:
      return Icons.alarm;
    case AdhkarCollectionKind.other:
      return Icons.menu_book_outlined;
  }
}
