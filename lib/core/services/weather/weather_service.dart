import 'package:dio/dio.dart';
import 'weather_models.dart';

/// Service pour récupérer la météo depuis Open-Meteo (gratuit, sans clé API)
class WeatherService {
  final Dio _dio;

  static const String _baseUrl = 'https://api.open-meteo.com/v1';

  WeatherService({Dio? dio}) : _dio = dio ?? Dio();

  /// Récupère toutes les données météo pour une position
  Future<WeatherData> getWeather({
    required double latitude,
    required double longitude,
    String? city,
    String? country,
  }) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/forecast',
        queryParameters: {
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
        },
      );

      final data = response.data as Map<String, dynamic>;

      // Parse current weather
      final currentData = data['current'] as Map<String, dynamic>;
      final current = CurrentWeather(
        temperature: (currentData['temperature_2m'] as num).toDouble(),
        feelsLike: (currentData['apparent_temperature'] as num).toDouble(),
        humidity: (currentData['relative_humidity_2m'] as num).toInt(),
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

      return WeatherData(
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
    } on DioException catch (e) {
      throw WeatherException('Erreur réseau: ${e.message}');
    } catch (e) {
      throw WeatherException('Erreur: $e');
    }
  }
}

class WeatherException implements Exception {
  final String message;
  WeatherException(this.message);

  @override
  String toString() => message;
}
