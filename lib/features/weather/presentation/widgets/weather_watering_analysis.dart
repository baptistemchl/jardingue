import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/services/weather/weather_analysis/garden_analysis.dart';
import '../../../../core/services/weather/weather_analysis/garden_analysis_ui.dart';
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

    final watering = analysis.watering;
    final color = watering.status.color;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusXxl,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                PhosphorIcons.drop(PhosphorIconsStyle.duotone),
                size: 22,
                color: AppColors.info,
              ),
              const SizedBox(width: 10),
              Text('Arrosage',
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  )),
            ],
          ),
          const SizedBox(height: 16),
          // Verdict consolidé
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.06),
              borderRadius: AppSpacing.borderRadiusLg,
              border: Border.all(color: color.withValues(alpha: 0.20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  watering.label,
                  style: AppTypography.titleSmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (watering.recommendations.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  ...watering.recommendations.map(
                    (r) => Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        r,
                        style: AppTypography.bodySmall.copyWith(height: 1.4),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Mesures',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textTertiary,
              letterSpacing: 0.3,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          WeatherAnalysisRow(
            label: 'Précipitations actuelles',
            value: '${current.precipitation.toStringAsFixed(1)} mm',
            ideal: current.precipitation > 0 ? 'Pluie ✓' : '-',
            status: current.precipitation > 0
                ? GardenStatus.good
                : GardenStatus.warning,
          ),
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
          WeatherAnalysisRow(
            label: 'Pluie prévue (6h)',
            value: '${precipNext6h.toStringAsFixed(1)} mm',
            ideal: precipNext6h > 2 ? 'Pas d\'arrosage' : 'Arrosez',
            status: precipNext6h > 2
                ? GardenStatus.good
                : (precipNext6h > 0
                    ? GardenStatus.warning
                    : GardenStatus.bad),
          ),
          WeatherAnalysisRow(
            label: 'Pluie prévue (24h)',
            value: '${precipNext24h.toStringAsFixed(1)} mm',
            ideal: '-',
            status: precipNext24h > 5
                ? GardenStatus.good
                : (precipNext24h > 0
                    ? GardenStatus.warning
                    : GardenStatus.bad),
          ),
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
          WeatherAnalysisRow(
            label: 'Évaporation',
            value: current.temperature > 25
                ? 'Forte'
                : (current.temperature > 15 ? 'Modérée' : 'Faible'),
            ideal:
                current.temperature > 25 ? 'Arrosez le soir' : '-',
            status: current.temperature > 30
                ? GardenStatus.warning
                : GardenStatus.good,
          ),
        ],
      ),
    );
  }
}
