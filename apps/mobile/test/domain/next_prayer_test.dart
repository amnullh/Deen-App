import 'package:deen_mobile/domain/entities/enums.dart';
import 'package:deen_mobile/domain/entities/settings.dart';
import 'package:deen_mobile/domain/prayer/day_times_usecase.dart';
import 'package:deen_mobile/domain/prayer/next_prayer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prayer_engine/prayer_engine.dart';

/// Mecca, UTC+3 all year, so local midnight is 21:00 UTC the day before.
final _location = AppLocation(
  source: LocationSource.city,
  latitude: 21.4225,
  longitude: 39.8262,
  displayName: 'Mecca',
  timeZoneId: 'Asia/Riyadh',
  countryCode: 'SA',
  updatedAt: DateTime.utc(2026, 10, 21),
);

const _settings = PrayerSettings(
  method: CalculationMethod.ummAlQura,
  asrMethod: AsrMethod.standard,
  highLatitudeRule: HighLatitudeRule.middleOfNight,
  language: AppLanguage.en,
);

DayTimesUseCase _useCase() => DayTimesUseCase(
  engine: AdhanDartEngine(),
  offsets: const FixedOffsetResolver(Duration(hours: 3)),
);

/// A local wall-clock time in Mecca as a UTC instant.
DateTime _local(int y, int m, int d, int h, [int min = 0]) =>
    DateTime.utc(y, m, d, h, min).subtract(const Duration(hours: 3));

void main() {
  group('localDateOf and shiftDate', () {
    test('uses the location zone, not UTC', () {
      final useCase = _useCase();
      // 22:30 UTC on the 21st is already 01:30 on the 22nd in Mecca.
      expect(
        useCase.localDateOf(DateTime.utc(2026, 10, 21, 22, 30), 'Asia/Riyadh'),
        '2026-10-22',
      );
      expect(
        useCase.localDateOf(DateTime.utc(2026, 10, 21, 20, 59), 'Asia/Riyadh'),
        '2026-10-21',
      );
    });

    test('shifts across month and year ends', () {
      final useCase = _useCase();
      expect(useCase.shiftDate('2026-10-31', 1), '2026-11-01');
      expect(useCase.shiftDate('2026-01-01', -1), '2025-12-31');
      expect(useCase.shiftDate('2026-03-01', -1), '2026-02-28');
    });
  });

  group('nextPrayer', () {
    test('before Fajr the next prayer is today\'s Fajr', () {
      final useCase = _useCase();
      final now = _local(2026, 10, 21, 2);
      final next = useCase.nextPrayer(
        location: _location,
        settings: _settings,
        now: now,
      );
      final today = useCase.scheduleFor(
        location: _location,
        settings: _settings,
        localDate: '2026-10-21',
      );
      expect(next!.prayer, Prayer.fajr);
      expect(next.time, today.timeOf(Prayer.fajr));
      expect(next.remaining(now), next.time.difference(now));
    });

    test('between prayers it picks the following one', () {
      final useCase = _useCase();
      final today = useCase.scheduleFor(
        location: _location,
        settings: _settings,
        localDate: '2026-10-21',
      );
      final justAfterDhuhr = today
          .timeOf(Prayer.dhuhr)!
          .add(const Duration(minutes: 1));
      final next = useCase.nextPrayer(
        location: _location,
        settings: _settings,
        now: justAfterDhuhr,
      );
      expect(next!.prayer, Prayer.asr);
    });

    test('sunrise is not offered as the next prayer', () {
      final useCase = _useCase();
      final today = useCase.scheduleFor(
        location: _location,
        settings: _settings,
        localDate: '2026-10-21',
      );
      final justAfterFajr = today
          .timeOf(Prayer.fajr)!
          .add(const Duration(minutes: 1));
      final next = useCase.nextPrayer(
        location: _location,
        settings: _settings,
        now: justAfterFajr,
      );
      expect(next!.prayer, Prayer.dhuhr);
    });

    test('after Isha the next prayer is tomorrow\'s Fajr', () {
      final useCase = _useCase();
      final now = _local(2026, 10, 21, 23, 30);
      final next = useCase.nextPrayer(
        location: _location,
        settings: _settings,
        now: now,
      );
      final tomorrow = useCase.scheduleFor(
        location: _location,
        settings: _settings,
        localDate: '2026-10-22',
      );
      expect(next!.prayer, Prayer.fajr);
      expect(next.time, tomorrow.timeOf(Prayer.fajr));
    });

    test('just after local midnight the next prayer is that day\'s Fajr', () {
      final useCase = _useCase();
      final now = _local(2026, 10, 22, 0, 1);
      final next = useCase.nextPrayer(
        location: _location,
        settings: _settings,
        now: now,
      );
      final sameDay = useCase.scheduleFor(
        location: _location,
        settings: _settings,
        localDate: '2026-10-22',
      );
      expect(next!.time, sameDay.timeOf(Prayer.fajr));
    });

    test('at the exact prayer instant the prayer has begun', () {
      final useCase = _useCase();
      final today = useCase.scheduleFor(
        location: _location,
        settings: _settings,
        localDate: '2026-10-21',
      );
      final next = useCase.nextPrayer(
        location: _location,
        settings: _settings,
        now: today.timeOf(Prayer.dhuhr)!,
      );
      expect(next!.prayer, Prayer.asr);
    });
  });

  test('the same prayer at the same time is equal', () {
    final a = NextPrayer(
      prayer: Prayer.asr,
      time: DateTime.utc(2026, 1, 1, 12),
    );
    final b = NextPrayer(
      prayer: Prayer.asr,
      time: DateTime.utc(2026, 1, 1, 12),
    );
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(
      a,
      isNot(
        NextPrayer(prayer: Prayer.isha, time: DateTime.utc(2026, 1, 1, 12)),
      ),
    );
  });

  group('findNextPrayer with missing events', () {
    test('skips prayers that do not occur and reaches the next day', () {
      final now = DateTime.utc(2026, 6, 21, 12);
      final today = DayTimes(
        localDate: '2026-06-21',
        times: {
          Prayer.fajr: null,
          Prayer.sunrise: null,
          Prayer.dhuhr: DateTime.utc(2026, 6, 21, 11),
          Prayer.asr: null,
          Prayer.maghrib: null,
          Prayer.isha: null,
        },
      );
      final tomorrow = DayTimes(
        localDate: '2026-06-22',
        times: {
          Prayer.fajr: null,
          Prayer.sunrise: null,
          Prayer.dhuhr: DateTime.utc(2026, 6, 22, 11),
          Prayer.asr: null,
          Prayer.maghrib: null,
          Prayer.isha: null,
        },
      );
      final next = findNextPrayer(today: today, tomorrow: tomorrow, now: now);
      expect(next!.prayer, Prayer.dhuhr);
      expect(next.time, DateTime.utc(2026, 6, 22, 11));
    });

    test('returns null when nothing is left', () {
      const empty = DayTimes(localDate: '2026-06-21', times: {});
      expect(
        findNextPrayer(today: empty, tomorrow: empty, now: DateTime.utc(2026)),
        isNull,
      );
    });
  });

  group('Jumu\'ah', () {
    test('Dhuhr is the Friday prayer on Fridays by the local date', () {
      final useCase = _useCase();
      // 2026-10-23 is a Friday.
      final friday = useCase.scheduleFor(
        location: _location,
        settings: _settings,
        localDate: '2026-10-23',
      );
      final thursday = useCase.scheduleFor(
        location: _location,
        settings: _settings,
        localDate: '2026-10-22',
      );
      expect(friday.isFriday, isTrue);
      expect(
        friday.entries.firstWhere((e) => e.prayer == Prayer.dhuhr).isJumuah,
        isTrue,
      );
      expect(thursday.isFriday, isFalse);
      expect(thursday.entries.any((e) => e.isJumuah), isFalse);
    });

    test('six entries are produced in display order', () {
      final schedule = _useCase().scheduleFor(
        location: _location,
        settings: _settings,
        localDate: '2026-10-21',
      );
      expect(schedule.entries.map((e) => e.prayer).toList(), Prayer.values);
    });
  });

  test('offsets shift the displayed time', () {
    final useCase = _useCase();
    final plain = useCase.scheduleFor(
      location: _location,
      settings: _settings,
      localDate: '2026-10-21',
    );
    final shifted = useCase.scheduleFor(
      location: _location,
      settings: _settings.copyWith(offsetsMinutes: {Prayer.asr: 7}),
      localDate: '2026-10-21',
    );
    expect(
      shifted.timeOf(Prayer.asr)!.difference(plain.timeOf(Prayer.asr)!),
      const Duration(minutes: 7),
    );
  });
}
