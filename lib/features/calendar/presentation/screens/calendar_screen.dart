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

// ============================================
// PROVIDER POUR LA VUE SÉLECTIONNÉE
// ============================================

enum CalendarViewType { calendar, list }

final calendarViewProvider = StateProvider<CalendarViewType>(
  (ref) => CalendarViewType.calendar,
);

/// Écran calendrier du potager
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    ref.read(calendarViewProvider.notifier).state = index == 0
        ? CalendarViewType.calendar
        : CalendarViewType.list;
  }

  void _onTabChanged(CalendarViewType view) {
    final targetPage = view == CalendarViewType.calendar ? 0 : 1;
    _pageController.animateToPage(
      targetPage,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final activitiesAsync = ref.watch(monthActivitiesProvider(selectedMonth));
    final currentView = ref.watch(calendarViewProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Background décoratif
          const _DecorativeBackground(),

          // Contenu
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _CalendarHeader(selectedMonth: selectedMonth),
                const SizedBox(height: AppSpacing.sm),

                // TabBar pour choisir la vue
                _ViewTabBar(
                  currentView: currentView,
                  onTabChanged: _onTabChanged,
                ),
                const SizedBox(height: AppSpacing.md),

                // Contenu avec PageView pour le swipe
                Expanded(
                  child: activitiesAsync.when(
                    data: (activities) => PageView(
                      controller: _pageController,
                      onPageChanged: _onPageChanged,
                      children: [
                        _CalendarView(
                          selectedMonth: selectedMonth,
                          activities: activities,
                        ),
                        _MonthListView(
                          selectedMonth: selectedMonth,
                          activities: activities,
                        ),
                      ],
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Erreur: $e')),
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

// ============================================
// TAB BAR VUE CALENDRIER / LISTE
// ============================================

class _ViewTabBar extends StatelessWidget {
  final CalendarViewType currentView;
  final void Function(CalendarViewType) onTabChanged;

  const _ViewTabBar({required this.currentView, required this.onTabChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.horizontalPadding,
      child: Container(
        height: 44,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppSpacing.borderRadiusFull,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: _TabButton(
                icon: PhosphorIcons.calendarDots(PhosphorIconsStyle.fill),
                label: 'Calendrier',
                isSelected: currentView == CalendarViewType.calendar,
                onTap: () => onTabChanged(CalendarViewType.calendar),
              ),
            ),
            Expanded(
              child: _TabButton(
                icon: PhosphorIcons.listBullets(PhosphorIconsStyle.fill),
                label: 'Liste du mois',
                isSelected: currentView == CalendarViewType.list,
                onTap: () => onTabChanged(CalendarViewType.list),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: AppSpacing.borderRadiusFull,
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================
// VUE CALENDRIER (compacte) - ENTIÈREMENT SCROLLABLE
// ============================================

class _CalendarView extends ConsumerWidget {
  final DateTime selectedMonth;
  final MonthActivities activities;

  const _CalendarView({required this.selectedMonth, required this.activities});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(activityFilterProvider);

    if (activities.isEmpty) {
      return Column(
        children: [
          _CompactMonthCalendar(
            selectedMonth: selectedMonth,
            activities: activities,
          ),
          const SizedBox(height: AppSpacing.md),
          const _ActivityFilters(),
          Expanded(child: _EmptyState()),
        ],
      );
    }

    return CustomScrollView(
      slivers: [
        // Calendrier compact
        SliverToBoxAdapter(
          child: _CompactMonthCalendar(
            selectedMonth: selectedMonth,
            activities: activities,
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

        // Filtres
        const SliverToBoxAdapter(child: _ActivityFilters()),

        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

        // Sections d'activités
        if (filter != null) ...[
          ..._buildFilteredSections(activities, filter),
        ] else ...[
          if (activities.sowingUnderCover.isNotEmpty)
            SliverToBoxAdapter(
              child: _ActivitySectionScrollable(
                type: GardenActivityType.sowingUnderCover,
                activities: activities.sowingUnderCover,
              ),
            ),
          if (activities.sowingOpenGround.isNotEmpty)
            SliverToBoxAdapter(
              child: _ActivitySectionScrollable(
                type: GardenActivityType.sowingOpenGround,
                activities: activities.sowingOpenGround,
              ),
            ),
          if (activities.planting.isNotEmpty)
            SliverToBoxAdapter(
              child: _ActivitySectionScrollable(
                type: GardenActivityType.planting,
                activities: activities.planting,
              ),
            ),
          if (activities.harvest.isNotEmpty)
            SliverToBoxAdapter(
              child: _ActivitySectionScrollable(
                type: GardenActivityType.harvest,
                activities: activities.harvest,
              ),
            ),
        ],

        // Padding en bas pour la navigation
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }

  List<Widget> _buildFilteredSections(
    MonthActivities activities,
    GardenActivityType filter,
  ) {
    final filteredActivities = activities.getActivitiesByType(filter);
    if (filteredActivities.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _EmptyStateForType(type: filter),
        ),
      ];
    }
    return [
      SliverToBoxAdapter(
        child: _ActivitySectionScrollable(
          type: filter,
          activities: filteredActivities,
        ),
      ),
    ];
  }
}

// ============================================
// CALENDRIER COMPACT
// ============================================

class _CompactMonthCalendar extends StatelessWidget {
  final DateTime selectedMonth;
  final MonthActivities activities;

  const _CompactMonthCalendar({
    required this.selectedMonth,
    required this.activities,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final firstDay = DateTime(selectedMonth.year, selectedMonth.month, 1);
    final lastDay = DateTime(selectedMonth.year, selectedMonth.month + 1, 0);
    final startWeekday = (firstDay.weekday - 1) % 7;

    final totalDays = startWeekday + lastDay.day;
    final weeksNeeded = (totalDays / 7).ceil();
    final itemCount = weeksNeeded * 7;

    const dayNames = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

    final hasSowingUnderCover = activities.sowingUnderCover.isNotEmpty;
    final hasSowingOpenGround = activities.sowingOpenGround.isNotEmpty;
    final hasPlanting = activities.planting.isNotEmpty;
    final hasHarvest = activities.harvest.isNotEmpty;

    return Container(
      margin: AppSpacing.horizontalPadding,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // En-têtes des jours
          Row(
            children: dayNames
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textTertiary,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 6),

          // Grille des jours - COMPACT
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
              childAspectRatio: 1.3, // Plus large que haut = plus compact
            ),
            itemCount: itemCount,
            itemBuilder: (context, index) {
              final dayOffset = index - startWeekday;
              if (dayOffset < 0 || dayOffset >= lastDay.day) {
                return const SizedBox();
              }

              final day = dayOffset + 1;
              final isToday =
                  now.year == selectedMonth.year &&
                  now.month == selectedMonth.month &&
                  now.day == day;

              return _CompactDayCell(
                day: day,
                isToday: isToday,
                hasActivities:
                    hasSowingUnderCover ||
                    hasSowingOpenGround ||
                    hasPlanting ||
                    hasHarvest,
              );
            },
          ),

          // Mini légende
          if (!activities.isEmpty) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (hasSowingUnderCover)
                  _MiniLegendDot(
                    color: GardenActivityType.sowingUnderCover.color,
                  ),
                if (hasSowingOpenGround)
                  _MiniLegendDot(
                    color: GardenActivityType.sowingOpenGround.color,
                  ),
                if (hasPlanting)
                  _MiniLegendDot(color: GardenActivityType.planting.color),
                if (hasHarvest)
                  _MiniLegendDot(color: GardenActivityType.harvest.color),
                const SizedBox(width: 8),
                Text(
                  '${activities.totalActivities} activités ce mois',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CompactDayCell extends StatelessWidget {
  final int day;
  final bool isToday;
  final bool hasActivities;

  const _CompactDayCell({
    required this.day,
    required this.isToday,
    required this.hasActivities,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isToday
            ? AppColors.primary
            : hasActivities
            ? AppColors.primaryContainer.withValues(alpha: 0.4)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          '$day',
          style: AppTypography.caption.copyWith(
            color: isToday ? Colors.white : AppColors.textPrimary,
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _MiniLegendDot extends StatelessWidget {
  final Color color;

  const _MiniLegendDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

// ============================================
// VUE LISTE DU MOIS
// ============================================

class _MonthListView extends StatelessWidget {
  final DateTime selectedMonth;
  final MonthActivities activities;

  const _MonthListView({required this.selectedMonth, required this.activities});

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return _EmptyState();
    }

    // Combiner toutes les activités dans une liste unique
    final allActivities = <_ActivityItem>[];

    for (final activity in activities.sowingUnderCover) {
      allActivities.add(
        _ActivityItem(
          plant: activity.plant,
          type: GardenActivityType.sowingUnderCover,
          detail: activity.detail,
        ),
      );
    }
    for (final activity in activities.sowingOpenGround) {
      allActivities.add(
        _ActivityItem(
          plant: activity.plant,
          type: GardenActivityType.sowingOpenGround,
          detail: activity.detail,
        ),
      );
    }
    for (final activity in activities.planting) {
      allActivities.add(
        _ActivityItem(
          plant: activity.plant,
          type: GardenActivityType.planting,
          detail: activity.detail,
        ),
      );
    }
    for (final activity in activities.harvest) {
      allActivities.add(
        _ActivityItem(
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
        _MonthSummaryCard(activities: activities, selectedMonth: selectedMonth),
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

class _ActivityItem {
  final Plant plant;
  final GardenActivityType type;
  final String? detail;

  _ActivityItem({required this.plant, required this.type, this.detail});
}

class _MonthSummaryCard extends StatelessWidget {
  final MonthActivities activities;
  final DateTime selectedMonth;

  const _MonthSummaryCard({
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
  final _ActivityItem item;

  const _ActivityListTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPlantDetail(context, item.plant),
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
          const SizedBox(height: AppSpacing.md),
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
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _TodayButton(
                onTap: () {
                  final now = DateTime.now();
                  ref.read(selectedMonthProvider.notifier).state = DateTime(
                    now.year,
                    now.month,
                  );
                },
                isCurrentMonth:
                    selectedMonth.year == DateTime.now().year &&
                    selectedMonth.month == DateTime.now().month,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: AppSpacing.borderRadiusFull,
                  ),
                  child: Text(
                    selectedMonth.frenchMonthYear,
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.primary,
                    ),
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
            Icon(
              PhosphorIcons.calendarBlank(PhosphorIconsStyle.fill),
              size: 16,
              color: Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              'Aujourd\'hui',
              style: AppTypography.labelSmall.copyWith(color: Colors.white),
            ),
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
// FILTRES
// ============================================

class _ActivityFilters extends ConsumerWidget {
  const _ActivityFilters();

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
            onTap: () => ref.read(activityFilterProvider.notifier).state = null,
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
                    ref.read(activityFilterProvider.notifier).state = type,
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

class _ActivitySectionScrollable extends StatelessWidget {
  final GardenActivityType type;
  final List<PlantActivity> activities;

  const _ActivitySectionScrollable({
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
            height: 105,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: activities.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) =>
                  _PlantActivityCardImproved(activity: activities[index]),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

class _PlantActivityCardImproved extends StatelessWidget {
  final PlantActivity activity;

  const _PlantActivityCardImproved({required this.activity});

  @override
  Widget build(BuildContext context) {
    final plant = activity.plant;

    return GestureDetector(
      onTap: () => _showPlantDetail(context, plant),
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// ÉTATS VIDES
// ============================================

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🌱', style: TextStyle(fontSize: 36)),
              ),
            ),
            const SizedBox(height: 20),
            Text('Aucune activité ce mois', style: AppTypography.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Ajoutez des plantes à votre potager pour voir les activités recommandées',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(type.emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              'Pas de ${type.label.toLowerCase()}',
              style: AppTypography.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Aucune plante à ${type.label.toLowerCase()} ce mois',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// MONTH PICKER
// ============================================

class _MonthPickerSheet extends StatelessWidget {
  final DateTime currentMonth;
  final Function(DateTime) onMonthSelected;

  const _MonthPickerSheet({
    required this.currentMonth,
    required this.onMonthSelected,
  });

  @override
  Widget build(BuildContext context) {
    final months = [
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre',
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text('Choisir un mois', style: AppTypography.titleLarge),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2,
            ),
            itemCount: 12,
            itemBuilder: (context, index) {
              final isSelected = currentMonth.month == index + 1;
              return GestureDetector(
                onTap: () =>
                    onMonthSelected(DateTime(currentMonth.year, index + 1)),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      months[index].substring(0, 3),
                      style: AppTypography.labelMedium.copyWith(
                        color: isSelected
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

// ============================================
// PLANT DETAIL BOTTOM SHEET (COMPLET)
// ============================================

void _showPlantDetail(BuildContext context, Plant plant) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => ProviderScope(
      parent: ProviderScope.containerOf(context),
      child: _PlantDetailSheet(plant: plant),
    ),
  );
}

class _PlantDetailSheet extends ConsumerWidget {
  final Plant plant;

  const _PlantDetailSheet({required this.plant});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companionsAsync = ref.watch(plantCompanionsProvider(plant.id));
    final antagonistsAsync = ref.watch(plantAntagonistsProvider(plant.id));

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
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
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Header
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: AppSpacing.borderRadiusLg,
                    ),
                    child: Center(
                      child: Text(
                        plant.emoji,
                        style: const TextStyle(fontSize: 36),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(plant.commonName, style: AppTypography.titleLarge),
                        if (plant.latinName != null)
                          Text(
                            plant.latinName!,
                            style: AppTypography.bodySmall.copyWith(
                              fontStyle: FontStyle.italic,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${plant.category.emoji} ${plant.categoryDisplayLabel}',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Calendrier annuel
              _PlantYearCalendar(plant: plant),
              const SizedBox(height: 20),

              // Infos rapides
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(icon: plant.sunIcon, label: plant.sunLabel),
                  if (plant.spacingBetweenPlants != null)
                    _InfoChip(
                      icon: '📏',
                      label: '${plant.spacingBetweenPlants} cm entre plants',
                    ),
                  if (plant.spacingBetweenRows != null)
                    _InfoChip(
                      icon: '↔️',
                      label: '${plant.spacingBetweenRows} cm entre rangs',
                    ),
                  if (plant.plantingDepthCm != null)
                    _InfoChip(
                      icon: '⬇️',
                      label: '${plant.plantingDepthCm} cm profondeur',
                    ),
                  if (plant.plantingMinTempC != null)
                    _InfoChip(
                      icon: '🌡️',
                      label: '≥ ${plant.plantingMinTempC}°C',
                    ),
                  if (plant.watering != null)
                    _InfoChip(icon: '💧', label: 'Arrosage régulier'),
                ],
              ),
              const SizedBox(height: 24),

              // Périodes détaillées
              if (plant.sowingOpenGroundPeriod != null ||
                  plant.sowingUnderCoverPeriod != null ||
                  plant.transplantingPeriod != null ||
                  plant.harvestPeriod != null) ...[
                _DetailSectionTitle(title: '📅 Périodes'),
                if (plant.sowingUnderCoverPeriod != null)
                  _PeriodInfo(
                    type: GardenActivityType.sowingUnderCover,
                    value: plant.sowingUnderCoverPeriod!,
                  ),
                if (plant.sowingOpenGroundPeriod != null)
                  _PeriodInfo(
                    type: GardenActivityType.sowingOpenGround,
                    value: plant.sowingOpenGroundPeriod!,
                  ),
                if (plant.transplantingPeriod != null)
                  _PeriodInfo(
                    type: GardenActivityType.planting,
                    value: plant.transplantingPeriod!,
                  ),
                if (plant.harvestPeriod != null)
                  _PeriodInfo(
                    type: GardenActivityType.harvest,
                    value: plant.harvestPeriod!,
                  ),
                const SizedBox(height: 16),
              ],

              // Conseils de semis
              if (plant.sowingRecommendation != null) ...[
                _DetailSectionTitle(title: '🌱 Conseils de semis'),
                _DetailCard(
                  color: GardenActivityType.sowingOpenGround.color,
                  child: Text(
                    plant.sowingRecommendation!,
                    style: AppTypography.bodySmall,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Conseils de plantation
              if (plant.plantingAdvice != null) ...[
                _DetailSectionTitle(title: '🪴 Plantation'),
                Text(plant.plantingAdvice!, style: AppTypography.bodyMedium),
                const SizedBox(height: 16),
              ],

              // Conditions météo
              if (plant.plantingWeatherConditions != null) ...[
                _DetailSectionTitle(title: '🌤️ Conditions de plantation'),
                _DetailCard(
                  color: AppColors.info,
                  child: Text(
                    plant.plantingWeatherConditions!,
                    style: AppTypography.bodySmall,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Conseils d'entretien
              if (plant.careAdvice != null) ...[
                _DetailSectionTitle(title: '🧑‍🌾 Entretien'),
                Text(plant.careAdvice!, style: AppTypography.bodyMedium),
                const SizedBox(height: 16),
              ],

              // Arrosage détaillé
              if (plant.watering != null) ...[
                _DetailSectionTitle(title: '💧 Arrosage'),
                Text(plant.watering!, style: AppTypography.bodyMedium),
                const SizedBox(height: 16),
              ],

              // Sol
              if (plant.soilType != null ||
                  plant.soilMoisturePreference != null ||
                  plant.soilTreatmentAdvice != null) ...[
                _DetailSectionTitle(title: '🪨 Sol'),
                if (plant.soilType != null)
                  _DetailRow(label: 'Type de sol', value: plant.soilType!),
                if (plant.soilMoisturePreference != null)
                  _DetailRow(
                    label: 'Humidité',
                    value: plant.soilMoisturePreference!,
                  ),
                if (plant.soilTreatmentAdvice != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      plant.soilTreatmentAdvice!,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
              ],

              // Zone de culture
              if (plant.growingZone != null) ...[
                _DetailSectionTitle(title: '📍 Zone de culture'),
                Text(plant.growingZone!, style: AppTypography.bodyMedium),
                const SizedBox(height: 16),
              ],

              // Culture sous serre
              if (plant.cultivationGreenhouse != null) ...[
                _DetailSectionTitle(title: '🏠 Culture sous abri'),
                _DetailCard(
                  color: GardenActivityType.sowingUnderCover.color,
                  child: Text(
                    plant.cultivationGreenhouse!,
                    style: AppTypography.bodySmall,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Points d'attention
              if (plant.redFlags != null) ...[
                _DetailSectionTitle(title: '⚠️ Points d\'attention'),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: AppSpacing.borderRadiusMd,
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(plant.redFlags!, style: AppTypography.bodySmall),
                ),
                const SizedBox(height: 16),
              ],

              // Nuisibles
              if (plant.mainDestroyers != null) ...[
                _DetailSectionTitle(title: '🐛 Nuisibles & maladies'),
                _DestroyersList(destroyersJson: plant.mainDestroyers!),
                const SizedBox(height: 16),
              ],

              // Compagnons
              companionsAsync.when(
                data: (companions) {
                  if (companions.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DetailSectionTitle(title: '✅ Bonnes associations'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: companions
                            .map(
                              (c) => _PlantChip(
                                emoji: c.emoji,
                                name: c.commonName,
                                color: AppColors.success,
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),

              // Antagonistes
              antagonistsAsync.when(
                data: (antagonists) {
                  if (antagonists.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DetailSectionTitle(title: '❌ À éviter'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: antagonists
                            .map(
                              (a) => _PlantChip(
                                emoji: a.emoji,
                                name: a.commonName,
                                color: AppColors.error,
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }
}

class _DetailSectionTitle extends StatelessWidget {
  final String title;

  const _DetailSectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: AppTypography.titleSmall),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final Color color;
  final Widget child;

  const _DetailCard({required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: child,
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(child: Text(value, style: AppTypography.bodySmall)),
        ],
      ),
    );
  }
}

class _DestroyersList extends StatelessWidget {
  final String destroyersJson;

  const _DestroyersList({required this.destroyersJson});

  @override
  Widget build(BuildContext context) {
    List<String> destroyers = [];
    try {
      final decoded = json.decode(destroyersJson);
      if (decoded is List) {
        destroyers = decoded.cast<String>();
      }
    } catch (_) {
      // Si ce n'est pas du JSON, c'est peut-être une string simple
      destroyers = [destroyersJson];
    }

    if (destroyers.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: destroyers
          .map(
            (d) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: AppSpacing.borderRadiusFull,
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🐛', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text(
                    d,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppSpacing.borderRadiusFull,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(label, style: AppTypography.caption),
        ],
      ),
    );
  }
}

class _PlantChip extends StatelessWidget {
  final String emoji;
  final String name;
  final Color color;

  const _PlantChip({
    required this.emoji,
    required this.name,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppSpacing.borderRadiusFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(name, style: AppTypography.caption.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _PlantYearCalendar extends StatelessWidget {
  final Plant plant;

  const _PlantYearCalendar({required this.plant});

  @override
  Widget build(BuildContext context) {
    const months = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
    const monthsFull = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

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
              _SmallLegend(
                color: GardenActivityType.sowingUnderCover.color,
                label: 'Semis abri',
              ),
              _SmallLegend(
                color: GardenActivityType.sowingOpenGround.color,
                label: 'Semis',
              ),
              _SmallLegend(
                color: GardenActivityType.planting.color,
                label: 'Plantation',
              ),
              _SmallLegend(
                color: GardenActivityType.harvest.color,
                label: 'Récolte',
              ),
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
                    Text(
                      months[index],
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textTertiary,
                      ),
                    ),
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
                                    ? [
                                        activities.first.color,
                                        activities.first.color,
                                      ]
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
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
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
            decoration: BoxDecoration(
              color: type.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(type.emoji, style: const TextStyle(fontSize: 14)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.label,
                  style: AppTypography.labelSmall.copyWith(color: type.color),
                ),
                Text(value, style: AppTypography.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// BACKGROUND DÉCORATIF - RONDS ÉPARS
// ============================================

class _DecorativeBackground extends StatelessWidget {
  const _DecorativeBackground();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.background,
      child: CustomPaint(
        size: size,
        painter: _OrganicBlobsPainter(
          primaryColor: AppColors.primary,
          primaryLightColor: AppColors.primaryContainer,
        ),
      ),
    );
  }
}

class _OrganicBlobsPainter extends CustomPainter {
  final Color primaryColor;
  final Color primaryLightColor;

  _OrganicBlobsPainter({
    required this.primaryColor,
    required this.primaryLightColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final darkPaint = Paint()..style = PaintingStyle.fill;
    final lightPaint = Paint()..style = PaintingStyle.fill;

    // === COIN HAUT DROITE ===
    lightPaint.color = primaryLightColor.withValues(alpha: 0.5);
    canvas.drawCircle(Offset(size.width + 20, -30), 120, lightPaint);

    darkPaint.color = primaryColor.withValues(alpha: 0.15);
    canvas.drawCircle(Offset(size.width - 40, 60), 45, darkPaint);

    lightPaint.color = primaryLightColor.withValues(alpha: 0.4);
    canvas.drawCircle(Offset(size.width - 20, 130), 25, lightPaint);

    // === COIN HAUT GAUCHE ===
    lightPaint.color = primaryLightColor.withValues(alpha: 0.35);
    canvas.drawCircle(Offset(-30, 80), 55, lightPaint);

    darkPaint.color = primaryColor.withValues(alpha: 0.12);
    canvas.drawCircle(Offset(40, 50), 20, darkPaint);

    // === MILIEU GAUCHE ===
    lightPaint.color = primaryLightColor.withValues(alpha: 0.3);
    canvas.drawCircle(Offset(-60, size.height * 0.4), 90, lightPaint);

    darkPaint.color = primaryColor.withValues(alpha: 0.1);
    canvas.drawCircle(Offset(25, size.height * 0.35), 18, darkPaint);

    // === MILIEU DROITE ===
    lightPaint.color = primaryLightColor.withValues(alpha: 0.25);
    canvas.drawCircle(
      Offset(size.width + 30, size.height * 0.5),
      70,
      lightPaint,
    );

    darkPaint.color = primaryColor.withValues(alpha: 0.08);
    canvas.drawCircle(
      Offset(size.width - 35, size.height * 0.45),
      15,
      darkPaint,
    );

    // === BAS GAUCHE ===
    lightPaint.color = primaryLightColor.withValues(alpha: 0.4);
    canvas.drawCircle(Offset(-50, size.height * 0.75), 100, lightPaint);

    darkPaint.color = primaryColor.withValues(alpha: 0.12);
    canvas.drawCircle(Offset(50, size.height * 0.8), 35, darkPaint);

    lightPaint.color = primaryLightColor.withValues(alpha: 0.3);
    canvas.drawCircle(Offset(20, size.height * 0.7), 22, lightPaint);

    // === BAS DROITE ===
    lightPaint.color = primaryLightColor.withValues(alpha: 0.35);
    canvas.drawCircle(
      Offset(size.width + 40, size.height * 0.85),
      80,
      lightPaint,
    );

    darkPaint.color = primaryColor.withValues(alpha: 0.1);
    canvas.drawCircle(
      Offset(size.width - 50, size.height * 0.9),
      25,
      darkPaint,
    );

    // === PETITS RONDS DISPERSÉS ===
    darkPaint.color = primaryColor.withValues(alpha: 0.06);
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.15),
      12,
      darkPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.3),
      10,
      darkPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 0.55),
      8,
      darkPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.9, size.height * 0.65),
      14,
      darkPaint,
    );

    lightPaint.color = primaryLightColor.withValues(alpha: 0.2);
    canvas.drawCircle(
      Offset(size.width * 0.75, size.height * 0.2),
      16,
      lightPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.6),
      12,
      lightPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.75),
      10,
      lightPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
