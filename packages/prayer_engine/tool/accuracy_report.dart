// ignore_for_file: avoid_print
// Prints a per-method, per-prayer, per-city summary of engine-vs-oracle
// disagreements for 2026. Used to write spike S9 results.
//   dart run tool/accuracy_report.dart [method] [city]
import 'package:fixtures_gen/fixtures_gen.dart';
import 'package:prayer_engine/prayer_engine.dart';

void main(List<String> args) {
  final offsets = BundledOffsetResolver();
  final engine = AdhanDartEngine(offsetResolver: offsets);
  for (final om in OracleMethod.values) {
    if (args.isNotEmpty && args[0] != om.name) continue;
    final method = CalculationMethod.values.byName(om.name);
    final summary = <String, List<int>>{}; // key -> [checked, bad, worst]
    final firsts = <String, String>{};
    for (final city in referenceCities) {
      if (args.length > 1 && args[1] != city.name) continue;
      final rule = defaultHighLatitudeRule(city.latitude);
      for (final asr in AsrMethod.values) {
        for (var i = 0; i < 365; i++) {
          final d = DateTime.utc(2026, 1, 1).add(Duration(days: i));
          final date =
              '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
          final o = calculateCivilDay(
            latitude: city.latitude,
            longitude: city.longitude,
            year: d.year,
            month: d.month,
            day: d.day,
            method: om,
            asrShadowFactor: asr == AsrMethod.hanafi ? 2 : 1,
            highLatitude: OracleHighLatitude.values.byName(rule.name),
            offsetAt: (t) => offsets.offsetAt(city.timeZoneId, t),
            isRamadan: isRamadan(date),
          );
          final r = engine.timesFor(
            latitude: city.latitude,
            longitude: city.longitude,
            timeZoneId: city.timeZoneId,
            localDate: date,
            method: method,
            asr: asr,
            highLatitudeRule: rule,
            offsetsMinutes: const {},
            imsakMinutes: 10,
          );
          final want = {
            Prayer.fajr: o.fajr,
            Prayer.sunrise: o.sunrise,
            Prayer.dhuhr: o.dhuhr,
            Prayer.asr: o.asr,
            Prayer.maghrib: o.maghrib,
            Prayer.isha: o.isha,
          };
          for (final p in Prayer.values) {
            final w = want[p];
            final g = r.times[p];
            final key = '${city.name}/${asr.name}/${p.name}';
            final s = summary.putIfAbsent(key, () => [0, 0, 0, 0]);
            s[0]++;
            int diff;
            if (w == null || g == null) {
              diff = (w == null) == (g == null) ? 0 : 99999;
            } else {
              diff = toWholeMinute(
                w,
                roundsUp: methodDefinitions[om]!.roundsUp,
              ).difference(g).inMinutes.abs();
            }
            if (diff > s[3]) s[3] = diff;
            if (diff > 1) {
              s[1]++;
              if (diff > s[2]) s[2] = diff;
              firsts.putIfAbsent(
                key,
                () =>
                    '$date want=${w?.toIso8601String()} got=${g?.toIso8601String()}',
              );
            }
          }
        }
      }
    }
    final bad = summary.entries.where((e) => e.value[1] > 0).toList();
    final total = summary.values.fold<int>(0, (a, s) => a + s[1]);
    final worstAll = summary.values.fold<int>(0, (a, s) => s[3] > a ? s[3] : a);
    final checked = summary.values.fold<int>(0, (a, s) => a + s[0]);
    print(
      '== ${om.name}: worst deviation $worstAll min; $total over 1 min of $checked',
    );
    for (final e in bad) {
      print(
        '  ${e.key}: bad=${e.value[1]} worst=${e.value[2]} first ${firsts[e.key]}',
      );
    }
  }
}
