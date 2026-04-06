import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/services/weather/weather_models.dart';
import '../../../../core/theme/app_typography.dart';

class WeatherDailySection extends StatelessWidget {
  final List<DailyForecast> dailyForecast;

  const WeatherDailySection({super.key, required this.dailyForecast});

  /// Builds the title row for the daily section (used as a separate sliver)
  static Widget buildTitle() {
    return Row(
      children: [
        Icon(
          PhosphorIcons.calendar(PhosphorIconsStyle.fill),
          size: 18,
          color: AppColors.primary,
        ),
        const SizedBox(width: 8),
        Text(
          'Prévisions 7 jours',
          style: AppTypography.titleMedium,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _DailyCard(forecast: dailyForecast[index]),
        ),
        childCount: dailyForecast.length,
      ),
    );
  }
}

class _DailyCard extends StatelessWidget {
  final DailyForecast forecast;

  const _DailyCard({required this.forecast});

  @override
  Widget build(BuildContext context) {
    // Analyse pour ce jour
    final canPlant =
        forecast.tempMax >= 12 &&
        forecast.tempMin >= 3 &&
        forecast.precipitationProbability < 70;
    final frostRisk = forecast.tempMin < 2;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Jour
          SizedBox(
            width: 70,
            child: Text(forecast.dayName, style: AppTypography.labelMedium),
          ),

          // Icône
          SizedBox(
            width: 40,
            child: Text(
              forecast.condition.icon,
              style: const TextStyle(fontSize: 24),
              textAlign: TextAlign.center,
            ),
          ),

          // Températures
          Expanded(
            child: Row(
              children: [
                Text(forecast.tempMaxDisplay, style: AppTypography.labelMedium),
                Text(
                  ' / ',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                Text(
                  forecast.tempMinDisplay,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Précipitations
          if (forecast.precipitationProbability > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '💧${forecast.precipitationProbability}%',
                style: AppTypography.caption.copyWith(
                  color: AppColors.info,
                  fontSize: 10,
                ),
              ),
            ),

          // Indicateurs jardinage
          if (frostRisk)
            Container(
              padding: const EdgeInsets.all(4),
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('❄️', style: TextStyle(fontSize: 12)),
            ),

          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: canPlant
                  ? AppColors.success
                  : (frostRisk ? AppColors.error : AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }
}
