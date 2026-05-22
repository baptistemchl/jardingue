import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/providers/database_providers.dart';
import '../../../../../core/services/database/app_database.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/utils/plant_emoji_mapper.dart';
import '../../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../../domain/models/harvest_summary.dart';
import '../../providers/harvest_providers.dart';
import 'add_harvest_sheet.dart';
import '_shared_sheet_fields.dart';

/// Liste détaillée des récoltes pour une plante × unité donnée.
/// Tap sur une ligne = édit, icône poubelle = delete avec
/// confirmation. Le sheet écoute le stream Riverpod et se met à jour
/// automatiquement après chaque action.
class HarvestHistorySheet extends ConsumerWidget {
  final int plantId;
  final String plantName;
  final String? plantCategoryCode;
  final String unit;

  const HarvestHistorySheet({
    super.key,
    required this.plantId,
    required this.plantName,
    required this.plantCategoryCode,
    required this.unit,
  });

  static Future<void> show(
    BuildContext context, {
    required int plantId,
    required String plantName,
    required String? plantCategoryCode,
    required String unit,
  }) {
    return AppBottomSheet.show(
      context: context,
      heightFraction: 0.78,
      child: HarvestHistorySheet(
        plantId: plantId,
        plantName: plantName,
        plantCategoryCode: plantCategoryCode,
        unit: unit,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final harvestsAsync = ref.watch(harvestsForYearProvider);
    final emoji = PlantEmojiMapper.fromName(
      plantName,
      categoryCode: plantCategoryCode,
    );

    return Column(
      children: [
        const AppBottomSheetHandle(),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plantName,
                      style: AppTypography.titleLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      loc.harvestHistorySheetSubtitle(
                        _unitLabel(loc, unit),
                      ),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Divider(
          height: 1,
          color: AppColors.border.withValues(alpha: 0.5),
        ),
        Expanded(
          child: harvestsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (e, _) => Center(
              child: Text(
                e.toString(),
                style: AppTypography.caption.copyWith(
                  color: AppColors.error,
                ),
              ),
            ),
            data: (all) {
              final filtered = all
                  .where((h) => h.plantId == plantId && h.unit == unit)
                  .toList();
              if (filtered.isEmpty) {
                // L'utilisateur a supprimé toutes les récoltes → on
                // ferme automatiquement le sheet au prochain frame.
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) Navigator.of(context).pop();
                });
                return const SizedBox.shrink();
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  return _HarvestRow(
                    harvest: filtered[i],
                    unit: unit,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  String _unitLabel(AppLocalizations loc, String unit) {
    return switch (HarvestUnit.fromCode(unit)) {
      HarvestUnit.grams => loc.addHarvestUnitGrams,
      HarvestUnit.kilos => loc.addHarvestUnitKilos,
      HarvestUnit.pieces => loc.addHarvestUnitPieces,
      HarvestUnit.bunches => loc.addHarvestUnitBunches,
    };
  }
}

class _HarvestRow extends ConsumerWidget {
  final Harvest harvest;
  final String unit;
  const _HarvestRow({required this.harvest, required this.unit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final qty = _formatQuantity(harvest.quantity, unit, loc);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => AddHarvestSheet.show(
          context,
          existing: harvest,
        ),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  PhosphorIcons.calendar(PhosphorIconsStyle.regular),
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatCarnetDate(harvest.harvestedAt),
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (harvest.note != null &&
                        harvest.note!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        harvest.note!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                qty,
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              IconButton(
                onPressed: () => _confirmDelete(context, ref),
                icon: Icon(
                  PhosphorIcons.trash(PhosphorIconsStyle.regular),
                  size: 16,
                  color: AppColors.textTertiary,
                ),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatQuantity(
    double q,
    String unit,
    AppLocalizations loc,
  ) {
    final unitLabel = switch (HarvestUnit.fromCode(unit)) {
      HarvestUnit.grams => loc.addHarvestUnitGrams,
      HarvestUnit.kilos => loc.addHarvestUnitKilos,
      HarvestUnit.pieces => loc.addHarvestUnitPieces,
      HarvestUnit.bunches => loc.addHarvestUnitBunches,
    };
    final n = q == q.roundToDouble()
        ? q.toStringAsFixed(0)
        : q
            .toStringAsFixed(3)
            .replaceAll(RegExp(r'0+$'), '')
            .replaceAll(RegExp(r'\.$'), '')
            .replaceAll('.', ',');
    return '$n $unitLabel';
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final loc = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.harvestHistoryDeleteTitle),
        content: Text(loc.harvestHistoryDeleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text(loc.commonDelete),
          ),
        ],
      ),
    );
    if (ok == true) {
      final db = ref.read(databaseProvider);
      await db.deleteHarvest(harvest.id);
    }
  }
}
