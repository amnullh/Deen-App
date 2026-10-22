import 'dart:convert';

import 'package:flutter/services.dart';

import '../../domain/adhkar/adhkar_content.dart';
import '../../domain/entities/enums.dart';

/// Where pack files come from. The app reads bundled assets; tests pass a fake.
abstract interface class AdhkarAssetSource {
  /// Paths of every pack file (`assets/adhkar/*.json`), possibly none.
  Future<List<String>> listPackFiles();

  Future<String> read(String path);
}

/// Reads pack files from the Flutter asset bundle. Folder `assets/adhkar/`
/// need not exist: until the content gate (plan D-4) is cleared the app ships
/// without adhkar and shows a friendly empty state.
class BundleAdhkarAssetSource implements AdhkarAssetSource {
  BundleAdhkarAssetSource(this._bundle);

  static const String folder = 'assets/adhkar/';

  final AssetBundle _bundle;

  @override
  Future<List<String>> listPackFiles() async {
    final manifest = await AssetManifest.loadFromAssetBundle(_bundle);
    return manifest
        .listAssets()
        .where((path) => path.startsWith(folder) && path.endsWith('.json'))
        .toList()
      ..sort();
  }

  @override
  Future<String> read(String path) => _bundle.loadString(path);
}

/// Loads the read-only adhkar pack.
///
/// Never throws: a missing, unreadable or malformed file is skipped and noted
/// in [AdhkarPack.problems]. An entry without text, source, license or
/// reviewer is skipped too, because no religious text may be shown without
/// them (FR-008).
///
/// Pack shape (schema version 1, see `tools/sync_content`): an object with
/// `collections`, either a list of objects or an object keyed by collection
/// id. A collection has `id`, optional `kind` (defaults to the id; unknown
/// kinds become `other`), optional `titles`, `sourceId` and `entries`. An
/// entry has `id`, `order`, `arabic`, optional `transliteration` and
/// `translations` (en, ur, id), `repeatCount`, `reference`, `sourceId`,
/// `licenseId`, `reviewer` and `reviewedOn`.
class AdhkarContentLoader {
  AdhkarContentLoader(this._assets);

  final AdhkarAssetSource _assets;

  Future<AdhkarPack> load() async {
    final problems = <String>[];
    final List<String> files;
    try {
      files = await _assets.listPackFiles();
    } on Object catch (_) {
      return const AdhkarPack(
        collections: [],
        problems: ['The asset list could not be read.'],
      );
    }

    final builders = <String, _CollectionBuilder>{};
    for (final path in files) {
      try {
        final decoded = jsonDecode(await _assets.read(path));
        if (decoded is! Map<String, Object?>) {
          problems.add('$path: top level must be an object.');
          continue;
        }
        _readCollections(path, decoded['collections'], builders, problems);
      } on Object catch (e) {
        problems.add('$path: could not be read ($e).');
      }
    }
    return AdhkarPack(
      collections: [for (final b in builders.values) b.build()],
      problems: problems,
    );
  }

  void _readCollections(
    String path,
    Object? raw,
    Map<String, _CollectionBuilder> builders,
    List<String> problems,
  ) {
    final items = <MapEntry<String?, Object?>>[];
    if (raw is List<Object?>) {
      items.addAll(raw.map((c) => MapEntry<String?, Object?>(null, c)));
    } else if (raw is Map<String, Object?>) {
      items.addAll(
        raw.entries.map((e) => MapEntry<String?, Object?>(e.key, e.value)),
      );
    } else {
      problems.add('$path: "collections" is missing.');
      return;
    }
    for (final item in items) {
      final json = item.value;
      if (json is! Map<String, Object?>) {
        problems.add('$path: a collection is not an object.');
        continue;
      }
      final id = _text(json['id']) ?? item.key;
      if (id == null) {
        problems.add('$path: a collection has no id.');
        continue;
      }
      final builder = builders.putIfAbsent(
        id,
        () => _CollectionBuilder(
          id: id,
          kind: _kindOf(_text(json['kind']) ?? id),
          titles: _languageMap(json['titles']),
          sourceId: _text(json['sourceId']),
        ),
      );
      final entries = json['entries'];
      if (entries is! List<Object?>) continue;
      for (var i = 0; i < entries.length; i++) {
        final entry = _readEntry(entries[i], i + 1);
        if (entry == null) {
          problems.add(
            '$path: entry ${i + 1} of "$id" is incomplete and was skipped.',
          );
        } else {
          builder.entries.add(entry);
        }
      }
    }
  }

  AdhkarEntry? _readEntry(Object? raw, int fallbackOrder) {
    if (raw is! Map<String, Object?>) return null;
    final id = _text(raw['id']);
    final arabic = _text(raw['arabic']);
    final reference = _text(raw['reference']);
    final sourceId = _text(raw['sourceId']);
    final licenseId = _text(raw['licenseId']);
    final reviewer = _text(raw['reviewer']);
    final reviewedOn = _text(raw['reviewedOn']);
    final repeat = raw['repeatCount'] ?? 1;
    final order = raw['order'];
    if (id == null ||
        arabic == null ||
        reference == null ||
        sourceId == null ||
        licenseId == null ||
        reviewer == null ||
        reviewedOn == null ||
        repeat is! int ||
        repeat < 1) {
      return null;
    }
    return AdhkarEntry(
      id: id,
      order: order is int ? order : fallbackOrder,
      arabic: arabic,
      transliteration: _text(raw['transliteration']),
      translations: _languageMap(raw['translations']),
      repeatCount: repeat,
      reference: reference,
      sourceId: sourceId,
      licenseId: licenseId,
      reviewer: reviewer,
      reviewedOn: reviewedOn,
    );
  }

  /// A non-blank string, trimmed, or null.
  static String? _text(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Language code to text for the languages the app has; others are ignored.
  static Map<AppLanguage, String> _languageMap(Object? raw) {
    if (raw is! Map<String, Object?>) return const {};
    final result = <AppLanguage, String>{};
    for (final language in AppLanguage.values) {
      final text = _text(raw[language.name]);
      if (text != null) result[language] = text;
    }
    return result;
  }

  static AdhkarCollectionKind _kindOf(String name) {
    for (final kind in AdhkarCollectionKind.values) {
      if (kind.name.toLowerCase() == name.toLowerCase()) return kind;
    }
    return AdhkarCollectionKind.other;
  }
}

class _CollectionBuilder {
  _CollectionBuilder({
    required this.id,
    required this.kind,
    required this.titles,
    required this.sourceId,
  });

  final String id;
  final AdhkarCollectionKind kind;
  final Map<AppLanguage, String> titles;
  final String? sourceId;
  final List<AdhkarEntry> entries = [];

  AdhkarCollection build() => AdhkarCollection(
    id: id,
    kind: kind,
    titles: titles,
    sourceId: sourceId,
    entries: entries,
  );
}
