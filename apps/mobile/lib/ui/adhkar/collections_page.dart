import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/adhkar_providers.dart';
import '../../l10n/generated/app_localizations.dart';
import 'adhkar_labels.dart';
import 'bookmarks_page.dart';
import 'entry_page.dart';
import 'message_view.dart';
import 'reminder_settings_page.dart';

/// The adhkar home: every collection in the bundled pack, with entry points
/// for bookmarks and reminders. Until the pack has content it shows a friendly
/// empty state (plan D-4).
class AdhkarCollectionsPage extends ConsumerWidget {
  const AdhkarCollectionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final pack = ref.watch(adhkarPackProvider);
    return Scaffold(
      key: const Key('adhkar-collections-page'),
      appBar: AppBar(title: Text(l10n.adhkarTitle)),
      body: SafeArea(
        child: pack.when(
          loading: () => Center(
            child: Semantics(
              label: l10n.loading,
              child: const CircularProgressIndicator(),
            ),
          ),
          error: (_, _) => MessageView(
            key: const Key('adhkar-load-error'),
            icon: Icons.error_outline,
            title: l10n.adhkarLoadError,
          ),
          data: (data) {
            if (data.isEmpty) {
              return MessageView(
                key: const Key('adhkar-empty'),
                icon: Icons.menu_book_outlined,
                title: l10n.adhkarEmptyTitle,
                body: l10n.adhkarEmptyBody,
              );
            }
            return ListView(
              padding: const EdgeInsetsDirectional.symmetric(vertical: 8),
              children: [
                for (final collection in data.collections)
                  if (collection.entries.isNotEmpty)
                    ListTile(
                      key: Key('adhkar-collection-${collection.id}'),
                      minVerticalPadding: 12,
                      leading: Icon(kindIcon(collection.kind)),
                      title: Text(collectionTitle(context, collection)),
                      subtitle: Text(
                        l10n.adhkarEntryCount(collection.entries.length),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _open(
                        context,
                        AdhkarEntryPage(collectionId: collection.id),
                      ),
                    ),
              ],
            );
          },
        ),
      ),
      // Bookmarks and reminders sit at the bottom, within reach of a thumb.
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('adhkar-bookmarks-entry'),
                  style: _barButtonStyle,
                  icon: const Icon(Icons.bookmarks_outlined),
                  label: Text(
                    l10n.adhkarBookmarksTitle,
                    textAlign: TextAlign.center,
                  ),
                  onPressed: () => _open(context, const AdhkarBookmarksPage()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('adhkar-reminders-entry'),
                  style: _barButtonStyle,
                  icon: const Icon(Icons.notifications_outlined),
                  label: Text(
                    l10n.adhkarRemindersTitle,
                    textAlign: TextAlign.center,
                  ),
                  onPressed: () =>
                      _open(context, const AdhkarReminderSettingsPage()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static final ButtonStyle _barButtonStyle = OutlinedButton.styleFrom(
    minimumSize: const Size(0, 56),
  );

  static void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }
}
