import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

const _prefKey = 'calendar_onboarding_dismissed';

/// Affiche le dialogue d'aide du calendrier.
/// Appelé automatiquement au premier lancement
/// ou manuellement via le bouton "?".
Future<void> showCalendarOnboarding(
  BuildContext context,
) {
  return showDialog(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => const _OnboardingDialog(),
  );
}

/// Vérifie si l'onboarding doit être affiché
/// et l'affiche si c'est le premier lancement.
Future<void> maybeShowCalendarOnboarding(
  BuildContext context,
) async {
  final prefs =
      await SharedPreferences.getInstance();
  final dismissed =
      prefs.getBool(_prefKey) ?? false;

  if (!dismissed && context.mounted) {
    // Petit délai pour laisser le screen se build
    await Future.delayed(
      const Duration(milliseconds: 500),
    );
    if (context.mounted) {
      await showCalendarOnboarding(context);
      await prefs.setBool(_prefKey, true);
    }
  }
}

class _OnboardingDialog extends StatelessWidget {
  const _OnboardingDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 40,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.info
                        .withValues(alpha: 0.12),
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: Icon(
                    PhosphorIcons.lightbulb(
                      PhosphorIconsStyle.fill,
                    ),
                    size: 22,
                    color: AppColors.info,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Guide du calendrier',
                    style: AppTypography
                        .titleMedium
                        .copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Étapes
            const _Step(
              emoji: '📅',
              title: 'Vue calendrier',
              text: 'Les points de couleur '
                  'montrent les activités '
                  'possibles ce mois-ci.',
            ),
            const SizedBox(height: 12),
            const _Step(
              emoji: '📋',
              title: 'Vue liste',
              text: 'Toutes les activités '
                  'groupées par type : '
                  'semis, plantation, récolte.',
            ),
            const SizedBox(height: 12),
            const _Step(
              emoji: '🌱',
              title: 'Filtrer par plant',
              text: 'Sélectionnez un plant '
                  'pour ne voir que ses '
                  'périodes.',
            ),
            const SizedBox(height: 12),
            const _Step(
              emoji: '👆',
              title: 'Ajouter un événement',
              text: 'Appuyez sur un jour '
                  'pour enregistrer une action '
                  '(semis, arrosage...).',
            ),
            const SizedBox(height: 12),
            const _Step(
              emoji: '📝',
              title: 'Mon suivi',
              text: 'Retrouvez l\'historique '
                  'de toutes vos actions '
                  'enregistrées.',
            ),

            const SizedBox(height: 24),

            // Bouton fermer
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'C\'est compris !',
                  style: AppTypography.labelLarge
                      .copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String emoji;
  final String title;
  final String text;

  const _Step({
    required this.emoji,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.labelMedium
                    .copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                text,
                style: AppTypography.caption
                    .copyWith(
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
