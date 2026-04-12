import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/providers/planning_providers.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/plant_emoji_mapper.dart';
import '../../domain/models/selected_plant.dart';

class SelectedPlantsRow extends ConsumerWidget {
  final List<SelectedPlant> plants;
  final VoidCallback onAdd;

  const SelectedPlantsRow({
    super.key,
    required this.plants,
    required this.onAdd,
  });

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final activeFilter = ref.watch(
      planningStateProvider.select(
        (s) => s.valueOrNull?.plantIdFilter,
      ),
    );

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Padding(
          padding: AppSpacing.horizontalPadding,
          child: Row(
            children: [
              Text(
                'Mes plants',
                style: AppTypography.titleSmall
                    .copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (activeFilter != null)
                GestureDetector(
                  onTap: () => ref
                      .read(
                        planningStateProvider
                            .notifier,
                      )
                      .setPlantFilter(null),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary
                          .withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),
                    child: Row(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        Icon(
                          PhosphorIcons.x(
                            PhosphorIconsStyle
                                .bold,
                          ),
                          size: 12,
                          color:
                              AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Voir tout',
                          style: AppTypography
                              .caption
                              .copyWith(
                            color:
                                AppColors.primary,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Text(
                  '${plants.length} sélectionnés',
                  style: AppTypography.caption
                      .copyWith(
                    color:
                        AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
        if (plants.isEmpty)
          Padding(
            padding: AppSpacing.horizontalPadding,
            child: Padding(
              padding: const EdgeInsets.only(
                top: 8,
              ),
              child: _AddButton(onTap: onAdd),
            ),
          )
        else ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding:
                  AppSpacing.horizontalPadding,
              itemCount: plants.length + 1,
              itemBuilder: (context, index) {
                if (index == plants.length) {
                  return _AddButton(onTap: onAdd);
                }
                final plant = plants[index];
                final isActive = activeFilter ==
                    plant.plantId;

                return _PlantChip(
                  plant: plant,
                  isActive: isActive,
                  onTap: () => ref
                      .read(
                        planningStateProvider
                            .notifier,
                      )
                      .setPlantFilter(
                        plant.plantId,
                      ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _PlantChip extends StatelessWidget {
  final SelectedPlant plant;
  final bool isActive;
  final VoidCallback onTap;

  const _PlantChip({
    required this.plant,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final emoji = PlantEmojiMapper.fromName(
      plant.commonName,
      categoryCode: plant.categoryCode,
    );

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(
          milliseconds: 200,
        ),
        width: 64,
        margin: const EdgeInsets.only(right: 10),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primary
                        .withValues(alpha: 0.15)
                    : AppColors.primaryContainer,
                borderRadius:
                    BorderRadius.circular(12),
                border: isActive
                    ? Border.all(
                        color: AppColors.primary,
                        width: 2,
                      )
                    : null,
              ),
              child: Center(
                child: Text(
                  emoji,
                  style: const TextStyle(
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              plant.commonName,
              style: AppTypography.caption
                  .copyWith(
                fontSize: 10,
                fontWeight: isActive
                    ? FontWeight.w600
                    : FontWeight.normal,
                color: isActive
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 64,
        child: Column(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius:
                    BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.border,
                ),
              ),
              child: Icon(
                PhosphorIcons.plus(
                  PhosphorIconsStyle.bold,
                ),
                size: 18,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ajouter',
              style: AppTypography.caption
                  .copyWith(
                fontSize: 10,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
