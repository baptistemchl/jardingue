import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jardingue/l10n/generated/app_localizations.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/garden_event_providers.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/care_reminder.dart';
import 'care_reminder_tile.dart';

/// Carte de rappels generique pour un type de soin.
///
/// Parametree par [CareKind] : meme widget pour arrosage, fertilisation,
/// et tout autre soin futur. Masquee automatiquement si la liste est vide.
class CareRemindersCard extends ConsumerWidget {
  final CareKind kind;

  const CareRemindersCard({super.key, required this.kind});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersAsync = ref.watch(careRemindersProvider(kind));

    return remindersAsync.when(
      data: (reminders) {
        if (reminders.isEmpty) return const SizedBox.shrink();
        // Espacement haut interne : la card n'occupe 0 px QUAND elle est
        // masquée, ce qui garantit un écart inter-cards uniforme côté écran
        // (l'écran ne met pas de SizedBox autour pour éviter les doublons).
        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: _Card(kind: kind, reminders: reminders),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _Card extends StatelessWidget {
  final CareKind kind;
  final List<CareReminder> reminders;

  const _Card({required this.kind, required this.reminders});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final overdueCount =
        reminders.where((r) => r.isOverdue && !r.shouldSkip).length;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: kind.bgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    kind.icon(PhosphorIconsStyle.duotone),
                    size: 22,
                    color: kind.accentColor,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _title(loc, kind),
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _subtitle(loc, kind, overdueCount),
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

          // Liste des plantes (max 5 visibles)
          ...reminders
              .take(5)
              .map((reminder) => CareReminderTile(reminder: reminder)),

          if (reminders.length > 5) ...[
            Divider(
                height: 1,
                color: AppColors.border,
                indent: 16,
                endIndent: 16),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  loc.otherPlantsCount(reminders.length - 5),
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

  String _title(AppLocalizations loc, CareKind kind) {
    switch (kind) {
      case CareKind.watering:
        return loc.wateringToday;
      case CareKind.fertilizing:
        return loc.fertilizingToday;
    }
  }

  String _subtitle(AppLocalizations loc, CareKind kind, int overdueCount) {
    if (overdueCount == 0) return loc.allUpToDate;
    switch (kind) {
      case CareKind.watering:
        return loc.plantsToWaterCount(overdueCount);
      case CareKind.fertilizing:
        return loc.plantsToFertilizeCount(overdueCount);
    }
  }
}
