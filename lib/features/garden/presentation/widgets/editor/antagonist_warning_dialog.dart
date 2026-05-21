import 'package:flutter/material.dart';
import 'package:jardingue/l10n/generated/app_localizations.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/app_bottom_sheet.dart';
import '../../../domain/companion_guidance_service.dart';
import 'guidance_opt_out_link.dart';

/// Bottom sheet d'avertissement avant placement d'une plante à
/// proximité d'un ou plusieurs antagonistes connus.
///
/// Retourne `true` si l'utilisateur confirme le placement, `false` s'il
/// annule, désactive la fonctionnalité ou ferme la sheet. Le caller doit
/// ne pas écrire en base si le résultat est false.
///
/// Le nom de la classe garde « Dialog » pour ne pas casser tous les
/// callers existants ; sous le capot c'est désormais un AppBottomSheet.
class AntagonistWarningDialog extends StatelessWidget {
  final String sourcePlantName;
  final List<AntagonistConflict> conflicts;

  const AntagonistWarningDialog({
    super.key,
    required this.sourcePlantName,
    required this.conflicts,
  });

  static Future<bool> show({
    required BuildContext context,
    required String sourcePlantName,
    required List<AntagonistConflict> conflicts,
  }) async {
    final result = await AppBottomSheet.show<bool>(
      context: context,
      child: AntagonistWarningDialog(
        sourcePlantName: sourcePlantName,
        conflicts: conflicts,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppBottomSheetHandle(),
        const SizedBox(height: 8),
        // Icône warning grosse, en cercle teinté
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            PhosphorIcons.warning(PhosphorIconsStyle.fill),
            size: 36,
            color: AppColors.warning,
          ),
        ),
        const SizedBox(height: 16),
        // Titre centré
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            loc.antagonistDialogTitle,
            textAlign: TextAlign.center,
            style: AppTypography.titleLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Liste des conflits, chaque conflit dans sa carte douce
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              for (final c in conflicts)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      _formatConflict(loc, c),
                      style: AppTypography.bodyMedium.copyWith(
                        height: 1.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            loc.antagonistDialogConfirmQuestion,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Boutons côte à côte, pleine largeur
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    loc.cancel,
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    loc.antagonistDialogPlace,
                    style: AppTypography.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // Lien discret pour désactiver. Pop avec false (= annule le
        // placement, plus safe que de placer "par accident" en
        // désactivant).
        GuidanceOptOutLink(
          feature: GuidanceFeature.antagonistWarnings,
          onDismiss: () => Navigator.of(context).pop(false),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  String _formatConflict(AppLocalizations loc, AntagonistConflict c) {
    final reason = c.reason;
    if (reason != null && reason.isNotEmpty) {
      return loc.antagonistConflictWithReason(
        sourcePlantName,
        c.neighborPlantName,
        reason,
      );
    }
    return loc.antagonistConflictGeneric(
      sourcePlantName,
      c.neighborPlantName,
    );
  }
}
