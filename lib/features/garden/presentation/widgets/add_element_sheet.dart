import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/services/database/app_database.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../core/providers/garden_providers.dart';

/// Sheet pour ajouter un élément (plante ou zone)
class AddElementSheet extends ConsumerStatefulWidget {
  final Garden garden;
  final Function(int plantId, double widthM, double heightM) onPlantAdded;
  final Function(ZoneType zoneType, double widthM, double heightM) onZoneAdded;

  const AddElementSheet({
    super.key,
    required this.garden,
    required this.onPlantAdded,
    required this.onZoneAdded,
  });

  @override
  ConsumerState<AddElementSheet> createState() => _AddElementSheetState();
}

class _AddElementSheetState extends ConsumerState<AddElementSheet> {
  int _step = 0; // 0 = choix type, 1 = config plante, 2 = config zone
  Plant? _selectedPlant;
  ZoneType? _selectedZone;

  // Dimensions en centimètres
  int _widthCm = 30;
  int _heightCm = 30;

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

  void _selectPlant(Plant plant) {
    setState(() {
      _selectedPlant = plant;
      if (plant.spacingBetweenPlants != null &&
          plant.spacingBetweenPlants! > 0) {
        _widthCm = plant.spacingBetweenPlants!.clamp(10, 200);
        _heightCm = plant.spacingBetweenPlants!.clamp(10, 200);
      } else {
        _widthCm = 30;
        _heightCm = 30;
      }
      _step = 1;
    });
  }

  void _selectZone(ZoneType zone) {
    setState(() {
      _selectedZone = zone;
      _widthCm = 100;
      _heightCm = 100;
      _step = 2;
    });
  }

  void _confirm() {
    final widthM = _widthCm / 100.0;
    final heightM = _heightCm / 100.0;

    if (_step == 1 && _selectedPlant != null) {
      widget.onPlantAdded(_selectedPlant!.id, widthM, heightM);
    } else if (_step == 2 && _selectedZone != null) {
      widget.onZoneAdded(_selectedZone!, widthM, heightM);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
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
                if (_step > 0)
                  IconButton(
                    onPressed: () => setState(() => _step = 0),
                    icon: Icon(
                      PhosphorIcons.arrowLeft(PhosphorIconsStyle.bold),
                    ),
                  ),
                Expanded(
                  child: Text(
                    _step == 0
                        ? 'Ajouter un élément'
                        : (_step == 1
                              ? 'Configurer la plante'
                              : 'Configurer la zone'),
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

          const Divider(),

          // Contenu
          Expanded(
            child: _step == 0 ? _buildTypeSelection() : _buildConfiguration(),
          ),

          // Bouton confirmer
          if (_step > 0)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _confirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('Ajouter (${_widthCm}cm × ${_heightCm}cm)'),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTypeSelection() {
    final plantsAsync = ref.watch(filteredPlantsProvider);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Plantes', style: AppTypography.titleMedium),
        const SizedBox(height: 8),
        TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Rechercher une plante...',
            prefixIcon: Icon(
              PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.regular),
            ),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        plantsAsync.when(
          data: (plants) {
            if (plants.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    'Aucune plante trouvée',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }
            return SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: plants.length.clamp(0, 20),
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final plant = plants[index];
                  return _PlantCard(
                    plant: plant,
                    onTap: () => _selectPlant(plant),
                  );
                },
              ),
            );
          },
          loading: () => const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text('Erreur: $e'),
        ),

        const SizedBox(height: 32),

        Text('Zones spéciales', style: AppTypography.titleMedium),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1,
          children: ZoneType.values.map((zone) {
            return _ZoneCard(zone: zone, onTap: () => _selectZone(zone));
          }).toList(),
        ),

        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildConfiguration() {
    final isPlant = _step == 1;
    final emoji = isPlant
        ? _getPlantEmoji(_selectedPlant!)
        : _selectedZone!.emoji;
    final name = isPlant ? _selectedPlant!.commonName : _selectedZone!.label;
    final color = isPlant ? AppColors.primary : Color(_selectedZone!.color);

    final maxWidthCm = (widget.garden.widthMeters * 100).round().clamp(10, 500);
    final maxHeightCm = (widget.garden.heightMeters * 100).round().clamp(
      10,
      500,
    );

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Element sélectionné
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppTypography.titleSmall),
                    if (isPlant && _selectedPlant!.latinName != null)
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
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Aperçu adaptatif
        _AdaptivePreview(
          emoji: emoji,
          color: color,
          widthCm: _widthCm,
          heightCm: _heightCm,
        ),

        const SizedBox(height: 20),

        // Tailles rapides
        Text('Tailles rapides', style: AppTypography.labelMedium),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _QuickSizeChip(
                label: '10cm',
                selected: _widthCm == 10,
                onTap: () => setState(() {
                  _widthCm = 10;
                  _heightCm = 10;
                }),
              ),
              const SizedBox(width: 8),
              _QuickSizeChip(
                label: '20cm',
                selected: _widthCm == 20,
                onTap: () => setState(() {
                  _widthCm = 20;
                  _heightCm = 20;
                }),
              ),
              const SizedBox(width: 8),
              _QuickSizeChip(
                label: '30cm',
                selected: _widthCm == 30,
                onTap: () => setState(() {
                  _widthCm = 30;
                  _heightCm = 30;
                }),
              ),
              const SizedBox(width: 8),
              _QuickSizeChip(
                label: '50cm',
                selected: _widthCm == 50,
                onTap: () => setState(() {
                  _widthCm = 50;
                  _heightCm = 50;
                }),
              ),
              const SizedBox(width: 8),
              _QuickSizeChip(
                label: '1m',
                selected: _widthCm == 100,
                onTap: () => setState(() {
                  _widthCm = 100;
                  _heightCm = 100;
                }),
              ),
              const SizedBox(width: 8),
              _QuickSizeChip(
                label: '2m',
                selected: _widthCm == 200,
                onTap: () => setState(() {
                  _widthCm = 200;
                  _heightCm = 200;
                }),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Sliders
        _DimensionSliderCm(
          label: 'Largeur',
          valueCm: _widthCm,
          maxCm: maxWidthCm,
          onChanged: (v) => setState(() => _widthCm = v),
        ),
        const SizedBox(height: 12),
        _DimensionSliderCm(
          label: 'Longueur',
          valueCm: _heightCm,
          maxCm: maxHeightCm,
          onChanged: (v) => setState(() => _heightCm = v),
        ),

        if (isPlant && _selectedPlant!.spacingBetweenPlants != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  PhosphorIcons.info(PhosphorIconsStyle.fill),
                  size: 16,
                  color: AppColors.info,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Espacement recommandé: ${_selectedPlant!.spacingBetweenPlants}cm',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.info,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 20),
      ],
    );
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
      'oignon': '🧅',
      'ail': '🧄',
      'pomme de terre': '🥔',
      'chou': '🥬',
      'brocoli': '🥦',
      'fraise': '🍓',
      'basilic': '🌿',
      'persil': '🌿',
    };
    for (final entry in map.entries) {
      if (name.contains(entry.key)) return entry.value;
    }
    return '🌱';
  }
}

/// Aperçu adaptatif qui grossit avec la taille
class _AdaptivePreview extends StatelessWidget {
  final String emoji;
  final Color color;
  final int widthCm;
  final int heightCm;

  const _AdaptivePreview({
    required this.emoji,
    required this.color,
    required this.widthCm,
    required this.heightCm,
  });

  @override
  Widget build(BuildContext context) {
    // Taille proportionnelle : 10cm = 40px, 200cm = 150px
    final baseSize = math.min(widthCm, heightCm);
    final previewSize = (baseSize * 0.6 + 30).clamp(40.0, 150.0);
    final emojiSize = (previewSize * 0.5).clamp(20.0, 60.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Container qui grossit
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            width: previewSize * (widthCm / math.max(widthCm, heightCm)),
            height: previewSize * (heightCm / math.max(widthCm, heightCm)),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color, width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(fontSize: emojiSize),
                child: Text(emoji),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Dimensions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${widthCm}cm × ${heightCm}cm',
              style: AppTypography.titleSmall.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlantCard extends StatelessWidget {
  final Plant plant;
  final VoidCallback onTap;

  const _PlantCard({required this.plant, required this.onTap});

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
      'pomme de terre': '🥔',
      'fraise': '🍓',
      'basilic': '🌿',
    };
    for (final entry in map.entries) {
      if (name.contains(entry.key)) return entry.value;
    }
    return '🌱';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_emoji, style: const TextStyle(fontSize: 32)),
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
  }
}

class _ZoneCard extends StatelessWidget {
  final ZoneType zone;
  final VoidCallback onTap;

  const _ZoneCard({required this.zone, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Color(zone.color).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(zone.color).withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(zone.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 4),
            Text(
              zone.label,
              style: AppTypography.caption.copyWith(color: Color(zone.color)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _DimensionSliderCm extends StatelessWidget {
  final String label;
  final int valueCm;
  final int maxCm;
  final Function(int) onChanged;

  const _DimensionSliderCm({
    required this.label,
    required this.valueCm,
    required this.maxCm,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final divisions = ((maxCm - 5) / 5).floor().clamp(1, 100);

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
              '$valueCm cm',
              style: AppTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.border,
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withValues(alpha: 0.2),
            trackHeight: 4,
          ),
          child: Slider(
            value: valueCm.toDouble().clamp(5, maxCm.toDouble()),
            min: 5,
            max: maxCm.toDouble(),
            divisions: divisions,
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
      ],
    );
  }
}

class _QuickSizeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _QuickSizeChip({
    required this.label,
    this.selected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: selected ? Colors.white : AppColors.textPrimary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
