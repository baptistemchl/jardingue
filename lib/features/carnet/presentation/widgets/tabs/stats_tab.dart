import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../_empty_tab_placeholder.dart';

class StatsTab extends StatelessWidget {
  const StatsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyTabPlaceholder(
      icon: PhosphorIcons.chartBar(PhosphorIconsStyle.duotone),
      title: AppLocalizations.of(context)!.carnetStatsEmptyTitle,
      subtitle: AppLocalizations.of(context)!.carnetStatsEmptySubtitle,
    );
  }
}
