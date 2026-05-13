import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/services/weather/weather_analysis/garden_analysis.dart';
import '../../../../core/services/weather/weather_analysis/garden_analysis_ui.dart';
import '../../../../core/services/weather/weather_models.dart';
import '../../../../core/theme/app_typography.dart';

/// Conseils du jour — déroulé des recommandations par activité.
/// Pattern Jardingue : surface blanche, header 40×40, divider, contenu.
class WeatherPlantingAnalysisCard extends StatelessWidget {
  final GardenAnalysis analysis;
  final WeatherData weather;

  const WeatherPlantingAnalysisCard({
    super.key,
    required this.analysis,
    required this.weather,
  });

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
          _Header(),
          Divider(height: 1, color: AppColors.border),
          _ActivityBlock(
            icon: PhosphorIcons.grains(PhosphorIconsStyle.regular),
            title: 'Semer',
            verdict: analysis.sowing,
          ),
          Divider(height: 1, color: AppColors.border, indent: 16),
          _ActivityBlock(
            icon: PhosphorIcons.plant(PhosphorIconsStyle.regular),
            title: 'Repiquer / Planter',
            verdict: analysis.planting,
          ),
          Divider(height: 1, color: AppColors.border, indent: 16),
          _ActivityBlock(
            icon: PhosphorIcons.basket(PhosphorIconsStyle.regular),
            title: 'Récolter',
            verdict: analysis.harvest,
          ),
          Divider(height: 1, color: AppColors.border, indent: 16),
          _ActivityBlock(
            icon: PhosphorIcons.drop(PhosphorIconsStyle.regular),
            title: 'Arroser',
            verdict: analysis.watering,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
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
              PhosphorIcons.notebook(PhosphorIconsStyle.duotone),
              size: 22,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Conseils du jour',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Détaillés par activité',
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

class _ActivityBlock extends StatelessWidget {
  final IconData icon;
  final String title;
  final ActivityVerdict verdict;
  final bool isLast;

  const _ActivityBlock({
    required this.icon,
    required this.title,
    required this.verdict,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = verdict.status.color;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, isLast ? 18 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: AppSpacing.borderRadiusFull,
                ),
                child: Text(
                  verdict.label,
                  style: AppTypography.labelSmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          if (verdict.recommendations.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...verdict.recommendations.map(
              (r) => Padding(
                padding: const EdgeInsets.only(left: 32, bottom: 4),
                child: Text(
                  r,
                  style: AppTypography.bodySmall.copyWith(
                    height: 1.45,
                    color: AppColors.textPrimary.withValues(alpha: 0.85),
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
