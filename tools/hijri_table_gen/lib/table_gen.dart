/// Reads the ICU4X Umm al-Qura month-length data and writes a Dart table.
///
/// ICU4X (https://github.com/unicode-org/icu4x, components/calendar) publishes
/// the Umm al-Qura month lengths for 1300 to 1600 AH under the Unicode License
/// V3, which requires its notice to travel with the data. The generated file
/// carries it.
library;

/// One Hijri year of the Umm al-Qura calendar.
class HijriYearRow {
  const HijriYearRow({
    required this.year,
    required this.monthIsLong,
    required this.startDay,
  });

  final int year;

  /// Twelve entries; true when the month has 30 days, false for 29.
  final List<bool> monthIsLong;

  /// Days since 1970-01-01 (UTC) of 1 Muharram of [year].
  final int startDay;

  /// Number of days in the year.
  int get length => monthIsLong.where((long) => long).length + 12 * 29;
}

/// The Unicode License V3 notice, reproduced from the ICU4X repository.
const String unicodeLicenseV3 = r'''
UNICODE LICENSE V3

COPYRIGHT AND PERMISSION NOTICE

Copyright © 2020-2024 Unicode, Inc.

NOTICE TO USER: Carefully read the following legal agreement. BY
DOWNLOADING, INSTALLING, COPYING OR OTHERWISE USING DATA FILES, AND/OR
SOFTWARE, YOU UNEQUIVOCALLY ACCEPT, AND AGREE TO BE BOUND BY, ALL OF THE
TERMS AND CONDITIONS OF THIS AGREEMENT. IF YOU DO NOT AGREE, DO NOT
DOWNLOAD, INSTALL, COPY, DISTRIBUTE OR USE THE DATA FILES OR SOFTWARE.

Permission is hereby granted, free of charge, to any person obtaining a
copy of data files and any associated documentation (the "Data Files") or
software and any associated documentation (the "Software") to deal in the
Data Files or Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, and/or sell
copies of the Data Files or Software, and to permit persons to whom the
Data Files or Software are furnished to do so, provided that either (a)
this copyright and permission notice appear with all copies of the Data
Files or Software, or (b) this copyright and permission notice appear in
associated Documentation.

THE DATA FILES AND SOFTWARE ARE PROVIDED "AS IS", WITHOUT WARRANTY OF ANY
KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT OF
THIRD PARTY RIGHTS.

IN NO EVENT SHALL THE COPYRIGHT HOLDER OR HOLDERS INCLUDED IN THIS NOTICE
BE LIABLE FOR ANY CLAIM, OR ANY SPECIAL INDIRECT OR CONSEQUENTIAL DAMAGES,
OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS,
WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THE DATA
FILES OR SOFTWARE.

Except as contained in this notice, the name of a copyright holder shall
not be used in advertising or otherwise to promote the sale, use or other
dealings in these Data Files or Software without prior written
authorization of the copyright holder.
''';

/// The pinned ICU4X source the table is generated from.
const String icu4xDataUrl =
    'https://raw.githubusercontent.com/unicode-org/icu4x/'
    '0455cbc76805bcace221573f242e2a7a82d10322/'
    'components/calendar/src/cal/hijri/ummalqura_data.rs';

final RegExp _row = RegExp(
  r'try_new\(\s*(\d+)\s*,\s*\[([^\]]*)\]\s*,\s*gregorian\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\)',
);

/// Parses the rows of ICU4X's `ummalqura_data.rs`.
List<HijriYearRow> parseIcu4xTable(String source) {
  final rows = <HijriYearRow>[];
  for (final match in _row.allMatches(source)) {
    final flags = match
        .group(2)!
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    if (flags.length != 12 || flags.any((f) => f != 'l' && f != 's')) {
      throw FormatException('Expected 12 month flags (l or s)', match.group(0));
    }
    final startDay =
        DateTime.utc(
          int.parse(match.group(3)!),
          int.parse(match.group(4)!),
          int.parse(match.group(5)!),
        ).millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay;
    rows.add(
      HijriYearRow(
        year: int.parse(match.group(1)!),
        monthIsLong: [for (final f in flags) f == 'l'],
        startDay: startDay,
      ),
    );
  }
  return rows;
}

/// Checks that years are consecutive and each year starts the day after the
/// previous one ends. Throws [StateError] otherwise.
void validateTable(List<HijriYearRow> rows) {
  for (var i = 1; i < rows.length; i++) {
    final previous = rows[i - 1];
    final current = rows[i];
    if (current.year != previous.year + 1) {
      throw StateError('Year ${current.year} does not follow ${previous.year}');
    }
    if (current.startDay != previous.startDay + previous.length) {
      throw StateError(
        'Year ${current.year} starts ${current.startDay - previous.startDay} '
        'days after ${previous.year}, expected ${previous.length}',
      );
    }
  }
}

String _join(List<int> values) {
  final buffer = StringBuffer();
  for (var i = 0; i < values.length; i++) {
    buffer.write(values[i]);
    if (i == values.length - 1) break;
    buffer.write(i % 10 == 9 ? ',\n  ' : ', ');
  }
  return buffer.toString();
}

/// Renders the Dart source of `umm_al_qura_table.dart`.
String renderDartTable(List<HijriYearRow> rows, {required String sourceUrl}) {
  final starts = [for (final row in rows) row.startDay];
  final masks = [
    for (final row in rows)
      [
        for (var m = 0; m < 12; m++)
          if (row.monthIsLong[m]) 1 << m,
      ].fold<int>(0, (a, b) => a | b),
  ];
  final licenseLines = unicodeLicenseV3
      .trim()
      .split('\n')
      .map((line) => line.isEmpty ? '//' : '// $line')
      .join('\n');
  return '''// GENERATED by tools/hijri_table_gen/bin/gen.dart. Do not edit by hand.
//
// Umm al-Qura calendar month lengths, ${rows.first.year} to ${rows.last.year} AH.
// Source: ICU4X, $sourceUrl
// (ICU4X obtained the data from ICU4C, which took it from the Umm al-Qura
// calendar published by KACST.)
//
// This data is used under the Unicode License V3 (SPDX: Unicode-3.0), whose
// notice follows and must be kept with this file.
//
$licenseLines
//
// SPDX-License-Identifier: Unicode-3.0

/// First Hijri year in the table.
const int ummAlQuraFirstYear = ${rows.first.year};

/// Last Hijri year in the table.
const int ummAlQuraLastYear = ${rows.last.year};

/// Days since 1970-01-01 (UTC) of 1 Muharram of each year, from
/// [ummAlQuraFirstYear].
const List<int> ummAlQuraYearStartDays = [
  ${_join(starts)},
];

/// For each year, a bit mask of its months: bit 0 is Muharram and a set bit
/// means the month has 30 days (clear: 29 days).
const List<int> ummAlQuraMonthMasks = [
  ${_join(masks)},
];
''';
}
