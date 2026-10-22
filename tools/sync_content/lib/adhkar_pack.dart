/// Builds the bundled adhkar pack from source files and validates them.
///
/// No religious text may ship without a source, a cleared license and a named
/// reviewer (FR-008, constitution principle 10). Validation therefore refuses
/// to build when anything is missing, and reports every problem at once. The
/// pack schema is documented in `adhkar_pack_schema.md`.
///
/// This file contains no adhkar text: the content is unresolved (plan D-4) and
/// the tests use invented placeholder data.
library;

import 'dart:convert';

/// Version of both the source and the pack format.
const int adhkarSchemaVersion = 1;

/// Collection kinds, matching `AdhkarCollectionKind` in the app.
const Set<String> adhkarKinds = {
  'morning',
  'evening',
  'afterPrayer',
  'beforeSleep',
  'waking',
  'other',
};

/// Languages with translations, matching `AppLanguage` minus Arabic.
const Set<String> translationLanguages = {'en', 'ur', 'id'};

/// Languages a collection title may be given in.
const Set<String> titleLanguages = {'en', 'ar', 'ur', 'id'};

/// The only license status that lets text into the pack.
const String clearedStatus = 'cleared';

/// One problem found in a source file.
class AdhkarIssue {
  const AdhkarIssue(this.file, this.location, this.message);

  /// Source file name.
  final String file;

  /// Where in the file, for example `entries[2] (morning-003)`.
  final String location;
  final String message;

  @override
  String toString() => '$file $location: $message';
}

/// The outcome of [buildAdhkarPack]: pack files, or issues and no files.
class AdhkarBuildResult {
  const AdhkarBuildResult(this.packFiles, this.issues);

  /// Pack file name (`<collection id>.json`) to its text. Empty when there are
  /// issues.
  final Map<String, String> packFiles;
  final List<AdhkarIssue> issues;
}

/// Validates [sourceFiles] (file name to JSON text) and builds the pack.
AdhkarBuildResult buildAdhkarPack(Map<String, String> sourceFiles) {
  final issues = <AdhkarIssue>[];
  final collections = <String, Map<String, Object?>>{};
  final entryIds = <String, String>{};

  final names = sourceFiles.keys.toList()..sort();
  for (final name in names) {
    final Object? decoded;
    try {
      decoded = jsonDecode(sourceFiles[name]!);
    } on FormatException catch (e) {
      issues.add(AdhkarIssue(name, 'file', 'not valid JSON (${e.message})'));
      continue;
    }
    if (decoded is! Map<String, Object?>) {
      issues.add(AdhkarIssue(name, 'file', 'top level must be an object'));
      continue;
    }
    final built = _validateFile(name, decoded, entryIds, issues);
    if (built == null) continue;
    final id = built['id']! as String;
    if (collections.containsKey(id)) {
      issues.add(
        AdhkarIssue(
          name,
          'collection.id',
          'collection "$id" is already '
              'defined by another source file',
        ),
      );
    } else {
      collections[id] = built;
    }
  }

  if (issues.isNotEmpty) return AdhkarBuildResult(const {}, issues);
  const encoder = JsonEncoder.withIndent('  ');
  return AdhkarBuildResult({
    for (final id in collections.keys.toList()..sort())
      '$id.json':
          '${encoder.convert({
            'schemaVersion': adhkarSchemaVersion,
            'collections': [collections[id]],
          })}\n',
  }, const []);
}

final RegExp _idPattern = RegExp(r'^[a-z0-9][a-z0-9_-]{0,63}$');
final RegExp _datePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');
final RegExp _placeholderReviewer = RegExp(
  r'todo|tbd|placeholder|unknown|^n/?a$|^none$|^\?+$|^-+$',
  caseSensitive: false,
);

/// The collection map for the pack, or null when the file is unusable.
Map<String, Object?>? _validateFile(
  String file,
  Map<String, Object?> json,
  Map<String, String> entryIds,
  List<AdhkarIssue> issues,
) {
  final before = issues.length;
  void problem(String location, String message) =>
      issues.add(AdhkarIssue(file, location, message));

  _rejectUnknownKeys(
    json,
    const {'schemaVersion', 'collection', 'sources', 'licenses', 'entries'},
    'file',
    problem,
  );
  if (json['schemaVersion'] != adhkarSchemaVersion) {
    problem('schemaVersion', 'must be $adhkarSchemaVersion');
  }

  final sources = _objectOf(json['sources']);
  final licenses = _objectOf(json['licenses']);
  if (sources == null) {
    problem('sources', 'must be an object of source records');
  }
  if (licenses == null) {
    problem('licenses', 'must be an object of license records');
  }
  final licenseStatus = <String, String>{};
  licenses?.forEach((id, record) {
    final map = _objectOf(record);
    final name = map == null ? null : _text(map['name']);
    final status = map == null ? null : _text(map['status']);
    if (name == null || status == null) {
      problem('licenses.$id', 'needs a name and a status');
    } else {
      licenseStatus[id] = status;
    }
  });
  final sourceIds = <String>{};
  sources?.forEach((id, record) {
    final map = _objectOf(record);
    if (map == null || _text(map['title']) == null) {
      problem('sources.$id', 'needs a title');
    } else {
      sourceIds.add(id);
    }
  });

  void checkSource(String location, Object? value, {bool required = true}) {
    final id = _text(value);
    if (id == null) {
      if (required) problem(location, 'sourceId is required');
    } else if (!sourceIds.contains(id)) {
      problem(location, 'sourceId "$id" is not listed in sources');
    }
  }

  String? checkLicense(String location, Object? value) {
    final id = _text(value);
    if (id == null) {
      problem(location, 'licenseId is required');
      return null;
    }
    final status = licenseStatus[id];
    if (status == null) {
      problem(location, 'licenseId "$id" is not listed in licenses');
      return null;
    }
    if (status != clearedStatus) {
      problem(
        location,
        'license "$id" is not cleared (status "$status"); text under it '
        'cannot ship',
      );
      return null;
    }
    return id;
  }

  // Collection header.
  final collection = _objectOf(json['collection']);
  var collectionId = '';
  var kind = '';
  Object? titles;
  String? collectionSource;
  if (collection == null) {
    problem('collection', 'must be an object');
  } else {
    _rejectUnknownKeys(
      collection,
      const {'id', 'kind', 'titles', 'sourceId'},
      'collection',
      problem,
    );
    collectionId = _text(collection['id']) ?? '';
    if (!_idPattern.hasMatch(collectionId)) {
      problem(
        'collection.id',
        'must be 1-64 characters of a-z, 0-9, "_" or "-" '
            '(it becomes the pack file name)',
      );
    }
    kind = _text(collection['kind']) ?? '';
    if (!adhkarKinds.contains(kind)) {
      problem('collection.kind', 'must be one of ${adhkarKinds.join(', ')}');
    }
    titles = collection['titles'];
    final titleMap = _objectOf(titles);
    if (titles != null) {
      if (titleMap == null) {
        problem('collection.titles', 'must be an object');
      } else {
        for (final entry in titleMap.entries) {
          if (!titleLanguages.contains(entry.key) ||
              _text(entry.value) == null) {
            problem(
              'collection.titles.${entry.key}',
              'unknown language or blank title',
            );
          }
        }
      }
    }
    if (collection['sourceId'] != null) {
      collectionSource = _text(collection['sourceId']);
      checkSource('collection.sourceId', collection['sourceId']);
    }
  }

  // Entries.
  final rawEntries = json['entries'];
  final entries = <Map<String, Object?>>[];
  if (rawEntries is! List<Object?>) {
    problem('entries', 'must be a list');
  } else if (rawEntries.isEmpty) {
    problem('entries', 'the collection has no entries');
  } else {
    final orders = <int>{};
    for (var i = 0; i < rawEntries.length; i++) {
      final raw = rawEntries[i];
      final label = raw is Map<String, Object?> && raw['id'] is String
          ? 'entries[$i] (${raw['id']})'
          : 'entries[$i]';
      final entry = _validateEntry(
        raw,
        label,
        problem,
        checkSource,
        checkLicense,
        entryIds,
        file,
        orders,
      );
      if (entry != null) entries.add(entry);
    }
  }

  if (issues.length > before) return null;
  entries.sort((a, b) => (a['order']! as int).compareTo(b['order']! as int));
  return {
    'id': collectionId,
    'kind': kind,
    'titles': ?titles,
    'sourceId': ?collectionSource,
    'entries': entries,
  };
}

/// The pack record for one entry, or null (after reporting) when invalid.
Map<String, Object?>? _validateEntry(
  Object? raw,
  String label,
  void Function(String, String) problem,
  void Function(String, Object?, {bool required}) checkSource,
  String? Function(String, Object?) checkLicense,
  Map<String, String> entryIds,
  String file,
  Set<int> orders,
) {
  final map = _objectOf(raw);
  if (map == null) {
    problem(label, 'must be an object');
    return null;
  }
  var ok = true;
  void bad(String message) {
    problem(label, message);
    ok = false;
  }

  _rejectUnknownKeys(
    map,
    const {
      'id',
      'order',
      'arabic',
      'transliteration',
      'translations',
      'repeatCount',
      'reference',
      'sourceId',
      'licenseId',
      'reviewer',
      'reviewedOn',
    },
    label,
    (location, message) {
      problem(location, message);
      ok = false;
    },
  );

  final id = _text(map['id']);
  if (id == null || !_idPattern.hasMatch(id)) {
    bad('id is required: 1-64 characters of a-z, 0-9, "_" or "-"');
  } else if (entryIds.containsKey(id)) {
    bad('duplicate id "$id" (also in ${entryIds[id]})');
  } else {
    entryIds[id] = file;
  }

  final order = map['order'];
  if (order is! int || order < 1) {
    bad('order is required and must be an integer from 1');
  } else if (!orders.add(order)) {
    bad('order $order is used twice in this collection');
  }

  final arabic = _text(map['arabic']);
  if (arabic == null) {
    bad('arabic text is required');
  } else if (!_hasArabicLetters(arabic)) {
    bad('arabic text must contain Arabic letters');
  }

  final repeat = map['repeatCount'];
  if (repeat is! int || repeat < 1) {
    bad('repeatCount is required and must be an integer from 1');
  }

  if (_text(map['reference']) == null) bad('reference is required');

  final reviewer = _text(map['reviewer']);
  if (reviewer == null) {
    bad('reviewer is required');
  } else if (_placeholderReviewer.hasMatch(reviewer)) {
    bad('reviewer "$reviewer" is a placeholder; name the person who reviewed');
  }

  final reviewedOn = _text(map['reviewedOn']);
  if (reviewedOn == null || !_isRealDate(reviewedOn)) {
    bad('reviewedOn is required and must be a real date as yyyy-MM-dd');
  }

  checkSource(label, map['sourceId']);
  final licenseId = checkLicense(label, map['licenseId']);
  if (licenseId == null) ok = false;

  if (map.containsKey('transliteration') &&
      _text(map['transliteration']) == null) {
    bad('transliteration, when present, must be non-blank text');
  }

  final translations = <String, String>{};
  final translationLicenses = <String, String>{};
  final rawTranslations = map['translations'];
  if (rawTranslations != null) {
    final byLanguage = _objectOf(rawTranslations);
    if (byLanguage == null) {
      bad('translations must be an object keyed by language');
    } else {
      for (final language in byLanguage.keys.toList()..sort()) {
        final where = '$label translations.$language';
        if (!translationLanguages.contains(language)) {
          problem(
            where,
            'language "$language" is not one of '
            '${translationLanguages.join(', ')}',
          );
          ok = false;
          continue;
        }
        final record = _objectOf(byLanguage[language]);
        if (record == null) {
          problem(where, 'must be an object with text and licenseId');
          ok = false;
          continue;
        }
        final text = _text(record['text']);
        if (text == null) {
          problem(where, 'text is required');
          ok = false;
        }
        final license = checkLicense(where, record['licenseId']);
        if (license == null) ok = false;
        if (record['sourceId'] != null) {
          checkSource(where, record['sourceId']);
        }
        _rejectUnknownKeys(
          record,
          const {'text', 'licenseId', 'sourceId'},
          where,
          (location, message) {
            problem(location, message);
            ok = false;
          },
        );
        if (text != null && license != null) {
          translations[language] = text;
          translationLicenses[language] = license;
        }
      }
    }
  }

  if (!ok) return null;
  return {
    'id': id,
    'order': order,
    'arabic': arabic,
    'transliteration': ?_text(map['transliteration']),
    if (translations.isNotEmpty) 'translations': translations,
    if (translationLicenses.isNotEmpty)
      'translationLicenseIds': translationLicenses,
    'repeatCount': repeat,
    'reference': _text(map['reference']),
    'sourceId': _text(map['sourceId']),
    'licenseId': licenseId,
    'reviewer': reviewer,
    'reviewedOn': reviewedOn,
  };
}

void _rejectUnknownKeys(
  Map<String, Object?> map,
  Set<String> known,
  String location,
  void Function(String location, String message) problem,
) {
  for (final key in map.keys) {
    if (!known.contains(key)) {
      problem(location, 'unknown field "$key" (check the spelling)');
    }
  }
}

Map<String, Object?>? _objectOf(Object? value) =>
    value is Map<String, Object?> ? value : null;

/// A non-blank string, trimmed, or null.
String? _text(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

bool _hasArabicLetters(String text) {
  for (final rune in text.runes) {
    if ((rune >= 0x0600 && rune <= 0x06FF) ||
        (rune >= 0x0750 && rune <= 0x077F) ||
        (rune >= 0xFB50 && rune <= 0xFDFF) ||
        (rune >= 0xFE70 && rune <= 0xFEFF)) {
      return true;
    }
  }
  return false;
}

bool _isRealDate(String text) {
  if (!_datePattern.hasMatch(text)) return false;
  final parsed = DateTime.tryParse(text);
  if (parsed == null) return false;
  String two(int n) => n.toString().padLeft(2, '0');
  return text ==
      '${parsed.year.toString().padLeft(4, '0')}-'
          '${two(parsed.month)}-${two(parsed.day)}';
}
