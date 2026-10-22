import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_id.dart';
import 'app_localizations_ur.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('id'),
    Locale('ur'),
  ];

  /// Heading of the attributions section.
  ///
  /// In en, this message translates to:
  /// **'Attributions'**
  String get aboutAttributionsTitle;

  /// Heading above the GeoNames attribution.
  ///
  /// In en, this message translates to:
  /// **'City data'**
  String get aboutCitiesHeading;

  /// Heading of the content sources section.
  ///
  /// In en, this message translates to:
  /// **'Adhkar texts'**
  String get aboutContentHeading;

  /// Short description of the app at the top of About.
  ///
  /// In en, this message translates to:
  /// **'Prayer times, Azaan alerts and daily worship tools. Everything works offline.'**
  String get aboutDescription;

  /// Hint under the About entry in settings.
  ///
  /// In en, this message translates to:
  /// **'Licenses, sources and privacy'**
  String get aboutEntryHint;

  /// Heading above the font attribution.
  ///
  /// In en, this message translates to:
  /// **'Fonts'**
  String get aboutFontsHeading;

  /// Heading above the Unicode notice.
  ///
  /// In en, this message translates to:
  /// **'Hijri calendar data'**
  String get aboutHijriHeading;

  /// Note before the English license wording.
  ///
  /// In en, this message translates to:
  /// **'The wording below is the license wording and stays in English.'**
  String get aboutLegalEnglishNote;

  /// Subtitle of the licenses entry.
  ///
  /// In en, this message translates to:
  /// **'Licenses of the software this app is built with'**
  String get aboutLicensesSubtitle;

  /// Entry that opens the list of software licenses.
  ///
  /// In en, this message translates to:
  /// **'Open-source licenses'**
  String get aboutLicensesTitle;

  /// The no-data-collected statement.
  ///
  /// In en, this message translates to:
  /// **'Deen App collects no data. There are no accounts, no analytics and no ads. Your location stays on this device and is used only to work out prayer times and the Qibla direction.'**
  String get aboutNoDataCollected;

  /// Heading of the privacy statement.
  ///
  /// In en, this message translates to:
  /// **'Your privacy'**
  String get aboutPrivacyHeading;

  /// Shown when the privacy policy address is known.
  ///
  /// In en, this message translates to:
  /// **'Read the full policy at: {address}'**
  String aboutPrivacyPolicyAddress(String address);

  /// Placeholder shown until the privacy policy address is known.
  ///
  /// In en, this message translates to:
  /// **'The full privacy policy will be published before release. It will say the same thing: the app collects no data.'**
  String get aboutPrivacyPolicyPending;

  /// Heading of the privacy policy section.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get aboutPrivacyPolicyTitle;

  /// Title of the About screen.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTitle;

  /// App version.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String aboutVersion(String version);

  /// Tooltip and screen-reader label of the bookmark button when the entry is not bookmarked.
  ///
  /// In en, this message translates to:
  /// **'Add bookmark'**
  String get adhkarBookmarkAdd;

  /// Tooltip and screen-reader label of the bookmark button when the entry is bookmarked.
  ///
  /// In en, this message translates to:
  /// **'Remove bookmark'**
  String get adhkarBookmarkRemove;

  /// Empty state of the bookmarks screen.
  ///
  /// In en, this message translates to:
  /// **'You have not bookmarked anything yet. Use the bookmark button on an entry to save it here.'**
  String get adhkarBookmarksEmpty;

  /// Title of the bookmarks screen and its button.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get adhkarBookmarksTitle;

  /// Collection name.
  ///
  /// In en, this message translates to:
  /// **'After prayer'**
  String get adhkarCollectionAfterPrayer;

  /// Collection name.
  ///
  /// In en, this message translates to:
  /// **'Before sleep'**
  String get adhkarCollectionBeforeSleep;

  /// Collection name.
  ///
  /// In en, this message translates to:
  /// **'Evening adhkar'**
  String get adhkarCollectionEvening;

  /// Collection name.
  ///
  /// In en, this message translates to:
  /// **'Morning adhkar'**
  String get adhkarCollectionMorning;

  /// Collection name.
  ///
  /// In en, this message translates to:
  /// **'Other adhkar'**
  String get adhkarCollectionOther;

  /// Collection name.
  ///
  /// In en, this message translates to:
  /// **'On waking'**
  String get adhkarCollectionWaking;

  /// Text and screen-reader label of the large counting button.
  ///
  /// In en, this message translates to:
  /// **'Tap to count: {done} of {total}'**
  String adhkarCountLabel(int done, int total);

  /// Heading of one text in the credits list.
  ///
  /// In en, this message translates to:
  /// **'Entry {order}: {reference}'**
  String adhkarCreditEntry(int order, String reference);

  /// Reviewer and review date of one text.
  ///
  /// In en, this message translates to:
  /// **'Reviewed by {reviewer} on {date}.'**
  String adhkarCreditReviewer(String reviewer, String date);

  /// Source and license of one text.
  ///
  /// In en, this message translates to:
  /// **'Source: {source}. License: {license}.'**
  String adhkarCreditSource(String source, String license);

  /// Subtitle of the credits entry in About.
  ///
  /// In en, this message translates to:
  /// **'Texts listed: {count}'**
  String adhkarCreditsCount(int count);

  /// Empty state of the credits screen.
  ///
  /// In en, this message translates to:
  /// **'This version of the app includes no adhkar texts, so there are no sources to list yet.'**
  String get adhkarCreditsEmpty;

  /// Introduction on the credits screen.
  ///
  /// In en, this message translates to:
  /// **'Every text lists where it comes from, its license and who reviewed it.'**
  String get adhkarCreditsIntro;

  /// Title of the credits screen and its entry in About.
  ///
  /// In en, this message translates to:
  /// **'Content sources and reviewers'**
  String get adhkarCreditsTitle;

  /// Explanation in the empty state; says why there is no adhkar content.
  ///
  /// In en, this message translates to:
  /// **'This version of the app does not include adhkar texts yet. They will be added only after their sources are licensed and a scholar has reviewed them.'**
  String get adhkarEmptyBody;

  /// Heading of the empty state shown while the content pack is empty.
  ///
  /// In en, this message translates to:
  /// **'Adhkar are not available yet'**
  String get adhkarEmptyTitle;

  /// Number of entries in a collection, shown under its name.
  ///
  /// In en, this message translates to:
  /// **'Entries: {count}'**
  String adhkarEntryCount(int count);

  /// Label of the counting button once the entry reached its repeat count.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get adhkarEntryDone;

  /// One-line hint under the adhkar entry on the home screen.
  ///
  /// In en, this message translates to:
  /// **'Daily remembrances, bookmarks and reminders'**
  String get adhkarEntryHint;

  /// Shown when the content pack fails to load.
  ///
  /// In en, this message translates to:
  /// **'The adhkar could not be loaded.'**
  String get adhkarLoadError;

  /// Tooltip of the next button.
  ///
  /// In en, this message translates to:
  /// **'Next entry'**
  String get adhkarNext;

  /// Shown when a collection id is not in the pack.
  ///
  /// In en, this message translates to:
  /// **'This collection is not available.'**
  String get adhkarNotFound;

  /// Position of the shown entry in its collection.
  ///
  /// In en, this message translates to:
  /// **'Entry {position} of {total}'**
  String adhkarPosition(int position, int total);

  /// Tooltip of the previous button.
  ///
  /// In en, this message translates to:
  /// **'Previous entry'**
  String get adhkarPrevious;

  /// Progress through a session, shown above the entry and read by screen readers.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} entries complete'**
  String adhkarProgressLabel(int done, int total);

  /// Reminder timing, positive offset.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min after {prayer}'**
  String adhkarReminderAfter(int minutes, String prayer);

  /// Label above the choice of prayer a reminder follows.
  ///
  /// In en, this message translates to:
  /// **'Time it from'**
  String get adhkarReminderAnchor;

  /// Reminder timing, zero offset.
  ///
  /// In en, this message translates to:
  /// **'At {prayer} time'**
  String adhkarReminderAt(String prayer);

  /// Reminder timing, negative offset.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min before {prayer}'**
  String adhkarReminderBefore(int minutes, String prayer);

  /// Tooltip of the button that moves a reminder earlier.
  ///
  /// In en, this message translates to:
  /// **'5 minutes earlier'**
  String get adhkarReminderEarlier;

  /// Label of the on/off switch of a reminder.
  ///
  /// In en, this message translates to:
  /// **'Remind me'**
  String get adhkarReminderEnable;

  /// Heading of the evening reminder card.
  ///
  /// In en, this message translates to:
  /// **'Evening reminder'**
  String get adhkarReminderEvening;

  /// Explains that the morning reminder has a fixed anchor.
  ///
  /// In en, this message translates to:
  /// **'Morning reminders follow Fajr.'**
  String get adhkarReminderFajrOnly;

  /// Tooltip of the button that moves a reminder later.
  ///
  /// In en, this message translates to:
  /// **'5 minutes later'**
  String get adhkarReminderLater;

  /// Heading of the morning reminder card.
  ///
  /// In en, this message translates to:
  /// **'Morning reminder'**
  String get adhkarReminderMorning;

  /// Note at the bottom of the reminder settings.
  ///
  /// In en, this message translates to:
  /// **'Reminders are notifications on this device. They follow your prayer times, so they move with your location and calculation method.'**
  String get adhkarReminderNote;

  /// Shown when saving a reminder fails.
  ///
  /// In en, this message translates to:
  /// **'The reminder could not be saved.'**
  String get adhkarReminderSaveError;

  /// Title of the reminder settings screen and its button.
  ///
  /// In en, this message translates to:
  /// **'Adhkar reminders'**
  String get adhkarRemindersTitle;

  /// How many times the entry is recited.
  ///
  /// In en, this message translates to:
  /// **'Repetitions: {count}'**
  String adhkarRepeatLabel(int count);

  /// Shown when every entry reached its repeat count.
  ///
  /// In en, this message translates to:
  /// **'Session complete'**
  String get adhkarSessionComplete;

  /// Source reference of an entry.
  ///
  /// In en, this message translates to:
  /// **'Source: {reference}'**
  String adhkarSourceLabel(String reference);

  /// Button that begins a new session after one is complete.
  ///
  /// In en, this message translates to:
  /// **'Start again'**
  String get adhkarStartAgain;

  /// Title of the adhkar collections screen.
  ///
  /// In en, this message translates to:
  /// **'Adhkar'**
  String get adhkarTitle;

  /// Heading used when only the English translation exists.
  ///
  /// In en, this message translates to:
  /// **'Translation (English; not available in your language yet)'**
  String get adhkarTranslationFallbackHeading;

  /// Heading above the translation of an entry.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get adhkarTranslationHeading;

  /// Heading above the transliteration of an entry.
  ///
  /// In en, this message translates to:
  /// **'Transliteration'**
  String get adhkarTransliterationHeading;

  /// Tooltip of the undo button.
  ///
  /// In en, this message translates to:
  /// **'Undo last count'**
  String get adhkarUndo;

  /// No description provided for @alertAudioIntro.
  ///
  /// In en, this message translates to:
  /// **'Where the Azaan plays when headphones or a Bluetooth device are connected. Without them it plays on the speaker.'**
  String get alertAudioIntro;

  /// No description provided for @alertAudioTitle.
  ///
  /// In en, this message translates to:
  /// **'Audio output'**
  String get alertAudioTitle;

  /// No description provided for @alertCauseAppNotRun.
  ///
  /// In en, this message translates to:
  /// **'The app had not been opened.'**
  String get alertCauseAppNotRun;

  /// No description provided for @alertCauseBatteryRestricted.
  ///
  /// In en, this message translates to:
  /// **'Battery saving may have stopped it. Check the battery settings.'**
  String get alertCauseBatteryRestricted;

  /// No description provided for @alertCauseCallInProgress.
  ///
  /// In en, this message translates to:
  /// **'A phone call was in progress.'**
  String get alertCauseCallInProgress;

  /// No description provided for @alertCauseExactAlarmDenied.
  ///
  /// In en, this message translates to:
  /// **'Exact alarms are off, so Android may have delayed it.'**
  String get alertCauseExactAlarmDenied;

  /// No description provided for @alertCauseFgsBlocked.
  ///
  /// In en, this message translates to:
  /// **'Android did not let the app start the Azaan, so a notification tone was used.'**
  String get alertCauseFgsBlocked;

  /// No description provided for @alertCauseNotificationDenied.
  ///
  /// In en, this message translates to:
  /// **'Notifications were turned off.'**
  String get alertCauseNotificationDenied;

  /// No description provided for @alertCauseQuietHours.
  ///
  /// In en, this message translates to:
  /// **'Silenced by quiet hours.'**
  String get alertCauseQuietHours;

  /// No description provided for @alertCauseScheduleEnded.
  ///
  /// In en, this message translates to:
  /// **'The scheduled alerts ran out because the app was not opened for a long time. Opening it renewed them.'**
  String get alertCauseScheduleEnded;

  /// No description provided for @alertCauseSilentMode.
  ///
  /// In en, this message translates to:
  /// **'The phone was on silent.'**
  String get alertCauseSilentMode;

  /// No description provided for @alertCauseUnknown.
  ///
  /// In en, this message translates to:
  /// **'The reason is not known.'**
  String get alertCauseUnknown;

  /// No description provided for @alertExactBody.
  ///
  /// In en, this message translates to:
  /// **'To sound at the exact prayer time, Android needs the “Alarms & reminders” permission for Deen App. Without it, alerts still arrive but may be a few minutes late.'**
  String get alertExactBody;

  /// No description provided for @alertExactCheck.
  ///
  /// In en, this message translates to:
  /// **'I changed it, check again'**
  String get alertExactCheck;

  /// No description provided for @alertExactGranted.
  ///
  /// In en, this message translates to:
  /// **'Exact alarms are on.'**
  String get alertExactGranted;

  /// No description provided for @alertExactInexact.
  ///
  /// In en, this message translates to:
  /// **'Alerts will still arrive, but timing may be less precise. You can change this later in the Reliability check.'**
  String get alertExactInexact;

  /// No description provided for @alertExactOpen.
  ///
  /// In en, this message translates to:
  /// **'Open alarm settings'**
  String get alertExactOpen;

  /// No description provided for @alertExactSkip.
  ///
  /// In en, this message translates to:
  /// **'Continue without it'**
  String get alertExactSkip;

  /// No description provided for @alertExactTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow exact alarms?'**
  String get alertExactTitle;

  /// No description provided for @alertIgnoreQuietHours.
  ///
  /// In en, this message translates to:
  /// **'Ignore quiet hours'**
  String get alertIgnoreQuietHours;

  /// No description provided for @alertIgnoreQuietHoursHint.
  ///
  /// In en, this message translates to:
  /// **'Keep this alert audible even inside quiet hours.'**
  String get alertIgnoreQuietHoursHint;

  /// No description provided for @alertLoudAndroidOnly.
  ///
  /// In en, this message translates to:
  /// **'Loud mode is available on Android only. On iPhone the silent switch mutes the notification sound; tapping the notification still plays the full Azaan.'**
  String get alertLoudAndroidOnly;

  /// No description provided for @alertLoudIntro.
  ///
  /// In en, this message translates to:
  /// **'Off by default. When on for a prayer, the Azaan sounds even if the phone is on silent. Deen App never changes your system volume unless you choose this.'**
  String get alertLoudIntro;

  /// No description provided for @alertLoudSwitch.
  ///
  /// In en, this message translates to:
  /// **'Loud mode for {prayer}'**
  String alertLoudSwitch(String prayer);

  /// No description provided for @alertLoudTitle.
  ///
  /// In en, this message translates to:
  /// **'Loud mode'**
  String get alertLoudTitle;

  /// No description provided for @alertMissedDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get alertMissedDismiss;

  /// One line in the missed-alert notice: when, then the likely cause.
  ///
  /// In en, this message translates to:
  /// **'{when}: {cause}'**
  String alertMissedLine(String when, String cause);

  /// No description provided for @alertMissedMore.
  ///
  /// In en, this message translates to:
  /// **'and {count} more'**
  String alertMissedMore(int count);

  /// No description provided for @alertMissedOpenCheck.
  ///
  /// In en, this message translates to:
  /// **'Open Reliability check'**
  String get alertMissedOpenCheck;

  /// No description provided for @alertMissedPossibly.
  ///
  /// In en, this message translates to:
  /// **'iPhone cannot confirm delivery, so this one is only possibly missed.'**
  String get alertMissedPossibly;

  /// No description provided for @alertMissedTitle.
  ///
  /// In en, this message translates to:
  /// **'An alert may not have sounded'**
  String get alertMissedTitle;

  /// No description provided for @alertMissedTitleMany.
  ///
  /// In en, this message translates to:
  /// **'Some alerts may not have sounded'**
  String get alertMissedTitleMany;

  /// No description provided for @alertNotifAdhkarEveningBody.
  ///
  /// In en, this message translates to:
  /// **'A good time for your evening remembrance.'**
  String get alertNotifAdhkarEveningBody;

  /// No description provided for @alertNotifAdhkarEveningTitle.
  ///
  /// In en, this message translates to:
  /// **'Evening adhkar'**
  String get alertNotifAdhkarEveningTitle;

  /// No description provided for @alertNotifAdhkarMorningBody.
  ///
  /// In en, this message translates to:
  /// **'A good time for your morning remembrance.'**
  String get alertNotifAdhkarMorningBody;

  /// No description provided for @alertNotifAdhkarMorningTitle.
  ///
  /// In en, this message translates to:
  /// **'Morning adhkar'**
  String get alertNotifAdhkarMorningTitle;

  /// Body of the notification at prayer time.
  ///
  /// In en, this message translates to:
  /// **'It is time for {prayer}.'**
  String alertNotifPrayerBody(String prayer);

  /// Title of the notification at prayer time. The placeholder is the prayer name.
  ///
  /// In en, this message translates to:
  /// **'{prayer} prayer'**
  String alertNotifPrayerTitle(String prayer);

  /// Body of the reminder before a prayer.
  ///
  /// In en, this message translates to:
  /// **'Get ready for the {prayer} prayer.'**
  String alertNotifPreBody(String prayer);

  /// Title of the reminder before a prayer.
  ///
  /// In en, this message translates to:
  /// **'{prayer} in {minutes} min'**
  String alertNotifPreTitle(String prayer, int minutes);

  /// No description provided for @alertNotifRenewalBody.
  ///
  /// In en, this message translates to:
  /// **'Your scheduled alerts end soon. Open the app once and they are renewed.'**
  String get alertNotifRenewalBody;

  /// Shown about a week before the scheduled alerts run out.
  ///
  /// In en, this message translates to:
  /// **'Open Deen App to keep your alerts on'**
  String get alertNotifRenewalTitle;

  /// Label of the notification button that stops the Azaan.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get alertNotifStopLabel;

  /// Body of the suhoor reminder.
  ///
  /// In en, this message translates to:
  /// **'Fajr is in {minutes} min.'**
  String alertNotifSuhoorBody(int minutes);

  /// No description provided for @alertNotifSuhoorTitle.
  ///
  /// In en, this message translates to:
  /// **'Suhoor reminder'**
  String get alertNotifSuhoorTitle;

  /// No description provided for @alertOptionsTile.
  ///
  /// In en, this message translates to:
  /// **'More alert options'**
  String get alertOptionsTile;

  /// No description provided for @alertOptionsTileHint.
  ///
  /// In en, this message translates to:
  /// **'Loud mode, quiet hours, reminders and audio output'**
  String get alertOptionsTileHint;

  /// No description provided for @alertOptionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Alert options'**
  String get alertOptionsTitle;

  /// No description provided for @alertOutputBluetooth.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth'**
  String get alertOutputBluetooth;

  /// No description provided for @alertOutputHeadphones.
  ///
  /// In en, this message translates to:
  /// **'Headphones'**
  String get alertOutputHeadphones;

  /// No description provided for @alertOutputSpeaker.
  ///
  /// In en, this message translates to:
  /// **'Speaker'**
  String get alertOutputSpeaker;

  /// No description provided for @alertPreviewFailed.
  ///
  /// In en, this message translates to:
  /// **'This recording could not be played.'**
  String get alertPreviewFailed;

  /// Accessibility label of a preview button.
  ///
  /// In en, this message translates to:
  /// **'Play {name}'**
  String alertPreviewPlay(String name);

  /// No description provided for @alertPreviewStop.
  ///
  /// In en, this message translates to:
  /// **'Stop preview'**
  String get alertPreviewStop;

  /// No description provided for @alertQuietEnd.
  ///
  /// In en, this message translates to:
  /// **'Ends at'**
  String get alertQuietEnd;

  /// No description provided for @alertQuietIntro.
  ///
  /// In en, this message translates to:
  /// **'Alerts that would make a sound inside quiet hours become silent notifications, unless a prayer is set to ignore quiet hours.'**
  String get alertQuietIntro;

  /// Summary of the chosen quiet hours.
  ///
  /// In en, this message translates to:
  /// **'Quiet hours {start} to {end}'**
  String alertQuietRange(String start, String end);

  /// No description provided for @alertQuietStart.
  ///
  /// In en, this message translates to:
  /// **'Starts at'**
  String get alertQuietStart;

  /// No description provided for @alertQuietSwitch.
  ///
  /// In en, this message translates to:
  /// **'Use quiet hours'**
  String get alertQuietSwitch;

  /// No description provided for @alertQuietTitle.
  ///
  /// In en, this message translates to:
  /// **'Quiet hours'**
  String get alertQuietTitle;

  /// Accessibility label of the reminder menu for one prayer.
  ///
  /// In en, this message translates to:
  /// **'Reminder for {prayer}'**
  String alertReminderFor(String prayer);

  /// No description provided for @alertReminderIntro.
  ///
  /// In en, this message translates to:
  /// **'A reminder is never a full Azaan. It uses a short tone at most.'**
  String get alertReminderIntro;

  /// No description provided for @alertReminderMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min before'**
  String alertReminderMinutes(int minutes);

  /// No description provided for @alertReminderNone.
  ///
  /// In en, this message translates to:
  /// **'No reminder'**
  String get alertReminderNone;

  /// Summary line on a prayer's card when a reminder is set.
  ///
  /// In en, this message translates to:
  /// **'Reminder {minutes} min before'**
  String alertReminderSummary(int minutes);

  /// No description provided for @alertReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminder before each prayer'**
  String get alertReminderTitle;

  /// No description provided for @alertSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'This choice could not be saved. Please try again.'**
  String get alertSaveFailed;

  /// No description provided for @alertSettingsIntro.
  ///
  /// In en, this message translates to:
  /// **'Choose what happens at each prayer time.'**
  String get alertSettingsIntro;

  /// No description provided for @alertSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Prayer alerts'**
  String get alertSettingsTitle;

  /// No description provided for @alertSilentSwitchBody.
  ///
  /// In en, this message translates to:
  /// **'When your iPhone\'s silent switch is on, the sound of a notification is muted. Tapping the notification still plays the full Azaan. You can also choose vibration instead.'**
  String get alertSilentSwitchBody;

  /// No description provided for @alertSilentSwitchGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get alertSilentSwitchGotIt;

  /// No description provided for @alertSilentSwitchTitle.
  ///
  /// In en, this message translates to:
  /// **'About the silent switch'**
  String get alertSilentSwitchTitle;

  /// No description provided for @alertSilentSwitchVibrate.
  ///
  /// In en, this message translates to:
  /// **'Use vibration for my alerts'**
  String get alertSilentSwitchVibrate;

  /// No description provided for @alertSuhoorIntro.
  ///
  /// In en, this message translates to:
  /// **'During Ramadan, a reminder before Fajr so you can eat in time.'**
  String get alertSuhoorIntro;

  /// No description provided for @alertSuhoorMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min before Fajr'**
  String alertSuhoorMinutes(int minutes);

  /// No description provided for @alertSuhoorSwitch.
  ///
  /// In en, this message translates to:
  /// **'Remind me before suhoor ends'**
  String get alertSuhoorSwitch;

  /// No description provided for @alertSuhoorTitle.
  ///
  /// In en, this message translates to:
  /// **'Suhoor reminder'**
  String get alertSuhoorTitle;

  /// No description provided for @alertTypeFullAzaan.
  ///
  /// In en, this message translates to:
  /// **'Full Azaan'**
  String get alertTypeFullAzaan;

  /// Accessibility label of the group of choices for one prayer.
  ///
  /// In en, this message translates to:
  /// **'Alert for {prayer}'**
  String alertTypeGroupLabel(String prayer);

  /// No description provided for @alertTypeOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get alertTypeOff;

  /// No description provided for @alertTypeShortTone.
  ///
  /// In en, this message translates to:
  /// **'Short tone'**
  String get alertTypeShortTone;

  /// No description provided for @alertTypeSilent.
  ///
  /// In en, this message translates to:
  /// **'Silent notification'**
  String get alertTypeSilent;

  /// No description provided for @alertTypeVibrate.
  ///
  /// In en, this message translates to:
  /// **'Vibrate'**
  String get alertTypeVibrate;

  /// No description provided for @alertVariantFajr.
  ///
  /// In en, this message translates to:
  /// **'Fajr version'**
  String get alertVariantFajr;

  /// No description provided for @alertVariantFajrHint.
  ///
  /// In en, this message translates to:
  /// **'Includes “as-salatu khayrun min an-nawm”. Played at Fajr when Standard is chosen.'**
  String get alertVariantFajrHint;

  /// No description provided for @alertVariantShia.
  ///
  /// In en, this message translates to:
  /// **'Shia wording'**
  String get alertVariantShia;

  /// No description provided for @alertVariantShiaHint.
  ///
  /// In en, this message translates to:
  /// **'The call to prayer with Shia wording. Played at all five prayers when chosen.'**
  String get alertVariantShiaHint;

  /// No description provided for @alertVariantStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get alertVariantStandard;

  /// No description provided for @alertVariantStandardHint.
  ///
  /// In en, this message translates to:
  /// **'The usual call to prayer. Fajr uses the Fajr recording.'**
  String get alertVariantStandardHint;

  /// Subtitle of the voice picker: which prayer the choice applies to.
  ///
  /// In en, this message translates to:
  /// **'For {prayer}'**
  String alertVoiceForPrayer(String prayer);

  /// No description provided for @alertVoiceIntro.
  ///
  /// In en, this message translates to:
  /// **'Each voice has three recordings. Tap play to hear one before you choose.'**
  String get alertVoiceIntro;

  /// Name of a bundled voice.
  ///
  /// In en, this message translates to:
  /// **'Voice {number}'**
  String alertVoiceName(int number);

  /// No description provided for @alertVoiceSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get alertVoiceSelected;

  /// No description provided for @alertVoiceTile.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get alertVoiceTile;

  /// Current voice and wording shown on a prayer's card.
  ///
  /// In en, this message translates to:
  /// **'{voice}, {variant}'**
  String alertVoiceTileValue(String voice, String variant);

  /// No description provided for @alertVoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a voice'**
  String get alertVoiceTitle;

  /// No description provided for @alertVolumeKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep my current volume'**
  String get alertVolumeKeep;

  /// No description provided for @alertVolumeRamp.
  ///
  /// In en, this message translates to:
  /// **'Gentle ramp'**
  String get alertVolumeRamp;

  /// No description provided for @alertVolumeRampHint.
  ///
  /// In en, this message translates to:
  /// **'Starts quiet and gets louder over a few seconds.'**
  String get alertVolumeRampHint;

  /// Brand name shown in the app bar and task switcher.
  ///
  /// In en, this message translates to:
  /// **'Deen App'**
  String get appTitle;

  /// No description provided for @asrHanafiBody.
  ///
  /// In en, this message translates to:
  /// **'Asr starts when an object\'s shadow is twice as long as the object, so Asr begins later (used by the Hanafi school).'**
  String get asrHanafiBody;

  /// No description provided for @asrHanafiTitle.
  ///
  /// In en, this message translates to:
  /// **'Hanafi'**
  String get asrHanafiTitle;

  /// No description provided for @asrStandardBody.
  ///
  /// In en, this message translates to:
  /// **'Asr starts when an object\'s shadow is as long as the object itself (used by the Shafi\'i, Maliki and Hanbali schools).'**
  String get asrStandardBody;

  /// No description provided for @asrStandardTitle.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get asrStandardTitle;

  /// No description provided for @detailHijriAdjusted.
  ///
  /// In en, this message translates to:
  /// **'Includes your adjustment of {days} days (Umm al-Qura calendar).'**
  String detailHijriAdjusted(String days);

  /// No description provided for @detailHijriDefault.
  ///
  /// In en, this message translates to:
  /// **'Umm al-Qura calendar.'**
  String get detailHijriDefault;

  /// No description provided for @detailHijriTitle.
  ///
  /// In en, this message translates to:
  /// **'Hijri date'**
  String get detailHijriTitle;

  /// No description provided for @detailHijriUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The Hijri date is not available yet.'**
  String get detailHijriUnavailable;

  /// Hijri date, for example 12 Ramadan 1448 AH.
  ///
  /// In en, this message translates to:
  /// **'{day} {month} {year} AH'**
  String detailHijriValue(String day, String month, String year);

  /// No description provided for @detailImsak.
  ///
  /// In en, this message translates to:
  /// **'Imsak'**
  String get detailImsak;

  /// No description provided for @detailLastThird.
  ///
  /// In en, this message translates to:
  /// **'Last third of the night'**
  String get detailLastThird;

  /// No description provided for @detailMidnight.
  ///
  /// In en, this message translates to:
  /// **'Midnight'**
  String get detailMidnight;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @highLatAngleBody.
  ///
  /// In en, this message translates to:
  /// **'Fajr and Isha use a share of the night equal to the twilight angle divided by 60.'**
  String get highLatAngleBody;

  /// No description provided for @highLatAngleTitle.
  ///
  /// In en, this message translates to:
  /// **'Angle-based'**
  String get highLatAngleTitle;

  /// Explanation shown when a high-latitude rule is applied.
  ///
  /// In en, this message translates to:
  /// **'Fajr and Isha were estimated with the “{rule}” rule because your latitude is above 48 degrees, where twilight may not end. You can change the rule in prayer settings.'**
  String highLatApplied(String rule);

  /// No description provided for @highLatMiddleBody.
  ///
  /// In en, this message translates to:
  /// **'The night is split in half: Isha comes no later than the middle of the night and Fajr no earlier.'**
  String get highLatMiddleBody;

  /// No description provided for @highLatMiddleTitle.
  ///
  /// In en, this message translates to:
  /// **'Middle of the night'**
  String get highLatMiddleTitle;

  /// No description provided for @highLatSeventhBody.
  ///
  /// In en, this message translates to:
  /// **'The night is divided into seven parts: Isha is at most one part after sunset and Fajr one part before sunrise.'**
  String get highLatSeventhBody;

  /// No description provided for @highLatSeventhTitle.
  ///
  /// In en, this message translates to:
  /// **'Seventh of the night'**
  String get highLatSeventhTitle;

  /// No description provided for @hijriMonth1.
  ///
  /// In en, this message translates to:
  /// **'Muharram'**
  String get hijriMonth1;

  /// No description provided for @hijriMonth10.
  ///
  /// In en, this message translates to:
  /// **'Shawwal'**
  String get hijriMonth10;

  /// No description provided for @hijriMonth11.
  ///
  /// In en, this message translates to:
  /// **'Dhu al-Qi\'dah'**
  String get hijriMonth11;

  /// No description provided for @hijriMonth12.
  ///
  /// In en, this message translates to:
  /// **'Dhu al-Hijjah'**
  String get hijriMonth12;

  /// No description provided for @hijriMonth2.
  ///
  /// In en, this message translates to:
  /// **'Safar'**
  String get hijriMonth2;

  /// No description provided for @hijriMonth3.
  ///
  /// In en, this message translates to:
  /// **'Rabi\' al-awwal'**
  String get hijriMonth3;

  /// No description provided for @hijriMonth4.
  ///
  /// In en, this message translates to:
  /// **'Rabi\' al-thani'**
  String get hijriMonth4;

  /// No description provided for @hijriMonth5.
  ///
  /// In en, this message translates to:
  /// **'Jumada al-ula'**
  String get hijriMonth5;

  /// No description provided for @hijriMonth6.
  ///
  /// In en, this message translates to:
  /// **'Jumada al-thani'**
  String get hijriMonth6;

  /// No description provided for @hijriMonth7.
  ///
  /// In en, this message translates to:
  /// **'Rajab'**
  String get hijriMonth7;

  /// No description provided for @hijriMonth8.
  ///
  /// In en, this message translates to:
  /// **'Sha\'ban'**
  String get hijriMonth8;

  /// No description provided for @hijriMonth9.
  ///
  /// In en, this message translates to:
  /// **'Ramadan'**
  String get hijriMonth9;

  /// No description provided for @homeBackToToday.
  ///
  /// In en, this message translates to:
  /// **'Back to today'**
  String get homeBackToToday;

  /// No description provided for @homeBannerDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get homeBannerDismiss;

  /// No description provided for @homeChooseLocation.
  ///
  /// In en, this message translates to:
  /// **'Choose location'**
  String get homeChooseLocation;

  /// No description provided for @homeClockBeforeBuild.
  ///
  /// In en, this message translates to:
  /// **'Your phone\'s date looks wrong: it is earlier than this version of the app. Prayer times and alerts may be wrong. Please check Date and time in your phone\'s settings.'**
  String get homeClockBeforeBuild;

  /// No description provided for @homeClockDrifted.
  ///
  /// In en, this message translates to:
  /// **'Your phone\'s clock was changed. If the time is wrong, prayer times and alerts may be wrong. Please check Date and time in your phone\'s settings.'**
  String get homeClockDrifted;

  /// No description provided for @homeClockMovedBack.
  ///
  /// In en, this message translates to:
  /// **'Your phone\'s clock was set back. If the time is wrong, prayer times and alerts may be wrong. Please check Date and time in your phone\'s settings.'**
  String get homeClockMovedBack;

  /// Spoken label of the countdown.
  ///
  /// In en, this message translates to:
  /// **'{prayer} in {hours, plural, =1{1 hour} other{{hours} hours}} and {minutes, plural, =1{1 minute} other{{minutes} minutes}}'**
  String homeCountdownSemantics(String prayer, int hours, int minutes);

  /// No description provided for @homeError.
  ///
  /// In en, this message translates to:
  /// **'Prayer times could not be calculated. Check the location and try again.'**
  String get homeError;

  /// Opens the detail view with Imsak, midnight and the last third of the night.
  ///
  /// In en, this message translates to:
  /// **'More times'**
  String get homeMoreTimes;

  /// Text marker on the row of the next prayer (not colour alone).
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get homeNextBadge;

  /// No description provided for @homeNextDay.
  ///
  /// In en, this message translates to:
  /// **'Next day'**
  String get homeNextDay;

  /// No description provided for @homeNoLocation.
  ///
  /// In en, this message translates to:
  /// **'Choose a location to see prayer times.'**
  String get homeNoLocation;

  /// No description provided for @homePreviousDay.
  ///
  /// In en, this message translates to:
  /// **'Previous day'**
  String get homePreviousDay;

  /// No description provided for @homeRegionSuggestion.
  ///
  /// In en, this message translates to:
  /// **'This region usually uses {method}. Your chosen method stays as it is.'**
  String homeRegionSuggestion(String method);

  /// No description provided for @homeRegionSuggestionGeneral.
  ///
  /// In en, this message translates to:
  /// **'No regional default exists for this location. {method} is a general choice. Your chosen method stays as it is.'**
  String homeRegionSuggestionGeneral(String method);

  /// No description provided for @homeRegionSuggestionSwitch.
  ///
  /// In en, this message translates to:
  /// **'Switch to {method}'**
  String homeRegionSuggestionSwitch(String method);

  /// Shown when the sun does not rise or set.
  ///
  /// In en, this message translates to:
  /// **'Does not occur today'**
  String get homeTimeNotAvailable;

  /// No description provided for @homeTimeSemantics.
  ///
  /// In en, this message translates to:
  /// **'{prayer} at {time}'**
  String homeTimeSemantics(String prayer, String time);

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Prayer times'**
  String get homeTitle;

  /// No description provided for @homeToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get homeToday;

  /// No description provided for @homeTzRulesNotice.
  ///
  /// In en, this message translates to:
  /// **'Time-zone rules may have changed. Please update the app. Until then, times follow your phone\'s rules.'**
  String get homeTzRulesNotice;

  /// Name of the language in itself; never translated.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get languageNameAr;

  /// Name of the language in itself; never translated.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageNameEn;

  /// Name of the language in itself; never translated.
  ///
  /// In en, this message translates to:
  /// **'Bahasa Indonesia'**
  String get languageNameId;

  /// Name of the language in itself; never translated.
  ///
  /// In en, this message translates to:
  /// **'اردو'**
  String get languageNameUr;

  /// No description provided for @languageSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSettingsTitle;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @locationSettingsCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current location: {name}'**
  String locationSettingsCurrent(String name);

  /// No description provided for @locationSettingsNone.
  ///
  /// In en, this message translates to:
  /// **'No location is saved yet.'**
  String get locationSettingsNone;

  /// No description provided for @locationSettingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Location saved. Alerts will be updated.'**
  String get locationSettingsSaved;

  /// No description provided for @locationSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationSettingsTitle;

  /// No description provided for @methodDiyanet.
  ///
  /// In en, this message translates to:
  /// **'Turkey (Diyanet)'**
  String get methodDiyanet;

  /// No description provided for @methodEgypt.
  ///
  /// In en, this message translates to:
  /// **'Egyptian General Authority of Survey'**
  String get methodEgypt;

  /// No description provided for @methodFranceUoif.
  ///
  /// In en, this message translates to:
  /// **'France (UOIF)'**
  String get methodFranceUoif;

  /// No description provided for @methodGulf.
  ///
  /// In en, this message translates to:
  /// **'Gulf Region'**
  String get methodGulf;

  /// No description provided for @methodIsna.
  ///
  /// In en, this message translates to:
  /// **'ISNA (North America)'**
  String get methodIsna;

  /// No description provided for @methodJafari.
  ///
  /// In en, this message translates to:
  /// **'Shia Ithna-Ashari (Jafari)'**
  String get methodJafari;

  /// No description provided for @methodKarachi.
  ///
  /// In en, this message translates to:
  /// **'University of Islamic Sciences, Karachi'**
  String get methodKarachi;

  /// No description provided for @methodKuwait.
  ///
  /// In en, this message translates to:
  /// **'Kuwait'**
  String get methodKuwait;

  /// No description provided for @methodMoonsightingCommittee.
  ///
  /// In en, this message translates to:
  /// **'Moonsighting Committee'**
  String get methodMoonsightingCommittee;

  /// No description provided for @methodMuslimWorldLeague.
  ///
  /// In en, this message translates to:
  /// **'Muslim World League'**
  String get methodMuslimWorldLeague;

  /// No description provided for @methodQatar.
  ///
  /// In en, this message translates to:
  /// **'Qatar'**
  String get methodQatar;

  /// No description provided for @methodSingapore.
  ///
  /// In en, this message translates to:
  /// **'Singapore (MUIS)'**
  String get methodSingapore;

  /// No description provided for @methodTehran.
  ///
  /// In en, this message translates to:
  /// **'Institute of Geophysics, University of Tehran'**
  String get methodTehran;

  /// No description provided for @methodUmmAlQura.
  ///
  /// In en, this message translates to:
  /// **'Umm al-Qura (Makkah)'**
  String get methodUmmAlQura;

  /// No description provided for @nextPrayerLabel.
  ///
  /// In en, this message translates to:
  /// **'Next prayer'**
  String get nextPrayerLabel;

  /// Brand names are not translated.
  ///
  /// In en, this message translates to:
  /// **'Huawei, Honor'**
  String get oemBrandHuawei;

  /// Brand names are not translated.
  ///
  /// In en, this message translates to:
  /// **'OnePlus'**
  String get oemBrandOneplus;

  /// Brand names are not translated.
  ///
  /// In en, this message translates to:
  /// **'Oppo, realme'**
  String get oemBrandOppo;

  /// No description provided for @oemBrandOther.
  ///
  /// In en, this message translates to:
  /// **'Another brand'**
  String get oemBrandOther;

  /// Brand names are not translated.
  ///
  /// In en, this message translates to:
  /// **'Samsung'**
  String get oemBrandSamsung;

  /// Brand names are not translated.
  ///
  /// In en, this message translates to:
  /// **'Vivo, iQOO'**
  String get oemBrandVivo;

  /// Brand names are not translated.
  ///
  /// In en, this message translates to:
  /// **'Xiaomi, Redmi, POCO'**
  String get oemBrandXiaomi;

  /// No description provided for @permissionBannerAction.
  ///
  /// In en, this message translates to:
  /// **'Fix in settings'**
  String get permissionBannerAction;

  /// No description provided for @permissionBannerAlerts.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off. Prayer alerts will not appear.'**
  String get permissionBannerAlerts;

  /// No description provided for @permissionBannerExact.
  ///
  /// In en, this message translates to:
  /// **'Exact alarms are off. Alerts may be a few minutes late.'**
  String get permissionBannerExact;

  /// No description provided for @permissionBannerLocation.
  ///
  /// In en, this message translates to:
  /// **'Location is off. Times use your saved city.'**
  String get permissionBannerLocation;

  /// No description provided for @prayerAsr.
  ///
  /// In en, this message translates to:
  /// **'Asr'**
  String get prayerAsr;

  /// No description provided for @prayerDhuhr.
  ///
  /// In en, this message translates to:
  /// **'Dhuhr'**
  String get prayerDhuhr;

  /// No description provided for @prayerFajr.
  ///
  /// In en, this message translates to:
  /// **'Fajr'**
  String get prayerFajr;

  /// No description provided for @prayerIsha.
  ///
  /// In en, this message translates to:
  /// **'Isha'**
  String get prayerIsha;

  /// No description provided for @prayerJumuah.
  ///
  /// In en, this message translates to:
  /// **'Jumu\'ah'**
  String get prayerJumuah;

  /// No description provided for @prayerMaghrib.
  ///
  /// In en, this message translates to:
  /// **'Maghrib'**
  String get prayerMaghrib;

  /// No description provided for @prayerSettingsHighLatIntro.
  ///
  /// In en, this message translates to:
  /// **'Above 48 degrees of latitude, twilight may not end in summer. Choose how Fajr and Isha are estimated then.'**
  String get prayerSettingsHighLatIntro;

  /// No description provided for @prayerSettingsHighLatTitle.
  ///
  /// In en, this message translates to:
  /// **'High latitudes'**
  String get prayerSettingsHighLatTitle;

  /// No description provided for @prayerSettingsHijriLess.
  ///
  /// In en, this message translates to:
  /// **'Move the Hijri date one day back'**
  String get prayerSettingsHijriLess;

  /// No description provided for @prayerSettingsHijriMore.
  ///
  /// In en, this message translates to:
  /// **'Move the Hijri date one day forward'**
  String get prayerSettingsHijriMore;

  /// No description provided for @prayerSettingsHijriTitle.
  ///
  /// In en, this message translates to:
  /// **'Hijri date adjustment (days)'**
  String get prayerSettingsHijriTitle;

  /// Signed days, for example +1 days.
  ///
  /// In en, this message translates to:
  /// **'{value} days'**
  String prayerSettingsHijriValue(String value);

  /// No description provided for @prayerSettingsNoLocation.
  ///
  /// In en, this message translates to:
  /// **'Choose a location first. Prayer settings apply to your saved location.'**
  String get prayerSettingsNoLocation;

  /// No description provided for @prayerSettingsOffsetLabel.
  ///
  /// In en, this message translates to:
  /// **'{prayer} adjustment'**
  String prayerSettingsOffsetLabel(String prayer);

  /// No description provided for @prayerSettingsOffsetLess.
  ///
  /// In en, this message translates to:
  /// **'Subtract one minute from {prayer}'**
  String prayerSettingsOffsetLess(String prayer);

  /// No description provided for @prayerSettingsOffsetMore.
  ///
  /// In en, this message translates to:
  /// **'Add one minute to {prayer}'**
  String prayerSettingsOffsetMore(String prayer);

  /// Signed minutes, for example +5 min.
  ///
  /// In en, this message translates to:
  /// **'{value} min'**
  String prayerSettingsOffsetValue(String value);

  /// No description provided for @prayerSettingsOffsetsIntro.
  ///
  /// In en, this message translates to:
  /// **'Add or remove up to 60 minutes for any prayer. This applies everywhere, including alerts.'**
  String get prayerSettingsOffsetsIntro;

  /// No description provided for @prayerSettingsOffsetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Adjust times'**
  String get prayerSettingsOffsetsTitle;

  /// No description provided for @prayerSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Prayer settings'**
  String get prayerSettingsTitle;

  /// No description provided for @prayerSunrise.
  ///
  /// In en, this message translates to:
  /// **'Sunrise'**
  String get prayerSunrise;

  /// Compass accuracy level.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get qiblaAccuracyHigh;

  /// Accuracy indicator. The level is always written out, never shown by color alone.
  ///
  /// In en, this message translates to:
  /// **'Compass accuracy: {level}'**
  String qiblaAccuracyLabel(String level);

  /// Compass accuracy level.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get qiblaAccuracyLow;

  /// Compass accuracy level.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get qiblaAccuracyMedium;

  /// Compass accuracy level.
  ///
  /// In en, this message translates to:
  /// **'Unreliable'**
  String get qiblaAccuracyUnreliable;

  /// Prefix of the screen-reader label of the rotating arrow.
  ///
  /// In en, this message translates to:
  /// **'Compass arrow'**
  String get qiblaArrowSemantics;

  /// Shown instead of a compass when the saved location is within the Haram.
  ///
  /// In en, this message translates to:
  /// **'You are at the Haram in Makkah. Face the Kaaba directly.'**
  String get qiblaAtHaram;

  /// Heading with the saved place name and the bearing text.
  ///
  /// In en, this message translates to:
  /// **'Qibla from {place}: {description}'**
  String qiblaBearingFromPlace(String place, String description);

  /// Shown when the compass reports low accuracy.
  ///
  /// In en, this message translates to:
  /// **'Calibrate your compass. Move your phone in a figure eight a few times, away from metal and magnets.'**
  String get qiblaCalibrationPrompt;

  /// Shown when starting the sensors fails.
  ///
  /// In en, this message translates to:
  /// **'The compass could not be started. The direction is shown in degrees instead.'**
  String get qiblaCompassError;

  /// A bearing spoken by a screen reader, for example '212 degrees, southwest'. Degrees are clockwise from true north.
  ///
  /// In en, this message translates to:
  /// **'{degrees} degrees, {direction}'**
  String qiblaDirectionDescription(int degrees, String direction);

  /// Compass point, lower case.
  ///
  /// In en, this message translates to:
  /// **'east'**
  String get qiblaDirectionEast;

  /// Compass point, lower case, used inside a sentence read by a screen reader.
  ///
  /// In en, this message translates to:
  /// **'north'**
  String get qiblaDirectionNorth;

  /// Compass point, lower case.
  ///
  /// In en, this message translates to:
  /// **'northeast'**
  String get qiblaDirectionNortheast;

  /// Compass point, lower case.
  ///
  /// In en, this message translates to:
  /// **'northwest'**
  String get qiblaDirectionNorthwest;

  /// Compass point, lower case.
  ///
  /// In en, this message translates to:
  /// **'south'**
  String get qiblaDirectionSouth;

  /// Compass point, lower case.
  ///
  /// In en, this message translates to:
  /// **'southeast'**
  String get qiblaDirectionSoutheast;

  /// Compass point, lower case.
  ///
  /// In en, this message translates to:
  /// **'southwest'**
  String get qiblaDirectionSouthwest;

  /// Compass point, lower case.
  ///
  /// In en, this message translates to:
  /// **'west'**
  String get qiblaDirectionWest;

  /// Great-circle distance to the Kaaba in kilometres.
  ///
  /// In en, this message translates to:
  /// **'{km} km to the Kaaba'**
  String qiblaDistanceToKaaba(int km);

  /// One-line hint under the Qibla entry on the home screen.
  ///
  /// In en, this message translates to:
  /// **'Find the direction of the Kaaba'**
  String get qiblaEntryHint;

  /// Shown and announced when the phone points within a few degrees of the Qibla.
  ///
  /// In en, this message translates to:
  /// **'You are facing the Qibla'**
  String get qiblaFacingQibla;

  /// Shown when the magnetic field is outside the expected range or the heading jumps.
  ///
  /// In en, this message translates to:
  /// **'Magnetic interference nearby. Move away from metal, speakers, magnets and electronics, then check again. The arrow may be wrong until then.'**
  String get qiblaInterferenceWarning;

  /// Shown when the platform could not apply magnetic declination.
  ///
  /// In en, this message translates to:
  /// **'The compass is using magnetic north. A small error is possible.'**
  String get qiblaMagneticNorthNote;

  /// Plain instructions when the device has no usable compass.
  ///
  /// In en, this message translates to:
  /// **'Use the direction above. Find north with a map, a compass, or the sun (it rises in the east and sets in the west), then turn clockwise from north by the number of degrees shown.'**
  String get qiblaNoCompassInstructions;

  /// Heading of the no-compass fallback.
  ///
  /// In en, this message translates to:
  /// **'No compass on this device'**
  String get qiblaNoCompassTitle;

  /// Shown when no location has been saved.
  ///
  /// In en, this message translates to:
  /// **'Set your location first so the Qibla direction can be worked out.'**
  String get qiblaNoLocation;

  /// Explains what the degrees mean.
  ///
  /// In en, this message translates to:
  /// **'Measured clockwise from true north'**
  String get qiblaNorthReference;

  /// Shown briefly until the first compass reading arrives.
  ///
  /// In en, this message translates to:
  /// **'Starting the compass'**
  String get qiblaStartingCompass;

  /// Title of the Qibla screen and its entry on the home screen.
  ///
  /// In en, this message translates to:
  /// **'Qibla'**
  String get qiblaTitle;

  /// Plain instruction under the compass arrow.
  ///
  /// In en, this message translates to:
  /// **'Turn until the arrow points straight up'**
  String get qiblaTurnHint;

  /// Screen-reader description of the arrow when the Qibla is to the left.
  ///
  /// In en, this message translates to:
  /// **'Turn {degrees} degrees to the left'**
  String qiblaTurnLeft(int degrees);

  /// Screen-reader description of the arrow when the Qibla is to the right.
  ///
  /// In en, this message translates to:
  /// **'Turn {degrees} degrees to the right'**
  String qiblaTurnRight(int degrees);

  /// No description provided for @reliabilityAllGood.
  ///
  /// In en, this message translates to:
  /// **'Everything looks good.'**
  String get reliabilityAllGood;

  /// No description provided for @reliabilityBattery.
  ///
  /// In en, this message translates to:
  /// **'Battery optimization (Android)'**
  String get reliabilityBattery;

  /// No description provided for @reliabilityBatteryFix.
  ///
  /// In en, this message translates to:
  /// **'On some phones, battery saving can stop alerts. Open the battery settings and let Deen App run in the background.'**
  String get reliabilityBatteryFix;

  /// No description provided for @reliabilityBatteryOk.
  ///
  /// In en, this message translates to:
  /// **'Deen App is not restricted.'**
  String get reliabilityBatteryOk;

  /// No description provided for @reliabilityBatteryOpen.
  ///
  /// In en, this message translates to:
  /// **'Open battery settings'**
  String get reliabilityBatteryOpen;

  /// No description provided for @reliabilityCheckHint.
  ///
  /// In en, this message translates to:
  /// **'Check that your alerts will fire'**
  String get reliabilityCheckHint;

  /// No description provided for @reliabilityCheckTitle.
  ///
  /// In en, this message translates to:
  /// **'Reliability check'**
  String get reliabilityCheckTitle;

  /// No description provided for @reliabilityErrorBudget.
  ///
  /// In en, this message translates to:
  /// **'There are more alerts than this phone can hold, so the later ones were left out until you open the app again.'**
  String get reliabilityErrorBudget;

  /// No description provided for @reliabilityErrorExactDenied.
  ///
  /// In en, this message translates to:
  /// **'Exact alarms are not allowed, so timing may be less precise.'**
  String get reliabilityErrorExactDenied;

  /// No description provided for @reliabilityErrorInvalid.
  ///
  /// In en, this message translates to:
  /// **'The phone could not accept this alert.'**
  String get reliabilityErrorInvalid;

  /// No description provided for @reliabilityErrorPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Notifications are not allowed.'**
  String get reliabilityErrorPermissionDenied;

  /// No description provided for @reliabilityErrorPlatform.
  ///
  /// In en, this message translates to:
  /// **'The alert system did not respond.'**
  String get reliabilityErrorPlatform;

  /// No description provided for @reliabilityErrorServiceBlocked.
  ///
  /// In en, this message translates to:
  /// **'Android blocked the Azaan sound from starting. A notification tone is used instead.'**
  String get reliabilityErrorServiceBlocked;

  /// No description provided for @reliabilityExact.
  ///
  /// In en, this message translates to:
  /// **'Exact alarms (Android)'**
  String get reliabilityExact;

  /// No description provided for @reliabilityExactFix.
  ///
  /// In en, this message translates to:
  /// **'Exact alarms are off, so alerts may be a few minutes late. Allow “Alarms & reminders” for Deen App.'**
  String get reliabilityExactFix;

  /// No description provided for @reliabilityExactOpen.
  ///
  /// In en, this message translates to:
  /// **'Open alarm settings'**
  String get reliabilityExactOpen;

  /// No description provided for @reliabilityFlagInexact.
  ///
  /// In en, this message translates to:
  /// **'Timing may be a few minutes late'**
  String get reliabilityFlagInexact;

  /// No description provided for @reliabilityFlagSilenced.
  ///
  /// In en, this message translates to:
  /// **'Silenced by quiet hours'**
  String get reliabilityFlagSilenced;

  /// No description provided for @reliabilityIntro.
  ///
  /// In en, this message translates to:
  /// **'This screen shows whether your alerts will fire, and how to fix anything that could stop them.'**
  String get reliabilityIntro;

  /// No description provided for @reliabilityIosRefreshNote.
  ///
  /// In en, this message translates to:
  /// **'On iPhone, alerts are refreshed each time you open the app. Open it every few days to keep them going.'**
  String get reliabilityIosRefreshNote;

  /// No description provided for @reliabilityKindRenewal.
  ///
  /// In en, this message translates to:
  /// **'Renewal notice'**
  String get reliabilityKindRenewal;

  /// Last alert: when it was due, then what happened.
  ///
  /// In en, this message translates to:
  /// **'{when}: {result}'**
  String reliabilityLastLine(String when, String result);

  /// No description provided for @reliabilityLastNone.
  ///
  /// In en, this message translates to:
  /// **'No alert has fired yet.'**
  String get reliabilityLastNone;

  /// No description provided for @reliabilityLastTitle.
  ///
  /// In en, this message translates to:
  /// **'Last alert result'**
  String get reliabilityLastTitle;

  /// No description provided for @reliabilityLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'The check could not be completed. Please try again.'**
  String get reliabilityLoadFailed;

  /// No description provided for @reliabilityNextNone.
  ///
  /// In en, this message translates to:
  /// **'Nothing is scheduled.'**
  String get reliabilityNextNone;

  /// Accessibility label of one upcoming alert.
  ///
  /// In en, this message translates to:
  /// **'{title}, {type}, {when}'**
  String reliabilityNextRow(String title, String type, String when);

  /// No description provided for @reliabilityNextTitle.
  ///
  /// In en, this message translates to:
  /// **'Next 5 alerts'**
  String get reliabilityNextTitle;

  /// No description provided for @reliabilityNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get reliabilityNotifications;

  /// No description provided for @reliabilityNotificationsAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications'**
  String get reliabilityNotificationsAllow;

  /// No description provided for @reliabilityNotificationsFix.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off, so alerts cannot appear. Allow notifications for Deen App.'**
  String get reliabilityNotificationsFix;

  /// No description provided for @reliabilityNotificationsSettings.
  ///
  /// In en, this message translates to:
  /// **'Open notification settings'**
  String get reliabilityNotificationsSettings;

  /// No description provided for @reliabilityPermissionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get reliabilityPermissionsTitle;

  /// No description provided for @reliabilityProblemsFound.
  ///
  /// In en, this message translates to:
  /// **'Something needs your attention.'**
  String get reliabilityProblemsFound;

  /// No description provided for @reliabilityRebuildFailed.
  ///
  /// In en, this message translates to:
  /// **'Your alerts could not be updated. {reason}'**
  String reliabilityRebuildFailed(String reason);

  /// No description provided for @reliabilityRefresh.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get reliabilityRefresh;

  /// No description provided for @reliabilityRegistered.
  ///
  /// In en, this message translates to:
  /// **'{count} alerts are registered with the phone.'**
  String reliabilityRegistered(int count);

  /// No description provided for @reliabilityResultAcknowledged.
  ///
  /// In en, this message translates to:
  /// **'Stopped by you'**
  String get reliabilityResultAcknowledged;

  /// No description provided for @reliabilityResultFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get reliabilityResultFailed;

  /// No description provided for @reliabilityResultFired.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get reliabilityResultFired;

  /// No description provided for @reliabilityResultMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get reliabilityResultMissed;

  /// No description provided for @reliabilityResultPlanned.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get reliabilityResultPlanned;

  /// No description provided for @reliabilityResultPlayed.
  ///
  /// In en, this message translates to:
  /// **'Azaan played'**
  String get reliabilityResultPlayed;

  /// No description provided for @reliabilityResultPossiblyMissed.
  ///
  /// In en, this message translates to:
  /// **'Possibly missed'**
  String get reliabilityResultPossiblyMissed;

  /// No description provided for @reliabilityResultSuppressed.
  ///
  /// In en, this message translates to:
  /// **'Silenced'**
  String get reliabilityResultSuppressed;

  /// No description provided for @reliabilityRunsUntilHint.
  ///
  /// In en, this message translates to:
  /// **'Open the app before this date to keep alerts going. It renews them every time.'**
  String get reliabilityRunsUntilHint;

  /// No description provided for @reliabilityRunsUntilNone.
  ///
  /// In en, this message translates to:
  /// **'No alerts are scheduled yet.'**
  String get reliabilityRunsUntilNone;

  /// No description provided for @reliabilityRunsUntilTitle.
  ///
  /// In en, this message translates to:
  /// **'Alerts run until'**
  String get reliabilityRunsUntilTitle;

  /// No description provided for @reliabilitySilentSwitchTip.
  ///
  /// In en, this message translates to:
  /// **'If your iPhone\'s silent switch is on, notification sounds are muted. Tapping the notification plays the full Azaan.'**
  String get reliabilitySilentSwitchTip;

  /// No description provided for @reliabilitySound.
  ///
  /// In en, this message translates to:
  /// **'Notification sound (iPhone)'**
  String get reliabilitySound;

  /// No description provided for @reliabilitySoundFix.
  ///
  /// In en, this message translates to:
  /// **'Sound is off in the notification settings, so alerts will be silent. Allow sound for Deen App.'**
  String get reliabilitySoundFix;

  /// No description provided for @reliabilityStateOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get reliabilityStateOff;

  /// No description provided for @reliabilityStateOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get reliabilityStateOn;

  /// No description provided for @reliabilityTestButton.
  ///
  /// In en, this message translates to:
  /// **'Send a test Azaan in 1 minute'**
  String get reliabilityTestButton;

  /// No description provided for @reliabilityTestFailed.
  ///
  /// In en, this message translates to:
  /// **'The test could not be set. {reason}'**
  String reliabilityTestFailed(String reason);

  /// No description provided for @reliabilityTestNeedsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications first, then try again.'**
  String get reliabilityTestNeedsNotifications;

  /// Confirmation after pressing the test button.
  ///
  /// In en, this message translates to:
  /// **'Test Azaan set for {time}. Lock your phone and wait.'**
  String reliabilityTestScheduled(String time);

  /// No description provided for @reliabilityUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This device cannot schedule alerts, so there is nothing to check here.'**
  String get reliabilityUnsupported;

  /// Hint under the appearance entry.
  ///
  /// In en, this message translates to:
  /// **'Theme, text size and contrast'**
  String get settingsAppearanceHint;

  /// Shown when no settings exist yet.
  ///
  /// In en, this message translates to:
  /// **'Finish setup first. You can change the appearance once your prayer settings are saved.'**
  String get settingsAppearanceNeedsSetup;

  /// Title of the appearance screen and its entry in settings.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearanceTitle;

  /// Hint under the data entry.
  ///
  /// In en, this message translates to:
  /// **'Export, import or delete'**
  String get settingsDataHint;

  /// Title of the data screen and its entry in settings.
  ///
  /// In en, this message translates to:
  /// **'Your data'**
  String get settingsDataTitle;

  /// Explains what deleting does.
  ///
  /// In en, this message translates to:
  /// **'Removes your settings, location, tasbih counts, bookmarks and alert history from this device, and cancels all scheduled alerts.'**
  String get settingsDeleteBody;

  /// Cancel button of the confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get settingsDeleteCancel;

  /// Destructive button of the confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Delete everything'**
  String get settingsDeleteConfirmAction;

  /// Confirmation text; must say that saved export files remain.
  ///
  /// In en, this message translates to:
  /// **'This removes everything the app stores on this device and cannot be undone. Settings files you saved or shared outside the app are not deleted and stay where you put them.'**
  String get settingsDeleteConfirmBody;

  /// Title of the confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Delete all data?'**
  String get settingsDeleteConfirmTitle;

  /// Shown after deletion.
  ///
  /// In en, this message translates to:
  /// **'All data was deleted.'**
  String get settingsDeleteDone;

  /// Shown when some deletion steps failed.
  ///
  /// In en, this message translates to:
  /// **'Some data could not be removed. Please try again.'**
  String get settingsDeletePartial;

  /// Heading and button of the delete section.
  ///
  /// In en, this message translates to:
  /// **'Delete all my data'**
  String get settingsDeleteTitle;

  /// Shown when the user dismisses the share or save dialog.
  ///
  /// In en, this message translates to:
  /// **'Export cancelled.'**
  String get settingsExportCancelled;

  /// Shown after a successful export.
  ///
  /// In en, this message translates to:
  /// **'The settings file is ready.'**
  String get settingsExportDone;

  /// Shown when export fails.
  ///
  /// In en, this message translates to:
  /// **'The settings file could not be created.'**
  String get settingsExportFailed;

  /// Button that opens the system save dialog.
  ///
  /// In en, this message translates to:
  /// **'Save settings file'**
  String get settingsExportSave;

  /// Button that opens the system share sheet.
  ///
  /// In en, this message translates to:
  /// **'Share settings file'**
  String get settingsExportShare;

  /// Heading of the export section.
  ///
  /// In en, this message translates to:
  /// **'Export settings'**
  String get settingsExportTitle;

  /// Plain warning shown before exporting.
  ///
  /// In en, this message translates to:
  /// **'The file contains your saved location and your settings. Anyone who gets the file can see where you are. Share it only with people and places you trust.'**
  String get settingsExportWarning;

  /// Label of the high contrast switch.
  ///
  /// In en, this message translates to:
  /// **'High contrast'**
  String get settingsHighContrast;

  /// Hint under the high contrast switch.
  ///
  /// In en, this message translates to:
  /// **'Stronger text and outline colors. Nothing in the app depends on color alone.'**
  String get settingsHighContrastHint;

  /// Explains import.
  ///
  /// In en, this message translates to:
  /// **'Choose a settings file exported from Deen App. It replaces the settings it contains. If the file has a problem, nothing changes.'**
  String get settingsImportBody;

  /// Button that opens the file picker.
  ///
  /// In en, this message translates to:
  /// **'Choose settings file'**
  String get settingsImportButton;

  /// Shown after a successful import.
  ///
  /// In en, this message translates to:
  /// **'Settings imported.'**
  String get settingsImportDone;

  /// Shown when the settings were saved but rebuilding the schedule failed.
  ///
  /// In en, this message translates to:
  /// **'Settings imported. Alerts will be updated the next time the app opens.'**
  String get settingsImportDoneLater;

  /// Import error: saving failed.
  ///
  /// In en, this message translates to:
  /// **'The settings could not be saved. Nothing was changed.'**
  String get settingsImportFailed;

  /// Import error: a value is invalid. The field is a technical key such as prayer.imsakMinutes.
  ///
  /// In en, this message translates to:
  /// **'The file has a value that is missing or out of range ({field}). Nothing was changed.'**
  String settingsImportInvalid(String field);

  /// Import error: file version is newer.
  ///
  /// In en, this message translates to:
  /// **'This file was made by a newer version of the app. Update the app to read it.'**
  String get settingsImportNewer;

  /// Import error: wrong format.
  ///
  /// In en, this message translates to:
  /// **'This is not a Deen App settings file.'**
  String get settingsImportNotSettings;

  /// Heading of the import section.
  ///
  /// In en, this message translates to:
  /// **'Import settings'**
  String get settingsImportTitle;

  /// Import error: not valid JSON or too large.
  ///
  /// In en, this message translates to:
  /// **'The file could not be read.'**
  String get settingsImportUnreadable;

  /// Shown when saving an appearance change fails.
  ///
  /// In en, this message translates to:
  /// **'This change could not be saved.'**
  String get settingsSaveError;

  /// Label of the text size slider.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get settingsTextSizeLabel;

  /// Tooltip of the button that raises the text size.
  ///
  /// In en, this message translates to:
  /// **'Larger text'**
  String get settingsTextSizeLarger;

  /// Preview line under the text size slider.
  ///
  /// In en, this message translates to:
  /// **'Sample text: this is how text looks at this size.'**
  String get settingsTextSizeSample;

  /// Tooltip of the button that lowers the text size.
  ///
  /// In en, this message translates to:
  /// **'Smaller text'**
  String get settingsTextSizeSmaller;

  /// Current text size as a percentage.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String settingsTextSizeValue(int percent);

  /// Theme choice.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// Label of the theme choice.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsThemeLabel;

  /// Theme choice.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// Theme choice: follow the system.
  ///
  /// In en, this message translates to:
  /// **'Match device'**
  String get settingsThemeSystem;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @setupAsrIntro.
  ///
  /// In en, this message translates to:
  /// **'Choose the school you follow for the start of Asr. Standard is already selected.'**
  String get setupAsrIntro;

  /// No description provided for @setupAsrTitle.
  ///
  /// In en, this message translates to:
  /// **'Asr prayer'**
  String get setupAsrTitle;

  /// No description provided for @setupBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get setupBack;

  /// No description provided for @setupBatteryBody.
  ///
  /// In en, this message translates to:
  /// **'Some phones close apps in the background to save battery, which can delay or stop alerts. Choose your phone brand and follow the steps.'**
  String get setupBatteryBody;

  /// No description provided for @setupBatteryBrandLabel.
  ///
  /// In en, this message translates to:
  /// **'Your phone brand'**
  String get setupBatteryBrandLabel;

  /// No description provided for @setupBatteryGuideUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The steps for this brand could not be loaded. Open the battery settings and allow Deen App to run in the background.'**
  String get setupBatteryGuideUnavailable;

  /// No description provided for @setupBatteryOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open battery settings'**
  String get setupBatteryOpenSettings;

  /// No description provided for @setupBatteryStep.
  ///
  /// In en, this message translates to:
  /// **'Step {number}: {text}'**
  String setupBatteryStep(int number, String text);

  /// No description provided for @setupBatteryTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep alerts reliable'**
  String get setupBatteryTitle;

  /// Explanation of the Android exact-alarm permission.
  ///
  /// In en, this message translates to:
  /// **'Android can ring your alert at the exact prayer time only if you allow exact alarms. Without it, alerts still arrive but can be a few minutes late.'**
  String get setupExactBody;

  /// No description provided for @setupExactCheck.
  ///
  /// In en, this message translates to:
  /// **'I changed it, check again'**
  String get setupExactCheck;

  /// No description provided for @setupExactContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue without it'**
  String get setupExactContinue;

  /// No description provided for @setupExactDenied.
  ///
  /// In en, this message translates to:
  /// **'Exact alarms are off. Alerts will still arrive but may be a few minutes late. The Reliability check shows this.'**
  String get setupExactDenied;

  /// No description provided for @setupExactGranted.
  ///
  /// In en, this message translates to:
  /// **'Exact alarms are allowed.'**
  String get setupExactGranted;

  /// No description provided for @setupExactOpen.
  ///
  /// In en, this message translates to:
  /// **'Open alarm settings'**
  String get setupExactOpen;

  /// No description provided for @setupExactTitle.
  ///
  /// In en, this message translates to:
  /// **'Exact alert timing'**
  String get setupExactTitle;

  /// No description provided for @setupFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish setup'**
  String get setupFinish;

  /// No description provided for @setupLanguageBody.
  ///
  /// In en, this message translates to:
  /// **'You can change this at any time in settings.'**
  String get setupLanguageBody;

  /// No description provided for @setupLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get setupLanguageTitle;

  /// No description provided for @setupLocationApproximate.
  ///
  /// In en, this message translates to:
  /// **'Use my approximate location'**
  String get setupLocationApproximate;

  /// No description provided for @setupLocationApproximateHint.
  ///
  /// In en, this message translates to:
  /// **'Approximate rounds your position to about 10 km. Prayer times change by well under a minute.'**
  String get setupLocationApproximateHint;

  /// Saved name for a rounded position.
  ///
  /// In en, this message translates to:
  /// **'Approximate location'**
  String get setupLocationApproximateName;

  /// Saved name for a place read from the phone's position.
  ///
  /// In en, this message translates to:
  /// **'Current location'**
  String get setupLocationCurrentName;

  /// No description provided for @setupLocationFinding.
  ///
  /// In en, this message translates to:
  /// **'Finding your location…'**
  String get setupLocationFinding;

  /// No description provided for @setupLocationNeeded.
  ///
  /// In en, this message translates to:
  /// **'Choose a location or a city to continue.'**
  String get setupLocationNeeded;

  /// No description provided for @setupLocationOfflineNote.
  ///
  /// In en, this message translates to:
  /// **'The city list is stored in the app, so searching works without internet. You can skip sharing your location and just pick a city.'**
  String get setupLocationOfflineNote;

  /// No description provided for @setupLocationPrecise.
  ///
  /// In en, this message translates to:
  /// **'Use my precise location'**
  String get setupLocationPrecise;

  /// Plain statement that location never leaves the device.
  ///
  /// In en, this message translates to:
  /// **'Your location stays on this device. It is never sent anywhere, and it is only used to calculate prayer times.'**
  String get setupLocationPrivacy;

  /// No description provided for @setupLocationSearchEmpty.
  ///
  /// In en, this message translates to:
  /// **'No city found. Check the spelling or try another name.'**
  String get setupLocationSearchEmpty;

  /// No description provided for @setupLocationSearchHint.
  ///
  /// In en, this message translates to:
  /// **'City name'**
  String get setupLocationSearchHint;

  /// No description provided for @setupLocationSearchLabel.
  ///
  /// In en, this message translates to:
  /// **'Or search for a city'**
  String get setupLocationSearchLabel;

  /// No description provided for @setupLocationSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected: {name}'**
  String setupLocationSelected(String name);

  /// No description provided for @setupLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Your location'**
  String get setupLocationTitle;

  /// No description provided for @setupMethodChange.
  ///
  /// In en, this message translates to:
  /// **'You can choose a different method:'**
  String get setupMethodChange;

  /// No description provided for @setupMethodGeneral.
  ///
  /// In en, this message translates to:
  /// **'There is no regional default for your location, so the general Muslim World League method is suggested.'**
  String get setupMethodGeneral;

  /// No description provided for @setupMethodSuggested.
  ///
  /// In en, this message translates to:
  /// **'Suggested for your region: {method}'**
  String setupMethodSuggested(String method);

  /// No description provided for @setupMethodTitle.
  ///
  /// In en, this message translates to:
  /// **'Calculation method'**
  String get setupMethodTitle;

  /// No description provided for @setupNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get setupNext;

  /// No description provided for @setupNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get setupNotNow;

  /// No description provided for @setupNotificationsAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications'**
  String get setupNotificationsAllow;

  /// Explanation shown before the notification permission prompt.
  ///
  /// In en, this message translates to:
  /// **'To remind you at prayer times, Deen App needs permission to show notifications. Alerts are made on your phone; nothing is sent over the internet.'**
  String get setupNotificationsBody;

  /// No description provided for @setupNotificationsDenied.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off, so prayer alerts will not appear. You can allow them later in app settings.'**
  String get setupNotificationsDenied;

  /// No description provided for @setupNotificationsGranted.
  ///
  /// In en, this message translates to:
  /// **'Notifications are allowed.'**
  String get setupNotificationsGranted;

  /// No description provided for @setupNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Prayer alerts'**
  String get setupNotificationsTitle;

  /// No description provided for @setupOpenAppSettings.
  ///
  /// In en, this message translates to:
  /// **'Open app settings'**
  String get setupOpenAppSettings;

  /// Privacy summary: no personal data collected.
  ///
  /// In en, this message translates to:
  /// **'Deen App collects no personal data.'**
  String get setupPrivacyNoData;

  /// No description provided for @setupPrivacyNoTracking.
  ///
  /// In en, this message translates to:
  /// **'There are no accounts, no ads and no trackers, and the app works without an internet connection.'**
  String get setupPrivacyNoTracking;

  /// No description provided for @setupPrivacyOnDevice.
  ///
  /// In en, this message translates to:
  /// **'Your location, settings and alert history stay on this phone.'**
  String get setupPrivacyOnDevice;

  /// No description provided for @setupPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your privacy'**
  String get setupPrivacyTitle;

  /// No description provided for @setupProblemLocationDenied.
  ///
  /// In en, this message translates to:
  /// **'Location was not allowed. Pick a city from the list instead, or allow location in app settings.'**
  String get setupProblemLocationDenied;

  /// No description provided for @setupProblemLocationTimeout.
  ///
  /// In en, this message translates to:
  /// **'Your location could not be found in time. Try again, or pick a city from the list.'**
  String get setupProblemLocationTimeout;

  /// No description provided for @setupProblemLocationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Location is not available on this phone right now. Pick a city from the list.'**
  String get setupProblemLocationUnavailable;

  /// No description provided for @setupProblemSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Your choice could not be saved. Please try again.'**
  String get setupProblemSaveFailed;

  /// No description provided for @setupProblemZoneUnknown.
  ///
  /// In en, this message translates to:
  /// **'Your phone did not report a time zone. Pick a city from the list.'**
  String get setupProblemZoneUnknown;

  /// Progress through setup.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String setupProgress(int current, int total);

  /// No description provided for @setupSummaryAlerts.
  ///
  /// In en, this message translates to:
  /// **'Prayer alerts will not appear because notifications are off.'**
  String get setupSummaryAlerts;

  /// No description provided for @setupSummaryExact.
  ///
  /// In en, this message translates to:
  /// **'Alerts may arrive a few minutes late because exact alarms are off.'**
  String get setupSummaryExact;

  /// No description provided for @setupSummaryLocation.
  ///
  /// In en, this message translates to:
  /// **'Your phone\'s location is off, so times use the city you chose.'**
  String get setupSummaryLocation;

  /// No description provided for @setupSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'What will not work yet'**
  String get setupSummaryTitle;

  /// No description provided for @setupSummaryWayBack.
  ///
  /// In en, this message translates to:
  /// **'You can allow any of these later in app settings.'**
  String get setupSummaryWayBack;

  /// Title of the first-run setup app bar.
  ///
  /// In en, this message translates to:
  /// **'Set up Deen App'**
  String get setupTitle;

  /// Dismisses a dialog without changes.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get tasbihCancel;

  /// Screen-reader hint of the large tap target.
  ///
  /// In en, this message translates to:
  /// **'Adds one to the count'**
  String get tasbihCountHint;

  /// Screen-reader label of the large tap target.
  ///
  /// In en, this message translates to:
  /// **'Count: {count} of {target}'**
  String tasbihCountLabel(int count, int target);

  /// One-line hint under the Tasbih entry on the home screen.
  ///
  /// In en, this message translates to:
  /// **'Count your dhikr'**
  String get tasbihEntryHint;

  /// Switch label.
  ///
  /// In en, this message translates to:
  /// **'Vibrate on each count'**
  String get tasbihHaptics;

  /// Shown when there are no daily totals.
  ///
  /// In en, this message translates to:
  /// **'No counts yet. Your daily totals appear here.'**
  String get tasbihHistoryEmpty;

  /// Heading of the daily totals list.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get tasbihHistoryTitle;

  /// Switch label; applies only while this screen is open.
  ///
  /// In en, this message translates to:
  /// **'Keep the screen on'**
  String get tasbihKeepAwake;

  /// Switch label for the tap lock.
  ///
  /// In en, this message translates to:
  /// **'Lock touches on the counter'**
  String get tasbihLock;

  /// Explains the tap lock.
  ///
  /// In en, this message translates to:
  /// **'A stray touch will not add a count. The volume keys still count.'**
  String get tasbihLockHint;

  /// Shown on the counter while the tap lock is on.
  ///
  /// In en, this message translates to:
  /// **'Locked. Touches on the counter are ignored.'**
  String get tasbihLockedMessage;

  /// Shown under the large count, for example 'of 33'.
  ///
  /// In en, this message translates to:
  /// **'of {target}'**
  String tasbihOfTarget(int target);

  /// Heading of the switches below the counter.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get tasbihOptionsTitle;

  /// Button that sets the count back to zero (after confirmation).
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get tasbihReset;

  /// Body of the reset confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'The count goes back to 0. Your daily totals are kept.'**
  String get tasbihResetBody;

  /// Title of the reset confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Reset the counter?'**
  String get tasbihResetTitle;

  /// How many times the target was reached since the last reset.
  ///
  /// In en, this message translates to:
  /// **'Rounds completed: {rounds}'**
  String tasbihRounds(int rounds);

  /// Confirms the custom target.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get tasbihSave;

  /// Plain error message when the database write fails.
  ///
  /// In en, this message translates to:
  /// **'Could not save the count. Try again.'**
  String get tasbihSaveError;

  /// Switch label for the optional tick sound.
  ///
  /// In en, this message translates to:
  /// **'Tap sound'**
  String get tasbihSound;

  /// Choice that opens the custom target dialog.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get tasbihTargetCustom;

  /// Label of the number field in the custom target dialog.
  ///
  /// In en, this message translates to:
  /// **'Target (1 to 100000)'**
  String get tasbihTargetCustomField;

  /// Screen-reader label of the custom choice when a custom target is active.
  ///
  /// In en, this message translates to:
  /// **'Custom target: {target}'**
  String tasbihTargetCustomLabel(int target);

  /// Title of the custom target dialog.
  ///
  /// In en, this message translates to:
  /// **'Custom target'**
  String get tasbihTargetCustomTitle;

  /// Heading above the target choices.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get tasbihTargetHeading;

  /// Error under the custom target field.
  ///
  /// In en, this message translates to:
  /// **'Enter a whole number from 1 to 100000.'**
  String get tasbihTargetInvalid;

  /// Screen-reader label of a target choice (33 or 99).
  ///
  /// In en, this message translates to:
  /// **'Target {target}'**
  String tasbihTargetOptionLabel(int target);

  /// Announced to screen readers when the count reaches the target.
  ///
  /// In en, this message translates to:
  /// **'Target of {target} reached'**
  String tasbihTargetReached(int target);

  /// Title of the Tasbih counter screen and its entry on the home screen.
  ///
  /// In en, this message translates to:
  /// **'Tasbih'**
  String get tasbihTitle;

  /// Total counted today, across resets.
  ///
  /// In en, this message translates to:
  /// **'Today: {total}'**
  String tasbihTodayTotal(int total);

  /// Button that turns the tap lock off with a long press.
  ///
  /// In en, this message translates to:
  /// **'Hold to unlock'**
  String get tasbihUnlock;

  /// Message shown after a short press on the unlock button.
  ///
  /// In en, this message translates to:
  /// **'Press and hold the button to unlock.'**
  String get tasbihUnlockPressHint;

  /// Switch label, Android only.
  ///
  /// In en, this message translates to:
  /// **'Count with the volume keys'**
  String get tasbihVolumeKeys;

  /// Explains the volume key option.
  ///
  /// In en, this message translates to:
  /// **'While this screen is open the volume keys count instead of changing the volume.'**
  String get tasbihVolumeKeysHint;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'id', 'ur'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
    case 'ur':
      return AppLocalizationsUr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
