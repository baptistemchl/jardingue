import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/providers/weather_providers.dart';
import '../../../../core/providers/garden_providers.dart';
import '../../../../core/services/weather/weather_models.dart';
import '../../../../core/services/database/app_database.dart';
import '../../../../router/app_router.dart';
import '../../../weather/presentation/widgets/weather_animations.dart';
import '../widgets/garden_card.dart';
import 'garden_create_screen.dart';
import 'garden_editor_screen.dart';

const double kNavBarHeight = 100.0;

class GardenScreen extends ConsumerWidget {
  const GardenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gardensAsync = ref.watch(gardensListProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: AppSpacing.screenPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Mon Potager', style: AppTypography.displayMedium),
                        _CreateButton(
                          onTap: () => _showCreateSheet(context, ref),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Planifiez et organisez votre jardin',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),

            // Carte météo intelligente
            SliverToBoxAdapter(
              child: Padding(
                padding: AppSpacing.horizontalPadding,
                child: const _SmartWeatherCard(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),

            // Liste des potagers
            gardensAsync.when(
              data: (gardens) {
                if (gardens.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: AppSpacing.horizontalPadding,
                      child: _EmptyState(
                        onTap: () => _showCreateSheet(context, ref),
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: AppSpacing.horizontalPadding,
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final garden = gardens[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: GardenCard(
                          garden: garden,
                          onTap: () => _openGarden(context, garden),
                          onEdit: () => _showEditSheet(context, ref, garden),
                          onDelete: () => _confirmDelete(context, ref, garden),
                        ),
                      );
                    }, childCount: gardens.length),
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) =>
                  SliverToBoxAdapter(child: Center(child: Text('Erreur: $e'))),
            ),

            SliverToBoxAdapter(child: SizedBox(height: kNavBarHeight)),
          ],
        ),
      ),
    );
  }

  void _showCreateSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GardenCreateScreen(
        onSaved: () {
          ref.invalidate(gardensListProvider);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showEditSheet(BuildContext context, WidgetRef ref, Garden garden) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GardenCreateScreen(
        garden: garden,
        onSaved: () {
          ref.invalidate(gardensListProvider);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _openGarden(BuildContext context, Garden garden) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GardenEditorScreen(gardenId: garden.id),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Garden garden) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le potager ?'),
        content: Text('Voulez-vous supprimer "${garden.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(gardenNotifierProvider.notifier)
                  .deleteGarden(garden.id);
              ref.invalidate(gardensListProvider);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

class _CreateButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CreateButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: AppSpacing.borderRadiusFull,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIcons.plus(PhosphorIconsStyle.bold),
              size: 16,
              color: Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              'Créer',
              style: AppTypography.labelMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onTap;

  const _EmptyState({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusXxl,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              PhosphorIcons.plant(PhosphorIconsStyle.duotone),
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Aucun potager', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Créez votre premier potager',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton.icon(
            onPressed: onTap,
            icon: Icon(PhosphorIcons.plus(PhosphorIconsStyle.bold)),
            label: const Text('Créer mon potager'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// CARTE MÉTÉO INTELLIGENTE
// ============================================

class _SmartWeatherCard extends ConsumerWidget {
  const _SmartWeatherCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(weatherDataProvider);

    return weatherAsync.when(
      data: (weather) => _WeatherCardContent(
        weather: weather,
        onTap: () => context.go(AppRoutes.weather),
      ),
      loading: () => _buildPlaceholder(),
      error: (_, __) => _buildError(() => ref.invalidate(weatherDataProvider)),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusXxl,
        border: Border.all(color: AppColors.border),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildError(VoidCallback onRetry) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusXxl,
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Réessayer'),
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
    final analysis = _GardenWeatherAnalysis.fromWeather(weather);
    final condition = weather.current.condition;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppSpacing.borderRadiusXxl,
          boxShadow: [
            BoxShadow(
              color: Color(condition.primaryColor).withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: AppSpacing.borderRadiusXxl,
          child: Stack(
            children: [
              // Background animé
              Positioned.fill(child: WeatherBackground(condition: condition)),

              // Contenu
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ligne 1: Température + condition
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

                    // Ligne 2: Verdict principal
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: analysis.verdictColor.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: analysis.verdictColor.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            analysis.verdictEmoji,
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

                    // Ligne 3: Indicateurs détaillés
                    Row(
                      children: [
                        _DetailIndicator(
                          icon: '🌡️',
                          label: analysis.tempAdvice,
                          status: analysis.tempStatus,
                        ),
                        const SizedBox(width: 8),
                        _DetailIndicator(
                          icon: '💧',
                          label: analysis.waterAdvice,
                          status: analysis.waterStatus,
                        ),
                        const SizedBox(width: 8),
                        _DetailIndicator(
                          icon: '🌱',
                          label: analysis.plantAdvice,
                          status: analysis.plantStatus,
                        ),
                      ],
                    ),

                    // Ligne 4: Alerte si nécessaire
                    if (analysis.alert != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Text('⚠️', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                analysis.alert!,
                                style: AppTypography.caption.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Chevron
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    PhosphorIcons.arrowRight(PhosphorIconsStyle.bold),
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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

/// Analyse météo intelligente pour le jardinage
class _GardenWeatherAnalysis {
  final String verdict;
  final String verdictEmoji;
  final Color verdictColor;
  final String tempAdvice;
  final _IndicatorStatus tempStatus;
  final String waterAdvice;
  final _IndicatorStatus waterStatus;
  final String plantAdvice;
  final _IndicatorStatus plantStatus;
  final String? alert;

  _GardenWeatherAnalysis({
    required this.verdict,
    required this.verdictEmoji,
    required this.verdictColor,
    required this.tempAdvice,
    required this.tempStatus,
    required this.waterAdvice,
    required this.waterStatus,
    required this.plantAdvice,
    required this.plantStatus,
    this.alert,
  });

  factory _GardenWeatherAnalysis.fromWeather(WeatherData weather) {
    final current = weather.current;
    final temp = current.temperature;
    final _ = current.feelsLike;
    final humidity = current.humidity;
    final precipitation = current.precipitation;
    final windSpeed = current.windSpeed;
    final uvIndex = current.uvIndex;

    // Prévisions
    final hourly = weather.hourlyForecast;
    final daily = weather.dailyForecast;

    // Analyse température pour les prochaines heures
    double minTempNext12h = temp;
    double maxTempNext12h = temp;
    double totalPrecipNext12h = precipitation;
    int maxPrecipProb = 0;

    for (int i = 0; i < math.min(12, hourly.length); i++) {
      final h = hourly[i];
      if (h.temperature < minTempNext12h) minTempNext12h = h.temperature;
      if (h.temperature > maxTempNext12h) maxTempNext12h = h.temperature;
      totalPrecipNext12h += h.precipitation;
      if (h.precipitationProbability > maxPrecipProb) {
        maxPrecipProb = h.precipitationProbability;
      }
    }

    // Température min ce soir/nuit (risque gel)
    double minTempTonight = temp;
    if (daily.isNotEmpty) {
      minTempTonight = daily[0].tempMin;
    }

    // === ANALYSE TEMPÉRATURE ===
    String tempAdvice;
    _IndicatorStatus tempStatus;

    if (temp < 0) {
      tempAdvice = 'Gel actif';
      tempStatus = _IndicatorStatus.bad;
    } else if (temp < 5) {
      tempAdvice = 'Trop froid';
      tempStatus = _IndicatorStatus.bad;
    } else if (temp < 10) {
      tempAdvice = 'Frais';
      tempStatus = _IndicatorStatus.warning;
    } else if (temp > 35) {
      tempAdvice = 'Canicule';
      tempStatus = _IndicatorStatus.bad;
    } else if (temp > 30) {
      tempAdvice = 'Très chaud';
      tempStatus = _IndicatorStatus.warning;
    } else if (temp >= 15 && temp <= 25) {
      tempAdvice = 'Idéal';
      tempStatus = _IndicatorStatus.good;
    } else {
      tempAdvice = 'Correct';
      tempStatus = _IndicatorStatus.good;
    }

    // === ANALYSE ARROSAGE ===
    String waterAdvice;
    _IndicatorStatus waterStatus;

    if (precipitation > 0) {
      waterAdvice = 'Pluie en cours';
      waterStatus = _IndicatorStatus.good; // Pas besoin d'arroser
    } else if (totalPrecipNext12h > 2) {
      waterAdvice = 'Pluie prévue';
      waterStatus = _IndicatorStatus.good;
    } else if (maxPrecipProb > 60) {
      waterAdvice = 'Pluie probable';
      waterStatus = _IndicatorStatus.good;
    } else if (temp > 30 && humidity < 40) {
      waterAdvice = 'Arrosez ce soir';
      waterStatus = _IndicatorStatus.warning;
    } else if (humidity < 30) {
      waterAdvice = 'Sol sec';
      waterStatus = _IndicatorStatus.warning;
    } else if (humidity > 80) {
      waterAdvice = 'Sol humide';
      waterStatus = _IndicatorStatus.good;
    } else {
      waterAdvice = 'Normal';
      waterStatus = _IndicatorStatus.good;
    }

    // === ANALYSE PLANTATION ===
    String plantAdvice;
    _IndicatorStatus plantStatus;

    if (temp < 5 || minTempTonight < 2) {
      plantAdvice = 'Évitez';
      plantStatus = _IndicatorStatus.bad;
    } else if (windSpeed > 40) {
      plantAdvice = 'Vent fort';
      plantStatus = _IndicatorStatus.bad;
    } else if (windSpeed > 25) {
      plantAdvice = 'Venteux';
      plantStatus = _IndicatorStatus.warning;
    } else if (precipitation > 5) {
      plantAdvice = 'Trop humide';
      plantStatus = _IndicatorStatus.warning;
    } else if (temp > 30) {
      plantAdvice = 'Trop chaud';
      plantStatus = _IndicatorStatus.warning;
    } else if (temp >= 12 &&
        temp <= 25 &&
        windSpeed < 20 &&
        precipitation < 2) {
      plantAdvice = 'Idéal';
      plantStatus = _IndicatorStatus.good;
    } else {
      plantAdvice = 'Possible';
      plantStatus = _IndicatorStatus.good;
    }

    // === VERDICT GLOBAL ===
    String verdict;
    String verdictEmoji;
    Color verdictColor;
    String? alert;

    // Cas critiques
    if (temp < 0) {
      verdict = 'Gel : protégez vos plants !';
      verdictEmoji = '🥶';
      verdictColor = Colors.blue;
      alert = 'Température négative. Rentrez les plants sensibles.';
    } else if (minTempTonight < 0) {
      verdict = 'Gel prévu cette nuit';
      verdictEmoji = '❄️';
      verdictColor = Colors.blue;
      alert = 'Protégez vos plants sensibles au gel avant ce soir.';
    } else if (temp < 5) {
      verdict = 'Trop froid pour jardiner';
      verdictEmoji = '🧊';
      verdictColor = Colors.blue;
    } else if (temp > 35) {
      verdict = 'Canicule : évitez le jardin';
      verdictEmoji = '🔥';
      verdictColor = Colors.red;
      alert = 'Arrosez tôt le matin ou tard le soir uniquement.';
    } else if (windSpeed > 50) {
      verdict = 'Vent violent : restez à l\'abri';
      verdictEmoji = '💨';
      verdictColor = Colors.orange;
    } else if (precipitation > 10) {
      verdict = 'Fortes pluies en cours';
      verdictEmoji = '🌧️';
      verdictColor = Colors.blue;
    }
    // Cas moyens
    else if (temp > 30) {
      verdict = 'Chaleur : jardinez tôt ou tard';
      verdictEmoji = '☀️';
      verdictColor = Colors.orange;
    } else if (temp < 10) {
      verdict = 'Frais : travaux légers possibles';
      verdictEmoji = '🌥️';
      verdictColor = Colors.orange;
    } else if (precipitation > 2) {
      verdict = 'Pluie légère';
      verdictEmoji = '🌦️';
      verdictColor = Colors.blue;
    } else if (maxPrecipProb > 70) {
      verdict = 'Pluie prévue : reportez l\'arrosage';
      verdictEmoji = '🌧️';
      verdictColor = Colors.blue;
    }
    // Cas favorables
    else if (temp >= 15 &&
        temp <= 25 &&
        windSpeed < 15 &&
        precipitation == 0 &&
        uvIndex < 7) {
      verdict = 'Conditions parfaites !';
      verdictEmoji = '🌟';
      verdictColor = Colors.green;
    } else if (temp >= 12 && temp <= 28 && windSpeed < 25) {
      verdict = 'Bon moment pour jardiner';
      verdictEmoji = '👍';
      verdictColor = Colors.green;
    } else {
      verdict = 'Conditions acceptables';
      verdictEmoji = '👌';
      verdictColor = Colors.green;
    }

    return _GardenWeatherAnalysis(
      verdict: verdict,
      verdictEmoji: verdictEmoji,
      verdictColor: verdictColor,
      tempAdvice: tempAdvice,
      tempStatus: tempStatus,
      waterAdvice: waterAdvice,
      waterStatus: waterStatus,
      plantAdvice: plantAdvice,
      plantStatus: plantStatus,
      alert: alert,
    );
  }
}
