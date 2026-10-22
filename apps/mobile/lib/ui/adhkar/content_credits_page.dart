import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/adhkar_providers.dart';
import '../../domain/adhkar/adhkar_content.dart';
import '../../l10n/generated/app_localizations.dart';
import 'adhkar_labels.dart';
import 'message_view.dart';

/// Lists the source, license and reviewer of every adhkar text in the pack
/// (spec Story 6, scenario 5). Reached from the About screen.
class ContentCreditsPage extends ConsumerWidget {
  const ContentCreditsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final pack = ref.watch(adhkarPackProvider);
    return Scaffold(
      key: const Key('content-credits-page'),
      appBar: AppBar(title: Text(l10n.adhkarCreditsTitle)),
      body: SafeArea(
        child: pack.when(
          loading: () => Center(
            child: Semantics(
              label: l10n.loading,
              child: const CircularProgressIndicator(),
            ),
          ),
          error: (_, _) => MessageView(
            icon: Icons.error_outline,
            title: l10n.adhkarLoadError,
          ),
          data: (data) {
            if (data.isEmpty) {
              return MessageView(
                key: const Key('content-credits-empty'),
                icon: Icons.menu_book_outlined,
                title: l10n.adhkarCreditsTitle,
                body: l10n.adhkarCreditsEmpty,
              );
            }
            return ListView(
              padding: const EdgeInsetsDirectional.all(16),
              children: [
                Text(l10n.adhkarCreditsIntro),
                for (final collection in data.collections)
                  if (collection.entries.isNotEmpty)
                    ..._section(context, collection),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _section(BuildContext context, AdhkarCollection collection) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return [
      const SizedBox(height: 24),
      Semantics(
        header: true,
        child: Text(
          collectionTitle(context, collection),
          style: theme.textTheme.titleMedium,
        ),
      ),
      for (final entry in collection.entries)
        Padding(
          padding: const EdgeInsetsDirectional.only(top: 12),
          child: Column(
            key: Key('credit-${entry.id}'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.adhkarCreditEntry(entry.order, entry.reference),
                style: theme.textTheme.titleSmall,
              ),
              Text(l10n.adhkarCreditSource(entry.sourceId, entry.licenseId)),
              Text(l10n.adhkarCreditReviewer(entry.reviewer, entry.reviewedOn)),
            ],
          ),
        ),
    ];
  }
}
