import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/services/database/app_database.dart';
import '../../../../core/providers/database_providers.dart';

/// Sheet pour sélectionner une plante à ajouter au potager
class PlantPickerSheet extends ConsumerStatefulWidget {
  final Function(Plant plant) onPlantSelected;

  const PlantPickerSheet({super.key, required this.onPlantSelected});

  @override
  ConsumerState<PlantPickerSheet> createState() => _PlantPickerSheetState();
}

class _PlantPickerSheetState extends ConsumerState<PlantPickerSheet> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(plantsFilterProvider.notifier).setSearchQuery(value);
    });
  }

  String _getPlantEmoji(Plant plant) {
    final name = plant.commonName.toLowerCase();
    const map = {
      'tomate': '🍅',
      'carotte': '🥕',
      'salade': '🥬',
      'laitue': '🥬',
      'poivron': '🫑',
      'aubergine': '🍆',
      'courgette': '🥒',
      'concombre': '🥒',
      'haricot': '🫘',
      'petit pois': '🫛',
      'pois': '🫛',
      'radis': '🔴',
      'betterave': '🔴',
      'oignon': '🧅',
      'ail': '🧄',
      'pomme de terre': '🥔',
      'patate': '🥔',
      'chou': '🥬',
      'brocoli': '🥦',
      'épinard': '🥬',
      'fraise': '🍓',
      'framboise': '🫐',
      'myrtille': '🫐',
      'basilic': '🌿',
      'persil': '🌿',
      'menthe': '🌿',
      'thym': '🌿',
      'romarin': '🌿',
      'ciboulette': '🌿',
      'maïs': '🌽',
      'tournesol': '🌻',
      'citrouille': '🎃',
      'potiron': '🎃',
      'melon': '🍈',
      'pastèque': '🍉',
    };
    for (final entry in map.entries) {
      if (name.contains(entry.key)) return entry.value;
    }
    return '🌱';
  }

  @override
  Widget build(BuildContext context) {
    final plantsAsync = ref.watch(filteredPlantsProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Choisir une plante',
                        style: AppTypography.titleLarge,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(PhosphorIcons.x(PhosphorIconsStyle.bold)),
                    ),
                  ],
                ),
              ),

              // Barre de recherche
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Rechercher...',
                    prefixIcon: Icon(
                      PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.regular),
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),

              // Liste des plantes
              Expanded(
                child: plantsAsync.when(
                  data: (plants) {
                    if (plants.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              PhosphorIcons.plant(PhosphorIconsStyle.duotone),
                              size: 48,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Aucune plante trouvée',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: plants.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final plant = plants[index];
                        return _PlantListItem(
                          plant: plant,
                          emoji: _getPlantEmoji(plant),
                          onTap: () => widget.onPlantSelected(plant),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Erreur: $e')),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PlantListItem extends StatelessWidget {
  final Plant plant;
  final String emoji;
  final VoidCallback onTap;

  const _PlantListItem({
    required this.plant,
    required this.emoji,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // Emoji
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 12),
            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plant.commonName,
                    style: AppTypography.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (plant.latinName != null)
                    Text(
                      plant.latinName!,
                      style: AppTypography.caption.copyWith(
                        fontStyle: FontStyle.italic,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (plant.categoryLabel != null)
                        _MiniChip(label: plant.categoryLabel!),
                      if (plant.spacingBetweenPlants != null) ...[
                        const SizedBox(width: 6),
                        _MiniChip(label: '${plant.spacingBetweenPlants}cm'),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              PhosphorIcons.plus(PhosphorIconsStyle.bold),
              size: 20,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;

  const _MiniChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          fontSize: 10,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
