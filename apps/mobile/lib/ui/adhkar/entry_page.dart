import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/providers/adhkar_providers.dart';
import '../../domain/adhkar/adhkar_content.dart';
import '../../domain/adhkar/adhkar_session.dart';
import '../../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';
import 'adhkar_labels.dart';
import 'message_view.dart';

/// Reads one collection entry by entry and tracks the session.
///
/// The counting, undo, bookmark and previous/next controls sit at the bottom
/// of the screen, within reach of a thumb. [initialEntryId] opens a given
/// entry (used by bookmarks); otherwise the first unfinished entry is shown.
class AdhkarEntryPage extends ConsumerStatefulWidget {
  const AdhkarEntryPage({
    super.key,
    required this.collectionId,
    this.initialEntryId,
  });

  final String collectionId;
  final String? initialEntryId;

  @override
  ConsumerState<AdhkarEntryPage> createState() => _AdhkarEntryPageState();
}

class _AdhkarEntryPageState extends ConsumerState<AdhkarEntryPage> {
  /// Index of the shown entry, or null until the first build chooses it.
  int? _index;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sessionState = ref.watch(adhkarSessionProvider(widget.collectionId));
    return Scaffold(
      key: const Key('adhkar-entry-page'),
      appBar: AppBar(
        title: Text(
          sessionState.value == null
              ? l10n.adhkarTitle
              : collectionTitle(context, sessionState.value!.collection),
        ),
      ),
      body: SafeArea(
        child: sessionState.when(
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
          data: (session) {
            if (session == null || session.collection.entries.isEmpty) {
              return MessageView(
                icon: Icons.menu_book_outlined,
                title: l10n.adhkarNotFound,
              );
            }
            return _Reader(
              session: session,
              index: _initialIndex(session),
              onIndexChanged: (i) => setState(() => _index = i),
              controller: ref.read(
                adhkarSessionProvider(widget.collectionId).notifier,
              ),
            );
          },
        ),
      ),
    );
  }

  /// The entry to show. It is chosen once, when the session first loads, and
  /// then only changes when the user moves, so finishing an entry never jumps
  /// ahead by itself.
  int _initialIndex(AdhkarSession session) {
    final entries = session.collection.entries;
    final current = _index;
    if (current != null && current < entries.length) return current;
    final wanted = widget.initialEntryId ?? session.firstIncompleteEntryId;
    final found = entries.indexWhere((e) => e.id == wanted);
    return _index = found < 0 ? 0 : found;
  }
}

class _Reader extends ConsumerWidget {
  const _Reader({
    required this.session,
    required this.index,
    required this.onIndexChanged,
    required this.controller,
  });

  final AdhkarSession session;
  final int index;
  final ValueChanged<int> onIndexChanged;
  final AdhkarSessionController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final entries = session.collection.entries;
    final entry = entries[index];
    final bookmarked =
        ref
            .watch(adhkarBookmarksProvider)
            .value
            ?.any((b) => b.entryId == entry.id) ??
        false;
    final done = session.countFor(entry.id);
    final complete = session.isEntryComplete(entry.id);

    return Column(
      children: [
        _ProgressHeader(session: session),
        Expanded(
          child: SingleChildScrollView(
            key: const Key('adhkar-entry-scroll'),
            padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 16),
            child: _EntryCard(entry: entry),
          ),
        ),
        Material(
          elevation: 4,
          color: Theme.of(context).colorScheme.surface,
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 8,
              vertical: 8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (session.isFinished)
                  _FinishedBar(onRestart: controller.restart)
                else
                  Row(
                    children: [
                      IconButton(
                        key: const Key('adhkar-undo'),
                        tooltip: l10n.adhkarUndo,
                        icon: const Icon(Icons.undo),
                        onPressed: done == 0
                            ? null
                            : () => controller.undo(entry.id),
                      ),
                      Expanded(
                        child: _CountButton(
                          done: done,
                          total: entry.repeatCount,
                          complete: complete,
                          onPressed: complete
                              ? null
                              : () => controller.tap(entry.id),
                        ),
                      ),
                      IconButton(
                        key: const Key('adhkar-bookmark'),
                        tooltip: bookmarked
                            ? l10n.adhkarBookmarkRemove
                            : l10n.adhkarBookmarkAdd,
                        isSelected: bookmarked,
                        icon: const Icon(Icons.bookmark_border),
                        selectedIcon: const Icon(Icons.bookmark),
                        onPressed: () => ref
                            .read(adhkarBookmarkRepositoryProvider)
                            .toggle(entry.id, now: ref.read(clockProvider)()),
                      ),
                    ],
                  ),
                Row(
                  children: [
                    IconButton(
                      key: const Key('adhkar-previous'),
                      tooltip: l10n.adhkarPrevious,
                      icon: const Icon(Icons.chevron_left),
                      onPressed: index == 0
                          ? null
                          : () => onIndexChanged(index - 1),
                    ),
                    Expanded(
                      child: Text(
                        l10n.adhkarPosition(index + 1, entries.length),
                        key: const Key('adhkar-position'),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      key: const Key('adhkar-next'),
                      tooltip: l10n.adhkarNext,
                      icon: const Icon(Icons.chevron_right),
                      onPressed: index == entries.length - 1
                          ? null
                          : () => onIndexChanged(index + 1),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.session});

  final AdhkarSession session;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = l10n.adhkarProgressLabel(
      session.completedEntryCount,
      session.totalEntries,
    );
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 0),
      child: Semantics(
        container: true,
        label: label,
        child: ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, key: const Key('adhkar-progress-label')),
              const SizedBox(height: 6),
              LinearProgressIndicator(value: session.fraction, minHeight: 6),
            ],
          ),
        ),
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry});

  final AdhkarEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final language = appLanguageOf(context);
    final translation = entry.translationFor(language);
    final transliteration = entry.transliteration;

    return Card(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              entry.arabic,
              key: const Key('adhkar-arabic'),
              textDirection: TextDirection.rtl,
              locale: const Locale('ar'),
              style: TextStyle(
                fontFamily: arabicTextFontFamily,
                fontSize: 30,
                height: 1.9,
                color: theme.colorScheme.onSurface,
              ),
            ),
            if (transliteration != null) ...[
              const SizedBox(height: 16),
              _Section(
                heading: l10n.adhkarTransliterationHeading,
                child: Text(
                  transliteration,
                  key: const Key('adhkar-transliteration'),
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ],
            if (translation != null) ...[
              const SizedBox(height: 16),
              _Section(
                heading: translation.language == language
                    ? l10n.adhkarTranslationHeading
                    : l10n.adhkarTranslationFallbackHeading,
                child: Directionality(
                  textDirection: translation.language.isRtl
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                  child: Text(
                    translation.text,
                    key: const Key('adhkar-translation'),
                    locale: Locale(translation.language.name),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontFamily: uiFontFamily(translation.language),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.repeat, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.adhkarRepeatLabel(entry.repeatCount),
                    key: const Key('adhkar-repeat'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.menu_book_outlined, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.adhkarSourceLabel(entry.reference),
                    key: const Key('adhkar-source'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.heading, required this.child});

  final String heading;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(heading, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}

class _CountButton extends StatelessWidget {
  const _CountButton({
    required this.done,
    required this.total,
    required this.complete,
    required this.onPressed,
  });

  final int done;
  final int total;
  final bool complete;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = complete
        ? l10n.adhkarEntryDone
        : l10n.adhkarCountLabel(done, total);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 64),
      child: FilledButton.icon(
        key: const Key('adhkar-count'),
        onPressed: onPressed,
        icon: Icon(complete ? Icons.check_circle_outline : Icons.touch_app),
        label: Text(label, textAlign: TextAlign.center),
      ),
    );
  }
}

class _FinishedBar extends StatelessWidget {
  const _FinishedBar({required this.onRestart});

  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        const Padding(
          padding: EdgeInsetsDirectional.symmetric(horizontal: 8),
          child: Icon(Icons.check_circle_outline),
        ),
        Expanded(
          child: Text(
            l10n.adhkarSessionComplete,
            key: const Key('adhkar-session-complete'),
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: FilledButton(
            key: const Key('adhkar-restart'),
            onPressed: onRestart,
            child: Text(l10n.adhkarStartAgain),
          ),
        ),
      ],
    );
  }
}
