import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/services/weather/weather_analysis/garden_analysis.dart';
import '../../../../core/services/weather/weather_analysis/garden_analysis_ui.dart';
import '../../../../core/theme/app_typography.dart';

/// Carte verdict — pattern Jardingue standard (surface blanche, header
/// 40×40, divider, contenu). Affiche le résultat de la cascade lune ×
/// météo sous forme de liste d'activités, pas de chips colorés.
class WeatherGardenVerdictCard extends StatelessWidget {
  final GardenAnalysis analysis;

  const WeatherGardenVerdictCard({super.key, required this.analysis});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusXl,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(analysis: analysis),
          Divider(height: 1, color: AppColors.border),
          _Body(analysis: analysis),
          Divider(height: 1, color: AppColors.border),
          _ActivityList(analysis: analysis),
          if (analysis.alerts.isNotEmpty) ...[
            Divider(height: 1, color: AppColors.border),
            _AlertsSection(alerts: analysis.alerts),
          ],
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final GardenAnalysis analysis;
  const _Header({required this.analysis});

  @override
  Widget build(BuildContext context) {
    final severityColor = analysis.severity.color;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: severityColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              PhosphorIcons.compass(PhosphorIconsStyle.duotone),
              size: 22,
              color: severityColor,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Au jardin aujourd\'hui',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  analysis.verdict,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: severityColor.withValues(alpha: 0.12),
              borderRadius: AppSpacing.borderRadiusFull,
            ),
            child: Text(
              analysis.scoreLabel,
              style: AppTypography.labelSmall.copyWith(
                color: severityColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final GardenAnalysis analysis;
  const _Body({required this.analysis});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            analysis.headline,
            style: AppTypography.titleLarge.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            analysis.summary,
            style: AppTypography.bodySmall.copyWith(height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _ActivityList extends StatelessWidget {
  final GardenAnalysis analysis;
  const _ActivityList({required this.analysis});

  @override
  Widget build(BuildContext context) {
    final items = [
      _ActivityRow(
        icon: PhosphorIcons.grains(PhosphorIconsStyle.regular),
        title: 'Semer',
        verdict: analysis.sowing,
      ),
      _ActivityRow(
        icon: PhosphorIcons.plant(PhosphorIconsStyle.regular),
        title: 'Repiquer',
        verdict: analysis.planting,
      ),
      _ActivityRow(
        icon: PhosphorIcons.basket(PhosphorIconsStyle.regular),
        title: 'Récolter',
        verdict: analysis.harvest,
      ),
      _ActivityRow(
        icon: PhosphorIcons.drop(PhosphorIconsStyle.regular),
        title: 'Arroser',
        verdict: analysis.watering,
      ),
    ];

    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          items[i],
          if (i < items.length - 1)
            Divider(height: 1, color: AppColors.border, indent: 16, endIndent: 16),
        ],
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final ActivityVerdict verdict;

  const _ActivityRow({
    required this.icon,
    required this.title,
    required this.verdict,
  });

  @override
  Widget build(BuildContext context) {
    final color = verdict.status.color;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _SourcePill(source: verdict.source),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  verdict.label,
                  style: AppTypography.bodySmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            _statusIcon(verdict.status),
            size: 18,
            color: color,
          ),
        ],
      ),
    );
  }

  IconData _statusIcon(GardenStatus s) => switch (s) {
        GardenStatus.good =>
          PhosphorIcons.checkCircle(PhosphorIconsStyle.regular),
        GardenStatus.warning => PhosphorIcons.warningCircle(
            PhosphorIconsStyle.regular,
          ),
        GardenStatus.bad =>
          PhosphorIcons.xCircle(PhosphorIconsStyle.regular),
      };
}

class _SourcePill extends StatelessWidget {
  final GardenVerdictSource source;

  const _SourcePill({required this.source});

  @override
  Widget build(BuildContext context) {
    final (label, icon) = switch (source) {
      GardenVerdictSource.lunar => (
        'lune',
        PhosphorIcons.moon(PhosphorIconsStyle.regular),
      ),
      GardenVerdictSource.weather => (
        'météo',
        PhosphorIcons.cloud(PhosphorIconsStyle.regular),
      ),
      GardenVerdictSource.both => (
        'lune + météo',
        PhosphorIcons.intersect(PhosphorIconsStyle.regular),
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppSpacing.borderRadiusFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 9, color: AppColors.textTertiary),
          const SizedBox(width: 3),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w600,
              fontSize: 10,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertsSection extends StatelessWidget {
  final List<String> alerts;
  const _AlertsSection({required this.alerts});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: alerts
            .map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      PhosphorIcons.warning(PhosphorIconsStyle.regular),
                      size: 16,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        a,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.error,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
