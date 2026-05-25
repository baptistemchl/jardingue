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
import '_shared_sheet_fields.dart';

/// Bottom sheet de saisie d'un nouveau semis.
class AddSeedlingSheet extends ConsumerStatefulWidget {
  const AddSeedlingSheet({super.key});

  static Future<void> show(BuildContext context) {
    return AppBottomSheet.show(
      context: context,
      heightFraction: 0.86,
      child: const AddSeedlingSheet(),
    );
  }

  @override
  ConsumerState<AddSeedlingSheet> createState() => _AddSeedlingSheetState();
}

class _AddSeedlingSheetState extends ConsumerState<AddSeedlingSheet> {
  Plant? _selectedPlant;
  DateTime _sowedAt = DateTime.now();
  final _countController = TextEditingController();
  final _noteController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _countController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  bool get _canSave => _selectedPlant != null;

  Future<void> _save() async {
    if (!_canSave || _saving) return;
    setState(() => _saving = true);
    try {
      final db = ref.read(databaseProvider);
      final countText = _countController.text.trim();
      // Insert semis + snapshot + event sowing dans GardenEvents pour
      // linker à la planification.
      await db.insertSeedling(SeedlingsCompanion.insert(
        plantId: _selectedPlant!.id,
        sowedAt: _sowedAt,
        count: countText.isEmpty
            ? const Value.absent()
            : Value(int.tryParse(countText)),
        plantNameSnapshot: Value(_selectedPlant!.commonName),
        note: _noteController.text.trim().isEmpty
            ? const Value.absent()
            : Value(_noteController.text.trim()),
      ));
      // Event 'sowing' sans gardenId : le potager sera choisi au
      // moment du repiquage, pas avant.
      await db.insertSowingEventForSeedling(
        plantId: _selectedPlant!.id,
        sowedAt: _sowedAt,
        notes: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );
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
                PhosphorIcons.plant(PhosphorIconsStyle.fill),
                color: AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  loc.addSeedlingSheetTitle,
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
              CarnetSheetLabel(text: loc.addSeedlingPlantLabel),
              const SizedBox(height: 6),
              CarnetPlantPicker(
                selected: _selectedPlant,
                onChanged: (p) => setState(() => _selectedPlant = p),
                onCleared: () => setState(() => _selectedPlant = null),
              ),
              const SizedBox(height: 18),
              CarnetSheetLabel(text: loc.addSeedlingSowedAtLabel),
              const SizedBox(height: 6),
              CarnetDateField(
                value: _sowedAt,
                lastDate: DateTime.now().add(const Duration(days: 1)),
                onChanged: (d) => setState(() => _sowedAt = d),
              ),
              // Le potager n'est plus demandé ici — il sera proposé
              // au moment du repiquage (transition ready → transplanted),
              // moment où le choix est réellement nécessaire.
              const SizedBox(height: 18),
              CarnetSheetLabel(text: loc.addSeedlingCountLabel),
              const SizedBox(height: 6),
              TextField(
                controller: _countController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                ],
                decoration: carnetSheetInputDecoration().copyWith(
                  hintText: loc.addSeedlingCountHint,
                ),
              ),
              const SizedBox(height: 18),
              CarnetSheetLabel(text: loc.addSeedlingNoteLabel),
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
                    : Text(loc.addSeedlingSaveButton),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

