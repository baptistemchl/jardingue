import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/services/database/app_database.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../core/providers/garden_providers.dart';

/// Sheet affichant les détails d'une plante placée dans le potager
class GardenPlantDetailSheet extends ConsumerWidget {
  final GardenPlantWithDetails plantWithDetails;
  final int gardenId;
  final VoidCallback? onDelete;

  const GardenPlantDetailSheet({
    super.key,
    required this.plantWithDetails,
    required this.gardenId,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plant = plantWithDetails.plant;
    final companionsAsync = ref.watch(plantCompanionsProvider(plant!.id));
    final antagonistsAsync = ref.watch(plantAntagonistsProvider(plant.id));

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

              // Contenu scrollable
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Header plante
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              plantWithDetails.emoji,
                              style: const TextStyle(fontSize: 40),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                plant.commonName,
                                style: AppTypography.titleLarge,
                              ),
                              if (plant.latinName != null)
                                Text(
                                  plant.latinName!,
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontStyle: FontStyle.italic,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              const SizedBox(height: 8),
                              if (plant.categoryLabel != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    plant.categoryLabel!,
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Position dans le potager
                    _InfoCard(
                      title: 'Position',
                      icon: PhosphorIcons.mapPin(PhosphorIconsStyle.fill),
                      children: [
                        _InfoRow(
                          label: 'Coordonnées',
                          value:
                              '(${plantWithDetails.gridX}, ${plantWithDetails.gridY})',
                        ),
                        _InfoRow(
                          label: 'Taille',
                          value:
                              '${plantWithDetails.widthCells} × ${plantWithDetails.heightCells} cellules',
                        ),
                        if (plantWithDetails.plantedAt != null)
                          _InfoRow(
                            label: 'Planté le',
                            value: _formatDate(plantWithDetails.plantedAt!),
                          ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Culture
                    _InfoCard(
                      title: 'Culture',
                      icon: PhosphorIcons.plant(PhosphorIconsStyle.fill),
                      children: [
                        if (plant.spacingBetweenPlants != null)
                          _InfoRow(
                            label: 'Espacement',
                            value: '${plant.spacingBetweenPlants} cm',
                          ),
                        if (plant.plantingDepthCm != null)
                          _InfoRow(
                            label: 'Profondeur',
                            value: '${plant.plantingDepthCm} cm',
                          ),
                        if (plant.sunExposure != null)
                          _InfoRow(
                            label: 'Exposition',
                            value: plant.sunExposure!,
                          ),
                        if (plant.watering != null)
                          _InfoRow(label: 'Arrosage', value: plant.watering!),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Récolte
                    if (plant.harvestPeriod != null)
                      _InfoCard(
                        title: 'Récolte',
                        icon: PhosphorIcons.basket(PhosphorIconsStyle.fill),
                        children: [
                          _InfoRow(
                            label: 'Période',
                            value: plant.harvestPeriod!,
                          ),
                        ],
                      ),

                    const SizedBox(height: 16),

                    // Compagnons
                    companionsAsync.when(
                      data: (companions) {
                        if (companions.isEmpty) return const SizedBox.shrink();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  PhosphorIcons.handshake(
                                    PhosphorIconsStyle.fill,
                                  ),
                                  size: 18,
                                  color: AppColors.success,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Bonnes associations',
                                  style: AppTypography.titleSmall,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: companions
                                  .map(
                                    (c) => _PlantChip(plant: c, isGood: true),
                                  )
                                  .toList(),
                            ),
                            const SizedBox(height: 16),
                          ],
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),

                    // Antagonistes
                    antagonistsAsync.when(
                      data: (antagonists) {
                        if (antagonists.isEmpty) return const SizedBox.shrink();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  PhosphorIcons.prohibit(
                                    PhosphorIconsStyle.fill,
                                  ),
                                  size: 18,
                                  color: AppColors.error,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'À éviter',
                                  style: AppTypography.titleSmall,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: antagonists
                                  .map(
                                    (a) => _PlantChip(plant: a, isGood: false),
                                  )
                                  .toList(),
                            ),
                            const SizedBox(height: 16),
                          ],
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),

                    // Notes
                    if (plantWithDetails.notes != null &&
                        plantWithDetails.notes!.isNotEmpty)
                      _InfoCard(
                        title: 'Notes',
                        icon: PhosphorIcons.notepad(PhosphorIconsStyle.fill),
                        children: [
                          Text(
                            plantWithDetails.notes!,
                            style: AppTypography.bodyMedium,
                          ),
                        ],
                      ),

                    const SizedBox(height: 24),

                    // Bouton supprimer
                    OutlinedButton.icon(
                      onPressed: () => _confirmDelete(context),
                      icon: Icon(
                        PhosphorIcons.trash(PhosphorIconsStyle.regular),
                      ),
                      label: const Text('Retirer du potager'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Retirer cette plante ?'),
        content: Text(
          'Voulez-vous vraiment retirer "${plantWithDetails.name}" du potager ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDelete?.call();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _InfoCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(title, style: AppTypography.titleSmall),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlantChip extends StatelessWidget {
  final Plant plant;
  final bool isGood;

  const _PlantChip({required this.plant, required this.isGood});

  String get _emoji {
    final name = plant.commonName.toLowerCase();
    const map = {
      'tomate': '🍅',
      'carotte': '🥕',
      'salade': '🥬',
      'laitue': '🥬',
      'poivron': '🫑',
      'aubergine': '🍆',
      'courgette': '🥒',
      'oignon': '🧅',
      'ail': '🧄',
      'pomme de terre': '🥔',
      'chou': '🥬',
      'brocoli': '🥦',
      'fraise': '🍓',
      'basilic': '🌿',
      'persil': '🌿',
      'menthe': '🌿',
    };
    for (final entry in map.entries) {
      if (name.contains(entry.key)) return entry.value;
    }
    return '🌱';
  }

  @override
  Widget build(BuildContext context) {
    final color = isGood ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            plant.commonName,
            style: AppTypography.labelSmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
