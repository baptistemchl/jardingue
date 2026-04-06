import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/providers/calendar_providers.dart';

// ============================================
// ÉTATS VIDES
// ============================================

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🌱', style: TextStyle(fontSize: 36)),
              ),
            ),
            const SizedBox(height: 20),
            Text('Aucune activité ce mois', style: AppTypography.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Ajoutez des plantes à votre potager pour voir les activités recommandées',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyStateForType extends StatelessWidget {
  final GardenActivityType type;

  const EmptyStateForType({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(type.emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              'Pas de ${type.label.toLowerCase()}',
              style: AppTypography.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Aucune ${type.label.toLowerCase()} ce mois',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
