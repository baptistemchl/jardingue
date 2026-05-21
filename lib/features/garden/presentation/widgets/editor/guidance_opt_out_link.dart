import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jardingue/l10n/generated/app_localizations.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/services/preferences/user_guidance_preferences.dart';
import '../../../../../core/theme/app_typography.dart';

/// Les deux features de guidance opt-in côté Paramètres. Les labels et
/// messages sont résolus côté widget via AppLocalizations (les enum
/// values ne peuvent pas accéder au BuildContext).
enum GuidanceFeature { companionSuggestions, antagonistWarnings }

/// Lien discret « Ne plus afficher… » à placer en bas d'une bottom sheet
/// ou d'un dialog de guidance (suggestions compagnons / warnings
/// antagonistes). Au tap :
/// 1. Désactive la préférence correspondante
/// 2. Appelle [onDismiss] pour que le caller ferme proprement son widget
///    (le caller connaît son type de retour : `<int>[]` pour la sheet,
///    `false` pour le dialog…)
/// 3. Affiche un snackbar explicatif avec bouton « Annuler » qui
///    réactive la préférence (anti fat-finger)
class GuidanceOptOutLink extends ConsumerWidget {
  final GuidanceFeature feature;
  final VoidCallback onDismiss;

  const GuidanceOptOutLink({
    super.key,
    required this.feature,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final label = switch (feature) {
      GuidanceFeature.companionSuggestions => loc.guidanceOptOutCompanionLink,
      GuidanceFeature.antagonistWarnings => loc.guidanceOptOutAntagonistLink,
    };
    return TextButton.icon(
      onPressed: () => _handleTap(context, ref),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.textTertiary,
      ),
      icon: const Icon(Icons.visibility_off_outlined, size: 16),
      label: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: AppColors.textTertiary,
          decoration: TextDecoration.underline,
          decorationColor: AppColors.textTertiary,
        ),
      ),
    );
  }

  Future<void> _handleTap(BuildContext context, WidgetRef ref) async {
    // Capture le messenger + la localization AVANT l'await + le dismiss :
    // le context du widget peut être disposé pendant ces opérations.
    final messenger = ScaffoldMessenger.of(context);
    final loc = AppLocalizations.of(context)!;
    final notifier = ref.read(userGuidancePreferencesProvider.notifier);

    final snackMessage = switch (feature) {
      GuidanceFeature.companionSuggestions =>
        loc.guidanceOptOutCompanionSnackbar,
      GuidanceFeature.antagonistWarnings =>
        loc.guidanceOptOutAntagonistSnackbar,
    };
    final undoLabel = loc.guidanceOptOutUndo;

    // Désactive la pref correspondante.
    switch (feature) {
      case GuidanceFeature.companionSuggestions:
        await notifier.setCompanionSuggestionsEnabled(false);
      case GuidanceFeature.antagonistWarnings:
        await notifier.setAntagonistWarningsEnabled(false);
    }

    // Ferme le widget parent (sheet ou dialog).
    onDismiss();

    // Snackbar explicatif + undo.
    messenger.showSnackBar(
      SnackBar(
        content: Text(snackMessage),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: undoLabel,
          onPressed: () {
            switch (feature) {
              case GuidanceFeature.companionSuggestions:
                notifier.setCompanionSuggestionsEnabled(true);
              case GuidanceFeature.antagonistWarnings:
                notifier.setAntagonistWarningsEnabled(true);
            }
          },
        ),
      ),
    );
  }
}
