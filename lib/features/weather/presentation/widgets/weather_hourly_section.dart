import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/services/weather/weather_models.dart';
import '../../../../core/theme/app_typography.dart';

class WeatherHourlySection extends StatelessWidget {
  final List<HourlyForecast> hourlyForecast;

  const WeatherHourlySection({super.key, required this.hourlyForecast});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: AppSpacing.horizontalPadding,
          child: Row(
            children: [
              Icon(
                PhosphorIcons.clock(PhosphorIconsStyle.fill),
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Prochaines heures',
                style: AppTypography.titleMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: AppSpacing.horizontalPadding,
            itemCount: hourlyForecast.length.clamp(0, 24),
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) => _HourlyCard(
              forecast: hourlyForecast[index],
              isNow: index == 0,
            ),
          ),
        ),
      ],
    );
  }
}

class _HourlyCard extends StatelessWidget {
  final HourlyForecast forecast;
  final bool isNow;

  const _HourlyCard({required this.forecast, this.isNow = false});

  @override
  Widget build(BuildContext context) {
    final canPlant =
        forecast.temperature >= 10 &&
        forecast.temperature <= 28 &&
        forecast.precipitation < 2;

    return Container(
      width: 70,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: isNow
            ? AppColors.primary.withValues(alpha: 0.15)
            : AppColors.surface,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: isNow ? AppColors.primary : AppColors.border,
          width: isNow ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            isNow ? 'Maint.' : forecast.hourDisplay,
            style: AppTypography.caption.copyWith(
              color: isNow ? AppColors.primary : AppColors.textSecondary,
              fontWeight: isNow ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 6),
          Text(forecast.condition.icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(
            forecast.temperatureDisplay,
            style: AppTypography.labelMedium.copyWith(
              color: isNow ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
          if (forecast.precipitationProbability > 0) ...[
            const SizedBox(height: 4),
            Text(
              '💧${forecast.precipitationProbability}%',
              style: AppTypography.caption.copyWith(
                color: AppColors.info,
                fontSize: 9,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: canPlant
                  ? AppColors.success
                  : (forecast.temperature < 5
                        ? AppColors.error
                        : AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }
}
