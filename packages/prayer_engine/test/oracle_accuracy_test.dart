// Spec SC-003: for 20 reference cities, every calculation method and both Asr
// schools, across a full year, engine times are within 1 minute of an
// independent calculation. Times are compared as whole minutes, because the
// engine returns times rounded to the nearest minute.
import 'package:fixtures_gen/fixtures_gen.dart';
import 'package:prayer_engine/prayer_engine.dart';
import 'package:test/test.dart';

const int _year = 2026;
const int _toleranceMinutes = 1;

/// Known gaps that are tracked, not hidden. Each entry is explained in
/// specs/001-offline-worship-app/spike-results-engine.md (spike S9). It is
/// empty: after the corrections described there every comparison is within
/// tolerance. An entry has the form `<method>:<city>/<asr>/<prayer>`.
const Set<String> _knownGaps = <String>{};

String _localDate(int month, int day) =>
    '$_year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

OracleHighLatitude _oracleRule(HighLatitudeRule rule) {
  switch (rule) {
    case HighLatitudeRule.middleOfNight:
      return OracleHighLatitude.middleOfNight;
    case HighLatitudeRule.seventhOfNight:
      return OracleHighLatitude.seventhOfNight;
    case HighLatitudeRule.angleBased:
      return OracleHighLatitude.angleBased;
  }
}

class _Stat {
  int checked = 0;
  int mismatches = 0;
  int worst = 0;
  String example = '';
}

void main() {
  final offsets = BundledOffsetResolver();
  final engine = AdhanDartEngine(offsetResolver: offsets);

  group('engine vs independent oracle, $_year', () {
    for (final oracleMethod in OracleMethod.values) {
      final method = CalculationMethod.values.byName(oracleMethod.name);
      test('${method.name}: all cities, both Asr schools, 365 days', () {
        final stats = <String, _Stat>{};
        final failures = <String>[];

        for (final city in referenceCities) {
          final rule = defaultHighLatitudeRule(city.latitude);
          for (final asr in AsrMethod.values) {
            final date = DateTime.utc(_year, 1, 1);
            for (var i = 0; i < 365; i++) {
              final day = date.add(Duration(days: i));
              final oracle = calculateCivilDay(
                latitude: city.latitude,
                longitude: city.longitude,
                year: day.year,
                month: day.month,
                day: day.day,
                method: oracleMethod,
                asrShadowFactor: asr == AsrMethod.hanafi ? 2 : 1,
                highLatitude: _oracleRule(rule),
                offsetAt: (instant) =>
                    offsets.offsetAt(city.timeZoneId, instant),
                isRamadan: isRamadan(_localDate(day.month, day.day)),
              );
              final result = engine.timesFor(
                latitude: city.latitude,
                longitude: city.longitude,
                timeZoneId: city.timeZoneId,
                localDate: _localDate(day.month, day.day),
                method: method,
                asr: asr,
                highLatitudeRule: rule,
                offsetsMinutes: const {},
                imsakMinutes: 10,
              );

              final expected = <Prayer, DateTime?>{
                Prayer.fajr: oracle.fajr,
                Prayer.sunrise: oracle.sunrise,
                Prayer.dhuhr: oracle.dhuhr,
                Prayer.asr: oracle.asr,
                Prayer.maghrib: oracle.maghrib,
                Prayer.isha: oracle.isha,
              };
              for (final prayer in Prayer.values) {
                final want = expected[prayer];
                final got = result.times[prayer];
                final key = '${city.name}/${asr.name}/${prayer.name}';
                final stat = stats.putIfAbsent(key, _Stat.new);
                if (want == null || got == null) {
                  // Both must agree that the event does not occur.
                  if ((want == null) != (got == null)) {
                    stat.checked++;
                    stat.mismatches++;
                    failures.add(
                      '$key ${_localDate(day.month, day.day)}: '
                      'oracle=${want?.toIso8601String()} engine=${got?.toIso8601String()}',
                    );
                  }
                  continue;
                }
                final diff = toWholeMinute(
                  want,
                  roundsUp: methodDefinitions[oracleMethod]!.roundsUp,
                ).difference(got).inMinutes.abs();
                stat.checked++;
                if (diff > stat.worst) stat.worst = diff;
                if (diff > _toleranceMinutes) {
                  stat.mismatches++;
                  if (stat.example.isEmpty) {
                    stat.example =
                        '${_localDate(day.month, day.day)} off by $diff min';
                  }
                  failures.add(
                    '$key ${_localDate(day.month, day.day)}: off by $diff min',
                  );
                }
              }
            }
          }
        }

        final unexpected = failures.where((f) {
          return !_knownGaps.any((gap) => f.startsWith('${method.name}:$gap'));
        }).toList();
        final worst = stats.values.fold<int>(
          0,
          (m, s) => s.worst > m ? s.worst : m,
        );
        expect(
          unexpected,
          isEmpty,
          reason:
              '${unexpected.length} of ${stats.values.fold<int>(0, (a, s) => a + s.checked)} '
              'comparisons exceed $_toleranceMinutes min (worst $worst min). '
              'First: ${unexpected.take(12).join('; ')}',
        );
      }, timeout: const Timeout(Duration(minutes: 5)));
    }
  });
}
