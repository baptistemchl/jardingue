import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/utils/plant_emoji_mapper.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../../domain/models/harvest_summary.dart';
import '../../providers/harvest_providers.dart';
import '../sheets/add_harvest_sheet.dart';
import '../_empty_tab_placeholder.dart';

class HarvestsTab extends ConsumerWidget {
  const HarvestsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final year = ref.watch(harvestYearProvider);
    final summaries = ref.watch(harvestSummariesProvider);
    final harvestsAsync = ref.watch(harvestsForYearProvider);

    return Stack(
      children: [
        harvestsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          error: (e, _) => _ErrorState(message: e.toString()),
          data: (_) {
            if (summaries.isEmpty) {
              return EmptyTabPlaceholder(
                icon: PhosphorIcons.basket(PhosphorIconsStyle.duotone),
                title: loc.carnetHarvestsEmptyTitle,
                subtitle: loc.carnetHarvestsEmptySubtitle,
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.only(bottom: 96),
              itemCount: summaries.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                if (i == 0) {
                  return _SeasonHeader(
                    year: year,
                    summaries: summaries,
                  );
                }
                return _HarvestSummaryCard(summary: summaries[i - 1]);
              },
            );
          },
        ),
        // Bouton flottant en bas à droite, dans la zone du drawer body.
        Positioned(
          bottom: 8,
          right: 0,
          child: _AddButton(
            label: loc.carnetHarvestsAddButton,
            onTap: () => AddHarvestSheet.show(context),
          ),
        ),
      ],
    );
  }
}

class _SeasonHeader extends StatelessWidget {
  final int year;
  final List<HarvestSummary> summaries;
  const _SeasonHeader({required this.year, required this.summaries});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final totalCount =
        summaries.fold<int>(0, (sum, s) => sum + s.harvestCount);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.secondary.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.carnetLine),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              PhosphorIcons.basket(PhosphorIconsStyle.fill),
              size: 20,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.carnetHarvestsTitleYear(year),
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  loc.carnetHarvestsSummaryLine(
                    summaries.length,
                    totalCount,
                  ),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HarvestSummaryCard extends StatelessWidget {
  final HarvestSummary summary;
  const _HarvestSummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final emoji = PlantEmojiMapper.fromName(
      summary.plantName,
      categoryCode: summary.plantCategoryCode,
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.carnetSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.carnetLine),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summary.plantName,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  loc.carnetHarvestsCardSubtitle(
                    summary.harvestCount,
                    _formatRelativeDate(context, summary.lastHarvestedAt),
                  ),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _QuantityBadge(
            quantity: summary.totalQuantity,
            unit: HarvestUnit.fromCode(summary.unit),
          ),
        ],
      ),
    );
  }

  String _formatRelativeDate(BuildContext context, DateTime d) {
    final loc = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diffDays = today.difference(day).inDays;
    if (diffDays == 0) return loc.dateRelativeToday;
    if (diffDays == 1) return loc.dateRelativeYesterday;
    if (diffDays < 7) return loc.dateRelativeDaysAgo(diffDays);
    const months = [
      'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
      'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
    ];
    return '${d.day} ${months[d.month - 1]}';
  }
}

class _QuantityBadge extends StatelessWidget {
  final double quantity;
  final HarvestUnit unit;
  const _QuantityBadge({required this.quantity, required this.unit});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final label = switch (unit) {
      HarvestUnit.grams => loc.addHarvestUnitGrams,
      HarvestUnit.kilos => loc.addHarvestUnitKilos,
      HarvestUnit.pieces => loc.addHarvestUnitPieces,
      HarvestUnit.bunches => loc.addHarvestUnitBunches,
    };
    // Format propre, jusqu'à 3 décimales sans zéros traînants :
    //   250    → "250"
    //   2.4    → "2,4"
    //   4.345  → "4,345"
    //   2.0    → "2"
    final formatted = _formatQuantity(quantity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            formatted,
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatQuantity(double q) {
  if (q == q.roundToDouble()) return q.toStringAsFixed(0);
  return q
      .toStringAsFixed(3)
      .replaceAll(RegExp(r'0+$'), '')
      .replaceAll(RegExp(r'\.$'), '')
      .replaceAll('.', ',');
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

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          style: AppTypography.caption.copyWith(color: AppColors.error),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
