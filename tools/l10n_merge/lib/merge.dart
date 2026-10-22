/// Merges string fragments into ARB files.
///
/// Each feature owns one fragment file, `apps/mobile/lib/l10n/fragments/<name>.json`:
///
///     {
///       "setupTitle": {
///         "en": "Set up Deen App", "ar": "...", "ur": "...", "id": "...",
///         "description": "Heading of the first setup screen.",
///         "placeholders": { "name": { "type": "String" } }   // optional
///       }
///     }
///
/// Every key needs all four languages. A key may appear in one fragment only.
/// The ARB files are generated; never edit them by hand.
library;

import 'dart:convert';

/// Languages the app ships (FR-007).
const List<String> languages = ['en', 'ar', 'ur', 'id'];

class MergeResult {
  const MergeResult(this.arbByLanguage, this.problems);

  /// Language code to the text of its ARB file.
  final Map<String, String> arbByLanguage;
  final List<String> problems;

  bool get ok => problems.isEmpty;
}

/// Merges [fragments] (file name to decoded JSON text).
MergeResult mergeFragments(Map<String, String> fragments) {
  final problems = <String>[];
  final entries = <String, Map<String, Object?>>{};
  final owner = <String, String>{};

  for (final file in fragments.keys.toList()..sort()) {
    final Object? decoded;
    try {
      decoded = jsonDecode(fragments[file]!);
    } on FormatException catch (e) {
      problems.add('$file: invalid JSON (${e.message})');
      continue;
    }
    if (decoded is! Map<String, Object?>) {
      problems.add('$file: top level must be an object');
      continue;
    }
    for (final entry in decoded.entries) {
      final key = entry.key;
      final value = entry.value;
      if (!RegExp(r'^[a-z][A-Za-z0-9]*$').hasMatch(key)) {
        problems.add(
          '$file: key "$key" must be lowerCamelCase letters and digits',
        );
        continue;
      }
      if (value is! Map<String, Object?>) {
        problems.add('$file: "$key" must be an object');
        continue;
      }
      if (owner.containsKey(key)) {
        problems.add('$file: key "$key" is already defined in ${owner[key]}');
        continue;
      }
      var complete = true;
      for (final language in languages) {
        final text = value[language];
        if (text is! String || text.trim().isEmpty) {
          problems.add('$file: "$key" has no "$language" text');
          complete = false;
        }
      }
      if (!complete) continue;
      owner[key] = file;
      entries[key] = value;
    }
  }

  final sorted = entries.keys.toList()..sort();
  final result = <String, String>{};
  for (final language in languages) {
    final out = <String, Object?>{'@@locale': language};
    for (final key in sorted) {
      final value = entries[key]!;
      out[key] = value[language];
      if (language == 'en') {
        final meta = <String, Object?>{};
        if (value['description'] is String) {
          meta['description'] = value['description'];
        }
        if (value['placeholders'] is Map) {
          meta['placeholders'] = value['placeholders'];
        }
        if (meta.isNotEmpty) out['@$key'] = meta;
      }
    }
    result[language] = '${const JsonEncoder.withIndent('  ').convert(out)}\n';
  }
  return MergeResult(result, problems);
}
