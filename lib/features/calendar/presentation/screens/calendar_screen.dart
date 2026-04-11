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
import '../widgets/calendar_filter_chips.dart'
    show CalendarFilterPanel;
import '../widgets/calendar_onboarding.dart';
import 'package:jardingue/l10n/generated/app_localizations.dart';

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

class _CalendarScreenState
    extends ConsumerState<CalendarScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: 0,
    );
    // Popup d'aide au premier lancement
    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      maybeShowCalendarOnboarding(context);
    });
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

  /// Applique les filtres globaux (type + plant)
  /// aux activités du mois.
  MonthActivities _applyFilters(
    WidgetRef ref,
    MonthActivities src,
  ) {
    final typeFilter = ref.watch(
      activityFilterProvider,
    );
    final plantFilter = ref.watch(
      calendarPlantFilterProvider,
    );

    var result = src;

    // Filtre par plant
    if (plantFilter != null) {
      bool match(PlantActivity a) =>
          a.plant.id == plantFilter;
      result = MonthActivities(
        month: result.month,
        year: result.year,
        sowingUnderCover: result
            .sowingUnderCover
            .where(match)
            .toList(),
        sowingOpenGround: result
            .sowingOpenGround
            .where(match)
            .toList(),
        planting: result.planting
            .where(match)
            .toList(),
        harvest: result.harvest
            .where(match)
            .toList(),
      );
    }

    // Filtre par type : on vide les listes
    // qui ne correspondent pas
    if (typeFilter != null) {
      result = MonthActivities(
        month: result.month,
        year: result.year,
        sowingUnderCover:
            typeFilter ==
                    GardenActivityType
                        .sowingUnderCover
                ? result.sowingUnderCover
                : [],
        sowingOpenGround:
            typeFilter ==
                    GardenActivityType
                        .sowingOpenGround
                ? result.sowingOpenGround
                : [],
        planting:
            typeFilter ==
                    GardenActivityType.planting
                ? result.planting
                : [],
        harvest:
            typeFilter ==
                    GardenActivityType.harvest
                ? result.harvest
                : [],
      );
    }

    return result;
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
                // Header + bouton aide
                Row(
                  children: [
                    Expanded(
                      child: CalendarHeader(
                        selectedMonth:
                            selectedMonth,
                        showMonthNav: currentView !=
                            CalendarViewType
                                .myActivities,
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.only(
                        right: 16,
                        top: 8,
                      ),
                      child: GestureDetector(
                        onTap: () =>
                            showCalendarOnboarding(
                          context,
                        ),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration:
                              BoxDecoration(
                            color: AppColors.info
                                .withValues(
                              alpha: 0.1,
                            ),
                            borderRadius:
                                BorderRadius
                                    .circular(
                              10,
                            ),
                          ),
                          child: Icon(
                            PhosphorIcons
                                .question(
                              PhosphorIconsStyle
                                  .bold,
                            ),
                            size: 16,
                            color: AppColors.info,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: AppSpacing.sm,
                ),

                // TabBar
                _ViewTabBar(
                  currentView: currentView,
                  onTabChanged: _onTabChanged,
                ),
                const SizedBox(
                  height: AppSpacing.sm,
                ),

                // Filtres collapsibles
                const CalendarFilterPanel(),
                const SizedBox(
                  height: AppSpacing.sm,
                ),

                // Contenu avec PageView
                Expanded(
                  child: activitiesAsync.when(
                    data: (activities) {
                      final filtered =
                          _applyFilters(
                        ref,
                        activities,
                      );
                      return PageView(
                        controller:
                            _pageController,
                        onPageChanged:
                            _onPageChanged,
                        children: [
                          _CalendarView(
                            selectedMonth:
                                selectedMonth,
                            activities: filtered,
                            onDayTap: _onDayTap,
                          ),
                          MonthListView(
                            selectedMonth:
                                selectedMonth,
                            activities: filtered,
                          ),
                          UserEventsView(
                            selectedMonth:
                                selectedMonth,
                          ),
                        ],
                      );
                    },
                    loading: () => const Center(
                      child:
                          CircularProgressIndicator(),
                    ),
                    error: (e, _) => Center(
                      child: Text(
                        AppLocalizations.of(
                          context,
                        )!
                            .errorWithMessage(
                          e.toString(),
                        ),
                      ),
                    ),
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
                label: AppLocalizations.of(context)!.calendarTab,
                isSelected: currentView == CalendarViewType.calendar,
                onTap: () => onTabChanged(CalendarViewType.calendar),
              ),
            ),
            Expanded(
              child: _TabButton(
                icon: PhosphorIcons.listBullets(PhosphorIconsStyle.fill),
                label: AppLocalizations.of(context)!.listTab,
                isSelected: currentView == CalendarViewType.list,
                onTap: () => onTabChanged(CalendarViewType.list),
              ),
            ),
            Expanded(
              child: _TabButton(
                icon: PhosphorIcons.userCircle(PhosphorIconsStyle.fill),
                label: AppLocalizations.of(context)!.myTracking,
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
  Widget build(
    BuildContext context,
    WidgetRef ref, // Gardé pour monthUserEventsProvider
  ) {
    final userEventsAsync = ref.watch(
      monthUserEventsProvider(selectedMonth),
    );
    final userEvents =
        userEventsAsync.valueOrNull ?? [];

    // Les filtres sont déjà appliqués en amont
    // par _applyFilters dans le parent.
    if (activities.isEmpty) {
      return CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: CompactMonthCalendar(
              selectedMonth: selectedMonth,
              activities: activities,
              userEvents: userEvents,
              onDayTap: onDayTap,
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(
              height: AppSpacing.md,
            ),
          ),
          const SliverToBoxAdapter(
            child: ActivityFilters(),
          ),
          const SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(),
          ),
        ],
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: CompactMonthCalendar(
            selectedMonth: selectedMonth,
            activities: activities,
            userEvents: userEvents,
            onDayTap: onDayTap,
          ),
        ),

        const SliverToBoxAdapter(
          child: SizedBox(
            height: AppSpacing.md,
          ),
        ),

        const SliverToBoxAdapter(
          child: ActivityFilters(),
        ),

        const SliverToBoxAdapter(
          child: SizedBox(
            height: AppSpacing.md,
          ),
        ),

        if (activities
            .sowingUnderCover.isNotEmpty)
          SliverToBoxAdapter(
            child: ActivitySectionScrollable(
              type: GardenActivityType
                  .sowingUnderCover,
              activities:
                  activities.sowingUnderCover,
            ),
          ),
        if (activities
            .sowingOpenGround.isNotEmpty)
          SliverToBoxAdapter(
            child: ActivitySectionScrollable(
              type: GardenActivityType
                  .sowingOpenGround,
              activities:
                  activities.sowingOpenGround,
            ),
          ),
        if (activities.planting.isNotEmpty)
          SliverToBoxAdapter(
            child: ActivitySectionScrollable(
              type:
                  GardenActivityType.planting,
              activities:
                  activities.planting,
            ),
          ),
        if (activities.harvest.isNotEmpty)
          SliverToBoxAdapter(
            child: ActivitySectionScrollable(
              type:
                  GardenActivityType.harvest,
              activities:
                  activities.harvest,
            ),
          ),

        const SliverToBoxAdapter(
          child: SizedBox(height: 120),
        ),
      ],
    );
  }
}
