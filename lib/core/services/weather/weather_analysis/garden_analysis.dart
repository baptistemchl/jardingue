import 'dart:math' as math;

import '../../../../core/services/weather/weather_models.dart';

enum GardenStatus { good, warning, bad }

enum GardenSeverity { critical, hard, ok, good, great }

class GardenAnalysis {
  final String verdict;
  final String emoji;
  final String scoreLabel;
  final GardenSeverity severity;
  final List<String> alerts;

  final GardenStatus plantingStatus;
  final String plantingDetail;
  final List<String> plantingRecommendations;

  final GardenStatus wateringStatus;
  final String wateringDetail;
  final String wateringAdvice;

  final GardenStatus harvestStatus;
  final String harvestDetail;

  const GardenAnalysis({
    required this.verdict,
    required this.emoji,
    required this.scoreLabel,
    required this.severity,
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

  factory GardenAnalysis.fromWeather(WeatherData weather) {
    return GardenAnalysisCalculator().calculate(weather);
  }
}

class GardenAnalysisCalculator {
  GardenAnalysis calculate(WeatherData weather) {
    final current = weather.current;
    final hourly = weather.hourlyForecast;
    final daily = weather.dailyForecast;

    final temp = current.temperature;
    final humidity = current.humidity;
    final precip = current.precipitation;
    final wind = current.windSpeed;
    final uv = current.uvIndex;

    final minTempTonight = _minTempTonight(daily, temp);
    final forecast = _forecast(hourly, precip);

    final alerts = _buildAlerts(
      temp: temp,
      minTempTonight: minTempTonight,
      wind: wind,
      uv: uv,
    );

    final planting = _buildPlanting(
      temp: temp,
      minTempTonight: minTempTonight,
      wind: wind,
      precip: precip,
      maxPrecipProb: forecast.maxPrecipProb,
    );

    final watering = _buildWatering(
      temp: temp,
      humidity: humidity,
      precip: precip,
      totalPrecip24h: forecast.totalPrecip24h,
      maxPrecipProb: forecast.maxPrecipProb,
    );

    final harvest = _buildHarvest(temp: temp, precip: precip);

    final global = _buildGlobal(
      plantingStatus: planting.status,
      wateringStatus: watering.status,
      harvestStatus: harvest.status,
      alerts: alerts,
      temp: temp,
    );

    return GardenAnalysis(
      verdict: global.verdict,
      emoji: global.emoji,
      scoreLabel: global.scoreLabel,
      severity: global.severity,
      alerts: alerts,
      plantingStatus: planting.status,
      plantingDetail: planting.detail,
      plantingRecommendations: planting.recommendations,
      wateringStatus: watering.status,
      wateringDetail: watering.detail,
      wateringAdvice: watering.advice,
      harvestStatus: harvest.status,
      harvestDetail: harvest.detail,
    );
  }

  double _minTempTonight(List<DailyForecast> daily, double fallback) {
    if (daily.isEmpty) return fallback;
    return daily[0].tempMin;
  }

  _ForecastData _forecast(List<HourlyForecast> hourly, double currentPrecip) {
    double totalPrecip24h = currentPrecip;
    int maxPrecipProb = 0;

    for (var i = 0; i < math.min(24, hourly.length); i++) {
      final h = hourly[i];
      totalPrecip24h += h.precipitation;
      if (h.precipitationProbability > maxPrecipProb) {
        maxPrecipProb = h.precipitationProbability;
      }
    }

    return _ForecastData(
      totalPrecip24h: totalPrecip24h,
      maxPrecipProb: maxPrecipProb,
    );
  }

  List<String> _buildAlerts({
    required double temp,
    required double minTempTonight,
    required double wind,
    required double uv,
  }) {
    final alerts = <String>[];

    if (temp < 0) {
      alerts.add('Gel actif ! Rentrez les plants sensibles immédiatement.');
    } else if (minTempTonight < 0) {
      alerts.add(
        'Gel prévu cette nuit (${minTempTonight.round()}°C). '
        'Protégez vos plants.',
      );
    } else if (minTempTonight < 3) {
      alerts.add('Risque de gelée cette nuit. Surveillez les jeunes plants.');
    }

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

    if (uv > 8) {
      alerts.add('UV très élevés. Protégez-vous si vous jardinez.');
    }

    return alerts;
  }

  _PlantingResult _buildPlanting({
    required double temp,
    required double minTempTonight,
    required double wind,
    required double precip,
    required int maxPrecipProb,
  }) {
    if (temp < 5 || minTempTonight < 0) {
      return _PlantingResult(
        status: GardenStatus.bad,
        detail: 'Trop froid',
        recommendations: [
          '✗ Ne plantez rien en pleine terre',
          '✗ Risque de gel pour les jeunes plants',
          if (temp > 0) '• Travaux en serre possibles',
        ],
      );
    }

    if (temp > 32 || wind > 40) {
      return _PlantingResult(
        status: GardenStatus.bad,
        detail: temp > 32 ? 'Trop chaud' : 'Trop venteux',
        recommendations: [
          '✗ Stress hydrique pour les plants',
          '• Plantez tôt le matin ou le soir',
        ],
      );
    }

    if (temp < 10 || temp > 28 || wind > 25 || precip > 5) {
      final recs = <String>[];
      if (temp < 12) {
        recs.add('• Privilégiez les légumes rustiques (choux, poireaux)');
      }
      if (temp > 26) recs.add('• Arrosez immédiatement après plantation');
      if (wind > 20) recs.add('• Protégez du vent avec un voile');
      if (precip > 3) recs.add('• Sol détrempé : attendez qu\'il ressuie');

      return _PlantingResult(
        status: GardenStatus.warning,
        detail: 'Conditions moyennes',
        recommendations: recs,
      );
    }

    final recs = <String>[
      '✓ Conditions parfaites pour planter',
      '✓ Tomates, courgettes, salades...',
      '✓ Le sol est à bonne température',
      if (maxPrecipProb > 50) '✓ Pluie prévue = pas besoin d\'arroser après',
    ];

    return _PlantingResult(
      status: GardenStatus.good,
      detail: 'Idéal',
      recommendations: recs,
    );
  }

  _WateringResult _buildWatering({
    required double temp,
    required double humidity,
    required double precip,
    required double totalPrecip24h,
    required int maxPrecipProb,
  }) {
    if (precip > 2 || totalPrecip24h > 5) {
      return const _WateringResult(
        status: GardenStatus.good,
        detail: 'Pluie suffisante',
        advice: 'Pas besoin d\'arroser. La pluie s\'en charge !',
      );
    }

    if (maxPrecipProb > 60) {
      return _WateringResult(
        status: GardenStatus.good,
        detail: 'Pluie prévue',
        advice: 'Pluie annoncée à $maxPrecipProb%. Reportez l\'arrosage.',
      );
    }

    if (temp > 28 && humidity < 50) {
      return const _WateringResult(
        status: GardenStatus.warning,
        detail: 'Arrosage urgent',
        advice:
            'Forte évaporation. Arrosez ce soir en profondeur, '
            'jamais en plein soleil.',
      );
    }

    if (humidity < 40 && precip == 0) {
      return const _WateringResult(
        status: GardenStatus.warning,
        detail: 'Sol sec',
        advice: 'Humidité faible. Arrosez le soir pour limiter l\'évaporation.',
      );
    }

    return const _WateringResult(
      status: GardenStatus.good,
      detail: 'Normal',
      advice:
          'Arrosage classique si nécessaire. Vérifiez l\'humidité du sol '
          'en profondeur.',
    );
  }

  _HarvestResult _buildHarvest({required double temp, required double precip}) {
    if (precip > 3) {
      return const _HarvestResult(
        status: GardenStatus.warning,
        detail: 'Sol humide',
      );
    }
    if (temp > 30) {
      return const _HarvestResult(
        status: GardenStatus.warning,
        detail: 'Récoltez tôt',
      );
    }
    if (temp < 5) {
      return const _HarvestResult(
        status: GardenStatus.warning,
        detail: 'Avant le gel',
      );
    }
    return const _HarvestResult(
      status: GardenStatus.good,
      detail: 'Bon moment',
    );
  }

  _GlobalResult _buildGlobal({
    required GardenStatus plantingStatus,
    required GardenStatus wateringStatus,
    required GardenStatus harvestStatus,
    required List<String> alerts,
    required double temp,
  }) {
    var score = 0;
    score += _score2(plantingStatus);
    score += _score2(wateringStatus);
    if (harvestStatus == GardenStatus.good) score += 1;

    if (alerts.isNotEmpty && (temp < 0 || temp > 35)) {
      return const _GlobalResult(
        verdict: 'Conditions critiques',
        emoji: '⛔',
        scoreLabel: '1/5',
        severity: GardenSeverity.critical,
      );
    }

    if (score >= 4 && alerts.isEmpty) {
      return const _GlobalResult(
        verdict: 'Excellentes conditions',
        emoji: '🌟',
        scoreLabel: '5/5',
        severity: GardenSeverity.great,
      );
    }

    if (score >= 3) {
      return const _GlobalResult(
        verdict: 'Bonnes conditions',
        emoji: '👍',
        scoreLabel: '4/5',
        severity: GardenSeverity.good,
      );
    }

    if (score >= 2) {
      return const _GlobalResult(
        verdict: 'Conditions acceptables',
        emoji: '👌',
        scoreLabel: '3/5',
        severity: GardenSeverity.ok,
      );
    }

    return const _GlobalResult(
      verdict: 'Conditions difficiles',
      emoji: '⚠️',
      scoreLabel: '2/5',
      severity: GardenSeverity.hard,
    );
  }

  int _score2(GardenStatus status) {
    return switch (status) {
      GardenStatus.good => 2,
      GardenStatus.warning => 1,
      GardenStatus.bad => 0,
    };
  }
}

class _ForecastData {
  final double totalPrecip24h;
  final int maxPrecipProb;

  const _ForecastData({
    required this.totalPrecip24h,
    required this.maxPrecipProb,
  });
}

class _PlantingResult {
  final GardenStatus status;
  final String detail;
  final List<String> recommendations;

  const _PlantingResult({
    required this.status,
    required this.detail,
    required this.recommendations,
  });
}

class _WateringResult {
  final GardenStatus status;
  final String detail;
  final String advice;

  const _WateringResult({
    required this.status,
    required this.detail,
    required this.advice,
  });
}

class _HarvestResult {
  final GardenStatus status;
  final String detail;

  const _HarvestResult({required this.status, required this.detail});
}

class _GlobalResult {
  final String verdict;
  final String emoji;
  final String scoreLabel;
  final GardenSeverity severity;

  const _GlobalResult({
    required this.verdict,
    required this.emoji,
    required this.scoreLabel,
    required this.severity,
  });
}
