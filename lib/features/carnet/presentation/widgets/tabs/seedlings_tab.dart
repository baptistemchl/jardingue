import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../_empty_tab_placeholder.dart';

class SeedlingsTab extends StatelessWidget {
  const SeedlingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyTabPlaceholder(
      icon: PhosphorIcons.plant(PhosphorIconsStyle.duotone),
      title: AppLocalizations.of(context)!.carnetSeedlingsEmptyTitle,
      subtitle: AppLocalizations.of(context)!.carnetSeedlingsEmptySubtitle,
    );
  }
}
