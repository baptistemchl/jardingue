import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/crash_reporting/crash_reporting_service.dart';
import '../services/weather/weather_analysis/garden_analysis.dart';
import '../services/weather/weather_service.dart';
import '../services/weather/weather_models.dart';
import '../services/weather/location_service.dart';

/// Provider pour le service météo
final weatherServiceProvider = Provider<WeatherService>((ref) {
  return WeatherService();
});

/// Provider pour le service de localisation
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

/// Provider pour la localisation actuelle
final currentLocationProvider = FutureProvider<LocationResult>((ref) async {
  final locationService = ref.watch(locationServiceProvider);
  return locationService.getCurrentLocation();
});

/// Provider pour la localisation sélectionnée (peut être modifiée par l'utilisateur)
final selectedLocationProvider =
    NotifierProvider<SelectedLocationNotifier, LocationResult?>(
        SelectedLocationNotifier.new);

class SelectedLocationNotifier extends Notifier<LocationResult?> {
  @override
  LocationResult? build() => null;

  void set(LocationResult? value) => state = value;
}

/// Provider pour la localisation effective (sélectionnée ou détectée)
final effectiveLocationProvider = Provider<AsyncValue<LocationResult>>((ref) {
  final selected = ref.watch(selectedLocationProvider);
  if (selected != null) {
    return AsyncValue.data(selected);
  }
  return ref.watch(currentLocationProvider);
});

/// Provider principal pour les données météo
final weatherDataProvider = FutureProvider<WeatherData>(
  (ref) async {
    // Toutes les `ref.watch` doivent être déclarées synchroniquement
    // (avant tout `await`) sous peine de casser le bookkeeping
    // pause/resume des subscriptions Riverpod 3.x lors d'un changement
    // de TickerMode (navigation, clavier).
    //
    // Si l'utilisateur a choisi une ville, on l'utilise directement
    // sans attendre le GPS (qui peut timeout pendant 15s+) — d'où la
    // capture conditionnelle du futur.
    final selected = ref.watch(selectedLocationProvider);
    final locationFuture = selected != null
        ? Future.value(selected)
        : ref.watch(currentLocationProvider.future);
    final weatherService = ref.watch(weatherServiceProvider);

    final effective = await locationFuture;

    CrashReportingService.log(
      'Météo: chargement pour ${effective.displayName}'
      ' (${effective.source.name})',
    );
    final weather = await weatherService.getWeather(
      latitude: effective.latitude,
      longitude: effective.longitude,
      city: effective.city,
      country: effective.country,
    );
    debugPrint('Météo: ${weather.current.temperature}°C');
    return weather;
  },
  // Désactive l'auto-retry Riverpod 3.x (backoff exponentiel infini).
  // Hors-ligne, l'utilisateur vivait un freeze : chaque retry rejoue
  // un timeout Open-Meteo (~15s) + reporting Crashlytics + rebuild de
  // tous les watchers (smart_weather_card, planning_weather_banner,
  // frost_notification, derived providers...). L'UI fournit déjà des
  // boutons "Réessayer" manuels partout.
  retry: (retryCount, error) => null,
);

/// Provider pour rafraîchir la météo
final weatherRefreshProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    ref.invalidate(weatherDataProvider);
    ref.invalidate(currentLocationProvider);
  };
});

/// Provider pour rechercher une ville
final citySearchProvider = FutureProvider.family<List<LocationResult>, String>((
  ref,
  query,
) async {
  if (query.isEmpty) return [];
  final locationService = ref.watch(locationServiceProvider);
  return locationService.searchCity(query);
});

/// Provider pour la météo actuelle (raccourci)
final currentWeatherProvider = Provider<AsyncValue<CurrentWeather>>((ref) {
  final weatherAsync = ref.watch(weatherDataProvider);
  return weatherAsync.whenData((data) => data.current);
});

/// Provider pour les prévisions horaires
final hourlyForecastProvider =
    Provider<AsyncValue<List<HourlyForecast>>>((ref) {
  final weatherAsync = ref.watch(weatherDataProvider);
  return weatherAsync.whenData((data) => data.hourlyForecast);
});

/// Provider pour les prévisions journalières
final dailyForecastProvider = Provider<AsyncValue<List<DailyForecast>>>((ref) {
  final weatherAsync = ref.watch(weatherDataProvider);
  return weatherAsync.whenData((data) => data.dailyForecast);
});

/// Provider pour l'état lunaire biodynamique du jour.
final lunarDayProvider = Provider<AsyncValue<LunarDay>>((ref) {
  final weatherAsync = ref.watch(weatherDataProvider);
  return weatherAsync.whenData((data) => data.lunar);
});

/// Provider pour l'analyse jardinage complète (cascade lune → météo).
/// Source unique de vérité pour tous les conseils du jour.
final gardenAnalysisProvider = Provider<AsyncValue<GardenAnalysis>>((ref) {
  final weatherAsync = ref.watch(weatherDataProvider);
  return weatherAsync.whenData(GardenAnalysis.fromWeather);
});
