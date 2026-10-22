// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get aboutAttributionsTitle => 'Atribusi';

  @override
  String get aboutCitiesHeading => 'Data kota';

  @override
  String get aboutContentHeading => 'Teks zikir';

  @override
  String get aboutDescription =>
      'Waktu salat, peringatan azan, dan alat ibadah harian. Semuanya berjalan tanpa internet.';

  @override
  String get aboutEntryHint => 'Lisensi, sumber, dan privasi';

  @override
  String get aboutFontsHeading => 'Font';

  @override
  String get aboutHijriHeading => 'Data kalender Hijriah';

  @override
  String get aboutLegalEnglishNote =>
      'Teks di bawah adalah kalimat lisensi dan tetap dalam bahasa Inggris.';

  @override
  String get aboutLicensesSubtitle =>
      'Lisensi perangkat lunak yang dipakai untuk membangun aplikasi ini';

  @override
  String get aboutLicensesTitle => 'Lisensi sumber terbuka';

  @override
  String get aboutNoDataCollected =>
      'Aplikasi ini tidak mengumpulkan data apa pun. Tidak ada akun, analitik, atau iklan. Lokasi Anda tetap di perangkat ini dan hanya dipakai untuk menghitung waktu salat dan arah kiblat.';

  @override
  String get aboutPrivacyHeading => 'Privasi Anda';

  @override
  String aboutPrivacyPolicyAddress(String address) {
    return 'Baca kebijakan lengkap di: $address';
  }

  @override
  String get aboutPrivacyPolicyPending =>
      'Kebijakan privasi lengkap akan dipublikasikan sebelum rilis. Isinya sama: aplikasi tidak mengumpulkan data.';

  @override
  String get aboutPrivacyPolicyTitle => 'Kebijakan privasi';

  @override
  String get aboutTitle => 'Tentang';

  @override
  String aboutVersion(String version) {
    return 'Versi $version';
  }

  @override
  String get adhkarBookmarkAdd => 'Tambah markah';

  @override
  String get adhkarBookmarkRemove => 'Hapus markah';

  @override
  String get adhkarBookmarksEmpty =>
      'Belum ada zikir yang dimarkahi. Gunakan tombol markah pada sebuah zikir untuk menyimpannya di sini.';

  @override
  String get adhkarBookmarksTitle => 'Markah';

  @override
  String get adhkarCollectionAfterPrayer => 'Zikir setelah salat';

  @override
  String get adhkarCollectionBeforeSleep => 'Zikir sebelum tidur';

  @override
  String get adhkarCollectionEvening => 'Zikir petang';

  @override
  String get adhkarCollectionMorning => 'Zikir pagi';

  @override
  String get adhkarCollectionOther => 'Zikir lainnya';

  @override
  String get adhkarCollectionWaking => 'Zikir bangun tidur';

  @override
  String adhkarCountLabel(int done, int total) {
    return 'Ketuk untuk menghitung: $done dari $total';
  }

  @override
  String adhkarCreditEntry(int order, String reference) {
    return 'Zikir $order: $reference';
  }

  @override
  String adhkarCreditReviewer(String reviewer, String date) {
    return 'Ditinjau oleh $reviewer pada $date.';
  }

  @override
  String adhkarCreditSource(String source, String license) {
    return 'Sumber: $source. Lisensi: $license.';
  }

  @override
  String adhkarCreditsCount(int count) {
    return 'Jumlah teks tercantum: $count';
  }

  @override
  String get adhkarCreditsEmpty =>
      'Versi ini belum menyertakan teks zikir, jadi belum ada sumber yang dicantumkan.';

  @override
  String get adhkarCreditsIntro =>
      'Setiap teks mencantumkan sumbernya, lisensinya, dan siapa yang meninjaunya.';

  @override
  String get adhkarCreditsTitle => 'Sumber konten dan peninjau';

  @override
  String get adhkarEmptyBody =>
      'Versi aplikasi ini belum menyertakan teks zikir. Teks akan ditambahkan hanya setelah sumbernya berlisensi dan telah ditinjau oleh seorang ulama.';

  @override
  String get adhkarEmptyTitle => 'Zikir belum tersedia';

  @override
  String adhkarEntryCount(int count) {
    return 'Jumlah zikir: $count';
  }

  @override
  String get adhkarEntryDone => 'Selesai';

  @override
  String get adhkarEntryHint => 'Zikir harian, markah, dan pengingat';

  @override
  String get adhkarLoadError => 'Zikir tidak dapat dimuat.';

  @override
  String get adhkarNext => 'Zikir berikutnya';

  @override
  String get adhkarNotFound => 'Koleksi ini tidak tersedia.';

  @override
  String adhkarPosition(int position, int total) {
    return 'Zikir $position dari $total';
  }

  @override
  String get adhkarPrevious => 'Zikir sebelumnya';

  @override
  String adhkarProgressLabel(int done, int total) {
    return '$done dari $total zikir selesai';
  }

  @override
  String adhkarReminderAfter(int minutes, String prayer) {
    return '$minutes menit setelah $prayer';
  }

  @override
  String get adhkarReminderAnchor => 'Hitung waktu dari';

  @override
  String adhkarReminderAt(String prayer) {
    return 'Pada waktu $prayer';
  }

  @override
  String adhkarReminderBefore(int minutes, String prayer) {
    return '$minutes menit sebelum $prayer';
  }

  @override
  String get adhkarReminderEarlier => '5 menit lebih awal';

  @override
  String get adhkarReminderEnable => 'Ingatkan saya';

  @override
  String get adhkarReminderEvening => 'Pengingat petang';

  @override
  String get adhkarReminderFajrOnly => 'Pengingat pagi mengikuti waktu Subuh.';

  @override
  String get adhkarReminderLater => '5 menit lebih lambat';

  @override
  String get adhkarReminderMorning => 'Pengingat pagi';

  @override
  String get adhkarReminderNote =>
      'Pengingat berupa notifikasi di perangkat ini. Waktunya mengikuti waktu salat Anda, sehingga ikut berubah bersama lokasi dan metode perhitungan.';

  @override
  String get adhkarReminderSaveError => 'Pengingat tidak dapat disimpan.';

  @override
  String get adhkarRemindersTitle => 'Pengingat zikir';

  @override
  String adhkarRepeatLabel(int count) {
    return 'Jumlah pengulangan: $count';
  }

  @override
  String get adhkarSessionComplete => 'Sesi selesai';

  @override
  String adhkarSourceLabel(String reference) {
    return 'Sumber: $reference';
  }

  @override
  String get adhkarStartAgain => 'Mulai lagi';

  @override
  String get adhkarTitle => 'Zikir';

  @override
  String get adhkarTranslationFallbackHeading =>
      'Terjemahan (bahasa Inggris; belum tersedia dalam bahasa Anda)';

  @override
  String get adhkarTranslationHeading => 'Terjemahan';

  @override
  String get adhkarTransliterationHeading => 'Transliterasi';

  @override
  String get adhkarUndo => 'Batalkan hitungan terakhir';

  @override
  String get alertAudioIntro =>
      'Tempat azan diputar saat headphone atau perangkat Bluetooth terhubung. Tanpa keduanya, azan diputar lewat speaker.';

  @override
  String get alertAudioTitle => 'Keluaran audio';

  @override
  String get alertCauseAppNotRun => 'Aplikasi belum dibuka.';

  @override
  String get alertCauseBatteryRestricted =>
      'Penghemat baterai mungkin menghentikannya. Periksa pengaturan baterai.';

  @override
  String get alertCauseCallInProgress => 'Sedang ada panggilan telepon.';

  @override
  String get alertCauseExactAlarmDenied =>
      'Alarm tepat waktu mati, jadi Android mungkin menundanya.';

  @override
  String get alertCauseFgsBlocked =>
      'Android tidak mengizinkan aplikasi memulai azan, jadi nada notifikasi digunakan.';

  @override
  String get alertCauseNotificationDenied => 'Notifikasi dimatikan.';

  @override
  String get alertCauseQuietHours => 'Dibisukan oleh jam tenang.';

  @override
  String get alertCauseScheduleEnded =>
      'Peringatan terjadwal habis karena aplikasi lama tidak dibuka. Membukanya telah memperbarui jadwal.';

  @override
  String get alertCauseSilentMode => 'Ponsel dalam mode senyap.';

  @override
  String get alertCauseUnknown => 'Penyebabnya tidak diketahui.';

  @override
  String get alertExactBody =>
      'Agar berbunyi tepat pada waktu salat, Android memerlukan izin “Alarm & pengingat” untuk Deen App. Tanpa izin ini, peringatan tetap datang tetapi bisa terlambat beberapa menit.';

  @override
  String get alertExactCheck => 'Sudah saya ubah, periksa lagi';

  @override
  String get alertExactGranted => 'Alarm tepat waktu aktif.';

  @override
  String get alertExactInexact =>
      'Peringatan tetap datang, tetapi ketepatan waktunya bisa berkurang. Anda dapat mengubahnya nanti di Pemeriksaan keandalan.';

  @override
  String get alertExactOpen => 'Buka pengaturan alarm';

  @override
  String get alertExactSkip => 'Lanjutkan tanpa izin';

  @override
  String get alertExactTitle => 'Izinkan alarm tepat waktu?';

  @override
  String get alertIgnoreQuietHours => 'Abaikan jam tenang';

  @override
  String get alertIgnoreQuietHoursHint =>
      'Tetap bunyikan peringatan ini meski di dalam jam tenang.';

  @override
  String get alertLoudAndroidOnly =>
      'Mode keras hanya tersedia di Android. Di iPhone, tombol senyap membisukan suara notifikasi; mengetuk notifikasi tetap memutar azan lengkap.';

  @override
  String get alertLoudIntro =>
      'Mati secara bawaan. Jika aktif untuk suatu salat, azan berbunyi meski ponsel dalam mode senyap. Deen App tidak pernah mengubah volume sistem kecuali Anda memilihnya.';

  @override
  String alertLoudSwitch(String prayer) {
    return 'Mode keras untuk $prayer';
  }

  @override
  String get alertLoudTitle => 'Mode keras';

  @override
  String get alertMissedDismiss => 'Tutup';

  @override
  String alertMissedLine(String when, String cause) {
    return '$when: $cause';
  }

  @override
  String alertMissedMore(int count) {
    return 'dan $count lainnya';
  }

  @override
  String get alertMissedOpenCheck => 'Buka Pemeriksaan keandalan';

  @override
  String get alertMissedPossibly =>
      'iPhone tidak dapat memastikan pengiriman, jadi ini hanya mungkin terlewat.';

  @override
  String get alertMissedTitle => 'Satu peringatan mungkin tidak berbunyi';

  @override
  String get alertMissedTitleMany =>
      'Beberapa peringatan mungkin tidak berbunyi';

  @override
  String get alertNotifAdhkarEveningBody =>
      'Waktu yang baik untuk zikir petang.';

  @override
  String get alertNotifAdhkarEveningTitle => 'Zikir petang';

  @override
  String get alertNotifAdhkarMorningBody => 'Waktu yang baik untuk zikir pagi.';

  @override
  String get alertNotifAdhkarMorningTitle => 'Zikir pagi';

  @override
  String alertNotifPrayerBody(String prayer) {
    return 'Waktu $prayer telah tiba.';
  }

  @override
  String alertNotifPrayerTitle(String prayer) {
    return 'Salat $prayer';
  }

  @override
  String alertNotifPreBody(String prayer) {
    return 'Bersiaplah untuk salat $prayer.';
  }

  @override
  String alertNotifPreTitle(String prayer, int minutes) {
    return '$prayer dalam $minutes mnt';
  }

  @override
  String get alertNotifRenewalBody =>
      'Peringatan terjadwal Anda segera berakhir. Buka aplikasi sekali dan peringatan diperbarui.';

  @override
  String get alertNotifRenewalTitle =>
      'Buka Deen App agar peringatan tetap aktif';

  @override
  String get alertNotifStopLabel => 'Hentikan';

  @override
  String alertNotifSuhoorBody(int minutes) {
    return 'Subuh dalam $minutes mnt.';
  }

  @override
  String get alertNotifSuhoorTitle => 'Pengingat sahur';

  @override
  String get alertOptionsTile => 'Opsi peringatan lainnya';

  @override
  String get alertOptionsTileHint =>
      'Mode keras, jam tenang, pengingat, dan keluaran audio';

  @override
  String get alertOptionsTitle => 'Opsi peringatan';

  @override
  String get alertOutputBluetooth => 'Bluetooth';

  @override
  String get alertOutputHeadphones => 'Headphone';

  @override
  String get alertOutputSpeaker => 'Speaker';

  @override
  String get alertPreviewFailed => 'Rekaman ini tidak dapat diputar.';

  @override
  String alertPreviewPlay(String name) {
    return 'Putar $name';
  }

  @override
  String get alertPreviewStop => 'Hentikan pratinjau';

  @override
  String get alertQuietEnd => 'Berakhir pukul';

  @override
  String get alertQuietIntro =>
      'Peringatan yang berbunyi di dalam jam tenang menjadi notifikasi senyap, kecuali salat diatur untuk mengabaikannya.';

  @override
  String alertQuietRange(String start, String end) {
    return 'Jam tenang $start sampai $end';
  }

  @override
  String get alertQuietStart => 'Mulai pukul';

  @override
  String get alertQuietSwitch => 'Gunakan jam tenang';

  @override
  String get alertQuietTitle => 'Jam tenang';

  @override
  String alertReminderFor(String prayer) {
    return 'Pengingat untuk $prayer';
  }

  @override
  String get alertReminderIntro =>
      'Pengingat tidak pernah berupa azan lengkap; paling banyak nada pendek.';

  @override
  String alertReminderMinutes(int minutes) {
    return '$minutes mnt sebelumnya';
  }

  @override
  String get alertReminderNone => 'Tanpa pengingat';

  @override
  String alertReminderSummary(int minutes) {
    return 'Pengingat $minutes mnt sebelumnya';
  }

  @override
  String get alertReminderTitle => 'Pengingat sebelum setiap salat';

  @override
  String get alertSaveFailed =>
      'Pilihan ini tidak dapat disimpan. Silakan coba lagi.';

  @override
  String get alertSettingsIntro =>
      'Pilih apa yang terjadi pada setiap waktu salat.';

  @override
  String get alertSettingsTitle => 'Peringatan salat';

  @override
  String get alertSilentSwitchBody =>
      'Saat tombol senyap iPhone aktif, suara notifikasi dibisukan. Mengetuk notifikasi tetap memutar azan lengkap. Anda juga dapat memilih getar.';

  @override
  String get alertSilentSwitchGotIt => 'Mengerti';

  @override
  String get alertSilentSwitchTitle => 'Tentang tombol senyap';

  @override
  String get alertSilentSwitchVibrate => 'Gunakan getar untuk peringatan saya';

  @override
  String get alertSuhoorIntro =>
      'Selama Ramadan, pengingat sebelum Subuh agar Anda sempat sahur.';

  @override
  String alertSuhoorMinutes(int minutes) {
    return '$minutes mnt sebelum Subuh';
  }

  @override
  String get alertSuhoorSwitch => 'Ingatkan saya sebelum sahur berakhir';

  @override
  String get alertSuhoorTitle => 'Pengingat sahur';

  @override
  String get alertTypeFullAzaan => 'Azan lengkap';

  @override
  String alertTypeGroupLabel(String prayer) {
    return 'Peringatan $prayer';
  }

  @override
  String get alertTypeOff => 'Mati';

  @override
  String get alertTypeShortTone => 'Nada pendek';

  @override
  String get alertTypeSilent => 'Notifikasi senyap';

  @override
  String get alertTypeVibrate => 'Getar';

  @override
  String get alertVariantFajr => 'Versi Subuh';

  @override
  String get alertVariantFajrHint =>
      'Memuat “as-salatu khairun minan-naum”. Diputar saat Subuh jika memilih Standar.';

  @override
  String get alertVariantShia => 'Lafaz Syiah';

  @override
  String get alertVariantShiaHint =>
      'Azan dengan lafaz Syiah. Diputar pada kelima salat jika dipilih.';

  @override
  String get alertVariantStandard => 'Standar';

  @override
  String get alertVariantStandardHint =>
      'Azan biasa. Subuh memakai rekaman Subuh.';

  @override
  String alertVoiceForPrayer(String prayer) {
    return 'Untuk $prayer';
  }

  @override
  String get alertVoiceIntro =>
      'Setiap suara memiliki tiga rekaman. Ketuk putar untuk mendengarkan sebelum memilih.';

  @override
  String alertVoiceName(int number) {
    return 'Suara $number';
  }

  @override
  String get alertVoiceSelected => 'Dipilih';

  @override
  String get alertVoiceTile => 'Suara';

  @override
  String alertVoiceTileValue(String voice, String variant) {
    return '$voice, $variant';
  }

  @override
  String get alertVoiceTitle => 'Pilih suara';

  @override
  String get alertVolumeKeep => 'Pertahankan volume saya saat ini';

  @override
  String get alertVolumeRamp => 'Naik perlahan';

  @override
  String get alertVolumeRampHint =>
      'Mulai pelan dan menjadi lebih keras dalam beberapa detik.';

  @override
  String get appTitle => 'Deen App';

  @override
  String get asrHanafiBody =>
      'Asar dimulai saat bayangan benda dua kali panjang bendanya, sehingga Asar dimulai lebih lambat (dipakai mazhab Hanafi).';

  @override
  String get asrHanafiTitle => 'Hanafi';

  @override
  String get asrStandardBody =>
      'Asar dimulai saat panjang bayangan benda sama dengan panjang bendanya (dipakai mazhab Syafi\'i, Maliki, dan Hanbali).';

  @override
  String get asrStandardTitle => 'Standar';

  @override
  String detailHijriAdjusted(String days) {
    return 'Termasuk penyesuaian Anda sebesar $days hari (kalender Umm al-Qura).';
  }

  @override
  String get detailHijriDefault => 'Kalender Umm al-Qura.';

  @override
  String get detailHijriTitle => 'Tanggal Hijriah';

  @override
  String get detailHijriUnavailable => 'Tanggal Hijriah belum tersedia.';

  @override
  String detailHijriValue(String day, String month, String year) {
    return '$day $month $year H';
  }

  @override
  String get detailImsak => 'Imsak';

  @override
  String get detailLastThird => 'Sepertiga malam terakhir';

  @override
  String get detailMidnight => 'Tengah malam';

  @override
  String get errorGeneric => 'Terjadi kesalahan. Silakan coba lagi.';

  @override
  String get highLatAngleBody =>
      'Subuh dan Isya memakai bagian malam yang sama dengan sudut senja dibagi 60.';

  @override
  String get highLatAngleTitle => 'Berdasarkan sudut';

  @override
  String highLatApplied(String rule) {
    return 'Subuh dan Isya diperkirakan dengan aturan “$rule” karena lintang Anda di atas 48 derajat, tempat senja bisa tidak berakhir. Anda dapat mengubah aturan di pengaturan salat.';
  }

  @override
  String get highLatMiddleBody =>
      'Malam dibagi dua: Isya paling lambat pada tengah malam dan Subuh paling awal pada tengah malam.';

  @override
  String get highLatMiddleTitle => 'Tengah malam';

  @override
  String get highLatSeventhBody =>
      'Malam dibagi tujuh bagian: Isya paling lama satu bagian setelah matahari terbenam dan Subuh satu bagian sebelum matahari terbit.';

  @override
  String get highLatSeventhTitle => 'Sepertujuh malam';

  @override
  String get hijriMonth1 => 'Muharam';

  @override
  String get hijriMonth10 => 'Syawal';

  @override
  String get hijriMonth11 => 'Zulkaidah';

  @override
  String get hijriMonth12 => 'Zulhijah';

  @override
  String get hijriMonth2 => 'Safar';

  @override
  String get hijriMonth3 => 'Rabiulawal';

  @override
  String get hijriMonth4 => 'Rabiulakhir';

  @override
  String get hijriMonth5 => 'Jumadilawal';

  @override
  String get hijriMonth6 => 'Jumadilakhir';

  @override
  String get hijriMonth7 => 'Rajab';

  @override
  String get hijriMonth8 => 'Syaban';

  @override
  String get hijriMonth9 => 'Ramadan';

  @override
  String get homeBackToToday => 'Kembali ke hari ini';

  @override
  String get homeBannerDismiss => 'Tutup';

  @override
  String get homeChooseLocation => 'Pilih lokasi';

  @override
  String get homeClockBeforeBuild =>
      'Tanggal ponsel Anda tampak salah: lebih awal dari versi aplikasi ini. Waktu salat dan peringatan mungkin salah. Silakan periksa Tanggal dan waktu di pengaturan ponsel Anda.';

  @override
  String get homeClockDrifted =>
      'Jam ponsel Anda diubah. Jika waktunya salah, waktu salat dan peringatan mungkin salah. Silakan periksa Tanggal dan waktu di pengaturan ponsel Anda.';

  @override
  String get homeClockMovedBack =>
      'Jam ponsel Anda diputar mundur. Jika waktunya salah, waktu salat dan peringatan mungkin salah. Silakan periksa Tanggal dan waktu di pengaturan ponsel Anda.';

  @override
  String homeCountdownSemantics(String prayer, int hours, int minutes) {
    return '$prayer dalam $hours jam $minutes menit';
  }

  @override
  String get homeError =>
      'Waktu salat tidak dapat dihitung. Periksa lokasi dan coba lagi.';

  @override
  String get homeMoreTimes => 'Waktu lainnya';

  @override
  String get homeNextBadge => 'Berikutnya';

  @override
  String get homeNextDay => 'Hari berikutnya';

  @override
  String get homeNoLocation => 'Pilih lokasi untuk melihat waktu salat.';

  @override
  String get homePreviousDay => 'Hari sebelumnya';

  @override
  String homeRegionSuggestion(String method) {
    return 'Wilayah ini biasanya memakai $method. Metode pilihan Anda tidak berubah.';
  }

  @override
  String homeRegionSuggestionGeneral(String method) {
    return 'Tidak ada metode bawaan untuk lokasi ini. $method adalah pilihan umum. Metode pilihan Anda tidak berubah.';
  }

  @override
  String homeRegionSuggestionSwitch(String method) {
    return 'Beralih ke $method';
  }

  @override
  String get homeTimeNotAvailable => 'Tidak terjadi hari ini';

  @override
  String homeTimeSemantics(String prayer, String time) {
    return '$prayer pukul $time';
  }

  @override
  String get homeTitle => 'Waktu salat';

  @override
  String get homeToday => 'Hari ini';

  @override
  String get homeTzRulesNotice =>
      'Aturan zona waktu mungkin telah berubah. Silakan perbarui aplikasi. Sementara itu, waktu mengikuti aturan ponsel Anda.';

  @override
  String get languageNameAr => 'العربية';

  @override
  String get languageNameEn => 'English';

  @override
  String get languageNameId => 'Bahasa Indonesia';

  @override
  String get languageNameUr => 'اردو';

  @override
  String get languageSettingsTitle => 'Bahasa';

  @override
  String get loading => 'Memuat';

  @override
  String locationSettingsCurrent(String name) {
    return 'Lokasi saat ini: $name';
  }

  @override
  String get locationSettingsNone => 'Belum ada lokasi yang tersimpan.';

  @override
  String get locationSettingsSaved =>
      'Lokasi disimpan. Peringatan akan diperbarui.';

  @override
  String get locationSettingsTitle => 'Lokasi';

  @override
  String get methodDiyanet => 'Turki (Diyanet)';

  @override
  String get methodEgypt => 'Otoritas Survei Umum Mesir';

  @override
  String get methodFranceUoif => 'Prancis (UOIF)';

  @override
  String get methodGulf => 'Kawasan Teluk';

  @override
  String get methodIsna => 'ISNA (Amerika Utara)';

  @override
  String get methodJafari => 'Syiah Itsna Asyariyah (Jakfari)';

  @override
  String get methodKarachi => 'Universitas Ilmu Islam, Karachi';

  @override
  String get methodKuwait => 'Kuwait';

  @override
  String get methodMoonsightingCommittee => 'Komite Rukyat Hilal';

  @override
  String get methodMuslimWorldLeague => 'Liga Dunia Muslim';

  @override
  String get methodQatar => 'Qatar';

  @override
  String get methodSingapore => 'Singapura (MUIS)';

  @override
  String get methodTehran => 'Institut Geofisika, Universitas Teheran';

  @override
  String get methodUmmAlQura => 'Umm al-Qura (Makkah)';

  @override
  String get nextPrayerLabel => 'Salat berikutnya';

  @override
  String get oemBrandHuawei => 'Huawei, Honor';

  @override
  String get oemBrandOneplus => 'OnePlus';

  @override
  String get oemBrandOppo => 'Oppo, realme';

  @override
  String get oemBrandOther => 'Merek lain';

  @override
  String get oemBrandSamsung => 'Samsung';

  @override
  String get oemBrandVivo => 'Vivo, iQOO';

  @override
  String get oemBrandXiaomi => 'Xiaomi, Redmi, POCO';

  @override
  String get permissionBannerAction => 'Perbaiki di pengaturan';

  @override
  String get permissionBannerAlerts =>
      'Notifikasi mati. Peringatan salat tidak akan muncul.';

  @override
  String get permissionBannerExact =>
      'Alarm tepat waktu mati. Peringatan bisa terlambat beberapa menit.';

  @override
  String get permissionBannerLocation =>
      'Lokasi mati. Waktu memakai kota yang tersimpan.';

  @override
  String get prayerAsr => 'Asar';

  @override
  String get prayerDhuhr => 'Zuhur';

  @override
  String get prayerFajr => 'Subuh';

  @override
  String get prayerIsha => 'Isya';

  @override
  String get prayerJumuah => 'Jumat';

  @override
  String get prayerMaghrib => 'Magrib';

  @override
  String get prayerSettingsHighLatIntro =>
      'Di atas lintang 48 derajat, senja bisa tidak berakhir saat musim panas. Pilih cara memperkirakan Subuh dan Isya pada saat itu.';

  @override
  String get prayerSettingsHighLatTitle => 'Lintang tinggi';

  @override
  String get prayerSettingsHijriLess => 'Mundurkan tanggal Hijriah satu hari';

  @override
  String get prayerSettingsHijriMore => 'Majukan tanggal Hijriah satu hari';

  @override
  String get prayerSettingsHijriTitle => 'Penyesuaian tanggal Hijriah (hari)';

  @override
  String prayerSettingsHijriValue(String value) {
    return '$value hari';
  }

  @override
  String get prayerSettingsNoLocation =>
      'Pilih lokasi lebih dulu. Pengaturan salat berlaku untuk lokasi Anda yang tersimpan.';

  @override
  String prayerSettingsOffsetLabel(String prayer) {
    return 'Penyesuaian $prayer';
  }

  @override
  String prayerSettingsOffsetLess(String prayer) {
    return 'Kurangi satu menit dari $prayer';
  }

  @override
  String prayerSettingsOffsetMore(String prayer) {
    return 'Tambah satu menit ke $prayer';
  }

  @override
  String prayerSettingsOffsetValue(String value) {
    return '$value mnt';
  }

  @override
  String get prayerSettingsOffsetsIntro =>
      'Tambah atau kurangi hingga 60 menit untuk salat mana pun. Berlaku di mana saja, termasuk peringatan.';

  @override
  String get prayerSettingsOffsetsTitle => 'Sesuaikan waktu';

  @override
  String get prayerSettingsTitle => 'Pengaturan salat';

  @override
  String get prayerSunrise => 'Terbit';

  @override
  String get qiblaAccuracyHigh => 'Tinggi';

  @override
  String qiblaAccuracyLabel(String level) {
    return 'Akurasi kompas: $level';
  }

  @override
  String get qiblaAccuracyLow => 'Rendah';

  @override
  String get qiblaAccuracyMedium => 'Sedang';

  @override
  String get qiblaAccuracyUnreliable => 'Tidak andal';

  @override
  String get qiblaArrowSemantics => 'Panah kompas';

  @override
  String get qiblaAtHaram =>
      'Anda berada di Masjidil Haram, Makkah. Menghadaplah langsung ke Ka\'bah.';

  @override
  String qiblaBearingFromPlace(String place, String description) {
    return 'Kiblat dari $place: $description';
  }

  @override
  String get qiblaCalibrationPrompt =>
      'Kalibrasi kompas. Gerakkan ponsel membentuk angka 8 beberapa kali, jauh dari logam dan magnet.';

  @override
  String get qiblaCompassError =>
      'Kompas tidak dapat dimulai. Arah ditampilkan dalam derajat.';

  @override
  String qiblaDirectionDescription(int degrees, String direction) {
    return '$degrees derajat, $direction';
  }

  @override
  String get qiblaDirectionEast => 'timur';

  @override
  String get qiblaDirectionNorth => 'utara';

  @override
  String get qiblaDirectionNortheast => 'timur laut';

  @override
  String get qiblaDirectionNorthwest => 'barat laut';

  @override
  String get qiblaDirectionSouth => 'selatan';

  @override
  String get qiblaDirectionSoutheast => 'tenggara';

  @override
  String get qiblaDirectionSouthwest => 'barat daya';

  @override
  String get qiblaDirectionWest => 'barat';

  @override
  String qiblaDistanceToKaaba(int km) {
    return '$km km ke Ka\'bah';
  }

  @override
  String get qiblaEntryHint => 'Temukan arah Ka\'bah';

  @override
  String get qiblaFacingQibla => 'Anda menghadap kiblat';

  @override
  String get qiblaInterferenceWarning =>
      'Ada gangguan magnet di dekat Anda. Menjauhlah dari logam, speaker, magnet, dan perangkat elektronik, lalu periksa lagi. Panah mungkin tidak tepat sampai saat itu.';

  @override
  String get qiblaMagneticNorthNote =>
      'Kompas memakai utara magnetis. Kesalahan kecil mungkin terjadi.';

  @override
  String get qiblaNoCompassInstructions =>
      'Gunakan arah di atas. Tentukan utara dengan peta, kompas, atau matahari (terbit di timur, terbenam di barat), lalu putar searah jarum jam dari utara sebesar derajat yang ditampilkan.';

  @override
  String get qiblaNoCompassTitle => 'Perangkat ini tidak memiliki kompas';

  @override
  String get qiblaNoLocation =>
      'Atur lokasi Anda dulu agar arah kiblat dapat dihitung.';

  @override
  String get qiblaNorthReference => 'Diukur searah jarum jam dari utara sejati';

  @override
  String get qiblaStartingCompass => 'Memulai kompas';

  @override
  String get qiblaTitle => 'Kiblat';

  @override
  String get qiblaTurnHint => 'Putar badan sampai panah menunjuk lurus ke atas';

  @override
  String qiblaTurnLeft(int degrees) {
    return 'Putar $degrees derajat ke kiri';
  }

  @override
  String qiblaTurnRight(int degrees) {
    return 'Putar $degrees derajat ke kanan';
  }

  @override
  String get reliabilityAllGood => 'Semuanya tampak baik.';

  @override
  String get reliabilityBattery => 'Optimalisasi baterai (Android)';

  @override
  String get reliabilityBatteryFix =>
      'Di beberapa ponsel, penghemat baterai dapat menghentikan peringatan. Buka pengaturan baterai dan biarkan Deen App berjalan di latar belakang.';

  @override
  String get reliabilityBatteryOk => 'Deen App tidak dibatasi.';

  @override
  String get reliabilityBatteryOpen => 'Buka pengaturan baterai';

  @override
  String get reliabilityCheckHint => 'Pastikan peringatan Anda akan berbunyi';

  @override
  String get reliabilityCheckTitle => 'Pemeriksaan keandalan';

  @override
  String get reliabilityErrorBudget =>
      'Jumlah peringatan melebihi kapasitas ponsel ini, jadi yang terakhir dilewatkan sampai Anda membuka aplikasi lagi.';

  @override
  String get reliabilityErrorExactDenied =>
      'Alarm tepat waktu tidak diizinkan, jadi ketepatan waktu bisa berkurang.';

  @override
  String get reliabilityErrorInvalid =>
      'Ponsel tidak dapat menerima peringatan ini.';

  @override
  String get reliabilityErrorPermissionDenied => 'Notifikasi tidak diizinkan.';

  @override
  String get reliabilityErrorPlatform => 'Sistem peringatan tidak merespons.';

  @override
  String get reliabilityErrorServiceBlocked =>
      'Android memblokir pemutaran azan. Nada notifikasi digunakan sebagai gantinya.';

  @override
  String get reliabilityExact => 'Alarm tepat waktu (Android)';

  @override
  String get reliabilityExactFix =>
      'Alarm tepat waktu mati, jadi peringatan bisa terlambat beberapa menit. Izinkan “Alarm & pengingat” untuk Deen App.';

  @override
  String get reliabilityExactOpen => 'Buka pengaturan alarm';

  @override
  String get reliabilityFlagInexact => 'Waktu bisa terlambat beberapa menit';

  @override
  String get reliabilityFlagSilenced => 'Dibisukan oleh jam tenang';

  @override
  String get reliabilityIntro =>
      'Layar ini menunjukkan apakah peringatan Anda akan berbunyi dan cara memperbaiki hal yang bisa menghentikannya.';

  @override
  String get reliabilityIosRefreshNote =>
      'Di iPhone, peringatan diperbarui setiap kali Anda membuka aplikasi. Buka setiap beberapa hari agar tetap berjalan.';

  @override
  String get reliabilityKindRenewal => 'Pemberitahuan pembaruan';

  @override
  String reliabilityLastLine(String when, String result) {
    return '$when: $result';
  }

  @override
  String get reliabilityLastNone => 'Belum ada peringatan yang berbunyi.';

  @override
  String get reliabilityLastTitle => 'Hasil peringatan terakhir';

  @override
  String get reliabilityLoadFailed =>
      'Pemeriksaan tidak dapat diselesaikan. Silakan coba lagi.';

  @override
  String get reliabilityNextNone => 'Tidak ada yang terjadwal.';

  @override
  String reliabilityNextRow(String title, String type, String when) {
    return '$title, $type, $when';
  }

  @override
  String get reliabilityNextTitle => '5 peringatan berikutnya';

  @override
  String get reliabilityNotifications => 'Notifikasi';

  @override
  String get reliabilityNotificationsAllow => 'Izinkan notifikasi';

  @override
  String get reliabilityNotificationsFix =>
      'Notifikasi mati, jadi peringatan tidak dapat muncul. Izinkan notifikasi untuk Deen App.';

  @override
  String get reliabilityNotificationsSettings => 'Buka pengaturan notifikasi';

  @override
  String get reliabilityPermissionsTitle => 'Izin';

  @override
  String get reliabilityProblemsFound => 'Ada hal yang perlu diperhatikan.';

  @override
  String reliabilityRebuildFailed(String reason) {
    return 'Peringatan Anda tidak dapat diperbarui. $reason';
  }

  @override
  String get reliabilityRefresh => 'Periksa lagi';

  @override
  String reliabilityRegistered(int count) {
    return '$count peringatan terdaftar di ponsel.';
  }

  @override
  String get reliabilityResultAcknowledged => 'Dihentikan oleh Anda';

  @override
  String get reliabilityResultFailed => 'Gagal';

  @override
  String get reliabilityResultFired => 'Terkirim';

  @override
  String get reliabilityResultMissed => 'Terlewat';

  @override
  String get reliabilityResultPlanned => 'Menunggu';

  @override
  String get reliabilityResultPlayed => 'Azan diputar';

  @override
  String get reliabilityResultPossiblyMissed => 'Mungkin terlewat';

  @override
  String get reliabilityResultSuppressed => 'Dibisukan';

  @override
  String get reliabilityRunsUntilHint =>
      'Buka aplikasi sebelum tanggal ini agar peringatan terus berjalan. Setiap kali dibuka, jadwal diperbarui.';

  @override
  String get reliabilityRunsUntilNone => 'Belum ada peringatan terjadwal.';

  @override
  String get reliabilityRunsUntilTitle => 'Peringatan berjalan sampai';

  @override
  String get reliabilitySilentSwitchTip =>
      'Jika tombol senyap iPhone aktif, suara notifikasi dibisukan. Mengetuk notifikasi memutar azan lengkap.';

  @override
  String get reliabilitySound => 'Suara notifikasi (iPhone)';

  @override
  String get reliabilitySoundFix =>
      'Suara mati di pengaturan notifikasi, jadi peringatan akan senyap. Izinkan suara untuk Deen App.';

  @override
  String get reliabilityStateOff => 'Mati';

  @override
  String get reliabilityStateOn => 'Aktif';

  @override
  String get reliabilityTestButton => 'Kirim azan uji dalam 1 menit';

  @override
  String reliabilityTestFailed(String reason) {
    return 'Uji tidak dapat dijadwalkan. $reason';
  }

  @override
  String get reliabilityTestNeedsNotifications =>
      'Izinkan notifikasi terlebih dahulu, lalu coba lagi.';

  @override
  String reliabilityTestScheduled(String time) {
    return 'Azan uji dijadwalkan pukul $time. Kunci ponsel Anda dan tunggu.';
  }

  @override
  String get reliabilityUnsupported =>
      'Perangkat ini tidak dapat menjadwalkan peringatan, jadi tidak ada yang perlu diperiksa.';

  @override
  String get settingsAppearanceHint => 'Tema, ukuran teks, dan kontras';

  @override
  String get settingsAppearanceNeedsSetup =>
      'Selesaikan pengaturan awal dahulu. Tampilan dapat diubah setelah pengaturan salat tersimpan.';

  @override
  String get settingsAppearanceTitle => 'Tampilan';

  @override
  String get settingsDataHint => 'Ekspor, impor, atau hapus';

  @override
  String get settingsDataTitle => 'Data Anda';

  @override
  String get settingsDeleteBody =>
      'Menghapus pengaturan, lokasi, hitungan tasbih, markah, dan riwayat peringatan dari perangkat ini, serta membatalkan semua peringatan terjadwal.';

  @override
  String get settingsDeleteCancel => 'Batal';

  @override
  String get settingsDeleteConfirmAction => 'Hapus semuanya';

  @override
  String get settingsDeleteConfirmBody =>
      'Ini menghapus semua yang disimpan aplikasi di perangkat ini dan tidak dapat dibatalkan. Berkas pengaturan yang Anda simpan atau bagikan di luar aplikasi tidak ikut terhapus dan tetap di tempatnya.';

  @override
  String get settingsDeleteConfirmTitle => 'Hapus semua data?';

  @override
  String get settingsDeleteDone => 'Semua data telah dihapus.';

  @override
  String get settingsDeletePartial =>
      'Sebagian data tidak dapat dihapus. Silakan coba lagi.';

  @override
  String get settingsDeleteTitle => 'Hapus semua data saya';

  @override
  String get settingsExportCancelled => 'Ekspor dibatalkan.';

  @override
  String get settingsExportDone => 'Berkas pengaturan siap.';

  @override
  String get settingsExportFailed => 'Berkas pengaturan tidak dapat dibuat.';

  @override
  String get settingsExportSave => 'Simpan berkas pengaturan';

  @override
  String get settingsExportShare => 'Bagikan berkas pengaturan';

  @override
  String get settingsExportTitle => 'Ekspor pengaturan';

  @override
  String get settingsExportWarning =>
      'Berkas ini berisi lokasi tersimpan dan pengaturan Anda. Siapa pun yang memperolehnya dapat melihat di mana Anda berada. Bagikan hanya kepada orang dan tempat yang Anda percaya.';

  @override
  String get settingsHighContrast => 'Kontras tinggi';

  @override
  String get settingsHighContrastHint =>
      'Warna teks dan garis tepi lebih kuat. Tidak ada informasi di aplikasi yang hanya bergantung pada warna.';

  @override
  String get settingsImportBody =>
      'Pilih berkas pengaturan yang diekspor dari aplikasi ini. Pengaturan di dalamnya akan menggantikan yang ada. Jika berkas bermasalah, tidak ada yang berubah.';

  @override
  String get settingsImportButton => 'Pilih berkas pengaturan';

  @override
  String get settingsImportDone => 'Pengaturan berhasil diimpor.';

  @override
  String get settingsImportDoneLater =>
      'Pengaturan berhasil diimpor. Peringatan akan diperbarui saat aplikasi dibuka berikutnya.';

  @override
  String get settingsImportFailed =>
      'Pengaturan tidak dapat disimpan. Tidak ada yang diubah.';

  @override
  String settingsImportInvalid(String field) {
    return 'Berkas memiliki nilai yang hilang atau di luar rentang ($field). Tidak ada yang diubah.';
  }

  @override
  String get settingsImportNewer =>
      'Berkas ini dibuat oleh versi aplikasi yang lebih baru. Perbarui aplikasi untuk membukanya.';

  @override
  String get settingsImportNotSettings =>
      'Ini bukan berkas pengaturan Deen App.';

  @override
  String get settingsImportTitle => 'Impor pengaturan';

  @override
  String get settingsImportUnreadable => 'Berkas tidak dapat dibaca.';

  @override
  String get settingsSaveError => 'Perubahan ini tidak dapat disimpan.';

  @override
  String get settingsTextSizeLabel => 'Ukuran teks';

  @override
  String get settingsTextSizeLarger => 'Teks lebih besar';

  @override
  String get settingsTextSizeSample =>
      'Teks contoh: beginilah tampilan teks pada ukuran ini.';

  @override
  String get settingsTextSizeSmaller => 'Teks lebih kecil';

  @override
  String settingsTextSizeValue(int percent) {
    return '$percent%';
  }

  @override
  String get settingsThemeDark => 'Gelap';

  @override
  String get settingsThemeLabel => 'Tema';

  @override
  String get settingsThemeLight => 'Terang';

  @override
  String get settingsThemeSystem => 'Ikuti perangkat';

  @override
  String get settingsTitle => 'Pengaturan';

  @override
  String get setupAsrIntro =>
      'Pilih mazhab yang Anda ikuti untuk awal waktu Asar. Standar sudah dipilih.';

  @override
  String get setupAsrTitle => 'Salat Asar';

  @override
  String get setupBack => 'Kembali';

  @override
  String get setupBatteryBody =>
      'Beberapa ponsel menutup aplikasi di latar belakang untuk menghemat baterai, sehingga peringatan bisa tertunda atau berhenti. Pilih merek ponsel Anda dan ikuti langkahnya.';

  @override
  String get setupBatteryBrandLabel => 'Merek ponsel Anda';

  @override
  String get setupBatteryGuideUnavailable =>
      'Langkah untuk merek ini tidak dapat dimuat. Buka pengaturan baterai dan izinkan Deen App berjalan di latar belakang.';

  @override
  String get setupBatteryOpenSettings => 'Buka pengaturan baterai';

  @override
  String setupBatteryStep(int number, String text) {
    return 'Langkah $number: $text';
  }

  @override
  String get setupBatteryTitle => 'Jaga peringatan tetap andal';

  @override
  String get setupExactBody =>
      'Android dapat membunyikan peringatan tepat pada waktu salat hanya jika Anda mengizinkan alarm tepat waktu. Tanpa itu, peringatan tetap datang tetapi bisa terlambat beberapa menit.';

  @override
  String get setupExactCheck => 'Sudah saya ubah, periksa lagi';

  @override
  String get setupExactContinue => 'Lanjut tanpa itu';

  @override
  String get setupExactDenied =>
      'Alarm tepat waktu mati. Peringatan tetap datang tetapi bisa terlambat beberapa menit. Pemeriksaan keandalan menunjukkan hal ini.';

  @override
  String get setupExactGranted => 'Alarm tepat waktu diizinkan.';

  @override
  String get setupExactOpen => 'Buka pengaturan alarm';

  @override
  String get setupExactTitle => 'Ketepatan waktu peringatan';

  @override
  String get setupFinish => 'Selesaikan pengaturan';

  @override
  String get setupLanguageBody =>
      'Anda dapat mengubahnya kapan saja di pengaturan.';

  @override
  String get setupLanguageTitle => 'Pilih bahasa Anda';

  @override
  String get setupLocationApproximate => 'Gunakan lokasi perkiraan saya';

  @override
  String get setupLocationApproximateHint =>
      'Perkiraan membulatkan posisi Anda hingga sekitar 10 km. Waktu salat berubah jauh kurang dari satu menit.';

  @override
  String get setupLocationApproximateName => 'Lokasi perkiraan';

  @override
  String get setupLocationCurrentName => 'Lokasi saat ini';

  @override
  String get setupLocationFinding => 'Mencari lokasi Anda…';

  @override
  String get setupLocationNeeded => 'Pilih lokasi atau kota untuk melanjutkan.';

  @override
  String get setupLocationOfflineNote =>
      'Daftar kota tersimpan di aplikasi, jadi pencarian bekerja tanpa internet. Anda bisa melewati berbagi lokasi dan cukup memilih kota.';

  @override
  String get setupLocationPrecise => 'Gunakan lokasi tepat saya';

  @override
  String get setupLocationPrivacy =>
      'Lokasi Anda tetap berada di perangkat ini. Lokasi tidak pernah dikirim ke mana pun dan hanya dipakai untuk menghitung waktu salat.';

  @override
  String get setupLocationSearchEmpty =>
      'Kota tidak ditemukan. Periksa ejaan atau coba nama lain.';

  @override
  String get setupLocationSearchHint => 'Nama kota';

  @override
  String get setupLocationSearchLabel => 'Atau cari kota';

  @override
  String setupLocationSelected(String name) {
    return 'Dipilih: $name';
  }

  @override
  String get setupLocationTitle => 'Lokasi Anda';

  @override
  String get setupMethodChange => 'Anda dapat memilih metode lain:';

  @override
  String get setupMethodGeneral =>
      'Tidak ada metode bawaan untuk lokasi Anda, jadi metode umum Liga Dunia Muslim disarankan.';

  @override
  String setupMethodSuggested(String method) {
    return 'Disarankan untuk wilayah Anda: $method';
  }

  @override
  String get setupMethodTitle => 'Metode perhitungan';

  @override
  String get setupNext => 'Berikutnya';

  @override
  String get setupNotNow => 'Nanti saja';

  @override
  String get setupNotificationsAllow => 'Izinkan notifikasi';

  @override
  String get setupNotificationsBody =>
      'Untuk mengingatkan Anda pada waktu salat, Deen App memerlukan izin menampilkan notifikasi. Peringatan dibuat di ponsel Anda; tidak ada yang dikirim lewat internet.';

  @override
  String get setupNotificationsDenied =>
      'Notifikasi mati, sehingga peringatan salat tidak akan muncul. Anda dapat mengizinkannya nanti di pengaturan aplikasi.';

  @override
  String get setupNotificationsGranted => 'Notifikasi diizinkan.';

  @override
  String get setupNotificationsTitle => 'Peringatan salat';

  @override
  String get setupOpenAppSettings => 'Buka pengaturan aplikasi';

  @override
  String get setupPrivacyNoData =>
      'Deen App tidak mengumpulkan data pribadi apa pun.';

  @override
  String get setupPrivacyNoTracking =>
      'Tidak ada akun, iklan, atau pelacak, dan aplikasi bekerja tanpa koneksi internet.';

  @override
  String get setupPrivacyOnDevice =>
      'Lokasi, pengaturan, dan riwayat peringatan Anda tetap di ponsel ini.';

  @override
  String get setupPrivacyTitle => 'Privasi Anda';

  @override
  String get setupProblemLocationDenied =>
      'Lokasi tidak diizinkan. Pilih kota dari daftar, atau izinkan lokasi di pengaturan aplikasi.';

  @override
  String get setupProblemLocationTimeout =>
      'Lokasi Anda tidak dapat ditemukan tepat waktu. Coba lagi, atau pilih kota dari daftar.';

  @override
  String get setupProblemLocationUnavailable =>
      'Lokasi tidak tersedia di ponsel ini saat ini. Pilih kota dari daftar.';

  @override
  String get setupProblemSaveFailed =>
      'Pilihan Anda tidak dapat disimpan. Silakan coba lagi.';

  @override
  String get setupProblemZoneUnknown =>
      'Ponsel Anda tidak melaporkan zona waktu. Pilih kota dari daftar.';

  @override
  String setupProgress(int current, int total) {
    return 'Langkah $current dari $total';
  }

  @override
  String get setupSummaryAlerts =>
      'Peringatan salat tidak akan muncul karena notifikasi mati.';

  @override
  String get setupSummaryExact =>
      'Peringatan bisa terlambat beberapa menit karena alarm tepat waktu mati.';

  @override
  String get setupSummaryLocation =>
      'Lokasi ponsel Anda mati, jadi waktu memakai kota yang Anda pilih.';

  @override
  String get setupSummaryTitle => 'Yang belum akan berfungsi';

  @override
  String get setupSummaryWayBack =>
      'Anda dapat mengizinkan semuanya nanti di pengaturan aplikasi.';

  @override
  String get setupTitle => 'Siapkan Deen App';

  @override
  String get tasbihCancel => 'Batal';

  @override
  String get tasbihCountHint => 'Menambah satu hitungan';

  @override
  String tasbihCountLabel(int count, int target) {
    return 'Hitungan: $count dari $target';
  }

  @override
  String get tasbihEntryHint => 'Hitung zikir Anda';

  @override
  String get tasbihHaptics => 'Getar pada setiap hitungan';

  @override
  String get tasbihHistoryEmpty =>
      'Belum ada hitungan. Total harian Anda muncul di sini.';

  @override
  String get tasbihHistoryTitle => 'Riwayat';

  @override
  String get tasbihKeepAwake => 'Biarkan layar menyala';

  @override
  String get tasbihLock => 'Kunci sentuhan pada penghitung';

  @override
  String get tasbihLockHint =>
      'Sentuhan tidak sengaja tidak menambah hitungan. Tombol volume tetap menghitung.';

  @override
  String get tasbihLockedMessage =>
      'Terkunci. Sentuhan pada penghitung diabaikan.';

  @override
  String tasbihOfTarget(int target) {
    return 'dari $target';
  }

  @override
  String get tasbihOptionsTitle => 'Opsi';

  @override
  String get tasbihReset => 'Atur ulang';

  @override
  String get tasbihResetBody =>
      'Hitungan kembali ke 0. Total harian Anda tetap tersimpan.';

  @override
  String get tasbihResetTitle => 'Atur ulang penghitung?';

  @override
  String tasbihRounds(int rounds) {
    return 'Putaran selesai: $rounds';
  }

  @override
  String get tasbihSave => 'Simpan';

  @override
  String get tasbihSaveError => 'Hitungan tidak dapat disimpan. Coba lagi.';

  @override
  String get tasbihSound => 'Suara ketukan';

  @override
  String get tasbihTargetCustom => 'Kustom';

  @override
  String get tasbihTargetCustomField => 'Target (1 sampai 100000)';

  @override
  String tasbihTargetCustomLabel(int target) {
    return 'Target kustom: $target';
  }

  @override
  String get tasbihTargetCustomTitle => 'Target kustom';

  @override
  String get tasbihTargetHeading => 'Target';

  @override
  String get tasbihTargetInvalid =>
      'Masukkan bilangan bulat dari 1 sampai 100000.';

  @override
  String tasbihTargetOptionLabel(int target) {
    return 'Target $target';
  }

  @override
  String tasbihTargetReached(int target) {
    return 'Target $target tercapai';
  }

  @override
  String get tasbihTitle => 'Tasbih';

  @override
  String tasbihTodayTotal(int total) {
    return 'Hari ini: $total';
  }

  @override
  String get tasbihUnlock => 'Tahan untuk membuka kunci';

  @override
  String get tasbihUnlockPressHint =>
      'Tekan dan tahan tombol untuk membuka kunci.';

  @override
  String get tasbihVolumeKeys => 'Hitung dengan tombol volume';

  @override
  String get tasbihVolumeKeysHint =>
      'Saat layar ini terbuka, tombol volume menghitung dan tidak mengubah volume.';
}
