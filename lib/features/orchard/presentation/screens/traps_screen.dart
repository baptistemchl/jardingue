import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jardingue/l10n/generated/app_localizations.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/providers/orchard_providers.dart';
import '../../../../core/theme/app_typography.dart';
import '../sheets/add_trap_sheet.dart';

/// Ecran de gestion CRUD des pieges a pheromones.
///
/// Liste tous les pieges, regroupes par arbre. Actions :
/// - Ajouter un piege (FAB) : choix de l'arbre puis [AddTrapSheet]
/// - Renouveler un piege (tap)
/// - Supprimer un piege (long press / menu)
class TrapsScreen extends ConsumerWidget {
  const TrapsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final remindersAsync = ref.watch(pheromoneTrapRemindersProvider);
    final treesAsync = ref.watch(userFruitTreesNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: AppSpacing.screenPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            PhosphorIcons.arrowLeft(PhosphorIconsStyle.bold),
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Icon(
                              PhosphorIcons.bug(PhosphorIconsStyle.duotone),
                              size: 24,
                              color: const Color(0xFFFB8C00),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            loc.trapsScreenTitle,
                            style: AppTypography.titleLarge.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
            remindersAsync.when(
              data: (all) {
                if (all.isEmpty) {
                  return SliverToBoxAdapter(
                    child: _EmptyState(
                      onAddTap: () => _pickTreeAndAddTrap(context, ref),
                    ),
                  );
                }
                return SliverPadding(
                  padding: AppSpacing.horizontalPadding,
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _TrapCard(reminder: all[index]),
                      childCount: all.length,
                    ),
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child:
                      Center(child: Text(loc.errorWithMessage(e.toString()))),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: treesAsync.maybeWhen(
        data: (trees) => trees.isEmpty
            ? null
            : FloatingActionButton.extended(
                onPressed: () => _pickTreeAndAddTrap(context, ref),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                icon: Icon(PhosphorIcons.plus(PhosphorIconsStyle.bold)),
                label: Text(loc.addTrapAction),
              ),
        orElse: () => null,
      ),
    );
  }

  Future<void> _pickTreeAndAddTrap(
      BuildContext context, WidgetRef ref) async {
    final loc = AppLocalizations.of(context)!;
    final treesAsync = ref.read(userFruitTreesNotifierProvider);
    final trees = treesAsync.maybeWhen(
      data: (list) => list,
      orElse: () => const <UserFruitTreeWithDetails>[],
    );
    if (trees.isEmpty) return;

    if (trees.length == 1) {
      await AddTrapSheet.show(context, trees.first);
      return;
    }

    // Plusieurs arbres : on demande lequel
    final selected = await showModalBottomSheet<UserFruitTreeWithDetails>(
      context: context,
      useRootNavigator: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  loc.pickTreeForTrap,
                  style: AppTypography.titleMedium,
                ),
              ),
              const SizedBox(height: 12),
              ...trees.map((t) => ListTile(
                    leading:
                        Text(t.emoji, style: const TextStyle(fontSize: 24)),
                    title: Text(t.name),
                    subtitle: t.variety != null ? Text(t.variety!) : null,
                    onTap: () => Navigator.pop(ctx, t),
                  )),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
    if (selected != null && context.mounted) {
      await AddTrapSheet.show(context, selected);
    }
  }
}

class _TrapCard extends ConsumerWidget {
  final PheromoneTrapReminder reminder;
  const _TrapCard({required this.reminder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final type = reminder.type;
    final now = DateTime.now();
    final isOverdue = reminder.isOverdueAt(now);
    final daysUntil = reminder.nextRenewalDue.difference(now).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(type.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.label,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      reminder.treeName,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  PhosphorIcons.dotsThreeVertical(PhosphorIconsStyle.bold),
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                onSelected: (value) async {
                  switch (value) {
                    case 'renew':
                      await _renew(context, ref);
                      break;
                    case 'delete':
                      await _confirmDelete(context, ref);
                      break;
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'renew',
                    child: Row(
                      children: [
                        Icon(
                          PhosphorIcons.arrowsClockwise(
                              PhosphorIconsStyle.regular),
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 10),
                        Text(loc.renewAction),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          PhosphorIcons.trash(PhosphorIconsStyle.regular),
                          size: 18,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: 10),
                        Text(loc.delete,
                            style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isOverdue
                  ? AppColors.warning.withValues(alpha: 0.1)
                  : AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  PhosphorIcons.calendar(PhosphorIconsStyle.regular),
                  size: 14,
                  color: isOverdue
                      ? AppColors.warning
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    isOverdue
                        ? loc.installedDaysAgo(reminder.daysSinceInstalled)
                        : loc.renewalInDays(daysUntil),
                    style: AppTypography.caption.copyWith(
                      color: isOverdue
                          ? AppColors.warning
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _renew(BuildContext context, WidgetRef ref) async {
    final loc = AppLocalizations.of(context)!;
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
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.deleteTrapTitle),
        content: Text(loc.deleteTrapConfirm(reminder.type.label)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(loc.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref
        .read(pheromoneTrapsNotifierProvider.notifier)
        .deleteTrap(reminder.trap.id);
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAddTap;

  const _EmptyState({required this.onAddTap});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Container(
      margin: AppSpacing.horizontalPadding,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Icon(
                PhosphorIcons.bug(PhosphorIconsStyle.duotone),
                size: 40,
                color: const Color(0xFFFB8C00),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            loc.trapsEmptyTitle,
            style: AppTypography.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            loc.trapsEmptySubtitle,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAddTap,
            icon: Icon(PhosphorIcons.plus(PhosphorIconsStyle.bold), size: 18),
            label: Text(loc.addTrapAction),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
