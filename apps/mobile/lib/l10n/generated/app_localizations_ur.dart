// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Urdu (`ur`).
class AppLocalizationsUr extends AppLocalizations {
  AppLocalizationsUr([String locale = 'ur']) : super(locale);

  @override
  String get aboutAttributionsTitle => 'اعترافات';

  @override
  String get aboutCitiesHeading => 'شہروں کا ڈیٹا';

  @override
  String get aboutContentHeading => 'اذکار کے متون';

  @override
  String get aboutDescription =>
      'نماز کے اوقات، اذان کے الرٹس اور روزمرہ عبادت کے اوزار۔ سب کچھ بغیر انٹرنیٹ کے چلتا ہے۔';

  @override
  String get aboutEntryHint => 'لائسنس، ماخذ اور رازداری';

  @override
  String get aboutFontsHeading => 'فونٹس';

  @override
  String get aboutHijriHeading => 'ہجری کیلنڈر کا ڈیٹا';

  @override
  String get aboutLegalEnglishNote =>
      'نیچے کی عبارت لائسنس کے الفاظ ہیں اور انگریزی میں ہی رہتی ہے۔';

  @override
  String get aboutLicensesSubtitle =>
      'اس ایپ میں استعمال ہونے والے سافٹ ویئر کے لائسنس';

  @override
  String get aboutLicensesTitle => 'اوپن سورس لائسنس';

  @override
  String get aboutNoDataCollected =>
      'ایپ کوئی ڈیٹا جمع نہیں کرتی۔ نہ اکاؤنٹ ہیں، نہ تجزیات اور نہ اشتہارات۔ آپ کا مقام اسی آلے پر رہتا ہے اور صرف نماز کے اوقات اور قبلہ کی سمت معلوم کرنے کے لیے استعمال ہوتا ہے۔';

  @override
  String get aboutPrivacyHeading => 'آپ کی رازداری';

  @override
  String aboutPrivacyPolicyAddress(String address) {
    return 'مکمل پالیسی یہاں پڑھیں: $address';
  }

  @override
  String get aboutPrivacyPolicyPending =>
      'مکمل رازداری کی پالیسی ریلیز سے پہلے شائع کی جائے گی۔ اس میں بھی یہی لکھا ہوگا: ایپ کوئی ڈیٹا جمع نہیں کرتی۔';

  @override
  String get aboutPrivacyPolicyTitle => 'رازداری کی پالیسی';

  @override
  String get aboutTitle => 'ایپ کے بارے میں';

  @override
  String aboutVersion(String version) {
    return 'ورژن $version';
  }

  @override
  String get adhkarBookmarkAdd => 'بک مارک شامل کریں';

  @override
  String get adhkarBookmarkRemove => 'بک مارک ہٹائیں';

  @override
  String get adhkarBookmarksEmpty =>
      'آپ نے ابھی کچھ بھی بک مارک نہیں کیا۔ کسی ذکر کو یہاں محفوظ کرنے کے لیے اس پر بک مارک کا بٹن دبائیں۔';

  @override
  String get adhkarBookmarksTitle => 'بک مارکس';

  @override
  String get adhkarCollectionAfterPrayer => 'نماز کے بعد کے اذکار';

  @override
  String get adhkarCollectionBeforeSleep => 'سونے سے پہلے کے اذکار';

  @override
  String get adhkarCollectionEvening => 'شام کے اذکار';

  @override
  String get adhkarCollectionMorning => 'صبح کے اذکار';

  @override
  String get adhkarCollectionOther => 'دیگر اذکار';

  @override
  String get adhkarCollectionWaking => 'جاگنے کے اذکار';

  @override
  String adhkarCountLabel(int done, int total) {
    return 'گننے کے لیے دبائیں: $total میں سے $done';
  }

  @override
  String adhkarCreditEntry(int order, String reference) {
    return 'ذکر $order: $reference';
  }

  @override
  String adhkarCreditReviewer(String reviewer, String date) {
    return 'جائزہ: $reviewer، تاریخ: $date۔';
  }

  @override
  String adhkarCreditSource(String source, String license) {
    return 'ماخذ: $source۔ لائسنس: $license۔';
  }

  @override
  String adhkarCreditsCount(int count) {
    return 'درج متون کی تعداد: $count';
  }

  @override
  String get adhkarCreditsEmpty =>
      'اس ورژن میں اذکار کے متن شامل نہیں ہیں، اس لیے فی الحال درج کرنے کے لیے کوئی ماخذ نہیں۔';

  @override
  String get adhkarCreditsIntro =>
      'ہر متن کے ساتھ اس کا ماخذ، لائسنس اور جائزہ لینے والے کا نام درج ہے۔';

  @override
  String get adhkarCreditsTitle => 'مواد کے ماخذ اور جائزہ لینے والے';

  @override
  String get adhkarEmptyBody =>
      'ایپ کے اس ورژن میں ابھی اذکار کے متن شامل نہیں ہیں۔ انہیں صرف اس کے بعد شامل کیا جائے گا جب ان کے ماخذ کی اجازت مل جائے اور کوئی عالم ان کا جائزہ لے لے۔';

  @override
  String get adhkarEmptyTitle => 'اذکار ابھی دستیاب نہیں ہیں';

  @override
  String adhkarEntryCount(int count) {
    return 'اذکار کی تعداد: $count';
  }

  @override
  String get adhkarEntryDone => 'مکمل';

  @override
  String get adhkarEntryHint => 'روزانہ کے اذکار، بک مارکس اور یاد دہانیاں';

  @override
  String get adhkarLoadError => 'اذکار لوڈ نہیں ہو سکے۔';

  @override
  String get adhkarNext => 'اگلا ذکر';

  @override
  String get adhkarNotFound => 'یہ مجموعہ دستیاب نہیں ہے۔';

  @override
  String adhkarPosition(int position, int total) {
    return '$total میں سے ذکر $position';
  }

  @override
  String get adhkarPrevious => 'پچھلا ذکر';

  @override
  String adhkarProgressLabel(int done, int total) {
    return '$total میں سے $done اذکار مکمل';
  }

  @override
  String adhkarReminderAfter(int minutes, String prayer) {
    return '$prayer کے $minutes منٹ بعد';
  }

  @override
  String get adhkarReminderAnchor => 'وقت کس نماز سے گنیں';

  @override
  String adhkarReminderAt(String prayer) {
    return '$prayer کے وقت';
  }

  @override
  String adhkarReminderBefore(int minutes, String prayer) {
    return '$prayer سے $minutes منٹ پہلے';
  }

  @override
  String get adhkarReminderEarlier => '5 منٹ پہلے';

  @override
  String get adhkarReminderEnable => 'مجھے یاد دلائیں';

  @override
  String get adhkarReminderEvening => 'شام کی یاد دہانی';

  @override
  String get adhkarReminderFajrOnly =>
      'صبح کی یاد دہانی فجر کے وقت کے مطابق ہوتی ہے۔';

  @override
  String get adhkarReminderLater => '5 منٹ بعد';

  @override
  String get adhkarReminderMorning => 'صبح کی یاد دہانی';

  @override
  String get adhkarReminderNote =>
      'یاد دہانیاں اس آلے پر نوٹیفکیشن ہوتی ہیں۔ یہ آپ کی نماز کے اوقات کے مطابق ہوتی ہیں، اس لیے مقام اور حساب کے طریقے کے ساتھ بدل جاتی ہیں۔';

  @override
  String get adhkarReminderSaveError => 'یاد دہانی محفوظ نہیں ہو سکی۔';

  @override
  String get adhkarRemindersTitle => 'اذکار کی یاد دہانیاں';

  @override
  String adhkarRepeatLabel(int count) {
    return 'تکرار کی تعداد: $count';
  }

  @override
  String get adhkarSessionComplete => 'سیشن مکمل ہوا';

  @override
  String adhkarSourceLabel(String reference) {
    return 'ماخذ: $reference';
  }

  @override
  String get adhkarStartAgain => 'دوبارہ شروع کریں';

  @override
  String get adhkarTitle => 'اذکار';

  @override
  String get adhkarTranslationFallbackHeading =>
      'ترجمہ (انگریزی؛ آپ کی زبان میں ابھی دستیاب نہیں)';

  @override
  String get adhkarTranslationHeading => 'ترجمہ';

  @override
  String get adhkarTransliterationHeading => 'رومن حروف میں';

  @override
  String get adhkarUndo => 'آخری گنتی واپس کریں';

  @override
  String get alertAudioIntro =>
      'ہیڈ فون یا بلوٹوتھ ڈیوائس جڑی ہو تو اذان کہاں چلے۔ ان کے بغیر اذان اسپیکر پر چلتی ہے۔';

  @override
  String get alertAudioTitle => 'آڈیو آؤٹ پٹ';

  @override
  String get alertCauseAppNotRun => 'ایپ کھولی نہیں گئی تھی۔';

  @override
  String get alertCauseBatteryRestricted =>
      'ہو سکتا ہے بیٹری بچت نے اسے روک دیا ہو۔ بیٹری کی ترتیبات دیکھیں۔';

  @override
  String get alertCauseCallInProgress => 'فون کال جاری تھی۔';

  @override
  String get alertCauseExactAlarmDenied =>
      'درست الارم بند ہیں، اس لیے اینڈرائیڈ نے اسے مؤخر کیا ہو گا۔';

  @override
  String get alertCauseFgsBlocked =>
      'اینڈرائیڈ نے ایپ کو اذان شروع کرنے نہیں دی، اس لیے نوٹیفکیشن کی آواز استعمال ہوئی۔';

  @override
  String get alertCauseNotificationDenied => 'نوٹیفکیشن بند تھے۔';

  @override
  String get alertCauseQuietHours => 'خاموش اوقات کی وجہ سے خاموش کیا گیا۔';

  @override
  String get alertCauseScheduleEnded =>
      'ایپ طویل عرصے تک نہ کھلنے سے مقررہ الرٹس ختم ہو گئے۔ اب کھولنے سے وہ دوبارہ مقرر ہو گئے۔';

  @override
  String get alertCauseSilentMode => 'فون خاموش موڈ میں تھا۔';

  @override
  String get alertCauseUnknown => 'وجہ معلوم نہیں۔';

  @override
  String get alertExactBody =>
      'نماز کے عین وقت پر آواز کے لیے اینڈرائیڈ کو ایپ کے لیے «الارم اور یاد دہانیاں» کی اجازت درکار ہے۔ اس کے بغیر الرٹس آئیں گے مگر چند منٹ دیر سے ہو سکتے ہیں۔';

  @override
  String get alertExactCheck => 'میں نے بدل دیا، دوبارہ جانچیں';

  @override
  String get alertExactGranted => 'درست الارم آن ہیں۔';

  @override
  String get alertExactInexact =>
      'الرٹس پھر بھی آئیں گے مگر وقت کم درست ہو سکتا ہے۔ آپ اسے بعد میں اعتماد کی جانچ میں بدل سکتے ہیں۔';

  @override
  String get alertExactOpen => 'الارم کی ترتیبات کھولیں';

  @override
  String get alertExactSkip => 'اس کے بغیر جاری رکھیں';

  @override
  String get alertExactTitle => 'درست الارم کی اجازت دیں؟';

  @override
  String get alertIgnoreQuietHours => 'خاموش اوقات کو نظر انداز کریں';

  @override
  String get alertIgnoreQuietHoursHint =>
      'خاموش اوقات میں بھی اس الرٹ کی آواز برقرار رکھیں۔';

  @override
  String get alertLoudAndroidOnly =>
      'بلند موڈ صرف اینڈرائیڈ پر دستیاب ہے۔ آئی فون پر خاموش سوئچ نوٹیفکیشن کی آواز بند کر دیتا ہے؛ نوٹیفکیشن پر ٹیپ کرنے سے مکمل اذان پھر بھی چلتی ہے۔';

  @override
  String get alertLoudIntro =>
      'بطور ڈیفالٹ بند ہے۔ کسی نماز کے لیے آن ہو تو فون خاموش ہونے پر بھی اذان سنائی دیتی ہے۔ آپ کے منتخب کیے بغیر ایپ سسٹم کی آواز نہیں بدلتی۔';

  @override
  String alertLoudSwitch(String prayer) {
    return '$prayer کے لیے بلند موڈ';
  }

  @override
  String get alertLoudTitle => 'بلند موڈ';

  @override
  String get alertMissedDismiss => 'بند کریں';

  @override
  String alertMissedLine(String when, String cause) {
    return '$when: $cause';
  }

  @override
  String alertMissedMore(int count) {
    return 'اور $count مزید';
  }

  @override
  String get alertMissedOpenCheck => 'اعتماد کی جانچ کھولیں';

  @override
  String get alertMissedPossibly =>
      'آئی فون ڈیلیوری کی تصدیق نہیں کر سکتا، اس لیے یہ صرف ممکنہ طور پر رہ گیا ہے۔';

  @override
  String get alertMissedTitle => 'ہو سکتا ہے ایک الرٹ نہ بجا ہو';

  @override
  String get alertMissedTitleMany => 'ہو سکتا ہے کچھ الرٹ نہ بجے ہوں';

  @override
  String get alertNotifAdhkarEveningBody => 'شام کے اذکار کا اچھا وقت۔';

  @override
  String get alertNotifAdhkarEveningTitle => 'شام کے اذکار';

  @override
  String get alertNotifAdhkarMorningBody => 'صبح کے اذکار کا اچھا وقت۔';

  @override
  String get alertNotifAdhkarMorningTitle => 'صبح کے اذکار';

  @override
  String alertNotifPrayerBody(String prayer) {
    return '$prayer کا وقت ہو گیا ہے۔';
  }

  @override
  String alertNotifPrayerTitle(String prayer) {
    return '$prayer کی نماز';
  }

  @override
  String alertNotifPreBody(String prayer) {
    return '$prayer کی نماز کی تیاری کریں۔';
  }

  @override
  String alertNotifPreTitle(String prayer, int minutes) {
    return '$prayer میں $minutes منٹ';
  }

  @override
  String get alertNotifRenewalBody =>
      'آپ کے مقررہ الرٹس جلد ختم ہو جائیں گے۔ ایپ ایک بار کھولیں، یہ دوبارہ مقرر ہو جائیں گے۔';

  @override
  String get alertNotifRenewalTitle => 'الرٹس جاری رکھنے کے لیے ایپ کھولیں';

  @override
  String get alertNotifStopLabel => 'بند کریں';

  @override
  String alertNotifSuhoorBody(int minutes) {
    return 'فجر میں $minutes منٹ باقی ہیں۔';
  }

  @override
  String get alertNotifSuhoorTitle => 'سحری کی یاد دہانی';

  @override
  String get alertOptionsTile => 'مزید الرٹ اختیارات';

  @override
  String get alertOptionsTileHint =>
      'بلند موڈ، خاموش اوقات، یاد دہانیاں اور آڈیو آؤٹ پٹ';

  @override
  String get alertOptionsTitle => 'الرٹ کے اختیارات';

  @override
  String get alertOutputBluetooth => 'بلوٹوتھ';

  @override
  String get alertOutputHeadphones => 'ہیڈ فون';

  @override
  String get alertOutputSpeaker => 'اسپیکر';

  @override
  String get alertPreviewFailed => 'یہ ریکارڈنگ نہیں چلائی جا سکی۔';

  @override
  String alertPreviewPlay(String name) {
    return '$name چلائیں';
  }

  @override
  String get alertPreviewStop => 'پیش نظارہ بند کریں';

  @override
  String get alertQuietEnd => 'اختتام';

  @override
  String get alertQuietIntro =>
      'خاموش اوقات میں آواز والے الرٹس خاموش نوٹیفکیشن بن جاتے ہیں، سوائے اس نماز کے جسے نظر انداز کرنے پر سیٹ کیا گیا ہو۔';

  @override
  String alertQuietRange(String start, String end) {
    return 'خاموش اوقات $start سے $end تک';
  }

  @override
  String get alertQuietStart => 'آغاز';

  @override
  String get alertQuietSwitch => 'خاموش اوقات استعمال کریں';

  @override
  String get alertQuietTitle => 'خاموش اوقات';

  @override
  String alertReminderFor(String prayer) {
    return '$prayer کے لیے یاد دہانی';
  }

  @override
  String get alertReminderIntro =>
      'یاد دہانی کبھی مکمل اذان نہیں ہوتی؛ زیادہ سے زیادہ مختصر آواز ہوتی ہے۔';

  @override
  String alertReminderMinutes(int minutes) {
    return '$minutes منٹ پہلے';
  }

  @override
  String get alertReminderNone => 'کوئی یاد دہانی نہیں';

  @override
  String alertReminderSummary(int minutes) {
    return '$minutes منٹ پہلے یاد دہانی';
  }

  @override
  String get alertReminderTitle => 'ہر نماز سے پہلے یاد دہانی';

  @override
  String get alertSaveFailed =>
      'یہ انتخاب محفوظ نہیں ہو سکا۔ براہِ کرم دوبارہ کوشش کریں۔';

  @override
  String get alertSettingsIntro => 'ہر نماز کے وقت پر کیا ہو، یہ منتخب کریں۔';

  @override
  String get alertSettingsTitle => 'نماز کے الرٹس';

  @override
  String get alertSilentSwitchBody =>
      'جب آپ کے آئی فون کا خاموش سوئچ آن ہو تو نوٹیفکیشن کی آواز بند ہو جاتی ہے۔ نوٹیفکیشن پر ٹیپ کرنے سے مکمل اذان پھر بھی چلتی ہے۔ آپ اس کی جگہ ارتعاش بھی منتخب کر سکتے ہیں۔';

  @override
  String get alertSilentSwitchGotIt => 'سمجھ گیا';

  @override
  String get alertSilentSwitchTitle => 'خاموش سوئچ کے بارے میں';

  @override
  String get alertSilentSwitchVibrate =>
      'میرے الرٹس کے لیے ارتعاش استعمال کریں';

  @override
  String get alertSuhoorIntro =>
      'رمضان میں فجر سے پہلے یاد دہانی تاکہ آپ وقت پر سحری کر سکیں۔';

  @override
  String alertSuhoorMinutes(int minutes) {
    return 'فجر سے $minutes منٹ پہلے';
  }

  @override
  String get alertSuhoorSwitch => 'سحری ختم ہونے سے پہلے یاد دلائیں';

  @override
  String get alertSuhoorTitle => 'سحری کی یاد دہانی';

  @override
  String get alertTypeFullAzaan => 'مکمل اذان';

  @override
  String alertTypeGroupLabel(String prayer) {
    return '$prayer کا الرٹ';
  }

  @override
  String get alertTypeOff => 'بند';

  @override
  String get alertTypeShortTone => 'مختصر آواز';

  @override
  String get alertTypeSilent => 'خاموش نوٹیفکیشن';

  @override
  String get alertTypeVibrate => 'ارتعاش';

  @override
  String get alertVariantFajr => 'فجر کا ورژن';

  @override
  String get alertVariantFajrHint =>
      'اس میں «الصلاۃ خیر من النوم» شامل ہے۔ معیاری منتخب ہونے پر فجر میں چلتی ہے۔';

  @override
  String get alertVariantShia => 'شیعہ الفاظ';

  @override
  String get alertVariantShiaHint =>
      'شیعہ الفاظ کے ساتھ اذان۔ منتخب ہونے پر پانچوں نمازوں میں چلتی ہے۔';

  @override
  String get alertVariantStandard => 'معیاری';

  @override
  String get alertVariantStandardHint =>
      'معمول کی اذان۔ فجر پر فجر کی ریکارڈنگ چلتی ہے۔';

  @override
  String alertVoiceForPrayer(String prayer) {
    return '$prayer کے لیے';
  }

  @override
  String get alertVoiceIntro =>
      'ہر آواز کی تین ریکارڈنگز ہیں۔ منتخب کرنے سے پہلے سننے کے لیے پلے دبائیں۔';

  @override
  String alertVoiceName(int number) {
    return 'آواز $number';
  }

  @override
  String get alertVoiceSelected => 'منتخب';

  @override
  String get alertVoiceTile => 'آواز';

  @override
  String alertVoiceTileValue(String voice, String variant) {
    return '$voice، $variant';
  }

  @override
  String get alertVoiceTitle => 'آواز منتخب کریں';

  @override
  String get alertVolumeKeep => 'میری موجودہ آواز برقرار رکھیں';

  @override
  String get alertVolumeRamp => 'آہستہ آہستہ بڑھائیں';

  @override
  String get alertVolumeRampHint =>
      'آہستہ شروع ہو کر چند سیکنڈ میں بلند ہوتی ہے۔';

  @override
  String get appTitle => 'Deen App';

  @override
  String get asrHanafiBody =>
      'عصر اس وقت شروع ہوتی ہے جب سایہ چیز کی لمبائی سے دوگنا ہو جائے، اس لیے عصر دیر سے شروع ہوتی ہے (حنفی مکتب اسی پر ہے)۔';

  @override
  String get asrHanafiTitle => 'حنفی';

  @override
  String get asrStandardBody =>
      'عصر اس وقت شروع ہوتی ہے جب کسی چیز کا سایہ اس کی اپنی لمبائی کے برابر ہو جائے (شافعی، مالکی اور حنبلی مکاتب اسی پر ہیں)۔';

  @override
  String get asrStandardTitle => 'معیاری';

  @override
  String detailHijriAdjusted(String days) {
    return 'اس میں آپ کی $days دن کی ایڈجسٹمنٹ شامل ہے (ام القریٰ کیلنڈر)۔';
  }

  @override
  String get detailHijriDefault => 'ام القریٰ کیلنڈر۔';

  @override
  String get detailHijriTitle => 'ہجری تاریخ';

  @override
  String get detailHijriUnavailable => 'ہجری تاریخ ابھی دستیاب نہیں۔';

  @override
  String detailHijriValue(String day, String month, String year) {
    return '$day $month $year ھ';
  }

  @override
  String get detailImsak => 'امساک';

  @override
  String get detailLastThird => 'رات کا آخری تہائی حصہ';

  @override
  String get detailMidnight => 'نصف شب';

  @override
  String get errorGeneric => 'کچھ غلط ہو گیا۔ براہِ کرم دوبارہ کوشش کریں۔';

  @override
  String get highLatAngleBody =>
      'فجر اور عشاء کے لیے رات کا وہ حصہ لیا جاتا ہے جو شفق کے زاویے کو 60 سے تقسیم کرنے پر آتا ہے۔';

  @override
  String get highLatAngleTitle => 'زاویے کے مطابق';

  @override
  String highLatApplied(String rule) {
    return 'آپ کا عرض بلد 48 ڈگری سے اوپر ہے جہاں شفق ختم نہیں ہو سکتی، اس لیے فجر اور عشاء کا اندازہ «$rule» قاعدے سے لگایا گیا۔ آپ نماز کی ترتیبات میں قاعدہ بدل سکتے ہیں۔';
  }

  @override
  String get highLatMiddleBody =>
      'رات کو دو برابر حصوں میں بانٹا جاتا ہے: عشاء رات کے درمیان سے دیر سے نہیں ہوتی اور فجر اس سے پہلے نہیں ہوتی۔';

  @override
  String get highLatMiddleTitle => 'رات کا درمیان';

  @override
  String get highLatSeventhBody =>
      'رات کو سات حصوں میں بانٹا جاتا ہے: عشاء غروب کے بعد زیادہ سے زیادہ ایک حصہ اور فجر طلوع سے ایک حصہ پہلے ہوتی ہے۔';

  @override
  String get highLatSeventhTitle => 'رات کا ساتواں حصہ';

  @override
  String get hijriMonth1 => 'محرم';

  @override
  String get hijriMonth10 => 'شوال';

  @override
  String get hijriMonth11 => 'ذوالقعدہ';

  @override
  String get hijriMonth12 => 'ذوالحجہ';

  @override
  String get hijriMonth2 => 'صفر';

  @override
  String get hijriMonth3 => 'ربیع الاول';

  @override
  String get hijriMonth4 => 'ربیع الثانی';

  @override
  String get hijriMonth5 => 'جمادی الاولیٰ';

  @override
  String get hijriMonth6 => 'جمادی الثانیہ';

  @override
  String get hijriMonth7 => 'رجب';

  @override
  String get hijriMonth8 => 'شعبان';

  @override
  String get hijriMonth9 => 'رمضان';

  @override
  String get homeBackToToday => 'آج پر واپس';

  @override
  String get homeBannerDismiss => 'بند کریں';

  @override
  String get homeChooseLocation => 'مقام منتخب کریں';

  @override
  String get homeClockBeforeBuild =>
      'آپ کے فون کی تاریخ غلط لگتی ہے: یہ ایپ کے اس ورژن سے پرانی ہے۔ نماز کے اوقات اور الرٹس غلط ہو سکتے ہیں۔ براہِ کرم فون کی ترتیبات میں تاریخ اور وقت دیکھیں۔';

  @override
  String get homeClockDrifted =>
      'آپ کے فون کی گھڑی بدلی گئی ہے۔ اگر وقت غلط ہے تو نماز کے اوقات اور الرٹس غلط ہو سکتے ہیں۔ براہِ کرم فون کی ترتیبات میں تاریخ اور وقت دیکھیں۔';

  @override
  String get homeClockMovedBack =>
      'آپ کے فون کی گھڑی پیچھے کر دی گئی ہے۔ اگر وقت غلط ہے تو نماز کے اوقات اور الرٹس غلط ہو سکتے ہیں۔ براہِ کرم فون کی ترتیبات میں تاریخ اور وقت دیکھیں۔';

  @override
  String homeCountdownSemantics(String prayer, int hours, int minutes) {
    return '$prayer میں $hours گھنٹے $minutes منٹ باقی';
  }

  @override
  String get homeError =>
      'نماز کے اوقات نہیں نکالے جا سکے۔ مقام دیکھیں اور دوبارہ کوشش کریں۔';

  @override
  String get homeMoreTimes => 'مزید اوقات';

  @override
  String get homeNextBadge => 'اگلی';

  @override
  String get homeNextDay => 'اگلا دن';

  @override
  String get homeNoLocation => 'نماز کے اوقات دیکھنے کے لیے مقام منتخب کریں۔';

  @override
  String get homePreviousDay => 'پچھلا دن';

  @override
  String homeRegionSuggestion(String method) {
    return 'اس علاقے میں عموماً $method استعمال ہوتا ہے۔ آپ کا منتخب کردہ طریقہ جوں کا توں رہے گا۔';
  }

  @override
  String homeRegionSuggestionGeneral(String method) {
    return 'اس مقام کے لیے کوئی علاقائی طریقہ مقرر نہیں۔ $method ایک عمومی انتخاب ہے۔ آپ کا منتخب کردہ طریقہ جوں کا توں رہے گا۔';
  }

  @override
  String homeRegionSuggestionSwitch(String method) {
    return '$method پر جائیں';
  }

  @override
  String get homeTimeNotAvailable => 'آج واقع نہیں ہوتا';

  @override
  String homeTimeSemantics(String prayer, String time) {
    return '$prayer $time بجے';
  }

  @override
  String get homeTitle => 'نماز کے اوقات';

  @override
  String get homeToday => 'آج';

  @override
  String get homeTzRulesNotice =>
      'ٹائم زون کے قواعد بدل چکے ہوں گے۔ براہِ کرم ایپ اپڈیٹ کریں۔ تب تک اوقات آپ کے فون کے قواعد کے مطابق رہیں گے۔';

  @override
  String get languageNameAr => 'العربية';

  @override
  String get languageNameEn => 'English';

  @override
  String get languageNameId => 'Bahasa Indonesia';

  @override
  String get languageNameUr => 'اردو';

  @override
  String get languageSettingsTitle => 'زبان';

  @override
  String get loading => 'لوڈ ہو رہا ہے';

  @override
  String locationSettingsCurrent(String name) {
    return 'موجودہ مقام: $name';
  }

  @override
  String get locationSettingsNone => 'ابھی کوئی مقام محفوظ نہیں۔';

  @override
  String get locationSettingsSaved => 'مقام محفوظ ہو گیا۔ الرٹس اپڈیٹ ہوں گے۔';

  @override
  String get locationSettingsTitle => 'مقام';

  @override
  String get methodDiyanet => 'ترکی (دیانت)';

  @override
  String get methodEgypt => 'مصری جنرل اتھارٹی آف سروے';

  @override
  String get methodFranceUoif => 'فرانس (UOIF)';

  @override
  String get methodGulf => 'خلیجی خطہ';

  @override
  String get methodIsna => 'آئی ایس این اے (شمالی امریکہ)';

  @override
  String get methodJafari => 'شیعہ اثنا عشری (جعفری)';

  @override
  String get methodKarachi => 'جامعہ علومِ اسلامیہ، کراچی';

  @override
  String get methodKuwait => 'کویت';

  @override
  String get methodMoonsightingCommittee => 'مون سائٹنگ کمیٹی';

  @override
  String get methodMuslimWorldLeague => 'مسلم ورلڈ لیگ';

  @override
  String get methodQatar => 'قطر';

  @override
  String get methodSingapore => 'سنگاپور (MUIS)';

  @override
  String get methodTehran => 'انسٹیٹیوٹ آف جیوفزکس، تہران یونیورسٹی';

  @override
  String get methodUmmAlQura => 'ام القریٰ (مکہ مکرمہ)';

  @override
  String get nextPrayerLabel => 'اگلی نماز';

  @override
  String get oemBrandHuawei => 'Huawei, Honor';

  @override
  String get oemBrandOneplus => 'OnePlus';

  @override
  String get oemBrandOppo => 'Oppo, realme';

  @override
  String get oemBrandOther => 'کوئی اور برانڈ';

  @override
  String get oemBrandSamsung => 'Samsung';

  @override
  String get oemBrandVivo => 'Vivo, iQOO';

  @override
  String get oemBrandXiaomi => 'Xiaomi, Redmi, POCO';

  @override
  String get permissionBannerAction => 'ترتیبات میں درست کریں';

  @override
  String get permissionBannerAlerts =>
      'نوٹیفکیشن بند ہیں۔ نماز کے الرٹس نظر نہیں آئیں گے۔';

  @override
  String get permissionBannerExact =>
      'درست الارم بند ہیں۔ الرٹس چند منٹ دیر سے آ سکتے ہیں۔';

  @override
  String get permissionBannerLocation =>
      'مقام بند ہے۔ اوقات آپ کے محفوظ شہر کے مطابق ہیں۔';

  @override
  String get prayerAsr => 'عصر';

  @override
  String get prayerDhuhr => 'ظہر';

  @override
  String get prayerFajr => 'فجر';

  @override
  String get prayerIsha => 'عشاء';

  @override
  String get prayerJumuah => 'جمعہ';

  @override
  String get prayerMaghrib => 'مغرب';

  @override
  String get prayerSettingsHighLatIntro =>
      '48 ڈگری سے اوپر کے عرض بلد پر گرمیوں میں شفق ختم نہیں ہوتی۔ منتخب کریں کہ اس وقت فجر اور عشاء کا اندازہ کیسے لگایا جائے۔';

  @override
  String get prayerSettingsHighLatTitle => 'بلند عرض بلد';

  @override
  String get prayerSettingsHijriLess => 'ہجری تاریخ ایک دن پیچھے کریں';

  @override
  String get prayerSettingsHijriMore => 'ہجری تاریخ ایک دن آگے کریں';

  @override
  String get prayerSettingsHijriTitle => 'ہجری تاریخ میں ردوبدل (دنوں میں)';

  @override
  String prayerSettingsHijriValue(String value) {
    return '$value دن';
  }

  @override
  String get prayerSettingsNoLocation =>
      'پہلے مقام منتخب کریں۔ نماز کی ترتیبات آپ کے محفوظ مقام پر لاگو ہوتی ہیں۔';

  @override
  String prayerSettingsOffsetLabel(String prayer) {
    return '$prayer میں ردوبدل';
  }

  @override
  String prayerSettingsOffsetLess(String prayer) {
    return '$prayer سے ایک منٹ کم کریں';
  }

  @override
  String prayerSettingsOffsetMore(String prayer) {
    return '$prayer میں ایک منٹ بڑھائیں';
  }

  @override
  String prayerSettingsOffsetValue(String value) {
    return '$value منٹ';
  }

  @override
  String get prayerSettingsOffsetsIntro =>
      'کسی بھی نماز میں 60 منٹ تک کمی یا اضافہ کریں۔ یہ ہر جگہ لاگو ہوتا ہے، الرٹس سمیت۔';

  @override
  String get prayerSettingsOffsetsTitle => 'اوقات میں ردوبدل';

  @override
  String get prayerSettingsTitle => 'نماز کی ترتیبات';

  @override
  String get prayerSunrise => 'طلوعِ آفتاب';

  @override
  String get qiblaAccuracyHigh => 'اعلیٰ';

  @override
  String qiblaAccuracyLabel(String level) {
    return 'قطب نما کی درستگی: $level';
  }

  @override
  String get qiblaAccuracyLow => 'کم';

  @override
  String get qiblaAccuracyMedium => 'درمیانی';

  @override
  String get qiblaAccuracyUnreliable => 'ناقابلِ اعتماد';

  @override
  String get qiblaArrowSemantics => 'قطب نما کا تیر';

  @override
  String get qiblaAtHaram =>
      'آپ مکہ مکرمہ میں حرم شریف میں ہیں۔ کعبہ شریف کی طرف براہِ راست رخ کریں۔';

  @override
  String qiblaBearingFromPlace(String place, String description) {
    return '$place سے قبلہ: $description';
  }

  @override
  String get qiblaCalibrationPrompt =>
      'قطب نما کیلیبریٹ کریں۔ فون کو چند بار عدد 8 کی شکل میں گھمائیں، دھات اور مقناطیس سے دور۔';

  @override
  String get qiblaCompassError =>
      'قطب نما شروع نہیں ہو سکا۔ اس کے بجائے سمت ڈگری میں دکھائی جا رہی ہے۔';

  @override
  String qiblaDirectionDescription(int degrees, String direction) {
    return '$degrees ڈگری، $direction';
  }

  @override
  String get qiblaDirectionEast => 'مشرق';

  @override
  String get qiblaDirectionNorth => 'شمال';

  @override
  String get qiblaDirectionNortheast => 'شمال مشرق';

  @override
  String get qiblaDirectionNorthwest => 'شمال مغرب';

  @override
  String get qiblaDirectionSouth => 'جنوب';

  @override
  String get qiblaDirectionSoutheast => 'جنوب مشرق';

  @override
  String get qiblaDirectionSouthwest => 'جنوب مغرب';

  @override
  String get qiblaDirectionWest => 'مغرب';

  @override
  String qiblaDistanceToKaaba(int km) {
    return 'کعبہ تک $km کلومیٹر';
  }

  @override
  String get qiblaEntryHint => 'کعبہ کی سمت معلوم کریں';

  @override
  String get qiblaFacingQibla => 'آپ کا رخ قبلے کی طرف ہے';

  @override
  String get qiblaInterferenceWarning =>
      'قریب مقناطیسی خلل ہے۔ دھات، اسپیکر، مقناطیس اور برقی آلات سے دور ہوں، پھر دوبارہ دیکھیں۔ تب تک تیر غلط ہو سکتا ہے۔';

  @override
  String get qiblaMagneticNorthNote =>
      'قطب نما مقناطیسی شمال استعمال کر رہا ہے۔ معمولی غلطی ممکن ہے۔';

  @override
  String get qiblaNoCompassInstructions =>
      'اوپر دی گئی سمت استعمال کریں۔ نقشے، قطب نما یا سورج (جو مشرق سے طلوع اور مغرب میں غروب ہوتا ہے) سے شمال معلوم کریں، پھر شمال سے گھڑی کی سمت میں دکھائے گئے ڈگری کے برابر گھومیں۔';

  @override
  String get qiblaNoCompassTitle => 'اس آلے میں قطب نما نہیں ہے';

  @override
  String get qiblaNoLocation =>
      'پہلے اپنا مقام منتخب کریں تاکہ قبلے کی سمت معلوم ہو سکے۔';

  @override
  String get qiblaNorthReference => 'شمالِ حقیقی سے گھڑی کی سمت میں ناپا گیا';

  @override
  String get qiblaStartingCompass => 'قطب نما شروع ہو رہا ہے';

  @override
  String get qiblaTitle => 'قبلہ';

  @override
  String get qiblaTurnHint =>
      'اس وقت تک گھومیں جب تک تیر سیدھا اوپر نہ ہو جائے';

  @override
  String qiblaTurnLeft(int degrees) {
    return '$degrees ڈگری بائیں گھومیں';
  }

  @override
  String qiblaTurnRight(int degrees) {
    return '$degrees ڈگری دائیں گھومیں';
  }

  @override
  String get reliabilityAllGood => 'سب کچھ ٹھیک نظر آ رہا ہے۔';

  @override
  String get reliabilityBattery => 'بیٹری آپٹیمائزیشن (اینڈرائیڈ)';

  @override
  String get reliabilityBatteryFix =>
      'کچھ فونز پر بیٹری بچت الرٹس کو روک سکتی ہے۔ بیٹری کی ترتیبات کھولیں اور Deen App کو بیک گراؤنڈ میں چلنے دیں۔';

  @override
  String get reliabilityBatteryOk => 'Deen App پر کوئی پابندی نہیں۔';

  @override
  String get reliabilityBatteryOpen => 'بیٹری کی ترتیبات کھولیں';

  @override
  String get reliabilityCheckHint => 'یقینی بنائیں کہ آپ کے الرٹس بجیں گے';

  @override
  String get reliabilityCheckTitle => 'اعتماد کی جانچ';

  @override
  String get reliabilityErrorBudget =>
      'الرٹس اس فون کی گنجائش سے زیادہ ہیں، اس لیے بعد والے ایپ دوبارہ کھلنے تک چھوڑ دیے گئے۔';

  @override
  String get reliabilityErrorExactDenied =>
      'درست الارم کی اجازت نہیں، اس لیے وقت کم درست ہو سکتا ہے۔';

  @override
  String get reliabilityErrorInvalid => 'فون یہ الرٹ قبول نہیں کر سکا۔';

  @override
  String get reliabilityErrorPermissionDenied => 'نوٹیفکیشن کی اجازت نہیں۔';

  @override
  String get reliabilityErrorPlatform => 'الرٹ سسٹم نے جواب نہیں دیا۔';

  @override
  String get reliabilityErrorServiceBlocked =>
      'اینڈرائیڈ نے اذان کی آواز شروع ہونے سے روک دیا۔ اس کی جگہ نوٹیفکیشن کی آواز استعمال ہو گی۔';

  @override
  String get reliabilityExact => 'درست الارم (اینڈرائیڈ)';

  @override
  String get reliabilityExactFix =>
      'درست الارم بند ہیں، اس لیے الرٹس چند منٹ دیر سے آ سکتے ہیں۔ Deen App کے لیے «الارم اور یاد دہانیاں» کی اجازت دیں۔';

  @override
  String get reliabilityExactOpen => 'الارم کی ترتیبات کھولیں';

  @override
  String get reliabilityFlagInexact => 'وقت چند منٹ دیر سے ہو سکتا ہے';

  @override
  String get reliabilityFlagSilenced => 'خاموش اوقات کی وجہ سے خاموش';

  @override
  String get reliabilityIntro =>
      'یہ اسکرین بتاتی ہے کہ آپ کے الرٹس بجیں گے یا نہیں، اور انہیں روکنے والی کسی بھی چیز کو کیسے ٹھیک کیا جائے۔';

  @override
  String get reliabilityIosRefreshNote =>
      'آئی فون پر ہر بار ایپ کھولنے پر الرٹس تازہ ہوتے ہیں۔ انہیں جاری رکھنے کے لیے ہر چند دن بعد ایپ کھولیں۔';

  @override
  String get reliabilityKindRenewal => 'تجدید کی اطلاع';

  @override
  String reliabilityLastLine(String when, String result) {
    return '$when: $result';
  }

  @override
  String get reliabilityLastNone => 'ابھی کوئی الرٹ نہیں بجا۔';

  @override
  String get reliabilityLastTitle => 'آخری الرٹ کا نتیجہ';

  @override
  String get reliabilityLoadFailed =>
      'جانچ مکمل نہیں ہو سکی۔ براہِ کرم دوبارہ کوشش کریں۔';

  @override
  String get reliabilityNextNone => 'کچھ بھی مقرر نہیں۔';

  @override
  String reliabilityNextRow(String title, String type, String when) {
    return '$title، $type، $when';
  }

  @override
  String get reliabilityNextTitle => 'اگلے 5 الرٹس';

  @override
  String get reliabilityNotifications => 'نوٹیفکیشن';

  @override
  String get reliabilityNotificationsAllow => 'نوٹیفکیشن کی اجازت دیں';

  @override
  String get reliabilityNotificationsFix =>
      'نوٹیفکیشن بند ہیں، اس لیے الرٹس ظاہر نہیں ہو سکتے۔ Deen App کے لیے نوٹیفکیشن کی اجازت دیں۔';

  @override
  String get reliabilityNotificationsSettings => 'نوٹیفکیشن کی ترتیبات کھولیں';

  @override
  String get reliabilityPermissionsTitle => 'اجازتیں';

  @override
  String get reliabilityProblemsFound => 'کسی چیز پر توجہ درکار ہے۔';

  @override
  String reliabilityRebuildFailed(String reason) {
    return 'آپ کے الرٹس اپ ڈیٹ نہیں ہو سکے۔ $reason';
  }

  @override
  String get reliabilityRefresh => 'دوبارہ جانچیں';

  @override
  String reliabilityRegistered(int count) {
    return 'فون میں $count الرٹس درج ہیں۔';
  }

  @override
  String get reliabilityResultAcknowledged => 'آپ نے روکا';

  @override
  String get reliabilityResultFailed => 'ناکام';

  @override
  String get reliabilityResultFired => 'پہنچ گیا';

  @override
  String get reliabilityResultMissed => 'رہ گیا';

  @override
  String get reliabilityResultPlanned => 'انتظار میں';

  @override
  String get reliabilityResultPlayed => 'اذان چلی';

  @override
  String get reliabilityResultPossiblyMissed => 'ممکنہ طور پر رہ گیا';

  @override
  String get reliabilityResultSuppressed => 'خاموش کیا گیا';

  @override
  String get reliabilityRunsUntilHint =>
      'الرٹس جاری رکھنے کے لیے اس تاریخ سے پہلے ایپ کھولیں۔ ہر بار کھلنے پر وہ تجدید ہو جاتے ہیں۔';

  @override
  String get reliabilityRunsUntilNone => 'ابھی کوئی الرٹ مقرر نہیں۔';

  @override
  String get reliabilityRunsUntilTitle => 'الرٹس اس تاریخ تک چلیں گے';

  @override
  String get reliabilitySilentSwitchTip =>
      'اگر آپ کے آئی فون کا خاموش سوئچ آن ہے تو نوٹیفکیشن کی آوازیں بند رہتی ہیں۔ نوٹیفکیشن پر ٹیپ کرنے سے مکمل اذان چلتی ہے۔';

  @override
  String get reliabilitySound => 'نوٹیفکیشن کی آواز (آئی فون)';

  @override
  String get reliabilitySoundFix =>
      'نوٹیفکیشن کی ترتیبات میں آواز بند ہے، اس لیے الرٹس خاموش ہوں گے۔ Deen App کے لیے آواز کی اجازت دیں۔';

  @override
  String get reliabilityStateOff => 'بند';

  @override
  String get reliabilityStateOn => 'آن';

  @override
  String get reliabilityTestButton => '1 منٹ میں آزمائشی اذان بھیجیں';

  @override
  String reliabilityTestFailed(String reason) {
    return 'آزمائش مقرر نہیں ہو سکی۔ $reason';
  }

  @override
  String get reliabilityTestNeedsNotifications =>
      'پہلے نوٹیفکیشن کی اجازت دیں، پھر دوبارہ کوشش کریں۔';

  @override
  String reliabilityTestScheduled(String time) {
    return 'آزمائشی اذان $time پر مقرر ہو گئی۔ اپنا فون لاک کریں اور انتظار کریں۔';
  }

  @override
  String get reliabilityUnsupported =>
      'یہ ڈیوائس الرٹس مقرر نہیں کر سکتی، اس لیے یہاں جانچنے کو کچھ نہیں۔';

  @override
  String get settingsAppearanceHint => 'تھیم، متن کا سائز اور کنٹراسٹ';

  @override
  String get settingsAppearanceNeedsSetup =>
      'پہلے سیٹ اپ مکمل کریں۔ نماز کی ترتیبات محفوظ ہونے کے بعد آپ ظاہری شکل بدل سکتے ہیں۔';

  @override
  String get settingsAppearanceTitle => 'ظاہری شکل';

  @override
  String get settingsDataHint => 'برآمد، درآمد یا حذف';

  @override
  String get settingsDataTitle => 'آپ کا ڈیٹا';

  @override
  String get settingsDeleteBody =>
      'اس آلے سے آپ کی ترتیبات، مقام، تسبیح کی گنتیاں، بک مارکس اور الرٹس کی تاریخ ہٹا دیتا ہے، اور تمام شیڈول شدہ الرٹس منسوخ کر دیتا ہے۔';

  @override
  String get settingsDeleteCancel => 'منسوخ کریں';

  @override
  String get settingsDeleteConfirmAction => 'سب کچھ حذف کریں';

  @override
  String get settingsDeleteConfirmBody =>
      'اس سے وہ سب کچھ ہٹ جائے گا جو ایپ اس آلے پر رکھتی ہے، اور اسے واپس نہیں کیا جا سکتا۔ ایپ کے باہر جو ترتیبات کی فائلیں آپ نے محفوظ یا شیئر کیں وہ حذف نہیں ہوتیں، وہ وہیں رہتی ہیں جہاں آپ نے رکھیں۔';

  @override
  String get settingsDeleteConfirmTitle => 'سارا ڈیٹا حذف کریں؟';

  @override
  String get settingsDeleteDone => 'سارا ڈیٹا حذف کر دیا گیا۔';

  @override
  String get settingsDeletePartial =>
      'کچھ ڈیٹا حذف نہیں ہو سکا۔ براہِ کرم دوبارہ کوشش کریں۔';

  @override
  String get settingsDeleteTitle => 'میرا سارا ڈیٹا حذف کریں';

  @override
  String get settingsExportCancelled => 'برآمد منسوخ کر دی گئی۔';

  @override
  String get settingsExportDone => 'ترتیبات کی فائل تیار ہے۔';

  @override
  String get settingsExportFailed => 'ترتیبات کی فائل نہیں بن سکی۔';

  @override
  String get settingsExportSave => 'ترتیبات کی فائل محفوظ کریں';

  @override
  String get settingsExportShare => 'ترتیبات کی فائل شیئر کریں';

  @override
  String get settingsExportTitle => 'ترتیبات برآمد کریں';

  @override
  String get settingsExportWarning =>
      'فائل میں آپ کا محفوظ مقام اور ترتیبات شامل ہیں۔ جس کے پاس بھی یہ فائل پہنچے وہ جان سکتا ہے کہ آپ کہاں ہیں۔ اسے صرف قابلِ اعتماد لوگوں اور جگہوں کے ساتھ شیئر کریں۔';

  @override
  String get settingsHighContrast => 'اعلیٰ کنٹراسٹ';

  @override
  String get settingsHighContrastHint =>
      'متن اور خاکے کے زیادہ گہرے رنگ۔ ایپ میں کوئی بات صرف رنگ پر منحصر نہیں ہے۔';

  @override
  String get settingsImportBody =>
      'ایپ سے برآمد کی گئی ترتیبات کی فائل چنیں۔ یہ اپنی شامل ترتیبات کو بدل دیتی ہے۔ اگر فائل میں کوئی مسئلہ ہو تو کچھ نہیں بدلے گا۔';

  @override
  String get settingsImportButton => 'ترتیبات کی فائل منتخب کریں';

  @override
  String get settingsImportDone => 'ترتیبات درآمد ہو گئیں۔';

  @override
  String get settingsImportDoneLater =>
      'ترتیبات درآمد ہو گئیں۔ الرٹس اگلی بار ایپ کھلنے پر اپ ڈیٹ ہوں گے۔';

  @override
  String get settingsImportFailed =>
      'ترتیبات محفوظ نہیں ہو سکیں۔ کچھ نہیں بدلا گیا۔';

  @override
  String settingsImportInvalid(String field) {
    return 'فائل میں ایک قدر غائب ہے یا حد سے باہر ہے ($field)۔ کچھ نہیں بدلا گیا۔';
  }

  @override
  String get settingsImportNewer =>
      'یہ فائل ایپ کے نئے ورژن نے بنائی ہے۔ اسے پڑھنے کے لیے ایپ اپ ڈیٹ کریں۔';

  @override
  String get settingsImportNotSettings =>
      'یہ Deen App کی ترتیبات کی فائل نہیں ہے۔';

  @override
  String get settingsImportTitle => 'ترتیبات درآمد کریں';

  @override
  String get settingsImportUnreadable => 'فائل پڑھی نہیں جا سکی۔';

  @override
  String get settingsSaveError => 'یہ تبدیلی محفوظ نہیں ہو سکی۔';

  @override
  String get settingsTextSizeLabel => 'متن کا سائز';

  @override
  String get settingsTextSizeLarger => 'بڑا متن';

  @override
  String get settingsTextSizeSample =>
      'نمونے کا متن: اس سائز پر متن ایسا نظر آتا ہے۔';

  @override
  String get settingsTextSizeSmaller => 'چھوٹا متن';

  @override
  String settingsTextSizeValue(int percent) {
    return '$percent%';
  }

  @override
  String get settingsThemeDark => 'تاریک';

  @override
  String get settingsThemeLabel => 'تھیم';

  @override
  String get settingsThemeLight => 'روشن';

  @override
  String get settingsThemeSystem => 'آلے کے مطابق';

  @override
  String get settingsTitle => 'ترتیبات';

  @override
  String get setupAsrIntro =>
      'عصر کے آغاز کے لیے وہ مکتبِ فکر منتخب کریں جس کی آپ پیروی کرتے ہیں۔ «معیاری» پہلے سے منتخب ہے۔';

  @override
  String get setupAsrTitle => 'نمازِ عصر';

  @override
  String get setupBack => 'پیچھے';

  @override
  String get setupBatteryBody =>
      'کچھ فون بیٹری بچانے کے لیے ایپس کو پس منظر میں بند کر دیتے ہیں، جس سے الرٹس میں تاخیر ہو سکتی ہے یا وہ رک سکتے ہیں۔ اپنے فون کا برانڈ منتخب کریں اور مراحل پر عمل کریں۔';

  @override
  String get setupBatteryBrandLabel => 'آپ کے فون کا برانڈ';

  @override
  String get setupBatteryGuideUnavailable =>
      'اس برانڈ کے مراحل لوڈ نہیں ہو سکے۔ بیٹری کی ترتیبات کھولیں اور Deen App کو پس منظر میں چلنے کی اجازت دیں۔';

  @override
  String get setupBatteryOpenSettings => 'بیٹری کی ترتیبات کھولیں';

  @override
  String setupBatteryStep(int number, String text) {
    return 'مرحلہ $number: $text';
  }

  @override
  String get setupBatteryTitle => 'الرٹس کو قابلِ اعتماد رکھیں';

  @override
  String get setupExactBody =>
      'اینڈرائیڈ الرٹ کو عین نماز کے وقت پر تبھی بجا سکتا ہے جب آپ درست الارم کی اجازت دیں۔ اس کے بغیر الرٹس آئیں گے مگر چند منٹ دیر سے ہو سکتے ہیں۔';

  @override
  String get setupExactCheck => 'میں نے بدل دیا، دوبارہ جانچیں';

  @override
  String get setupExactContinue => 'اس کے بغیر جاری رکھیں';

  @override
  String get setupExactDenied =>
      'درست الارم بند ہیں۔ الرٹس پھر بھی آئیں گے مگر چند منٹ دیر سے ہو سکتے ہیں۔ اعتماد کی جانچ میں یہ دکھایا جاتا ہے۔';

  @override
  String get setupExactGranted => 'درست الارم کی اجازت ہے۔';

  @override
  String get setupExactOpen => 'الارم کی ترتیبات کھولیں';

  @override
  String get setupExactTitle => 'الرٹ کا درست وقت';

  @override
  String get setupFinish => 'سیٹ اپ مکمل کریں';

  @override
  String get setupLanguageBody =>
      'آپ اسے کسی بھی وقت ترتیبات میں بدل سکتے ہیں۔';

  @override
  String get setupLanguageTitle => 'اپنی زبان منتخب کریں';

  @override
  String get setupLocationApproximate => 'میرا تخمینی مقام استعمال کریں';

  @override
  String get setupLocationApproximateHint =>
      'تخمینی مقام آپ کی جگہ کو تقریباً 10 کلومیٹر تک گول کر دیتا ہے۔ اوقات میں ایک منٹ سے بہت کم فرق آتا ہے۔';

  @override
  String get setupLocationApproximateName => 'تخمینی مقام';

  @override
  String get setupLocationCurrentName => 'موجودہ مقام';

  @override
  String get setupLocationFinding => 'آپ کا مقام تلاش کیا جا رہا ہے…';

  @override
  String get setupLocationNeeded => 'جاری رکھنے کے لیے مقام یا شہر منتخب کریں۔';

  @override
  String get setupLocationOfflineNote =>
      'شہروں کی فہرست ایپ میں محفوظ ہے، اس لیے تلاش انٹرنیٹ کے بغیر کام کرتی ہے۔ آپ مقام شیئر کیے بغیر صرف شہر منتخب کر سکتے ہیں۔';

  @override
  String get setupLocationPrecise => 'میرا درست مقام استعمال کریں';

  @override
  String get setupLocationPrivacy =>
      'آپ کا مقام اسی ڈیوائس پر رہتا ہے۔ اسے کہیں نہیں بھیجا جاتا، اور یہ صرف نماز کے اوقات نکالنے کے لیے استعمال ہوتا ہے۔';

  @override
  String get setupLocationSearchEmpty =>
      'کوئی شہر نہیں ملا۔ ہجے دیکھیں یا کوئی اور نام آزمائیں۔';

  @override
  String get setupLocationSearchHint => 'شہر کا نام';

  @override
  String get setupLocationSearchLabel => 'یا کسی شہر کو تلاش کریں';

  @override
  String setupLocationSelected(String name) {
    return 'منتخب: $name';
  }

  @override
  String get setupLocationTitle => 'آپ کا مقام';

  @override
  String get setupMethodChange => 'آپ کوئی دوسرا طریقہ منتخب کر سکتے ہیں:';

  @override
  String get setupMethodGeneral =>
      'آپ کے مقام کے لیے کوئی علاقائی طریقہ مقرر نہیں، اس لیے عمومی مسلم ورلڈ لیگ کا طریقہ تجویز کیا گیا ہے۔';

  @override
  String setupMethodSuggested(String method) {
    return 'آپ کے علاقے کے لیے تجویز کردہ: $method';
  }

  @override
  String get setupMethodTitle => 'حساب کا طریقہ';

  @override
  String get setupNext => 'آگے';

  @override
  String get setupNotNow => 'ابھی نہیں';

  @override
  String get setupNotificationsAllow => 'نوٹیفکیشن کی اجازت دیں';

  @override
  String get setupNotificationsBody =>
      'نماز کے اوقات پر یاد دہانی کے لیے Deen App کو نوٹیفکیشن دکھانے کی اجازت چاہیے۔ الرٹس آپ کے فون پر بنتے ہیں؛ انٹرنیٹ پر کچھ نہیں بھیجا جاتا۔';

  @override
  String get setupNotificationsDenied =>
      'نوٹیفکیشن بند ہیں، اس لیے نماز کے الرٹس نظر نہیں آئیں گے۔ آپ بعد میں ایپ کی ترتیبات میں اجازت دے سکتے ہیں۔';

  @override
  String get setupNotificationsGranted => 'نوٹیفکیشن کی اجازت ہے۔';

  @override
  String get setupNotificationsTitle => 'نماز کے الرٹس';

  @override
  String get setupOpenAppSettings => 'ایپ کی ترتیبات کھولیں';

  @override
  String get setupPrivacyNoData => 'Deen App کوئی ذاتی ڈیٹا جمع نہیں کرتی۔';

  @override
  String get setupPrivacyNoTracking =>
      'کوئی اکاؤنٹ، اشتہار یا ٹریکر نہیں ہے، اور ایپ انٹرنیٹ کے بغیر چلتی ہے۔';

  @override
  String get setupPrivacyOnDevice =>
      'آپ کا مقام، ترتیبات اور الرٹس کی تاریخ اسی فون پر رہتی ہے۔';

  @override
  String get setupPrivacyTitle => 'آپ کی رازداری';

  @override
  String get setupProblemLocationDenied =>
      'مقام کی اجازت نہیں ملی۔ اس کے بجائے فہرست سے شہر منتخب کریں، یا ایپ کی ترتیبات میں مقام کی اجازت دیں۔';

  @override
  String get setupProblemLocationTimeout =>
      'آپ کا مقام بروقت نہیں مل سکا۔ دوبارہ کوشش کریں یا فہرست سے شہر منتخب کریں۔';

  @override
  String get setupProblemLocationUnavailable =>
      'اس فون پر فی الحال مقام دستیاب نہیں۔ فہرست سے شہر منتخب کریں۔';

  @override
  String get setupProblemSaveFailed =>
      'آپ کا انتخاب محفوظ نہیں ہو سکا۔ براہِ کرم دوبارہ کوشش کریں۔';

  @override
  String get setupProblemZoneUnknown =>
      'آپ کے فون نے ٹائم زون نہیں بتایا۔ فہرست سے شہر منتخب کریں۔';

  @override
  String setupProgress(int current, int total) {
    return 'مرحلہ $current از $total';
  }

  @override
  String get setupSummaryAlerts =>
      'نماز کے الرٹس نظر نہیں آئیں گے کیونکہ نوٹیفکیشن بند ہیں۔';

  @override
  String get setupSummaryExact =>
      'الرٹس چند منٹ دیر سے آ سکتے ہیں کیونکہ درست الارم بند ہیں۔';

  @override
  String get setupSummaryLocation =>
      'آپ کے فون کا مقام بند ہے، اس لیے اوقات آپ کے منتخب کردہ شہر کے مطابق ہیں۔';

  @override
  String get setupSummaryTitle => 'ابھی کیا کام نہیں کرے گا';

  @override
  String get setupSummaryWayBack =>
      'آپ ان میں سے کسی کی بھی اجازت بعد میں ایپ کی ترتیبات میں دے سکتے ہیں۔';

  @override
  String get setupTitle => 'Deen App کی ترتیب';

  @override
  String get tasbihCancel => 'منسوخ کریں';

  @override
  String get tasbihCountHint => 'گنتی میں ایک کا اضافہ کرتا ہے';

  @override
  String tasbihCountLabel(int count, int target) {
    return 'گنتی: $target میں سے $count';
  }

  @override
  String get tasbihEntryHint => 'اپنا ذکر گنیں';

  @override
  String get tasbihHaptics => 'ہر گنتی پر وائبریشن';

  @override
  String get tasbihHistoryEmpty =>
      'ابھی کوئی گنتی نہیں۔ آپ کے روزانہ کے مجموعے یہاں نظر آئیں گے۔';

  @override
  String get tasbihHistoryTitle => 'تاریخچہ';

  @override
  String get tasbihKeepAwake => 'اسکرین کو روشن رکھیں';

  @override
  String get tasbihLock => 'کاؤنٹر پر لمس بند کریں';

  @override
  String get tasbihLockHint =>
      'غلطی سے لگنے والا لمس گنتی نہیں بڑھائے گا۔ والیوم بٹن پھر بھی گنتی کریں گے۔';

  @override
  String get tasbihLockedMessage =>
      'مقفل۔ کاؤنٹر پر لمس نظر انداز کیا جاتا ہے۔';

  @override
  String tasbihOfTarget(int target) {
    return '$target میں سے';
  }

  @override
  String get tasbihOptionsTitle => 'اختیارات';

  @override
  String get tasbihReset => 'ری سیٹ';

  @override
  String get tasbihResetBody =>
      'گنتی 0 پر واپس آ جائے گی۔ آپ کے روزانہ کے مجموعے محفوظ رہیں گے۔';

  @override
  String get tasbihResetTitle => 'کاؤنٹر ری سیٹ کریں؟';

  @override
  String tasbihRounds(int rounds) {
    return 'مکمل دور: $rounds';
  }

  @override
  String get tasbihSave => 'محفوظ کریں';

  @override
  String get tasbihSaveError => 'گنتی محفوظ نہیں ہو سکی۔ دوبارہ کوشش کریں۔';

  @override
  String get tasbihSound => 'ٹیپ کی آواز';

  @override
  String get tasbihTargetCustom => 'اپنی مرضی';

  @override
  String get tasbihTargetCustomField => 'ہدف (1 سے 100000)';

  @override
  String tasbihTargetCustomLabel(int target) {
    return 'اپنی مرضی کا ہدف: $target';
  }

  @override
  String get tasbihTargetCustomTitle => 'اپنی مرضی کا ہدف';

  @override
  String get tasbihTargetHeading => 'ہدف';

  @override
  String get tasbihTargetInvalid => '1 سے 100000 تک کوئی پورا عدد درج کریں۔';

  @override
  String tasbihTargetOptionLabel(int target) {
    return 'ہدف $target';
  }

  @override
  String tasbihTargetReached(int target) {
    return '$target کا ہدف پورا ہو گیا';
  }

  @override
  String get tasbihTitle => 'تسبیح';

  @override
  String tasbihTodayTotal(int total) {
    return 'آج: $total';
  }

  @override
  String get tasbihUnlock => 'کھولنے کے لیے دبائے رکھیں';

  @override
  String get tasbihUnlockPressHint => 'کھولنے کے لیے بٹن کو دبائے رکھیں۔';

  @override
  String get tasbihVolumeKeys => 'والیوم بٹنوں سے گنتی';

  @override
  String get tasbihVolumeKeysHint =>
      'جب تک یہ اسکرین کھلی ہے، والیوم بٹن آواز بدلنے کے بجائے گنتی کریں گے۔';
}
