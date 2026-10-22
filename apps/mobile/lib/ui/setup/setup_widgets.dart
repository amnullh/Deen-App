import 'package:flutter/material.dart';

import '../../domain/setup/setup_state.dart';
import '../../l10n/generated/app_localizations.dart';

/// Layout shared by the setup steps: a heading and content that scrolls.
class SetupStepLayout extends StatelessWidget {
  const SetupStepLayout({
    required this.title,
    required this.children,
    super.key,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

/// A status line with an icon and words, so the state is never colour alone.
class StatusLine extends StatelessWidget {
  const StatusLine({required this.ok, required this.message, super.key});

  final bool ok;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Icon(
              ok ? Icons.check_circle_outline : Icons.info_outline,
              color: ok
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

/// The plain message for a setup problem.
String setupProblemMessage(AppLocalizations l10n, SetupProblem problem) {
  switch (problem) {
    case SetupProblem.locationDenied:
      return l10n.setupProblemLocationDenied;
    case SetupProblem.locationTimeout:
      return l10n.setupProblemLocationTimeout;
    case SetupProblem.locationUnavailable:
      return l10n.setupProblemLocationUnavailable;
    case SetupProblem.zoneUnknown:
      return l10n.setupProblemZoneUnknown;
    case SetupProblem.saveFailed:
      return l10n.setupProblemSaveFailed;
  }
}
