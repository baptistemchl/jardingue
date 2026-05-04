import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jardingue/l10n/generated/app_localizations.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/orchard_providers.dart';
import '../../../../core/theme/app_typography.dart';
import '../screens/orchard_screen.dart';

/// Carte de rappels de renouvellement de pieges a pheromones.
///
/// Deux modes via [compact] :
/// - `compact: true` : mini-resume (compteur + tap pour ouvrir l'ecran).
///   Utilise sur l'ecran Jardin pour ne pas surcharger.
/// - `compact: false` : liste detaillee avec actions quick-renew. Utilise
///   sur l'ecran Verger.
///
/// Masquee automatiquement quand il n'y a aucun piege en retard ou bientot
/// du, pour ne pas surcharger l'UI quand tout est OK.
class PheromoneTrapRemindersCard extends ConsumerWidget {
  final bool compact;

  const PheromoneTrapRemindersCard({super.key, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersAsync = ref.watch(pheromoneTrapRemindersProvider);
    return remindersAsync.when(
      data: (all) {
        // Filtre : on n'affiche que les pieges en retard ou demain (cf. care).
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final relevant = all.where((r) {
          final daysUntil = r.nextRenewalDue.difference(today).inDays;
          return daysUntil <= 1;
        }).toList();
        if (relevant.isEmpty) return const SizedBox.shrink();
        return compact
            ? _CompactCard(reminders: relevant)
            : _FullCard(reminders: relevant);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _CompactCard extends StatelessWidget {
  final List<PheromoneTrapReminder> reminders;
  const _CompactCard({required this.reminders});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final overdueCount = reminders.where((r) {
      final now = DateTime.now();
      return r.isOverdueAt(now);
    }).length;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(builder: (_) => const OrchardScreen()),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                PhosphorIcons.bug(PhosphorIconsStyle.duotone),
                size: 22,
                color: const Color(0xFFFB8C00),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.pheromoneTrapsToReplace(reminders.length),
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    overdueCount > 0
                        ? loc.pheromoneTrapsOverdueCount(overdueCount)
                        : loc.pheromoneTrapsDueSoon,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
              size: 18,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _FullCard extends ConsumerWidget {
  final List<PheromoneTrapReminder> reminders;
  const _FullCard({required this.reminders});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final overdueCount = reminders
        .where((r) => r.isOverdueAt(DateTime.now()))
        .length;

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
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    PhosphorIcons.bug(PhosphorIconsStyle.duotone),
                    size: 22,
                    color: const Color(0xFFFB8C00),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.pheromoneTrapsTitle,
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        overdueCount > 0
                            ? loc.pheromoneTrapsOverdueCount(overdueCount)
                            : loc.pheromoneTrapsDueSoon,
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
          ...reminders.take(5).map((r) => _ReminderTile(reminder: r)),
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
                  loc.otherTrapsCount(reminders.length - 5),
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
}

class _ReminderTile extends ConsumerWidget {
  final PheromoneTrapReminder reminder;
  const _ReminderTile({required this.reminder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final type = reminder.type;
    final isOverdue = reminder.isOverdueAt(DateTime.now());
    final daysSince = reminder.daysSinceInstalled;

    return InkWell(
      onTap: () async {
        await ref
            .read(pheromoneTrapsNotifierProvider.notifier)
            .renewTrap(reminder.trap.id);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.trapRenewedFor(reminder.treeName)),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(type.emoji, style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${type.label} — ${reminder.treeName}',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('🦋', style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        isOverdue
                            ? loc.installedDaysAgo(daysSince)
                            : loc.tomorrow,
                        style: AppTypography.caption.copyWith(
                          color: isOverdue
                              ? AppColors.warning
                              : AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    PhosphorIcons.arrowsClockwise(PhosphorIconsStyle.fill),
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    loc.renewAction,
                    style: AppTypography.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
