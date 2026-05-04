import 'package:flutter/material.dart';
import 'package:jardingue/l10n/generated/app_localizations.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';

/// Grille curée d'emojis pertinents pour le potager. Couvre les
/// principales catégories du `PlantEmojiMapper` plus quelques fallbacks
/// génériques. Évite d'embarquer une vraie librairie de picker emoji
/// (~5 Mo) pour un cas d'usage très restreint.
const List<String> _curatedEmojis = [
  // Légumes-fruits
  '\u{1F345}', // tomate
  '\u{1FAD1}', // poivron
  '\u{1F346}', // aubergine
  '\u{1F952}', // concombre/courgette
  '\u{1F33D}', // maïs
  // Cucurbitacées
  '\u{1F348}', // melon
  '\u{1F349}', // pastèque
  '\u{1F383}', // courge / citrouille
  // Feuilles
  '\u{1F96C}', // salade
  '\u{1F966}', // brocoli/chou-fleur
  // Racines
  '\u{1F955}', // carotte
  '\u{1F954}', // pomme de terre
  '\u{1F360}', // patate douce / betterave
  '\u{1FADC}', // radis / navet
  '\u{1FADA}', // gingembre / topinambour
  // Bulbes
  '\u{1F9C5}', // oignon / poireau
  '\u{1F9C4}', // ail
  // Légumineuses
  '\u{1FAD8}', // haricot
  '\u{1FADB}', // pois
  // Petits fruits
  '\u{1F353}', // fraise
  '\u{1FAD0}', // myrtille / framboise / cassis
  '\u{1F347}', // raisin
  '\u{1F352}', // cerise
  '\u{1F34F}', // pomme verte
  '\u{1F34E}', // pomme rouge
  '\u{1F350}', // poire
  '\u{1F351}', // pêche
  '\u{1F34A}', // orange
  '\u{1F34B}', // citron
  '\u{1F965}', // noix de coco
  '\u{1F95D}', // kiwi
  '\u{1F344}', // champignon
  '\u{1F33F}', // herbe / aromate
  // Aromates / fleurs
  '\u{1FABB}', // lavande
  '\u{1F33A}', // hibiscus / capucine
  '\u{1F338}', // fleur de cerisier / oeillet
  '\u{1F33C}', // souci / pâquerette
  '\u{1F33B}', // tournesol
  '\u{1F337}', // tulipe
  '\u{1F339}', // rose
  '\u{1F940}', // rose fanée
  // Fallbacks
  '\u{1F331}', // jeune pousse
  '\u{1F33E}', // épi
  '\u{1F490}', // bouquet
  '\u{1F33F}', // herbe
  '\u{1F343}', // feuille
  '\u{1F342}', // feuille morte
];

/// Affiche un sheet de sélection d'emoji. Renvoie l'emoji choisi ou
/// `null` si annulé. L'emoji actuellement sélectionné est mis en
/// surbrillance.
Future<String?> showUserPlantEmojiPicker({
  required BuildContext context,
  required String? currentEmoji,
}) {
  return AppBottomSheet.show<String>(
    context: context,
    heightFraction: 0.6,
    child: _EmojiPickerSheet(currentEmoji: currentEmoji),
  );
}

class _EmojiPickerSheet extends StatelessWidget {
  final String? currentEmoji;

  const _EmojiPickerSheet({required this.currentEmoji});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AppBottomSheetHandle(),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Text(
            AppLocalizations.of(context)!.userPlantEmojiPickerTitle,
            style: AppTypography.titleMedium,
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: AppSpacing.screenPadding,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: _curatedEmojis.length,
            itemBuilder: (context, index) {
              final e = _curatedEmojis[index];
              final selected = e == currentEmoji;
              return GestureDetector(
                onTap: () => Navigator.of(context).pop(e),
                child: Container(
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : AppColors.background,
                    borderRadius: AppSpacing.borderRadiusMd,
                    border: Border.all(
                      color: selected
                          ? AppColors.primary
                          : AppColors.border,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      e,
                      style: const TextStyle(fontSize: 26),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
