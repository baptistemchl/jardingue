import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/providers/calendar_providers.dart';

// ============================================
// HEADER
// ============================================

class CalendarHeader extends ConsumerWidget {
  final DateTime selectedMonth;
  final bool showMonthNav;

  const CalendarHeader({
    super.key,
    required this.selectedMonth,
    this.showMonthNav = true,
  });

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
              TodayButton(
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
          if (showMonthNav) ...[
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                MonthNavButton(
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
                MonthNavButton(
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
        ],
      ),
    );
  }

  void _showMonthPicker(BuildContext context, WidgetRef ref, DateTime current) {
    showModalBottomSheet(
      useRootNavigator: true,
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => MonthPickerSheet(
        currentMonth: current,
        onMonthSelected: (month) {
          ref.read(selectedMonthProvider.notifier).state = month;
          Navigator.pop(context);
        },
      ),
    );
  }
}

class TodayButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isCurrentMonth;

  const TodayButton({super.key, required this.onTap, required this.isCurrentMonth});

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

class MonthNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const MonthNavButton({super.key, required this.icon, required this.onTap});

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
// MONTH PICKER
// ============================================

class MonthPickerSheet extends StatelessWidget {
  final DateTime currentMonth;
  final Function(DateTime) onMonthSelected;

  const MonthPickerSheet({
    super.key,
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
