import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/services/weather/weather_models.dart';
import '../../../../core/theme/app_typography.dart';

class WeatherDetailedConditionsCard extends StatelessWidget {
  final WeatherData weather;

  const WeatherDetailedConditionsCard({super.key, required this.weather});

  @override
  Widget build(BuildContext context) {
    final current = weather.current;
    final daily = weather.dailyForecast.isNotEmpty
        ? weather.dailyForecast[0]
        : null;

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
                PhosphorIcons.thermometer(PhosphorIconsStyle.fill),
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text('Conditions détaillées', style: AppTypography.titleMedium),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _DetailTile(
                  icon: '🌡️',
                  label: 'Température',
                  value: current.temperatureDisplay,
                ),
              ),
              Expanded(
                child: _DetailTile(
                  icon: '🤒',
                  label: 'Ressenti',
                  value: current.feelsLikeDisplay,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DetailTile(
                  icon: '💧',
                  label: 'Humidité',
                  value: current.humidityDisplay,
                ),
              ),
              Expanded(
                child: _DetailTile(
                  icon: '🌧️',
                  label: 'Précipitations',
                  value: '${current.precipitation.toStringAsFixed(1)} mm',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DetailTile(
                  icon: '💨',
                  label: 'Vent',
                  value:
                      '${current.windSpeedDisplay} ${current.windDirectionDisplay}',
                ),
              ),
              Expanded(
                child: _DetailTile(
                  icon: '☁️',
                  label: 'Couverture',
                  value: '${current.cloudCover}%',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DetailTile(
                  icon: '☀️',
                  label: 'UV Index',
                  value:
                      '${current.uvIndex.round()} (${_uvLabel(current.uvIndex)})',
                ),
              ),
              Expanded(
                child: _DetailTile(
                  icon: '🧭',
                  label: 'Pression',
                  value: '${current.pressure.round()} hPa',
                ),
              ),
            ],
          ),
          if (daily != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DetailTile(
                    icon: '🌅',
                    label: 'Lever soleil',
                    value: _formatTime(daily.sunrise),
                  ),
                ),
                Expanded(
                  child: _DetailTile(
                    icon: '🌇',
                    label: 'Coucher soleil',
                    value: _formatTime(daily.sunset),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _uvLabel(double uv) {
    if (uv <= 2) return 'Faible';
    if (uv <= 5) return 'Modéré';
    if (uv <= 7) return 'Élevé';
    return 'Très élevé';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class _DetailTile extends StatelessWidget {
  final String icon;
  final String label;
  final String value;

  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: AppTypography.labelMedium),
        ],
      ),
    );
  }
}
