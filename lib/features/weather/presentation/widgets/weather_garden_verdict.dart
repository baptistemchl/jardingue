import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/services/weather/weather_analysis/garden_analysis.dart';
import '../../../../core/services/weather/weather_analysis/garden_analysis_ui.dart';
import '../../../../core/theme/app_typography.dart';

class WeatherGardenVerdictCard extends StatelessWidget {
  final GardenAnalysis analysis;

  const WeatherGardenVerdictCard({super.key, required this.analysis});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusXl,
        border: Border.all(
          color: analysis.severity.color.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: analysis.severity.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    analysis.emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verdict jardinage',
                      style: AppTypography.labelMedium.copyWith(
                        color: analysis.severity.color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(analysis.verdict, style: AppTypography.titleSmall),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: analysis.severity.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  analysis.scoreLabel,
                  style: AppTypography.labelMedium.copyWith(
                    color: analysis.severity.color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (analysis.alerts.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...analysis.alerts.map(
              (alert) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Text('⚠️', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        alert,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _VerdictIndicator(
                  emoji: '🌱',
                  label: 'Plantation',
                  status: analysis.plantingStatus,
                  detail: analysis.plantingDetail,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _VerdictIndicator(
                  emoji: '💧',
                  label: 'Arrosage',
                  status: analysis.wateringStatus,
                  detail: analysis.wateringDetail,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _VerdictIndicator(
                  emoji: '🧺',
                  label: 'Récolte',
                  status: analysis.harvestStatus,
                  detail: analysis.harvestDetail,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VerdictIndicator extends StatelessWidget {
  final String emoji;
  final String label;
  final GardenStatus status;
  final String detail;

  const _VerdictIndicator({
    required this.emoji,
    required this.label,
    required this.status,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case GardenStatus.good:
        color = AppColors.success;
        break;
      case GardenStatus.warning:
        color = AppColors.warning;
        break;
      case GardenStatus.bad:
        color = AppColors.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            detail,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 9,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}
