import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/providers/calendar_providers.dart';
import '../../../../core/services/database/database.dart';
import '../../../../features/plants/domain/models/plant_helpers.dart';
import 'calendar_empty_states.dart';
import 'calendar_plant_detail_sheet.dart';

// ============================================
// VUE LISTE DU MOIS
// ============================================

class MonthListView extends StatelessWidget {
  final DateTime selectedMonth;
  final MonthActivities activities;

  const MonthListView({super.key, required this.selectedMonth, required this.activities});

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return EmptyState();
    }

    // Combiner toutes les activités dans une liste unique
    final allActivities = <ActivityItem>[];

    for (final activity in activities.sowingUnderCover) {
      allActivities.add(
        ActivityItem(
          plant: activity.plant,
          type: GardenActivityType.sowingUnderCover,
          detail: activity.detail,
        ),
      );
    }
    for (final activity in activities.sowingOpenGround) {
      allActivities.add(
        ActivityItem(
          plant: activity.plant,
          type: GardenActivityType.sowingOpenGround,
          detail: activity.detail,
        ),
      );
    }
    for (final activity in activities.planting) {
      allActivities.add(
        ActivityItem(
          plant: activity.plant,
          type: GardenActivityType.planting,
          detail: activity.detail,
        ),
      );
    }
    for (final activity in activities.harvest) {
      allActivities.add(
        ActivityItem(
          plant: activity.plant,
          type: GardenActivityType.harvest,
          detail: activity.detail,
        ),
      );
    }

    // Trier par nom de plante
    allActivities.sort(
      (a, b) => a.plant.commonName.compareTo(b.plant.commonName),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Résumé du mois
        MonthSummaryCard(activities: activities, selectedMonth: selectedMonth),
        const SizedBox(height: AppSpacing.md),

        // Liste complète
        Expanded(
          child: ListView.builder(
            padding: AppSpacing.horizontalPadding,
            itemCount: allActivities.length + 1, // +1 pour le padding final
            itemBuilder: (context, index) {
              if (index == allActivities.length) {
                return const SizedBox(height: 120);
              }
              return _ActivityListTile(item: allActivities[index]);
            },
          ),
        ),
      ],
    );
  }
}

class ActivityItem {
  final Plant plant;
  final GardenActivityType type;
  final String? detail;

  ActivityItem({required this.plant, required this.type, this.detail});
}

class MonthSummaryCard extends StatelessWidget {
  final MonthActivities activities;
  final DateTime selectedMonth;

  const MonthSummaryCard({
    super.key,
    required this.activities,
    required this.selectedMonth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: AppSpacing.horizontalPadding,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.secondary.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                PhosphorIcons.calendarCheck(PhosphorIconsStyle.fill),
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'À faire en ${selectedMonth.frenchMonthName}',
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Stats par type
          Row(
            children: [
              if (activities.sowingUnderCover.isNotEmpty)
                _SummaryChip(
                  emoji: GardenActivityType.sowingUnderCover.emoji,
                  count: activities.sowingUnderCover.length,
                  color: GardenActivityType.sowingUnderCover.color,
                ),
              if (activities.sowingOpenGround.isNotEmpty)
                _SummaryChip(
                  emoji: GardenActivityType.sowingOpenGround.emoji,
                  count: activities.sowingOpenGround.length,
                  color: GardenActivityType.sowingOpenGround.color,
                ),
              if (activities.planting.isNotEmpty)
                _SummaryChip(
                  emoji: GardenActivityType.planting.emoji,
                  count: activities.planting.length,
                  color: GardenActivityType.planting.color,
                ),
              if (activities.harvest.isNotEmpty)
                _SummaryChip(
                  emoji: GardenActivityType.harvest.emoji,
                  count: activities.harvest.length,
                  color: GardenActivityType.harvest.color,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String emoji;
  final int count;
  final Color color;

  const _SummaryChip({
    required this.emoji,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: AppSpacing.borderRadiusFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: AppTypography.labelMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityListTile extends StatelessWidget {
  final ActivityItem item;

  const _ActivityListTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showPlantDetail(context, item.plant),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppSpacing.borderRadiusMd,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // Emoji plante
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  item.plant.emoji,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.plant.commonName, style: AppTypography.titleSmall),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: item.type.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item.type.emoji,
                              style: const TextStyle(fontSize: 10),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              item.type.label,
                              style: AppTypography.caption.copyWith(
                                color: item.type.color,
                                fontWeight: FontWeight.w500,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (item.detail != null) ...[
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item.detail!,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Chevron
            Icon(
              PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
              color: AppColors.textTertiary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
