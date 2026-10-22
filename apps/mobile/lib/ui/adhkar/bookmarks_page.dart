import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/adhkar_providers.dart';
import '../../domain/adhkar/adhkar_bookmark.dart';
import '../../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';
import 'adhkar_labels.dart';
import 'entry_page.dart';
import 'message_view.dart';

/// The entries the user bookmarked, newest first. Tapping one opens it in its
/// collection.
class AdhkarBookmarksPage extends ConsumerWidget {
  const AdhkarBookmarksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final pack = ref.watch(adhkarPackProvider).value;
    final bookmarks = ref.watch(adhkarBookmarksProvider).value;
    final items = (pack == null || bookmarks == null)
        ? null
        : bookmarkedEntries(pack, bookmarks);

    return Scaffold(
      key: const Key('adhkar-bookmarks-page'),
      appBar: AppBar(title: Text(l10n.adhkarBookmarksTitle)),
      body: SafeArea(
        child: items == null
            ? Center(
                child: Semantics(
                  label: l10n.loading,
                  child: const CircularProgressIndicator(),
                ),
              )
            : items.isEmpty
            ? MessageView(
                key: const Key('adhkar-bookmarks-empty'),
                icon: Icons.bookmark_border,
                title: l10n.adhkarBookmarksTitle,
                body: l10n.adhkarBookmarksEmpty,
              )
            : ListView(
                children: [
                  for (final item in items)
                    ListTile(
                      key: Key('adhkar-bookmark-${item.entry.id}'),
                      minVerticalPadding: 12,
                      leading: const Icon(Icons.bookmark),
                      title: Text(
                        item.entry.arabic,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textDirection: TextDirection.rtl,
                        locale: const Locale('ar'),
                        style: const TextStyle(
                          fontFamily: arabicTextFontFamily,
                          fontSize: 20,
                        ),
                      ),
                      subtitle: Text(collectionTitle(context, item.collection)),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => AdhkarEntryPage(
                            collectionId: item.collection.id,
                            initialEntryId: item.entry.id,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
