import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jardingue/l10n/generated/app_localizations.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/orchard_providers.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';

/// Sheet pour ajouter un piege a pheromones sur un arbre fruitier.
///
/// L'arbre est passe en parametre (deja selectionne par le parent). On
/// limite les types proposes a ceux pertinents pour l'arbre via
/// [PheromoneTrapType.isRelevantFor], avec un toggle "tout afficher"
/// pour les cas ou l'utilisateur sait ce qu'il fait.
class AddTrapSheet extends ConsumerStatefulWidget {
  final UserFruitTreeWithDetails tree;

  const AddTrapSheet({super.key, required this.tree});

  static Future<bool?> show(
    BuildContext context,
    UserFruitTreeWithDetails tree,
  ) =>
      AppBottomSheet.show<bool>(
        context: context,
        heightFraction: 0.85,
        child: AddTrapSheet(tree: tree),
      );

  @override
  ConsumerState<AddTrapSheet> createState() => _AddTrapSheetState();
}

class _AddTrapSheetState extends ConsumerState<AddTrapSheet> {
  PheromoneTrapType? _selectedType;
  DateTime _installedAt = DateTime.now();
  late TextEditingController _lifetimeController;
  late TextEditingController _notesController;
  bool _showAllTypes = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _lifetimeController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _lifetimeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onTypeSelected(PheromoneTrapType type) {
    setState(() {
      _selectedType = type;
      _lifetimeController.text = type.defaultLifetimeDays.toString();
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _installedAt,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 7)),
    );
    if (picked != null) {
      setState(() => _installedAt = picked);
    }
  }

  Future<void> _save() async {
    if (_selectedType == null) return;
    final lifetime = int.tryParse(_lifetimeController.text) ??
        _selectedType!.defaultLifetimeDays;
    setState(() => _saving = true);
    try {
      await ref.read(pheromoneTrapsNotifierProvider.notifier).addTrap(
            userFruitTreeId: widget.tree.id,
            type: _selectedType!,
            installedAt: _installedAt,
            lifetimeDays: lifetime,
            notes: _notesController.text.isEmpty ? null : _notesController.text,
          );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      // L'erreur est deja loguee via CrashReporting dans le notifier
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final relevantTypes = PheromoneTrapType.values
        .where((t) => t.isRelevantFor(widget.tree.fruitTree.commonName))
        .toList();
    final allTypes = PheromoneTrapType.values;
    final typesToShow =
        _showAllTypes || relevantTypes.isEmpty ? allTypes : relevantTypes;

    return Column(
      children: [
        const AppBottomSheetHandle(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  loc.addTrapTitle,
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
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Row(
            children: [
              Text(widget.tree.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.tree.name,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              // Toggle "tout afficher" si types filtres
              if (relevantTypes.isNotEmpty &&
                  relevantTypes.length < allTypes.length)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Switch(
                        value: _showAllTypes,
                        onChanged: (v) => setState(() => _showAllTypes = v),
                      ),
                      const SizedBox(width: 8),
                      Text(loc.showAllTrapTypes,
                          style: AppTypography.bodySmall),
                    ],
                  ),
                ),

              // Types
              Text(loc.trapType, style: AppTypography.titleSmall),
              const SizedBox(height: 8),
              ...typesToShow.map((t) => _TypeOption(
                    type: t,
                    selected: _selectedType == t,
                    onTap: () => _onTypeSelected(t),
                  )),

              const SizedBox(height: 16),
              Divider(color: AppColors.border),
              const SizedBox(height: 16),

              // Date de pose
              Text(loc.installationDate, style: AppTypography.titleSmall),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(PhosphorIcons.calendar(PhosphorIconsStyle.regular),
                          size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: 12),
                      Text(
                        '${_installedAt.day.toString().padLeft(2, '0')}/'
                        '${_installedAt.month.toString().padLeft(2, '0')}/'
                        '${_installedAt.year}',
                        style: AppTypography.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Duree de vie
              Text(loc.lifetimeDays, style: AppTypography.titleSmall),
              const SizedBox(height: 8),
              TextField(
                controller: _lifetimeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: _selectedType?.defaultLifetimeDays.toString() ??
                      loc.selectTypeFirst,
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Notes
              Text(loc.notes, style: AppTypography.titleSmall),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: loc.notesHint,
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Bouton enregistrer
              ElevatedButton(
                onPressed: _selectedType != null && !_saving ? _save : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _saving ? loc.loading : loc.save,
                  style: AppTypography.labelMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TypeOption extends StatelessWidget {
  final PheromoneTrapType type;
  final bool selected;
  final VoidCallback onTap;

  const _TypeOption({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:
              selected ? AppColors.primaryContainer : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(type.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type.label,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    type.description,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    loc.lifetimeAboutDays(type.defaultLifetimeDays),
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(
                PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                color: AppColors.primary,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}
