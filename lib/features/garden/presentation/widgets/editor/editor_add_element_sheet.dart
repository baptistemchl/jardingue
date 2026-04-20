import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:jardingue/l10n/generated/app_localizations.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/services/database/app_database.dart';
import '../../../../../core/providers/database_providers.dart';
import '../../../../../core/utils/plant_emoji_mapper.dart';
import '../../../domain/models/watering_helpers.dart';
import '../../../domain/models/zone_type.dart';
import 'dimension_input.dart';

/// Sheet pour ajouter un element au potager depuis
/// l'editeur, avec limitation aux dimensions du jardin.
class EditorAddElementSheet
    extends ConsumerStatefulWidget {
  final Garden garden;
  final double maxWidthM;
  final double maxHeightM;
  final Function(int plantId, double w, double h,
      {DateTime? sowedAt,
      DateTime? plantedAt,
      int? wateringFrequencyDays}) onPlantAdded;
  final Function(ZoneType type, double w, double h)
      onZoneAdded;

  const EditorAddElementSheet({
    super.key,
    required this.garden,
    required this.maxWidthM,
    required this.maxHeightM,
    required this.onPlantAdded,
    required this.onZoneAdded,
  });

  @override
  ConsumerState<EditorAddElementSheet> createState() =>
      _State();
}

class _State extends ConsumerState<EditorAddElementSheet> {
  int _step = 0;
  bool _isAddingZone = false;
  ZoneType _selectedZoneType = ZoneType.greenhouse;
  Plant? _selectedPlant;
  late double _width;
  late double _height;
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  // Dates et arrosage
  DateTime? _sowedAt;
  DateTime _plantedAt = DateTime.now();
  int? _wateringFrequencyDays;

  @override
  void initState() {
    super.initState();
    _width = math.min(1.0, widget.maxWidthM);
    _height = math.min(1.0, widget.maxHeightM);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    // Ne pas laisser la recherche fuir vers l'ecran Plantes principal.
    ref.read(plantsFilterProvider.notifier).clearFilters();
    super.dispose();
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => ref
          .read(plantsFilterProvider.notifier)
          .setSearchQuery(value),
    );
  }

  void _selectPlant(Plant plant) {
    setState(() {
      _selectedPlant = plant;
      if (plant.spacingBetweenPlants != null &&
          plant.spacingBetweenPlants! > 0) {
        final s = plant.spacingBetweenPlants! / 100.0;
        _width = s.clamp(0.1, widget.maxWidthM);
        _height = s.clamp(0.1, widget.maxHeightM);
      } else {
        _width = math.min(0.3, widget.maxWidthM);
        _height = math.min(0.3, widget.maxHeightM);
      }
      _wateringFrequencyDays =
          defaultWateringFrequencyDays(plant.watering);
      _plantedAt = DateTime.now();
      _sowedAt = null;
      _step = 2;
    });
  }

  void _selectZone(ZoneType type) {
    setState(() {
      _selectedZoneType = type;
      _isAddingZone = true;
      _width = math.min(1.0, widget.maxWidthM);
      _height = math.min(1.0, widget.maxHeightM);
      _step = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _step == 1
          ? MediaQuery.of(context).size.height * 0.85
          : null,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: _step == 1
            ? MediaQuery.of(context).padding.bottom + 20
            : MediaQuery.of(context).viewInsets.bottom +
                MediaQuery.of(context).padding.bottom +
                20,
      ),
      child: _step == 1
          ? _buildPlantSelection()
          : _buildMainContent(),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHandle(),
          const SizedBox(height: 16),
          _buildHeader(),
          const SizedBox(height: 8),
          if (_step == 0) ..._buildTypeSelection(),
          if (_step == 2) ..._buildDimensionConfig(),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        if (_step > 0)
          IconButton(
            onPressed: () => setState(() => _step = 0),
            icon: Icon(
              PhosphorIcons.arrowLeft(
                PhosphorIconsStyle.bold,
              ),
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        if (_step > 0) const SizedBox(width: 8),
        Expanded(
          child: Text(
            _step == 0
                ? AppLocalizations.of(context)!.addElement
                : (_isAddingZone
                    ? AppLocalizations.of(context)!.configureZone
                    : AppLocalizations.of(context)!.configurePlant),
            style: AppTypography.titleMedium,
            textAlign:
                _step == 0 ? TextAlign.center : null,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildTypeSelection() {
    return [
      // Info dimensions max
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primary
              .withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary
                .withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              PhosphorIcons.info(PhosphorIconsStyle.fill),
              color: AppColors.primary,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Max : '
                '${widget.maxWidthM.toStringAsFixed(1)}m '
                '\u{00D7} '
                '${widget.maxHeightM.toStringAsFixed(1)}m',
                style: AppTypography.caption.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      // Bouton plante
      _SelectionCard(
        icon: PhosphorIcons.plant(PhosphorIconsStyle.fill),
        title: AppLocalizations.of(context)!.addPlantOption,
        subtitle: AppLocalizations.of(context)!.chooseAmongVarieties,
        color: AppColors.primary,
        onTap: () => setState(() {
          _isAddingZone = false;
          _step = 1;
        }),
      ),
      const SizedBox(height: 12),
      Text(
        AppLocalizations.of(context)!.orAddZone,
        style: AppTypography.labelMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: ZoneType.values
            .map((t) => _ZoneChip(
                  type: t,
                  onTap: () => _selectZone(t),
                ))
            .toList(),
      ),
    ];
  }

  List<Widget> _buildDimensionConfig() {
    return [
      // Element selectionne
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primaryContainer
              .withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _isAddingZone
                    ? Color(_selectedZoneType.color)
                        .withValues(alpha: 0.2)
                    : AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  _isAddingZone
                      ? _selectedZoneType.emoji
                      : (_selectedPlant != null
                          ? PlantEmojiMapper.fromName(
                              _selectedPlant!.commonName,
                              categoryCode:
                                  _selectedPlant!
                                      .categoryCode,
                            )
                          : '\u{1F331}'),
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    _isAddingZone
                        ? _selectedZoneType.label
                        : (_selectedPlant?.commonName ??
                            'Plante'),
                    style: AppTypography.titleSmall,
                  ),
                  if (!_isAddingZone &&
                      _selectedPlant?.latinName != null)
                    Text(
                      _selectedPlant!.latinName!,
                      style: AppTypography.caption
                          .copyWith(
                        fontStyle: FontStyle.italic,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => setState(
                () => _step = _isAddingZone ? 0 : 1,
              ),
              child: Text(AppLocalizations.of(context)!.change),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      DimensionInput(
        label: AppLocalizations.of(context)!.width,
        value: _width,
        min: 0.1,
        max: widget.maxWidthM,
        unit: 'm',
        onChanged: (v) => setState(() => _width = v),
      ),
      const SizedBox(height: 16),
      DimensionInput(
        label: AppLocalizations.of(context)!.length,
        value: _height,
        min: 0.1,
        max: widget.maxHeightM,
        unit: 'm',
        onChanged: (v) => setState(() => _height = v),
      ),
      // Section dates et arrosage (plantes uniquement)
      if (!_isAddingZone) ...[
        const SizedBox(height: 24),
        Text(AppLocalizations.of(context)!.dates, style: AppTypography.labelMedium),
        const SizedBox(height: 8),
        _DatePickerRow(
          label: AppLocalizations.of(context)!.plantingDate,
          date: _plantedAt,
          onChanged: (d) => setState(() => _plantedAt = d),
        ),
        const SizedBox(height: 8),
        _OptionalDatePickerRow(
          label: AppLocalizations.of(context)!.sowingDate,
          date: _sowedAt,
          onChanged: (d) => setState(() => _sowedAt = d),
          onClear: () => setState(() => _sowedAt = null),
        ),
        const SizedBox(height: 16),
        Text(AppLocalizations.of(context)!.watering, style: AppTypography.labelMedium),
        const SizedBox(height: 8),
        _WateringFrequencyPicker(
          value: _wateringFrequencyDays,
          plantWatering: _selectedPlant?.watering,
          onChanged: (v) =>
              setState(() => _wateringFrequencyDays = v),
        ),
      ],
      const SizedBox(height: 24),
      ElevatedButton(
        onPressed: () {
          if (_isAddingZone) {
            widget.onZoneAdded(
              _selectedZoneType,
              _width,
              _height,
            );
          } else if (_selectedPlant != null) {
            widget.onPlantAdded(
              _selectedPlant!.id,
              _width,
              _height,
              sowedAt: _sowedAt,
              plantedAt: _plantedAt,
              wateringFrequencyDays: _wateringFrequencyDays,
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          _isAddingZone
              ? AppLocalizations.of(context)!.addTheZone
              : AppLocalizations.of(context)!.addThePlant,
          style: AppTypography.bodyMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ];
  }

  Widget _buildPlantSelection() {
    final plantsAsync = ref.watch(filteredPlantsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHandle(),
        const SizedBox(height: 16),
        Row(
          children: [
            IconButton(
              onPressed: () => setState(() => _step = 0),
              icon: Icon(
                PhosphorIcons.arrowLeft(
                  PhosphorIconsStyle.bold,
                ),
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.choosePlant,
                style: AppTypography.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _searchCtrl,
          onChanged: _onSearch,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.searchPlant,
            prefixIcon: Icon(
              PhosphorIcons.magnifyingGlass(
                PhosphorIconsStyle.regular,
              ),
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
        const SizedBox(height: 16),
        Expanded(
          child: plantsAsync.when(
            data: (plants) {
              if (plants.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        PhosphorIcons.plant(
                          PhosphorIconsStyle.duotone,
                        ),
                        size: 48,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppLocalizations.of(context)!.noPlantFound,
                        style: AppTypography.bodyMedium
                            .copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return ListView.separated(
                itemCount: plants.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final plant = plants[i];
                  return _PlantListItem(
                    plant: plant,
                    onTap: () => _selectPlant(plant),
                  );
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (e, _) =>
                Center(child: Text(AppLocalizations.of(context)!.errorWithMessage(e.toString()))),
          ),
        ),
      ],
    );
  }
}

class _SelectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _SelectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleSmall
                        .copyWith(color: color),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(
                      color: color.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              PhosphorIcons.caretRight(
                PhosphorIconsStyle.bold,
              ),
              color: color,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoneChip extends StatelessWidget {
  final ZoneType type;
  final VoidCallback onTap;
  const _ZoneChip({required this.type, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = Color(type.color);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: c.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              type.emoji,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(width: 8),
            Text(
              type.label,
              style: AppTypography.bodySmall.copyWith(
                color: c,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlantListItem extends StatelessWidget {
  final Plant plant;
  final VoidCallback onTap;
  const _PlantListItem({
    required this.plant,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final emoji = PlantEmojiMapper.fromName(
      plant.commonName,
      categoryCode: plant.categoryCode,
    );
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
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    plant.commonName,
                    style: AppTypography.titleSmall,
                  ),
                  if (plant.latinName != null)
                    Text(
                      plant.latinName!,
                      style: AppTypography.caption
                          .copyWith(
                        fontStyle: FontStyle.italic,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  if (plant.categoryLabel != null ||
                      plant.spacingBetweenPlants != null)
                    Padding(
                      padding:
                          const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          if (plant.categoryLabel != null)
                            _MiniChip(
                              label: plant.categoryLabel!,
                            ),
                          if (plant.spacingBetweenPlants !=
                              null)
                            Padding(
                              padding:
                                  const EdgeInsets.only(
                                left: 6,
                              ),
                              child: _MiniChip(
                                label:
                                    '${plant.spacingBetweenPlants}cm',
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
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
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
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

// ============================================
// DATE & WATERING WIDGETS
// ============================================

class _DatePickerRow extends StatelessWidget {
  final String label;
  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  const _DatePickerRow({
    required this.label,
    required this.date,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd MMM yyyy', 'fr_FR');
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          locale: const Locale('fr', 'FR'),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(
              PhosphorIcons.calendar(PhosphorIconsStyle.regular),
              size: 18,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(label,
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
            const Spacer(),
            Text(
              formatter.format(date),
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionalDatePickerRow extends StatelessWidget {
  final String label;
  final DateTime? date;
  final ValueChanged<DateTime> onChanged;
  final VoidCallback onClear;

  const _OptionalDatePickerRow({
    required this.label,
    required this.date,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd MMM yyyy', 'fr_FR');
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          locale: const Locale('fr', 'FR'),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(
              PhosphorIcons.calendar(PhosphorIconsStyle.regular),
              size: 18,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(label,
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
            const Spacer(),
            if (date != null) ...[
              Text(
                formatter.format(date!),
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onClear,
                child: Icon(
                  PhosphorIcons.x(PhosphorIconsStyle.bold),
                  size: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ] else
              Text(
                AppLocalizations.of(context)!.notDefined,
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textTertiary),
              ),
          ],
        ),
      ),
    );
  }
}

class _WateringFrequencyPicker extends StatelessWidget {
  final int? value;
  final String? plantWatering;
  final ValueChanged<int> onChanged;

  const _WateringFrequencyPicker({
    required this.value,
    this.plantWatering,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (plantWatering != null && plantWatering!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Text('💧', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.needWatering(plantWatering!),
                      style: AppTypography.caption.copyWith(
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _FreqChip(
                label: AppLocalizations.of(context)!.nDays(2),
                days: 2,
                selected: value == 2,
                onTap: () => onChanged(2)),
            _FreqChip(
                label: AppLocalizations.of(context)!.nDays(3),
                days: 3,
                selected: value == 3,
                onTap: () => onChanged(3)),
            _FreqChip(
                label: AppLocalizations.of(context)!.nDays(5),
                days: 5,
                selected: value == 5,
                onTap: () => onChanged(5)),
            _FreqChip(
                label: AppLocalizations.of(context)!.nDays(7),
                days: 7,
                selected: value == 7,
                onTap: () => onChanged(7)),
          ],
        ),
      ],
    );
  }
}

class _FreqChip extends StatelessWidget {
  final String label;
  final int days;
  final bool selected;
  final VoidCallback onTap;

  const _FreqChip({
    required this.label,
    required this.days,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? Colors.blue
              : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.blue : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: selected ? Colors.white : AppColors.textPrimary,
            fontWeight:
                selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
