import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/soil_task.dart';

class SoilTaskSection extends StatelessWidget {
  final List<SoilTask> tasks;

  const SoilTaskSection({
    super.key,
    required this.tasks,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.horizontalPadding,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                '🪴',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 8),
              Text(
                'Préparation du sol',
                style: AppTypography.titleSmall
                    .copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final task in tasks)
            _SoilTaskTile(task: task),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SoilTaskTile extends StatelessWidget {
  final SoilTask task;

  const _SoilTaskTile({required this.task});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Text(
            task.type.emoji,
            style: const TextStyle(fontSize: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  task.type.label,
                  style: AppTypography.labelLarge
                      .copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  task.message,
                  style: AppTypography.bodySmall
                      .copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (task.weatherReason != null)
                  Text(
                    task.weatherReason!,
                    style: AppTypography.caption
                        .copyWith(
                      color: AppColors.warning,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: task.urgency.color
                  .withValues(alpha: 0.12),
              borderRadius:
                  BorderRadius.circular(8),
            ),
            child: Text(
              task.urgency.label,
              style: AppTypography.caption.copyWith(
                color: task.urgency.color,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
