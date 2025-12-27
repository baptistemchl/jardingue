import 'package:flutter_riverpod/flutter_riverpod.dart';
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
final selectedLocationProvider = StateProvider<LocationResult?>((ref) => null);

/// Provider pour la localisation effective (sélectionnée ou détectée)
final effectiveLocationProvider = Provider<AsyncValue<LocationResult>>((ref) {
  final selected = ref.watch(selectedLocationProvider);
  if (selected != null) {
    return AsyncValue.data(selected);
  }
  return ref.watch(currentLocationProvider);
});

/// Provider principal pour les données météo
final weatherDataProvider = FutureProvider<WeatherData>((ref) async {
  final locationAsync = ref.watch(effectiveLocationProvider);

  return locationAsync.when(
    data: (location) async {
      final weatherService = ref.watch(weatherServiceProvider);
      return weatherService.getWeather(
        latitude: location.latitude,
        longitude: location.longitude,
        city: location.city,
        country: location.country,
      );
    },
    loading: () => throw Exception('Localisation en cours...'),
    error: (e, _) => throw Exception('Erreur localisation: $e'),
  );
});

/// Provider pour rafraîchir la météo
final weatherRefreshProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    ref.invalidate(weatherDataProvider);
    ref.invalidate(currentLocationProvider);
  };
});

/// Provider pour rechercher une ville
final citySearchProvider = FutureProvider.family<List<LocationResult>, String>((ref, query) async {
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
final hourlyForecastProvider = Provider<AsyncValue<List<HourlyForecast>>>((ref) {
  final weatherAsync = ref.watch(weatherDataProvider);
  return weatherAsync.whenData((data) => data.hourlyForecast);
});

/// Provider pour les prévisions journalières
final dailyForecastProvider = Provider<AsyncValue<List<DailyForecast>>>((ref) {
  final weatherAsync = ref.watch(weatherDataProvider);
  return weatherAsync.whenData((data) => data.dailyForecast);
});

/// Provider pour les données lunaires
final moonDataProvider = Provider<AsyncValue<MoonData>>((ref) {
  final weatherAsync = ref.watch(weatherDataProvider);
  return weatherAsync.whenData((data) => data.moon);
});

/// Provider pour les conseils jardinage
final gardeningAdviceProvider = Provider<AsyncValue<GardeningAdvice>>((ref) {
  final weatherAsync = ref.watch(weatherDataProvider);
  return weatherAsync.whenData((data) => data.gardeningAdvice);
});