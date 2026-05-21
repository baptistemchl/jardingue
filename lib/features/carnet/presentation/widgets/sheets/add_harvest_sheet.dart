import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/providers/database_providers.dart';
import '../../../../../core/services/database/app_database.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../../domain/models/harvest_summary.dart';

/// Bottom sheet de saisie d'une nouvelle récolte.
///
/// Sélection plante (autocomplete sur le catalogue) + date + quantité +
/// unité (chips) + note optionnelle.
class AddHarvestSheet extends ConsumerStatefulWidget {
  /// Plante pré-sélectionnée (ex: quand on lance la saisie depuis une
  /// carte de l'onglet Récoltes pour rapidement « rajouter une ligne »).
  final Plant? initialPlant;

  const AddHarvestSheet({super.key, this.initialPlant});

  static Future<void> show(
    BuildContext context, {
    Plant? initialPlant,
  }) {
    return AppBottomSheet.show(
      context: context,
      heightFraction: 0.88,
      child: AddHarvestSheet(initialPlant: initialPlant),
    );
  }

  @override
  ConsumerState<AddHarvestSheet> createState() => _AddHarvestSheetState();
}

class _AddHarvestSheetState extends ConsumerState<AddHarvestSheet> {
  Plant? _selectedPlant;
  DateTime _date = DateTime.now();
  HarvestUnit _unit = HarvestUnit.grams;
  final _quantityController = TextEditingController();
  final _noteController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedPlant = widget.initialPlant;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _selectedPlant != null &&
      double.tryParse(_quantityController.text.replaceAll(',', '.')) != null;

  Future<void> _save() async {
    if (!_canSave || _saving) return;
    final qty =
        double.parse(_quantityController.text.replaceAll(',', '.'));
    setState(() => _saving = true);
    try {
      final db = ref.read(databaseProvider);
      await db.insertHarvest(HarvestsCompanion.insert(
        plantId: _selectedPlant!.id,
        harvestedAt: _date,
        quantity: qty,
        unit: _unit.code,
        note: _noteController.text.trim().isEmpty
            ? const Value.absent()
            : Value(_noteController.text.trim()),
      ));
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Column(
      children: [
        const AppBottomSheetHandle(),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(
            children: [
              Icon(
                PhosphorIcons.basket(PhosphorIconsStyle.fill),
                color: AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  loc.addHarvestSheetTitle,
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            children: [
              _Label(text: loc.addHarvestPlantLabel),
              const SizedBox(height: 6),
              _PlantPicker(
                selected: _selectedPlant,
                onChanged: (p) => setState(() => _selectedPlant = p),
                onCleared: () => setState(() => _selectedPlant = null),
              ),
              const SizedBox(height: 18),
              _Label(text: loc.addHarvestDateLabel),
              const SizedBox(height: 6),
              _DateField(
                value: _date,
                onChanged: (d) => setState(() => _date = d),
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Label(text: loc.addHarvestQuantityLabel),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _quantityController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.,]'),
                            ),
                          ],
                          onChanged: (_) => setState(() {}),
                          decoration: _inputDecoration(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 7,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Label(text: loc.addHarvestUnitLabel),
                        const SizedBox(height: 6),
                        _UnitChips(
                          value: _unit,
                          onChanged: (u) => setState(() => _unit = u),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _Label(text: loc.addHarvestNoteLabel),
              const SizedBox(height: 6),
              TextField(
                controller: _noteController,
                minLines: 2,
                maxLines: 4,
                decoration: _inputDecoration(),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _canSave && !_saving ? _save : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(loc.addHarvestSaveButton),
              ),
            ],
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: AppColors.surfaceVariant,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppColors.border.withValues(alpha: 0.5),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.labelMedium.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _PlantPicker extends ConsumerStatefulWidget {
  final Plant? selected;
  final ValueChanged<Plant> onChanged;
  final VoidCallback onCleared;
  const _PlantPicker({
    required this.selected,
    required this.onChanged,
    required this.onCleared,
  });

  @override
  ConsumerState<_PlantPicker> createState() => _PlantPickerState();
}

class _PlantPickerState extends ConsumerState<_PlantPicker> {
  final _searchController = TextEditingController();
  List<Plant> _allPlants = const [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final next = _searchController.text.trim().toLowerCase();
      if (next != _query) setState(() => _query = next);
    });
    Future.microtask(_load);
  }

  Future<void> _load() async {
    final db = ref.read(databaseProvider);
    final list = await db.getAllPlantsSorted();
    if (mounted) setState(() => _allPlants = list);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selected != null) {
      return _SelectedPlantPill(
        plant: widget.selected!,
        onClear: () {
          _searchController.clear();
          setState(() => _query = '');
          widget.onCleared();
        },
      );
    }
    final loc = AppLocalizations.of(context)!;
    final filtered = _query.isEmpty
        ? _allPlants.take(30).toList()
        : _allPlants
            .where((p) =>
                p.commonName.toLowerCase().contains(_query) ||
                (p.latinName?.toLowerCase().contains(_query) ?? false))
            .take(30)
            .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: loc.addHarvestPlantSearchHint,
            prefixIcon: Icon(
              PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.regular),
              size: 18,
              color: AppColors.textSecondary,
            ),
            filled: true,
            fillColor: AppColors.surfaceVariant,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(maxHeight: 200),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: filtered.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    loc.addHarvestPlantNoResult,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    color: AppColors.border.withValues(alpha: 0.5),
                  ),
                  itemBuilder: (context, i) {
                    final p = filtered[i];
                    return InkWell(
                      onTap: () => widget.onChanged(p),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              PhosphorIcons.plant(PhosphorIconsStyle.fill),
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                p.commonName,
                                style: AppTypography.bodyMedium,
                              ),
                            ),
                            if (p.latinName != null)
                              Text(
                                p.latinName!,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textTertiary,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
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

class _SelectedPlantPill extends StatelessWidget {
  final Plant plant;
  final VoidCallback onClear;
  const _SelectedPlantPill({required this.plant, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            PhosphorIcons.plant(PhosphorIconsStyle.fill),
            size: 18,
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              plant.commonName,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
          IconButton(
            onPressed: onClear,
            icon: Icon(
              PhosphorIcons.x(PhosphorIconsStyle.bold),
              size: 16,
              color: AppColors.primary,
            ),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  const _DateField({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(value.year - 5),
          lastDate: DateTime.now(),
        );
        if (picked != null) onChanged(picked);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.border.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(
              PhosphorIcons.calendar(PhosphorIconsStyle.regular),
              size: 18,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 10),
            Text(
              _formatDate(value),
              style: AppTypography.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime d) {
    const months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

class _UnitChips extends StatelessWidget {
  final HarvestUnit value;
  final ValueChanged<HarvestUnit> onChanged;
  const _UnitChips({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final labels = {
      HarvestUnit.grams: loc.addHarvestUnitGrams,
      HarvestUnit.kilos: loc.addHarvestUnitKilos,
      HarvestUnit.pieces: loc.addHarvestUnitPieces,
      HarvestUnit.bunches: loc.addHarvestUnitBunches,
    };
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: HarvestUnit.values.map((u) {
        final isActive = u == value;
        return GestureDetector(
          onTap: () => onChanged(u),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isActive
                    ? AppColors.primary
                    : AppColors.border.withValues(alpha: 0.5),
              ),
            ),
            child: Text(
              labels[u]!,
              style: AppTypography.labelSmall.copyWith(
                color: isActive ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
