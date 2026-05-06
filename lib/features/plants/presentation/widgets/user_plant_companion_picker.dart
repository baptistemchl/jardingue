import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jardingue/l10n/generated/app_localizations.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../core/services/database/database.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/plant_emoji_mapper.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';

/// Affiche un sheet de sélection multi de plantes catalogue (pour
/// définir compagnes ou antagonistes d'une plante user en cours
/// d'édition). Renvoie la liste mise à jour ou `null` si annulé.
///
/// Le filtrage exclut systématiquement :
/// - les plantes user (id ≥ [AppDatabase.userPlantIdMin]) — la v1 ne
///   gère que les relations user → catalogue, jamais user → user ;
/// - la plante en cours d'édition elle-même via [excludePlantId].
Future<List<int>?> showUserPlantCompanionPicker({
  required BuildContext context,
  required String title,
  required List<int> initialSelected,
  int? excludePlantId,
}) {
  return AppBottomSheet.show<List<int>>(
    context: context,
    heightFraction: 0.85,
    child: _CompanionPickerSheet(
      title: title,
      initialSelected: initialSelected,
      excludePlantId: excludePlantId,
    ),
  );
}

class _CompanionPickerSheet extends ConsumerStatefulWidget {
  final String title;
  final List<int> initialSelected;
  final int? excludePlantId;

  const _CompanionPickerSheet({
    required this.title,
    required this.initialSelected,
    required this.excludePlantId,
  });

  @override
  ConsumerState<_CompanionPickerSheet> createState() =>
      _CompanionPickerSheetState();
}

class _CompanionPickerSheetState
    extends ConsumerState<_CompanionPickerSheet> {
  late final Set<int> _selected;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selected = widget.initialSelected.toSet();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plantsAsync = ref.watch(allPlantsSortedProvider);
    return Column(
      children: [
        const AppBottomSheetHandle(),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: AppTypography.titleMedium,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context)
                    .pop(_selected.toList()),
                child: Text(
                  AppLocalizations.of(context)!
                      .userPlantCompanionsValidate(
                        _selected.length,
                      ),
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!
                  .userPlantCompanionsSearch,
              prefixIcon: Icon(
                PhosphorIcons.magnifyingGlass(
                  PhosphorIconsStyle.regular,
                ),
              ),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: AppSpacing.borderRadiusMd,
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: plantsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (e, _) => Center(child: Text('Erreur: $e')),
            data: (allPlants) {
              final query = _searchCtrl.text.trim().toLowerCase();
              final filtered = allPlants.where((p) {
                if (p.id >= AppDatabase.userPlantIdMin) return false;
                if (p.id == widget.excludePlantId) return false;
                if (query.isEmpty) return true;
                return p.commonName.toLowerCase().contains(query) ||
                    (p.latinName?.toLowerCase().contains(query) ??
                        false);
              }).toList();
              return ListView.separated(
                padding: AppSpacing.horizontalPadding,
                itemCount: filtered.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: 4),
                itemBuilder: (_, i) =>
                    _PlantTile(plant: filtered[i], selected: _selected),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PlantTile extends StatefulWidget {
  final Plant plant;
  final Set<int> selected;

  const _PlantTile({required this.plant, required this.selected});

  @override
  State<_PlantTile> createState() => _PlantTileState();
}

class _PlantTileState extends State<_PlantTile> {
  @override
  Widget build(BuildContext context) {
    final isSelected = widget.selected.contains(widget.plant.id);
    return InkWell(
      borderRadius: AppSpacing.borderRadiusMd,
      onTap: () => setState(() {
        if (isSelected) {
          widget.selected.remove(widget.plant.id);
        } else {
          widget.selected.add(widget.plant.id);
        }
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : null,
          borderRadius: AppSpacing.borderRadiusMd,
        ),
        child: Row(
          children: [
            Text(
              PlantEmojiMapper.forPlant(widget.plant),
              style: const TextStyle(fontSize: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.plant.commonName,
                    style: AppTypography.bodyMedium,
                  ),
                  Text(
                    widget.plant.categoryDisplayLabel,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? PhosphorIcons.checkCircle(
                      PhosphorIconsStyle.fill,
                    )
                  : PhosphorIcons.circle(PhosphorIconsStyle.regular),
              color: isSelected
                  ? AppColors.primary
                  : AppColors.textTertiary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
