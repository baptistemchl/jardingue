import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jardingue/core/services/weather/weather_analysis/garden_analysis.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/widgets/decorative_background.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/providers/weather_providers.dart';
import '../../../../core/services/weather/weather_models.dart';
import '../../../../core/theme/app_typography.dart';
import '../widgets/weather_animations.dart';
import '../widgets/weather_current_card.dart';
import '../widgets/weather_daily_section.dart';
import '../widgets/weather_detailed_conditions.dart';
import '../widgets/weather_garden_verdict.dart';
import '../widgets/weather_hourly_section.dart';
import '../widgets/weather_location_bar.dart';
import '../widgets/weather_moon_section.dart';
import '../widgets/weather_planting_analysis.dart';
import '../widgets/weather_watering_analysis.dart';
import 'package:jardingue/l10n/generated/app_localizations.dart';

class WeatherScreen extends ConsumerStatefulWidget {
  const WeatherScreen({super.key});

  @override
  ConsumerState<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends ConsumerState<WeatherScreen> {
  /// Garde la derniere donnee meteo valide pour eviter les flashs d'erreur
  WeatherData? _lastData;

  @override
  Widget build(BuildContext context) {
    final weatherAsync = ref.watch(weatherDataProvider);

    return Scaffold(
      body: weatherAsync.when(
        data: (weather) {
          _lastData = weather;
          return _WeatherContent(weather: weather);
        },
        loading: () {
          if (_lastData != null) {
            return _WeatherContent(weather: _lastData!);
          }
          return const _WeatherLoading();
        },
        error: (error, _) {
          // Si on a deja des donnees, les garder
          if (_lastData != null) {
            return _WeatherContent(weather: _lastData!);
          }
          return _WeatherError(
            error: error.toString(),
            onRetry: () {
              ref.invalidate(currentLocationProvider);
              ref.invalidate(weatherDataProvider);
            },
          );
        },
      ),
    );
  }
}

class _WeatherContent extends StatelessWidget {
  final WeatherData weather;

  const _WeatherContent({required this.weather});

  @override
  Widget build(BuildContext context) {
    final condition = weather.current.condition;
    final analysis = GardenAnalysis.fromWeather(weather);

    return Stack(
      children: [
        // Background météo animé
        Positioned.fill(child: WeatherBackground(condition: condition)),

        // Ronds décoratifs par-dessus
        Positioned.fill(child: const DecorativeBackground()),

        SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(child: WeatherHeader(weather: weather)),

              // Carte météo principale
              SliverToBoxAdapter(
                child: Padding(
                  padding: AppSpacing.horizontalPadding,
                  child: WeatherCurrentCard(weather: weather),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // VERDICT JARDINAGE
              SliverToBoxAdapter(
                child: Padding(
                  padding: AppSpacing.horizontalPadding,
                  child: WeatherGardenVerdictCard(analysis: analysis),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // ANALYSE DÉTAILLÉE PLANTATION
              SliverToBoxAdapter(
                child: Padding(
                  padding: AppSpacing.horizontalPadding,
                  child: WeatherPlantingAnalysisCard(
                    analysis: analysis,
                    weather: weather,
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // ANALYSE ARROSAGE
              SliverToBoxAdapter(
                child: Padding(
                  padding: AppSpacing.horizontalPadding,
                  child: WeatherWateringAnalysisCard(
                    analysis: analysis,
                    weather: weather,
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // CONDITIONS DÉTAILLÉES
              SliverToBoxAdapter(
                child: Padding(
                  padding: AppSpacing.horizontalPadding,
                  child: WeatherDetailedConditionsCard(weather: weather),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // PRÉVISIONS HORAIRES
              SliverToBoxAdapter(
                child: WeatherHourlySection(
                  hourlyForecast: weather.hourlyForecast,
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // PRÉVISIONS 7 JOURS AVEC ANALYSE
              SliverToBoxAdapter(
                child: Padding(
                  padding: AppSpacing.horizontalPadding,
                  child: WeatherDailySection.buildTitle(),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              SliverPadding(
                padding: AppSpacing.horizontalPadding,
                sliver: WeatherDailySection(
                  dailyForecast: weather.dailyForecast,
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // PHASE DE LUNE
              SliverToBoxAdapter(
                child: Padding(
                  padding: AppSpacing.horizontalPadding,
                  child: WeatherMoonCard(moon: weather.moon),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================
// LOADING / ERROR
// ============================================

class _WeatherLoading extends StatelessWidget {
  const _WeatherLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.background,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🌤️', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.weatherLoading),
          ],
        ),
      ),
    );
  }
}

class _WeatherError extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _WeatherError({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const DecorativeBackground(),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    PhosphorIcons.cloudSlash(PhosphorIconsStyle.duotone),
                    size: 40,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  AppLocalizations.of(context)!.weatherUnavailable,
                  style: AppTypography.headlineMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
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
                      size: 18,
                    ),
                    label: Text(
                      AppLocalizations.of(context)!.chooseCity,
                      style: AppTypography.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton.icon(
                    onPressed: onRetry,
                    icon: Icon(
                      PhosphorIcons.arrowClockwise(PhosphorIconsStyle.bold),
                      size: 18,
                    ),
                    label: Text(
                      AppLocalizations.of(context)!.retry,
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
