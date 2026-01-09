import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/services/database/app_database.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../core/providers/garden_providers.dart';

/// Sheet affichant les détails d'un élément
class ElementDetailSheet extends ConsumerWidget {
  final GardenPlantWithDetails element;
  final Garden garden;
  final VoidCallback? onDelete;

  const ElementDetailSheet({
    super.key,
    required this.element,
    required this.garden,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPlant = !element.isZone;
    final color = Color(element.color);
    final cellSize = garden.cellSizeCm;

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
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
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          element.emoji,
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(element.name, style: AppTypography.titleLarge),
                          if (isPlant && element.plant?.latinName != null)
                            Text(
                              element.plant!.latinName!,
                              style: AppTypography.bodySmall.copyWith(
                                fontStyle: FontStyle.italic,
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Infos position/taille
                _InfoCard(
                  title: 'Dimensions',
                  icon: PhosphorIcons.ruler(PhosphorIconsStyle.fill),
                  children: [
                    _InfoRow(
                      label: 'Largeur',
                      value:
                          '${element.widthMeters(cellSize).toStringAsFixed(2)} m',
                    ),
                    _InfoRow(
                      label: 'Longueur',
                      value:
                          '${element.heightMeters(cellSize).toStringAsFixed(2)} m',
                    ),
                    _InfoRow(
                      label: 'Position',
                      value:
                          '(${element.xMeters(cellSize).toStringAsFixed(2)}, ${element.yMeters(cellSize).toStringAsFixed(2)}) m',
                    ),
                    if (element.plantedAt != null)
                      _InfoRow(
                        label: 'Planté le',
                        value: _formatDate(element.plantedAt!),
                      ),
                  ],
                ),

                // Infos plante
                if (isPlant && element.plant != null) ...[
                  const SizedBox(height: 16),
                  _InfoCard(
                    title: 'Culture',
                    icon: PhosphorIcons.plant(PhosphorIconsStyle.fill),
                    children: [
                      if (element.plant!.spacingBetweenPlants != null)
                        _InfoRow(
                          label: 'Espacement',
                          value: '${element.plant!.spacingBetweenPlants} cm',
                        ),
                      if (element.plant!.sunExposure != null)
                        _InfoRow(
                          label: 'Exposition',
                          value: element.plant!.sunExposure!,
                        ),
                      if (element.plant!.watering != null)
                        _InfoRow(
                          label: 'Arrosage',
                          value: element.plant!.watering!,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildCompanions(ref),
                ],

                const SizedBox(height: 24),

                // Bouton supprimer
                OutlinedButton.icon(
                  onPressed: () => _confirmDelete(context),
                  icon: Icon(PhosphorIcons.trash(PhosphorIconsStyle.regular)),
                  label: Text(
                    isPlant ? 'Retirer la plante' : 'Supprimer la zone',
                  ),
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
  }

  Widget _buildCompanions(WidgetRef ref) {
    if (element.plant == null) return const SizedBox.shrink();

    final companionsAsync = ref.watch(
      plantCompanionsProvider(element.plant!.id),
    );
    final antagonistsAsync = ref.watch(
      plantAntagonistsProvider(element.plant!.id),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        companionsAsync.when(
          data: (companions) {
            if (companions.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      PhosphorIcons.handshake(PhosphorIconsStyle.fill),
                      size: 16,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Bonnes associations',
                      style: AppTypography.labelMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: companions
                      .take(6)
                      .map((c) => _PlantChip(name: c.commonName, isGood: true))
                      .toList(),
                ),
                const SizedBox(height: 16),
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        antagonistsAsync.when(
          data: (antagonists) {
            if (antagonists.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      PhosphorIcons.prohibit(PhosphorIconsStyle.fill),
                      size: 16,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: 8),
                    Text('À éviter', style: AppTypography.labelMedium),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: antagonists
                      .take(6)
                      .map((a) => _PlantChip(name: a.commonName, isGood: false))
                      .toList(),
                ),
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ?'),
        content: Text('Voulez-vous supprimer "${element.name}" ?'),
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
            child: const Text('Supprimer'),
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
  final String name;
  final bool isGood;

  const _PlantChip({required this.name, required this.isGood});

  @override
  Widget build(BuildContext context) {
    final color = isGood ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(name, style: AppTypography.caption.copyWith(color: color)),
    );
  }
}
