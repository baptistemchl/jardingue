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
import '_shared_sheet_fields.dart';

/// Bottom sheet de saisie d'une nouvelle récolte.
///
/// Sélection plante (autocomplete sur le catalogue) + date + quantité +
/// unité (chips) + note optionnelle.
class AddHarvestSheet extends ConsumerStatefulWidget {
  /// Plante pré-sélectionnée (ex: quand on lance la saisie depuis une
  /// carte de l'onglet Récoltes pour rapidement « rajouter une ligne »).
  final Plant? initialPlant;

  /// Récolte existante à éditer. Quand non null, le sheet bascule en
  /// mode update : valeurs pré-remplies, plante verrouillée (pas
  /// éditable), insert remplacé par updateHarvest.
  final Harvest? existing;

  const AddHarvestSheet({super.key, this.initialPlant, this.existing});

  static Future<void> show(
    BuildContext context, {
    Plant? initialPlant,
    Harvest? existing,
  }) {
    return AppBottomSheet.show(
      context: context,
      heightFraction: 0.88,
      child: AddHarvestSheet(
        initialPlant: initialPlant,
        existing: existing,
      ),
    );
  }

  @override
  ConsumerState<AddHarvestSheet> createState() => _AddHarvestSheetState();
}

class _AddHarvestSheetState extends ConsumerState<AddHarvestSheet> {
  Plant? _selectedPlant;
  DateTime _date = DateTime.now();
  HarvestUnit _unit = HarvestUnit.grams;
  // En mode "kilos", on combine les deux champs (kg + g) façon balance
  // pour faciliter l'addition mentale. _qtyMainController = la valeur
  // principale (kg, g, pièces, bottes) ; _qtyGramsController = la partie
  // grammes complémentaire, utilisée uniquement quand unit=kilos.
  final _qtyMainController = TextEditingController();
  final _qtyGramsController = TextEditingController();
  final _noteController = TextEditingController();
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _selectedPlant = widget.initialPlant;
    // Mode édition : pré-remplir les champs depuis la récolte existante.
    final existing = widget.existing;
    if (existing != null) {
      _date = existing.harvestedAt;
      _unit = HarvestUnit.fromCode(existing.unit);
      _noteController.text = existing.note ?? '';
      // Décomposition quantité pour le mode kilos : 4.345 → 4 kg 345 g.
      if (_unit == HarvestUnit.kilos) {
        final wholeKg = existing.quantity.floor();
        final remainGrams =
            ((existing.quantity - wholeKg) * 1000).round();
        _qtyMainController.text =
            wholeKg == 0 ? '' : wholeKg.toString();
        _qtyGramsController.text =
            remainGrams == 0 ? '' : remainGrams.toString();
      } else {
        // Pour les autres unités : valeur directe (entier si entier,
        // sinon décimal avec virgule).
        final q = existing.quantity;
        _qtyMainController.text = q == q.roundToDouble()
            ? q.toStringAsFixed(0)
            : q.toStringAsFixed(2).replaceAll('.', ',');
      }
    }
  }

  @override
  void dispose() {
    _qtyMainController.dispose();
    _qtyGramsController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  /// Quantité combinée selon l'unité courante. Null si saisie invalide
  /// ou totalement vide.
  double? get _combinedQuantity {
    final main = double.tryParse(
      _qtyMainController.text.replaceAll(',', '.').trim(),
    );
    if (_unit == HarvestUnit.kilos) {
      final grams = double.tryParse(
        _qtyGramsController.text.replaceAll(',', '.').trim(),
      );
      // Au moins un des deux doit être saisi.
      if (main == null && grams == null) return null;
      return (main ?? 0) + (grams ?? 0) / 1000.0;
    }
    return main;
  }

  bool get _canSave {
    if (_selectedPlant == null) return false;
    final qty = _combinedQuantity;
    return qty != null && qty > 0;
  }

  Future<void> _save() async {
    if (!_canSave || _saving) return;
    final qty = _combinedQuantity!;
    setState(() => _saving = true);
    try {
      final db = ref.read(databaseProvider);
      final existing = widget.existing;
      if (existing != null) {
        // Mode édition : update sur l'id existant. La plante n'est pas
        // modifiable (elle est verrouillée par le _PlantPicker).
        await db.updateHarvest(
          existing.id,
          harvestedAt: _date,
          quantity: qty,
          unit: _unit.code,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
        );
      } else {
        // Insert récolte + snapshot nom (préserve l'historique si le
        // plant est supprimé plus tard) + event harvest dans
        // GardenEvents pour linker à la planification/calendrier.
        await db.insertHarvest(HarvestsCompanion.insert(
          plantId: _selectedPlant!.id,
          harvestedAt: _date,
          quantity: qty,
          unit: _unit.code,
          plantNameSnapshot: Value(_selectedPlant!.commonName),
          note: _noteController.text.trim().isEmpty
              ? const Value.absent()
              : Value(_noteController.text.trim()),
        ));
        await db.insertHarvestEventForHarvest(
          plantId: _selectedPlant!.id,
          harvestedAt: _date,
          quantity: qty,
          unit: _unit.code,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
        );
      }
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
                  _isEditing
                      ? loc.addHarvestEditTitle
                      : loc.addHarvestSheetTitle,
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
              CarnetSheetLabel(text: loc.addHarvestPlantLabel),
              const SizedBox(height: 6),
              CarnetPlantPicker(
                selected: _selectedPlant,
                onChanged: (p) => setState(() => _selectedPlant = p),
                onCleared: () => setState(() => _selectedPlant = null),
              ),
              const SizedBox(height: 18),
              CarnetSheetLabel(text: loc.addHarvestDateLabel),
              const SizedBox(height: 6),
              CarnetDateField(
                value: _date,
                onChanged: (d) => setState(() => _date = d),
              ),
              const SizedBox(height: 18),
              CarnetSheetLabel(text: loc.addHarvestUnitLabel),
              const SizedBox(height: 6),
              _UnitChips(
                value: _unit,
                onChanged: (u) => setState(() => _unit = u),
              ),
              const SizedBox(height: 18),
              CarnetSheetLabel(text: loc.addHarvestQuantityLabel),
              const SizedBox(height: 6),
              _QuantityRow(
                unit: _unit,
                mainController: _qtyMainController,
                gramsController: _qtyGramsController,
                onChanged: () => setState(() {}),
                decoration: carnetSheetInputDecoration,
              ),
              const SizedBox(height: 18),
              CarnetSheetLabel(text: loc.addHarvestNoteLabel),
              const SizedBox(height: 6),
              TextField(
                controller: _noteController,
                minLines: 2,
                maxLines: 4,
                decoration: carnetSheetInputDecoration(),
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
                    : Text(_isEditing
                        ? loc.addHarvestUpdateButton
                        : loc.addHarvestSaveButton),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Row de saisie de quantité adaptée à l'unité courante.
///
/// - kilos  : [   ] kg  [   ] g  (style balance, addition mentale facile)
/// - grams  : [   ] g
/// - pieces : [   ] pièces
/// - bunches: [   ] bottes
class _QuantityRow extends StatelessWidget {
  final HarvestUnit unit;
  final TextEditingController mainController;
  final TextEditingController gramsController;
  final VoidCallback onChanged;
  final InputDecoration Function() decoration;

  const _QuantityRow({
    required this.unit,
    required this.mainController,
    required this.gramsController,
    required this.onChanged,
    required this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    if (unit == HarvestUnit.kilos) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: _NumberField(
              controller: mainController,
              decimal: false,
              onChanged: onChanged,
              decoration: decoration,
            ),
          ),
          const SizedBox(width: 6),
          _UnitSuffix(text: loc.addHarvestUnitKilos),
          const SizedBox(width: 10),
          Expanded(
            child: _NumberField(
              controller: gramsController,
              decimal: false,
              onChanged: onChanged,
              decoration: decoration,
            ),
          ),
          const SizedBox(width: 6),
          _UnitSuffix(text: loc.addHarvestUnitGrams),
        ],
      );
    }
    final suffix = switch (unit) {
      HarvestUnit.grams => loc.addHarvestUnitGrams,
      HarvestUnit.pieces => loc.addHarvestUnitPieces,
      HarvestUnit.bunches => loc.addHarvestUnitBunches,
      HarvestUnit.kilos => '', // déjà géré au-dessus
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: _NumberField(
            controller: mainController,
            // Pour les pièces/bottes : pas de décimales ; pour les g :
            // l'utilisateur peut saisir 250 ou 250.5 sans souci.
            decimal: unit == HarvestUnit.grams,
            onChanged: onChanged,
            decoration: decoration,
          ),
        ),
        const SizedBox(width: 10),
        _UnitSuffix(text: suffix),
      ],
    );
  }
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final bool decimal;
  final VoidCallback onChanged;
  final InputDecoration Function() decoration;

  const _NumberField({
    required this.controller,
    required this.decimal,
    required this.onChanged,
    required this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          decimal ? RegExp(r'[0-9.,]') : RegExp(r'[0-9]'),
        ),
      ],
      onChanged: (_) => onChanged(),
      decoration: decoration(),
      textAlign: TextAlign.center,
      style: AppTypography.titleMedium.copyWith(
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _UnitSuffix extends StatelessWidget {
  final String text;
  const _UnitSuffix({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.bodyMedium.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
    );
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
