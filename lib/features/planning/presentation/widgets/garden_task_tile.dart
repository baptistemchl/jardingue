import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/garden_task_data.dart';

/// Tuile tâche potagère avec checkbox.
class GardenTaskTile extends StatelessWidget {
  final GardenTaskData task;
  final bool isCompleted;
  final VoidCallback onToggle;

  const GardenTaskTile({
    super.key,
    required this.task,
    required this.isCompleted,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted
              ? AppColors.success
                  .withValues(alpha: 0.3)
              : AppColors.border,
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
              ),
              const SizedBox(width: 10),

              // Emoji catégorie
              Text(
                task.category.emoji,
                style: const TextStyle(
                  fontSize: 18,
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
                      task.title,
                      style: AppTypography
                          .labelMedium
                          .copyWith(
                        fontWeight:
                            FontWeight.w600,
                        color: isCompleted
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
                    const SizedBox(height: 2),
                    Text(
                      task.description,
                      style: AppTypography
                          .caption
                          .copyWith(
                        color: AppColors
                            .textSecondary,
                        decoration: isCompleted
                            ? TextDecoration
                                .lineThrough
                            : null,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Priorité
              if (task.priority == 'high')
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning
                        .withValues(alpha: 0.12),
                    borderRadius:
                        BorderRadius.circular(6),
                  ),
                  child: Text(
                    '!',
                    style: AppTypography
                        .labelSmall
                        .copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w700,
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

  const _CheckBox({required this.isCompleted});

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
              : AppColors.border,
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
