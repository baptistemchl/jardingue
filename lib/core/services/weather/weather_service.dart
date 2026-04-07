import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'weather_models.dart';

/// Service pour récupérer la météo depuis Open-Meteo (gratuit, sans clé API)
class WeatherService {
  final Dio _dio;

  static const String _baseUrl = 'https://api.open-meteo.com/v1';

  /// Cache en mémoire pour éviter le rate-limiting
  static WeatherData? _cache;
  static DateTime? _cacheTime;
  static double? _cacheLat;
  static double? _cacheLon;
  static const _cacheDuration = Duration(minutes: 15);

  WeatherService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 30),
            ));

  /// Récupère toutes les données météo pour une position
  Future<WeatherData> getWeather({
    required double latitude,
    required double longitude,
    String? city,
    String? country,
  }) async {
    // Retourne le cache s'il est encore frais ET même position
    final sameLocation = _cacheLat == latitude && _cacheLon == longitude;
    if (_cache != null && _cacheTime != null && sameLocation) {
      final age = DateTime.now().difference(_cacheTime!);
      if (age < _cacheDuration) {
        debugPrint('⛈️ Météo servie depuis le cache (${age.inMinutes}min)');
        return _cache!;
      }
    }

    try {
      final queryParams = {
          'latitude': latitude,
          'longitude': longitude,
          'current': [
            'temperature_2m',
            'relative_humidity_2m',
            'apparent_temperature',
            'is_day',
            'precipitation',
            'weather_code',
            'cloud_cover',
            'pressure_msl',
            'wind_speed_10m',
            'wind_direction_10m',
            'uv_index',
          ].join(','),
          'hourly': [
            'temperature_2m',
            'precipitation_probability',
            'precipitation',
            'weather_code',
            'is_day',
          ].join(','),
          'daily': [
            'weather_code',
            'temperature_2m_max',
            'temperature_2m_min',
            'precipitation_sum',
            'precipitation_probability_max',
            'sunrise',
            'sunset',
            'uv_index_max',
          ].join(','),
          'timezone': 'auto',
          'forecast_days': 7,
        };
      final response = await _dio.get(
        '$_baseUrl/forecast',
        queryParameters: queryParams,
      );

      final data = response.data as Map<String, dynamic>;

      // Parse current weather
      final currentData = data['current'] as Map<String, dynamic>;
      final current = CurrentWeather(
        temperature: (currentData['temperature_2m'] as num).toDouble(),
        feelsLike: (currentData['apparent_temperature'] as num).toDouble(),
        humidity: (currentData['relative_humidity_2m'] as num).toDouble(),
        windSpeed: (currentData['wind_speed_10m'] as num).toDouble(),
        windDirection: (currentData['wind_direction_10m'] as num).toInt(),
        cloudCover: (currentData['cloud_cover'] as num).toInt(),
        precipitation: (currentData['precipitation'] as num).toDouble(),
        weatherCode: (currentData['weather_code'] as num).toInt(),
        isDay: currentData['is_day'] == 1,
        uvIndex: (currentData['uv_index'] as num?)?.toDouble() ?? 0,
        pressure: (currentData['pressure_msl'] as num?)?.toDouble() ?? 1013,
        visibility: 10, // Non fourni par Open-Meteo basique
      );

      // Parse hourly forecast (prochaines 24h)
      final hourlyData = data['hourly'] as Map<String, dynamic>;
      final hourlyTimes = (hourlyData['time'] as List).cast<String>();
      final hourlyTemps = (hourlyData['temperature_2m'] as List);
      final hourlyPrecipProb =
          (hourlyData['precipitation_probability'] as List);
      final hourlyPrecip = (hourlyData['precipitation'] as List);
      final hourlyCodes = (hourlyData['weather_code'] as List);
      final hourlyIsDay = (hourlyData['is_day'] as List);

      final now = DateTime.now();
      final hourlyForecast = <HourlyForecast>[];

      for (
        var i = 0;
        i < hourlyTimes.length && hourlyForecast.length < 24;
        i++
      ) {
        final time = DateTime.parse(hourlyTimes[i]);
        if (time.isAfter(now.subtract(const Duration(hours: 1)))) {
          hourlyForecast.add(
            HourlyForecast(
              time: time,
              temperature: (hourlyTemps[i] as num).toDouble(),
              weatherCode: (hourlyCodes[i] as num).toInt(),
              precipitationProbability:
                  (hourlyPrecipProb[i] as num?)?.toInt() ?? 0,
              precipitation: (hourlyPrecip[i] as num?)?.toDouble() ?? 0,
              isDay: hourlyIsDay[i] == 1,
            ),
          );
        }
      }

      // Parse daily forecast
      final dailyData = data['daily'] as Map<String, dynamic>;
      final dailyTimes = (dailyData['time'] as List).cast<String>();
      final dailyTempMax = (dailyData['temperature_2m_max'] as List);
      final dailyTempMin = (dailyData['temperature_2m_min'] as List);
      final dailyCodes = (dailyData['weather_code'] as List);
      final dailyPrecipProb =
          (dailyData['precipitation_probability_max'] as List);
      final dailyPrecipSum = (dailyData['precipitation_sum'] as List);
      final dailySunrise = (dailyData['sunrise'] as List).cast<String>();
      final dailySunset = (dailyData['sunset'] as List).cast<String>();
      final dailyUvMax = (dailyData['uv_index_max'] as List);

      final dailyForecast = <DailyForecast>[];
      for (var i = 0; i < dailyTimes.length; i++) {
        dailyForecast.add(
          DailyForecast(
            date: DateTime.parse(dailyTimes[i]),
            tempMax: (dailyTempMax[i] as num).toDouble(),
            tempMin: (dailyTempMin[i] as num).toDouble(),
            weatherCode: (dailyCodes[i] as num).toInt(),
            precipitationProbability:
                (dailyPrecipProb[i] as num?)?.toInt() ?? 0,
            precipitationSum: (dailyPrecipSum[i] as num?)?.toDouble() ?? 0,
            sunrise: DateTime.parse(dailySunrise[i]),
            sunset: DateTime.parse(dailySunset[i]),
            uvIndexMax: (dailyUvMax[i] as num?)?.toDouble() ?? 0,
          ),
        );
      }

      // Calculate moon data
      final moon = MoonData.calculate(now);

      // Generate gardening advice
      final gardeningAdvice = GardeningAdvice.fromWeather(
        current,
        dailyForecast,
      );

      final result = WeatherData(
        fetchedAt: now,
        location: LocationData(
          latitude: latitude,
          longitude: longitude,
          city: city,
          country: country,
        ),
        current: current,
        hourlyForecast: hourlyForecast,
        dailyForecast: dailyForecast,
        moon: moon,
        gardeningAdvice: gardeningAdvice,
      );

      // Mettre en cache
      _cache = result;
      _cacheTime = now;
      _cacheLat = latitude;
      _cacheLon = longitude;

      return result;
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      debugPrint('⛈️ WeatherService DioException: $code – ${e.type}');

      // Retourne le cache périmé si disponible
      if (_cache != null) {
        debugPrint('⛈️ Erreur réseau, retour du cache périmé');
        return _cache!;
      }

      if (code == 429) {
        throw WeatherException(
          'Trop de requêtes météo. Réessayez dans quelques minutes.',
        );
      }
      throw WeatherException(
        'Le service météo est temporairement '
        'indisponible (${code ?? e.type.name}).',
      );
    } catch (e) {
      debugPrint('⛈️ WeatherService erreur inattendue: $e');
      if (_cache != null) {
        return _cache!;
      }
      throw WeatherException(
        'Le service météo a rencontré un problème.',
      );
    }
  }

}

class WeatherException implements Exception {
  final String message;
  WeatherException(this.message);

  @override
  String toString() => message;
}
