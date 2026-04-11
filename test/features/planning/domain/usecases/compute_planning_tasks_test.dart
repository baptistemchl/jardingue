import 'package:flutter_test/flutter_test.dart';
import 'package:jardingue/core/services/weather/weather_models.dart';
import 'package:jardingue/features/planning/domain/models/planning_action_type.dart';
import 'package:jardingue/features/planning/domain/models/task_urgency.dart';
import 'package:jardingue/features/planning/domain/usecases/compute_planning_tasks.dart';

void main() {
  final tomatoPlant = PlantData(
    id: 1,
    commonName: 'Tomate',
    emoji: '🍅',
    sowingCalendar: '{"monthly_period":'
        '{"January":"Non",'
        '"February":"Non",'
        '"March":"Oui (sous abri)",'
        '"April":"Oui (pleine terre)",'
        '"May":"Oui (pleine terre)"}}',
    plantingCalendar: '{"monthly_period":'
        '{"April":"Non",'
        '"May":"Oui (après saints de glace)",'
        '"June":"Oui"}}',
    harvestCalendar: '{"monthly_period":'
        '{"July":"Oui",'
        '"August":"Oui",'
        '"September":"Oui"}}',
    plantingMinTempC: 15,
  );

  final carrotPlant = PlantData(
    id: 2,
    commonName: 'Carotte',
    emoji: '🥕',
    sowingCalendar: '{"monthly_period":'
        '{"March":"Oui (pleine terre)",'
        '"April":"Oui (pleine terre)",'
        '"May":"Oui (pleine terre)"}}',
    plantingCalendar: null,
    harvestCalendar: '{"monthly_period":'
        '{"June":"Oui",'
        '"July":"Oui"}}',
    plantingMinTempC: 8,
  );

  group('ComputePlanningTasks', () {
    test(
      'retourne semis sous abri en mars '
      'sans météo',
      () {
        final tasks =
            ComputePlanningTasks.execute(
          plants: [tomatoPlant],
          month: 3,
        );

        expect(tasks, isNotEmpty);
        final sowing = tasks.where(
          (t) =>
              t.actionType ==
              PlanningActionType.sowingUnderCover,
        );
        expect(sowing, isNotEmpty);
        expect(
          sowing.first.urgency,
          TaskUrgency.upcoming,
        );
        expect(
          sowing.first.plantName,
          'Tomate',
        );
      },
    );

    test(
      'retourne semis pleine terre en avril '
      'sans météo',
      () {
        final tasks =
            ComputePlanningTasks.execute(
          plants: [tomatoPlant],
          month: 4,
        );

        final sowing = tasks.where(
          (t) =>
              t.actionType ==
              PlanningActionType.sowingOpenGround,
        );
        expect(sowing, isNotEmpty);
      },
    );

    test(
      'bloque semis pleine terre '
      'si temp < minTemp',
      () {
        final coldWeather = _buildWeather(
          temperature: 10,
          minTonight: 5,
        );

        final tasks =
            ComputePlanningTasks.execute(
          plants: [tomatoPlant],
          month: 4,
          weather: coldWeather,
        );

        final sowingTasks = tasks.where(
          (t) =>
              t.actionType ==
              PlanningActionType.sowingOpenGround,
        );

        expect(sowingTasks, isNotEmpty);
        expect(
          sowingTasks.first.blockedByWeather,
          isTrue,
        );
        expect(
          sowingTasks.first.urgency,
          TaskUrgency.blocked,
        );
      },
    );

    test(
      'bloque si gel prévu cette nuit',
      () {
        final frostWeather = _buildWeather(
          temperature: 18,
          minTonight: -2,
        );

        final tasks =
            ComputePlanningTasks.execute(
          plants: [tomatoPlant],
          month: 5,
          weather: frostWeather,
        );

        final planting = tasks.where(
          (t) =>
              t.actionType ==
              PlanningActionType.planting,
        );

        expect(planting, isNotEmpty);
        expect(
          planting.first.blockedByWeather,
          isTrue,
        );
        expect(
          planting.first.weatherReason,
          contains('gel'),
        );
      },
    );

    test(
      'urgence "now" si conditions idéales',
      () {
        final goodWeather = _buildWeather(
          temperature: 22,
          minTonight: 14,
        );

        final tasks =
            ComputePlanningTasks.execute(
          plants: [tomatoPlant],
          month: 5,
          weather: goodWeather,
        );

        final plantingTasks = tasks.where(
          (t) =>
              t.actionType ==
              PlanningActionType.planting,
        );

        expect(plantingTasks, isNotEmpty);
        expect(
          plantingTasks.first.urgency,
          TaskUrgency.now,
        );
      },
    );

    test(
      'aucune tâche en janvier pour la tomate',
      () {
        final tasks =
            ComputePlanningTasks.execute(
          plants: [tomatoPlant],
          month: 1,
        );

        expect(tasks, isEmpty);
      },
    );

    test('liste vide si aucun plant', () {
      final tasks = ComputePlanningTasks.execute(
        plants: [],
        month: 5,
      );

      expect(tasks, isEmpty);
    });

    test(
      'gère plusieurs plants correctement',
      () {
        final tasks =
            ComputePlanningTasks.execute(
          plants: [tomatoPlant, carrotPlant],
          month: 4,
        );

        final tomatoTasks = tasks.where(
          (t) => t.plantId == 1,
        );
        final carrotTasks = tasks.where(
          (t) => t.plantId == 2,
        );

        expect(tomatoTasks, isNotEmpty);
        expect(carrotTasks, isNotEmpty);
      },
    );

    test(
      'récolte en juillet pour la tomate',
      () {
        final tasks =
            ComputePlanningTasks.execute(
          plants: [tomatoPlant],
          month: 7,
        );

        final harvest = tasks.where(
          (t) =>
              t.actionType ==
              PlanningActionType.harvest,
        );
        expect(harvest, isNotEmpty);
      },
    );

    test(
      'tâches triées par urgence',
      () {
        final goodWeather = _buildWeather(
          temperature: 22,
          minTonight: 14,
        );

        final tasks =
            ComputePlanningTasks.execute(
          plants: [tomatoPlant, carrotPlant],
          month: 5,
          weather: goodWeather,
        );

        if (tasks.length >= 2) {
          for (var i = 1; i < tasks.length; i++) {
            expect(
              tasks[i].urgency.index,
              greaterThanOrEqualTo(
                tasks[i - 1].urgency.index,
              ),
            );
          }
        }
      },
    );

    test(
      'bloque semis si vent > 30 km/h',
      () {
        final windyWeather = _buildWeather(
          temperature: 20,
          minTonight: 12,
          windSpeed: 35,
        );

        final tasks =
            ComputePlanningTasks.execute(
          plants: [carrotPlant],
          month: 4,
          weather: windyWeather,
        );

        final sowing = tasks.where(
          (t) =>
              t.actionType ==
              PlanningActionType.sowingOpenGround,
        );
        expect(sowing, isNotEmpty);
        expect(
          sowing.first.blockedByWeather,
          isTrue,
        );
        expect(
          sowing.first.weatherReason,
          contains('Vent'),
        );
      },
    );
  });
}

WeatherData _buildWeather({
  double temperature = 20,
  double minTonight = 10,
  double windSpeed = 5,
  double precipitation = 0,
}) {
  final isGood =
      temperature >= 10 && precipitation == 0;

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
      windSpeed: windSpeed,
      windDirection: 180,
      cloudCover: isGood ? 10 : 80,
      precipitation: precipitation,
      weatherCode: isGood ? 0 : 3,
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
        tempMin: minTonight,
        weatherCode: isGood ? 0 : 3,
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
      goodForPlanting: isGood,
      goodForHarvesting: true,
      frostRisk: minTonight < 3,
    ),
  );
}
