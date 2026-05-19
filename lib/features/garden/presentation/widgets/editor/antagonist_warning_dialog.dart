import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/companion_guidance_service.dart';

/// AlertDialog de confirmation avant placement d'une plante à proximité
/// d'un ou plusieurs antagonistes connus.
///
/// Retourne `true` si l'utilisateur confirme le placement, `false` s'il
/// annule. Le caller doit interpréter le résultat et ne pas écrire en
/// base si annulé.
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
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          const Text('⚠️ ', style: TextStyle(fontSize: 24)),
          Expanded(
            child: Text(
              'Incompatibilité détectée',
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
                _formatConflict(c),
                style: AppTypography.bodyMedium.copyWith(
                  height: 1.5,
                ),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'Placer quand même ?',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'Annuler',
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
            'Placer',
            style: AppTypography.labelLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.warning,
            ),
          ),
        ),
      ],
    );
  }

  String _formatConflict(AntagonistConflict c) {
    final reason = c.reason;
    if (reason != null && reason.isNotEmpty) {
      return '$sourcePlantName et ${c.neighborPlantName} partagent $reason.';
    }
    return '$sourcePlantName et ${c.neighborPlantName} ne s\'aiment pas.';
  }
}
