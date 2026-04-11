import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/planning_task.dart';
import '../../domain/models/task_urgency.dart';
import 'planning_task_card.dart';

class PlanningTaskSection extends StatelessWidget {
  final TaskUrgency urgency;
  final List<PlanningTask> tasks;

  const PlanningTaskSection({
    super.key,
    required this.urgency,
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
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: urgency.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${urgency.label} '
                '(${tasks.length})',
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
            PlanningTaskCard(task: task),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
