import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/services/database/app_database.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../core/providers/garden_providers.dart';

/// Sheet pour éditer un élément (plante ou zone)
class EditElementSheet extends ConsumerStatefulWidget {
  final GardenPlantWithDetails element;
  final Garden garden;
  final Function(double widthM, double heightM) onUpdate;
  final VoidCallback onDelete;

  const EditElementSheet({
    super.key,
    required this.element,
    required this.garden,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  ConsumerState<EditElementSheet> createState() => _EditElementSheetState();
}

class _EditElementSheetState extends ConsumerState<EditElementSheet> {
  late double _widthMeters;
  late double _heightMeters;

  @override
  void initState() {
    super.initState();
    final cellSize = widget.garden.cellSizeCm;
    _widthMeters = widget.element.widthMeters(cellSize);
    _heightMeters = widget.element.heightMeters(cellSize);
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.element;
    final isPlant = !e.isZone;
    final color = Color(e.color);
    final cellSize = widget.garden.cellSizeCm;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
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
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(e.emoji, style: const TextStyle(fontSize: 28)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.name, style: AppTypography.titleMedium),
                      if (isPlant && e.plant?.latinName != null)
                        Text(
                          e.plant!.latinName!,
                          style: AppTypography.caption.copyWith(
                            fontStyle: FontStyle.italic,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      Text(
                        'Position: (${e.xMeters(cellSize).toStringAsFixed(2)}m, ${e.yMeters(cellSize).toStringAsFixed(2)}m)',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(PhosphorIcons.x(PhosphorIconsStyle.bold)),
                ),
              ],
            ),
          ),

          const Divider(height: 24),

          // Contenu scrollable
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                // Dimensions
                Text('Dimensions', style: AppTypography.titleSmall),
                const SizedBox(height: 4),
                Text(
                  'Modifiez la taille de cet élément',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),

                _DimensionSlider(
                  label: 'Largeur',
                  value: _widthMeters,
                  max: widget.garden.widthMeters - e.xMeters(cellSize),
                  onChanged: (v) => setState(() => _widthMeters = v),
                ),
                const SizedBox(height: 16),
                _DimensionSlider(
                  label: 'Hauteur',
                  value: _heightMeters,
                  max: widget.garden.heightMeters - e.yMeters(cellSize),
                  onChanged: (v) => setState(() => _heightMeters = v),
                ),

                const SizedBox(height: 24),

                // Aperçu
                Text('Aperçu', style: AppTypography.labelMedium),
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: (_widthMeters / widget.garden.widthMeters) * 150,
                    height: (_heightMeters / widget.garden.heightMeters) * 150,
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        e.emoji,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    '${_widthMeters.toStringAsFixed(2)}m × ${_heightMeters.toStringAsFixed(2)}m',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),

                // Infos plante
                if (isPlant && e.plant != null) ...[
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text('Informations', style: AppTypography.titleSmall),
                  const SizedBox(height: 12),
                  _InfoRow(
                    label: 'Catégorie',
                    value: e.plant!.categoryLabel ?? '-',
                  ),
                  if (e.plant!.spacingBetweenPlants != null)
                    _InfoRow(
                      label: 'Espacement recommandé',
                      value: '${e.plant!.spacingBetweenPlants} cm',
                    ),
                  if (e.plant!.sunExposure != null)
                    _InfoRow(label: 'Exposition', value: e.plant!.sunExposure!),
                  if (e.plant!.watering != null)
                    _InfoRow(label: 'Arrosage', value: e.plant!.watering!),
                  if (e.plantedAt != null)
                    _InfoRow(
                      label: 'Planté le',
                      value: _formatDate(e.plantedAt!),
                    ),
                ],

                // Associations
                if (isPlant && e.plant != null) ...[
                  const SizedBox(height: 16),
                  _CompanionsSection(plantId: e.plant!.id),
                ],

                const SizedBox(height: 24),
              ],
            ),
          ),

          // Boutons actions
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                // Supprimer
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmDelete(context),
                    icon: Icon(
                      PhosphorIcons.trash(PhosphorIconsStyle.regular),
                      size: 18,
                    ),
                    label: const Text('Supprimer'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Enregistrer
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        widget.onUpdate(_widthMeters, _heightMeters),
                    icon: Icon(
                      PhosphorIcons.check(PhosphorIconsStyle.bold),
                      size: 18,
                    ),
                    label: const Text('Enregistrer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ?'),
        content: Text(
          'Voulez-vous supprimer "${widget.element.name}" du potager ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onDelete();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

class _DimensionSlider extends StatelessWidget {
  final String label;
  final double value;
  final double max;
  final Function(double) onChanged;

  const _DimensionSlider({
    required this.label,
    required this.value,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              '${value.toStringAsFixed(2)} m',
              style: AppTypography.titleSmall,
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.border,
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withValues(alpha: 0.2),
          ),
          child: Slider(
            value: value.clamp(0.1, max.clamp(0.1, 20)),
            min: 0.1,
            max: max.clamp(0.1, 20),
            divisions: ((max.clamp(0.1, 20) - 0.1) * 10).round().clamp(1, 200),
            onChanged: onChanged,
          ),
        ),
      ],
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

class _CompanionsSection extends ConsumerWidget {
  final int plantId;

  const _CompanionsSection({required this.plantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companionsAsync = ref.watch(plantCompanionsProvider(plantId));
    final antagonistsAsync = ref.watch(plantAntagonistsProvider(plantId));

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
                    const SizedBox(width: 6),
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
                      .take(8)
                      .map(
                        (c) => _CompanionChip(name: c.commonName, isGood: true),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),
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
                    const SizedBox(width: 6),
                    Text(
                      'À éviter à proximité',
                      style: AppTypography.labelMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: antagonists
                      .take(8)
                      .map(
                        (a) =>
                            _CompanionChip(name: a.commonName, isGood: false),
                      )
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
}

class _CompanionChip extends StatelessWidget {
  final String name;
  final bool isGood;

  const _CompanionChip({required this.name, required this.isGood});

  @override
  Widget build(BuildContext context) {
    final color = isGood ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(name, style: AppTypography.caption.copyWith(color: color)),
    );
  }
}
