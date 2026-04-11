import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/planning_task.dart';

/// Tuile tâche plant avec checkbox.
class PlanningTaskTile extends StatelessWidget {
  final PlanningTask task;
  final bool isCompleted;
  final VoidCallback onToggle;

  const PlanningTaskTile({
    super.key,
    required this.task,
    required this.isCompleted,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final dimmed =
        isCompleted || task.blockedByWeather;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted
              ? AppColors.success
                  .withValues(alpha: 0.3)
              : task.blockedByWeather
                  ? AppColors.border
                  : task.actionType.color
                      .withValues(alpha: 0.2),
        ),
      ),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          child: Row(
            children: [
              // Checkbox
              _CheckBox(
                isCompleted: isCompleted,
                color: task.actionType.color,
              ),
              const SizedBox(width: 10),

              // Emoji plant
              Text(
                task.plantEmoji,
                style: TextStyle(
                  fontSize: 20,
                  color: dimmed
                      ? Colors.grey
                      : null,
                ),
              ),
              const SizedBox(width: 10),

              // Contenu
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.plantName,
                      style: AppTypography
                          .labelMedium
                          .copyWith(
                        fontWeight:
                            FontWeight.w600,
                        color: dimmed
                            ? AppColors
                                .textTertiary
                            : AppColors
                                .textPrimary,
                        decoration: isCompleted
                            ? TextDecoration
                                .lineThrough
                            : null,
                      ),
                    ),
                    Text(
                      task.message,
                      style: AppTypography
                          .caption
                          .copyWith(
                        color: AppColors
                            .textSecondary,
                        decoration: isCompleted
                            ? TextDecoration
                                .lineThrough
                            : null,
                      ),
                    ),
                    if (task.weatherReason !=
                        null)
                      Text(
                        task.weatherReason!,
                        style: AppTypography
                            .caption
                            .copyWith(
                          color: AppColors.warning,
                          fontStyle:
                              FontStyle.italic,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ),

              // Badge action
              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: task.actionType.color
                      .withValues(alpha: 0.12),
                  borderRadius:
                      BorderRadius.circular(6),
                ),
                child: Text(
                  task.actionType.emoji,
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckBox extends StatelessWidget {
  final bool isCompleted;
  final Color color;

  const _CheckBox({
    required this.isCompleted,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(
        milliseconds: 200,
      ),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: isCompleted
            ? AppColors.success
            : Colors.transparent,
        borderRadius:
            BorderRadius.circular(6),
        border: Border.all(
          color: isCompleted
              ? AppColors.success
              : color.withValues(alpha: 0.4),
          width: 2,
        ),
      ),
      child: isCompleted
          ? const Icon(
              Icons.check,
              size: 14,
              color: Colors.white,
            )
          : null,
    );
  }
}
