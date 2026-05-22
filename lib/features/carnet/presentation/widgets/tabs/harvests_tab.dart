import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/services/database/app_database.dart';
import '../../../../../core/utils/plant_emoji_mapper.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../../domain/models/harvest_summary.dart';
import '../../providers/harvest_providers.dart';
import '../sheets/add_harvest_sheet.dart';
import '../sheets/harvest_history_sheet.dart';
import '../_empty_tab_placeholder.dart';

class HarvestsTab extends ConsumerWidget {
  const HarvestsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final year = ref.watch(harvestYearProvider);
    final summaries = ref.watch(harvestSummariesProvider);
    final harvestsAsync = ref.watch(harvestsForYearProvider);
    final filters = ref.watch(harvestFiltersProvider);
    final hasAnyHarvest = (harvestsAsync.value ?? []).isNotEmpty;

    return Stack(
      children: [
        harvestsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          error: (e, _) => _ErrorState(message: e.toString()),
          data: (_) {
            if (!hasAnyHarvest) {
              return EmptyTabPlaceholder(
                icon: PhosphorIcons.basket(PhosphorIconsStyle.duotone),
                title: loc.carnetHarvestsEmptyTitle,
                subtitle: loc.carnetHarvestsEmptySubtitle,
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.only(bottom: 96),
              // +2 = season header + filter bar ; +1 supplémentaire si
              // l'agrégat est vide (état « aucune récolte ne matche les
              // filtres »).
              itemCount: summaries.length + 2 + (summaries.isEmpty ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                if (i == 0) {
                  return _SeasonHeader(year: year, summaries: summaries);
                }
                if (i == 1) {
                  return _FilterBar(filters: filters);
                }
                if (summaries.isEmpty && i == 2) {
                  return _NoMatchPlaceholder(onClear: () =>
                      ref.read(harvestFiltersProvider.notifier).clear());
                }
                return _HarvestSummaryCard(summary: summaries[i - 2]);
              },
            );
          },
        ),
        // Bouton flottant en bas à droite, dans la zone du drawer body.
        Positioned(
          bottom: 8,
          right: 0,
          child: _AddButton(
            label: loc.carnetHarvestsAddButton,
            onTap: () => AddHarvestSheet.show(context),
          ),
        ),
      ],
    );
  }
}

/// Barre de filtres horizontale : mois + plante + unité, avec un bouton
/// « tout réinitialiser » à droite quand un filtre est actif.
class _FilterBar extends ConsumerWidget {
  final HarvestFilters filters;
  const _FilterBar({required this.filters});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final notifier = ref.read(harvestFiltersProvider.notifier);
    final all = ref.watch(harvestsForYearProvider).value ?? const [];
    final plantsLookup =
        ref.watch(harvestPlantsLookupProvider).value ?? const {};

    // Listes des valeurs disponibles selon les récoltes effectives.
    final monthsAvailable = all.map((h) => h.harvestedAt.month).toSet().toList()
      ..sort();
    final unitsAvailable = all.map((h) => h.unit).toSet().toList();
    final plantsAvailable =
        all.map((h) => h.plantId).toSet().toList()
          ..sort((a, b) {
            final na = plantsLookup[a]?.commonName ?? '';
            final nb = plantsLookup[b]?.commonName ?? '';
            return na.compareTo(nb);
          });

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: SizedBox(
        height: 36,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _FilterChip(
              icon: PhosphorIcons.calendar(PhosphorIconsStyle.regular),
              label: filters.month == null
                  ? loc.harvestFilterMonth
                  : _shortMonth(filters.month!),
              active: filters.month != null,
              onTap: () => _pickMonth(context, ref, monthsAvailable),
            ),
            const SizedBox(width: 6),
            _FilterChip(
              icon: PhosphorIcons.plant(PhosphorIconsStyle.regular),
              label: filters.plantId == null
                  ? loc.harvestFilterPlant
                  : (plantsLookup[filters.plantId]?.commonName ?? '—'),
              active: filters.plantId != null,
              onTap: () => _pickPlant(
                context,
                ref,
                plantsAvailable,
                plantsLookup,
              ),
            ),
            const SizedBox(width: 6),
            _FilterChip(
              icon: PhosphorIcons.scales(PhosphorIconsStyle.regular),
              label: filters.unit == null
                  ? loc.harvestFilterUnit
                  : _unitLabel(loc, filters.unit!),
              active: filters.unit != null,
              onTap: () => _pickUnit(context, ref, unitsAvailable),
            ),
            if (!filters.isEmpty) ...[
              const SizedBox(width: 6),
              _ClearFiltersChip(onTap: notifier.clear),
            ],
          ],
        ),
      ),
    );
  }

  static String _shortMonth(int m) {
    const labels = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
    ];
    return labels[m - 1];
  }

  static String _unitLabel(AppLocalizations loc, String code) {
    return switch (HarvestUnit.fromCode(code)) {
      HarvestUnit.grams => loc.addHarvestUnitGrams,
      HarvestUnit.kilos => loc.addHarvestUnitKilos,
      HarvestUnit.pieces => loc.addHarvestUnitPieces,
      HarvestUnit.bunches => loc.addHarvestUnitBunches,
    };
  }

  Future<void> _pickMonth(
    BuildContext context,
    WidgetRef ref,
    List<int> available,
  ) async {
    final loc = AppLocalizations.of(context)!;
    final notifier = ref.read(harvestFiltersProvider.notifier);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(loc.harvestFilterAllMonths),
                onTap: () {
                  notifier.setMonth(null);
                  Navigator.pop(ctx);
                },
              ),
              for (final m in available)
                ListTile(
                  title: Text(_shortMonth(m)),
                  onTap: () {
                    notifier.setMonth(m);
                    Navigator.pop(ctx);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickPlant(
    BuildContext context,
    WidgetRef ref,
    List<int> available,
    Map<int, Plant> plants,
  ) async {
    final loc = AppLocalizations.of(context)!;
    final notifier = ref.read(harvestFiltersProvider.notifier);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            ListTile(
              title: Text(loc.harvestFilterAllPlants),
              onTap: () {
                notifier.setPlantId(null);
                Navigator.pop(ctx);
              },
            ),
            for (final id in available)
              ListTile(
                title: Text(plants[id]?.commonName ?? '—'),
                onTap: () {
                  notifier.setPlantId(id);
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickUnit(
    BuildContext context,
    WidgetRef ref,
    List<String> available,
  ) async {
    final loc = AppLocalizations.of(context)!;
    final notifier = ref.read(harvestFiltersProvider.notifier);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(loc.harvestFilterAllUnits),
              onTap: () {
                notifier.setUnit(null);
                Navigator.pop(ctx);
              },
            ),
            for (final u in available)
              ListTile(
                title: Text(_unitLabel(loc, u)),
                onTap: () {
                  notifier.setUnit(u);
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _FilterChip({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.carnetSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: active ? AppColors.primary : AppColors.carnetLine,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 13,
                  color: active ? Colors.white : AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: active ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                PhosphorIcons.caretDown(PhosphorIconsStyle.bold),
                size: 10,
                color:
                    active ? Colors.white : AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClearFiltersChip extends StatelessWidget {
  final VoidCallback onTap;
  const _ClearFiltersChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(
            PhosphorIcons.x(PhosphorIconsStyle.bold),
            size: 12,
            color: AppColors.error,
          ),
        ),
      ),
    );
  }
}

class _NoMatchPlaceholder extends StatelessWidget {
  final VoidCallback onClear;
  const _NoMatchPlaceholder({required this.onClear});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: AppColors.carnetSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.carnetLine),
      ),
      child: Column(
        children: [
          Icon(
            PhosphorIcons.funnel(PhosphorIconsStyle.duotone),
            size: 32,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 10),
          Text(
            loc.harvestFilterNoMatchTitle,
            style: AppTypography.titleSmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            loc.harvestFilterNoMatchSubtitle,
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: onClear,
            child: Text(loc.harvestFilterReset),
          ),
        ],
      ),
    );
  }
}

class _SeasonHeader extends StatelessWidget {
  final int year;
  final List<HarvestSummary> summaries;
  const _SeasonHeader({required this.year, required this.summaries});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final totalCount =
        summaries.fold<int>(0, (sum, s) => sum + s.harvestCount);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.secondary.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.carnetLine),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              PhosphorIcons.basket(PhosphorIconsStyle.fill),
              size: 20,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.carnetHarvestsTitleYear(year),
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  loc.carnetHarvestsSummaryLine(
                    summaries.length,
                    totalCount,
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
    );
  }
}

class _HarvestSummaryCard extends StatelessWidget {
  final HarvestSummary summary;
  const _HarvestSummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final emoji = PlantEmojiMapper.fromName(
      summary.plantName,
      categoryCode: summary.plantCategoryCode,
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => HarvestHistorySheet.show(
          context,
          plantId: summary.plantId,
          plantName: summary.plantName,
          plantCategoryCode: summary.plantCategoryCode,
          unit: summary.unit,
        ),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: AppColors.carnetSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.carnetLine),
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.plantName,
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loc.carnetHarvestsCardSubtitle(
                        summary.harvestCount,
                        _formatRelativeDate(
                            context, summary.lastHarvestedAt),
                      ),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _QuantityBadge(
                quantity: summary.totalQuantity,
                unit: HarvestUnit.fromCode(summary.unit),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatRelativeDate(BuildContext context, DateTime d) {
    final loc = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diffDays = today.difference(day).inDays;
    if (diffDays == 0) return loc.dateRelativeToday;
    if (diffDays == 1) return loc.dateRelativeYesterday;
    if (diffDays < 7) return loc.dateRelativeDaysAgo(diffDays);
    const months = [
      'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
      'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
    ];
    return '${d.day} ${months[d.month - 1]}';
  }
}

class _QuantityBadge extends StatelessWidget {
  final double quantity;
  final HarvestUnit unit;
  const _QuantityBadge({required this.quantity, required this.unit});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final label = switch (unit) {
      HarvestUnit.grams => loc.addHarvestUnitGrams,
      HarvestUnit.kilos => loc.addHarvestUnitKilos,
      HarvestUnit.pieces => loc.addHarvestUnitPieces,
      HarvestUnit.bunches => loc.addHarvestUnitBunches,
    };
    // Format propre, jusqu'à 3 décimales sans zéros traînants :
    //   250    → "250"
    //   2.4    → "2,4"
    //   4.345  → "4,345"
    //   2.0    → "2"
    final formatted = _formatQuantity(quantity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            formatted,
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatQuantity(double q) {
  if (q == q.roundToDouble()) return q.toStringAsFixed(0);
  return q
      .toStringAsFixed(3)
      .replaceAll(RegExp(r'0+$'), '')
      .replaceAll(RegExp(r'\.$'), '')
      .replaceAll('.', ',');
}

class _AddButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _AddButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                PhosphorIcons.plus(PhosphorIconsStyle.bold),
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          style: AppTypography.caption.copyWith(color: AppColors.error),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
