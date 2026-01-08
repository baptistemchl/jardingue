import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/providers/orchard_providers.dart';

/// Carte pour un arbre fruitier de l'utilisateur
class UserFruitTreeCard extends StatelessWidget {
  final UserFruitTreeWithDetails tree;
  final VoidCallback onTap;

  const UserFruitTreeCard({super.key, required this.tree, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final healthColor = _getHealthColor(tree.healthStatus);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Emoji avec indicateur santé
            Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      tree.emoji,
                      style: const TextStyle(fontSize: 30),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: healthColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(width: 14),

            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tree.name,
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    tree.fruitTree.commonName,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (tree.variety != null)
                    Text(
                      tree.variety!,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textTertiary,
                        fontStyle: FontStyle.italic,
                        fontSize: 11,
                      ),
                    ),
                  const SizedBox(height: 6),

                  // Infos supplémentaires
                  Row(
                    children: [
                      if (tree.plantingDate != null)
                        _InfoChip(
                          icon: PhosphorIcons.calendar(
                            PhosphorIconsStyle.regular,
                          ),
                          label: _formatAge(tree.plantingDate!),
                        ),
                      if (tree.plantingDate != null && tree.location != null)
                        const SizedBox(width: 8),
                      if (tree.location != null)
                        Expanded(
                          child: _InfoChip(
                            icon: PhosphorIcons.mapPin(
                              PhosphorIconsStyle.regular,
                            ),
                            label: tree.location!,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Chevron
            Icon(
              PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
              color: AppColors.textTertiary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Color _getHealthColor(String status) {
    switch (status) {
      case 'good':
        return AppColors.success;
      case 'warning':
        return AppColors.warning;
      case 'poor':
        return AppColors.error;
      default:
        return AppColors.success;
    }
  }

  String _formatAge(DateTime plantingDate) {
    final now = DateTime.now();
    final difference = now.difference(plantingDate);
    final years = difference.inDays ~/ 365;
    final months = (difference.inDays % 365) ~/ 30;

    if (years > 0) {
      return '$years an${years > 1 ? 's' : ''}';
    } else if (months > 0) {
      return '$months mois';
    } else {
      return '${difference.inDays}j';
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.textTertiary),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textTertiary,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
