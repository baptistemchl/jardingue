import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/providers/database_providers.dart';
import '../../../../../core/services/database/app_database.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../l10n/generated/app_localizations.dart';

/// Décoration de TextField partagée par tous les sheets du carnet.
InputDecoration carnetSheetInputDecoration() {
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

class CarnetSheetLabel extends StatelessWidget {
  final String text;
  const CarnetSheetLabel({super.key, required this.text});

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

/// Picker de plante avec autocomplete sur le catalogue. Quand
/// [selected] est null, affiche la barre de recherche + liste.
/// Sinon, une pill compacte avec un bouton de suppression.
class CarnetPlantPicker extends ConsumerStatefulWidget {
  final Plant? selected;
  final ValueChanged<Plant> onChanged;
  final VoidCallback onCleared;
  final String? hintText;
  const CarnetPlantPicker({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.onCleared,
    this.hintText,
  });

  @override
  ConsumerState<CarnetPlantPicker> createState() =>
      _CarnetPlantPickerState();
}

class _CarnetPlantPickerState extends ConsumerState<CarnetPlantPicker> {
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
    final loc = AppLocalizations.of(context)!;
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
            hintText: widget.hintText ?? loc.addHarvestPlantSearchHint,
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

/// Champ de date carnet — InkWell qui ouvre un DatePicker, affichage
/// format français long.
class CarnetDateField extends StatelessWidget {
  final DateTime value;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final ValueChanged<DateTime> onChanged;

  const CarnetDateField({
    super.key,
    required this.value,
    required this.onChanged,
    this.firstDate,
    this.lastDate,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: firstDate ?? DateTime(value.year - 5),
          lastDate: lastDate ?? DateTime.now(),
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
            Text(formatCarnetDate(value), style: AppTypography.bodyMedium),
          ],
        ),
      ),
    );
  }
}

String formatCarnetDate(DateTime d) {
  const months = [
    'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
    'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}
