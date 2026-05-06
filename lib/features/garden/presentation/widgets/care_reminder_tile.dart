import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jardingue/l10n/generated/app_localizations.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/garden_event_providers.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/plant_emoji_mapper.dart';
import '../../domain/models/care_reminder.dart';

/// Tile generique d'un rappel de soin (arrosage, fertilisation, ...).
///
/// Branche les actions specifiques au CareKind via le notifier generique
/// [GardenEventNotifier.quickLogCare], et resout les libelles via le kind
/// passe en parametre — un seul widget pour tous les types.
class CareReminderTile extends ConsumerWidget {
  final CareReminder reminder;

  const CareReminderTile({super.key, required this.reminder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final plant = reminder.gardenPlant.plant;
    final emoji = plant != null
        ? PlantEmojiMapper.forPlant(plant)
        : '🌱';
    final name = reminder.gardenPlant.name;

    final (statusText, statusColor) = _statusFor(context);
    final shouldSkip = reminder.shouldSkip;

    return InkWell(
      onTap: !shouldSkip
          ? () {
              ref
                  .read(gardenEventNotifierProvider.notifier)
                  .quickLogCare(
                    reminder.kind,
                    reminder.gardenPlant.gardenPlant.id,
                  );
              ref.invalidate(careRemindersProvider(reminder.kind));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_snackbarMessage(loc, name, reminder.kind)),
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
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(reminder.kind.emoji,
                          style: const TextStyle(fontSize: 12)),
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

            // Bouton action ou badge skip
            if (!shouldSkip)
              _ActionPill(
                kind: reminder.kind,
                label: _actionLabel(loc, reminder.kind),
              )
            else
              const Text('🌧', style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }

  (String, Color) _statusFor(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    if (reminder.shouldSkip) {
      return (
        reminder.hint?.message ?? loc.rainExpectedPostponed,
        AppColors.info,
      );
    }
    if (reminder.isOverdue) {
      final days = reminder.daysSinceLast;
      if (days < 0) {
        // Jamais effectue
        return (_neverLabel(loc, reminder.kind), AppColors.warning);
      }
      return (_doneDaysAgoLabel(loc, reminder.kind, days), AppColors.warning);
    }
    return (loc.tomorrow, AppColors.textSecondary);
  }

  String _actionLabel(AppLocalizations loc, CareKind kind) {
    switch (kind) {
      case CareKind.watering:
        return loc.waterAction;
      case CareKind.fertilizing:
        return loc.fertilizeAction;
    }
  }

  String _snackbarMessage(AppLocalizations loc, String name, CareKind kind) {
    switch (kind) {
      case CareKind.watering:
        return loc.nameWatered(name);
      case CareKind.fertilizing:
        return loc.nameFertilized(name);
    }
  }

  String _neverLabel(AppLocalizations loc, CareKind kind) {
    switch (kind) {
      case CareKind.watering:
        return loc.neverWatered;
      case CareKind.fertilizing:
        return loc.neverFertilized;
    }
  }

  String _doneDaysAgoLabel(AppLocalizations loc, CareKind kind, int days) {
    switch (kind) {
      case CareKind.watering:
        return loc.wateredDaysAgo(days);
      case CareKind.fertilizing:
        return loc.fertilizedDaysAgo(days);
    }
  }
}

class _ActionPill extends StatelessWidget {
  final CareKind kind;
  final String label;

  const _ActionPill({required this.kind, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            kind.icon(PhosphorIconsStyle.fill),
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
