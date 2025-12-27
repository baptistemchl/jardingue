/// Modèle météo complet pour le jardinage
class WeatherData {
  final DateTime fetchedAt;
  final LocationData location;
  final CurrentWeather current;
  final List<HourlyForecast> hourlyForecast;
  final List<DailyForecast> dailyForecast;
  final MoonData moon;
  final GardeningAdvice gardeningAdvice;

  WeatherData({
    required this.fetchedAt,
    required this.location,
    required this.current,
    required this.hourlyForecast,
    required this.dailyForecast,
    required this.moon,
    required this.gardeningAdvice,
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
  final int humidity;
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

/// Données lunaires
class MoonData {
  final double phase; // 0-1 (0=nouvelle lune, 0.5=pleine lune)
  final String phaseName;
  final String phaseEmoji;
  final bool isWaxing; // Croissante
  final DateTime? nextFullMoon;
  final DateTime? nextNewMoon;
  final GardeningMoonAdvice moonAdvice;

  MoonData({
    required this.phase,
    required this.phaseName,
    required this.phaseEmoji,
    required this.isWaxing,
    this.nextFullMoon,
    this.nextNewMoon,
    required this.moonAdvice,
  });

  factory MoonData.calculate(DateTime date) {
    // Calcul simplifié de la phase lunaire
    // Basé sur le cycle lunaire moyen de 29.53 jours
    final knownNewMoon = DateTime(2024, 1, 11, 11, 57); // Nouvelle lune connue
    final daysSinceNew = date.difference(knownNewMoon).inHours / 24.0;
    final lunarCycle = 29.53;
    final phase = (daysSinceNew % lunarCycle) / lunarCycle;

    final isWaxing = phase < 0.5;

    String phaseName;
    String phaseEmoji;

    if (phase < 0.03 || phase > 0.97) {
      phaseName = 'Nouvelle Lune';
      phaseEmoji = '🌑';
    } else if (phase < 0.22) {
      phaseName = 'Premier Croissant';
      phaseEmoji = '🌒';
    } else if (phase < 0.28) {
      phaseName = 'Premier Quartier';
      phaseEmoji = '🌓';
    } else if (phase < 0.47) {
      phaseName = 'Lune Gibbeuse Croissante';
      phaseEmoji = '🌔';
    } else if (phase < 0.53) {
      phaseName = 'Pleine Lune';
      phaseEmoji = '🌕';
    } else if (phase < 0.72) {
      phaseName = 'Lune Gibbeuse Décroissante';
      phaseEmoji = '🌖';
    } else if (phase < 0.78) {
      phaseName = 'Dernier Quartier';
      phaseEmoji = '🌗';
    } else {
      phaseName = 'Dernier Croissant';
      phaseEmoji = '🌘';
    }

    // Calcul prochaines phases
    final daysToFullMoon = ((0.5 - phase) * lunarCycle) % lunarCycle;
    final daysToNewMoon = ((1.0 - phase) * lunarCycle) % lunarCycle;

    return MoonData(
      phase: phase,
      phaseName: phaseName,
      phaseEmoji: phaseEmoji,
      isWaxing: isWaxing,
      nextFullMoon: date.add(Duration(days: daysToFullMoon.round())),
      nextNewMoon: date.add(Duration(days: daysToNewMoon.round())),
      moonAdvice: GardeningMoonAdvice.fromPhase(phase),
    );
  }
}

/// Conseils jardinage selon la lune
class GardeningMoonAdvice {
  final String title;
  final String description;
  final List<String> goodFor;
  final List<String> avoid;
  final int score; // 1-5 étoiles pour le jardinage

  GardeningMoonAdvice({
    required this.title,
    required this.description,
    required this.goodFor,
    required this.avoid,
    required this.score,
  });

  factory GardeningMoonAdvice.fromPhase(double phase) {
    if (phase < 0.03 || phase > 0.97) {
      // Nouvelle lune
      return GardeningMoonAdvice(
        title: 'Repos du jardin',
        description: 'Période de repos, évitez les semis et plantations.',
        goodFor: ['Désherbage', 'Taille des haies', 'Repos'],
        avoid: ['Semis', 'Plantations', 'Récolte'],
        score: 2,
      );
    } else if (phase < 0.25) {
      // Lune croissante (1er quartier)
      return GardeningMoonAdvice(
        title: 'Semis des légumes feuilles',
        description: 'Idéal pour les légumes dont on consomme les feuilles.',
        goodFor: [
          'Semis salades',
          'Semis épinards',
          'Semis choux',
          'Tonte pelouse',
        ],
        avoid: ['Taille', 'Récolte racines'],
        score: 4,
      );
    } else if (phase < 0.5) {
      // Lune croissante (2ème quartier)
      return GardeningMoonAdvice(
        title: 'Semis des légumes fruits',
        description: 'Période favorable aux légumes fruits et graines.',
        goodFor: [
          'Semis tomates',
          'Semis courgettes',
          'Greffes',
          'Récolte fruits',
        ],
        avoid: ['Taille sévère'],
        score: 5,
      );
    } else if (phase < 0.53) {
      // Pleine lune
      return GardeningMoonAdvice(
        title: 'Pleine vitalité',
        description: 'Maximum de vitalité, idéal pour les récoltes.',
        goodFor: ['Récolte', 'Cueillette herbes', 'Traitement naturels'],
        avoid: ['Taille', 'Semis'],
        score: 4,
      );
    } else if (phase < 0.75) {
      // Lune décroissante (3ème quartier)
      return GardeningMoonAdvice(
        title: 'Travail des racines',
        description: 'Favorable aux légumes racines et au travail du sol.',
        goodFor: [
          'Semis carottes',
          'Plantation bulbes',
          'Travail du sol',
          'Compost',
        ],
        avoid: ['Semis légumes feuilles'],
        score: 4,
      );
    } else {
      // Lune décroissante (4ème quartier)
      return GardeningMoonAdvice(
        title: 'Taille et nettoyage',
        description: 'Bon moment pour tailler et nettoyer le jardin.',
        goodFor: ['Taille arbres', 'Désherbage', 'Élimination nuisibles'],
        avoid: ['Semis', 'Plantations'],
        score: 3,
      );
    }
  }
}

/// Conseils jardinage selon la météo
class GardeningAdvice {
  final String mainAdvice;
  final List<String> tips;
  final bool goodForWatering;
  final bool goodForPlanting;
  final bool goodForHarvesting;
  final bool frostRisk;

  GardeningAdvice({
    required this.mainAdvice,
    required this.tips,
    required this.goodForWatering,
    required this.goodForPlanting,
    required this.goodForHarvesting,
    required this.frostRisk,
  });

  factory GardeningAdvice.fromWeather(
    CurrentWeather current,
    List<DailyForecast> forecast,
  ) {
    final tips = <String>[];
    var mainAdvice = '';
    var goodForWatering = true;
    var goodForPlanting = true;
    var goodForHarvesting = true;
    var frostRisk = false;

    // Analyse température
    if (current.temperature < 5) {
      frostRisk = true;
      goodForPlanting = false;
      tips.add('⚠️ Risque de gel, protégez vos plants sensibles');
      mainAdvice = 'Attention au gel cette nuit';
    } else if (current.temperature > 30) {
      tips.add('🌡️ Arrosez tôt le matin ou tard le soir');
      tips.add('💧 Paillez pour garder l\'humidité');
      mainAdvice = 'Forte chaleur, hydratez bien vos plants';
    }

    // Analyse précipitations
    if (current.precipitation > 0) {
      goodForWatering = false;
      tips.add('☔ Pas besoin d\'arroser aujourd\'hui');
      if (mainAdvice.isEmpty) mainAdvice = 'La pluie s\'occupe de l\'arrosage';
    } else if (current.humidity < 40) {
      tips.add('💧 Pensez à arroser ce soir');
    }

    // Analyse vent
    if (current.windSpeed > 30) {
      goodForPlanting = false;
      tips.add('💨 Vent fort, évitez les semis');
    }

    // Analyse UV
    if (current.uvIndex > 6) {
      tips.add('☀️ UV élevés, évitez de jardiner entre 12h et 16h');
    }

    // Prévisions pluie
    final rainTomorrow =
        forecast.isNotEmpty && forecast[0].precipitationProbability > 60;
    if (rainTomorrow && current.precipitation == 0) {
      tips.add('🌧️ Pluie prévue demain, reportez l\'arrosage');
      goodForWatering = false;
    }

    // Conseil par défaut
    if (mainAdvice.isEmpty) {
      if (current.condition.isGood) {
        mainAdvice = 'Beau temps pour jardiner !';
        tips.add('🌱 Conditions idéales pour le jardinage');
      } else {
        mainAdvice = 'Météo variable, restez vigilant';
      }
    }

    // Récolte
    if (current.precipitation > 0 || current.humidity > 80) {
      goodForHarvesting = false;
      tips.add('🥬 Évitez de récolter par temps humide');
    }

    return GardeningAdvice(
      mainAdvice: mainAdvice,
      tips: tips,
      goodForWatering: goodForWatering,
      goodForPlanting: goodForPlanting,
      goodForHarvesting: goodForHarvesting,
      frostRisk: frostRisk,
    );
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
