import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/services/database/app_database.dart';
import '../../../../core/providers/database_providers.dart';

/// Types d'éléments pouvant être placés dans le potager
enum GardenElementType {
  plant('Plante', '🌱', PhosphorIconsFill.plant, AppColors.primary),
  row('Rang', '📏', PhosphorIconsFill.rows, Color(0xFF2196F3)),
  zone('Zone', '⬛', PhosphorIconsFill.squaresFour, Color(0xFF9C27B0)),
  greenhouse('Serre', '🏠', PhosphorIconsFill.house, Color(0xFFFF9800)),
  path('Allée', '🚶', PhosphorIconsFill.path, Color(0xFF607D8B)),
  water('Point d\'eau', '💧', PhosphorIconsFill.drop, Color(0xFF03A9F4)),
  compost('Compost', '♻️', PhosphorIconsFill.recycle, Color(0xFF795548));

  final String label;
  final String emoji;
  final IconData icon;
  final Color color;

  const GardenElementType(this.label, this.emoji, this.icon, this.color);
}

/// Sheet pour sélectionner le type d'élément à placer
class ElementTypePickerSheet extends StatelessWidget {
  final Function(GardenElementType type) onTypeSelected;

  const ElementTypePickerSheet({super.key, required this.onTypeSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text('Que souhaitez-vous ajouter ?', style: AppTypography.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Choisissez le type d\'élément à placer',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1,
            children: GardenElementType.values.map((type) {
              return GestureDetector(
                onTap: () => onTypeSelected(type),
                child: Container(
                  decoration: BoxDecoration(
                    color: type.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: type.color.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(type.emoji, style: const TextStyle(fontSize: 28)),
                      const SizedBox(height: 8),
                      Text(
                        type.label,
                        style: AppTypography.labelSmall.copyWith(
                          color: type.color,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Sheet pour configurer un rang de culture
class RowConfigSheet extends ConsumerStatefulWidget {
  final Function(int length, bool isHorizontal, Plant? plant) onConfirm;

  const RowConfigSheet({super.key, required this.onConfirm});

  @override
  ConsumerState<RowConfigSheet> createState() => _RowConfigSheetState();
}

class _RowConfigSheetState extends ConsumerState<RowConfigSheet> {
  int _length = 5;
  bool _isHorizontal = true;
  Plant? _selectedPlant;

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
      'chou': '🥬',
      'brocoli': '🥦',
      'épinard': '🥬',
      'fraise': '🍓',
      'basilic': '🌿',
      'persil': '🌿',
      'menthe': '🌿',
      'maïs': '🌽',
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
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Text('📏', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Text('Créer un rang', style: AppTypography.titleLarge),
                  ],
                ),
              ),
              const Divider(height: 24),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    Text('Plante', style: AppTypography.labelMedium),
                    const SizedBox(height: 8),
                    if (_selectedPlant != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Text(
                              _getPlantEmoji(_selectedPlant!),
                              style: const TextStyle(fontSize: 32),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedPlant!.commonName,
                                    style: AppTypography.titleSmall,
                                  ),
                                  if (_selectedPlant!.latinName != null)
                                    Text(
                                      _selectedPlant!.latinName!,
                                      style: AppTypography.caption.copyWith(
                                        fontStyle: FontStyle.italic,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  setState(() => _selectedPlant = null),
                              icon: Icon(
                                PhosphorIcons.x(PhosphorIconsStyle.bold),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      plantsAsync.when(
                        data: (plants) => SizedBox(
                          height: 100,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: plants.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final plant = plants[index];
                              return GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedPlant = plant),
                                child: Container(
                                  width: 80,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _getPlantEmoji(plant),
                                        style: const TextStyle(fontSize: 28),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        plant.commonName,
                                        style: AppTypography.caption,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Text('Erreur: $e'),
                      ),
                    const SizedBox(height: 24),
                    Text('Nombre de plantes', style: AppTypography.labelMedium),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _length > 1
                              ? () => setState(() => _length--)
                              : null,
                          icon: Icon(
                            PhosphorIcons.minus(PhosphorIconsStyle.bold),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$_length',
                              style: AppTypography.titleLarge,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(() => _length++),
                          icon: Icon(
                            PhosphorIcons.plus(PhosphorIconsStyle.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text('Orientation', style: AppTypography.labelMedium),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _OrientationButton(
                            label: 'Horizontal',
                            icon: PhosphorIcons.arrowsHorizontal(
                              PhosphorIconsStyle.bold,
                            ),
                            isSelected: _isHorizontal,
                            onTap: () => setState(() => _isHorizontal = true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _OrientationButton(
                            label: 'Vertical',
                            icon: PhosphorIcons.arrowsVertical(
                              PhosphorIconsStyle.bold,
                            ),
                            isSelected: !_isHorizontal,
                            onTap: () => setState(() => _isHorizontal = false),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _selectedPlant == null
                          ? null
                          : () => widget.onConfirm(
                              _length,
                              _isHorizontal,
                              _selectedPlant,
                            ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        disabledBackgroundColor: AppColors.border,
                      ),
                      child: Text(
                        _selectedPlant == null
                            ? 'Sélectionnez une plante'
                            : 'Créer le rang',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OrientationButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _OrientationButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sheet pour configurer une zone
class ZoneConfigSheet extends StatefulWidget {
  final GardenElementType zoneType;
  final Function(int width, int height) onConfirm;

  const ZoneConfigSheet({
    super.key,
    required this.zoneType,
    required this.onConfirm,
  });

  @override
  State<ZoneConfigSheet> createState() => _ZoneConfigSheetState();
}

class _ZoneConfigSheetState extends State<ZoneConfigSheet> {
  int _width = 3;
  int _height = 3;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(widget.zoneType.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Text(
                'Configurer ${widget.zoneType.label.toLowerCase()}',
                style: AppTypography.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _DimensionInput(
                  label: 'Largeur',
                  value: _width,
                  onChanged: (v) => setState(() => _width = v),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _DimensionInput(
                  label: 'Hauteur',
                  value: _height,
                  onChanged: (v) => setState(() => _height = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Container(
              width: _width * 20.0,
              height: _height * 20.0,
              decoration: BoxDecoration(
                color: widget.zoneType.color.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: widget.zoneType.color, width: 2),
              ),
              child: Center(
                child: Text(
                  widget.zoneType.emoji,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => widget.onConfirm(_width, _height),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.zoneType.color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text('Créer ${widget.zoneType.label.toLowerCase()}'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _DimensionInput extends StatelessWidget {
  final String label;
  final int value;
  final Function(int) onChanged;

  const _DimensionInput({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            GestureDetector(
              onTap: value > 1 ? () => onChanged(value - 1) : null,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: value > 1 ? AppColors.surface : AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  PhosphorIcons.minus(PhosphorIconsStyle.bold),
                  size: 16,
                  color: value > 1
                      ? AppColors.textPrimary
                      : AppColors.textTertiary,
                ),
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$value',
                  style: AppTypography.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => onChanged(value + 1),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  PhosphorIcons.plus(PhosphorIconsStyle.bold),
                  size: 16,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
