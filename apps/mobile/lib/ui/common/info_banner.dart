import 'package:flutter/material.dart';

/// A boxed message with an icon, optional action and optional dismiss button.
///
/// The icon and the words carry the meaning; colour only adds emphasis (FR-013).
/// The text wraps, so it survives the largest text size.
class InfoBanner extends StatelessWidget {
  const InfoBanner({
    required this.message,
    this.icon = Icons.info_outline,
    this.actionLabel,
    this.onAction,
    this.dismissLabel,
    this.onDismiss,
    this.warning = false,
    super.key,
  });

  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Accessible label of the dismiss button; the button is shown only when both
  /// this and [onDismiss] are set.
  final String? dismissLabel;
  final VoidCallback? onDismiss;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = warning
        ? scheme.errorContainer
        : scheme.secondaryContainer;
    final foreground = warning
        ? scheme.onErrorContainer
        : scheme.onSecondaryContainer;
    return Semantics(
      container: true,
      liveRegion: true,
      child: Card(
        color: background,
        margin: const EdgeInsetsDirectional.symmetric(vertical: 4),
        child: Padding(
          padding: const EdgeInsetsDirectional.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(child: Icon(icon, color: foreground)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: foreground),
                    ),
                  ),
                  if (dismissLabel != null && onDismiss != null)
                    IconButton(
                      tooltip: dismissLabel,
                      icon: Icon(Icons.close, color: foreground),
                      onPressed: onDismiss,
                    ),
                ],
              ),
              if (actionLabel != null && onAction != null)
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: onAction,
                    child: Text(actionLabel!),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
