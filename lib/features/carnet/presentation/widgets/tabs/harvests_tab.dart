import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../_empty_tab_placeholder.dart';

class HarvestsTab extends StatelessWidget {
  const HarvestsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyTabPlaceholder(
      icon: PhosphorIcons.basket(PhosphorIconsStyle.duotone),
      title: AppLocalizations.of(context)!.carnetHarvestsEmptyTitle,
      subtitle: AppLocalizations.of(context)!.carnetHarvestsEmptySubtitle,
    );
  }
}
