import 'dart:convert';

import 'package:l10n_merge/merge.dart';
import 'package:test/test.dart';

String _fragment(Map<String, Object?> content) => jsonEncode(content);

Map<String, Object?> _entry(String en, {String? description}) => {
  'en': en,
  'ar': 'ar:$en',
  'ur': 'ur:$en',
  'id': 'id:$en',
  'description': ?description,
};

void main() {
  test(
    'merges fragments into sorted ARB files with metadata only in English',
    () {
      final result = mergeFragments({
        'b.json': _fragment({'zeta': _entry('Z')}),
        'a.json': _fragment({'alpha': _entry('A', description: 'First')}),
      });
      expect(result.ok, isTrue, reason: result.problems.join('; '));
      final en =
          jsonDecode(result.arbByLanguage['en']!) as Map<String, Object?>;
      expect(en.keys.toList(), ['@@locale', 'alpha', '@alpha', 'zeta']);
      expect(en['@alpha'], {'description': 'First'});
      final ar =
          jsonDecode(result.arbByLanguage['ar']!) as Map<String, Object?>;
      expect(ar['alpha'], 'ar:A');
      expect(ar.containsKey('@alpha'), isFalse);
      expect(ar['@@locale'], 'ar');
    },
  );

  test('copies placeholders into the English metadata', () {
    final entry = _entry('Hello {name}')
      ..['placeholders'] = {
        'name': {'type': 'String'},
      };
    final result = mergeFragments({
      'a.json': _fragment({'hello': entry}),
    });
    final en = jsonDecode(result.arbByLanguage['en']!) as Map<String, Object?>;
    expect(en['@hello'], {
      'placeholders': {
        'name': {'type': 'String'},
      },
    });
  });

  test('reports a missing language', () {
    final entry = _entry('X')..remove('ur');
    final result = mergeFragments({
      'a.json': _fragment({'x': entry}),
    });
    expect(result.ok, isFalse);
    expect(result.problems.single, contains('"x" has no "ur" text'));
  });

  test('reports a key defined in two fragments', () {
    final result = mergeFragments({
      'a.json': _fragment({'same': _entry('1')}),
      'b.json': _fragment({'same': _entry('2')}),
    });
    expect(result.problems.single, contains('already defined in a.json'));
  });

  test('reports bad key names and invalid JSON', () {
    final result = mergeFragments({
      'a.json': _fragment({'Bad_Key': _entry('1')}),
      'b.json': '{not json',
    });
    expect(result.problems.length, 2);
  });
}
