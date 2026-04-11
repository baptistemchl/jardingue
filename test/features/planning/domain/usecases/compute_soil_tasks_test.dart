import 'package:flutter_test/flutter_test.dart';
import 'package:jardingue/core/services/weather/weather_models.dart';
import 'package:jardingue/features/planning/domain/models/soil_task.dart';
import 'package:jardingue/features/planning/domain/models/task_urgency.dart';
import 'package:jardingue/features/planning/domain/usecases/compute_soil_tasks.dart';

void main() {
  group('ComputeSoilTasks', () {
    test('fumure en octobre sans météo', () {
      final tasks = ComputeSoilTasks.execute(
        month: 10,
      );

      final fertilizing = tasks.where(
        (t) =>
            t.type == SoilTaskType.fertilizing,
      );
      expect(fertilizing, isNotEmpty);
      expect(
        fertilizing.first.urgency,
        TaskUrgency.now,
      );
    });

    test('fumure bloquée si trop froid', () {
      final coldWeather = _buildWeather(
        temperature: 3,
      );

      final tasks = ComputeSoilTasks.execute(
        month: 10,
        weather: coldWeather,
      );

      final fertilizing = tasks.where(
        (t) =>
            t.type == SoilTaskType.fertilizing,
      );
      expect(fertilizing, isNotEmpty);
      expect(
        fertilizing.first.urgency,
        TaskUrgency.blocked,
      );
    });

    test('pas de fumure en mai', () {
      final tasks = ComputeSoilTasks.execute(
        month: 5,
      );

      final fertilizing = tasks.where(
        (t) =>
            t.type == SoilTaskType.fertilizing,
      );
      expect(fertilizing, isEmpty);
    });

    test(
      'retournement en mars sans pluie',
      () {
        final tasks = ComputeSoilTasks.execute(
          month: 3,
        );

        final turning = tasks.where(
          (t) => t.type == SoilTaskType.turning,
        );
        expect(turning, isNotEmpty);
        expect(
          turning.first.urgency,
          TaskUrgency.now,
        );
      },
    );

    test(
      'retournement bloqué si pluie forte',
      () {
        final wetWeather = _buildWeather(
          precipitation: 10,
        );

        final tasks = ComputeSoilTasks.execute(
          month: 3,
          weather: wetWeather,
        );

        final turning = tasks.where(
          (t) => t.type == SoilTaskType.turning,
        );
        expect(turning, isNotEmpty);
        expect(
          turning.first.urgency,
          TaskUrgency.blocked,
        );
      },
    );

    test('amendement en avril', () {
      final tasks = ComputeSoilTasks.execute(
        month: 4,
      );

      final amendment = tasks.where(
        (t) => t.type == SoilTaskType.amendment,
      );
      expect(amendment, isNotEmpty);
    });

    test('paillage en été si chaud', () {
      final hotWeather = _buildWeather(
        temperature: 25,
      );

      final tasks = ComputeSoilTasks.execute(
        month: 7,
        weather: hotWeather,
      );

      final mulching = tasks.where(
        (t) => t.type == SoilTaskType.mulching,
      );
      expect(mulching, isNotEmpty);
    });

    test(
      'pas de paillage en été si frais',
      () {
        final coolWeather = _buildWeather(
          temperature: 12,
        );

        final tasks = ComputeSoilTasks.execute(
          month: 7,
          weather: coolWeather,
        );

        final mulching = tasks.where(
          (t) => t.type == SoilTaskType.mulching,
        );
        expect(mulching, isEmpty);
      },
    );

    test('compostage en mars', () {
      final tasks = ComputeSoilTasks.execute(
        month: 3,
      );

      final composting = tasks.where(
        (t) => t.type == SoilTaskType.composting,
      );
      expect(composting, isNotEmpty);
      expect(
        composting.first.message,
        contains('compost mûr'),
      );
    });

    test('compostage en septembre', () {
      final tasks = ComputeSoilTasks.execute(
        month: 9,
      );

      final composting = tasks.where(
        (t) => t.type == SoilTaskType.composting,
      );
      expect(composting, isNotEmpty);
      expect(
        composting.first.message,
        contains('hiver'),
      );
    });

    test(
      'pas de tâches en décembre sans météo',
      () {
        final tasks = ComputeSoilTasks.execute(
          month: 12,
        );

        // Pas de fumure, pas de retournement,
        // pas d'amendement, pas de paillage,
        // pas de compostage en décembre
        expect(tasks, isEmpty);
      },
    );
  });
}

WeatherData _buildWeather({
  double temperature = 20,
  double precipitation = 0,
}) {
  return WeatherData(
    fetchedAt: DateTime.now(),
    location: LocationData(
      latitude: 48.8,
      longitude: 2.3,
      city: 'Paris',
    ),
    current: CurrentWeather(
      temperature: temperature,
      feelsLike: temperature - 1,
      humidity: 60,
      windSpeed: 5,
      windDirection: 180,
      cloudCover: 30,
      precipitation: precipitation,
      weatherCode: 0,
      isDay: true,
      uvIndex: 5,
      pressure: 1013,
      visibility: 10,
    ),
    hourlyForecast: [],
    dailyForecast: [
      DailyForecast(
        date: DateTime.now(),
        tempMax: temperature + 3,
        tempMin: temperature - 5,
        weatherCode: 0,
        precipitationProbability: 10,
        precipitationSum: precipitation,
        sunrise: DateTime.now(),
        sunset: DateTime.now(),
        uvIndexMax: 5,
      ),
    ],
    moon: MoonData.calculate(DateTime.now()),
    gardeningAdvice: GardeningAdvice(
      mainAdvice: 'Test',
      tips: [],
      goodForWatering: true,
      goodForPlanting: true,
      goodForHarvesting: true,
      frostRisk: false,
    ),
  );
}
