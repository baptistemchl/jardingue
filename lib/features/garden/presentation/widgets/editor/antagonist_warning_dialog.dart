import 'package:flutter/material.dart';
import 'package:jardingue/l10n/generated/app_localizations.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/companion_guidance_service.dart';
import 'guidance_opt_out_link.dart';

/// AlertDialog de confirmation avant placement d'une plante à proximité
/// d'un ou plusieurs antagonistes connus.
///
/// Retourne `true` si l'utilisateur confirme le placement, `false` s'il
/// annule ou désactive les avertissements depuis le dialog.
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
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AntagonistWarningDialog(
        sourcePlantName: sourcePlantName,
        conflicts: conflicts,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          const Text('⚠️ ', style: TextStyle(fontSize: 24)),
          Expanded(
            child: Text(
              loc.antagonistDialogTitle,
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final c in conflicts)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _formatConflict(loc, c),
                style: AppTypography.bodyMedium.copyWith(
                  height: 1.5,
                ),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            loc.antagonistDialogConfirmQuestion,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          // Lien discret pour désactiver les avertissements directement
          // depuis le dialog. Pop avec false (= annule le placement, plus
          // safe que de placer "par accident" en désactivant).
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: GuidanceOptOutLink(
                feature: GuidanceFeature.antagonistWarnings,
                onDismiss: () => Navigator.of(context).pop(false),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            loc.cancel,
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.warning,
          ),
          child: Text(
            loc.antagonistDialogPlace,
            style: AppTypography.labelLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.warning,
            ),
          ),
        ),
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
