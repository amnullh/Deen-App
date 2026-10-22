/// Generates `packages/prayer_engine/lib/src/hijri/umm_al_qura_table.dart`.
///
///     dart run tools/hijri_table_gen/bin/gen.dart [source.rs] [output.dart]
///
/// With no source argument the pinned ICU4X file is downloaded (network access
/// is needed once; the generated file is committed).
library;

import 'dart:io';

import 'package:hijri_table_gen/table_gen.dart';

Future<void> main(List<String> args) async {
  final sourcePath = args.isNotEmpty ? args[0] : null;
  final outputPath = args.length > 1
      ? args[1]
      : 'packages/prayer_engine/lib/src/hijri/umm_al_qura_table.dart';

  final String source;
  if (sourcePath != null) {
    source = await File(sourcePath).readAsString();
  } else {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(icu4xDataUrl));
      final response = await request.close();
      if (response.statusCode != 200) {
        stderr.writeln('Download failed: HTTP ${response.statusCode}');
        exitCode = 1;
        return;
      }
      source = await response.transform(const SystemEncoding().decoder).join();
    } finally {
      client.close();
    }
  }

  final rows = parseIcu4xTable(source);
  if (rows.isEmpty) {
    stderr.writeln('No year rows found in the source.');
    exitCode = 1;
    return;
  }
  validateTable(rows);
  final output = File(outputPath);
  await output.parent.create(recursive: true);
  await output.writeAsString(renderDartTable(rows, sourceUrl: icu4xDataUrl));
  stdout.writeln(
    'Wrote ${rows.length} years (${rows.first.year}-${rows.last.year} AH) '
    'to $outputPath',
  );
}
