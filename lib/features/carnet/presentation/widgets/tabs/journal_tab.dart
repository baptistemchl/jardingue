import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../_empty_tab_placeholder.dart';

class JournalTab extends StatelessWidget {
  const JournalTab({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyTabPlaceholder(
      icon: PhosphorIcons.notebook(PhosphorIconsStyle.duotone),
      title: AppLocalizations.of(context)!.carnetJournalEmptyTitle,
      subtitle: AppLocalizations.of(context)!.carnetJournalEmptySubtitle,
    );
  }
}
