import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/providers/planning_providers.dart';
import '../../../../core/theme/app_typography.dart';

class MonthFilterBar extends ConsumerWidget {
  const MonthFilterBar({super.key});

  static const _shortMonths = [
    'Jan', 'Fév', 'Mar', 'Avr',
    'Mai', 'Juin', 'Juil', 'Août',
    'Sep', 'Oct', 'Nov', 'Déc',
  ];

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final currentFilter = ref.watch(
      planningStateProvider.select(
        (s) => s.value?.monthFilter,
      ),
    );
    final now = DateTime.now().month;

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: AppSpacing.horizontalPadding,
        separatorBuilder: (_, __) =>
            const SizedBox(width: 6),
        itemCount: 13,
        itemBuilder: (context, index) {
          if (index == 0) {
            final isAll = currentFilter == null;
            return _Chip(
              label: 'Année',
              isSelected: isAll,
              isCurrent: false,
              onTap: () {
                // Toujours forcer le clear
                ref
                    .read(
                      planningStateProvider
                          .notifier,
                    )
                    .setMonthFilter(null);
              },
            );
          }

          final month = index;
          return _Chip(
            label: _shortMonths[month - 1],
            isSelected: currentFilter == month,
            isCurrent: month == now,
            onTap: () => ref
                .read(
                  planningStateProvider.notifier,
                )
                .setMonthFilter(month),
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isCurrent;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.isSelected,
    required this.isCurrent,
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
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : isCurrent
                  ? AppColors.primary
                      .withValues(alpha: 0.1)
                  : AppColors.surface,
          borderRadius:
              BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : isCurrent
                    ? AppColors.primary
                        .withValues(alpha: 0.3)
                    : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall
              .copyWith(
            color: isSelected
                ? Colors.white
                : isCurrent
                    ? AppColors.primary
                    : AppColors.textSecondary,
            fontWeight: isSelected || isCurrent
                ? FontWeight.w600
                : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
