import 'dart:convert';

import 'package:sync_content/adhkar_pack.dart';
import 'package:test/test.dart';

/// Fake data only: the Arabic is the placeholder phrase "test text" and the
/// ids are invented. No real adhkar text belongs in this file.
Map<String, Object?> _source({
  String collectionId = 'morning',
  String kind = 'morning',
  List<Map<String, Object?>>? entries,
  Map<String, Object?>? licenses,
  Map<String, Object?>? sources,
  Map<String, Object?>? extra,
}) {
  return {
    'schemaVersion': 1,
    'collection': {
      'id': collectionId,
      'kind': kind,
      'titles': {'en': 'Test collection', 'ar': 'مجموعة تجريبية'},
      'sourceId': 'src-fake',
    },
    'sources':
        sources ??
        {
          'src-fake': {
            'title': 'Fake source',
            'url': 'https://example.invalid',
          },
        },
    'licenses':
        licenses ??
        {
          'lic-fake': {'name': 'Fake license', 'status': 'cleared'},
          'lic-pending': {'name': 'Pending license', 'status': 'pending'},
        },
    'entries': entries ?? [_entry()],
    ...?extra,
  };
}

Map<String, Object?> _entry({
  String id = 'morning-001',
  Object? order = 1,
  Object? arabic = 'نص تجريبي',
  Object? reference = 'Fake reference 1',
  Object? sourceId = 'src-fake',
  Object? licenseId = 'lic-fake',
  Object? reviewer = 'Reviewer Fake',
  Object? reviewedOn = '2026-10-21',
  Object? repeatCount = 3,
  Map<String, Object?>? translations,
  Object? transliteration,
}) {
  return {
    'id': id,
    'order': order,
    'arabic': arabic,
    'reference': reference,
    'sourceId': sourceId,
    'licenseId': licenseId,
    'reviewer': reviewer,
    'reviewedOn': reviewedOn,
    'repeatCount': repeatCount,
    'transliteration': ?transliteration,
    'translations': ?translations,
  };
}

AdhkarBuildResult _build(Map<String, Map<String, Object?>> files) =>
    buildAdhkarPack({
      for (final e in files.entries) e.key: jsonEncode(e.value),
    });

List<String> _messages(AdhkarBuildResult r) => [
  for (final i in r.issues) '${i.file} ${i.location}: ${i.message}',
];

void main() {
  group('a valid source', () {
    test('builds one pack file per collection in the loader shape', () {
      final result = _build({
        'morning.json': _source(
          entries: [
            _entry(id: 'morning-002', order: 2, repeatCount: 1),
            _entry(
              translations: {
                'en': {'text': 'Fake English', 'licenseId': 'lic-fake'},
                'ur': {'text': 'Fake Urdu', 'licenseId': 'lic-fake'},
              },
              transliteration: 'fake translit',
            ),
          ],
        ),
      });
      expect(result.issues, isEmpty);
      expect(result.packFiles.keys, ['morning.json']);
      final pack =
          jsonDecode(result.packFiles['morning.json']!) as Map<String, Object?>;
      expect(pack['schemaVersion'], 1);
      final collections = pack['collections']! as List<Object?>;
      final collection = collections.single! as Map<String, Object?>;
      expect(collection['id'], 'morning');
      expect(collection['kind'], 'morning');
      expect(collection['titles'], {
        'en': 'Test collection',
        'ar': 'مجموعة تجريبية',
      });
      expect(collection['sourceId'], 'src-fake');
      final entries = collection['entries']! as List<Object?>;
      expect(
        [for (final e in entries) (e! as Map<String, Object?>)['id']],
        ['morning-001', 'morning-002'],
        reason: 'sorted by order',
      );
      final first = entries.first! as Map<String, Object?>;
      expect(first['translations'], {'en': 'Fake English', 'ur': 'Fake Urdu'});
      expect(first['translationLicenseIds'], {
        'en': 'lic-fake',
        'ur': 'lic-fake',
      });
      expect(first['transliteration'], 'fake translit');
      expect(first['reviewer'], 'Reviewer Fake');
      expect(first['reviewedOn'], '2026-10-21');
      expect(first['repeatCount'], 3);
      final second = entries.last! as Map<String, Object?>;
      expect(second.containsKey('translations'), isFalse);
    });

    test('output is deterministic and ends with a newline', () {
      final a = _build({'a.json': _source()});
      final b = _build({'a.json': _source()});
      expect(a.packFiles['morning.json'], b.packFiles['morning.json']);
      expect(a.packFiles['morning.json'], endsWith('\n'));
    });
  });

  group('entries are rejected when', () {
    void expectIssue(Map<String, Object?> entry, String fragment) {
      final result = _build({
        'a.json': _source(entries: [entry]),
      });
      expect(result.packFiles, isEmpty, reason: 'nothing is built on error');
      expect(_messages(result).join('\n'), contains(fragment));
    }

    test('Arabic text is missing, blank or not Arabic', () {
      expectIssue(_entry(arabic: null), 'arabic');
      expectIssue(_entry(arabic: '   '), 'arabic');
      expectIssue(_entry(arabic: 'latin only'), 'Arabic letters');
    });

    test('the reference is missing', () {
      expectIssue(_entry(reference: ''), 'reference');
    });

    test('the source id is missing or unknown', () {
      expectIssue(_entry(sourceId: null), 'sourceId');
      expectIssue(_entry(sourceId: 'src-nope'), 'src-nope');
    });

    test('the license is missing, unknown or not cleared', () {
      expectIssue(_entry(licenseId: null), 'licenseId');
      expectIssue(_entry(licenseId: 'lic-nope'), 'lic-nope');
      expectIssue(_entry(licenseId: 'lic-pending'), 'not cleared');
    });

    test('the reviewer is missing or a placeholder', () {
      expectIssue(_entry(reviewer: null), 'reviewer');
      expectIssue(_entry(reviewer: ' '), 'reviewer');
      expectIssue(_entry(reviewer: 'TODO scholar'), 'placeholder');
      expectIssue(_entry(reviewer: 'TBD'), 'placeholder');
    });

    test('the review date is missing or not a real date', () {
      expectIssue(_entry(reviewedOn: null), 'reviewedOn');
      expectIssue(_entry(reviewedOn: '21/10/2026'), 'yyyy-MM-dd');
      expectIssue(_entry(reviewedOn: '2026-02-30'), 'yyyy-MM-dd');
    });

    test('the repeat count is not a positive integer', () {
      expectIssue(_entry(repeatCount: 0), 'repeatCount');
      expectIssue(_entry(repeatCount: '3'), 'repeatCount');
      expectIssue(_entry(repeatCount: 1.5), 'repeatCount');
    });

    test('the order is not a positive integer', () {
      expectIssue(_entry(order: 0), 'order');
      expectIssue(_entry(order: null), 'order');
    });

    test('there is an unknown field (a typo would silently drop a rule)', () {
      expectIssue({..._entry(), 'reveiwer': 'x'}, 'reveiwer');
    });
  });

  group('translations', () {
    void expectIssue(Map<String, Object?> translations, String fragment) {
      final result = _build({
        'a.json': _source(entries: [_entry(translations: translations)]),
      });
      expect(result.packFiles, isEmpty);
      expect(_messages(result).join('\n'), contains(fragment));
    }

    test('are rejected without a license', () {
      expectIssue({
        'en': {'text': 'Fake'},
      }, 'licenseId');
    });

    test('are rejected with an unknown or uncleared license', () {
      expectIssue({
        'en': {'text': 'Fake', 'licenseId': 'lic-nope'},
      }, 'lic-nope');
      expectIssue({
        'ur': {'text': 'Fake', 'licenseId': 'lic-pending'},
      }, 'not cleared');
    });

    test('are rejected for a language the app does not have', () {
      expectIssue({
        'fr': {'text': 'Fake', 'licenseId': 'lic-fake'},
      }, 'fr');
    });

    test('are rejected when the text is blank or the shape is wrong', () {
      expectIssue({
        'en': {'text': ' ', 'licenseId': 'lic-fake'},
      }, 'text');
      expectIssue({'en': 'bare string'}, 'object');
    });

    test('cleared ones with their own source are accepted', () {
      final result = _build({
        'a.json': _source(
          entries: [
            _entry(
              translations: {
                'id': {
                  'text': 'Fake Indonesian',
                  'licenseId': 'lic-fake',
                  'sourceId': 'src-fake',
                },
              },
            ),
          ],
        ),
      });
      expect(result.issues, isEmpty);
    });
  });

  group('collections and files', () {
    test('an unknown collection kind is rejected', () {
      final result = _build({'a.json': _source(kind: 'midday')});
      expect(_messages(result).join('\n'), contains('kind'));
    });

    test('all six kinds are accepted', () {
      for (final kind in [
        'morning',
        'evening',
        'afterPrayer',
        'beforeSleep',
        'waking',
        'other',
      ]) {
        final result = _build({
          'a.json': _source(collectionId: kind.toLowerCase(), kind: kind),
        });
        expect(result.issues, isEmpty, reason: kind);
      }
    });

    test('duplicate entry ids, orders and collections are rejected', () {
      final dupId = _build({
        'a.json': _source(entries: [_entry(), _entry(order: 2)]),
      });
      expect(_messages(dupId).join('\n'), contains('duplicate id'));
      final dupOrder = _build({
        'a.json': _source(
          entries: [
            _entry(),
            _entry(id: 'morning-002'),
          ],
        ),
      });
      expect(_messages(dupOrder).join('\n'), contains('order 1'));
      final dupCollection = _build({
        'a.json': _source(),
        'b.json': _source(entries: [_entry(id: 'morning-009', order: 9)]),
      });
      expect(_messages(dupCollection).join('\n'), contains('already defined'));
    });

    test('an unsafe collection id is rejected (it becomes a file name)', () {
      final result = _build({'a.json': _source(collectionId: '../evil')});
      expect(_messages(result).join('\n'), contains('collection.id'));
    });

    test('bad JSON and a wrong schema version are reported', () {
      final bad = buildAdhkarPack({'a.json': '{not json'});
      expect(bad.issues.single.message, contains('JSON'));
      final wrong = _build({
        'a.json': _source(extra: {'schemaVersion': 2}),
      });
      expect(_messages(wrong).join('\n'), contains('schemaVersion'));
    });

    test('a collection with no entries is rejected', () {
      final result = _build({'a.json': _source(entries: [])});
      expect(_messages(result).join('\n'), contains('no entries'));
    });

    test('every problem is listed, not only the first', () {
      final result = _build({
        'a.json': _source(
          entries: [
            _entry(arabic: null, reviewer: null),
            _entry(id: 'morning-002', order: 2, reference: ''),
          ],
        ),
      });
      expect(result.issues.length, greaterThanOrEqualTo(3));
    });

    test('no source files is not an error and builds nothing', () {
      final result = buildAdhkarPack({});
      expect(result.issues, isEmpty);
      expect(result.packFiles, isEmpty);
    });
  });
}
