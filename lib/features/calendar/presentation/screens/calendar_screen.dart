import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/widgets/decorative_background.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/providers/calendar_providers.dart';
import '../../../../core/providers/garden_event_providers.dart';
import '../widgets/calendar_header.dart';
import '../widgets/compact_month_calendar.dart';
import '../widgets/activity_section.dart';
import '../widgets/month_list_view.dart';
import '../widgets/user_events_view.dart';
import '../widgets/add_event_sheet.dart';
import '../widgets/calendar_empty_states.dart';

// ============================================
// PROVIDER POUR LA VUE SÉLECTIONNÉE
// ============================================

enum CalendarViewType { calendar, list, myActivities }

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
    ref.read(calendarViewProvider.notifier).state = switch (index) {
      0 => CalendarViewType.calendar,
      1 => CalendarViewType.list,
      _ => CalendarViewType.myActivities,
    };
  }

  void _onTabChanged(CalendarViewType view) {
    final targetPage = switch (view) {
      CalendarViewType.calendar => 0,
      CalendarViewType.list => 1,
      CalendarViewType.myActivities => 2,
    };
    _pageController.animateToPage(
      targetPage,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onDayTap(DateTime date) {
    final selectedMonth = ref.read(selectedMonthProvider);
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddEventSheet(
        selectedDate: date,
        onEventAdded: () {
          // Rafraichir "Mon suivi" pour le mois en cours
          ref.invalidate(monthUserEventsProvider(selectedMonth));
        },
      ),
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
          const DecorativeBackground(),

          // Contenu
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                CalendarHeader(
                  selectedMonth: selectedMonth,
                  showMonthNav: currentView != CalendarViewType.myActivities,
                ),
                const SizedBox(height: AppSpacing.sm),

                // TabBar pour choisir la vue
                _ViewTabBar(
                  currentView: currentView,
                  onTabChanged: _onTabChanged,
                ),
                const SizedBox(height: AppSpacing.md),

                // Contenu avec PageView pour le swipe
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    children: [
                      activitiesAsync.when(
                        data: (activities) => _CalendarView(
                          selectedMonth: selectedMonth,
                          activities: activities,
                          onDayTap: _onDayTap,
                        ),
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(child: Text('Erreur: $e')),
                      ),
                      activitiesAsync.when(
                        data: (activities) => MonthListView(
                          selectedMonth: selectedMonth,
                          activities: activities,
                        ),
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(child: Text('Erreur: $e')),
                      ),
                      // 3ème page : Mes activités
                      UserEventsView(selectedMonth: selectedMonth),
                    ],
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
                label: 'Liste',
                isSelected: currentView == CalendarViewType.list,
                onTap: () => onTabChanged(CalendarViewType.list),
              ),
            ),
            Expanded(
              child: _TabButton(
                icon: PhosphorIcons.userCircle(PhosphorIconsStyle.fill),
                label: 'Mon suivi',
                isSelected: currentView == CalendarViewType.myActivities,
                onTap: () => onTabChanged(CalendarViewType.myActivities),
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
  final void Function(DateTime date)? onDayTap;

  const _CalendarView({
    required this.selectedMonth,
    required this.activities,
    this.onDayTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(activityFilterProvider);
    final userEventsAsync = ref.watch(monthUserEventsProvider(selectedMonth));
    final userEvents = userEventsAsync.valueOrNull ?? [];

    if (activities.isEmpty) {
      return Column(
        children: [
          CompactMonthCalendar(
            selectedMonth: selectedMonth,
            activities: activities,
            userEvents: userEvents,
            onDayTap: onDayTap,
          ),
          const SizedBox(height: AppSpacing.md),
          const ActivityFilters(),
          const Expanded(child: EmptyState()),
        ],
      );
    }

    return CustomScrollView(
      slivers: [
        // Calendrier compact
        SliverToBoxAdapter(
          child: CompactMonthCalendar(
            selectedMonth: selectedMonth,
            activities: activities,
            userEvents: userEvents,
            onDayTap: onDayTap,
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

        // Filtres
        const SliverToBoxAdapter(child: ActivityFilters()),

        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

        // Sections d'activités
        if (filter != null) ...[
          ..._buildFilteredSections(activities, filter),
        ] else ...[
          if (activities.sowingUnderCover.isNotEmpty)
            SliverToBoxAdapter(
              child: ActivitySectionScrollable(
                type: GardenActivityType.sowingUnderCover,
                activities: activities.sowingUnderCover,
              ),
            ),
          if (activities.sowingOpenGround.isNotEmpty)
            SliverToBoxAdapter(
              child: ActivitySectionScrollable(
                type: GardenActivityType.sowingOpenGround,
                activities: activities.sowingOpenGround,
              ),
            ),
          if (activities.planting.isNotEmpty)
            SliverToBoxAdapter(
              child: ActivitySectionScrollable(
                type: GardenActivityType.planting,
                activities: activities.planting,
              ),
            ),
          if (activities.harvest.isNotEmpty)
            SliverToBoxAdapter(
              child: ActivitySectionScrollable(
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
          child: EmptyStateForType(type: filter),
        ),
      ];
    }
    return [
      SliverToBoxAdapter(
        child: ActivitySectionScrollable(
          type: filter,
          activities: filteredActivities,
        ),
      ),
    ];
  }
}
