import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jardingue/core/services/weather/weather_analysis/garden_analysis.dart';
import 'package:jardingue/core/services/weather/weather_analysis/garden_analysis_ui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/providers/weather_providers.dart';
import '../../../../core/services/weather/weather_models.dart';
import '../../../../core/theme/app_typography.dart';
import '../widgets/weather_animations.dart';

class WeatherScreen extends ConsumerWidget {
  const WeatherScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationAsync = ref.watch(effectiveLocationProvider);
    final weatherAsync = ref.watch(weatherDataProvider);

    final isLocating = locationAsync.isLoading && !locationAsync.hasValue;

    return Scaffold(
      body: isLocating
          ? const _WeatherLoading(label: 'Localisation en cours...')
          : weatherAsync.when(
        data: (weather) => _WeatherContent(weather: weather),
        loading: () => const _WeatherLoading(
          label: 'Chargement des données météo...',
        ),
        error: (error, _) => _WeatherError(
          error: error.toString(),
          onRetry: () => _retry(ref),
          onPickLocation: () => _openLocationPicker(context),
        ),
      ),
    );
  }

  void _retry(WidgetRef ref) {
    ref.invalidate(weatherDataProvider);
    ref.invalidate(currentLocationProvider);
    ref.invalidate(effectiveLocationProvider);
  }

  void _openLocationPicker(BuildContext context) {
    showModalBottomSheet(
      useRootNavigator: true,
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LocationPickerSheet(),
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
        Positioned.fill(child: _DecorativeOverlay()),

        SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(child: _Header(weather: weather)),

              // Carte météo principale
              SliverToBoxAdapter(
                child: Padding(
                  padding: AppSpacing.horizontalPadding,
                  child: _MainWeatherCard(weather: weather),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // VERDICT JARDINAGE
              SliverToBoxAdapter(
                child: Padding(
                  padding: AppSpacing.horizontalPadding,
                  child: _GardenVerdictCard(analysis: analysis),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // ANALYSE DÉTAILLÉE PLANTATION
              SliverToBoxAdapter(
                child: Padding(
                  padding: AppSpacing.horizontalPadding,
                  child: _PlantingAnalysisCard(
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
                  child: _WateringAnalysisCard(
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
                  child: _DetailedConditionsCard(weather: weather),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // PRÉVISIONS HORAIRES
              SliverToBoxAdapter(
                child: Column(
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
                        itemCount: weather.hourlyForecast.length.clamp(0, 24),
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) => _HourlyCard(
                          forecast: weather.hourlyForecast[index],
                          isNow: index == 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // PRÉVISIONS 7 JOURS AVEC ANALYSE
              SliverToBoxAdapter(
                child: Padding(
                  padding: AppSpacing.horizontalPadding,
                  child: Row(
                    children: [
                      Icon(
                        PhosphorIcons.calendar(PhosphorIconsStyle.fill),
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Prévisions 7 jours',
                        style: AppTypography.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              SliverPadding(
                padding: AppSpacing.horizontalPadding,
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _DailyCard(forecast: weather.dailyForecast[index]),
                    ),
                    childCount: weather.dailyForecast.length,
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // PHASE DE LUNE
              SliverToBoxAdapter(
                child: Padding(
                  padding: AppSpacing.horizontalPadding,
                  child: _MoonCard(moon: weather.moon),
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
// HEADER
// ============================================

class _Header extends ConsumerWidget {
  final WeatherData weather;

  const _Header({required this.weather});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Météo', style: AppTypography.displayMedium),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => _showLocationPicker(context, ref),
                      child: Row(
                        children: [
                          Icon(
                            PhosphorIcons.mapPin(PhosphorIconsStyle.fill),
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            weather.location.displayName,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            PhosphorIcons.caretDown(PhosphorIconsStyle.bold),
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => ref.invalidate(weatherDataProvider),
                icon: Icon(
                  PhosphorIcons.arrowClockwise(PhosphorIconsStyle.regular),
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatDate(DateTime.now()),
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const jours = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche',
    ];
    const mois = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ];
    return '${jours[date.weekday - 1]} ${date.day} ${mois[date.month - 1]}';
  }

  void _showLocationPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      useRootNavigator: true,
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LocationPickerSheet(),
    );
  }
}

// ============================================
// CARTE MÉTÉO PRINCIPALE
// ============================================

class _MainWeatherCard extends StatelessWidget {
  final WeatherData weather;

  const _MainWeatherCard({required this.weather});

  @override
  Widget build(BuildContext context) {
    final current = weather.current;
    final condition = current.condition;
    final daily = weather.dailyForecast.isNotEmpty
        ? weather.dailyForecast[0]
        : null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(condition.primaryColor).withValues(alpha: 0.85),
            Color(condition.secondaryColor).withValues(alpha: 0.7),
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
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      current.temperatureDisplay,
                      style: AppTypography.displayLarge.copyWith(
                        fontSize: 64,
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
                    Text(
                      'Ressenti ${current.feelsLikeDisplay}',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    if (daily != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            PhosphorIcons.arrowUp(PhosphorIconsStyle.bold),
                            size: 14,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                          Text(
                            ' ${daily.tempMaxDisplay}',
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            PhosphorIcons.arrowDown(PhosphorIconsStyle.bold),
                            size: 14,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                          Text(
                            ' ${daily.tempMinDisplay}',
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Text(condition.icon, style: const TextStyle(fontSize: 64)),
            ],
          ),
          const SizedBox(height: 20),
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
              _WeatherStat(
                icon: PhosphorIcons.cloudRain(PhosphorIconsStyle.fill),
                value: '${current.precipitation.toStringAsFixed(1)}mm',
                label: 'Précip.',
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
        Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.labelMedium.copyWith(color: Colors.white),
        ),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

// ============================================
// VERDICT JARDINAGE GLOBAL
// ============================================

class _GardenVerdictCard extends StatelessWidget {
  final GardenAnalysis analysis;

  const _GardenVerdictCard({required this.analysis});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusXl,
        border: Border.all(
          color: analysis.severity.color.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: analysis.severity.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    analysis.emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verdict jardinage',
                      style: AppTypography.labelMedium.copyWith(
                        color: analysis.severity.color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(analysis.verdict, style: AppTypography.titleSmall),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: analysis.severity.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  analysis.scoreLabel,
                  style: AppTypography.labelMedium.copyWith(
                    color: analysis.severity.color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (analysis.alerts.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...analysis.alerts.map(
              (alert) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Text('⚠️', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        alert,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _VerdictIndicator(
                  emoji: '🌱',
                  label: 'Plantation',
                  status: analysis.plantingStatus,
                  detail: analysis.plantingDetail,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _VerdictIndicator(
                  emoji: '💧',
                  label: 'Arrosage',
                  status: analysis.wateringStatus,
                  detail: analysis.wateringDetail,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _VerdictIndicator(
                  emoji: '🧺',
                  label: 'Récolte',
                  status: analysis.harvestStatus,
                  detail: analysis.harvestDetail,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VerdictIndicator extends StatelessWidget {
  final String emoji;
  final String label;
  final GardenStatus status;
  final String detail;

  const _VerdictIndicator({
    required this.emoji,
    required this.label,
    required this.status,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case GardenStatus.good:
        color = AppColors.success;
        break;
      case GardenStatus.warning:
        color = AppColors.warning;
        break;
      case GardenStatus.bad:
        color = AppColors.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            detail,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 9,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

// ============================================
// ANALYSE PLANTATION
// ============================================

class _PlantingAnalysisCard extends StatelessWidget {
  final GardenAnalysis analysis;
  final WeatherData weather;

  const _PlantingAnalysisCard({required this.analysis, required this.weather});

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
          _AnalysisRow(
            label: 'Température actuelle',
            value: current.temperatureDisplay,
            ideal: '15-25°C',
            status: _getTempStatus(current.temperature),
          ),

          // Température ressentie
          _AnalysisRow(
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
            _AnalysisRow(
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
          _AnalysisRow(
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
          _AnalysisRow(
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

// ============================================
// ANALYSE ARROSAGE
// ============================================

class _WateringAnalysisCard extends StatelessWidget {
  final GardenAnalysis analysis;
  final WeatherData weather;

  const _WateringAnalysisCard({required this.analysis, required this.weather});

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
          _AnalysisRow(
            label: 'Précipitations actuelles',
            value: '${current.precipitation.toStringAsFixed(1)} mm',
            ideal: current.precipitation > 0 ? 'Pluie ✓' : '-',
            status: current.precipitation > 0
                ? GardenStatus.good
                : GardenStatus.warning,
          ),

          // Humidité
          _AnalysisRow(
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
          _AnalysisRow(
            label: 'Pluie prévue (6h)',
            value: '${precipNext6h.toStringAsFixed(1)} mm',
            ideal: precipNext6h > 2 ? 'Pas d\'arrosage' : 'Arrosez',
            status: precipNext6h > 2
                ? GardenStatus.good
                : (precipNext6h > 0 ? GardenStatus.warning : GardenStatus.bad),
          ),

          // Prévisions 24h
          _AnalysisRow(
            label: 'Pluie prévue (24h)',
            value: '${precipNext24h.toStringAsFixed(1)} mm',
            ideal: '-',
            status: precipNext24h > 5
                ? GardenStatus.good
                : (precipNext24h > 0 ? GardenStatus.warning : GardenStatus.bad),
          ),

          // Probabilité max
          _AnalysisRow(
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
          _AnalysisRow(
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

// ============================================
// CONDITIONS DÉTAILLÉES
// ============================================

class _DetailedConditionsCard extends StatelessWidget {
  final WeatherData weather;

  const _DetailedConditionsCard({required this.weather});

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

class _AnalysisRow extends StatelessWidget {
  final String label;
  final String value;
  final String ideal;
  final GardenStatus status;

  const _AnalysisRow({
    required this.label,
    required this.value,
    required this.ideal,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case GardenStatus.good:
        statusColor = AppColors.success;
        statusIcon = PhosphorIcons.checkCircle(PhosphorIconsStyle.fill);
        break;
      case GardenStatus.warning:
        statusColor = AppColors.warning;
        statusIcon = PhosphorIcons.warning(PhosphorIconsStyle.fill);
        break;
      case GardenStatus.bad:
        statusColor = AppColors.error;
        statusIcon = PhosphorIcons.xCircle(PhosphorIconsStyle.fill);
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(statusIcon, size: 16, color: statusColor),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: AppTypography.bodySmall)),
          Text(value, style: AppTypography.labelMedium),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              ideal,
              style: AppTypography.caption.copyWith(
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// CARTES HORAIRES / JOURNALIÈRES
// ============================================

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

class _DailyCard extends StatelessWidget {
  final DailyForecast forecast;

  const _DailyCard({required this.forecast});

  @override
  Widget build(BuildContext context) {
    // Analyse pour ce jour
    final canPlant =
        forecast.tempMax >= 12 &&
        forecast.tempMin >= 3 &&
        forecast.precipitationProbability < 70;
    final frostRisk = forecast.tempMin < 2;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Jour
          SizedBox(
            width: 70,
            child: Text(forecast.dayName, style: AppTypography.labelMedium),
          ),

          // Icône
          SizedBox(
            width: 40,
            child: Text(
              forecast.condition.icon,
              style: const TextStyle(fontSize: 24),
              textAlign: TextAlign.center,
            ),
          ),

          // Températures
          Expanded(
            child: Row(
              children: [
                Text(forecast.tempMaxDisplay, style: AppTypography.labelMedium),
                Text(
                  ' / ',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                Text(
                  forecast.tempMinDisplay,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Précipitations
          if (forecast.precipitationProbability > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '💧${forecast.precipitationProbability}%',
                style: AppTypography.caption.copyWith(
                  color: AppColors.info,
                  fontSize: 10,
                ),
              ),
            ),

          // Indicateurs jardinage
          if (frostRisk)
            Container(
              padding: const EdgeInsets.all(4),
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('❄️', style: TextStyle(fontSize: 12)),
            ),

          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: canPlant
                  ? AppColors.success
                  : (frostRisk ? AppColors.error : AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// CARTE LUNE
// ============================================

class _MoonCard extends StatelessWidget {
  final MoonData moon;

  const _MoonCard({required this.moon});

  @override
  Widget build(BuildContext context) {
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
              Text(moon.phaseEmoji, style: const TextStyle(fontSize: 40)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(moon.phaseName, style: AppTypography.titleMedium),
                    Text(
                      moon.isWaxing ? 'Lune croissante' : 'Lune décroissante',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _scoreColor(
                    moon.moonAdvice.score,
                  ).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
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
          Text(
            moon.moonAdvice.description,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Text('Recommandé :', style: AppTypography.labelSmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: moon.moonAdvice.goodFor
                .map(
                  (activity) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      activity,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          if (moon.moonAdvice.avoid.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('À éviter :', style: AppTypography.labelSmall),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: moon.moonAdvice.avoid
                  .map(
                    (activity) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        activity,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
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

// ============================================
// LOCATION PICKER
// ============================================

class _LocationPickerSheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<_LocationPickerSheet> createState() =>
      _LocationPickerSheetState();
}

class _LocationPickerSheetState extends ConsumerState<_LocationPickerSheet> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(citySearchProvider(_searchQuery));
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: AppSpacing.horizontalPadding,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher une ville...',
                prefixIcon: Icon(
                  PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.regular),
                  color: AppColors.textTertiary,
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: searchResults.when(
              data: (results) {
                if (results.isEmpty && _searchQuery.length >= 2) {
                  return Center(
                    child: Text(
                      'Aucune ville trouvée',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final location = results[index];
                    return ListTile(
                      leading: Icon(
                        PhosphorIcons.mapPin(PhosphorIconsStyle.regular),
                        color: AppColors.primary,
                      ),
                      title: Text(location.city ?? ''),
                      subtitle: Text(location.country ?? ''),
                      onTap: () {
                        ref.read(selectedLocationProvider.notifier).state =
                            location;
                        Navigator.pop(context);
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) =>
                  const Center(child: Text('Erreur de recherche')),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// LOADING / ERROR
// ============================================

class _WeatherLoading extends StatelessWidget {
  final String label;

  const _WeatherLoading({required this.label});

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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🌤️', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                label,
                style: AppTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeatherError extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  final VoidCallback onPickLocation;

  const _WeatherError({
    required this.error,
    required this.onRetry,
    required this.onPickLocation,
  });

  @override
  Widget build(BuildContext context) {
    final isLocationError = _isLocationError(error);

    final title = isLocationError
        ? 'Localisation requise'
        : 'Météo indisponible';

    final message = isLocationError
        ? 'Activez la localisation ou choisissez une ville.'
        : 'Impossible de récupérer les données météo.';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.error.withValues(alpha: 0.08),
            AppColors.background,
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isLocationError ? '📍' : '😕',
                    style: const TextStyle(fontSize: 56),
                  ),
                  const SizedBox(height: 12),
                  Text(title, style: AppTypography.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (isLocationError) ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onPickLocation,
                            icon: Icon(
                              PhosphorIcons.mapPin(
                                PhosphorIconsStyle.bold,
                              ),
                            ),
                            label: const Text('Choisir une ville'),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onRetry,
                          icon: Icon(
                            PhosphorIcons.arrowClockwise(
                              PhosphorIconsStyle.bold,
                            ),
                          ),
                          label: const Text('Réessayer'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text(
                      'Détails',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          error,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _isLocationError(String value) {
    final lower = value.toLowerCase();
    return lower.contains('location') ||
        lower.contains('permission') ||
        lower.contains('denied') ||
        lower.contains('gps');
  }
}

// ============================================
// BACKGROUND DÉCORATIF - RONDS ÉPARS
// ============================================

class _DecorativeOverlay extends StatelessWidget {
  const _DecorativeOverlay();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return IgnorePointer(
      child: CustomPaint(
        size: size,
        painter: _OrganicBlobsPainter(
          primaryColor: AppColors.primary,
          primaryLightColor: AppColors.primaryContainer,
        ),
      ),
    );
  }
}

class _OrganicBlobsPainter extends CustomPainter {
  final Color primaryColor;
  final Color primaryLightColor;

  _OrganicBlobsPainter({
    required this.primaryColor,
    required this.primaryLightColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Ronds verts foncés (primary)
    final darkPaint = Paint()..style = PaintingStyle.fill;

    // Ronds verts clairs (primaryContainer)
    final lightPaint = Paint()..style = PaintingStyle.fill;

    // === COIN HAUT DROITE ===
    // Grand rond vert clair
    lightPaint.color = primaryLightColor.withValues(alpha: 0.4);
    canvas.drawCircle(Offset(size.width + 20, -30), 120, lightPaint);

    // Rond vert foncé moyen
    darkPaint.color = primaryColor.withValues(alpha: 0.12);
    canvas.drawCircle(Offset(size.width - 40, 60), 45, darkPaint);

    // Petit rond vert clair
    lightPaint.color = primaryLightColor.withValues(alpha: 0.35);
    canvas.drawCircle(Offset(size.width - 20, 130), 25, lightPaint);

    // === COIN HAUT GAUCHE ===
    // Rond moyen vert clair
    lightPaint.color = primaryLightColor.withValues(alpha: 0.3);
    canvas.drawCircle(Offset(-30, 80), 55, lightPaint);

    // Petit rond vert foncé
    darkPaint.color = primaryColor.withValues(alpha: 0.1);
    canvas.drawCircle(Offset(40, 50), 20, darkPaint);

    // === MILIEU GAUCHE ===
    // Grand rond vert clair
    lightPaint.color = primaryLightColor.withValues(alpha: 0.25);
    canvas.drawCircle(Offset(-60, size.height * 0.4), 90, lightPaint);

    // Petit rond vert foncé
    darkPaint.color = primaryColor.withValues(alpha: 0.08);
    canvas.drawCircle(Offset(25, size.height * 0.35), 18, darkPaint);

    // === MILIEU DROITE ===
    // Rond moyen vert clair
    lightPaint.color = primaryLightColor.withValues(alpha: 0.2);
    canvas.drawCircle(
      Offset(size.width + 30, size.height * 0.5),
      70,
      lightPaint,
    );

    // Petit rond vert foncé
    darkPaint.color = primaryColor.withValues(alpha: 0.06);
    canvas.drawCircle(
      Offset(size.width - 35, size.height * 0.45),
      15,
      darkPaint,
    );

    // === BAS GAUCHE ===
    // Grand rond vert clair
    lightPaint.color = primaryLightColor.withValues(alpha: 0.35);
    canvas.drawCircle(Offset(-50, size.height * 0.75), 100, lightPaint);

    // Rond moyen vert foncé
    darkPaint.color = primaryColor.withValues(alpha: 0.1);
    canvas.drawCircle(Offset(50, size.height * 0.8), 35, darkPaint);

    // Petit rond vert clair
    lightPaint.color = primaryLightColor.withValues(alpha: 0.25);
    canvas.drawCircle(Offset(20, size.height * 0.7), 22, lightPaint);

    // === BAS DROITE ===
    // Rond moyen vert clair
    lightPaint.color = primaryLightColor.withValues(alpha: 0.3);
    canvas.drawCircle(
      Offset(size.width + 40, size.height * 0.85),
      80,
      lightPaint,
    );

    // Petit rond vert foncé
    darkPaint.color = primaryColor.withValues(alpha: 0.08);
    canvas.drawCircle(
      Offset(size.width - 50, size.height * 0.9),
      25,
      darkPaint,
    );

    // === PETITS RONDS DISPERSÉS ===
    darkPaint.color = primaryColor.withValues(alpha: 0.05);
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.15),
      12,
      darkPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.3),
      10,
      darkPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 0.55),
      8,
      darkPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.9, size.height * 0.65),
      14,
      darkPaint,
    );

    lightPaint.color = primaryLightColor.withValues(alpha: 0.15);
    canvas.drawCircle(
      Offset(size.width * 0.75, size.height * 0.2),
      16,
      lightPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.6),
      12,
      lightPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.75),
      10,
      lightPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
