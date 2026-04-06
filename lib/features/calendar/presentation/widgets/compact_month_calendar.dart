import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/providers/calendar_providers.dart';
import '../../../garden/domain/models/garden_event.dart';

// ============================================
// CALENDRIER COMPACT
// ============================================

class CompactMonthCalendar extends StatelessWidget {
  final DateTime selectedMonth;
  final MonthActivities activities;
  final void Function(DateTime date)? onDayTap;
  /// Événements utilisateur pour afficher des indicateurs par jour
  final List<GardenEventWithDetails> userEvents;

  const CompactMonthCalendar({
    super.key,
    required this.selectedMonth,
    required this.activities,
    this.onDayTap,
    this.userEvents = const [],
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

    // Construire un map jour → types d'événements utilisateur
    final dayEventTypes = <int, Set<GardenEventType>>{};
    for (final e in userEvents) {
      final d = e.event.eventDate.day;
      dayEventTypes.putIfAbsent(d, () => {}).add(e.type);
    }

    // Types d'événements présents dans le mois (pour la légende)
    final monthEventTypes = <GardenEventType>{};
    for (final types in dayEventTypes.values) {
      monthEventTypes.addAll(types);
    }

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

          // Grille des jours
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
              childAspectRatio: 1.1,
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

              final eventTypes = dayEventTypes[day];

              return _CompactDayCell(
                day: day,
                isToday: isToday,
                hasActivities:
                    hasSowingUnderCover ||
                    hasSowingOpenGround ||
                    hasPlanting ||
                    hasHarvest,
                eventTypes: eventTypes,
                onTap: onDayTap != null
                    ? () => onDayTap!(DateTime(
                          selectedMonth.year,
                          selectedMonth.month,
                          day,
                        ))
                    : null,
              );
            },
          ),

          // Mini légende - activités catalogue
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
                  '${activities.totalActivities} activites ce mois',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],

          // Légende événements utilisateur
          if (monthEventTypes.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 10,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              children: monthEventTypes.map((t) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: t.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    t.label,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              )).toList(),
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
  final Set<GardenEventType>? eventTypes;
  final VoidCallback? onTap;

  const _CompactDayCell({
    required this.day,
    required this.isToday,
    required this.hasActivities,
    this.eventTypes,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasEvents = eventTypes != null && eventTypes!.isNotEmpty;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isToday
              ? AppColors.primary
              : hasActivities
                  ? AppColors.primaryContainer.withValues(alpha: 0.4)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: AppTypography.caption.copyWith(
                color: isToday ? Colors.white : AppColors.textPrimary,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
            if (hasEvents) ...[
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: eventTypes!
                    .take(3)
                    .map((t) => Container(
                          width: 5,
                          height: 5,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: isToday
                                ? Colors.white.withValues(alpha: 0.8)
                                : t.color,
                            shape: BoxShape.circle,
                          ),
                        ))
                    .toList(),
              ),
            ],
          ],
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
