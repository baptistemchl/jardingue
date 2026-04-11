import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/planning_task.dart';

class PlanningTaskCard extends StatelessWidget {
  final PlanningTask task;

  const PlanningTaskCard({
    super.key,
    required this.task,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: task.blockedByWeather
              ? AppColors.border
              : task.actionType.color
                  .withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Emoji plant
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: task.actionType.color
                  .withValues(alpha: 0.12),
              borderRadius:
                  BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                task.plantEmoji,
                style: const TextStyle(
                  fontSize: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Contenu
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  task.plantName,
                  style: AppTypography.labelLarge
                      .copyWith(
                    fontWeight: FontWeight.w600,
                    color: task.blockedByWeather
                        ? AppColors.textTertiary
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  task.message,
                  style: AppTypography.bodySmall
                      .copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (task.detail != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    task.detail!,
                    style: AppTypography.caption
                        .copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
                if (task.weatherReason !=
                    null) ...[
                  const SizedBox(height: 4),
                  Text(
                    task.weatherReason!,
                    style: AppTypography.caption
                        .copyWith(
                      color: AppColors.warning,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Badge action
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: task.actionType.color
                  .withValues(alpha: 0.12),
              borderRadius:
                  BorderRadius.circular(8),
            ),
            child: Text(
              task.actionType.emoji,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
