import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jardingue/l10n/generated/app_localizations.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/providers/garden_event_providers.dart';
import '../../../../core/utils/plant_emoji_mapper.dart';
import '../../domain/models/watering_reminder.dart';

/// Carte affichant les rappels d'arrosage du jour
class WateringRemindersCard extends ConsumerWidget {
  const WateringRemindersCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersAsync = ref.watch(wateringRemindersProvider);

    return remindersAsync.when(
      data: (reminders) {
        if (reminders.isEmpty) return const SizedBox.shrink();
        return _WateringCard(reminders: reminders);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _WateringCard extends ConsumerWidget {
  final List<WateringReminder> reminders;

  const _WateringCard({required this.reminders});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overdueCount =
        reminders.where((r) => r.isOverdue && !r.weatherSaysSkip).length;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header — meme style que "Mes potagers"
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    PhosphorIcons.drop(PhosphorIconsStyle.duotone),
                    size: 22,
                    color: const Color(0xFF42A5F5),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.wateringToday,
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _subtitle(context, overdueCount),
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: AppColors.border),

          // Liste des plantes
          ...reminders.take(5).map(
                (reminder) => _ReminderTile(reminder: reminder),
              ),

          if (reminders.length > 5) ...[
            Divider(height: 1, color: AppColors.border, indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  AppLocalizations.of(context)!.otherPlantsCount(reminders.length - 5),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _subtitle(BuildContext context, int overdueCount) {
    if (overdueCount == 0) return AppLocalizations.of(context)!.allUpToDate;
    return AppLocalizations.of(context)!.plantsToWaterCount(overdueCount);
  }
}

class _ReminderTile extends ConsumerWidget {
  final WateringReminder reminder;

  const _ReminderTile({required this.reminder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plant = reminder.gardenPlant.plant;
    final emoji = plant != null
        ? PlantEmojiMapper.fromName(
            plant.commonName,
            categoryCode: plant.categoryCode,
          )
        : '🌱';
    final name = reminder.gardenPlant.name;

    final String statusText;
    final Color statusColor;

    if (reminder.weatherSaysSkip) {
      statusText = AppLocalizations.of(context)!.rainExpectedPostponed;
      statusColor = AppColors.info;
    } else if (reminder.isOverdue) {
      final days = reminder.daysSinceLastWatering;
      statusText =
          days < 0 ? AppLocalizations.of(context)!.neverWatered : AppLocalizations.of(context)!.wateredDaysAgo(days);
      statusColor = AppColors.warning;
    } else {
      statusText = AppLocalizations.of(context)!.tomorrow;
      statusColor = AppColors.textSecondary;
    }

    return InkWell(
      onTap: !reminder.weatherSaysSkip
          ? () {
              ref
                  .read(gardenEventNotifierProvider.notifier)
                  .quickWater(reminder.gardenPlant.gardenPlant.id);
              ref.invalidate(wateringRemindersProvider);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.nameWatered(name)),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Emoji plante
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 14),

            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('💧', style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: AppTypography.caption.copyWith(
                          color: statusColor,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Bouton arroser ou badge pluie
            if (!reminder.weatherSaysSkip)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      PhosphorIcons.drop(PhosphorIconsStyle.fill),
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      AppLocalizations.of(context)!.waterAction,
                      style: AppTypography.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            else
              Text('🌧', style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
