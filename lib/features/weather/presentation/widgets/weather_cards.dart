import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/glass_decoration.dart';
import '../../../../core/services/weather/weather_models.dart';

/// Carte météo principale
class MainWeatherCard extends StatelessWidget {
  final WeatherData weather;

  const MainWeatherCard({super.key, required this.weather});

  @override
  Widget build(BuildContext context) {
    final current = weather.current;
    final condition = current.condition;

    return GlassContainer(
      blur: 15,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(condition.primaryColor).withValues(alpha: 0.8),
            Color(condition.secondaryColor).withValues(alpha: 0.6),
          ],
        ),
        borderRadius: AppSpacing.borderRadiusXxl,
        boxShadow: [
          BoxShadow(
            color: Color(condition.primaryColor).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Température
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      current.temperatureDisplay,
                      style: AppTypography.displayLarge.copyWith(
                        fontSize: 72,
                        fontWeight: FontWeight.w200,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      condition.label,
                      style: AppTypography.titleMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ressenti ${current.feelsLikeDisplay}',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              // Icône météo
              Text(condition.icon, style: const TextStyle(fontSize: 64)),
            ],
          ),
          const SizedBox(height: 20),
          // Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _WeatherStat(
                icon: PhosphorIcons.drop(PhosphorIconsStyle.fill),
                value: current.humidityDisplay,
                label: 'Humidité',
              ),
              _WeatherStat(
                icon: PhosphorIcons.wind(PhosphorIconsStyle.fill),
                value: current.windSpeedDisplay,
                label: 'Vent ${current.windDirectionDisplay}',
              ),
              _WeatherStat(
                icon: PhosphorIcons.sun(PhosphorIconsStyle.fill),
                value: 'UV ${current.uvIndex.round()}',
                label: _uvLabel(current.uvIndex),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _uvLabel(double uv) {
    if (uv <= 2) return 'Faible';
    if (uv <= 5) return 'Modéré';
    if (uv <= 7) return 'Élevé';
    if (uv <= 10) return 'Très élevé';
    return 'Extrême';
  }
}

class _WeatherStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _WeatherStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: AppTypography.titleSmall.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

/// Carte de prévision horaire
class HourlyForecastCard extends StatelessWidget {
  final HourlyForecast forecast;
  final bool isNow;

  const HourlyForecastCard({
    super.key,
    required this.forecast,
    this.isNow = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 65,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxH = constraints.maxHeight;
          final isCompact = maxH.isFinite && maxH <= 80;

          final paddingV = isCompact ? 6.0 : 12.0;
          final gap = isCompact ? 4.0 : 8.0;
          final iconSize = isCompact ? 20.0 : 24.0;

          final showPrecip =
              !isCompact && forecast.precipitationProbability > 0;

          return Container(
            padding: EdgeInsets.symmetric(vertical: paddingV, horizontal: 8),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: isNow ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: isNow ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                SizedBox(height: gap),
                Text(
                  forecast.condition.icon,
                  style: TextStyle(fontSize: iconSize),
                ),
                SizedBox(height: gap),
                Text(
                  forecast.temperatureDisplay,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleSmall.copyWith(
                    color: isNow ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
                if (showPrecip) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${forecast.precipitationProbability}%',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.info,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Carte de prévision journalière
class DailyForecastCard extends StatelessWidget {
  final DailyForecast forecast;

  const DailyForecastCard({super.key, required this.forecast});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Jour
          Expanded(
            flex: 3,
            child: Text(
              forecast.dayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.titleSmall,
            ),
          ),
          // Icône + précipitations
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    forecast.condition.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                  if (forecast.precipitationProbability > 20) ...[
                    const SizedBox(width: 4),
                    Text(
                      '${forecast.precipitationProbability}%',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.info,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Températures
          Expanded(
            flex: 5,
            child: Row(
              children: [
                Text(
                  forecast.tempMinDisplay,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: LinearGradient(
                        colors: [AppColors.info, AppColors.warning],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  forecast.tempMaxDisplay,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
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

/// Carte phase de lune
class MoonPhaseCard extends StatelessWidget {
  final MoonData moon;

  const MoonPhaseCard({super.key, required this.moon});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(moon.phaseEmoji, style: const TextStyle(fontSize: 40)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(moon.phaseName, style: AppTypography.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      moon.isWaxing ? 'Lune croissante' : 'Lune décroissante',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              // Score jardinage
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _scoreColor(
                    moon.moonAdvice.score,
                  ).withValues(alpha: 0.15),
                  borderRadius: AppSpacing.borderRadiusFull,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      PhosphorIcons.plant(PhosphorIconsStyle.fill),
                      size: 14,
                      color: _scoreColor(moon.moonAdvice.score),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${moon.moonAdvice.score}/5',
                      style: AppTypography.labelSmall.copyWith(
                        color: _scoreColor(moon.moonAdvice.score),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            moon.moonAdvice.title,
            style: AppTypography.titleSmall.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: 4),
          Text(moon.moonAdvice.description, style: AppTypography.bodySmall),
          const SizedBox(height: 12),
          // Activités recommandées
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: moon.moonAdvice.goodFor.map((activity) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: AppSpacing.borderRadiusFull,
                ),
                child: Text(
                  activity,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.success,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Color _scoreColor(int score) {
    if (score >= 4) return AppColors.success;
    if (score >= 3) return AppColors.warning;
    return AppColors.textTertiary;
  }
}

/// Carte conseils jardinage
class GardeningAdviceCard extends StatelessWidget {
  final GardeningAdvice advice;

  const GardeningAdviceCard({super.key, required this.advice});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: AppSpacing.borderRadiusMd,
                ),
                child: Icon(
                  PhosphorIcons.lightbulb(PhosphorIconsStyle.fill),
                  color: AppColors.success,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Conseil du jour',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(advice.mainAdvice, style: AppTypography.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
          if (advice.tips.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...advice.tips.map(
              (tip) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  tip,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Indicateurs rapides
          Row(
            children: [
              _QuickIndicator(
                icon: PhosphorIcons.drop(PhosphorIconsStyle.fill),
                label: 'Arrosage',
                isGood: advice.goodForWatering,
              ),
              const SizedBox(width: 12),
              _QuickIndicator(
                icon: PhosphorIcons.plant(PhosphorIconsStyle.fill),
                label: 'Plantation',
                isGood: advice.goodForPlanting,
              ),
              const SizedBox(width: 12),
              _QuickIndicator(
                icon: PhosphorIcons.basket(PhosphorIconsStyle.fill),
                label: 'Récolte',
                isGood: advice.goodForHarvesting,
              ),
              if (advice.frostRisk) ...[
                const SizedBox(width: 12),
                _QuickIndicator(
                  icon: PhosphorIcons.snowflake(PhosphorIconsStyle.fill),
                  label: 'Gel',
                  isGood: false,
                  isWarning: true,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickIndicator extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isGood;
  final bool isWarning;

  const _QuickIndicator({
    required this.icon,
    required this.label,
    required this.isGood,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isWarning
        ? AppColors.error
        : (isGood ? AppColors.success : AppColors.textTertiary);

    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.caption.copyWith(color: color, fontSize: 10),
        ),
      ],
    );
  }
}
