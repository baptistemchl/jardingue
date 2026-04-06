import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/services/weather/weather_analysis/garden_analysis.dart';
import '../../../../core/services/weather/weather_models.dart';
import '../../../../core/theme/app_typography.dart';
import 'weather_analysis_row.dart';

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
    final current = weather.current;
    final daily = weather.dailyForecast;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusXl,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                PhosphorIcons.plant(PhosphorIconsStyle.fill),
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text('Analyse plantation', style: AppTypography.titleMedium),
            ],
          ),
          const SizedBox(height: 16),

          // Température actuelle vs idéale
          WeatherAnalysisRow(
            label: 'Température actuelle',
            value: current.temperatureDisplay,
            ideal: '15-25°C',
            status: _getTempStatus(current.temperature),
          ),

          // Température ressentie
          WeatherAnalysisRow(
            label: 'Ressenti',
            value: current.feelsLikeDisplay,
            ideal: '> 10°C',
            status: current.feelsLike >= 10
                ? GardenStatus.good
                : (current.feelsLike >= 5
                      ? GardenStatus.warning
                      : GardenStatus.bad),
          ),

          // Température min cette nuit
          if (daily.isNotEmpty)
            WeatherAnalysisRow(
              label: 'Min. cette nuit',
              value: '${daily[0].tempMin.round()}°C',
              ideal: '> 5°C',
              status: daily[0].tempMin >= 5
                  ? GardenStatus.good
                  : (daily[0].tempMin >= 0
                        ? GardenStatus.warning
                        : GardenStatus.bad),
            ),

          // Vent
          WeatherAnalysisRow(
            label: 'Vent',
            value: current.windSpeedDisplay,
            ideal: '< 20 km/h',
            status: current.windSpeed < 20
                ? GardenStatus.good
                : (current.windSpeed < 35
                      ? GardenStatus.warning
                      : GardenStatus.bad),
          ),

          // Sol (basé sur précipitations récentes)
          WeatherAnalysisRow(
            label: 'Sol',
            value: current.precipitation > 0
                ? 'Humide'
                : (current.humidity > 70 ? 'Correct' : 'Sec'),
            ideal: 'Humide/frais',
            status: current.precipitation > 5
                ? GardenStatus.warning
                : GardenStatus.good,
          ),

          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),

          // Recommandations
          Text('Recommandations', style: AppTypography.labelMedium),
          const SizedBox(height: 8),
          ...analysis.plantingRecommendations.map(
            (rec) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rec.startsWith('✓')
                        ? ''
                        : (rec.startsWith('✗') ? '' : '• '),
                    style: AppTypography.bodySmall,
                  ),
                  Expanded(
                    child: Text(
                      rec,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  GardenStatus _getTempStatus(double temp) {
    if (temp >= 15 && temp <= 25) return GardenStatus.good;
    if (temp >= 10 && temp <= 30) return GardenStatus.warning;
    return GardenStatus.bad;
  }
}
