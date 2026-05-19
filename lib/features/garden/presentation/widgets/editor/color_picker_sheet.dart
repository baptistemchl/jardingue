import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/app_bottom_sheet.dart';

/// Palette de 12 couleurs nature proposées à l'utilisateur. Chacune
/// correspond à un usage potager (vert feuille, marron tubercule, rouge
/// fruit, etc.). L'ordre est pensé pour le rendu en grille 4×3.
const _palette = <_Swatch>[
  _Swatch(0xFF4CAF50, 'Vert feuille'),
  _Swatch(0xFF8BC34A, 'Vert clair'),
  _Swatch(0xFF388E3C, 'Vert foncé'),
  _Swatch(0xFF009688, 'Vert aromate'),
  _Swatch(0xFFF44336, 'Rouge tomate'),
  _Swatch(0xFFE91E63, 'Rose fruit'),
  _Swatch(0xFFFF9800, 'Orange racine'),
  _Swatch(0xFFFBC02D, 'Jaune soleil'),
  _Swatch(0xFF795548, 'Marron terre'),
  _Swatch(0xFF9C27B0, 'Violet allium'),
  _Swatch(0xFF7E57C2, 'Mauve fleur'),
  _Swatch(0xFF607D8B, 'Ardoise zone'),
];

class _Swatch {
  final int color;
  final String label;
  const _Swatch(this.color, this.label);
}

/// Bottom sheet de sélection d'une couleur personnalisée pour un pied
/// placé. Affiche une palette de 12 couleurs nature + un bouton pour
/// revenir à la couleur déduite de la catégorie.
///
/// Retourne :
/// - `int` (ARGB) si une couleur a été choisie
/// - `null` si l'utilisateur reset (= retour catégorie)
/// - Aucun retour (dismiss) si annulé
class ColorPickerSheet extends StatelessWidget {
  final String plantName;
  final String plantEmoji;
  final int currentColor;
  final bool hasCustomColor;

  const ColorPickerSheet({
    super.key,
    required this.plantName,
    required this.plantEmoji,
    required this.currentColor,
    required this.hasCustomColor,
  });

  static Future<ColorPickResult?> show({
    required BuildContext context,
    required String plantName,
    required String plantEmoji,
    required int currentColor,
    required bool hasCustomColor,
  }) {
    return AppBottomSheet.show<ColorPickResult>(
      context: context,
      child: ColorPickerSheet(
        plantName: plantName,
        plantEmoji: plantEmoji,
        currentColor: currentColor,
        hasCustomColor: hasCustomColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppBottomSheetHandle(),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Color(currentColor).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Color(currentColor),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    plantEmoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plantName,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choisissez une couleur pour distinguer ce pied.',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.05,
            ),
            itemCount: _palette.length,
            itemBuilder: (context, index) {
              final swatch = _palette[index];
              final isSelected =
                  hasCustomColor && swatch.color == currentColor;
              return _SwatchTile(
                color: swatch.color,
                label: swatch.label,
                selected: isSelected,
                onTap: () => Navigator.of(context)
                    .pop(ColorPickResult.color(swatch.color)),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        if (hasCustomColor)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () => Navigator.of(context)
                    .pop(const ColorPickResult.reset()),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(
                  'Couleur par défaut (catégorie)',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 4),
      ],
    );
  }
}

/// Résultat du picker : soit une couleur choisie, soit un reset à la
/// catégorie. Permet de différencier le cas "ne rien faire" (null
/// retourné par la sheet dismiss) du cas "reset volontaire".
class ColorPickResult {
  final int? color;
  final bool isReset;
  const ColorPickResult.color(this.color) : isReset = false;
  const ColorPickResult.reset()
      : color = null,
        isReset = true;
}

class _SwatchTile extends StatelessWidget {
  final int color;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SwatchTile({
    required this.color,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: Color(color).withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? Color(color)
                  : Color(color).withValues(alpha: 0.4),
              width: selected ? 3 : 1,
            ),
          ),
          child: Stack(
            children: [
              if (selected)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Color(color),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              Center(
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Color(color),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(color).withValues(alpha: 0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
