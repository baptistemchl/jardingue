import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jardingue/core/constants/app_colors.dart';
import 'package:jardingue/core/constants/app_spacing.dart';
import 'package:jardingue/core/providers/weather_providers.dart';
import 'package:jardingue/core/services/weather/weather_models.dart';
import 'package:jardingue/core/theme/app_typography.dart';
import 'package:jardingue/features/weather/presentation/widgets/weather_animations.dart';
import 'package:jardingue/features/weather/presentation/widgets/weather_cards.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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

    return Stack(
      children: [
        // Background animé
        Positioned.fill(child: WeatherBackground(condition: condition)),

        // Contenu scrollable
        SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              // Header avec localisation
              SliverToBoxAdapter(child: _Header(weather: weather)),

              // Météo principale
              SliverToBoxAdapter(
                child: Padding(
                  padding: AppSpacing.horizontalPadding,
                  child: MainWeatherCard(weather: weather),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // Conseils jardinage
              SliverToBoxAdapter(
                child: Padding(
                  padding: AppSpacing.horizontalPadding,
                  child: GardeningAdviceCard(advice: weather.gardeningAdvice),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // Phase de lune
              SliverToBoxAdapter(
                child: Padding(
                  padding: AppSpacing.horizontalPadding,
                  child: MoonPhaseCard(moon: weather.moon),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // Prévisions horaires
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: AppSpacing.horizontalPadding,
                      child: Text(
                        'Prochaines heures',
                        style: AppTypography.titleMedium,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 150,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: AppSpacing.horizontalPadding,
                        itemCount: weather.hourlyForecast.length.clamp(0, 12),
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          return HourlyForecastCard(
                            forecast: weather.hourlyForecast[index],
                            isNow: index == 0,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // Prévisions 7 jours
              SliverToBoxAdapter(
                child: Padding(
                  padding: AppSpacing.horizontalPadding,
                  child: Text(
                    'Prévisions 7 jours',
                    style: AppTypography.titleMedium,
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
                      child: DailyForecastCard(
                        forecast: weather.dailyForecast[index],
                      ),
                    ),
                    childCount: weather.dailyForecast.length,
                  ),
                ),
              ),

              // Espace bottom nav
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
      ],
    );
  }
}

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
              // Bouton refresh
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
          // Date du jour
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
      builder: (context) => const _LocationPickerSheet(),
    );
  }
}

class _LocationPickerSheet extends ConsumerStatefulWidget {
  const _LocationPickerSheet();

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
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
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
