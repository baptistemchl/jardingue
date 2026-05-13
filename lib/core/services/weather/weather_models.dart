import '../lunar/lunar_calendar.dart';

export '../lunar/lunar_calendar.dart' show
    LunarDay,
    LunarDayType,
    LunarPhase,
    LunarAbstainEvent,
    ZodiacConstellation;

/// Modèle météo complet pour le jardinage.
///
/// Le calendrier lunaire biodynamique ([lunar]) est la **source unique** des
/// recommandations sur quoi semer / repiquer / récolter aujourd'hui. La météo
/// (temperature, vent, pluie) intervient en cascade par-dessus uniquement
/// pour bloquer les activités impossibles (gel, canicule, sol détrempé...).
class WeatherData {
  final DateTime fetchedAt;
  final LocationData location;
  final CurrentWeather current;
  final List<HourlyForecast> hourlyForecast;
  final List<DailyForecast> dailyForecast;

  /// État lunaire biodynamique complet pour la journée affichée.
  final LunarDay lunar;

  WeatherData({
    required this.fetchedAt,
    required this.location,
    required this.current,
    required this.hourlyForecast,
    required this.dailyForecast,
    required this.lunar,
  });
}

/// Données de localisation
class LocationData {
  final double latitude;
  final double longitude;
  final String? city;
  final String? country;

  LocationData({
    required this.latitude,
    required this.longitude,
    this.city,
    this.country,
  });

  String get displayName => city ?? '$latitude, $longitude';
}

/// Météo actuelle
class CurrentWeather {
  final double temperature;
  final double feelsLike;
  final double humidity;
  final double windSpeed;
  final int windDirection;
  final int cloudCover;
  final double precipitation;
  final int weatherCode;
  final bool isDay;
  final double uvIndex;
  final double pressure;
  final double visibility;

  CurrentWeather({
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.windDirection,
    required this.cloudCover,
    required this.precipitation,
    required this.weatherCode,
    required this.isDay,
    required this.uvIndex,
    required this.pressure,
    required this.visibility,
  });

  WeatherCondition get condition =>
      WeatherCondition.fromCode(weatherCode, isDay);

  String get temperatureDisplay => '${temperature.round()}°C';

  String get feelsLikeDisplay => '${feelsLike.round()}°C';

  String get humidityDisplay => '$humidity%';

  String get windSpeedDisplay => '${windSpeed.round()} km/h';

  String get windDirectionDisplay => _getWindDirection(windDirection);

  String _getWindDirection(int degrees) {
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SO', 'O', 'NO'];
    final index = ((degrees + 22.5) / 45).floor() % 8;
    return directions[index];
  }
}

/// Prévision horaire
class HourlyForecast {
  final DateTime time;
  final double temperature;
  final int weatherCode;
  final int precipitationProbability;
  final double precipitation;
  final bool isDay;

  HourlyForecast({
    required this.time,
    required this.temperature,
    required this.weatherCode,
    required this.precipitationProbability,
    required this.precipitation,
    required this.isDay,
  });

  WeatherCondition get condition =>
      WeatherCondition.fromCode(weatherCode, isDay);

  String get temperatureDisplay => '${temperature.round()}°';

  String get hourDisplay {
    final hour = time.hour;
    return '${hour}h';
  }
}

/// Prévision journalière
class DailyForecast {
  final DateTime date;
  final double tempMax;
  final double tempMin;
  final int weatherCode;
  final int precipitationProbability;
  final double precipitationSum;
  final DateTime sunrise;
  final DateTime sunset;
  final double uvIndexMax;

  DailyForecast({
    required this.date,
    required this.tempMax,
    required this.tempMin,
    required this.weatherCode,
    required this.precipitationProbability,
    required this.precipitationSum,
    required this.sunrise,
    required this.sunset,
    required this.uvIndexMax,
  });

  WeatherCondition get condition =>
      WeatherCondition.fromCode(weatherCode, true);

  String get tempMaxDisplay => '${tempMax.round()}°';

  String get tempMinDisplay => '${tempMin.round()}°';

  String get dayName {
    final now = DateTime.now();
    if (date.day == now.day && date.month == now.month) return "Aujourd'hui";
    if (date.day == now.day + 1 && date.month == now.month) return 'Demain';

    const days = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche',
    ];
    return days[date.weekday - 1];
  }
}

/// Condition météo avec icône et couleurs
class WeatherCondition {
  final int code;
  final String label;
  final String icon;
  final String animation; // Type d'animation à jouer
  final int primaryColor;
  final int secondaryColor;
  final bool isGood; // Bon pour le jardinage

  const WeatherCondition({
    required this.code,
    required this.label,
    required this.icon,
    required this.animation,
    required this.primaryColor,
    required this.secondaryColor,
    required this.isGood,
  });

  factory WeatherCondition.fromCode(int code, bool isDay) {
    // Codes WMO utilisés par Open-Meteo
    // https://open-meteo.com/en/docs
    switch (code) {
      case 0: // Clear sky
        return WeatherCondition(
          code: code,
          label: isDay ? 'Ensoleillé' : 'Nuit claire',
          icon: isDay ? '☀️' : '🌙',
          animation: isDay ? 'sunny' : 'clear_night',
          primaryColor: isDay ? 0xFFF4A261 : 0xFF1a237e,
          secondaryColor: isDay ? 0xFFFFE4B5 : 0xFF303f9f,
          isGood: true,
        );
      case 1: // Mainly clear
        return WeatherCondition(
          code: code,
          label: 'Peu nuageux',
          icon: isDay ? '🌤️' : '🌙',
          animation: isDay ? 'partly_cloudy' : 'clear_night',
          primaryColor: 0xFF87CEEB,
          secondaryColor: 0xFFB0E0E6,
          isGood: true,
        );
      case 2: // Partly cloudy
        return WeatherCondition(
          code: code,
          label: 'Partiellement nuageux',
          icon: '⛅',
          animation: 'partly_cloudy',
          primaryColor: 0xFF87CEEB,
          secondaryColor: 0xFFB8B8B8,
          isGood: true,
        );
      case 3: // Overcast
        return WeatherCondition(
          code: code,
          label: 'Couvert',
          icon: '☁️',
          animation: 'cloudy',
          primaryColor: 0xFF808080,
          secondaryColor: 0xFFB8B8B8,
          isGood: true,
        );
      case 45:
      case 48: // Fog
        return const WeatherCondition(
          code: 45,
          label: 'Brouillard',
          icon: '🌫️',
          animation: 'fog',
          primaryColor: 0xFFC0C0C0,
          secondaryColor: 0xFFE8E8E8,
          isGood: false,
        );
      case 51:
      case 53:
      case 55: // Drizzle
        return const WeatherCondition(
          code: 51,
          label: 'Bruine',
          icon: '🌧️',
          animation: 'drizzle',
          primaryColor: 0xFF6B8E9F,
          secondaryColor: 0xFF9FC5D8,
          isGood: false,
        );
      case 61:
      case 63:
      case 65: // Rain
        return WeatherCondition(
          code: code,
          label: code == 65 ? 'Forte pluie' : 'Pluie',
          icon: '🌧️',
          animation: code == 65 ? 'heavy_rain' : 'rain',
          primaryColor: 0xFF4A6FA5,
          secondaryColor: 0xFF7B9ECF,
          isGood: false,
        );
      case 66:
      case 67: // Freezing rain
        return const WeatherCondition(
          code: 66,
          label: 'Pluie verglaçante',
          icon: '🌨️',
          animation: 'freezing_rain',
          primaryColor: 0xFF6B8E9F,
          secondaryColor: 0xFFCCE5FF,
          isGood: false,
        );
      case 71:
      case 73:
      case 75:
      case 77: // Snow
        return const WeatherCondition(
          code: 71,
          label: 'Neige',
          icon: '❄️',
          animation: 'snow',
          primaryColor: 0xFFE8F4F8,
          secondaryColor: 0xFFFFFFFF,
          isGood: false,
        );
      case 80:
      case 81:
      case 82: // Rain showers
        return WeatherCondition(
          code: code,
          label: 'Averses',
          icon: '🌦️',
          animation: code == 82 ? 'heavy_rain' : 'rain',
          primaryColor: 0xFF5B9BD5,
          secondaryColor: 0xFF9DC3E6,
          isGood: false,
        );
      case 85:
      case 86: // Snow showers
        return const WeatherCondition(
          code: 85,
          label: 'Averses de neige',
          icon: '🌨️',
          animation: 'snow',
          primaryColor: 0xFFE8F4F8,
          secondaryColor: 0xFFFFFFFF,
          isGood: false,
        );
      case 95:
      case 96:
      case 99: // Thunderstorm
        return const WeatherCondition(
          code: 95,
          label: 'Orage',
          icon: '⛈️',
          animation: 'thunderstorm',
          primaryColor: 0xFF4A4A6A,
          secondaryColor: 0xFF7B7B9F,
          isGood: false,
        );
      default:
        return const WeatherCondition(
          code: -1,
          label: 'Inconnu',
          icon: '❓',
          animation: 'cloudy',
          primaryColor: 0xFF808080,
          secondaryColor: 0xFFB8B8B8,
          isGood: true,
        );
    }
  }
}

/// Re-export pour compatibilité historique : alias dépréciés.
/// Les nouvelles classes vivent dans `lunar_calendar.dart`.
@Deprecated('Utilisez LunarDay (export depuis lunar_calendar.dart)')
typedef MoonData = LunarDay;
