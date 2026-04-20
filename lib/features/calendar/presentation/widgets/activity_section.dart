import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/providers/calendar_providers.dart';
import '../../../../features/plants/domain/models/plant_helpers.dart';
import 'calendar_plant_detail_sheet.dart';

// ============================================
// FILTRES
// ============================================

class ActivityFilters extends ConsumerWidget {
  const ActivityFilters({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(activityFilterProvider);

    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: AppSpacing.horizontalPadding,
        children: [
          _FilterChip(
            label: 'Tout',
            emoji: '📋',
            color: AppColors.primary,
            isSelected: currentFilter == null,
            onTap: () => ref.read(activityFilterProvider.notifier).set(null),
          ),
          const SizedBox(width: 8),
          ...GardenActivityType.values.map(
            (type) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _FilterChip(
                label: type.label,
                emoji: type.emoji,
                color: type.color,
                isSelected: currentFilter == type,
                onTap: () =>
                    ref.read(activityFilterProvider.notifier).set(type),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String emoji;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.emoji,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : AppColors.surface,
          borderRadius: AppSpacing.borderRadiusFull,
          border: Border.all(color: isSelected ? color : AppColors.border),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// SECTIONS D'ACTIVITÉS SCROLLABLES
// ============================================

class ActivitySectionScrollable extends StatelessWidget {
  final GardenActivityType type;
  final List<PlantActivity> activities;

  const ActivitySectionScrollable({
    super.key,
    required this.type,
    required this.activities,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.horizontalPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de section
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: type.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      type.emoji,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(type.label, style: AppTypography.titleSmall),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: type.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${activities.length}',
                    style: AppTypography.caption.copyWith(
                      color: type.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Cards horizontales
          SizedBox(
            height: 115,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: activities.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) =>
                  PlantActivityCardImproved(activity: activities[index]),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

class PlantActivityCardImproved extends StatelessWidget {
  final PlantActivity activity;

  const PlantActivityCardImproved({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final plant = activity.plant;

    return GestureDetector(
      onTap: () => showPlantDetail(context, plant),
      child: Container(
        width: 85,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppSpacing.borderRadiusMd,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Emoji
            Text(plant.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 6),
            // Nom avec gestion overflow
            Flexible(
              child: Text(
                plant.commonName,
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
