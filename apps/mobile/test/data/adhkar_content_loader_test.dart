import 'dart:convert';

import 'package:deen_mobile/data/adhkar/adhkar_content_loader.dart';
import 'package:deen_mobile/domain/adhkar/adhkar_content.dart';
import 'package:deen_mobile/domain/entities/enums.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> _entry(String id, {int order = 1, Object? repeat = 2}) => {
  'id': id,
  'order': order,
  'arabic': 'FAKE ARABIC $id',
  'transliteration': 'FAKE TRANSLIT $id',
  'translations': {
    'en': 'FAKE EN $id',
    'ur': 'FAKE UR $id',
    'id': 'FAKE ID $id',
  },
  'repeatCount': repeat,
  'reference': 'FAKE REF $id',
  'sourceId': 'fake-source',
  'licenseId': 'fake-license',
  'reviewer': 'Fake Reviewer',
  'reviewedOn': '2000-01-01',
};

class _FakeAssets implements AdhkarAssetSource {
  _FakeAssets(this.files);
  final Map<String, String> files;

  @override
  Future<List<String>> listPackFiles() async => files.keys.toList();

  @override
  Future<String> read(String path) async => files[path]!;
}

Future<AdhkarPack> _load(Map<String, String> files) =>
    AdhkarContentLoader(_FakeAssets(files)).load();

void main() {
  test('an empty asset folder gives an empty pack, not an error', () async {
    final pack = await _load({});
    expect(pack.isEmpty, isTrue);
    expect(pack.collections, isEmpty);
  });

  test(
    'the real bundle without adhkar assets also gives an empty pack',
    () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final pack = await AdhkarContentLoader(
        BundleAdhkarAssetSource(rootBundle),
      ).load();
      expect(pack.isEmpty, isTrue);
    },
  );

  test('reads a list of collections with every field', () async {
    final pack = await _load({
      'assets/adhkar/a.json': jsonEncode({
        'collections': [
          {
            'id': 'morning',
            'kind': 'morning',
            'sourceId': 'fake-source',
            'titles': {'en': 'Fake morning', 'ur': 'FAKE UR'},
            'entries': [_entry('e2', order: 2), _entry('e1', order: 1)],
          },
        ],
      }),
    });
    expect(pack.isEmpty, isFalse);
    final c = pack.collections.single;
    expect(c.kind, AdhkarCollectionKind.morning);
    expect(c.titles[AppLanguage.en], 'Fake morning');
    expect(c.entries.map((e) => e.id), ['e1', 'e2'], reason: 'sorted by order');
    final e = c.entries.first;
    expect(e.arabic, 'FAKE ARABIC e1');
    expect(e.transliteration, 'FAKE TRANSLIT e1');
    expect(e.translations[AppLanguage.id], 'FAKE ID e1');
    expect(e.repeatCount, 2);
    expect(e.reviewer, 'Fake Reviewer');
    expect(pack.credits.map((c) => c.entryId), ['e1', 'e2']);
  });

  test(
    'accepts collections keyed by kind and unknown kinds become other',
    () async {
      final pack = await _load({
        'assets/adhkar/a.json': jsonEncode({
          'collections': {
            'evening': {
              'entries': [_entry('x1')],
            },
            'something-new': {
              'entries': [_entry('y1')],
            },
          },
        }),
      });
      expect(pack.collections.map((c) => c.id), ['evening', 'something-new']);
      expect(pack.collections[0].kind, AdhkarCollectionKind.evening);
      expect(pack.collections[1].kind, AdhkarCollectionKind.other);
    },
  );

  test('merges the same collection from several files', () async {
    final one = jsonEncode({
      'collections': [
        {
          'id': 'morning',
          'entries': [_entry('e1', order: 1)],
        },
      ],
    });
    final two = jsonEncode({
      'collections': [
        {
          'id': 'morning',
          'entries': [_entry('e2', order: 2)],
        },
      ],
    });
    final pack = await _load({
      'assets/adhkar/one.json': one,
      'assets/adhkar/two.json': two,
    });
    expect(pack.collections, hasLength(1));
    expect(pack.collections.single.entries.map((e) => e.id), ['e1', 'e2']);
  });

  test(
    'skips entries without a source, license or reviewer (FR-008)',
    () async {
      final noReviewer = _entry('bad1')..remove('reviewer');
      final noSource = _entry('bad2')..['sourceId'] = '';
      final noArabic = _entry('bad3')..['arabic'] = '  ';
      final badRepeat = _entry('bad4', repeat: 0);
      final pack = await _load({
        'assets/adhkar/a.json': jsonEncode({
          'collections': [
            {
              'id': 'other',
              'entries': [
                noReviewer,
                noSource,
                noArabic,
                badRepeat,
                _entry('good'),
              ],
            },
          ],
        }),
      });
      expect(pack.collections.single.entries.map((e) => e.id), ['good']);
      expect(pack.problems, hasLength(4));
    },
  );

  test('a broken file is skipped and reported, others still load', () async {
    final pack = await _load({
      'assets/adhkar/broken.json': '{ not json',
      'assets/adhkar/wrongshape.json': '[1, 2, 3]',
      'assets/adhkar/ok.json': jsonEncode({
        'collections': [
          {
            'id': 'waking',
            'entries': [_entry('w1')],
          },
        ],
      }),
    });
    expect(pack.collections.single.id, 'waking');
    expect(pack.problems, hasLength(2));
  });

  test('missing optional fields are fine', () async {
    final minimal = _entry('m1')
      ..remove('transliteration')
      ..remove('translations');
    final pack = await _load({
      'assets/adhkar/a.json': jsonEncode({
        'collections': [
          {
            'id': 'beforeSleep',
            'entries': [minimal],
          },
        ],
      }),
    });
    final entry = pack.collections.single.entries.single;
    expect(pack.collections.single.kind, AdhkarCollectionKind.beforeSleep);
    expect(entry.transliteration, isNull);
    expect(entry.translations, isEmpty);
    expect(entry.translationFor(AppLanguage.ur), isNull);
  });

  test('translationFor falls back to English and never for Arabic', () {
    const entry = AdhkarEntry(
      id: 'e',
      order: 1,
      arabic: 'FAKE',
      repeatCount: 1,
      reference: 'r',
      sourceId: 's',
      licenseId: 'l',
      reviewer: 'x',
      reviewedOn: 'd',
      translations: {AppLanguage.en: 'FAKE EN', AppLanguage.ur: 'FAKE UR'},
    );
    expect(entry.translationFor(AppLanguage.ur)?.text, 'FAKE UR');
    expect(entry.translationFor(AppLanguage.id)?.language, AppLanguage.en);
    expect(entry.translationFor(AppLanguage.ar), isNull);
  });
}
