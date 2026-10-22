import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/data_providers.dart';
import '../../data/export/settings_export_service.dart';
import '../../l10n/generated/app_localizations.dart';

/// Export, import and delete-all-data (spec Story 7, scenarios 3 and 4).
///
/// Every outcome is shown as a plain message with an icon, never by color
/// alone, and failures never crash the page.
class DataPage extends ConsumerStatefulWidget {
  const DataPage({super.key});

  @override
  ConsumerState<DataPage> createState() => _DataPageState();
}

enum _Tone { info, success, problem }

class _DataPageState extends ConsumerState<DataPage> {
  final ScrollController _scroll = ScrollController();
  bool _busy = false;
  String? _message;
  _Tone _tone = _Tone.info;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Shows the outcome in the banner at the top and scrolls there, so the
  /// result is visible after pressing a button further down.
  void _show(String message, _Tone tone) {
    if (!mounted) return;
    setState(() {
      _message = message;
      _tone = tone;
    });
    if (_scroll.hasClients && _scroll.offset > 0) {
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  /// Runs [action] with the buttons disabled; an unexpected error becomes the
  /// [failure] message.
  Future<void> _run(Future<void> Function() action, String failure) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } on Object catch (_) {
      _show(failure, _Tone.problem);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _export({required bool share, Rect? origin}) async {
    final l10n = AppLocalizations.of(context);
    await _run(() async {
      final service = ref.read(settingsExportServiceProvider);
      final sink = ref.read(exportFileSinkProvider);
      final content = await service.exportJson();
      final name = service.exportFileName();
      final done = share
          ? await sink.share(name, content, origin: origin)
          : await sink.saveToDevice(name, content);
      _show(
        done ? l10n.settingsExportDone : l10n.settingsExportCancelled,
        done ? _Tone.success : _Tone.info,
      );
    }, l10n.settingsExportFailed);
  }

  Future<void> _import() async {
    final l10n = AppLocalizations.of(context);
    await _run(() async {
      final text = await ref.read(importFileSourceProvider).pickSettingsFile();
      if (text == null) return;
      final result = await ref
          .read(settingsExportServiceProvider)
          .importJson(text);
      final error = result.errorOrNull;
      if (error == null) {
        final refreshed = result.valueOrNull?.scheduleRefreshed ?? true;
        _show(
          refreshed ? l10n.settingsImportDone : l10n.settingsImportDoneLater,
          _Tone.success,
        );
      } else {
        _show(_importMessage(l10n, error), _Tone.problem);
      }
    }, l10n.settingsImportUnreadable);
  }

  static String _importMessage(AppLocalizations l10n, Object error) {
    if (error is! ImportFailure) return l10n.settingsImportFailed;
    switch (error.kind) {
      case ImportFailureKind.notSettingsFile:
        return l10n.settingsImportNotSettings;
      case ImportFailureKind.newerVersion:
        return l10n.settingsImportNewer;
      case ImportFailureKind.unreadable:
        return l10n.settingsImportUnreadable;
      case ImportFailureKind.invalidValue:
        return l10n.settingsImportInvalid(error.field ?? '?');
      case ImportFailureKind.applyFailed:
        return l10n.settingsImportFailed;
    }
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('delete-all-dialog'),
        title: Text(l10n.settingsDeleteConfirmTitle),
        content: SingleChildScrollView(
          child: Text(l10n.settingsDeleteConfirmBody),
        ),
        actions: [
          TextButton(
            key: const Key('delete-all-cancel'),
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.settingsDeleteCancel),
          ),
          FilledButton(
            key: const Key('delete-all-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.settingsDeleteConfirmAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _run(() async {
      final result = await ref.read(deleteAllDataProvider)();
      _show(
        result.isOk ? l10n.settingsDeleteDone : l10n.settingsDeletePartial,
        result.isOk ? _Tone.success : _Tone.problem,
      );
    }, l10n.settingsDeletePartial);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      key: const Key('data-page'),
      appBar: AppBar(title: Text(l10n.settingsDataTitle)),
      body: SafeArea(
        child: ListView(
          controller: _scroll,
          padding: const EdgeInsetsDirectional.all(16),
          children: [
            if (_message != null) ...[
              _StatusBanner(message: _message!, tone: _tone),
              const SizedBox(height: 16),
            ],
            _Heading(l10n.settingsExportTitle),
            _Warning(text: l10n.settingsExportWarning),
            const SizedBox(height: 12),
            Builder(
              builder: (buttonContext) => FilledButton.icon(
                key: const Key('data-export-share'),
                onPressed: _busy
                    ? null
                    : () => _export(
                        share: true,
                        origin: _originOf(buttonContext),
                      ),
                icon: const Icon(Icons.ios_share),
                label: Text(l10n.settingsExportShare),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const Key('data-export-save'),
              onPressed: _busy ? null : () => _export(share: false),
              icon: const Icon(Icons.save_alt),
              label: Text(l10n.settingsExportSave),
            ),
            _Heading(l10n.settingsImportTitle),
            Text(l10n.settingsImportBody),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const Key('data-import'),
              onPressed: _busy ? null : _import,
              icon: const Icon(Icons.file_open_outlined),
              label: Text(l10n.settingsImportButton),
            ),
            _Heading(l10n.settingsDeleteTitle),
            Text(l10n.settingsDeleteBody),
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const Key('data-delete-all'),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
              onPressed: _busy ? null : _delete,
              icon: const Icon(Icons.delete_forever_outlined),
              label: Text(l10n.settingsDeleteTitle),
            ),
          ],
        ),
      ),
    );
  }

  /// The button's rectangle, which iPad needs to anchor the share sheet.
  static Rect? _originOf(BuildContext context) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 28, bottom: 8),
      child: Semantics(
        header: true,
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }
}

/// The location warning: an icon plus words, in a bordered box.
class _Warning extends StatelessWidget {
  const _Warning({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: const Key('data-export-warning'),
      padding: const EdgeInsetsDirectional.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

/// Result of the last action. Announced to screen readers when it appears.
class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.message, required this.tone});

  final String message;
  final _Tone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final icon = switch (tone) {
      _Tone.success => Icons.check_circle_outline,
      _Tone.problem => Icons.error_outline,
      _Tone.info => Icons.info_outline,
    };
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        key: const Key('data-status'),
        padding: const EdgeInsetsDirectional.all(12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          border: Border.all(color: scheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}
