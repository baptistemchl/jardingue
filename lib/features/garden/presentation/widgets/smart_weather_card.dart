
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jardingue/core/services/weather/weather_analysis/garden_analysis.dart';
import 'package:jardingue/core/services/weather/weather_analysis/garden_analysis_ui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/providers/weather_providers.dart';
import '../../../../core/services/weather/weather_models.dart';
import '../../../../router/app_router.dart';
import '../../../weather/presentation/widgets/weather_animations.dart';

// ============================================
// CARTE MÉTÉO INTELLIGENTE
// ============================================

class SmartWeatherCard extends ConsumerWidget {
  const SmartWeatherCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(weatherDataProvider);

    // Utiliser .when avec skipLoadingOnRefresh pour gérer proprement les états
    return weatherAsync.when(
      skipLoadingOnRefresh: true,
      data: (weather) => _WeatherCardContent(
        weather: weather,
        onTap: () => context.go(AppRoutes.weather),
      ),
      loading: () => const _WeatherCardSkeleton(),
      error: (error, stack) {
        // Vérifier si c'est vraiment une erreur ou juste un état initial
        // Si l'erreur contient "initial" ou similaire, on affiche le skeleton
        final errorStr = error.toString().toLowerCase();
        final isInitialState =
            errorStr.contains('null') ||
            errorStr.contains('initial') ||
            errorStr.contains('no element');

        if (isInitialState) {
          return const _WeatherCardSkeleton();
        }

        return _WeatherCardError(
          onRetry: () => ref.invalidate(weatherDataProvider),
          errorMessage: error.toString(),
        );
      },
    );
  }
}

class _WeatherCardError extends StatelessWidget {
  final VoidCallback onRetry;
  final String errorMessage;

  const _WeatherCardError({required this.onRetry, required this.errorMessage});

  @override
  Widget build(BuildContext context) {
    // Déterminer si c'est une erreur de localisation ou de réseau
    final isLocationError =
        errorMessage.contains('location') ||
        errorMessage.contains('permission') ||
        errorMessage.contains('Location');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLocationError
                ? PhosphorIcons.mapPinLine(PhosphorIconsStyle.duotone)
                : PhosphorIcons.cloudSlash(PhosphorIconsStyle.duotone),
            size: 40,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 12),
          Text(
            isLocationError ? 'Localisation requise' : 'Météo indisponible',
            style: AppTypography.titleSmall.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isLocationError
                ? 'Activez la localisation pour voir la météo'
                : 'Impossible de charger les données météo',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: onRetry,
            icon: Icon(
              PhosphorIcons.arrowClockwise(PhosphorIconsStyle.bold),
              size: 16,
            ),
            label: const Text('Réessayer'),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

// ============================================
// SKELETON LOADING MÉTÉO
// ============================================

class _WeatherCardSkeleton extends StatefulWidget {
  const _WeatherCardSkeleton();

  @override
  State<_WeatherCardSkeleton> createState() => _WeatherCardSkeletonState();
}

class _WeatherCardSkeletonState extends State<_WeatherCardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _shimmerController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ligne 1: Température + condition + icône
              Row(
                children: [
                  _ShimmerBox(
                    width: 75,
                    height: 48,
                    borderRadius: 8,
                    shimmerValue: _shimmerController.value,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ShimmerBox(
                          width: 100,
                          height: 14,
                          borderRadius: 4,
                          shimmerValue: _shimmerController.value,
                        ),
                        const SizedBox(height: 8),
                        _ShimmerBox(
                          width: 70,
                          height: 12,
                          borderRadius: 4,
                          shimmerValue: _shimmerController.value,
                        ),
                      ],
                    ),
                  ),
                  _ShimmerBox(
                    width: 48,
                    height: 48,
                    borderRadius: 12,
                    shimmerValue: _shimmerController.value,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Ligne 2: Verdict
              _ShimmerBox(
                width: double.infinity,
                height: 38,
                borderRadius: 12,
                shimmerValue: _shimmerController.value,
              ),
              const SizedBox(height: 14),

              // Ligne 3: 3 indicateurs
              Row(
                children: [
                  Expanded(
                    child: _ShimmerBox(
                      height: 46,
                      borderRadius: 8,
                      shimmerValue: _shimmerController.value,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ShimmerBox(
                      height: 46,
                      borderRadius: 8,
                      shimmerValue: _shimmerController.value,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ShimmerBox(
                      height: 46,
                      borderRadius: 8,
                      shimmerValue: _shimmerController.value,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;
  final double shimmerValue;

  const _ShimmerBox({
    this.width,
    required this.height,
    required this.borderRadius,
    required this.shimmerValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment(-1.0 + 2 * shimmerValue, 0),
          end: Alignment(-0.5 + 2 * shimmerValue, 0),
          colors: [
            AppColors.border,
            AppColors.border.withValues(alpha: 0.3),
            AppColors.border,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}

class _WeatherCardContent extends StatelessWidget {
  final WeatherData weather;
  final VoidCallback onTap;

  const _WeatherCardContent({required this.weather, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final analysis = GardenAnalysis.fromWeather(weather);
    final condition = weather.current.condition;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Color(condition.primaryColor).withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Positioned.fill(child: WeatherBackground(condition: condition)),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          weather.current.temperatureDisplay,
                          style: AppTypography.displayLarge.copyWith(
                            fontSize: 44,
                            fontWeight: FontWeight.w300,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                condition.label,
                                style: AppTypography.labelMedium.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                              Text(
                                'Ressenti ${weather.current.feelsLikeDisplay}',
                                style: AppTypography.caption.copyWith(
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          condition.icon,
                          style: const TextStyle(fontSize: 48),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Verdict = EXACTEMENT celui de WeatherScreen
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: analysis.severity.color.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: analysis.severity.color.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            analysis.emoji,
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              analysis.verdict,
                              style: AppTypography.labelMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Indicateurs = EXACTEMENT les 3 catégories de l’écran
                    Row(
                      children: [
                        _DetailIndicator(
                          icon: '🌱',
                          label: analysis.plantingDetail,
                          status: _toIndicatorStatus(analysis.plantingStatus),
                        ),
                        const SizedBox(width: 8),
                        _DetailIndicator(
                          icon: '💧',
                          label: analysis.wateringDetail,
                          status: _toIndicatorStatus(analysis.wateringStatus),
                        ),
                        const SizedBox(width: 8),
                        _DetailIndicator(
                          icon: '🧺',
                          label: analysis.harvestDetail,
                          status: _toIndicatorStatus(analysis.harvestStatus),
                        ),
                      ],
                    ),

                    // Alertes = mêmes alertes que l’écran
                    if (analysis.alerts.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _WeatherAlertBanner(alert: analysis.alerts.first),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _IndicatorStatus _toIndicatorStatus(GardenStatus status) {
    switch (status) {
      case GardenStatus.good:
        return _IndicatorStatus.good;
      case GardenStatus.warning:
        return _IndicatorStatus.warning;
      case GardenStatus.bad:
        return _IndicatorStatus.bad;
    }
  }
}

// ============================================
// ALERTE MÉTÉO SURTAXÉE (BANNER)
// ============================================

class _WeatherAlertBanner extends StatelessWidget {
  final String alert;

  const _WeatherAlertBanner({required this.alert});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.amber.shade800,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.shade400, width: 1),
      ),
      child: Row(
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              alert,
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// INDICATEURS DÉTAILLÉS
// ============================================

class _DetailIndicator extends StatelessWidget {
  final String icon;
  final String label;
  final _IndicatorStatus status;

  const _DetailIndicator({
    required this.icon,
    required this.label,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    switch (status) {
      case _IndicatorStatus.good:
        bgColor = Colors.green.withValues(alpha: 0.3);
        break;
      case _IndicatorStatus.warning:
        bgColor = Colors.orange.withValues(alpha: 0.3);
        break;
      case _IndicatorStatus.bad:
        bgColor = Colors.red.withValues(alpha: 0.3);
        break;
    }

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

enum _IndicatorStatus { good, warning, bad }
