import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class PlanningEmptyState extends StatelessWidget {
  final VoidCallback onAddPlants;

  const PlanningEmptyState({
    super.key,
    required this.onAddPlants,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary
                    .withValues(alpha: 0.12),
                borderRadius:
                    BorderRadius.circular(24),
              ),
              child: Icon(
                PhosphorIcons.plant(
                  PhosphorIconsStyle.duotone,
                ),
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Planifiez votre potager',
              style: AppTypography.headlineMedium
                  .copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajoutez des plants pour voir '
              'les tâches à réaliser ce mois-ci, '
              'adaptées à la météo.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall
                  .copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: onAddPlants,
                icon: Icon(
                  PhosphorIcons.plus(
                    PhosphorIconsStyle.bold,
                  ),
                  size: 18,
                ),
                label: Text(
                  'Parcourir le catalogue',
                  style: AppTypography.labelLarge
                      .copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(14),
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
