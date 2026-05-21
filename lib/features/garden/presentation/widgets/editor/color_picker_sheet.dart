import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:jardingue/l10n/generated/app_localizations.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/app_bottom_sheet.dart';

/// Palette de 30 couleurs nature, groupées par teinte (6×5) :
/// verts → rouges/roses → oranges/jaunes → terres → bleus/violets →
/// neutres. Pour les choix précis hors palette, l'utilisateur passe par
/// le bouton « Couleur personnalisée » qui ouvre une roue HSV +
/// champ hex (flex_color_picker).
const _palette = <int>[
  // Verts (6)
  0xFF4CAF50, 0xFF8BC34A, 0xFF2E7D32, 0xFF009688, 0xFF689F38, 0xFFCDDC39,
  // Rouges & roses (5)
  0xFFE53935, 0xFFC2185B, 0xFFFF7043, 0xFFE91E63, 0xFFAD1457,
  // Oranges & jaunes (5)
  0xFFFF9800, 0xFFFFB74D, 0xFFFBC02D, 0xFFD4A017, 0xFFB8860B,
  // Marrons & terres (5)
  0xFF6D4C41, 0xFF795548, 0xFFBCAAA4, 0xFFD7CCC8, 0xFF5D4037,
  // Bleus & violets (5)
  0xFF3F51B5, 0xFF9575CD, 0xFF7B1FA2, 0xFFBA68C8, 0xFF311B92,
  // Neutres (4)
  0xFF455A64, 0xFF424242, 0xFFFAFAFA, 0xFF212121,
];

/// Bottom sheet de sélection d'une couleur personnalisée pour un pied
/// placé. Propose une palette curée de 30 couleurs jardinage + un
/// bouton « Couleur personnalisée » qui ouvre une roue HSV pour les
/// 16 millions de couleurs restantes.
///
/// Retourne :
/// - `ColorPickResult.color(int)` si une couleur a été choisie
/// - `ColorPickResult.reset()` si reset (= retour catégorie)
/// - `null` si dismiss/annulé
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
    final loc = AppLocalizations.of(context)!;
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
                      loc.colorPickerSubtitle,
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
              crossAxisCount: 6,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.0,
            ),
            itemCount: _palette.length,
            itemBuilder: (context, index) {
              final swatchColor = _palette[index];
              final isSelected =
                  hasCustomColor && swatchColor == currentColor;
              return _SwatchTile(
                color: swatchColor,
                selected: isSelected,
                onTap: () => Navigator.of(context)
                    .pop(ColorPickResult.color(swatchColor)),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        // Bouton « Couleur personnalisée » → roue HSV / hex
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openCustomPicker(context),
              icon: const Icon(Icons.colorize, size: 18),
              label: Text(
                loc.colorPickerCustom,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.5),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
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
                  loc.colorPickerReset,
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

  /// Ouvre la roue HSV de flex_color_picker dans un AlertDialog
  /// localisé. Au tap "Appliquer", on pop la sheet courante avec la
  /// couleur retenue.
  Future<void> _openCustomPicker(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;
    Color picked = Color(currentColor);

    final confirmed = await ColorPicker(
      color: picked,
      onColorChanged: (c) => picked = c,
      // Active la roue HSV + champ hex pour des choix précis.
      pickersEnabled: const {
        ColorPickerType.primary: false,
        ColorPickerType.accent: false,
        ColorPickerType.wheel: true,
      },
      enableShadesSelection: true,
      showColorCode: true,
      colorCodeHasColor: true,
      width: 36,
      height: 36,
      borderRadius: 18,
      heading: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          loc.colorPickerCustomDialogTitle,
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ).showPickerDialog(
      context,
      constraints: const BoxConstraints(
        minHeight: 480,
        minWidth: 320,
        maxWidth: 340,
      ),
    );

    if (!confirmed) return;
    if (!context.mounted) return;
    Navigator.of(context).pop(
      // ignore: deprecated_member_use
      ColorPickResult.color(picked.value),
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
  final bool selected;
  final VoidCallback onTap;

  const _SwatchTile({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: Color(color).withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(12),
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
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Color(color),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
              Center(
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Color(color),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(color).withValues(alpha: 0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
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
