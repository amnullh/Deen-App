import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/adhkar_providers.dart';
import '../../app/providers/data_providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../adhkar/content_credits_page.dart';
import 'attributions.dart';

/// Open-source licenses, content sources and reviewers, attributions, the
/// "no data collected" statement and the privacy policy (spec Story 7,
/// scenario 5).
class AboutPage extends ConsumerWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final version = ref.watch(appVersionProvider);
    final policyUrl = ref.watch(privacyPolicyUrlProvider);
    final creditCount = ref.watch(adhkarPackProvider).value?.credits.length;

    return Scaffold(
      key: const Key('about-page'),
      appBar: AppBar(title: Text(l10n.aboutTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsetsDirectional.all(16),
          children: [
            Text(l10n.appTitle, style: theme.textTheme.headlineSmall),
            Text(l10n.aboutVersion(version)),
            const SizedBox(height: 8),
            Text(l10n.aboutDescription),
            _Heading(l10n.aboutPrivacyHeading),
            Text(l10n.aboutNoDataCollected, key: const Key('about-no-data')),
            _Heading(l10n.aboutPrivacyPolicyTitle),
            Text(
              policyUrl == null
                  ? l10n.aboutPrivacyPolicyPending
                  : l10n.aboutPrivacyPolicyAddress(policyUrl),
              key: const Key('about-privacy-policy'),
            ),
            const SizedBox(height: 16),
            ListTile(
              key: const Key('about-licenses'),
              contentPadding: EdgeInsets.zero,
              minVerticalPadding: 12,
              leading: const Icon(Icons.description_outlined),
              title: Text(l10n.aboutLicensesTitle),
              subtitle: Text(l10n.aboutLicensesSubtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showLicensePage(
                context: context,
                applicationName: l10n.appTitle,
                applicationVersion: version,
              ),
            ),
            _Heading(l10n.aboutAttributionsTitle),
            Text(l10n.aboutLegalEnglishNote, style: theme.textTheme.bodySmall),
            _LegalBlock(
              heading: l10n.aboutCitiesHeading,
              lines: const [
                Attributions.geoNames,
                Attributions.geoNamesLicenseUrl,
              ],
            ),
            _LegalBlock(
              heading: l10n.aboutFontsHeading,
              lines: [Attributions.fonts.join(', '), Attributions.fontsNotice],
            ),
            _LegalBlock(
              heading: l10n.aboutHijriHeading,
              lines: const [Attributions.unicode],
            ),
            _Heading(l10n.aboutContentHeading),
            ListTile(
              key: const Key('about-content-credits'),
              contentPadding: EdgeInsets.zero,
              minVerticalPadding: 12,
              leading: const Icon(Icons.verified_outlined),
              title: Text(l10n.adhkarCreditsTitle),
              subtitle: creditCount == null
                  ? null
                  : Text(l10n.adhkarCreditsCount(creditCount)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ContentCreditsPage(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 24, bottom: 8),
      child: Semantics(
        header: true,
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }
}

/// A heading and license wording that stays in English, so it is laid out left
/// to right and read with an English voice whatever the interface language.
class _LegalBlock extends StatelessWidget {
  const _LegalBlock({required this.heading, required this.lines});

  final String heading;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(heading, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: SelectableText(lines.join('\n')),
            ),
          ),
        ],
      ),
    );
  }
}
