import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/utils/plant_emoji_mapper.dart';
import '../../../../../core/widgets/app_bottom_sheet.dart';
import '../../../domain/companion_guidance_service.dart';

/// Résultat de la bottom sheet : ids des plantes que l'utilisateur a
/// cochées et veut ajouter au panier (en attente de placement).
typedef CompanionSuggestionResult = List<int>;

/// Bottom sheet listant les compagnons de la plante qu'on vient de poser.
/// L'utilisateur peut cocher/décocher (toutes cochées par défaut) et
/// valider pour ajouter les compagnons au panier (gridX = -1).
///
/// Le caller récupère la liste des plantIds cochés et appelle lui-même
/// `addPlantPendingPlacement` pour chacun (le widget ne fait que de l'UI).
class CompanionSuggestionsSheet extends StatefulWidget {
  final String sourcePlantName;
  final String sourcePlantEmoji;
  final List<CompanionSuggestion> suggestions;

  const CompanionSuggestionsSheet({
    super.key,
    required this.sourcePlantName,
    required this.sourcePlantEmoji,
    required this.suggestions,
  });

  static Future<CompanionSuggestionResult?> show({
    required BuildContext context,
    required String sourcePlantName,
    required String sourcePlantEmoji,
    required List<CompanionSuggestion> suggestions,
  }) {
    return AppBottomSheet.show<CompanionSuggestionResult>(
      context: context,
      child: CompanionSuggestionsSheet(
        sourcePlantName: sourcePlantName,
        sourcePlantEmoji: sourcePlantEmoji,
        suggestions: suggestions,
      ),
    );
  }

  @override
  State<CompanionSuggestionsSheet> createState() =>
      _CompanionSuggestionsSheetState();
}

class _CompanionSuggestionsSheetState extends State<CompanionSuggestionsSheet> {
  late Set<int> _checked;

  @override
  void initState() {
    super.initState();
    _checked = widget.suggestions.map((s) => s.plantId).toSet();
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
              Text(
                widget.sourcePlantEmoji,
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Compagnons de la ${widget.sourcePlantName}',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ajoute ces plantes au panier pour les placer après.',
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
        const SizedBox(height: 16),
        Flexible(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: widget.suggestions.length,
            separatorBuilder: (_, _) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              final s = widget.suggestions[index];
              final isChecked = _checked.contains(s.plantId);
              final emoji = PlantEmojiMapper.fromName(
                s.commonName,
                categoryCode: s.categoryCode,
              );
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  setState(() {
                    if (isChecked) {
                      _checked.remove(s.plantId);
                    } else {
                      _checked.add(s.plantId);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          s.commonName,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Checkbox(
                        value: isChecked,
                        onChanged: (v) {
                          setState(() {
                            if (v == true) {
                              _checked.add(s.plantId);
                            } else {
                              _checked.remove(s.plantId);
                            }
                          });
                        },
                        activeColor: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(<int>[]),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Plus tard',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _checked.isEmpty
                      ? null
                      : () => Navigator.of(context).pop(_checked.toList()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Ajouter au panier',
                    style: AppTypography.labelMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
