// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get aboutAttributionsTitle => 'Attributions';

  @override
  String get aboutCitiesHeading => 'City data';

  @override
  String get aboutContentHeading => 'Adhkar texts';

  @override
  String get aboutDescription =>
      'Prayer times, Azaan alerts and daily worship tools. Everything works offline.';

  @override
  String get aboutEntryHint => 'Licenses, sources and privacy';

  @override
  String get aboutFontsHeading => 'Fonts';

  @override
  String get aboutHijriHeading => 'Hijri calendar data';

  @override
  String get aboutLegalEnglishNote =>
      'The wording below is the license wording and stays in English.';

  @override
  String get aboutLicensesSubtitle =>
      'Licenses of the software this app is built with';

  @override
  String get aboutLicensesTitle => 'Open-source licenses';

  @override
  String get aboutNoDataCollected =>
      'Deen App collects no data. There are no accounts, no analytics and no ads. Your location stays on this device and is used only to work out prayer times and the Qibla direction.';

  @override
  String get aboutPrivacyHeading => 'Your privacy';

  @override
  String aboutPrivacyPolicyAddress(String address) {
    return 'Read the full policy at: $address';
  }

  @override
  String get aboutPrivacyPolicyPending =>
      'The full privacy policy will be published before release. It will say the same thing: the app collects no data.';

  @override
  String get aboutPrivacyPolicyTitle => 'Privacy policy';

  @override
  String get aboutTitle => 'About';

  @override
  String aboutVersion(String version) {
    return 'Version $version';
  }

  @override
  String get adhkarBookmarkAdd => 'Add bookmark';

  @override
  String get adhkarBookmarkRemove => 'Remove bookmark';

  @override
  String get adhkarBookmarksEmpty =>
      'You have not bookmarked anything yet. Use the bookmark button on an entry to save it here.';

  @override
  String get adhkarBookmarksTitle => 'Bookmarks';

  @override
  String get adhkarCollectionAfterPrayer => 'After prayer';

  @override
  String get adhkarCollectionBeforeSleep => 'Before sleep';

  @override
  String get adhkarCollectionEvening => 'Evening adhkar';

  @override
  String get adhkarCollectionMorning => 'Morning adhkar';

  @override
  String get adhkarCollectionOther => 'Other adhkar';

  @override
  String get adhkarCollectionWaking => 'On waking';

  @override
  String adhkarCountLabel(int done, int total) {
    return 'Tap to count: $done of $total';
  }

  @override
  String adhkarCreditEntry(int order, String reference) {
    return 'Entry $order: $reference';
  }

  @override
  String adhkarCreditReviewer(String reviewer, String date) {
    return 'Reviewed by $reviewer on $date.';
  }

  @override
  String adhkarCreditSource(String source, String license) {
    return 'Source: $source. License: $license.';
  }

  @override
  String adhkarCreditsCount(int count) {
    return 'Texts listed: $count';
  }

  @override
  String get adhkarCreditsEmpty =>
      'This version of the app includes no adhkar texts, so there are no sources to list yet.';

  @override
  String get adhkarCreditsIntro =>
      'Every text lists where it comes from, its license and who reviewed it.';

  @override
  String get adhkarCreditsTitle => 'Content sources and reviewers';

  @override
  String get adhkarEmptyBody =>
      'This version of the app does not include adhkar texts yet. They will be added only after their sources are licensed and a scholar has reviewed them.';

  @override
  String get adhkarEmptyTitle => 'Adhkar are not available yet';

  @override
  String adhkarEntryCount(int count) {
    return 'Entries: $count';
  }

  @override
  String get adhkarEntryDone => 'Done';

  @override
  String get adhkarEntryHint => 'Daily remembrances, bookmarks and reminders';

  @override
  String get adhkarLoadError => 'The adhkar could not be loaded.';

  @override
  String get adhkarNext => 'Next entry';

  @override
  String get adhkarNotFound => 'This collection is not available.';

  @override
  String adhkarPosition(int position, int total) {
    return 'Entry $position of $total';
  }

  @override
  String get adhkarPrevious => 'Previous entry';

  @override
  String adhkarProgressLabel(int done, int total) {
    return '$done of $total entries complete';
  }

  @override
  String adhkarReminderAfter(int minutes, String prayer) {
    return '$minutes min after $prayer';
  }

  @override
  String get adhkarReminderAnchor => 'Time it from';

  @override
  String adhkarReminderAt(String prayer) {
    return 'At $prayer time';
  }

  @override
  String adhkarReminderBefore(int minutes, String prayer) {
    return '$minutes min before $prayer';
  }

  @override
  String get adhkarReminderEarlier => '5 minutes earlier';

  @override
  String get adhkarReminderEnable => 'Remind me';

  @override
  String get adhkarReminderEvening => 'Evening reminder';

  @override
  String get adhkarReminderFajrOnly => 'Morning reminders follow Fajr.';

  @override
  String get adhkarReminderLater => '5 minutes later';

  @override
  String get adhkarReminderMorning => 'Morning reminder';

  @override
  String get adhkarReminderNote =>
      'Reminders are notifications on this device. They follow your prayer times, so they move with your location and calculation method.';

  @override
  String get adhkarReminderSaveError => 'The reminder could not be saved.';

  @override
  String get adhkarRemindersTitle => 'Adhkar reminders';

  @override
  String adhkarRepeatLabel(int count) {
    return 'Repetitions: $count';
  }

  @override
  String get adhkarSessionComplete => 'Session complete';

  @override
  String adhkarSourceLabel(String reference) {
    return 'Source: $reference';
  }

  @override
  String get adhkarStartAgain => 'Start again';

  @override
  String get adhkarTitle => 'Adhkar';

  @override
  String get adhkarTranslationFallbackHeading =>
      'Translation (English; not available in your language yet)';

  @override
  String get adhkarTranslationHeading => 'Translation';

  @override
  String get adhkarTransliterationHeading => 'Transliteration';

  @override
  String get adhkarUndo => 'Undo last count';

  @override
  String get alertAudioIntro =>
      'Where the Azaan plays when headphones or a Bluetooth device are connected. Without them it plays on the speaker.';

  @override
  String get alertAudioTitle => 'Audio output';

  @override
  String get alertCauseAppNotRun => 'The app had not been opened.';

  @override
  String get alertCauseBatteryRestricted =>
      'Battery saving may have stopped it. Check the battery settings.';

  @override
  String get alertCauseCallInProgress => 'A phone call was in progress.';

  @override
  String get alertCauseExactAlarmDenied =>
      'Exact alarms are off, so Android may have delayed it.';

  @override
  String get alertCauseFgsBlocked =>
      'Android did not let the app start the Azaan, so a notification tone was used.';

  @override
  String get alertCauseNotificationDenied => 'Notifications were turned off.';

  @override
  String get alertCauseQuietHours => 'Silenced by quiet hours.';

  @override
  String get alertCauseScheduleEnded =>
      'The scheduled alerts ran out because the app was not opened for a long time. Opening it renewed them.';

  @override
  String get alertCauseSilentMode => 'The phone was on silent.';

  @override
  String get alertCauseUnknown => 'The reason is not known.';

  @override
  String get alertExactBody =>
      'To sound at the exact prayer time, Android needs the “Alarms & reminders” permission for Deen App. Without it, alerts still arrive but may be a few minutes late.';

  @override
  String get alertExactCheck => 'I changed it, check again';

  @override
  String get alertExactGranted => 'Exact alarms are on.';

  @override
  String get alertExactInexact =>
      'Alerts will still arrive, but timing may be less precise. You can change this later in the Reliability check.';

  @override
  String get alertExactOpen => 'Open alarm settings';

  @override
  String get alertExactSkip => 'Continue without it';

  @override
  String get alertExactTitle => 'Allow exact alarms?';

  @override
  String get alertIgnoreQuietHours => 'Ignore quiet hours';

  @override
  String get alertIgnoreQuietHoursHint =>
      'Keep this alert audible even inside quiet hours.';

  @override
  String get alertLoudAndroidOnly =>
      'Loud mode is available on Android only. On iPhone the silent switch mutes the notification sound; tapping the notification still plays the full Azaan.';

  @override
  String get alertLoudIntro =>
      'Off by default. When on for a prayer, the Azaan sounds even if the phone is on silent. Deen App never changes your system volume unless you choose this.';

  @override
  String alertLoudSwitch(String prayer) {
    return 'Loud mode for $prayer';
  }

  @override
  String get alertLoudTitle => 'Loud mode';

  @override
  String get alertMissedDismiss => 'Dismiss';

  @override
  String alertMissedLine(String when, String cause) {
    return '$when: $cause';
  }

  @override
  String alertMissedMore(int count) {
    return 'and $count more';
  }

  @override
  String get alertMissedOpenCheck => 'Open Reliability check';

  @override
  String get alertMissedPossibly =>
      'iPhone cannot confirm delivery, so this one is only possibly missed.';

  @override
  String get alertMissedTitle => 'An alert may not have sounded';

  @override
  String get alertMissedTitleMany => 'Some alerts may not have sounded';

  @override
  String get alertNotifAdhkarEveningBody =>
      'A good time for your evening remembrance.';

  @override
  String get alertNotifAdhkarEveningTitle => 'Evening adhkar';

  @override
  String get alertNotifAdhkarMorningBody =>
      'A good time for your morning remembrance.';

  @override
  String get alertNotifAdhkarMorningTitle => 'Morning adhkar';

  @override
  String alertNotifPrayerBody(String prayer) {
    return 'It is time for $prayer.';
  }

  @override
  String alertNotifPrayerTitle(String prayer) {
    return '$prayer prayer';
  }

  @override
  String alertNotifPreBody(String prayer) {
    return 'Get ready for the $prayer prayer.';
  }

  @override
  String alertNotifPreTitle(String prayer, int minutes) {
    return '$prayer in $minutes min';
  }

  @override
  String get alertNotifRenewalBody =>
      'Your scheduled alerts end soon. Open the app once and they are renewed.';

  @override
  String get alertNotifRenewalTitle => 'Open Deen App to keep your alerts on';

  @override
  String get alertNotifStopLabel => 'Stop';

  @override
  String alertNotifSuhoorBody(int minutes) {
    return 'Fajr is in $minutes min.';
  }

  @override
  String get alertNotifSuhoorTitle => 'Suhoor reminder';

  @override
  String get alertOptionsTile => 'More alert options';

  @override
  String get alertOptionsTileHint =>
      'Loud mode, quiet hours, reminders and audio output';

  @override
  String get alertOptionsTitle => 'Alert options';

  @override
  String get alertOutputBluetooth => 'Bluetooth';

  @override
  String get alertOutputHeadphones => 'Headphones';

  @override
  String get alertOutputSpeaker => 'Speaker';

  @override
  String get alertPreviewFailed => 'This recording could not be played.';

  @override
  String alertPreviewPlay(String name) {
    return 'Play $name';
  }

  @override
  String get alertPreviewStop => 'Stop preview';

  @override
  String get alertQuietEnd => 'Ends at';

  @override
  String get alertQuietIntro =>
      'Alerts that would make a sound inside quiet hours become silent notifications, unless a prayer is set to ignore quiet hours.';

  @override
  String alertQuietRange(String start, String end) {
    return 'Quiet hours $start to $end';
  }

  @override
  String get alertQuietStart => 'Starts at';

  @override
  String get alertQuietSwitch => 'Use quiet hours';

  @override
  String get alertQuietTitle => 'Quiet hours';

  @override
  String alertReminderFor(String prayer) {
    return 'Reminder for $prayer';
  }

  @override
  String get alertReminderIntro =>
      'A reminder is never a full Azaan. It uses a short tone at most.';

  @override
  String alertReminderMinutes(int minutes) {
    return '$minutes min before';
  }

  @override
  String get alertReminderNone => 'No reminder';

  @override
  String alertReminderSummary(int minutes) {
    return 'Reminder $minutes min before';
  }

  @override
  String get alertReminderTitle => 'Reminder before each prayer';

  @override
  String get alertSaveFailed =>
      'This choice could not be saved. Please try again.';

  @override
  String get alertSettingsIntro => 'Choose what happens at each prayer time.';

  @override
  String get alertSettingsTitle => 'Prayer alerts';

  @override
  String get alertSilentSwitchBody =>
      'When your iPhone\'s silent switch is on, the sound of a notification is muted. Tapping the notification still plays the full Azaan. You can also choose vibration instead.';

  @override
  String get alertSilentSwitchGotIt => 'Got it';

  @override
  String get alertSilentSwitchTitle => 'About the silent switch';

  @override
  String get alertSilentSwitchVibrate => 'Use vibration for my alerts';

  @override
  String get alertSuhoorIntro =>
      'During Ramadan, a reminder before Fajr so you can eat in time.';

  @override
  String alertSuhoorMinutes(int minutes) {
    return '$minutes min before Fajr';
  }

  @override
  String get alertSuhoorSwitch => 'Remind me before suhoor ends';

  @override
  String get alertSuhoorTitle => 'Suhoor reminder';

  @override
  String get alertTypeFullAzaan => 'Full Azaan';

  @override
  String alertTypeGroupLabel(String prayer) {
    return 'Alert for $prayer';
  }

  @override
  String get alertTypeOff => 'Off';

  @override
  String get alertTypeShortTone => 'Short tone';

  @override
  String get alertTypeSilent => 'Silent notification';

  @override
  String get alertTypeVibrate => 'Vibrate';

  @override
  String get alertVariantFajr => 'Fajr version';

  @override
  String get alertVariantFajrHint =>
      'Includes “as-salatu khayrun min an-nawm”. Played at Fajr when Standard is chosen.';

  @override
  String get alertVariantShia => 'Shia wording';

  @override
  String get alertVariantShiaHint =>
      'The call to prayer with Shia wording. Played at all five prayers when chosen.';

  @override
  String get alertVariantStandard => 'Standard';

  @override
  String get alertVariantStandardHint =>
      'The usual call to prayer. Fajr uses the Fajr recording.';

  @override
  String alertVoiceForPrayer(String prayer) {
    return 'For $prayer';
  }

  @override
  String get alertVoiceIntro =>
      'Each voice has three recordings. Tap play to hear one before you choose.';

  @override
  String alertVoiceName(int number) {
    return 'Voice $number';
  }

  @override
  String get alertVoiceSelected => 'Selected';

  @override
  String get alertVoiceTile => 'Voice';

  @override
  String alertVoiceTileValue(String voice, String variant) {
    return '$voice, $variant';
  }

  @override
  String get alertVoiceTitle => 'Choose a voice';

  @override
  String get alertVolumeKeep => 'Keep my current volume';

  @override
  String get alertVolumeRamp => 'Gentle ramp';

  @override
  String get alertVolumeRampHint =>
      'Starts quiet and gets louder over a few seconds.';

  @override
  String get appTitle => 'Deen App';

  @override
  String get asrHanafiBody =>
      'Asr starts when an object\'s shadow is twice as long as the object, so Asr begins later (used by the Hanafi school).';

  @override
  String get asrHanafiTitle => 'Hanafi';

  @override
  String get asrStandardBody =>
      'Asr starts when an object\'s shadow is as long as the object itself (used by the Shafi\'i, Maliki and Hanbali schools).';

  @override
  String get asrStandardTitle => 'Standard';

  @override
  String detailHijriAdjusted(String days) {
    return 'Includes your adjustment of $days days (Umm al-Qura calendar).';
  }

  @override
  String get detailHijriDefault => 'Umm al-Qura calendar.';

  @override
  String get detailHijriTitle => 'Hijri date';

  @override
  String get detailHijriUnavailable => 'The Hijri date is not available yet.';

  @override
  String detailHijriValue(String day, String month, String year) {
    return '$day $month $year AH';
  }

  @override
  String get detailImsak => 'Imsak';

  @override
  String get detailLastThird => 'Last third of the night';

  @override
  String get detailMidnight => 'Midnight';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get highLatAngleBody =>
      'Fajr and Isha use a share of the night equal to the twilight angle divided by 60.';

  @override
  String get highLatAngleTitle => 'Angle-based';

  @override
  String highLatApplied(String rule) {
    return 'Fajr and Isha were estimated with the “$rule” rule because your latitude is above 48 degrees, where twilight may not end. You can change the rule in prayer settings.';
  }

  @override
  String get highLatMiddleBody =>
      'The night is split in half: Isha comes no later than the middle of the night and Fajr no earlier.';

  @override
  String get highLatMiddleTitle => 'Middle of the night';

  @override
  String get highLatSeventhBody =>
      'The night is divided into seven parts: Isha is at most one part after sunset and Fajr one part before sunrise.';

  @override
  String get highLatSeventhTitle => 'Seventh of the night';

  @override
  String get hijriMonth1 => 'Muharram';

  @override
  String get hijriMonth10 => 'Shawwal';

  @override
  String get hijriMonth11 => 'Dhu al-Qi\'dah';

  @override
  String get hijriMonth12 => 'Dhu al-Hijjah';

  @override
  String get hijriMonth2 => 'Safar';

  @override
  String get hijriMonth3 => 'Rabi\' al-awwal';

  @override
  String get hijriMonth4 => 'Rabi\' al-thani';

  @override
  String get hijriMonth5 => 'Jumada al-ula';

  @override
  String get hijriMonth6 => 'Jumada al-thani';

  @override
  String get hijriMonth7 => 'Rajab';

  @override
  String get hijriMonth8 => 'Sha\'ban';

  @override
  String get hijriMonth9 => 'Ramadan';

  @override
  String get homeBackToToday => 'Back to today';

  @override
  String get homeBannerDismiss => 'Dismiss';

  @override
  String get homeChooseLocation => 'Choose location';

  @override
  String get homeClockBeforeBuild =>
      'Your phone\'s date looks wrong: it is earlier than this version of the app. Prayer times and alerts may be wrong. Please check Date and time in your phone\'s settings.';

  @override
  String get homeClockDrifted =>
      'Your phone\'s clock was changed. If the time is wrong, prayer times and alerts may be wrong. Please check Date and time in your phone\'s settings.';

  @override
  String get homeClockMovedBack =>
      'Your phone\'s clock was set back. If the time is wrong, prayer times and alerts may be wrong. Please check Date and time in your phone\'s settings.';

  @override
  String homeCountdownSemantics(String prayer, int hours, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours hours',
      one: '1 hour',
    );
    String _temp1 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes',
      one: '1 minute',
    );
    return '$prayer in $_temp0 and $_temp1';
  }

  @override
  String get homeError =>
      'Prayer times could not be calculated. Check the location and try again.';

  @override
  String get homeMoreTimes => 'More times';

  @override
  String get homeNextBadge => 'Next';

  @override
  String get homeNextDay => 'Next day';

  @override
  String get homeNoLocation => 'Choose a location to see prayer times.';

  @override
  String get homePreviousDay => 'Previous day';

  @override
  String homeRegionSuggestion(String method) {
    return 'This region usually uses $method. Your chosen method stays as it is.';
  }

  @override
  String homeRegionSuggestionGeneral(String method) {
    return 'No regional default exists for this location. $method is a general choice. Your chosen method stays as it is.';
  }

  @override
  String homeRegionSuggestionSwitch(String method) {
    return 'Switch to $method';
  }

  @override
  String get homeTimeNotAvailable => 'Does not occur today';

  @override
  String homeTimeSemantics(String prayer, String time) {
    return '$prayer at $time';
  }

  @override
  String get homeTitle => 'Prayer times';

  @override
  String get homeToday => 'Today';

  @override
  String get homeTzRulesNotice =>
      'Time-zone rules may have changed. Please update the app. Until then, times follow your phone\'s rules.';

  @override
  String get languageNameAr => 'العربية';

  @override
  String get languageNameEn => 'English';

  @override
  String get languageNameId => 'Bahasa Indonesia';

  @override
  String get languageNameUr => 'اردو';

  @override
  String get languageSettingsTitle => 'Language';

  @override
  String get loading => 'Loading';

  @override
  String locationSettingsCurrent(String name) {
    return 'Current location: $name';
  }

  @override
  String get locationSettingsNone => 'No location is saved yet.';

  @override
  String get locationSettingsSaved => 'Location saved. Alerts will be updated.';

  @override
  String get locationSettingsTitle => 'Location';

  @override
  String get methodDiyanet => 'Turkey (Diyanet)';

  @override
  String get methodEgypt => 'Egyptian General Authority of Survey';

  @override
  String get methodFranceUoif => 'France (UOIF)';

  @override
  String get methodGulf => 'Gulf Region';

  @override
  String get methodIsna => 'ISNA (North America)';

  @override
  String get methodJafari => 'Shia Ithna-Ashari (Jafari)';

  @override
  String get methodKarachi => 'University of Islamic Sciences, Karachi';

  @override
  String get methodKuwait => 'Kuwait';

  @override
  String get methodMoonsightingCommittee => 'Moonsighting Committee';

  @override
  String get methodMuslimWorldLeague => 'Muslim World League';

  @override
  String get methodQatar => 'Qatar';

  @override
  String get methodSingapore => 'Singapore (MUIS)';

  @override
  String get methodTehran => 'Institute of Geophysics, University of Tehran';

  @override
  String get methodUmmAlQura => 'Umm al-Qura (Makkah)';

  @override
  String get nextPrayerLabel => 'Next prayer';

  @override
  String get oemBrandHuawei => 'Huawei, Honor';

  @override
  String get oemBrandOneplus => 'OnePlus';

  @override
  String get oemBrandOppo => 'Oppo, realme';

  @override
  String get oemBrandOther => 'Another brand';

  @override
  String get oemBrandSamsung => 'Samsung';

  @override
  String get oemBrandVivo => 'Vivo, iQOO';

  @override
  String get oemBrandXiaomi => 'Xiaomi, Redmi, POCO';

  @override
  String get permissionBannerAction => 'Fix in settings';

  @override
  String get permissionBannerAlerts =>
      'Notifications are off. Prayer alerts will not appear.';

  @override
  String get permissionBannerExact =>
      'Exact alarms are off. Alerts may be a few minutes late.';

  @override
  String get permissionBannerLocation =>
      'Location is off. Times use your saved city.';

  @override
  String get prayerAsr => 'Asr';

  @override
  String get prayerDhuhr => 'Dhuhr';

  @override
  String get prayerFajr => 'Fajr';

  @override
  String get prayerIsha => 'Isha';

  @override
  String get prayerJumuah => 'Jumu\'ah';

  @override
  String get prayerMaghrib => 'Maghrib';

  @override
  String get prayerSettingsHighLatIntro =>
      'Above 48 degrees of latitude, twilight may not end in summer. Choose how Fajr and Isha are estimated then.';

  @override
  String get prayerSettingsHighLatTitle => 'High latitudes';

  @override
  String get prayerSettingsHijriLess => 'Move the Hijri date one day back';

  @override
  String get prayerSettingsHijriMore => 'Move the Hijri date one day forward';

  @override
  String get prayerSettingsHijriTitle => 'Hijri date adjustment (days)';

  @override
  String prayerSettingsHijriValue(String value) {
    return '$value days';
  }

  @override
  String get prayerSettingsNoLocation =>
      'Choose a location first. Prayer settings apply to your saved location.';

  @override
  String prayerSettingsOffsetLabel(String prayer) {
    return '$prayer adjustment';
  }

  @override
  String prayerSettingsOffsetLess(String prayer) {
    return 'Subtract one minute from $prayer';
  }

  @override
  String prayerSettingsOffsetMore(String prayer) {
    return 'Add one minute to $prayer';
  }

  @override
  String prayerSettingsOffsetValue(String value) {
    return '$value min';
  }

  @override
  String get prayerSettingsOffsetsIntro =>
      'Add or remove up to 60 minutes for any prayer. This applies everywhere, including alerts.';

  @override
  String get prayerSettingsOffsetsTitle => 'Adjust times';

  @override
  String get prayerSettingsTitle => 'Prayer settings';

  @override
  String get prayerSunrise => 'Sunrise';

  @override
  String get qiblaAccuracyHigh => 'High';

  @override
  String qiblaAccuracyLabel(String level) {
    return 'Compass accuracy: $level';
  }

  @override
  String get qiblaAccuracyLow => 'Low';

  @override
  String get qiblaAccuracyMedium => 'Medium';

  @override
  String get qiblaAccuracyUnreliable => 'Unreliable';

  @override
  String get qiblaArrowSemantics => 'Compass arrow';

  @override
  String get qiblaAtHaram =>
      'You are at the Haram in Makkah. Face the Kaaba directly.';

  @override
  String qiblaBearingFromPlace(String place, String description) {
    return 'Qibla from $place: $description';
  }

  @override
  String get qiblaCalibrationPrompt =>
      'Calibrate your compass. Move your phone in a figure eight a few times, away from metal and magnets.';

  @override
  String get qiblaCompassError =>
      'The compass could not be started. The direction is shown in degrees instead.';

  @override
  String qiblaDirectionDescription(int degrees, String direction) {
    return '$degrees degrees, $direction';
  }

  @override
  String get qiblaDirectionEast => 'east';

  @override
  String get qiblaDirectionNorth => 'north';

  @override
  String get qiblaDirectionNortheast => 'northeast';

  @override
  String get qiblaDirectionNorthwest => 'northwest';

  @override
  String get qiblaDirectionSouth => 'south';

  @override
  String get qiblaDirectionSoutheast => 'southeast';

  @override
  String get qiblaDirectionSouthwest => 'southwest';

  @override
  String get qiblaDirectionWest => 'west';

  @override
  String qiblaDistanceToKaaba(int km) {
    return '$km km to the Kaaba';
  }

  @override
  String get qiblaEntryHint => 'Find the direction of the Kaaba';

  @override
  String get qiblaFacingQibla => 'You are facing the Qibla';

  @override
  String get qiblaInterferenceWarning =>
      'Magnetic interference nearby. Move away from metal, speakers, magnets and electronics, then check again. The arrow may be wrong until then.';

  @override
  String get qiblaMagneticNorthNote =>
      'The compass is using magnetic north. A small error is possible.';

  @override
  String get qiblaNoCompassInstructions =>
      'Use the direction above. Find north with a map, a compass, or the sun (it rises in the east and sets in the west), then turn clockwise from north by the number of degrees shown.';

  @override
  String get qiblaNoCompassTitle => 'No compass on this device';

  @override
  String get qiblaNoLocation =>
      'Set your location first so the Qibla direction can be worked out.';

  @override
  String get qiblaNorthReference => 'Measured clockwise from true north';

  @override
  String get qiblaStartingCompass => 'Starting the compass';

  @override
  String get qiblaTitle => 'Qibla';

  @override
  String get qiblaTurnHint => 'Turn until the arrow points straight up';

  @override
  String qiblaTurnLeft(int degrees) {
    return 'Turn $degrees degrees to the left';
  }

  @override
  String qiblaTurnRight(int degrees) {
    return 'Turn $degrees degrees to the right';
  }

  @override
  String get reliabilityAllGood => 'Everything looks good.';

  @override
  String get reliabilityBattery => 'Battery optimization (Android)';

  @override
  String get reliabilityBatteryFix =>
      'On some phones, battery saving can stop alerts. Open the battery settings and let Deen App run in the background.';

  @override
  String get reliabilityBatteryOk => 'Deen App is not restricted.';

  @override
  String get reliabilityBatteryOpen => 'Open battery settings';

  @override
  String get reliabilityCheckHint => 'Check that your alerts will fire';

  @override
  String get reliabilityCheckTitle => 'Reliability check';

  @override
  String get reliabilityErrorBudget =>
      'There are more alerts than this phone can hold, so the later ones were left out until you open the app again.';

  @override
  String get reliabilityErrorExactDenied =>
      'Exact alarms are not allowed, so timing may be less precise.';

  @override
  String get reliabilityErrorInvalid =>
      'The phone could not accept this alert.';

  @override
  String get reliabilityErrorPermissionDenied =>
      'Notifications are not allowed.';

  @override
  String get reliabilityErrorPlatform => 'The alert system did not respond.';

  @override
  String get reliabilityErrorServiceBlocked =>
      'Android blocked the Azaan sound from starting. A notification tone is used instead.';

  @override
  String get reliabilityExact => 'Exact alarms (Android)';

  @override
  String get reliabilityExactFix =>
      'Exact alarms are off, so alerts may be a few minutes late. Allow “Alarms & reminders” for Deen App.';

  @override
  String get reliabilityExactOpen => 'Open alarm settings';

  @override
  String get reliabilityFlagInexact => 'Timing may be a few minutes late';

  @override
  String get reliabilityFlagSilenced => 'Silenced by quiet hours';

  @override
  String get reliabilityIntro =>
      'This screen shows whether your alerts will fire, and how to fix anything that could stop them.';

  @override
  String get reliabilityIosRefreshNote =>
      'On iPhone, alerts are refreshed each time you open the app. Open it every few days to keep them going.';

  @override
  String get reliabilityKindRenewal => 'Renewal notice';

  @override
  String reliabilityLastLine(String when, String result) {
    return '$when: $result';
  }

  @override
  String get reliabilityLastNone => 'No alert has fired yet.';

  @override
  String get reliabilityLastTitle => 'Last alert result';

  @override
  String get reliabilityLoadFailed =>
      'The check could not be completed. Please try again.';

  @override
  String get reliabilityNextNone => 'Nothing is scheduled.';

  @override
  String reliabilityNextRow(String title, String type, String when) {
    return '$title, $type, $when';
  }

  @override
  String get reliabilityNextTitle => 'Next 5 alerts';

  @override
  String get reliabilityNotifications => 'Notifications';

  @override
  String get reliabilityNotificationsAllow => 'Allow notifications';

  @override
  String get reliabilityNotificationsFix =>
      'Notifications are off, so alerts cannot appear. Allow notifications for Deen App.';

  @override
  String get reliabilityNotificationsSettings => 'Open notification settings';

  @override
  String get reliabilityPermissionsTitle => 'Permissions';

  @override
  String get reliabilityProblemsFound => 'Something needs your attention.';

  @override
  String reliabilityRebuildFailed(String reason) {
    return 'Your alerts could not be updated. $reason';
  }

  @override
  String get reliabilityRefresh => 'Check again';

  @override
  String reliabilityRegistered(int count) {
    return '$count alerts are registered with the phone.';
  }

  @override
  String get reliabilityResultAcknowledged => 'Stopped by you';

  @override
  String get reliabilityResultFailed => 'Failed';

  @override
  String get reliabilityResultFired => 'Delivered';

  @override
  String get reliabilityResultMissed => 'Missed';

  @override
  String get reliabilityResultPlanned => 'Waiting';

  @override
  String get reliabilityResultPlayed => 'Azaan played';

  @override
  String get reliabilityResultPossiblyMissed => 'Possibly missed';

  @override
  String get reliabilityResultSuppressed => 'Silenced';

  @override
  String get reliabilityRunsUntilHint =>
      'Open the app before this date to keep alerts going. It renews them every time.';

  @override
  String get reliabilityRunsUntilNone => 'No alerts are scheduled yet.';

  @override
  String get reliabilityRunsUntilTitle => 'Alerts run until';

  @override
  String get reliabilitySilentSwitchTip =>
      'If your iPhone\'s silent switch is on, notification sounds are muted. Tapping the notification plays the full Azaan.';

  @override
  String get reliabilitySound => 'Notification sound (iPhone)';

  @override
  String get reliabilitySoundFix =>
      'Sound is off in the notification settings, so alerts will be silent. Allow sound for Deen App.';

  @override
  String get reliabilityStateOff => 'Off';

  @override
  String get reliabilityStateOn => 'On';

  @override
  String get reliabilityTestButton => 'Send a test Azaan in 1 minute';

  @override
  String reliabilityTestFailed(String reason) {
    return 'The test could not be set. $reason';
  }

  @override
  String get reliabilityTestNeedsNotifications =>
      'Allow notifications first, then try again.';

  @override
  String reliabilityTestScheduled(String time) {
    return 'Test Azaan set for $time. Lock your phone and wait.';
  }

  @override
  String get reliabilityUnsupported =>
      'This device cannot schedule alerts, so there is nothing to check here.';

  @override
  String get settingsAppearanceHint => 'Theme, text size and contrast';

  @override
  String get settingsAppearanceNeedsSetup =>
      'Finish setup first. You can change the appearance once your prayer settings are saved.';

  @override
  String get settingsAppearanceTitle => 'Appearance';

  @override
  String get settingsDataHint => 'Export, import or delete';

  @override
  String get settingsDataTitle => 'Your data';

  @override
  String get settingsDeleteBody =>
      'Removes your settings, location, tasbih counts, bookmarks and alert history from this device, and cancels all scheduled alerts.';

  @override
  String get settingsDeleteCancel => 'Cancel';

  @override
  String get settingsDeleteConfirmAction => 'Delete everything';

  @override
  String get settingsDeleteConfirmBody =>
      'This removes everything the app stores on this device and cannot be undone. Settings files you saved or shared outside the app are not deleted and stay where you put them.';

  @override
  String get settingsDeleteConfirmTitle => 'Delete all data?';

  @override
  String get settingsDeleteDone => 'All data was deleted.';

  @override
  String get settingsDeletePartial =>
      'Some data could not be removed. Please try again.';

  @override
  String get settingsDeleteTitle => 'Delete all my data';

  @override
  String get settingsExportCancelled => 'Export cancelled.';

  @override
  String get settingsExportDone => 'The settings file is ready.';

  @override
  String get settingsExportFailed => 'The settings file could not be created.';

  @override
  String get settingsExportSave => 'Save settings file';

  @override
  String get settingsExportShare => 'Share settings file';

  @override
  String get settingsExportTitle => 'Export settings';

  @override
  String get settingsExportWarning =>
      'The file contains your saved location and your settings. Anyone who gets the file can see where you are. Share it only with people and places you trust.';

  @override
  String get settingsHighContrast => 'High contrast';

  @override
  String get settingsHighContrastHint =>
      'Stronger text and outline colors. Nothing in the app depends on color alone.';

  @override
  String get settingsImportBody =>
      'Choose a settings file exported from Deen App. It replaces the settings it contains. If the file has a problem, nothing changes.';

  @override
  String get settingsImportButton => 'Choose settings file';

  @override
  String get settingsImportDone => 'Settings imported.';

  @override
  String get settingsImportDoneLater =>
      'Settings imported. Alerts will be updated the next time the app opens.';

  @override
  String get settingsImportFailed =>
      'The settings could not be saved. Nothing was changed.';

  @override
  String settingsImportInvalid(String field) {
    return 'The file has a value that is missing or out of range ($field). Nothing was changed.';
  }

  @override
  String get settingsImportNewer =>
      'This file was made by a newer version of the app. Update the app to read it.';

  @override
  String get settingsImportNotSettings =>
      'This is not a Deen App settings file.';

  @override
  String get settingsImportTitle => 'Import settings';

  @override
  String get settingsImportUnreadable => 'The file could not be read.';

  @override
  String get settingsSaveError => 'This change could not be saved.';

  @override
  String get settingsTextSizeLabel => 'Text size';

  @override
  String get settingsTextSizeLarger => 'Larger text';

  @override
  String get settingsTextSizeSample =>
      'Sample text: this is how text looks at this size.';

  @override
  String get settingsTextSizeSmaller => 'Smaller text';

  @override
  String settingsTextSizeValue(int percent) {
    return '$percent%';
  }

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeLabel => 'Theme';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeSystem => 'Match device';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get setupAsrIntro =>
      'Choose the school you follow for the start of Asr. Standard is already selected.';

  @override
  String get setupAsrTitle => 'Asr prayer';

  @override
  String get setupBack => 'Back';

  @override
  String get setupBatteryBody =>
      'Some phones close apps in the background to save battery, which can delay or stop alerts. Choose your phone brand and follow the steps.';

  @override
  String get setupBatteryBrandLabel => 'Your phone brand';

  @override
  String get setupBatteryGuideUnavailable =>
      'The steps for this brand could not be loaded. Open the battery settings and allow Deen App to run in the background.';

  @override
  String get setupBatteryOpenSettings => 'Open battery settings';

  @override
  String setupBatteryStep(int number, String text) {
    return 'Step $number: $text';
  }

  @override
  String get setupBatteryTitle => 'Keep alerts reliable';

  @override
  String get setupExactBody =>
      'Android can ring your alert at the exact prayer time only if you allow exact alarms. Without it, alerts still arrive but can be a few minutes late.';

  @override
  String get setupExactCheck => 'I changed it, check again';

  @override
  String get setupExactContinue => 'Continue without it';

  @override
  String get setupExactDenied =>
      'Exact alarms are off. Alerts will still arrive but may be a few minutes late. The Reliability check shows this.';

  @override
  String get setupExactGranted => 'Exact alarms are allowed.';

  @override
  String get setupExactOpen => 'Open alarm settings';

  @override
  String get setupExactTitle => 'Exact alert timing';

  @override
  String get setupFinish => 'Finish setup';

  @override
  String get setupLanguageBody =>
      'You can change this at any time in settings.';

  @override
  String get setupLanguageTitle => 'Choose your language';

  @override
  String get setupLocationApproximate => 'Use my approximate location';

  @override
  String get setupLocationApproximateHint =>
      'Approximate rounds your position to about 10 km. Prayer times change by well under a minute.';

  @override
  String get setupLocationApproximateName => 'Approximate location';

  @override
  String get setupLocationCurrentName => 'Current location';

  @override
  String get setupLocationFinding => 'Finding your location…';

  @override
  String get setupLocationNeeded => 'Choose a location or a city to continue.';

  @override
  String get setupLocationOfflineNote =>
      'The city list is stored in the app, so searching works without internet. You can skip sharing your location and just pick a city.';

  @override
  String get setupLocationPrecise => 'Use my precise location';

  @override
  String get setupLocationPrivacy =>
      'Your location stays on this device. It is never sent anywhere, and it is only used to calculate prayer times.';

  @override
  String get setupLocationSearchEmpty =>
      'No city found. Check the spelling or try another name.';

  @override
  String get setupLocationSearchHint => 'City name';

  @override
  String get setupLocationSearchLabel => 'Or search for a city';

  @override
  String setupLocationSelected(String name) {
    return 'Selected: $name';
  }

  @override
  String get setupLocationTitle => 'Your location';

  @override
  String get setupMethodChange => 'You can choose a different method:';

  @override
  String get setupMethodGeneral =>
      'There is no regional default for your location, so the general Muslim World League method is suggested.';

  @override
  String setupMethodSuggested(String method) {
    return 'Suggested for your region: $method';
  }

  @override
  String get setupMethodTitle => 'Calculation method';

  @override
  String get setupNext => 'Next';

  @override
  String get setupNotNow => 'Not now';

  @override
  String get setupNotificationsAllow => 'Allow notifications';

  @override
  String get setupNotificationsBody =>
      'To remind you at prayer times, Deen App needs permission to show notifications. Alerts are made on your phone; nothing is sent over the internet.';

  @override
  String get setupNotificationsDenied =>
      'Notifications are off, so prayer alerts will not appear. You can allow them later in app settings.';

  @override
  String get setupNotificationsGranted => 'Notifications are allowed.';

  @override
  String get setupNotificationsTitle => 'Prayer alerts';

  @override
  String get setupOpenAppSettings => 'Open app settings';

  @override
  String get setupPrivacyNoData => 'Deen App collects no personal data.';

  @override
  String get setupPrivacyNoTracking =>
      'There are no accounts, no ads and no trackers, and the app works without an internet connection.';

  @override
  String get setupPrivacyOnDevice =>
      'Your location, settings and alert history stay on this phone.';

  @override
  String get setupPrivacyTitle => 'Your privacy';

  @override
  String get setupProblemLocationDenied =>
      'Location was not allowed. Pick a city from the list instead, or allow location in app settings.';

  @override
  String get setupProblemLocationTimeout =>
      'Your location could not be found in time. Try again, or pick a city from the list.';

  @override
  String get setupProblemLocationUnavailable =>
      'Location is not available on this phone right now. Pick a city from the list.';

  @override
  String get setupProblemSaveFailed =>
      'Your choice could not be saved. Please try again.';

  @override
  String get setupProblemZoneUnknown =>
      'Your phone did not report a time zone. Pick a city from the list.';

  @override
  String setupProgress(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get setupSummaryAlerts =>
      'Prayer alerts will not appear because notifications are off.';

  @override
  String get setupSummaryExact =>
      'Alerts may arrive a few minutes late because exact alarms are off.';

  @override
  String get setupSummaryLocation =>
      'Your phone\'s location is off, so times use the city you chose.';

  @override
  String get setupSummaryTitle => 'What will not work yet';

  @override
  String get setupSummaryWayBack =>
      'You can allow any of these later in app settings.';

  @override
  String get setupTitle => 'Set up Deen App';

  @override
  String get tasbihCancel => 'Cancel';

  @override
  String get tasbihCountHint => 'Adds one to the count';

  @override
  String tasbihCountLabel(int count, int target) {
    return 'Count: $count of $target';
  }

  @override
  String get tasbihEntryHint => 'Count your dhikr';

  @override
  String get tasbihHaptics => 'Vibrate on each count';

  @override
  String get tasbihHistoryEmpty =>
      'No counts yet. Your daily totals appear here.';

  @override
  String get tasbihHistoryTitle => 'History';

  @override
  String get tasbihKeepAwake => 'Keep the screen on';

  @override
  String get tasbihLock => 'Lock touches on the counter';

  @override
  String get tasbihLockHint =>
      'A stray touch will not add a count. The volume keys still count.';

  @override
  String get tasbihLockedMessage =>
      'Locked. Touches on the counter are ignored.';

  @override
  String tasbihOfTarget(int target) {
    return 'of $target';
  }

  @override
  String get tasbihOptionsTitle => 'Options';

  @override
  String get tasbihReset => 'Reset';

  @override
  String get tasbihResetBody =>
      'The count goes back to 0. Your daily totals are kept.';

  @override
  String get tasbihResetTitle => 'Reset the counter?';

  @override
  String tasbihRounds(int rounds) {
    return 'Rounds completed: $rounds';
  }

  @override
  String get tasbihSave => 'Save';

  @override
  String get tasbihSaveError => 'Could not save the count. Try again.';

  @override
  String get tasbihSound => 'Tap sound';

  @override
  String get tasbihTargetCustom => 'Custom';

  @override
  String get tasbihTargetCustomField => 'Target (1 to 100000)';

  @override
  String tasbihTargetCustomLabel(int target) {
    return 'Custom target: $target';
  }

  @override
  String get tasbihTargetCustomTitle => 'Custom target';

  @override
  String get tasbihTargetHeading => 'Target';

  @override
  String get tasbihTargetInvalid => 'Enter a whole number from 1 to 100000.';

  @override
  String tasbihTargetOptionLabel(int target) {
    return 'Target $target';
  }

  @override
  String tasbihTargetReached(int target) {
    return 'Target of $target reached';
  }

  @override
  String get tasbihTitle => 'Tasbih';

  @override
  String tasbihTodayTotal(int total) {
    return 'Today: $total';
  }

  @override
  String get tasbihUnlock => 'Hold to unlock';

  @override
  String get tasbihUnlockPressHint => 'Press and hold the button to unlock.';

  @override
  String get tasbihVolumeKeys => 'Count with the volume keys';

  @override
  String get tasbihVolumeKeysHint =>
      'While this screen is open the volume keys count instead of changing the volume.';
}
