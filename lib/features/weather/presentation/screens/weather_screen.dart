import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final weatherAsync = ref.watch(weatherDataProvider);
    ref.watch(effectiveLocationProvider);

    return Scaffold(
      body: weatherAsync.when(
        data: (weather) => _WeatherContent(weather: weather),
        loading: () => const _WeatherLoading(),
        error: (error, _) => _WeatherError(
          error: error.toString(),
          onRetry: () => ref.invalidate(weatherDataProvider),
        ),
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
    final analysis = _FullGardenAnalysis.fromWeather(weather);

    return Stack(
      children: [
        Positioned.fill(child: WeatherBackground(condition: condition)),
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
  final _FullGardenAnalysis analysis;

  const _GardenVerdictCard({required this.analysis});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusXl,
        border: Border.all(
          color: analysis.globalColor.withValues(alpha: 0.3),
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
                  color: analysis.globalColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    analysis.globalEmoji,
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
                        color: analysis.globalColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      analysis.globalVerdict,
                      style: AppTypography.titleSmall,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: analysis.globalColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  analysis.globalScore,
                  style: AppTypography.labelMedium.copyWith(
                    color: analysis.globalColor,
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
  final _Status status;
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
      case _Status.good:
        color = AppColors.success;
        break;
      case _Status.warning:
        color = AppColors.warning;
        break;
      case _Status.bad:
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
  final _FullGardenAnalysis analysis;
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
                ? _Status.good
                : (current.feelsLike >= 5 ? _Status.warning : _Status.bad),
          ),

          // Température min cette nuit
          if (daily.isNotEmpty)
            _AnalysisRow(
              label: 'Min. cette nuit',
              value: '${daily[0].tempMin.round()}°C',
              ideal: '> 5°C',
              status: daily[0].tempMin >= 5
                  ? _Status.good
                  : (daily[0].tempMin >= 0 ? _Status.warning : _Status.bad),
            ),

          // Vent
          _AnalysisRow(
            label: 'Vent',
            value: current.windSpeedDisplay,
            ideal: '< 20 km/h',
            status: current.windSpeed < 20
                ? _Status.good
                : (current.windSpeed < 35 ? _Status.warning : _Status.bad),
          ),

          // Sol (basé sur précipitations récentes)
          _AnalysisRow(
            label: 'Sol',
            value: current.precipitation > 0
                ? 'Humide'
                : (current.humidity > 70 ? 'Correct' : 'Sec'),
            ideal: 'Humide/frais',
            status: current.precipitation > 5 ? _Status.warning : _Status.good,
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

  _Status _getTempStatus(double temp) {
    if (temp >= 15 && temp <= 25) return _Status.good;
    if (temp >= 10 && temp <= 30) return _Status.warning;
    return _Status.bad;
  }
}

// ============================================
// ANALYSE ARROSAGE
// ============================================

class _WateringAnalysisCard extends StatelessWidget {
  final _FullGardenAnalysis analysis;
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
            status: current.precipitation > 0 ? _Status.good : _Status.warning,
          ),

          // Humidité
          _AnalysisRow(
            label: 'Humidité air',
            value: current.humidityDisplay,
            ideal: '50-70%',
            status: current.humidity >= 50 && current.humidity <= 80
                ? _Status.good
                : (current.humidity < 30 ? _Status.bad : _Status.warning),
          ),

          // Prévisions 6h
          _AnalysisRow(
            label: 'Pluie prévue (6h)',
            value: '${precipNext6h.toStringAsFixed(1)} mm',
            ideal: precipNext6h > 2 ? 'Pas d\'arrosage' : 'Arrosez',
            status: precipNext6h > 2
                ? _Status.good
                : (precipNext6h > 0 ? _Status.warning : _Status.bad),
          ),

          // Prévisions 24h
          _AnalysisRow(
            label: 'Pluie prévue (24h)',
            value: '${precipNext24h.toStringAsFixed(1)} mm',
            ideal: '-',
            status: precipNext24h > 5
                ? _Status.good
                : (precipNext24h > 0 ? _Status.warning : _Status.bad),
          ),

          // Probabilité max
          _AnalysisRow(
            label: 'Probabilité pluie max',
            value: '$maxPrecipProb%',
            ideal: '> 60% = reportez',
            status: maxPrecipProb > 60
                ? _Status.good
                : (maxPrecipProb > 30 ? _Status.warning : _Status.bad),
          ),

          // Température (évaporation)
          _AnalysisRow(
            label: 'Évaporation',
            value: current.temperature > 25
                ? 'Forte'
                : (current.temperature > 15 ? 'Modérée' : 'Faible'),
            ideal: current.temperature > 25 ? 'Arrosez le soir' : '-',
            status: current.temperature > 30 ? _Status.warning : _Status.good,
          ),

          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),

          // Verdict arrosage
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: analysis.wateringStatus == _Status.good
                  ? AppColors.success.withValues(alpha: 0.1)
                  : (analysis.wateringStatus == _Status.warning
                        ? AppColors.warning.withValues(alpha: 0.1)
                        : AppColors.info.withValues(alpha: 0.1)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Text(
                  analysis.wateringStatus == _Status.good
                      ? '✅'
                      : (analysis.wateringStatus == _Status.warning
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
  final _Status status;

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
      case _Status.good:
        statusColor = AppColors.success;
        statusIcon = PhosphorIcons.checkCircle(PhosphorIconsStyle.fill);
        break;
      case _Status.warning:
        statusColor = AppColors.warning;
        statusIcon = PhosphorIcons.warning(PhosphorIconsStyle.fill);
        break;
      case _Status.bad:
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
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🌤️', style: TextStyle(fontSize: 64)),
            SizedBox(height: 16),
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text('Chargement de la météo...'),
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
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.error.withValues(alpha: 0.1),
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
              const Text('😕', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              Text(
                'Impossible de charger la météo',
                style: AppTypography.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: Icon(
                  PhosphorIcons.arrowClockwise(PhosphorIconsStyle.bold),
                ),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================
// ANALYSE COMPLÈTE JARDINAGE
// ============================================

enum _Status { good, warning, bad }

class _FullGardenAnalysis {
  final String globalVerdict;
  final String globalEmoji;
  final Color globalColor;
  final String globalScore;
  final List<String> alerts;

  final _Status plantingStatus;
  final String plantingDetail;
  final List<String> plantingRecommendations;

  final _Status wateringStatus;
  final String wateringDetail;
  final String wateringAdvice;

  final _Status harvestStatus;
  final String harvestDetail;

  _FullGardenAnalysis({
    required this.globalVerdict,
    required this.globalEmoji,
    required this.globalColor,
    required this.globalScore,
    required this.alerts,
    required this.plantingStatus,
    required this.plantingDetail,
    required this.plantingRecommendations,
    required this.wateringStatus,
    required this.wateringDetail,
    required this.wateringAdvice,
    required this.harvestStatus,
    required this.harvestDetail,
  });

  factory _FullGardenAnalysis.fromWeather(WeatherData weather) {
    final current = weather.current;
    final hourly = weather.hourlyForecast;
    final daily = weather.dailyForecast;

    final temp = current.temperature;
    final humidity = current.humidity;
    final precip = current.precipitation;
    final wind = current.windSpeed;
    final uv = current.uvIndex;

    // Prévisions
    double minTemp24h = temp;
    double maxTemp24h = temp;
    double totalPrecip24h = precip;
    int maxPrecipProb = 0;

    for (int i = 0; i < math.min(24, hourly.length); i++) {
      final h = hourly[i];
      if (h.temperature < minTemp24h) minTemp24h = h.temperature;
      if (h.temperature > maxTemp24h) maxTemp24h = h.temperature;
      totalPrecip24h += h.precipitation;
      if (h.precipitationProbability > maxPrecipProb) {
        maxPrecipProb = h.precipitationProbability;
      }
    }

    double minTempTonight = daily.isNotEmpty ? daily[0].tempMin : temp;

    // === ALERTES ===
    List<String> alerts = [];
    if (temp < 0) {
      alerts.add('Gel actif ! Rentrez les plants sensibles immédiatement.');
    } else if (minTempTonight < 0)
      alerts.add(
        'Gel prévu cette nuit (${minTempTonight.round()}°C). Protégez vos plants.',
      );
    else if (minTempTonight < 3)
      alerts.add('Risque de gelée cette nuit. Surveillez les jeunes plants.');
    if (temp > 35) {
      alerts.add(
        'Canicule : évitez toute activité au jardin entre 11h et 17h.',
      );
    }
    if (wind > 50) {
      alerts.add(
        'Vent violent (${wind.round()} km/h). Tuteurez vos plants hauts.',
      );
    }
    if (uv > 8) alerts.add('UV très élevés. Protégez-vous si vous jardinez.');

    // === PLANTATION ===
    _Status plantingStatus;
    String plantingDetail;
    List<String> plantingRecs = [];

    if (temp < 5 || minTempTonight < 0) {
      plantingStatus = _Status.bad;
      plantingDetail = 'Trop froid';
      plantingRecs.add('✗ Ne plantez rien en pleine terre');
      plantingRecs.add('✗ Risque de gel pour les jeunes plants');
      if (temp > 0) plantingRecs.add('• Travaux en serre possibles');
    } else if (temp > 32 || wind > 40) {
      plantingStatus = _Status.bad;
      plantingDetail = temp > 32 ? 'Trop chaud' : 'Trop venteux';
      plantingRecs.add('✗ Stress hydrique pour les plants');
      plantingRecs.add('• Plantez tôt le matin ou le soir');
    } else if (temp < 10 || temp > 28 || wind > 25 || precip > 5) {
      plantingStatus = _Status.warning;
      plantingDetail = 'Conditions moyennes';
      if (temp < 12) {
        plantingRecs.add(
          '• Privilégiez les légumes rustiques (choux, poireaux)',
        );
      }
      if (temp > 26) {
        plantingRecs.add('• Arrosez immédiatement après plantation');
      }
      if (wind > 20) plantingRecs.add('• Protégez du vent avec un voile');
      if (precip > 3) {
        plantingRecs.add('• Sol détrempé : attendez qu\'il ressuie');
      }
    } else {
      plantingStatus = _Status.good;
      plantingDetail = 'Idéal';
      plantingRecs.add('✓ Conditions parfaites pour planter');
      plantingRecs.add('✓ Tomates, courgettes, salades...');
      plantingRecs.add('✓ Le sol est à bonne température');
      if (maxPrecipProb > 50) {
        plantingRecs.add('✓ Pluie prévue = pas besoin d\'arroser après');
      }
    }

    // === ARROSAGE ===
    _Status wateringStatus;
    String wateringDetail;
    String wateringAdvice;

    if (precip > 2 || totalPrecip24h > 5) {
      wateringStatus = _Status.good;
      wateringDetail = 'Pluie suffisante';
      wateringAdvice = 'Pas besoin d\'arroser. La pluie s\'en charge !';
    } else if (maxPrecipProb > 60) {
      wateringStatus = _Status.good;
      wateringDetail = 'Pluie prévue';
      wateringAdvice =
          'Pluie annoncée à $maxPrecipProb%. Reportez l\'arrosage.';
    } else if (temp > 28 && humidity < 50) {
      wateringStatus = _Status.warning;
      wateringDetail = 'Arrosage urgent';
      wateringAdvice =
          'Forte évaporation. Arrosez ce soir en profondeur, jamais en plein soleil.';
    } else if (humidity < 40 && precip == 0) {
      wateringStatus = _Status.warning;
      wateringDetail = 'Sol sec';
      wateringAdvice =
          'Humidité faible. Arrosez le soir pour limiter l\'évaporation.';
    } else {
      wateringStatus = _Status.good;
      wateringDetail = 'Normal';
      wateringAdvice =
          'Arrosage classique si nécessaire. Vérifiez l\'humidité du sol en profondeur.';
    }

    // === RÉCOLTE ===
    _Status harvestStatus;
    String harvestDetail;

    if (precip > 3) {
      harvestStatus = _Status.warning;
      harvestDetail = 'Sol humide';
    } else if (temp > 30) {
      harvestStatus = _Status.warning;
      harvestDetail = 'Récoltez tôt';
    } else if (temp < 5) {
      harvestStatus = _Status.warning;
      harvestDetail = 'Avant le gel';
    } else {
      harvestStatus = _Status.good;
      harvestDetail = 'Bon moment';
    }

    // === VERDICT GLOBAL ===
    String globalVerdict;
    String globalEmoji;
    Color globalColor;
    String globalScore;

    int score = 0;
    if (plantingStatus == _Status.good) {
      score += 2;
    } else if (plantingStatus == _Status.warning)
      score += 1;
    if (wateringStatus == _Status.good) {
      score += 2;
    } else if (wateringStatus == _Status.warning)
      score += 1;
    if (harvestStatus == _Status.good) score += 1;

    if (alerts.isNotEmpty && (temp < 0 || temp > 35)) {
      globalVerdict = 'Conditions critiques';
      globalEmoji = '⛔';
      globalColor = Colors.red;
      globalScore = '1/5';
    } else if (score >= 4 && alerts.isEmpty) {
      globalVerdict = 'Excellentes conditions';
      globalEmoji = '🌟';
      globalColor = Colors.green;
      globalScore = '5/5';
    } else if (score >= 3) {
      globalVerdict = 'Bonnes conditions';
      globalEmoji = '👍';
      globalColor = Colors.green;
      globalScore = '4/5';
    } else if (score >= 2) {
      globalVerdict = 'Conditions acceptables';
      globalEmoji = '👌';
      globalColor = Colors.orange;
      globalScore = '3/5';
    } else {
      globalVerdict = 'Conditions difficiles';
      globalEmoji = '⚠️';
      globalColor = Colors.orange;
      globalScore = '2/5';
    }

    return _FullGardenAnalysis(
      globalVerdict: globalVerdict,
      globalEmoji: globalEmoji,
      globalColor: globalColor,
      globalScore: globalScore,
      alerts: alerts,
      plantingStatus: plantingStatus,
      plantingDetail: plantingDetail,
      plantingRecommendations: plantingRecs,
      wateringStatus: wateringStatus,
      wateringDetail: wateringDetail,
      wateringAdvice: wateringAdvice,
      harvestStatus: harvestStatus,
      harvestDetail: harvestDetail,
    );
  }
}
