import 'package:flutter/material.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/glass_decoration.dart';
import '../../data/models/{{name.snakeCase()}}_model.dart';

/// Carte pour afficher un élément {{name.pascalCase()}}
class {{name.pascalCase()}}Card extends StatelessWidget {
  final {{name.pascalCase()}}Model item;
  final VoidCallback? onTap;

  const {{name.pascalCase()}}Card({
    super.key,
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      child: Row(
        children: [
          // TODO: Ajouter l'icône ou l'image
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: AppTypography.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'ID: ${item.id}',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
