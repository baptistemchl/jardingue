import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/providers/calendar_providers.dart';
import '../../../../core/providers/garden_event_providers.dart';
import '../../../../core/providers/planning_providers.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/services/database/database.dart'
    show Plant;
import '../../../../core/utils/plant_emoji_mapper.dart';
import '../../../planning/domain/models/selected_plant.dart';

/// Bouton toggle + panneau de filtres collapsible.
class CalendarFilterPanel
    extends ConsumerStatefulWidget {
  const CalendarFilterPanel({super.key});

  @override
  ConsumerState<CalendarFilterPanel>
      createState() =>
          _CalendarFilterPanelState();
}

class _CalendarFilterPanelState
    extends ConsumerState<CalendarFilterPanel>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final actFilter = ref.watch(
      activityFilterProvider,
    );
    final plantFilter = ref.watch(
      calendarPlantFilterProvider,
    );
    final activeCount =
        (actFilter != null ? 1 : 0) +
        (plantFilter != null ? 1 : 0);

    return Column(
      children: [
        // Toggle button
        Padding(
          padding: AppSpacing.horizontalPadding,
          child: GestureDetector(
            onTap: () => setState(
              () => _expanded = !_expanded,
            ),
            child: Container(
              height: 36,
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 14,
              ),
              decoration: BoxDecoration(
                color: activeCount > 0
                    ? AppColors.primary
                        .withValues(alpha: 0.08)
                    : AppColors.surface,
                borderRadius:
                    BorderRadius.circular(12),
                border: Border.all(
                  color: activeCount > 0
                      ? AppColors.primary
                          .withValues(
                          alpha: 0.2,
                        )
                      : AppColors.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    PhosphorIcons.funnelSimple(
                      PhosphorIconsStyle.bold,
                    ),
                    size: 16,
                    color: activeCount > 0
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Filtres',
                    style: AppTypography
                        .labelMedium
                        .copyWith(
                      color: activeCount > 0
                          ? AppColors.primary
                          : AppColors
                              .textSecondary,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                  if (activeCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      width: 20,
                      height: 20,
                      decoration:
                          const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$activeCount',
                          style: AppTypography
                              .caption
                              .copyWith(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(
                      milliseconds: 200,
                    ),
                    child: Icon(
                      PhosphorIcons.caretDown(
                        PhosphorIconsStyle.bold,
                      ),
                      size: 14,
                      color:
                          AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Panneau filtres (collapsible)
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: _FilterContent(),
          crossFadeState: _expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(
            milliseconds: 250,
          ),
          sizeCurve: Curves.easeInOut,
        ),
      ],
    );
  }
}

class _FilterContent extends ConsumerWidget {
  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final actFilter = ref.watch(
      activityFilterProvider,
    );

    // Fusionner plants planification + suivis
    final planningPlants = ref.watch(
      selectedPlantsProvider,
    );
    final trackedPlants = ref.watch(
      trackedPlantsProvider,
    );

    final plantList = _mergedPlants(
      planningPlants.valueOrNull ?? [],
      trackedPlants.valueOrNull ?? [],
    );

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // Label
          Padding(
            padding: AppSpacing.horizontalPadding,
            child: Text(
              'Type d\'activité',
              style: AppTypography.caption
                  .copyWith(
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Chips activités
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding:
                  AppSpacing.horizontalPadding,
              children: [
                _Chip(
                  label: 'Tout',
                  emoji: '📋',
                  isSelected: actFilter == null,
                  color: AppColors.primary,
                  onTap: () => ref
                      .read(
                        activityFilterProvider
                            .notifier,
                      )
                      .state = null,
                ),
                for (final type
                    in GardenActivityType
                        .values) ...[
                  const SizedBox(width: 6),
                  _Chip(
                    label: type.label,
                    emoji: type.emoji,
                    isSelected:
                        actFilter == type,
                    color: type.color,
                    onTap: () => ref
                        .read(
                          activityFilterProvider
                              .notifier,
                        )
                        .state = type,
                  ),
                ],
              ],
            ),
          ),

          // Chips plants
          if (plantList.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding:
                  AppSpacing.horizontalPadding,
              child: Text(
                'Filtrer par plant',
                style: AppTypography.caption
                    .copyWith(
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 32,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding:
                    AppSpacing.horizontalPadding,
                children: [
                  _Chip(
                    label: 'Tous',
                    emoji: '🌱',
                    isSelected: ref.watch(
                          calendarPlantFilterProvider,
                        ) ==
                        null,
                    color: AppColors.success,
                    onTap: () => ref
                        .read(
                          calendarPlantFilterProvider
                              .notifier,
                        )
                        .state = null,
                  ),
                  for (final p
                      in plantList) ...[
                    const SizedBox(width: 6),
                    _Chip(
                      label: p.name,
                      emoji: PlantEmojiMapper
                          .fromName(
                        p.name,
                        categoryCode: p.cat,
                      ),
                      isSelected: ref.watch(
                            calendarPlantFilterProvider,
                          ) ==
                          p.id,
                      color: AppColors.primary,
                      onTap: () {
                        final cur = ref.read(
                          calendarPlantFilterProvider,
                        );
                        ref
                            .read(
                              calendarPlantFilterProvider
                                  .notifier,
                            )
                            .state =
                            cur == p.id
                                ? null
                                : p.id;
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

/// Fusionne plants planification + plants suivis,
/// dédupliqués par ID.
List<({int id, String name, String? cat})>
    _mergedPlants(
  List<SelectedPlant> planning,
  List<Plant> tracked,
) {
  final seen = <int>{};
  final result =
      <({int id, String name, String? cat})>[];

  for (final p in planning) {
    if (seen.add(p.plantId)) {
      result.add((
        id: p.plantId,
        name: p.commonName,
        cat: p.categoryCode,
      ));
    }
  }
  for (final p in tracked) {
    if (seen.add(p.id)) {
      result.add((
        id: p.id,
        name: p.commonName,
        cat: p.categoryCode,
      ));
    }
  }

  result.sort(
    (a, b) => a.name.compareTo(b.name),
  );
  return result;
}

class _Chip extends StatelessWidget {
  final String label;
  final String emoji;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.emoji,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(
          milliseconds: 200,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? color
              : AppColors.surface,
          borderRadius:
              BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              emoji,
              style: const TextStyle(
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.caption
                  .copyWith(
                fontSize: 11,
                color: isSelected
                    ? Colors.white
                    : AppColors.textSecondary,
                fontWeight: isSelected
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
