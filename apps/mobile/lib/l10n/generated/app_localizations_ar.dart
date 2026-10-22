// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get aboutAttributionsTitle => 'الإسناد والشكر';

  @override
  String get aboutCitiesHeading => 'بيانات المدن';

  @override
  String get aboutContentHeading => 'نصوص الأذكار';

  @override
  String get aboutDescription =>
      'أوقات الصلاة وتنبيهات الأذان وأدوات العبادة اليومية. كل شيء يعمل دون إنترنت.';

  @override
  String get aboutEntryHint => 'التراخيص والمصادر والخصوصية';

  @override
  String get aboutFontsHeading => 'الخطوط';

  @override
  String get aboutHijriHeading => 'بيانات التقويم الهجري';

  @override
  String get aboutLegalEnglishNote =>
      'النص أدناه هو صيغة الترخيص ويبقى بالإنجليزية.';

  @override
  String get aboutLicensesSubtitle =>
      'تراخيص البرمجيات المستخدمة في بناء هذا التطبيق';

  @override
  String get aboutLicensesTitle => 'تراخيص البرمجيات الحرة';

  @override
  String get aboutNoDataCollected =>
      'لا يجمع التطبيق أي بيانات. لا توجد حسابات ولا تحليلات ولا إعلانات. يبقى موقعك على هذا الجهاز ولا يُستخدم إلا لحساب أوقات الصلاة واتجاه القبلة.';

  @override
  String get aboutPrivacyHeading => 'خصوصيتك';

  @override
  String aboutPrivacyPolicyAddress(String address) {
    return 'اقرأ السياسة الكاملة على: $address';
  }

  @override
  String get aboutPrivacyPolicyPending =>
      'ستُنشر سياسة الخصوصية الكاملة قبل الإصدار، وستقول الأمر نفسه: التطبيق لا يجمع أي بيانات.';

  @override
  String get aboutPrivacyPolicyTitle => 'سياسة الخصوصية';

  @override
  String get aboutTitle => 'حول التطبيق';

  @override
  String aboutVersion(String version) {
    return 'الإصدار $version';
  }

  @override
  String get adhkarBookmarkAdd => 'إضافة علامة مرجعية';

  @override
  String get adhkarBookmarkRemove => 'إزالة العلامة المرجعية';

  @override
  String get adhkarBookmarksEmpty =>
      'لم تحفظ أي ذكر بعد. استخدم زر العلامة المرجعية في أي ذكر لحفظه هنا.';

  @override
  String get adhkarBookmarksTitle => 'العلامات المرجعية';

  @override
  String get adhkarCollectionAfterPrayer => 'أذكار بعد الصلاة';

  @override
  String get adhkarCollectionBeforeSleep => 'أذكار النوم';

  @override
  String get adhkarCollectionEvening => 'أذكار المساء';

  @override
  String get adhkarCollectionMorning => 'أذكار الصباح';

  @override
  String get adhkarCollectionOther => 'أذكار أخرى';

  @override
  String get adhkarCollectionWaking => 'أذكار الاستيقاظ';

  @override
  String adhkarCountLabel(int done, int total) {
    return 'اضغط للعدّ: $done من $total';
  }

  @override
  String adhkarCreditEntry(int order, String reference) {
    return 'الذكر $order: $reference';
  }

  @override
  String adhkarCreditReviewer(String reviewer, String date) {
    return 'راجعه $reviewer بتاريخ $date.';
  }

  @override
  String adhkarCreditSource(String source, String license) {
    return 'المصدر: $source. الترخيص: $license.';
  }

  @override
  String adhkarCreditsCount(int count) {
    return 'عدد النصوص المدرجة: $count';
  }

  @override
  String get adhkarCreditsEmpty =>
      'لا يتضمن هذا الإصدار نصوص أذكار، لذا لا توجد مصادر لعرضها بعد.';

  @override
  String get adhkarCreditsIntro => 'يُذكر لكل نص مصدره وترخيصه ومن راجعه.';

  @override
  String get adhkarCreditsTitle => 'مصادر المحتوى والمراجعون';

  @override
  String get adhkarEmptyBody =>
      'لا يتضمن هذا الإصدار من التطبيق نصوص الأذكار بعد. ستُضاف فقط بعد ترخيص مصادرها ومراجعتها من أحد أهل العلم.';

  @override
  String get adhkarEmptyTitle => 'الأذكار غير متاحة بعد';

  @override
  String adhkarEntryCount(int count) {
    return 'عدد الأذكار: $count';
  }

  @override
  String get adhkarEntryDone => 'تم';

  @override
  String get adhkarEntryHint => 'أذكار يومية وعلامات مرجعية وتذكيرات';

  @override
  String get adhkarLoadError => 'تعذّر تحميل الأذكار.';

  @override
  String get adhkarNext => 'الذكر التالي';

  @override
  String get adhkarNotFound => 'هذه المجموعة غير متاحة.';

  @override
  String adhkarPosition(int position, int total) {
    return 'الذكر $position من $total';
  }

  @override
  String get adhkarPrevious => 'الذكر السابق';

  @override
  String adhkarProgressLabel(int done, int total) {
    return 'اكتمل $done من $total من الأذكار';
  }

  @override
  String adhkarReminderAfter(int minutes, String prayer) {
    return 'بعد $prayer بـ $minutes دقيقة';
  }

  @override
  String get adhkarReminderAnchor => 'احسب الوقت من';

  @override
  String adhkarReminderAt(String prayer) {
    return 'عند وقت $prayer';
  }

  @override
  String adhkarReminderBefore(int minutes, String prayer) {
    return 'قبل $prayer بـ $minutes دقيقة';
  }

  @override
  String get adhkarReminderEarlier => 'قبل 5 دقائق';

  @override
  String get adhkarReminderEnable => 'ذكّرني';

  @override
  String get adhkarReminderEvening => 'تذكير المساء';

  @override
  String get adhkarReminderFajrOnly => 'تتبع تذكيرات الصباح وقت الفجر.';

  @override
  String get adhkarReminderLater => 'بعد 5 دقائق';

  @override
  String get adhkarReminderMorning => 'تذكير الصباح';

  @override
  String get adhkarReminderNote =>
      'التذكيرات إشعارات على هذا الجهاز، وهي تتبع أوقات صلاتك فتتغير بتغير موقعك وطريقة الحساب.';

  @override
  String get adhkarReminderSaveError => 'تعذّر حفظ التذكير.';

  @override
  String get adhkarRemindersTitle => 'تذكيرات الأذكار';

  @override
  String adhkarRepeatLabel(int count) {
    return 'عدد المرات: $count';
  }

  @override
  String get adhkarSessionComplete => 'اكتملت الجلسة';

  @override
  String adhkarSourceLabel(String reference) {
    return 'المصدر: $reference';
  }

  @override
  String get adhkarStartAgain => 'ابدأ من جديد';

  @override
  String get adhkarTitle => 'الأذكار';

  @override
  String get adhkarTranslationFallbackHeading =>
      'الترجمة (بالإنجليزية؛ غير متاحة بلغتك بعد)';

  @override
  String get adhkarTranslationHeading => 'الترجمة';

  @override
  String get adhkarTransliterationHeading => 'النطق بالحروف اللاتينية';

  @override
  String get adhkarUndo => 'التراجع عن آخر عدّ';

  @override
  String get alertAudioIntro =>
      'أين يُشغَّل الأذان عند توصيل سماعات أو جهاز بلوتوث. وبدونهما يُشغَّل عبر مكبّر الصوت.';

  @override
  String get alertAudioTitle => 'مخرج الصوت';

  @override
  String get alertCauseAppNotRun => 'لم يكن التطبيق مفتوحًا.';

  @override
  String get alertCauseBatteryRestricted =>
      'ربما أوقفه توفير البطارية. راجع إعدادات البطارية.';

  @override
  String get alertCauseCallInProgress => 'كانت هناك مكالمة هاتفية.';

  @override
  String get alertCauseExactAlarmDenied =>
      'المنبّهات الدقيقة معطّلة، فربما أخّره أندرويد.';

  @override
  String get alertCauseFgsBlocked =>
      'لم يسمح أندرويد للتطبيق ببدء الأذان، فاستُخدمت نغمة الإشعار.';

  @override
  String get alertCauseNotificationDenied => 'كانت الإشعارات معطّلة.';

  @override
  String get alertCauseQuietHours => 'كُتم بسبب ساعات الهدوء.';

  @override
  String get alertCauseScheduleEnded =>
      'انتهت التنبيهات المجدولة لأن التطبيق لم يُفتح منذ مدة طويلة. فتحه جدّدها.';

  @override
  String get alertCauseSilentMode => 'كان الهاتف في الوضع الصامت.';

  @override
  String get alertCauseUnknown => 'السبب غير معروف.';

  @override
  String get alertExactBody =>
      'ليُسمَع التنبيه في وقت الصلاة بالضبط، يحتاج أندرويد إلى إذن «المنبّهات والتذكيرات» للتطبيق. بدونه تصل التنبيهات لكن قد تتأخر بضع دقائق.';

  @override
  String get alertExactCheck => 'غيّرته، تحقق مرة أخرى';

  @override
  String get alertExactGranted => 'المنبّهات الدقيقة مفعّلة.';

  @override
  String get alertExactInexact =>
      'ستصل التنبيهات مع ذلك، لكن قد يقلّ ضبط التوقيت. يمكنك تغيير هذا لاحقًا من فحص الموثوقية.';

  @override
  String get alertExactOpen => 'فتح إعدادات المنبّهات';

  @override
  String get alertExactSkip => 'المتابعة بدونه';

  @override
  String get alertExactTitle => 'السماح بالمنبّهات الدقيقة؟';

  @override
  String get alertIgnoreQuietHours => 'تجاهل ساعات الهدوء';

  @override
  String get alertIgnoreQuietHoursHint =>
      'أبقِ هذا التنبيه مسموعًا حتى داخل ساعات الهدوء.';

  @override
  String get alertLoudAndroidOnly =>
      'الوضع المرتفع متاح على أندرويد فقط. في آيفون يكتم مفتاح الصامت صوت الإشعار، ويبقى الضغط على الإشعار يشغّل الأذان كاملًا.';

  @override
  String get alertLoudIntro =>
      'مُعطَّل افتراضيًا. عند تفعيله لصلاة ما، يُسمَع الأذان حتى لو كان الهاتف صامتًا. لا يغيّر التطبيق مستوى صوت النظام إلا إذا اخترت ذلك.';

  @override
  String alertLoudSwitch(String prayer) {
    return 'الوضع المرتفع لصلاة $prayer';
  }

  @override
  String get alertLoudTitle => 'الوضع المرتفع';

  @override
  String get alertMissedDismiss => 'إغلاق';

  @override
  String alertMissedLine(String when, String cause) {
    return '$when: $cause';
  }

  @override
  String alertMissedMore(int count) {
    return 'و$count أخرى';
  }

  @override
  String get alertMissedOpenCheck => 'فتح فحص الموثوقية';

  @override
  String get alertMissedPossibly =>
      'لا يستطيع آيفون تأكيد التسليم، لذا ربما فات هذا التنبيه فقط.';

  @override
  String get alertMissedTitle => 'ربما لم يصدر تنبيه صوتًا';

  @override
  String get alertMissedTitleMany => 'ربما لم تُصدر بعض التنبيهات صوتًا';

  @override
  String get alertNotifAdhkarEveningBody => 'وقت مناسب لأذكار المساء.';

  @override
  String get alertNotifAdhkarEveningTitle => 'أذكار المساء';

  @override
  String get alertNotifAdhkarMorningBody => 'وقت مناسب لأذكار الصباح.';

  @override
  String get alertNotifAdhkarMorningTitle => 'أذكار الصباح';

  @override
  String alertNotifPrayerBody(String prayer) {
    return 'حان وقت $prayer.';
  }

  @override
  String alertNotifPrayerTitle(String prayer) {
    return 'صلاة $prayer';
  }

  @override
  String alertNotifPreBody(String prayer) {
    return 'استعد لصلاة $prayer.';
  }

  @override
  String alertNotifPreTitle(String prayer, int minutes) {
    return '$prayer بعد $minutes د';
  }

  @override
  String get alertNotifRenewalBody =>
      'تنتهي تنبيهاتك المجدولة قريبًا. افتح التطبيق مرة واحدة لتُجدَّد.';

  @override
  String get alertNotifRenewalTitle => 'افتح التطبيق لتبقى تنبيهاتك مفعّلة';

  @override
  String get alertNotifStopLabel => 'إيقاف';

  @override
  String alertNotifSuhoorBody(int minutes) {
    return 'الفجر بعد $minutes د.';
  }

  @override
  String get alertNotifSuhoorTitle => 'تذكير بالسحور';

  @override
  String get alertOptionsTile => 'خيارات تنبيه إضافية';

  @override
  String get alertOptionsTileHint =>
      'الوضع المرتفع وساعات الهدوء والتذكيرات ومخرج الصوت';

  @override
  String get alertOptionsTitle => 'خيارات التنبيه';

  @override
  String get alertOutputBluetooth => 'بلوتوث';

  @override
  String get alertOutputHeadphones => 'سماعات الرأس';

  @override
  String get alertOutputSpeaker => 'مكبّر الصوت';

  @override
  String get alertPreviewFailed => 'تعذّر تشغيل هذا التسجيل.';

  @override
  String alertPreviewPlay(String name) {
    return 'تشغيل $name';
  }

  @override
  String get alertPreviewStop => 'إيقاف المعاينة';

  @override
  String get alertQuietEnd => 'تنتهي في';

  @override
  String get alertQuietIntro =>
      'التنبيهات التي تُصدر صوتًا داخل ساعات الهدوء تصبح إشعارات صامتة، إلا إذا ضُبطت الصلاة على تجاهلها.';

  @override
  String alertQuietRange(String start, String end) {
    return 'ساعات الهدوء من $start إلى $end';
  }

  @override
  String get alertQuietStart => 'تبدأ في';

  @override
  String get alertQuietSwitch => 'استخدام ساعات الهدوء';

  @override
  String get alertQuietTitle => 'ساعات الهدوء';

  @override
  String alertReminderFor(String prayer) {
    return 'تذكير لصلاة $prayer';
  }

  @override
  String get alertReminderIntro =>
      'التذكير ليس أذانًا كاملًا أبدًا؛ يستخدم نغمة قصيرة على الأكثر.';

  @override
  String alertReminderMinutes(int minutes) {
    return 'قبل $minutes د';
  }

  @override
  String get alertReminderNone => 'بدون تذكير';

  @override
  String alertReminderSummary(int minutes) {
    return 'تذكير قبل $minutes د';
  }

  @override
  String get alertReminderTitle => 'تذكير قبل كل صلاة';

  @override
  String get alertSaveFailed => 'تعذّر حفظ هذا الاختيار. حاول مرة أخرى.';

  @override
  String get alertSettingsIntro => 'اختر ما يحدث عند وقت كل صلاة.';

  @override
  String get alertSettingsTitle => 'تنبيهات الصلاة';

  @override
  String get alertSilentSwitchBody =>
      'عندما يكون مفتاح الصامت في آيفون مفعّلًا، يُكتم صوت الإشعار. ويبقى الضغط على الإشعار يشغّل الأذان كاملًا. ويمكنك أيضًا اختيار الاهتزاز بدلًا من ذلك.';

  @override
  String get alertSilentSwitchGotIt => 'فهمت';

  @override
  String get alertSilentSwitchTitle => 'عن مفتاح الصامت';

  @override
  String get alertSilentSwitchVibrate => 'استخدام الاهتزاز لتنبيهاتي';

  @override
  String get alertSuhoorIntro =>
      'في رمضان، تذكير قبل الفجر لتتناول السحور في وقته.';

  @override
  String alertSuhoorMinutes(int minutes) {
    return 'قبل الفجر بـ $minutes د';
  }

  @override
  String get alertSuhoorSwitch => 'ذكّرني قبل انتهاء السحور';

  @override
  String get alertSuhoorTitle => 'تذكير السحور';

  @override
  String get alertTypeFullAzaan => 'الأذان كاملًا';

  @override
  String alertTypeGroupLabel(String prayer) {
    return 'تنبيه $prayer';
  }

  @override
  String get alertTypeOff => 'إيقاف';

  @override
  String get alertTypeShortTone => 'نغمة قصيرة';

  @override
  String get alertTypeSilent => 'إشعار صامت';

  @override
  String get alertTypeVibrate => 'اهتزاز';

  @override
  String get alertVariantFajr => 'نسخة الفجر';

  @override
  String get alertVariantFajrHint =>
      'يتضمن «الصلاة خير من النوم». يُشغَّل عند الفجر إذا اخترت المعتاد.';

  @override
  String get alertVariantShia => 'صيغة الأذان الشيعية';

  @override
  String get alertVariantShiaHint =>
      'الأذان بالصيغة الشيعية. يُشغَّل في الصلوات الخمس عند اختياره.';

  @override
  String get alertVariantStandard => 'الأذان المعتاد';

  @override
  String get alertVariantStandardHint =>
      'الأذان المعتاد. يُستخدم تسجيل الفجر عند صلاة الفجر.';

  @override
  String alertVoiceForPrayer(String prayer) {
    return 'لصلاة $prayer';
  }

  @override
  String get alertVoiceIntro =>
      'لكل صوت ثلاثة تسجيلات. اضغط تشغيل لتسمع أحدها قبل الاختيار.';

  @override
  String alertVoiceName(int number) {
    return 'الصوت $number';
  }

  @override
  String get alertVoiceSelected => 'محدَّد';

  @override
  String get alertVoiceTile => 'الصوت';

  @override
  String alertVoiceTileValue(String voice, String variant) {
    return '$voice، $variant';
  }

  @override
  String get alertVoiceTitle => 'اختر الصوت';

  @override
  String get alertVolumeKeep => 'إبقاء مستوى الصوت الحالي';

  @override
  String get alertVolumeRamp => 'رفع تدريجي';

  @override
  String get alertVolumeRampHint => 'يبدأ هادئًا ويرتفع خلال بضع ثوانٍ.';

  @override
  String get appTitle => 'Deen App';

  @override
  String get asrHanafiBody =>
      'يبدأ العصر عندما يصبح ظل الشيء ضعف طوله، فيبدأ العصر متأخرًا (يعتمد عليه الحنفية).';

  @override
  String get asrHanafiTitle => 'الحنفي';

  @override
  String get asrStandardBody =>
      'يبدأ العصر عندما يصبح ظل الشيء مساويًا لطوله (يعتمد عليه الشافعية والمالكية والحنابلة).';

  @override
  String get asrStandardTitle => 'القياسي';

  @override
  String detailHijriAdjusted(String days) {
    return 'يشمل تعديلك البالغ $days يوم (تقويم أم القرى).';
  }

  @override
  String get detailHijriDefault => 'تقويم أم القرى.';

  @override
  String get detailHijriTitle => 'التاريخ الهجري';

  @override
  String get detailHijriUnavailable => 'التاريخ الهجري غير متاح بعد.';

  @override
  String detailHijriValue(String day, String month, String year) {
    return '$day $month $year هـ';
  }

  @override
  String get detailImsak => 'الإمساك';

  @override
  String get detailLastThird => 'الثلث الأخير من الليل';

  @override
  String get detailMidnight => 'منتصف الليل';

  @override
  String get errorGeneric => 'حدث خطأ ما. يرجى المحاولة مرة أخرى.';

  @override
  String get highLatAngleBody =>
      'يستخدم الفجر والعشاء جزءًا من الليل يساوي زاوية الشفق مقسومة على 60.';

  @override
  String get highLatAngleTitle => 'بحسب الزاوية';

  @override
  String highLatApplied(String rule) {
    return 'قُدِّر الفجر والعشاء بقاعدة «$rule» لأن خط عرضك فوق 48 درجة حيث قد لا ينتهي الشفق. يمكنك تغيير القاعدة من إعدادات الصلاة.';
  }

  @override
  String get highLatMiddleBody =>
      'يُقسَّم الليل إلى نصفين: لا يتأخر العشاء عن منتصف الليل ولا يبكّر الفجر عنه.';

  @override
  String get highLatMiddleTitle => 'منتصف الليل';

  @override
  String get highLatSeventhBody =>
      'يُقسَّم الليل إلى سبعة أجزاء: يكون العشاء بعد الغروب بجزء واحد على الأكثر والفجر قبل الشروق بجزء واحد.';

  @override
  String get highLatSeventhTitle => 'سُبع الليل';

  @override
  String get hijriMonth1 => 'محرم';

  @override
  String get hijriMonth10 => 'شوال';

  @override
  String get hijriMonth11 => 'ذو القعدة';

  @override
  String get hijriMonth12 => 'ذو الحجة';

  @override
  String get hijriMonth2 => 'صفر';

  @override
  String get hijriMonth3 => 'ربيع الأول';

  @override
  String get hijriMonth4 => 'ربيع الآخر';

  @override
  String get hijriMonth5 => 'جمادى الأولى';

  @override
  String get hijriMonth6 => 'جمادى الآخرة';

  @override
  String get hijriMonth7 => 'رجب';

  @override
  String get hijriMonth8 => 'شعبان';

  @override
  String get hijriMonth9 => 'رمضان';

  @override
  String get homeBackToToday => 'العودة إلى اليوم';

  @override
  String get homeBannerDismiss => 'إغلاق';

  @override
  String get homeChooseLocation => 'اختيار الموقع';

  @override
  String get homeClockBeforeBuild =>
      'يبدو تاريخ هاتفك خاطئًا: فهو أقدم من هذا الإصدار من التطبيق. قد تكون مواقيت الصلاة والتنبيهات خاطئة. يرجى مراجعة التاريخ والوقت في إعدادات هاتفك.';

  @override
  String get homeClockDrifted =>
      'تم تغيير ساعة هاتفك. إذا كان الوقت خاطئًا فقد تكون مواقيت الصلاة والتنبيهات خاطئة. يرجى مراجعة التاريخ والوقت في إعدادات هاتفك.';

  @override
  String get homeClockMovedBack =>
      'تم إرجاع ساعة هاتفك إلى الوراء. إذا كان الوقت خاطئًا فقد تكون مواقيت الصلاة والتنبيهات خاطئة. يرجى مراجعة التاريخ والوقت في إعدادات هاتفك.';

  @override
  String homeCountdownSemantics(String prayer, int hours, int minutes) {
    return '$prayer بعد $hours ساعة و$minutes دقيقة';
  }

  @override
  String get homeError =>
      'تعذّر حساب مواقيت الصلاة. تحقق من الموقع وحاول مرة أخرى.';

  @override
  String get homeMoreTimes => 'أوقات إضافية';

  @override
  String get homeNextBadge => 'التالية';

  @override
  String get homeNextDay => 'اليوم التالي';

  @override
  String get homeNoLocation => 'اختر موقعًا لعرض مواقيت الصلاة.';

  @override
  String get homePreviousDay => 'اليوم السابق';

  @override
  String homeRegionSuggestion(String method) {
    return 'تستخدم هذه المنطقة عادةً $method. تبقى الطريقة التي اخترتها كما هي.';
  }

  @override
  String homeRegionSuggestionGeneral(String method) {
    return 'لا توجد طريقة افتراضية لهذا الموقع. $method خيار عام. تبقى الطريقة التي اخترتها كما هي.';
  }

  @override
  String homeRegionSuggestionSwitch(String method) {
    return 'التبديل إلى $method';
  }

  @override
  String get homeTimeNotAvailable => 'لا يحدث اليوم';

  @override
  String homeTimeSemantics(String prayer, String time) {
    return '$prayer الساعة $time';
  }

  @override
  String get homeTitle => 'مواقيت الصلاة';

  @override
  String get homeToday => 'اليوم';

  @override
  String get homeTzRulesNotice =>
      'قد تكون قواعد المنطقة الزمنية قد تغيّرت. يرجى تحديث التطبيق. وإلى ذلك الحين تتبع المواقيت قواعد هاتفك.';

  @override
  String get languageNameAr => 'العربية';

  @override
  String get languageNameEn => 'English';

  @override
  String get languageNameId => 'Bahasa Indonesia';

  @override
  String get languageNameUr => 'اردو';

  @override
  String get languageSettingsTitle => 'اللغة';

  @override
  String get loading => 'جارٍ التحميل';

  @override
  String locationSettingsCurrent(String name) {
    return 'الموقع الحالي: $name';
  }

  @override
  String get locationSettingsNone => 'لا يوجد موقع محفوظ بعد.';

  @override
  String get locationSettingsSaved => 'تم حفظ الموقع. ستُحدَّث التنبيهات.';

  @override
  String get locationSettingsTitle => 'الموقع';

  @override
  String get methodDiyanet => 'تركيا (ديانت)';

  @override
  String get methodEgypt => 'الهيئة المصرية العامة للمساحة';

  @override
  String get methodFranceUoif => 'فرنسا (UOIF)';

  @override
  String get methodGulf => 'منطقة الخليج';

  @override
  String get methodIsna => 'الجمعية الإسلامية لأمريكا الشمالية (ISNA)';

  @override
  String get methodJafari => 'الشيعة الاثنا عشرية (الجعفري)';

  @override
  String get methodKarachi => 'جامعة العلوم الإسلامية بكراتشي';

  @override
  String get methodKuwait => 'الكويت';

  @override
  String get methodMoonsightingCommittee => 'لجنة رؤية الهلال';

  @override
  String get methodMuslimWorldLeague => 'رابطة العالم الإسلامي';

  @override
  String get methodQatar => 'قطر';

  @override
  String get methodSingapore => 'سنغافورة (المجلس الإسلامي)';

  @override
  String get methodTehran => 'معهد الجيوفيزياء، جامعة طهران';

  @override
  String get methodUmmAlQura => 'أم القرى (مكة المكرمة)';

  @override
  String get nextPrayerLabel => 'الصلاة القادمة';

  @override
  String get oemBrandHuawei => 'Huawei, Honor';

  @override
  String get oemBrandOneplus => 'OnePlus';

  @override
  String get oemBrandOppo => 'Oppo, realme';

  @override
  String get oemBrandOther => 'ماركة أخرى';

  @override
  String get oemBrandSamsung => 'Samsung';

  @override
  String get oemBrandVivo => 'Vivo, iQOO';

  @override
  String get oemBrandXiaomi => 'Xiaomi, Redmi, POCO';

  @override
  String get permissionBannerAction => 'إصلاح من الإعدادات';

  @override
  String get permissionBannerAlerts =>
      'الإشعارات متوقفة. لن تظهر تنبيهات الصلاة.';

  @override
  String get permissionBannerExact =>
      'المنبّهات الدقيقة متوقفة. قد تتأخر التنبيهات بضع دقائق.';

  @override
  String get permissionBannerLocation =>
      'الموقع متوقف. تُستخدم المدينة المحفوظة لديك.';

  @override
  String get prayerAsr => 'العصر';

  @override
  String get prayerDhuhr => 'الظهر';

  @override
  String get prayerFajr => 'الفجر';

  @override
  String get prayerIsha => 'العشاء';

  @override
  String get prayerJumuah => 'الجمعة';

  @override
  String get prayerMaghrib => 'المغرب';

  @override
  String get prayerSettingsHighLatIntro =>
      'فوق خط العرض 48 درجة قد لا ينتهي الشفق في الصيف. اختر كيف يُقدَّر الفجر والعشاء حينئذٍ.';

  @override
  String get prayerSettingsHighLatTitle => 'خطوط العرض العليا';

  @override
  String get prayerSettingsHijriLess => 'تأخير التاريخ الهجري يومًا';

  @override
  String get prayerSettingsHijriMore => 'تقديم التاريخ الهجري يومًا';

  @override
  String get prayerSettingsHijriTitle => 'تعديل التاريخ الهجري (بالأيام)';

  @override
  String prayerSettingsHijriValue(String value) {
    return '$value يوم';
  }

  @override
  String get prayerSettingsNoLocation =>
      'اختر موقعًا أولًا. تنطبق إعدادات الصلاة على موقعك المحفوظ.';

  @override
  String prayerSettingsOffsetLabel(String prayer) {
    return 'تعديل $prayer';
  }

  @override
  String prayerSettingsOffsetLess(String prayer) {
    return 'طرح دقيقة واحدة من $prayer';
  }

  @override
  String prayerSettingsOffsetMore(String prayer) {
    return 'إضافة دقيقة واحدة إلى $prayer';
  }

  @override
  String prayerSettingsOffsetValue(String value) {
    return '$value د';
  }

  @override
  String get prayerSettingsOffsetsIntro =>
      'أضف أو اطرح حتى 60 دقيقة لأي صلاة. ينطبق ذلك في كل مكان، بما في ذلك التنبيهات.';

  @override
  String get prayerSettingsOffsetsTitle => 'تعديل الأوقات';

  @override
  String get prayerSettingsTitle => 'إعدادات الصلاة';

  @override
  String get prayerSunrise => 'الشروق';

  @override
  String get qiblaAccuracyHigh => 'عالية';

  @override
  String qiblaAccuracyLabel(String level) {
    return 'دقة البوصلة: $level';
  }

  @override
  String get qiblaAccuracyLow => 'منخفضة';

  @override
  String get qiblaAccuracyMedium => 'متوسطة';

  @override
  String get qiblaAccuracyUnreliable => 'غير موثوقة';

  @override
  String get qiblaArrowSemantics => 'سهم البوصلة';

  @override
  String get qiblaAtHaram =>
      'أنت في المسجد الحرام بمكة المكرمة. استقبل الكعبة المشرفة مباشرة.';

  @override
  String qiblaBearingFromPlace(String place, String description) {
    return 'القبلة من $place: $description';
  }

  @override
  String get qiblaCalibrationPrompt =>
      'عايِر البوصلة. حرّك هاتفك على شكل رقم 8 عدة مرات بعيدًا عن المعادن والمغناطيس.';

  @override
  String get qiblaCompassError =>
      'تعذّر تشغيل البوصلة. يُعرض الاتجاه بالدرجات بدلًا من ذلك.';

  @override
  String qiblaDirectionDescription(int degrees, String direction) {
    return '$degrees درجة، $direction';
  }

  @override
  String get qiblaDirectionEast => 'الشرق';

  @override
  String get qiblaDirectionNorth => 'الشمال';

  @override
  String get qiblaDirectionNortheast => 'الشمال الشرقي';

  @override
  String get qiblaDirectionNorthwest => 'الشمال الغربي';

  @override
  String get qiblaDirectionSouth => 'الجنوب';

  @override
  String get qiblaDirectionSoutheast => 'الجنوب الشرقي';

  @override
  String get qiblaDirectionSouthwest => 'الجنوب الغربي';

  @override
  String get qiblaDirectionWest => 'الغرب';

  @override
  String qiblaDistanceToKaaba(int km) {
    return '$km كم إلى الكعبة';
  }

  @override
  String get qiblaEntryHint => 'اعرف اتجاه الكعبة';

  @override
  String get qiblaFacingQibla => 'أنت تواجه القبلة';

  @override
  String get qiblaInterferenceWarning =>
      'يوجد تشويش مغناطيسي قريب. ابتعد عن المعادن ومكبرات الصوت والمغناطيس والأجهزة الإلكترونية ثم تحقق مرة أخرى. قد يكون السهم غير صحيح إلى ذلك الحين.';

  @override
  String get qiblaMagneticNorthNote =>
      'تستخدم البوصلة الشمال المغناطيسي. قد يوجد خطأ بسيط.';

  @override
  String get qiblaNoCompassInstructions =>
      'استخدم الاتجاه أعلاه. حدّد الشمال بخريطة أو بوصلة أو بالشمس (تشرق من الشرق وتغرب في الغرب)، ثم استدر باتجاه عقارب الساعة من الشمال بعدد الدرجات المعروض.';

  @override
  String get qiblaNoCompassTitle => 'لا توجد بوصلة في هذا الجهاز';

  @override
  String get qiblaNoLocation => 'حدّد موقعك أولًا ليتم حساب اتجاه القبلة.';

  @override
  String get qiblaNorthReference =>
      'تُقاس باتجاه عقارب الساعة من الشمال الحقيقي';

  @override
  String get qiblaStartingCompass => 'جارٍ تشغيل البوصلة';

  @override
  String get qiblaTitle => 'القبلة';

  @override
  String get qiblaTurnHint => 'استدر حتى يشير السهم إلى الأعلى مباشرة';

  @override
  String qiblaTurnLeft(int degrees) {
    return 'استدر $degrees درجة إلى اليسار';
  }

  @override
  String qiblaTurnRight(int degrees) {
    return 'استدر $degrees درجة إلى اليمين';
  }

  @override
  String get reliabilityAllGood => 'كل شيء يبدو جيدًا.';

  @override
  String get reliabilityBattery => 'تحسين البطارية (أندرويد)';

  @override
  String get reliabilityBatteryFix =>
      'في بعض الهواتف قد يوقف توفير البطارية التنبيهات. افتح إعدادات البطارية واسمح لـ Deen App بالعمل في الخلفية.';

  @override
  String get reliabilityBatteryOk => 'التطبيق غير مقيَّد.';

  @override
  String get reliabilityBatteryOpen => 'فتح إعدادات البطارية';

  @override
  String get reliabilityCheckHint => 'تأكد من أن تنبيهاتك ستعمل';

  @override
  String get reliabilityCheckTitle => 'فحص الموثوقية';

  @override
  String get reliabilityErrorBudget =>
      'عدد التنبيهات أكبر مما يتّسع له هذا الهاتف، فتُركت المتأخرة منها حتى تفتح التطبيق مرة أخرى.';

  @override
  String get reliabilityErrorExactDenied =>
      'المنبّهات الدقيقة غير مسموح بها، فقد يقلّ ضبط التوقيت.';

  @override
  String get reliabilityErrorInvalid => 'لم يستطع الهاتف قبول هذا التنبيه.';

  @override
  String get reliabilityErrorPermissionDenied => 'الإشعارات غير مسموح بها.';

  @override
  String get reliabilityErrorPlatform => 'لم يستجب نظام التنبيهات.';

  @override
  String get reliabilityErrorServiceBlocked =>
      'منع أندرويد بدء صوت الأذان. تُستخدم نغمة الإشعار بدلًا منه.';

  @override
  String get reliabilityExact => 'المنبّهات الدقيقة (أندرويد)';

  @override
  String get reliabilityExactFix =>
      'المنبّهات الدقيقة معطّلة، فقد تتأخر التنبيهات بضع دقائق. اسمح بـ «المنبّهات والتذكيرات» لـ Deen App.';

  @override
  String get reliabilityExactOpen => 'فتح إعدادات المنبّهات';

  @override
  String get reliabilityFlagInexact => 'قد يتأخر التوقيت بضع دقائق';

  @override
  String get reliabilityFlagSilenced => 'مكتوم بسبب ساعات الهدوء';

  @override
  String get reliabilityIntro =>
      'تعرض هذه الشاشة ما إذا كانت تنبيهاتك ستعمل، وكيف تُصلح ما قد يوقفها.';

  @override
  String get reliabilityIosRefreshNote =>
      'في آيفون تُحدَّث التنبيهات في كل مرة تفتح فيها التطبيق. افتحه كل بضعة أيام لتستمر.';

  @override
  String get reliabilityKindRenewal => 'إشعار التجديد';

  @override
  String reliabilityLastLine(String when, String result) {
    return '$when: $result';
  }

  @override
  String get reliabilityLastNone => 'لم يصدر أي تنبيه بعد.';

  @override
  String get reliabilityLastTitle => 'نتيجة آخر تنبيه';

  @override
  String get reliabilityLoadFailed => 'تعذّر إكمال الفحص. حاول مرة أخرى.';

  @override
  String get reliabilityNextNone => 'لا شيء مجدول.';

  @override
  String reliabilityNextRow(String title, String type, String when) {
    return '$title، $type، $when';
  }

  @override
  String get reliabilityNextTitle => 'التنبيهات الخمسة القادمة';

  @override
  String get reliabilityNotifications => 'الإشعارات';

  @override
  String get reliabilityNotificationsAllow => 'السماح بالإشعارات';

  @override
  String get reliabilityNotificationsFix =>
      'الإشعارات معطّلة، فلا يمكن ظهور التنبيهات. اسمح بالإشعارات لـ Deen App.';

  @override
  String get reliabilityNotificationsSettings => 'فتح إعدادات الإشعارات';

  @override
  String get reliabilityPermissionsTitle => 'الأذونات';

  @override
  String get reliabilityProblemsFound => 'هناك أمر يحتاج إلى انتباهك.';

  @override
  String reliabilityRebuildFailed(String reason) {
    return 'تعذّر تحديث تنبيهاتك. $reason';
  }

  @override
  String get reliabilityRefresh => 'تحقق مرة أخرى';

  @override
  String reliabilityRegistered(int count) {
    return '$count تنبيهًا مسجّلًا لدى الهاتف.';
  }

  @override
  String get reliabilityResultAcknowledged => 'أوقفته أنت';

  @override
  String get reliabilityResultFailed => 'فشل';

  @override
  String get reliabilityResultFired => 'تم التسليم';

  @override
  String get reliabilityResultMissed => 'فات';

  @override
  String get reliabilityResultPlanned => 'في الانتظار';

  @override
  String get reliabilityResultPlayed => 'شُغِّل الأذان';

  @override
  String get reliabilityResultPossiblyMissed => 'ربما فات';

  @override
  String get reliabilityResultSuppressed => 'مكتوم';

  @override
  String get reliabilityRunsUntilHint =>
      'افتح التطبيق قبل هذا التاريخ لتستمر التنبيهات. يجدّدها في كل مرة.';

  @override
  String get reliabilityRunsUntilNone => 'لا توجد تنبيهات مجدولة بعد.';

  @override
  String get reliabilityRunsUntilTitle => 'تعمل التنبيهات حتى';

  @override
  String get reliabilitySilentSwitchTip =>
      'إذا كان مفتاح الصامت في آيفون مفعّلًا فإن أصوات الإشعارات تُكتم. والضغط على الإشعار يشغّل الأذان كاملًا.';

  @override
  String get reliabilitySound => 'صوت الإشعارات (آيفون)';

  @override
  String get reliabilitySoundFix =>
      'الصوت معطّل في إعدادات الإشعارات، فستكون التنبيهات صامتة. اسمح بالصوت لـ Deen App.';

  @override
  String get reliabilityStateOff => 'معطّل';

  @override
  String get reliabilityStateOn => 'مفعّل';

  @override
  String get reliabilityTestButton => 'أرسل أذانًا تجريبيًا بعد دقيقة';

  @override
  String reliabilityTestFailed(String reason) {
    return 'تعذّر ضبط التجربة. $reason';
  }

  @override
  String get reliabilityTestNeedsNotifications =>
      'اسمح بالإشعارات أولًا ثم حاول مرة أخرى.';

  @override
  String reliabilityTestScheduled(String time) {
    return 'ضُبط الأذان التجريبي في $time. اقفل هاتفك وانتظر.';
  }

  @override
  String get reliabilityUnsupported =>
      'لا يستطيع هذا الجهاز جدولة التنبيهات، فلا شيء لفحصه هنا.';

  @override
  String get settingsAppearanceHint => 'السمة وحجم النص والتباين';

  @override
  String get settingsAppearanceNeedsSetup =>
      'أكمل الإعداد أولاً. يمكنك تغيير المظهر بعد حفظ إعدادات الصلاة.';

  @override
  String get settingsAppearanceTitle => 'المظهر';

  @override
  String get settingsDataHint => 'تصدير أو استيراد أو حذف';

  @override
  String get settingsDataTitle => 'بياناتك';

  @override
  String get settingsDeleteBody =>
      'يزيل إعداداتك وموقعك وعدّاد التسبيح والعلامات المرجعية وسجل التنبيهات من هذا الجهاز، ويلغي جميع التنبيهات المجدولة.';

  @override
  String get settingsDeleteCancel => 'إلغاء';

  @override
  String get settingsDeleteConfirmAction => 'احذف كل شيء';

  @override
  String get settingsDeleteConfirmBody =>
      'يزيل هذا كل ما يخزنه التطبيق على هذا الجهاز ولا يمكن التراجع عنه. ملفات الإعدادات التي حفظتها أو شاركتها خارج التطبيق لا تُحذف وتبقى حيث وضعتها.';

  @override
  String get settingsDeleteConfirmTitle => 'حذف كل البيانات؟';

  @override
  String get settingsDeleteDone => 'تم حذف كل البيانات.';

  @override
  String get settingsDeletePartial =>
      'تعذّر حذف بعض البيانات. يرجى المحاولة مرة أخرى.';

  @override
  String get settingsDeleteTitle => 'حذف كل بياناتي';

  @override
  String get settingsExportCancelled => 'أُلغي التصدير.';

  @override
  String get settingsExportDone => 'ملف الإعدادات جاهز.';

  @override
  String get settingsExportFailed => 'تعذّر إنشاء ملف الإعدادات.';

  @override
  String get settingsExportSave => 'حفظ ملف الإعدادات';

  @override
  String get settingsExportShare => 'مشاركة ملف الإعدادات';

  @override
  String get settingsExportTitle => 'تصدير الإعدادات';

  @override
  String get settingsExportWarning =>
      'يحتوي الملف على موقعك المحفوظ وإعداداتك. يستطيع أي شخص يحصل عليه معرفة مكانك. شاركه فقط مع أشخاص وجهات تثق بهم.';

  @override
  String get settingsHighContrast => 'تباين عالٍ';

  @override
  String get settingsHighContrastHint =>
      'ألوان نص وحدود أقوى. لا يعتمد أي شيء في التطبيق على اللون وحده.';

  @override
  String get settingsImportBody =>
      'اختر ملف إعدادات صُدّر من التطبيق. يستبدل الإعدادات التي يحتوي عليها. إذا كان في الملف مشكلة فلن يتغير شيء.';

  @override
  String get settingsImportButton => 'اختيار ملف الإعدادات';

  @override
  String get settingsImportDone => 'تم استيراد الإعدادات.';

  @override
  String get settingsImportDoneLater =>
      'تم استيراد الإعدادات. ستُحدَّث التنبيهات عند فتح التطبيق في المرة القادمة.';

  @override
  String get settingsImportFailed => 'تعذّر حفظ الإعدادات. لم يتغير شيء.';

  @override
  String settingsImportInvalid(String field) {
    return 'في الملف قيمة مفقودة أو خارج النطاق ($field). لم يتغير شيء.';
  }

  @override
  String get settingsImportNewer =>
      'أُنشئ هذا الملف بإصدار أحدث من التطبيق. حدّث التطبيق لقراءته.';

  @override
  String get settingsImportNotSettings => 'هذا ليس ملف إعدادات للتطبيق.';

  @override
  String get settingsImportTitle => 'استيراد الإعدادات';

  @override
  String get settingsImportUnreadable => 'تعذّرت قراءة الملف.';

  @override
  String get settingsSaveError => 'تعذّر حفظ هذا التغيير.';

  @override
  String get settingsTextSizeLabel => 'حجم النص';

  @override
  String get settingsTextSizeLarger => 'نص أكبر';

  @override
  String get settingsTextSizeSample => 'نص تجريبي: هكذا يظهر النص بهذا الحجم.';

  @override
  String get settingsTextSizeSmaller => 'نص أصغر';

  @override
  String settingsTextSizeValue(int percent) {
    return '$percent%';
  }

  @override
  String get settingsThemeDark => 'داكن';

  @override
  String get settingsThemeLabel => 'السمة';

  @override
  String get settingsThemeLight => 'فاتح';

  @override
  String get settingsThemeSystem => 'مطابقة الجهاز';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get setupAsrIntro =>
      'اختر المذهب الذي تتبعه في بداية وقت العصر. الخيار «القياسي» محدد مسبقًا.';

  @override
  String get setupAsrTitle => 'صلاة العصر';

  @override
  String get setupBack => 'رجوع';

  @override
  String get setupBatteryBody =>
      'تغلق بعض الهواتف التطبيقات في الخلفية لتوفير البطارية، مما قد يؤخر التنبيهات أو يوقفها. اختر ماركة هاتفك واتبع الخطوات.';

  @override
  String get setupBatteryBrandLabel => 'ماركة هاتفك';

  @override
  String get setupBatteryGuideUnavailable =>
      'تعذّر تحميل خطوات هذه الماركة. افتح إعدادات البطارية واسمح لـ Deen App بالعمل في الخلفية.';

  @override
  String get setupBatteryOpenSettings => 'فتح إعدادات البطارية';

  @override
  String setupBatteryStep(int number, String text) {
    return 'الخطوة $number: $text';
  }

  @override
  String get setupBatteryTitle => 'حافظ على موثوقية التنبيهات';

  @override
  String get setupExactBody =>
      'لا يستطيع أندرويد تشغيل التنبيه في وقت الصلاة بالضبط إلا إذا سمحت بالمنبّهات الدقيقة. وبدونها تصل التنبيهات لكنها قد تتأخر بضع دقائق.';

  @override
  String get setupExactCheck => 'لقد غيّرته، تحقق مرة أخرى';

  @override
  String get setupExactContinue => 'المتابعة بدونها';

  @override
  String get setupExactDenied =>
      'المنبّهات الدقيقة متوقفة. ستصل التنبيهات لكنها قد تتأخر بضع دقائق. يعرض فحص الموثوقية ذلك.';

  @override
  String get setupExactGranted => 'المنبّهات الدقيقة مسموح بها.';

  @override
  String get setupExactOpen => 'فتح إعدادات المنبّه';

  @override
  String get setupExactTitle => 'توقيت التنبيه الدقيق';

  @override
  String get setupFinish => 'إنهاء الإعداد';

  @override
  String get setupLanguageBody => 'يمكنك تغيير ذلك في أي وقت من الإعدادات.';

  @override
  String get setupLanguageTitle => 'اختر لغتك';

  @override
  String get setupLocationApproximate => 'استخدام موقعي التقريبي';

  @override
  String get setupLocationApproximateHint =>
      'التقريبي يقرّب موقعك إلى نحو 10 كم. تتغير المواقيت بأقل بكثير من دقيقة.';

  @override
  String get setupLocationApproximateName => 'الموقع التقريبي';

  @override
  String get setupLocationCurrentName => 'الموقع الحالي';

  @override
  String get setupLocationFinding => 'جارٍ تحديد موقعك…';

  @override
  String get setupLocationNeeded => 'اختر موقعًا أو مدينة للمتابعة.';

  @override
  String get setupLocationOfflineNote =>
      'قائمة المدن مخزنة في التطبيق، فيعمل البحث دون إنترنت. يمكنك عدم مشاركة موقعك واختيار مدينة فقط.';

  @override
  String get setupLocationPrecise => 'استخدام موقعي الدقيق';

  @override
  String get setupLocationPrivacy =>
      'يبقى موقعك على هذا الجهاز. لا يُرسل إلى أي جهة، ويُستخدم فقط لحساب مواقيت الصلاة.';

  @override
  String get setupLocationSearchEmpty =>
      'لم يتم العثور على مدينة. تحقق من الإملاء أو جرّب اسمًا آخر.';

  @override
  String get setupLocationSearchHint => 'اسم المدينة';

  @override
  String get setupLocationSearchLabel => 'أو ابحث عن مدينة';

  @override
  String setupLocationSelected(String name) {
    return 'المحدد: $name';
  }

  @override
  String get setupLocationTitle => 'موقعك';

  @override
  String get setupMethodChange => 'يمكنك اختيار طريقة أخرى:';

  @override
  String get setupMethodGeneral =>
      'لا توجد طريقة افتراضية لمنطقتك، لذلك تُقترح الطريقة العامة لرابطة العالم الإسلامي.';

  @override
  String setupMethodSuggested(String method) {
    return 'المقترحة لمنطقتك: $method';
  }

  @override
  String get setupMethodTitle => 'طريقة الحساب';

  @override
  String get setupNext => 'التالي';

  @override
  String get setupNotNow => 'ليس الآن';

  @override
  String get setupNotificationsAllow => 'السماح بالإشعارات';

  @override
  String get setupNotificationsBody =>
      'لتذكيرك في أوقات الصلاة يحتاج Deen App إلى إذن لعرض الإشعارات. تُنشأ التنبيهات على هاتفك، ولا يُرسل شيء عبر الإنترنت.';

  @override
  String get setupNotificationsDenied =>
      'الإشعارات متوقفة، لذلك لن تظهر تنبيهات الصلاة. يمكنك السماح بها لاحقًا من إعدادات التطبيق.';

  @override
  String get setupNotificationsGranted => 'الإشعارات مسموح بها.';

  @override
  String get setupNotificationsTitle => 'تنبيهات الصلاة';

  @override
  String get setupOpenAppSettings => 'فتح إعدادات التطبيق';

  @override
  String get setupPrivacyNoData => 'لا يجمع Deen App أي بيانات شخصية.';

  @override
  String get setupPrivacyNoTracking =>
      'لا توجد حسابات ولا إعلانات ولا أدوات تتبّع، ويعمل التطبيق دون اتصال بالإنترنت.';

  @override
  String get setupPrivacyOnDevice =>
      'يبقى موقعك وإعداداتك وسجل تنبيهاتك على هذا الهاتف.';

  @override
  String get setupPrivacyTitle => 'خصوصيتك';

  @override
  String get setupProblemLocationDenied =>
      'لم يُسمح بالوصول إلى الموقع. اختر مدينة من القائمة بدلًا من ذلك، أو اسمح بالموقع من إعدادات التطبيق.';

  @override
  String get setupProblemLocationTimeout =>
      'تعذّر تحديد موقعك في الوقت المناسب. حاول مرة أخرى أو اختر مدينة من القائمة.';

  @override
  String get setupProblemLocationUnavailable =>
      'خدمة الموقع غير متاحة على هذا الهاتف حاليًا. اختر مدينة من القائمة.';

  @override
  String get setupProblemSaveFailed =>
      'تعذّر حفظ اختيارك. يرجى المحاولة مرة أخرى.';

  @override
  String get setupProblemZoneUnknown =>
      'لم يُبلغ هاتفك عن منطقة زمنية. اختر مدينة من القائمة.';

  @override
  String setupProgress(int current, int total) {
    return 'الخطوة $current من $total';
  }

  @override
  String get setupSummaryAlerts =>
      'لن تظهر تنبيهات الصلاة لأن الإشعارات متوقفة.';

  @override
  String get setupSummaryExact =>
      'قد تتأخر التنبيهات بضع دقائق لأن المنبّهات الدقيقة متوقفة.';

  @override
  String get setupSummaryLocation =>
      'موقع هاتفك متوقف، لذلك تُستخدم المدينة التي اخترتها.';

  @override
  String get setupSummaryTitle => 'ما الذي لن يعمل بعد';

  @override
  String get setupSummaryWayBack =>
      'يمكنك السماح بأي منها لاحقًا من إعدادات التطبيق.';

  @override
  String get setupTitle => 'إعداد Deen App';

  @override
  String get tasbihCancel => 'إلغاء';

  @override
  String get tasbihCountHint => 'يضيف واحدًا إلى العدد';

  @override
  String tasbihCountLabel(int count, int target) {
    return 'العدد: $count من $target';
  }

  @override
  String get tasbihEntryHint => 'عُدّ أذكارك';

  @override
  String get tasbihHaptics => 'اهتزاز عند كل عدّة';

  @override
  String get tasbihHistoryEmpty =>
      'لا توجد عدّات بعد. ستظهر مجاميعك اليومية هنا.';

  @override
  String get tasbihHistoryTitle => 'السجل';

  @override
  String get tasbihKeepAwake => 'إبقاء الشاشة مضاءة';

  @override
  String get tasbihLock => 'قفل اللمس على العداد';

  @override
  String get tasbihLockHint =>
      'لن يضيف اللمس العرضي عدّة. تبقى مفاتيح الصوت تعدّ.';

  @override
  String get tasbihLockedMessage => 'مقفل. يتم تجاهل اللمس على العداد.';

  @override
  String tasbihOfTarget(int target) {
    return 'من $target';
  }

  @override
  String get tasbihOptionsTitle => 'الخيارات';

  @override
  String get tasbihReset => 'إعادة تعيين';

  @override
  String get tasbihResetBody =>
      'سيعود العدد إلى 0. تبقى مجاميعك اليومية محفوظة.';

  @override
  String get tasbihResetTitle => 'إعادة تعيين العداد؟';

  @override
  String tasbihRounds(int rounds) {
    return 'الجولات المكتملة: $rounds';
  }

  @override
  String get tasbihSave => 'حفظ';

  @override
  String get tasbihSaveError => 'تعذّر حفظ العدد. حاول مرة أخرى.';

  @override
  String get tasbihSound => 'صوت النقر';

  @override
  String get tasbihTargetCustom => 'مخصص';

  @override
  String get tasbihTargetCustomField => 'الهدف (من 1 إلى 100000)';

  @override
  String tasbihTargetCustomLabel(int target) {
    return 'هدف مخصص: $target';
  }

  @override
  String get tasbihTargetCustomTitle => 'هدف مخصص';

  @override
  String get tasbihTargetHeading => 'الهدف';

  @override
  String get tasbihTargetInvalid => 'أدخل عددًا صحيحًا من 1 إلى 100000.';

  @override
  String tasbihTargetOptionLabel(int target) {
    return 'الهدف $target';
  }

  @override
  String tasbihTargetReached(int target) {
    return 'تم بلوغ الهدف $target';
  }

  @override
  String get tasbihTitle => 'المسبحة';

  @override
  String tasbihTodayTotal(int total) {
    return 'اليوم: $total';
  }

  @override
  String get tasbihUnlock => 'اضغط مطولًا لفتح القفل';

  @override
  String get tasbihUnlockPressHint => 'اضغط على الزر مطولًا لفتح القفل.';

  @override
  String get tasbihVolumeKeys => 'العدّ بمفاتيح الصوت';

  @override
  String get tasbihVolumeKeysHint =>
      'أثناء فتح هذه الشاشة تعدّ مفاتيح الصوت بدلًا من تغيير مستوى الصوت.';
}
