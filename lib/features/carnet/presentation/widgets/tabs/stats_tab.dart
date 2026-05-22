import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/utils/plant_emoji_mapper.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../../domain/models/carnet_stats.dart';
import '../../providers/stats_providers.dart';
import '../charts/animated_counter.dart';
import '../charts/monthly_bar_chart.dart';
import '../charts/success_ring.dart';
import '../charts/top_plants_bars.dart';
import '../_empty_tab_placeholder.dart';

class StatsTab extends ConsumerWidget {
  const StatsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final stats = ref.watch(carnetStatsProvider);

    if (stats.isEmpty) {
      return EmptyTabPlaceholder(
        icon: PhosphorIcons.chartBar(PhosphorIconsStyle.duotone),
        title: loc.carnetStatsEmptyTitle,
        subtitle: loc.carnetStatsEmptySubtitle,
      );
    }

    final currentMonth = DateTime.now().month;
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _HeroCard(year: stats.year, stats: stats),
        const SizedBox(height: 14),
        if (stats.plantOfTheYear != null) ...[
          _PlantOfTheYearCard(plant: stats.plantOfTheYear!),
          const SizedBox(height: 14),
        ],
        _MonthlyChartCard(
          values: stats.harvestsByMonth,
          bestMonth: stats.bestMonth,
          currentMonth: currentMonth,
        ),
        const SizedBox(height: 14),
        if (stats.topPlants.isNotEmpty) ...[
          _TopPlantsCard(plants: stats.topPlants),
          const SizedBox(height: 14),
        ],
        if (stats.seedlingsTotal > 0) ...[
          _SeedlingsSuccessCard(stats: stats),
          const SizedBox(height: 14),
        ],
        if (stats.totalGardenActivities > 0) ...[
          _GardenActivitiesCard(stats: stats),
          const SizedBox(height: 14),
        ],
        _MiscCountersRow(stats: stats),
      ],
    );
  }
}

/// Hero — gros poids cumulé en kg + secondary stats en chips.
class _HeroCard extends StatelessWidget {
  final int year;
  final dynamic stats;
  const _HeroCard({required this.year, required this.stats});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                PhosphorIcons.calendarHeart(PhosphorIconsStyle.fill),
                color: AppColors.secondary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                loc.carnetStatsHeroSeasonLabel(year),
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AnimatedCounter(
                value: stats.totalWeightKg,
                fractionDigits: stats.totalWeightKg < 10 ? 2 : 1,
                style: AppTypography.displayLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.5,
                  height: 1,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'kg',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            loc.carnetStatsHeroSubtitle(stats.totalHarvestCount),
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          if (stats.totalPieces > 0 || stats.totalBunches > 0) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (stats.totalPieces > 0)
                  _HeroChip(
                    icon: PhosphorIcons.appleLogo(PhosphorIconsStyle.fill),
                    text:
                        loc.carnetStatsHeroPieces(stats.totalPieces),
                  ),
                if (stats.totalBunches > 0)
                  _HeroChip(
                    icon: PhosphorIcons.flowerTulip(PhosphorIconsStyle.fill),
                    text:
                        loc.carnetStatsHeroBunches(stats.totalBunches),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _HeroChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.secondary),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppTypography.caption.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlantOfTheYearCard extends StatelessWidget {
  final dynamic plant;
  const _PlantOfTheYearCard({required this.plant});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final emoji = PlantEmojiMapper.fromName(
      plant.plantName,
      categoryCode: plant.plantCategoryCode,
    );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.secondary.withValues(alpha: 0.12),
            AppColors.warning.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondary.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      PhosphorIcons.star(PhosphorIconsStyle.fill),
                      size: 12,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      loc.carnetStatsPlantOfTheYearLabel,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  plant.plantName,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  loc.carnetStatsPlantOfTheYearCount(plant.harvestCount),
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

class _MonthlyChartCard extends StatelessWidget {
  final List<int> values;
  final int? bestMonth;
  final int currentMonth;
  const _MonthlyChartCard({
    required this.values,
    required this.bestMonth,
    required this.currentMonth,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return _SectionCard(
      icon: PhosphorIcons.chartBar(PhosphorIconsStyle.fill),
      title: loc.carnetStatsMonthlyTitle,
      child: MonthlyBarChart(
        values: values,
        bestMonth: bestMonth,
        currentMonth: currentMonth,
      ),
    );
  }
}

class _TopPlantsCard extends ConsumerWidget {
  final List<dynamic> plants;
  const _TopPlantsCard({required this.plants});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final mode = ref.watch(topPlantsSortProvider);
    final notifier = ref.read(topPlantsSortProvider.notifier);
    return _SectionCard(
      icon: PhosphorIcons.trophy(PhosphorIconsStyle.fill),
      title: loc.carnetStatsTopPlantsTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 28,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              children: [
                _SortChip(
                  label: loc.carnetStatsTopSortWeight,
                  active: mode == TopPlantsSortMode.weight,
                  onTap: () => notifier.set(TopPlantsSortMode.weight),
                ),
                const SizedBox(width: 6),
                _SortChip(
                  label: loc.carnetStatsTopSortCount,
                  active: mode == TopPlantsSortMode.count,
                  onTap: () => notifier.set(TopPlantsSortMode.count),
                ),
                const SizedBox(width: 6),
                _SortChip(
                  label: loc.carnetStatsTopSortPieces,
                  active: mode == TopPlantsSortMode.pieces,
                  onTap: () => notifier.set(TopPlantsSortMode.pieces),
                ),
                const SizedBox(width: 6),
                _SortChip(
                  label: loc.carnetStatsTopSortBunches,
                  active: mode == TopPlantsSortMode.bunches,
                  onTap: () => notifier.set(TopPlantsSortMode.bunches),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          TopPlantsBars(plants: plants.cast(), sortMode: mode),
        ],
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _SortChip({
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
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active
                  ? AppColors.primary
                  : AppColors.border.withValues(alpha: 0.5),
            ),
          ),
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              color: active ? Colors.white : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }
}

class _SeedlingsSuccessCard extends StatelessWidget {
  final dynamic stats;
  const _SeedlingsSuccessCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.carnetSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.carnetLine),
      ),
      child: Row(
        children: [
          SuccessRing(
            rate: stats.seedlingSuccessRate,
            label: loc.carnetStatsSeedlingsRingLabel,
            size: 110,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.carnetStatsSeedlingsTitle,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                _SeedStatLine(
                  color: AppColors.success,
                  label: loc.carnetStatsSeedlingsTransplanted,
                  value: stats.seedlingsTransplanted,
                ),
                const SizedBox(height: 4),
                _SeedStatLine(
                  color: AppColors.error,
                  label: loc.carnetStatsSeedlingsFailed,
                  value: stats.seedlingsFailed,
                ),
                const SizedBox(height: 4),
                _SeedStatLine(
                  color: AppColors.info,
                  label: loc.carnetStatsSeedlingsInProgress,
                  value: stats.seedlingsTotal -
                      stats.seedlingsTransplanted -
                      stats.seedlingsFailed,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SeedStatLine extends StatelessWidget {
  final Color color;
  final String label;
  final int value;
  const _SeedStatLine({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          '$value',
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// Carte « Activités du jardin » — récap des actions enregistrées dans
/// les autres écrans (arrosages, fertilisations, semis, plantations,
/// paillages) agrégées depuis GardenEvents pour l'année courante. Chaque
/// activité a son icône couleur + un compteur animé.
class _GardenActivitiesCard extends StatelessWidget {
  final dynamic stats;
  const _GardenActivitiesCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final items = <_ActivityItem>[
      if (stats.wateringCount > 0)
        _ActivityItem(
          icon: PhosphorIcons.dropHalf(PhosphorIconsStyle.fill),
          label: loc.carnetStatsActivityWateringPlants,
          value: stats.wateringCount,
          color: AppColors.info,
        ),
      if (stats.wateringSeedlingCount > 0)
        _ActivityItem(
          icon: PhosphorIcons.drop(PhosphorIconsStyle.fill),
          label: loc.carnetStatsActivityWateringSeedlings,
          value: stats.wateringSeedlingCount,
          color: AppColors.primaryLight,
        ),
      if (stats.fertilizingCount > 0)
        _ActivityItem(
          icon: PhosphorIcons.flask(PhosphorIconsStyle.fill),
          label: loc.carnetStatsActivityFertilizing,
          value: stats.fertilizingCount,
          color: AppColors.secondary,
        ),
      if (stats.sowingEventsCount > 0)
        _ActivityItem(
          icon: PhosphorIcons.plant(PhosphorIconsStyle.fill),
          label: loc.carnetStatsActivitySowing,
          value: stats.sowingEventsCount,
          color: AppColors.primary,
        ),
      if (stats.plantingEventsCount > 0)
        _ActivityItem(
          icon: PhosphorIcons.shovel(PhosphorIconsStyle.fill),
          label: loc.carnetStatsActivityPlanting,
          value: stats.plantingEventsCount,
          color: AppColors.success,
        ),
      if (stats.mulchingCount > 0)
        _ActivityItem(
          icon: PhosphorIcons.stack(PhosphorIconsStyle.fill),
          label: loc.carnetStatsActivityMulching,
          value: stats.mulchingCount,
          color: AppColors.tertiary,
        ),
      if (stats.otherCareCount > 0)
        _ActivityItem(
          icon: PhosphorIcons.heart(PhosphorIconsStyle.fill),
          label: loc.carnetStatsActivityOtherCare,
          value: stats.otherCareCount,
          color: AppColors.warning,
        ),
    ];
    return _SectionCard(
      icon: PhosphorIcons.leaf(PhosphorIconsStyle.fill),
      title: loc.carnetStatsActivitiesTitle,
      child: Column(
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: _ActivityRow(item: item),
            ),
        ],
      ),
    );
  }
}

class _ActivityItem {
  final IconData icon;
  final String label;
  final int value;
  final Color color;
  const _ActivityItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}

class _ActivityRow extends StatelessWidget {
  final _ActivityItem item;
  const _ActivityRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: item.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(item.icon, size: 16, color: item.color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            item.label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        AnimatedCounter(
          value: item.value.toDouble(),
          fractionDigits: 0,
          style: AppTypography.titleSmall.copyWith(
            fontWeight: FontWeight.w800,
            color: item.color,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _MiscCountersRow extends StatelessWidget {
  final dynamic stats;
  const _MiscCountersRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: _MiniCounter(
            icon: PhosphorIcons.notebook(PhosphorIconsStyle.fill),
            value: stats.journalEntriesCount,
            label: loc.carnetStatsCounterNotes,
            color: AppColors.info,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniCounter(
            icon: PhosphorIcons.plant(PhosphorIconsStyle.fill),
            value: stats.seedlingsTotal,
            label: loc.carnetStatsCounterSeedlings,
            color: AppColors.tertiary,
          ),
        ),
      ],
    );
  }
}

class _MiniCounter extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;
  final Color color;
  const _MiniCounter({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.carnetSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.carnetLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(height: 10),
          AnimatedCounter(
            value: value.toDouble(),
            fractionDigits: 0,
            style: AppTypography.headlineMedium.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.carnetSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.carnetLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                title,
                style: AppTypography.labelSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
