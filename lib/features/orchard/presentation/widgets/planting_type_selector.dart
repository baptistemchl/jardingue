import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/planting_type.dart';

/// Sélecteur à choix unique pour le type de plantation d'un arbre.
///
/// Affiche 3 [ChoiceChip] côte à côte. Quand l'arbre n'est pas
/// `containerSuitable` et que l'utilisateur sélectionne [PlantingType.pot],
/// un avertissement discret apparaît sous le sélecteur — l'option reste
/// cliquable (on ne bride pas l'utilisateur).
class PlantingTypeSelector extends StatelessWidget {
  final PlantingType selected;
  final ValueChanged<PlantingType> onChanged;
  final bool containerSuitable;
  final double? heightAdultM;

  const PlantingTypeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.containerSuitable = true,
    this.heightAdultM,
  });

  String _potWarningMessage() {
    final h = heightAdultM;
    if (h == null) {
      return 'Cet arbre tolère mal la culture en pot.';
    }
    return 'Cet arbre tolère mal la culture en pot (taille adulte ~${h.toStringAsFixed(0)} m).';
  }

  @override
  Widget build(BuildContext context) {
    final showWarning =
        selected == PlantingType.pot && !containerSuitable;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: PlantingType.values.map((t) {
            final isSelected = t == selected;
            return ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(t.emoji, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(t.label),
                ],
              ),
              selected: isSelected,
              onSelected: (_) => onChanged(t),
              backgroundColor: AppColors.background,
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
              labelStyle: AppTypography.labelSmall.copyWith(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textSecondary,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
              side: BorderSide(
                color:
                    isSelected ? AppColors.primary : AppColors.border,
              ),
            );
          }).toList(),
        ),
        if (showWarning) ...[
          const SizedBox(height: 8),
          Text(
            _potWarningMessage(),
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}
