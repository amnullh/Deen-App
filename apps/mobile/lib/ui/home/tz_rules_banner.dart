import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/prayer_providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../common/info_banner.dart';

/// Tells the user that the phone's time-zone rules and the app's bundled rules
/// disagree, so the app should be updated (research R-T1).
class TzRulesBanner extends ConsumerWidget {
  const TzRulesBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(tzRulesNoticeProvider)) return const SizedBox.shrink();
    return InfoBanner(
      key: const Key('tz-rules-banner'),
      icon: Icons.public,
      message: AppLocalizations.of(context).homeTzRulesNotice,
    );
  }
}
