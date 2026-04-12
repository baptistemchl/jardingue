import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/providers/planning_providers.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/planning_state.dart';

/// Tabs pour choisir le mode de vue :
/// Tout | Mes plants | Tâches potagères
class PlanningViewTabs extends ConsumerWidget {
  const PlanningViewTabs({super.key});

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final currentMode = ref.watch(
      planningStateProvider.select(
        (s) =>
            s.valueOrNull?.viewMode ??
            PlanningViewMode.all,
      ),
    );

    return Padding(
      padding: AppSpacing.horizontalPadding,
      child: Container(
        height: 40,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.border,
          ),
        ),
        child: Row(
          children: [
            for (final mode
                in PlanningViewMode.values)
              Expanded(
                child: _Tab(
                  label: mode.label,
                  isSelected: currentMode == mode,
                  onTap: () => ref
                      .read(
                        planningStateProvider
                            .notifier,
                      )
                      .setViewMode(mode),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _Tab({
    required this.label,
    required this.isSelected,
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
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 4,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: AppTypography.labelSmall
                    .copyWith(
                  color: isSelected
                      ? Colors.white
                      : AppColors.textSecondary,
                  fontWeight: isSelected
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
