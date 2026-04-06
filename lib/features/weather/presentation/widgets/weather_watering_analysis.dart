import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/services/weather/weather_analysis/garden_analysis.dart';
import '../../../../core/services/weather/weather_models.dart';
import '../../../../core/theme/app_typography.dart';
import 'weather_analysis_row.dart';

class WeatherWateringAnalysisCard extends StatelessWidget {
  final GardenAnalysis analysis;
  final WeatherData weather;

  const WeatherWateringAnalysisCard({
    super.key,
    required this.analysis,
    required this.weather,
  });

  @override
  Widget build(BuildContext context) {
    final current = weather.current;
    final hourly = weather.hourlyForecast;

    // Calculs prévisions
    double precipNext6h = 0;
    double precipNext24h = 0;
    int maxPrecipProb = 0;

    for (int i = 0; i < hourly.length && i < 24; i++) {
      precipNext24h += hourly[i].precipitation;
      if (i < 6) precipNext6h += hourly[i].precipitation;
      if (hourly[i].precipitationProbability > maxPrecipProb) {
        maxPrecipProb = hourly[i].precipitationProbability;
      }
    }

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
                PhosphorIcons.drop(PhosphorIconsStyle.fill),
                size: 20,
                color: Colors.blue,
              ),
              const SizedBox(width: 8),
              Text('Analyse arrosage', style: AppTypography.titleMedium),
            ],
          ),
          const SizedBox(height: 16),

          // Précipitations actuelles
          WeatherAnalysisRow(
            label: 'Précipitations actuelles',
            value: '${current.precipitation.toStringAsFixed(1)} mm',
            ideal: current.precipitation > 0 ? 'Pluie ✓' : '-',
            status: current.precipitation > 0
                ? GardenStatus.good
                : GardenStatus.warning,
          ),

          // Humidité
          WeatherAnalysisRow(
            label: 'Humidité air',
            value: current.humidityDisplay,
            ideal: '50-70%',
            status: current.humidity >= 50 && current.humidity <= 80
                ? GardenStatus.good
                : (current.humidity < 30
                      ? GardenStatus.bad
                      : GardenStatus.warning),
          ),

          // Prévisions 6h
          WeatherAnalysisRow(
            label: 'Pluie prévue (6h)',
            value: '${precipNext6h.toStringAsFixed(1)} mm',
            ideal: precipNext6h > 2 ? 'Pas d\'arrosage' : 'Arrosez',
            status: precipNext6h > 2
                ? GardenStatus.good
                : (precipNext6h > 0 ? GardenStatus.warning : GardenStatus.bad),
          ),

          // Prévisions 24h
          WeatherAnalysisRow(
            label: 'Pluie prévue (24h)',
            value: '${precipNext24h.toStringAsFixed(1)} mm',
            ideal: '-',
            status: precipNext24h > 5
                ? GardenStatus.good
                : (precipNext24h > 0 ? GardenStatus.warning : GardenStatus.bad),
          ),

          // Probabilité max
          WeatherAnalysisRow(
            label: 'Probabilité pluie max',
            value: '$maxPrecipProb%',
            ideal: '> 60% = reportez',
            status: maxPrecipProb > 60
                ? GardenStatus.good
                : (maxPrecipProb > 30
                      ? GardenStatus.warning
                      : GardenStatus.bad),
          ),

          // Température (évaporation)
          WeatherAnalysisRow(
            label: 'Évaporation',
            value: current.temperature > 25
                ? 'Forte'
                : (current.temperature > 15 ? 'Modérée' : 'Faible'),
            ideal: current.temperature > 25 ? 'Arrosez le soir' : '-',
            status: current.temperature > 30
                ? GardenStatus.warning
                : GardenStatus.good,
          ),

          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),

          // Verdict arrosage
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: GardenStatus.good == analysis.wateringStatus
                  ? AppColors.success.withValues(alpha: 0.1)
                  : (analysis.wateringStatus == GardenStatus.warning
                        ? AppColors.warning.withValues(alpha: 0.1)
                        : AppColors.info.withValues(alpha: 0.1)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Text(
                  analysis.wateringStatus == GardenStatus.good
                      ? '✅'
                      : (analysis.wateringStatus == GardenStatus.warning
                            ? '⚠️'
                            : '💧'),
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Conseil', style: AppTypography.labelMedium),
                      Text(
                        analysis.wateringAdvice,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
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
