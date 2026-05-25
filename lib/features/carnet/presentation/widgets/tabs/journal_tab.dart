import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/providers/database_providers.dart';
import '../../../../../core/services/database/app_database.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../providers/journal_providers.dart';
import '../sheets/_shared_sheet_fields.dart';
import '../sheets/add_journal_entry_sheet.dart';
import '../_empty_tab_placeholder.dart';

class JournalTab extends ConsumerWidget {
  const JournalTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final entriesAsync = ref.watch(allJournalEntriesProvider);

    return Stack(
      children: [
        entriesAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          error: (e, _) => Center(
            child: Text(e.toString(),
                style: AppTypography.caption.copyWith(color: AppColors.error)),
          ),
          data: (entries) {
            if (entries.isEmpty) {
              return EmptyTabPlaceholder(
                icon: PhosphorIcons.notebook(PhosphorIconsStyle.duotone),
                title: loc.carnetJournalEmptyTitle,
                subtitle: loc.carnetJournalEmptySubtitle,
              );
            }
            // Groupage par mois pour donner du rythme visuel.
            final byMonth = <String, List<JournalEntry>>{};
            for (final e in entries) {
              final key = '${e.entryDate.year}-${e.entryDate.month}';
              byMonth.putIfAbsent(key, () => []).add(e);
            }
            return ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                for (final group in byMonth.entries) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
                    child: Text(
                      _formatMonthHeader(group.value.first.entryDate),
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  ...group.value.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _JournalCard(entry: e),
                      )),
                ],
              ],
            );
          },
        ),
        Positioned(
          bottom: 8,
          right: 0,
          child: _AddButton(
            label: loc.carnetJournalAddButton,
            onTap: () => AddJournalEntrySheet.show(context),
          ),
        ),
      ],
    );
  }

  String _formatMonthHeader(DateTime d) {
    const months = [
      'JANVIER', 'FÉVRIER', 'MARS', 'AVRIL', 'MAI', 'JUIN',
      'JUILLET', 'AOÛT', 'SEPTEMBRE', 'OCTOBRE', 'NOVEMBRE', 'DÉCEMBRE',
    ];
    return '${months[d.month - 1]} ${d.year}';
  }
}

class _JournalCard extends ConsumerWidget {
  final JournalEntry entry;
  const _JournalCard({required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => AddJournalEntrySheet.show(context, existing: entry),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: AppColors.carnetSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.carnetLine),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mini-bande verticale jaune soleil sur le côté gauche
              // pour rappeler un favori/feuille de cahier.
              Container(
                width: 4,
                height: 56,
                margin: const EdgeInsets.only(right: 12, top: 2),
                decoration: BoxDecoration(
                  color: AppColors.carnetAccent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _shortDate(entry.entryDate),
                          style: AppTypography.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () => _confirmDelete(context, ref),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              PhosphorIcons.trash(
                                  PhosphorIconsStyle.regular),
                              size: 14,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (entry.title != null && entry.title!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        entry.title!,
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      entry.content,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                    if (entry.updatedAt
                            .difference(entry.createdAt)
                            .inMinutes >
                        1) ...[
                      const SizedBox(height: 6),
                      Text(
                        loc.carnetJournalEditedLabel,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textTertiary,
                          fontStyle: FontStyle.italic,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.carnetJournalDeleteTitle),
        content: Text(loc.carnetJournalDeleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(loc.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final db = ref.read(databaseProvider);
      await db.deleteJournalEntry(entry.id);
    }
  }

  String _shortDate(DateTime d) {
    return formatCarnetDate(d);
  }
}

class _AddButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _AddButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                PhosphorIcons.plus(PhosphorIconsStyle.bold),
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
