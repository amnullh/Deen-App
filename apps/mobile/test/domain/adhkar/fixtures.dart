import 'package:deen_mobile/domain/adhkar/adhkar_content.dart';
import 'package:deen_mobile/domain/entities/enums.dart';

/// Clearly fake entry for tests. No real adhkar, Quran or hadith text is
/// allowed in this repository until the content gate (plan D-4) is cleared.
AdhkarEntry fakeEntry(
  String id, {
  int order = 1,
  int repeatCount = 1,
  Map<AppLanguage, String> translations = const {},
  String? transliteration,
}) {
  return AdhkarEntry(
    id: id,
    order: order,
    arabic: 'FAKE ARABIC $id',
    transliteration: transliteration,
    translations: translations,
    repeatCount: repeatCount,
    reference: 'FAKE REFERENCE $id',
    sourceId: 'fake-source',
    licenseId: 'fake-license',
    reviewer: 'Fake Reviewer',
    reviewedOn: '2000-01-01',
  );
}

AdhkarCollection fakeCollection({
  String id = 'morning',
  AdhkarCollectionKind kind = AdhkarCollectionKind.morning,
  List<AdhkarEntry>? entries,
}) {
  return AdhkarCollection(
    id: id,
    kind: kind,
    entries:
        entries ??
        [
          fakeEntry('e1', order: 1, repeatCount: 3),
          fakeEntry('e2', order: 2, repeatCount: 1),
          fakeEntry('e3', order: 3, repeatCount: 2),
        ],
  );
}

AdhkarPack fakePack([List<AdhkarCollection>? collections]) =>
    AdhkarPack(collections: collections ?? [fakeCollection()]);
