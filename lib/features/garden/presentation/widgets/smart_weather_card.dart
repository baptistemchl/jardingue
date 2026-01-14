import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/providers/weather_providers.dart';
import '../../../../core/services/weather/weather_models.dart';
import '../../../../router/app_router.dart';
import '../../../weather/presentation/widgets/weather_animations.dart';

// ============================================
// CARTE MÉTÉO SIMPLIFIÉE
// ============================================

class SmartWeatherCard extends ConsumerWidget {
  const SmartWeatherCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(weatherDataProvider);

    return weatherAsync.when(
      skipLoadingOnRefresh: true,
      data: (weather) => _WeatherCardContent(
        weather: weather,
        onTap: () => context.go(AppRoutes.weather),
      ),
      loading: () => const _WeatherCardSkeleton(),
      error: (error, stack) {
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
              Row(
                children: [
                  Expanded(
                    child: _ShimmerBox(
                      height: 56,
                      borderRadius: 10,
                      shimmerValue: _shimmerController.value,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ShimmerBox(
                      height: 56,
                      borderRadius: 10,
                      shimmerValue: _shimmerController.value,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ShimmerBox(
                      height: 56,
                      borderRadius: 10,
                      shimmerValue: _shimmerController.value,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _ShimmerBox(
                width: double.infinity,
                height: 40,
                borderRadius: 10,
                shimmerValue: _shimmerController.value,
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

// ============================================
// HELPER : Déterminer si le fond est clair
// ============================================

/// Calcule si une couleur est considérée comme "claire"
/// Utilise la formule de luminance relative
bool _isLightColor(Color color) {
  // Formule de luminance relative (W3C)
  final luminance =
      (0.299 * color.red + 0.587 * color.green + 0.114 * color.blue) / 255;
  return luminance > 0.5;
}

/// Détermine si le fond météo est clair selon le code condition
bool _isLightBackground(WeatherCondition condition) {
  final primaryColor = Color(condition.primaryColor);
  final secondaryColor = Color(condition.secondaryColor);

  // On fait la moyenne des deux couleurs
  final avgLuminance =
      (_isLightColor(primaryColor) && _isLightColor(secondaryColor));

  // Cas spécifiques où on sait que c'est clair
  // Codes : 0 (jour), 1, 2 = ciel clair/peu nuageux
  // Codes : 45, 48 = brouillard (gris clair)
  // Codes : 71, 73, 75, 77, 85, 86 = neige (blanc)
  final lightCodes = [1, 2, 45, 48, 71, 73, 75, 77, 85, 86];

  // Ensoleillé de jour est aussi clair
  if (condition.code == 0 && condition.animation == 'sunny') {
    return true;
  }

  return lightCodes.contains(condition.code) || avgLuminance;
}

// ============================================
// CONTENU PRINCIPAL - MÉTÉO SIMPLIFIÉE
// ============================================

class _WeatherCardContent extends StatelessWidget {
  final WeatherData weather;
  final VoidCallback onTap;

  const _WeatherCardContent({required this.weather, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final condition = weather.current.condition;
    final isLight = _isLightBackground(condition);

    // Couleurs adaptatives
    final textColor = isLight ? const Color(0xFF1A1A2E) : Colors.white;
    final textColorSecondary = isLight
        ? const Color(0xFF1A1A2E).withValues(alpha: 0.7)
        : Colors.white.withValues(alpha: 0.8);
    final textColorTertiary = isLight
        ? const Color(0xFF1A1A2E).withValues(alpha: 0.5)
        : Colors.white.withValues(alpha: 0.7);
    final overlayColor = isLight
        ? const Color(0xFF1A1A2E).withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.15);
    final overlayBorderColor = isLight
        ? const Color(0xFF1A1A2E).withValues(alpha: 0.15)
        : Colors.white.withValues(alpha: 0.25);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Color(condition.primaryColor).withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Fond animé météo
              Positioned.fill(child: WeatherBackground(condition: condition)),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // === LIGNE 1 : Température + Condition + Icône ===
                    Row(
                      children: [
                        // Température
                        Text(
                          weather.current.temperatureDisplay,
                          style: AppTypography.displayLarge.copyWith(
                            fontSize: 48,
                            fontWeight: FontWeight.w300,
                            color: textColor,
                            height: 1,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Condition + Ressenti
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                condition.label,
                                style: AppTypography.titleSmall.copyWith(
                                  color: textColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Ressenti ${weather.current.feelsLikeDisplay}',
                                style: AppTypography.caption.copyWith(
                                  color: textColorSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Icône météo
                        Text(
                          condition.icon,
                          style: const TextStyle(fontSize: 52),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // === LIGNE 2 : Indicateurs météo classiques ===
                    Row(
                      children: [
                        _WeatherIndicator(
                          icon: PhosphorIcons.drop(PhosphorIconsStyle.fill),
                          label: 'Humidité',
                          value: weather.current.humidityDisplay,
                          textColor: textColor,
                          textColorSecondary: textColorTertiary,
                          overlayColor: overlayColor,
                        ),
                        const SizedBox(width: 8),
                        _WeatherIndicator(
                          icon: PhosphorIcons.wind(PhosphorIconsStyle.fill),
                          label: 'Vent',
                          value: weather.current.windSpeedDisplay,
                          textColor: textColor,
                          textColorSecondary: textColorTertiary,
                          overlayColor: overlayColor,
                        ),
                        const SizedBox(width: 8),
                        _WeatherIndicator(
                          icon: PhosphorIcons.thermometer(
                            PhosphorIconsStyle.fill,
                          ),
                          label: 'Min / Max',
                          value: _getTodayMinMax(),
                          textColor: textColor,
                          textColorSecondary: textColorTertiary,
                          overlayColor: overlayColor,
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // === LIGNE 3 : Bouton vers conseils jardinage ===
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: overlayColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: overlayBorderColor),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            PhosphorIcons.plant(PhosphorIconsStyle.fill),
                            size: 18,
                            color: textColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Voir les conseils jardinage',
                            style: AppTypography.labelMedium.copyWith(
                              color: textColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
                            size: 16,
                            color: textColorSecondary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTodayMinMax() {
    if (weather.dailyForecast.isNotEmpty) {
      final today = weather.dailyForecast.first;
      return '${today.tempMin.round()}° / ${today.tempMax.round()}°';
    }
    return '--° / --°';
  }
}

// ============================================
// INDICATEUR MÉTÉO SIMPLE
// ============================================

class _WeatherIndicator extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color textColor;
  final Color textColorSecondary;
  final Color overlayColor;

  const _WeatherIndicator({
    required this.icon,
    required this.label,
    required this.value,
    required this.textColor,
    required this.textColorSecondary,
    required this.overlayColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: overlayColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: textColor.withValues(alpha: 0.85)),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTypography.labelMedium.copyWith(
                color: textColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: textColorSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
