import 'package:prayer_engine/prayer_engine.dart';

import '../../domain/entities/enums.dart';
import '../../l10n/generated/app_localizations.dart';

/// Localized names for the engine's enums. One place, so every screen names a
/// method or prayer the same way.
extension PrayerLabels on AppLocalizations {
  String prayerName(Prayer prayer, {bool jumuah = false}) {
    switch (prayer) {
      case Prayer.fajr:
        return prayerFajr;
      case Prayer.sunrise:
        return prayerSunrise;
      case Prayer.dhuhr:
        return jumuah ? prayerJumuah : prayerDhuhr;
      case Prayer.asr:
        return prayerAsr;
      case Prayer.maghrib:
        return prayerMaghrib;
      case Prayer.isha:
        return prayerIsha;
    }
  }

  String methodName(CalculationMethod method) {
    switch (method) {
      case CalculationMethod.muslimWorldLeague:
        return methodMuslimWorldLeague;
      case CalculationMethod.isna:
        return methodIsna;
      case CalculationMethod.egypt:
        return methodEgypt;
      case CalculationMethod.ummAlQura:
        return methodUmmAlQura;
      case CalculationMethod.karachi:
        return methodKarachi;
      case CalculationMethod.tehran:
        return methodTehran;
      case CalculationMethod.jafari:
        return methodJafari;
      case CalculationMethod.gulf:
        return methodGulf;
      case CalculationMethod.kuwait:
        return methodKuwait;
      case CalculationMethod.qatar:
        return methodQatar;
      case CalculationMethod.singapore:
        return methodSingapore;
      case CalculationMethod.diyanet:
        return methodDiyanet;
      case CalculationMethod.franceUoif:
        return methodFranceUoif;
      case CalculationMethod.moonsightingCommittee:
        return methodMoonsightingCommittee;
    }
  }

  String asrName(AsrMethod asr) =>
      asr == AsrMethod.standard ? asrStandardTitle : asrHanafiTitle;

  String asrDescription(AsrMethod asr) =>
      asr == AsrMethod.standard ? asrStandardBody : asrHanafiBody;

  String highLatitudeRuleName(HighLatitudeRule rule) {
    switch (rule) {
      case HighLatitudeRule.middleOfNight:
        return highLatMiddleTitle;
      case HighLatitudeRule.seventhOfNight:
        return highLatSeventhTitle;
      case HighLatitudeRule.angleBased:
        return highLatAngleTitle;
    }
  }

  String highLatitudeRuleDescription(HighLatitudeRule rule) {
    switch (rule) {
      case HighLatitudeRule.middleOfNight:
        return highLatMiddleBody;
      case HighLatitudeRule.seventhOfNight:
        return highLatSeventhBody;
      case HighLatitudeRule.angleBased:
        return highLatAngleBody;
    }
  }

  /// Name of a Hijri month, 1 to 12.
  String hijriMonthName(int month) {
    switch (month) {
      case 1:
        return hijriMonth1;
      case 2:
        return hijriMonth2;
      case 3:
        return hijriMonth3;
      case 4:
        return hijriMonth4;
      case 5:
        return hijriMonth5;
      case 6:
        return hijriMonth6;
      case 7:
        return hijriMonth7;
      case 8:
        return hijriMonth8;
      case 9:
        return hijriMonth9;
      case 10:
        return hijriMonth10;
      case 11:
        return hijriMonth11;
      default:
        return hijriMonth12;
    }
  }

  /// A language's own name, which is the same in every interface language.
  String languageName(AppLanguage language) {
    switch (language) {
      case AppLanguage.en:
        return languageNameEn;
      case AppLanguage.ar:
        return languageNameAr;
      case AppLanguage.ur:
        return languageNameUr;
      case AppLanguage.id:
        return languageNameId;
    }
  }
}
