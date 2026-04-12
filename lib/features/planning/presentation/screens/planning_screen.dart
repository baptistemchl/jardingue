import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/providers/planning_providers.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/decorative_background.dart';
import '../../domain/models/planning_state.dart';
import '../widgets/garden_task_tile.dart';
import '../widgets/month_filter_bar.dart';
import '../widgets/planning_empty_state.dart';
import '../widgets/planning_task_tile.dart';
import '../widgets/planning_view_tabs.dart';
import '../widgets/planning_weather_banner.dart';
import '../widgets/plant_selector_sheet.dart';
import '../widgets/selected_plants_row.dart';

class PlanningScreen extends ConsumerWidget {
  const PlanningScreen({super.key});

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final stateAsync = ref.watch(
      planningStateProvider,
    );

    return Scaffold(
      body: Stack(
        children: [
          const DecorativeBackground(),
          SafeArea(
            bottom: false,
            child: stateAsync.when(
              data: (state) =>
                  _Content(state: state),
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              ),
              error: (e, _) => _ErrorView(
                error: e.toString(),
                onRetry: () => ref.invalidate(
                  planningStateProvider,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Content extends ConsumerWidget {
  final PlanningState state;

  const _Content({required this.state});

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final hasPlants =
        state.selectedPlants.isNotEmpty;
    final showPlantRow =
        state.viewMode != PlanningViewMode
            .gardenTasks
        && hasPlants;

    return CustomScrollView(
      slivers: [
        // Header
        const SliverToBoxAdapter(
          child: Padding(
            padding: AppSpacing.horizontalPadding,
            child: _Header(),
          ),
        ),
        const _Gap(),

        // Bandeau météo
        const SliverToBoxAdapter(
          child: Padding(
            padding: AppSpacing.horizontalPadding,
            child: PlanningWeatherBanner(),
          ),
        ),
        const _Gap(),

        // Tabs : Tout | Mes plants | Potagère
        const SliverToBoxAdapter(
          child: PlanningViewTabs(),
        ),
        const _Gap(),

        // Plants sélectionnés (mode all ou
        // mes plants)
        if (showPlantRow)
          SliverToBoxAdapter(
            child: SelectedPlantsRow(
              plants: state.selectedPlants,
              onAdd: () => _openSelector(context),
            ),
          ),
        if (showPlantRow) const _Gap(),

        // Filtre par mois
        const SliverToBoxAdapter(
          child: MonthFilterBar(),
        ),
        const _Gap(),

        // Sources (mode potagère ou tout)
        if (state.viewMode !=
            PlanningViewMode.myPlants)
          const SliverToBoxAdapter(
            child: _SourcesBanner(),
          ),
        if (state.viewMode !=
            PlanningViewMode.myPlants)
          const _Gap(),

        // Contenu par mois
        for (final month in state.activeMonths)
          ..._buildMonth(month, state, ref),

        // Empty state si aucun plant et mode
        // plants
        if (!hasPlants &&
            state.viewMode !=
                PlanningViewMode.gardenTasks)
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.all(16),
              child: PlanningEmptyState(
                onAddPlants: () =>
                    _openSelector(context),
              ),
            ),
          ),

        AppSpacing.bottomSpacer(context),
      ],
    );
  }

  List<Widget> _buildMonth(
    int month,
    PlanningState state,
    WidgetRef ref,
  ) {
    final plantTasks =
        state.plantTasksForMonth(month);
    final gardenTasks =
        state.gardenTasksForMonth(month);

    if (plantTasks.isEmpty &&
        gardenTasks.isEmpty) {
      return [];
    }

    return [
      // En-tête mois
      SliverToBoxAdapter(
        child: _MonthHeader(
          month: month,
          plantCount: plantTasks.length,
          gardenCount: gardenTasks.length,
        ),
      ),

      // Tâches des plants
      if (plantTasks.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: _SectionTitle(
            emoji: '🌱',
            title: 'Tâches des plants',
            count: plantTasks.length,
          ),
        ),
        for (final task in plantTasks)
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  AppSpacing.horizontalPadding,
              child: PlanningTaskTile(
                task: task,
                isCompleted: state.isCompleted(
                  'plant_${task.plantId}'
                  '_${task.actionType.name}',
                  month,
                ),
                onToggle: () => ref
                    .read(
                      planningStateProvider
                          .notifier,
                    )
                    .toggleTask(
                      taskKey:
                          'plant_${task.plantId}'
                          '_${task.actionType.name}',
                      month: month,
                      plantId: task.plantId,
                    ),
              ),
            ),
          ),
      ],

      // Tâches potagères
      if (gardenTasks.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: _SectionTitle(
            emoji: '⛏️',
            title: 'Tâches potagères',
            count: gardenTasks.length,
          ),
        ),
        for (final task in gardenTasks)
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  AppSpacing.horizontalPadding,
              child: GardenTaskTile(
                task: task,
                isCompleted: state.isCompleted(
                  task.id,
                  month,
                ),
                onToggle: () => ref
                    .read(
                      planningStateProvider
                          .notifier,
                    )
                    .toggleTask(
                      taskKey: task.id,
                      month: month,
                    ),
              ),
            ),
          ),
      ],

      const SliverToBoxAdapter(
        child: SizedBox(height: 16),
      ),
    ];
  }

  void _openSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          const PlantSelectorSheet(),
    );
  }
}

// ============================================
// WIDGETS INTERNES
// ============================================

class _Gap extends StatelessWidget {
  const _Gap();

  @override
  Widget build(BuildContext context) {
    return const SliverToBoxAdapter(
      child: SizedBox(height: AppSpacing.sm),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            'Planification',
            style: AppTypography.headlineLarge
                .copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Année ${DateTime.now().year}',
            style:
                AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  final int month;
  final int plantCount;
  final int gardenCount;

  const _MonthHeader({
    required this.month,
    required this.plantCount,
    required this.gardenCount,
  });

  static const _months = [
    'Janvier', 'Février', 'Mars', 'Avril',
    'Mai', 'Juin', 'Juillet', 'Août',
    'Septembre', 'Octobre', 'Novembre',
    'Décembre',
  ];

  @override
  Widget build(BuildContext context) {
    final isCurrent =
        month == DateTime.now().month;
    final total = plantCount + gardenCount;

    return Padding(
      padding: AppSpacing.horizontalPadding,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isCurrent
              ? AppColors.primary
                  .withValues(alpha: 0.1)
              : AppColors.surfaceVariant,
          borderRadius:
              BorderRadius.circular(12),
          border: isCurrent
              ? Border.all(
                  color: AppColors.primary
                      .withValues(alpha: 0.3),
                )
              : null,
        ),
        child: Row(
          children: [
            if (isCurrent)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(
                  right: 8,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            Text(
              _months[month - 1],
              style: AppTypography.titleMedium
                  .copyWith(
                fontWeight: FontWeight.w700,
                color: isCurrent
                    ? AppColors.primary
                    : AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            Text(
              '$total tâche'
              '${total > 1 ? 's' : ''}',
              style:
                  AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String emoji;
  final String title;
  final int count;

  const _SectionTitle({
    required this.emoji,
    required this.title,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.horizontalPadding,
      child: Padding(
        padding: const EdgeInsets.only(
          top: 4,
          bottom: 6,
        ),
        child: Row(
          children: [
            Text(
              emoji,
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$title ($count)',
              style: AppTypography.labelMedium
                  .copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourcesBanner extends StatelessWidget {
  const _SourcesBanner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.horizontalPadding,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius:
              BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              PhosphorIcons.info(
                PhosphorIconsStyle.fill,
              ),
              size: 14,
              color: AppColors.textTertiary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Sources : Rustica, Vilmorin, '
                'Gerbeaud, INRAE',
                style: AppTypography.caption
                    .copyWith(
                  color: AppColors.textTertiary,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '⚠️',
              style: TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: AppTypography.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall
                  .copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
