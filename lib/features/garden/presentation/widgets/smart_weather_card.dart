import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/providers/weather_providers.dart';
import '../../../../core/services/weather/location_service.dart';
import '../../../../core/services/weather/weather_models.dart';
import '../../../weather/presentation/widgets/weather_location_bar.dart';
import '../../../../router/app_router.dart';

// ============================================
// CARTE MÉTÉO SIMPLIFIÉE
// ============================================

class SmartWeatherCard extends ConsumerWidget {
  const SmartWeatherCard({super.key});

  static final _initialStatePattern = RegExp(
    r'null|initial|no element',
    caseSensitive: false,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(weatherDataProvider);

    return weatherAsync.when(
      skipLoadingOnRefresh: true,
      data: (weather) => _WeatherCardContent(
        weather: weather,
        onTap: () => context.push(AppRoutes.weather),
      ),
      loading: () => const _WeatherCardSkeleton(),
      error: (error, stack) {
        if (_initialStatePattern.hasMatch('$error')) {
          return const _WeatherCardSkeleton();
        }
        return _WeatherCardError(
          onRetry: () =>
              ref.invalidate(weatherDataProvider),
          errorMessage: '$error',
        );
      },
    );
  }
}

class _WeatherCardError extends StatelessWidget {
  final VoidCallback onRetry;
  final String errorMessage;

  const _WeatherCardError({
    required this.onRetry,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
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
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              PhosphorIcons.cloudSlash(PhosphorIconsStyle.duotone),
              size: 24,
              color: AppColors.warning,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Météo indisponible',
            style: AppTypography.titleSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            errorMessage,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: OutlinedButton.icon(
                    onPressed: onRetry,
                    icon: Icon(
                      PhosphorIcons.arrowClockwise(PhosphorIconsStyle.bold),
                      size: 14,
                    ),
                    label: Text(
                      'Réessayer',
                      style: AppTypography.captionStrong,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: ElevatedButton.icon(
                    onPressed: () => showModalBottomSheet(
                      useRootNavigator: true,
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const WeatherLocationPickerSheet(),
                    ),
                    icon: Icon(
                      PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.bold),
                      size: 14,
                    ),
                    label: Text(
                      'Choisir une ville',
                      style: AppTypography.captionStrong.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
            ],
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
// CONTENU PRINCIPAL - MÉTÉO
// ============================================

class _WeatherCardContent extends ConsumerWidget {
  final WeatherData weather;
  final VoidCallback onTap;

  const _WeatherCardContent({
    required this.weather,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final condition = weather.current.condition;
    final effectiveLocation = ref.watch(effectiveLocationProvider);
    final LocationResult? location = effectiveLocation.valueOrNull;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            // Bandeau localisation approximative
            if (location != null && location.hasFallback)
              _LocationIssueBanner(location: location, ref: ref),

            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      PhosphorIcons.sun(PhosphorIconsStyle.duotone),
                      size: 22,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Météo du jour',
                          style: AppTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          condition.label,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              PhosphorIcons.mapPin(PhosphorIconsStyle.fill),
                              size: 11,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                weather.location.displayName,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textTertiary,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
                    size: 18,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: AppColors.border),

            // Température + icone
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  Text(
                    condition.icon,
                    style: const TextStyle(fontSize: 44),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    weather.current.temperatureDisplay,
                    style: AppTypography.displayLarge.copyWith(
                      fontSize: 42,
                      fontWeight: FontWeight.w300,
                      color: AppColors.textPrimary,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ressenti ${weather.current.feelsLikeDisplay}',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getTodayMinMax(),
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Indicateurs
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  _WeatherChip(
                    emoji: '💧',
                    value: weather.current.humidityDisplay,
                    label: 'Humidité',
                  ),
                  const SizedBox(width: 8),
                  _WeatherChip(
                    emoji: '💨',
                    value: weather.current.windSpeedDisplay,
                    label: 'Vent',
                  ),
                  const SizedBox(width: 8),
                  _WeatherChip(
                    emoji: '🌡',
                    value: _getTodayMinMax(),
                    label: 'Min / Max',
                  ),
                ],
              ),
            ),

            // Lien conseils
            Divider(height: 1, color: AppColors.border),
            InkWell(
              onTap: onTap,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      PhosphorIcons.plant(PhosphorIconsStyle.fill),
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Voir les conseils jardinage',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
// BANDEAU LOCALISATION APPROXIMATIVE
// ============================================

class _LocationIssueBanner extends StatelessWidget {
  final LocationResult location;
  final WidgetRef ref;

  const _LocationIssueBanner({
    required this.location,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Icon(
            PhosphorIcons.mapPinLine(PhosphorIconsStyle.fill),
            size: 14,
            color: AppColors.warning,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Position approximative'
              '${location.source == LocationSource.defaultValue ? ' (Paris)' : ''}',
              style: AppTypography.caption.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => showModalBottomSheet(
              useRootNavigator: true,
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const WeatherLocationPickerSheet(),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Choisir une ville',
                style: AppTypography.captionStrong.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// CHIP INDICATEUR MÉTÉO
// ============================================

class _WeatherChip extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;

  const _WeatherChip({
    required this.emoji,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: AppColors.textTertiary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
