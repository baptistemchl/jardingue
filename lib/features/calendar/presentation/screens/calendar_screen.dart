import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/providers/calendar_providers.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../core/services/database/database.dart';

/// Écran calendrier du potager
class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final activitiesAsync = ref.watch(monthActivitiesProvider(selectedMonth));

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _CalendarHeader(selectedMonth: selectedMonth),
            activitiesAsync.when(
              data: (activities) => _MonthCalendarWithActivities(
                selectedMonth: selectedMonth,
                activities: activities,
              ),
              loading: () => const _MonthCalendarWithActivities(
                selectedMonth: null,
                activities: null,
              ),
              error: (_, __) => const _MonthCalendarWithActivities(
                selectedMonth: null,
                activities: null,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const _ActivityFilters(),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: activitiesAsync.when(
                data: (activities) => _ActivitiesList(activities: activities),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Erreur: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// HEADER
// ============================================

class _CalendarHeader extends ConsumerWidget {
  final DateTime selectedMonth;

  const _CalendarHeader({required this.selectedMonth});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Calendrier', style: AppTypography.displayMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Planifiez vos activités au potager',
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              _TodayButton(
                onTap: () {
                  final now = DateTime.now();
                  ref.read(selectedMonthProvider.notifier).state = DateTime(now.year, now.month);
                },
                isCurrentMonth: selectedMonth.year == DateTime.now().year &&
                    selectedMonth.month == DateTime.now().month,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MonthNavButton(
                icon: PhosphorIcons.caretLeft(PhosphorIconsStyle.bold),
                onTap: () {
                  ref.read(selectedMonthProvider.notifier).state = DateTime(
                    selectedMonth.year,
                    selectedMonth.month - 1,
                  );
                },
              ),
              GestureDetector(
                onTap: () => _showMonthPicker(context, ref, selectedMonth),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: AppSpacing.borderRadiusFull,
                  ),
                  child: Text(
                    selectedMonth.frenchMonthYear,
                    style: AppTypography.titleMedium.copyWith(color: AppColors.primary),
                  ),
                ),
              ),
              _MonthNavButton(
                icon: PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
                onTap: () {
                  ref.read(selectedMonthProvider.notifier).state = DateTime(
                    selectedMonth.year,
                    selectedMonth.month + 1,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showMonthPicker(BuildContext context, WidgetRef ref, DateTime current) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _MonthPickerSheet(
        currentMonth: current,
        onMonthSelected: (month) {
          ref.read(selectedMonthProvider.notifier).state = month;
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _TodayButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isCurrentMonth;

  const _TodayButton({required this.onTap, required this.isCurrentMonth});

  @override
  Widget build(BuildContext context) {
    if (isCurrentMonth) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: AppSpacing.borderRadiusFull,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(PhosphorIcons.calendarBlank(PhosphorIconsStyle.fill), size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text('Aujourd\'hui', style: AppTypography.labelSmall.copyWith(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

class _MonthNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MonthNavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 20),
      ),
    );
  }
}

// ============================================
// CALENDRIER AVEC ACTIVITÉS
// ============================================

class _MonthCalendarWithActivities extends StatelessWidget {
  final DateTime? selectedMonth;
  final MonthActivities? activities;

  const _MonthCalendarWithActivities({
    required this.selectedMonth,
    required this.activities,
  });

  @override
  Widget build(BuildContext context) {
    final month = selectedMonth ?? DateTime.now();
    final now = DateTime.now();
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final startWeekday = (firstDay.weekday - 1) % 7;

    // Calcul du nombre de semaines nécessaires
    final totalDays = startWeekday + lastDay.day;
    final weeksNeeded = (totalDays / 7).ceil();
    final itemCount = weeksNeeded * 7;

    const dayNames = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

    // Détermine si le mois a des activités
    final hasSowingUnderCover = activities?.sowingUnderCover.isNotEmpty ?? false;
    final hasSowingOpenGround = activities?.sowingOpenGround.isNotEmpty ?? false;
    final hasPlanting = activities?.planting.isNotEmpty ?? false;
    final hasHarvest = activities?.harvest.isNotEmpty ?? false;

    return Container(
      margin: AppSpacing.horizontalPadding,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // En-têtes des jours
          Row(
            children: dayNames.map((d) => Expanded(
              child: Center(
                child: Text(
                  d,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: 8),

          // Grille des jours
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 1,
            ),
            itemCount: itemCount,
            itemBuilder: (context, index) {
              final dayOffset = index - startWeekday;
              if (dayOffset < 0 || dayOffset >= lastDay.day) {
                return const SizedBox();
              }

              final day = dayOffset + 1;
              final isToday = now.year == month.year &&
                  now.month == month.month &&
                  now.day == day;

              return _DayCell(
                day: day,
                isToday: isToday,
                hasSowingUnderCover: hasSowingUnderCover,
                hasSowingOpenGround: hasSowingOpenGround,
                hasPlanting: hasPlanting,
                hasHarvest: hasHarvest,
              );
            },
          ),

          // Légende des activités
          if (activities != null && !activities!.isEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: [
                if (hasSowingUnderCover)
                  _LegendChip(
                    color: GardenActivityType.sowingUnderCover.color,
                    label: 'Semis abri (${activities!.sowingUnderCover.length})',
                  ),
                if (hasSowingOpenGround)
                  _LegendChip(
                    color: GardenActivityType.sowingOpenGround.color,
                    label: 'Semis (${activities!.sowingOpenGround.length})',
                  ),
                if (hasPlanting)
                  _LegendChip(
                    color: GardenActivityType.planting.color,
                    label: 'Plantation (${activities!.planting.length})',
                  ),
                if (hasHarvest)
                  _LegendChip(
                    color: GardenActivityType.harvest.color,
                    label: 'Récolte (${activities!.harvest.length})',
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final bool isToday;
  final bool hasSowingUnderCover;
  final bool hasSowingOpenGround;
  final bool hasPlanting;
  final bool hasHarvest;

  const _DayCell({
    required this.day,
    required this.isToday,
    required this.hasSowingUnderCover,
    required this.hasSowingOpenGround,
    required this.hasPlanting,
    required this.hasHarvest,
  });

  @override
  Widget build(BuildContext context) {
    final hasActivities = hasSowingUnderCover || hasSowingOpenGround || hasPlanting || hasHarvest;

    // Couleurs des indicateurs
    final indicatorColors = <Color>[
      if (hasSowingUnderCover) GardenActivityType.sowingUnderCover.color,
      if (hasSowingOpenGround) GardenActivityType.sowingOpenGround.color,
      if (hasPlanting) GardenActivityType.planting.color,
      if (hasHarvest) GardenActivityType.harvest.color,
    ];

    return Container(
      decoration: BoxDecoration(
        color: isToday
            ? AppColors.primary
            : hasActivities
            ? AppColors.primaryContainer.withValues(alpha: 0.5)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: hasActivities && !isToday
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1)
            : null,
      ),
      child: Stack(
        children: [
          // Numéro du jour
          Center(
            child: Text(
              '$day',
              style: AppTypography.bodySmall.copyWith(
                color: isToday ? Colors.white : AppColors.textPrimary,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),

          // Indicateurs d'activités (petits points en bas)
          if (hasActivities && indicatorColors.isNotEmpty)
            Positioned(
              bottom: 3,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: indicatorColors.take(4).map((color) => Container(
                  width: 5,
                  height: 5,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: isToday ? Colors.white.withValues(alpha: 0.8) : color,
                    shape: BoxShape.circle,
                  ),
                )).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendChip({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

// ============================================
// FILTRES
// ============================================

class _ActivityFilters extends ConsumerWidget {
  const _ActivityFilters();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(activityFilterProvider);

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: AppSpacing.horizontalPadding,
        children: [
          _FilterChip(
            label: 'Tout',
            emoji: '📋',
            color: AppColors.primary,
            isSelected: currentFilter == null,
            onTap: () => ref.read(activityFilterProvider.notifier).state = null,
          ),
          const SizedBox(width: 8),
          ...GardenActivityType.values.map((type) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _FilterChip(
              label: type.label,
              emoji: type.emoji,
              color: type.color,
              isSelected: currentFilter == type,
              onTap: () => ref.read(activityFilterProvider.notifier).state = type,
            ),
          )),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : AppColors.surface,
          borderRadius: AppSpacing.borderRadiusFull,
          border: Border.all(color: isSelected ? color : AppColors.border),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(label, style: AppTypography.labelMedium.copyWith(color: isSelected ? Colors.white : AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}

// ============================================
// LISTE DES ACTIVITÉS
// ============================================

class _ActivitiesList extends ConsumerWidget {
  final MonthActivities activities;

  const _ActivitiesList({required this.activities});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(activityFilterProvider);

    if (activities.isEmpty) return _EmptyState();

    if (filter != null) {
      final filteredActivities = activities.getActivitiesByType(filter);
      if (filteredActivities.isEmpty) return _EmptyStateForType(type: filter);
      return _ActivitySection(type: filter, activities: filteredActivities);
    }

    return ListView(
      padding: AppSpacing.horizontalPadding,
      children: [
        if (activities.sowingUnderCover.isNotEmpty)
          _ActivitySection(type: GardenActivityType.sowingUnderCover, activities: activities.sowingUnderCover),
        if (activities.sowingOpenGround.isNotEmpty)
          _ActivitySection(type: GardenActivityType.sowingOpenGround, activities: activities.sowingOpenGround),
        if (activities.planting.isNotEmpty)
          _ActivitySection(type: GardenActivityType.planting, activities: activities.planting),
        if (activities.harvest.isNotEmpty)
          _ActivitySection(type: GardenActivityType.harvest, activities: activities.harvest),
        const SizedBox(height: 120),
      ],
    );
  }
}

class _ActivitySection extends StatelessWidget {
  final GardenActivityType type;
  final List<PlantActivity> activities;

  const _ActivitySection({required this.type, required this.activities});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: type.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(child: Text(type.emoji, style: const TextStyle(fontSize: 18))),
              ),
              const SizedBox(width: 12),
              Text(type.label, style: AppTypography.titleMedium),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: type.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${activities.length}', style: AppTypography.labelSmall.copyWith(color: type.color)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: activities.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) => _PlantActivityCard(activity: activities[index]),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}

class _PlantActivityCard extends StatelessWidget {
  final PlantActivity activity;

  const _PlantActivityCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    final plant = activity.plant;

    return GestureDetector(
      onTap: () => _showPlantDetail(context, plant),
      child: Container(
        width: 90,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppSpacing.borderRadiusMd,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: activity.activityType.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Text(plant.emoji, style: const TextStyle(fontSize: 24))),
            ),
            const SizedBox(height: 6),
            Text(
              plant.commonName,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  void _showPlantDetail(BuildContext context, Plant plant) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PlantCalendarDetailSheet(plant: plant),
    );
  }
}

// ============================================
// EMPTY STATES
// ============================================

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🌿', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text('Aucune activité ce mois', style: AppTypography.titleMedium),
          const SizedBox(height: 8),
          Text('Profitez pour préparer le terrain !', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _EmptyStateForType extends StatelessWidget {
  final GardenActivityType type;

  const _EmptyStateForType({required this.type});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(type.emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text('Pas de ${type.label.toLowerCase()}', style: AppTypography.titleMedium),
          const SizedBox(height: 8),
          Text('Ce n\'est pas la saison', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

// ============================================
// MONTH PICKER
// ============================================

class _MonthPickerSheet extends StatelessWidget {
  final DateTime currentMonth;
  final ValueChanged<DateTime> onMonthSelected;

  const _MonthPickerSheet({required this.currentMonth, required this.onMonthSelected});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    const months = ['Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Text('Choisir un mois', style: AppTypography.titleLarge),
          const SizedBox(height: 8),
          Text('${currentMonth.year}', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 2.2),
            itemCount: 12,
            itemBuilder: (context, index) {
              final month = index + 1;
              final isSelected = currentMonth.month == month;
              final isCurrentMonth = now.month == month && now.year == currentMonth.year;

              return GestureDetector(
                onTap: () => onMonthSelected(DateTime(currentMonth.year, month)),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : isCurrentMonth ? AppColors.primaryContainer : AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
                  ),
                  child: Center(
                    child: Text(
                      months[index].substring(0, 3),
                      style: AppTypography.labelMedium.copyWith(
                        color: isSelected ? Colors.white : isCurrentMonth ? AppColors.primary : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => onMonthSelected(DateTime(currentMonth.year - 1, currentMonth.month)),
                icon: Icon(PhosphorIcons.caretLeft(PhosphorIconsStyle.bold)),
              ),
              TextButton(onPressed: () => onMonthSelected(DateTime(now.year, now.month)), child: const Text('Aujourd\'hui')),
              IconButton(
                onPressed: () => onMonthSelected(DateTime(currentMonth.year + 1, currentMonth.month)),
                icon: Icon(PhosphorIcons.caretRight(PhosphorIconsStyle.bold)),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 10),
        ],
      ),
    );
  }
}

// ============================================
// PLANT DETAIL SHEET
// ============================================

class _PlantCalendarDetailSheet extends StatelessWidget {
  final Plant plant;

  const _PlantCalendarDetailSheet({required this.plant});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(14)),
                    child: Center(child: Text(plant.emoji, style: const TextStyle(fontSize: 32))),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(plant.commonName, style: AppTypography.titleLarge),
                        Text(plant.categoryDisplayLabel, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _PlantYearCalendar(plant: plant),
              const SizedBox(height: 20),
              if (plant.sowingUnderCoverPeriod != null)
                _PeriodInfo(type: GardenActivityType.sowingUnderCover, value: plant.sowingUnderCoverPeriod!),
              if (plant.sowingOpenGroundPeriod != null)
                _PeriodInfo(type: GardenActivityType.sowingOpenGround, value: plant.sowingOpenGroundPeriod!),
              if (plant.transplantingPeriod != null)
                _PeriodInfo(type: GardenActivityType.planting, value: plant.transplantingPeriod!),
              if (plant.harvestPeriod != null)
                _PeriodInfo(type: GardenActivityType.harvest, value: plant.harvestPeriod!),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}

class _PlantYearCalendar extends StatelessWidget {
  final Plant plant;

  const _PlantYearCalendar({required this.plant});

  @override
  Widget build(BuildContext context) {
    const months = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
    const monthsFull = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Légende
          Wrap(
            spacing: 12,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              _SmallLegend(color: GardenActivityType.sowingUnderCover.color, label: 'Semis abri'),
              _SmallLegend(color: GardenActivityType.sowingOpenGround.color, label: 'Semis'),
              _SmallLegend(color: GardenActivityType.planting.color, label: 'Plantation'),
              _SmallLegend(color: GardenActivityType.harvest.color, label: 'Récolte'),
            ],
          ),
          const SizedBox(height: 12),

          // Grille des mois
          Row(
            children: List.generate(12, (index) {
              final monthName = monthsFull[index];
              final activities = _getMonthActivities(plant, monthName);

              return Expanded(
                child: Column(
                  children: [
                    Text(months[index], style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600, color: AppColors.textTertiary)),
                    const SizedBox(height: 4),
                    Container(
                      height: 28,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: activities.isEmpty
                            ? AppColors.border.withValues(alpha: 0.3)
                            : null,
                        gradient: activities.isNotEmpty
                            ? LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: activities.length == 1
                              ? [activities.first.color, activities.first.color]
                              : activities.map((a) => a.color).toList(),
                        )
                            : null,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  List<GardenActivityType> _getMonthActivities(Plant plant, String monthName) {
    final activities = <GardenActivityType>[];

    final sowingData = _parseCalendar(plant.sowingCalendar);
    if (sowingData != null) {
      final value = sowingData[monthName];
      if (value != null && value.toString().startsWith('Oui')) {
        if (value.toString().contains('sous abri')) {
          activities.add(GardenActivityType.sowingUnderCover);
        } else {
          activities.add(GardenActivityType.sowingOpenGround);
        }
      }
    }

    final plantingData = _parseCalendar(plant.plantingCalendar);
    if (plantingData != null) {
      final value = plantingData[monthName];
      if (value != null && value.toString().startsWith('Oui')) {
        activities.add(GardenActivityType.planting);
      }
    }

    final harvestData = _parseCalendar(plant.harvestCalendar);
    if (harvestData != null) {
      final value = harvestData[monthName];
      if (value != null && value.toString().startsWith('Oui')) {
        activities.add(GardenActivityType.harvest);
      }
    }

    return activities;
  }

  Map<String, dynamic>? _parseCalendar(String? calendarJson) {
    if (calendarJson == null) return null;
    try {
      final data = json.decode(calendarJson) as Map<String, dynamic>;
      return data['monthly_period'] as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }
}

class _SmallLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _SmallLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label, style: AppTypography.caption.copyWith(fontSize: 10)),
      ],
    );
  }
}

class _PeriodInfo extends StatelessWidget {
  final GardenActivityType type;
  final String value;

  const _PeriodInfo({required this.type, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: type.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text(type.emoji, style: const TextStyle(fontSize: 14))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(type.label, style: AppTypography.labelSmall.copyWith(color: type.color)),
                Text(value, style: AppTypography.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}