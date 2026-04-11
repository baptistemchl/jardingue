import '../../../../core/services/weather/weather_models.dart';
import '../models/planning_action_type.dart';
import '../models/planning_rule.dart';
import '../models/planning_task.dart';
import '../models/task_urgency.dart';
import 'extract_planning_rules.dart';

/// Donnee plant simplifiee pour le use case.
/// Evite de dependre de la classe Drift.
class PlantData {
  final int id;
  final String commonName;
  final String emoji;
  final String? sowingCalendar;
  final String? plantingCalendar;
  final String? harvestCalendar;
  final int? plantingMinTempC;

  const PlantData({
    required this.id,
    required this.commonName,
    required this.emoji,
    this.sowingCalendar,
    this.plantingCalendar,
    this.harvestCalendar,
    this.plantingMinTempC,
  });
}

/// Calcule les taches de planification pour TOUS
/// les mois, en croisant les regles calendrier
/// du plant avec la meteo du mois courant.
class ComputePlanningTasks {
  const ComputePlanningTasks._();

  /// Retourne les tâches indexées par mois (1-12).
  static Map<int, List<PlanningTask>> executeAll({
    required List<PlantData> plants,
    required int currentMonth,
    WeatherData? weather,
  }) {
    final result = <int, List<PlanningTask>>{};

    for (final plant in plants) {
      final rules = ExtractPlanningRules.execute(
        sowingCalendar: plant.sowingCalendar,
        plantingCalendar: plant.plantingCalendar,
        harvestCalendar: plant.harvestCalendar,
        plantingMinTempC: plant.plantingMinTempC,
      );

      for (var month = 1; month <= 12; month++) {
        final applicable = rules.where(
          (r) => r.appliesToMonth(month),
        );

        for (final rule in applicable) {
          // La météo ne s'applique qu'au mois courant
          final useWeather =
              month == currentMonth
                  ? weather
                  : null;

          final task = _buildTask(
            plant: plant,
            rule: rule,
            month: month,
            currentMonth: currentMonth,
            weather: useWeather,
          );
          result.putIfAbsent(month, () => []);
          result[month]!.add(task);
        }
      }
    }

    // Trier chaque mois par urgence
    for (final tasks in result.values) {
      tasks.sort(
        (a, b) => a.urgency.index.compareTo(
          b.urgency.index,
        ),
      );
    }

    return result;
  }

  /// Version simplifiée pour un seul mois
  /// (rétrocompatibilité tests).
  static List<PlanningTask> execute({
    required List<PlantData> plants,
    required int month,
    WeatherData? weather,
  }) {
    final all = executeAll(
      plants: plants,
      currentMonth: month,
      weather: weather,
    );
    return all[month] ?? [];
  }

  static PlanningTask _buildTask({
    required PlantData plant,
    required PlanningRule rule,
    required int month,
    required int currentMonth,
    WeatherData? weather,
  }) {
    var urgency = _baseUrgency(
      month,
      currentMonth,
    );
    var blocked = false;
    String? weatherReason;

    if (weather != null) {
      final result = _evaluateWeather(
        rule: rule,
        weather: weather,
      );
      blocked = result.blocked;
      weatherReason = result.reason;
      if (!blocked) {
        urgency = result.urgency;
      }
    }

    if (blocked) {
      urgency = TaskUrgency.blocked;
    }

    return PlanningTask(
      plantId: plant.id,
      plantName: plant.commonName,
      plantEmoji: plant.emoji,
      actionType: rule.actionType,
      urgency: urgency,
      message: _buildMessage(
        rule.actionType,
        plant.commonName,
        urgency,
      ),
      detail: rule.detail,
      blockedByWeather: blocked,
      weatherReason: weatherReason,
    );
  }

  /// Urgence de base selon la distance au mois
  /// courant (sans météo).
  static TaskUrgency _baseUrgency(
    int month,
    int currentMonth,
  ) {
    if (month == currentMonth) {
      return TaskUrgency.upcoming;
    }
    final diff = month - currentMonth;
    if (diff == 1 || diff == -11) {
      return TaskUrgency.soon;
    }
    if (diff < 0 && diff > -6) {
      return TaskUrgency.waiting;
    }
    return TaskUrgency.waiting;
  }

  static _WeatherEval _evaluateWeather({
    required PlanningRule rule,
    required WeatherData weather,
  }) {
    final temp = weather.current.temperature;
    final wind = weather.current.windSpeed;
    final precip = weather.current.precipitation;
    final minTonight =
        weather.dailyForecast.isNotEmpty
            ? weather.dailyForecast.first.tempMin
            : temp;

    if (rule.minTemp != null
        && temp < rule.minTemp!) {
      return _WeatherEval(
        blocked: true,
        reason: 'Température trop basse '
            '(${temp.round()}°C < '
            '${rule.minTemp!.round()}°C)',
      );
    }

    if (rule.requiresNoFrost && minTonight < 0) {
      return _WeatherEval(
        blocked: true,
        reason: 'Risque de gel cette nuit '
            '(${minTonight.round()}°C)',
      );
    }

    if (_isSowing(rule.actionType) && wind > 30) {
      return _WeatherEval(
        blocked: true,
        reason: 'Vent trop fort '
            '(${wind.round()} km/h)',
      );
    }

    if (_isSowing(rule.actionType) && precip > 5) {
      return _WeatherEval(
        blocked: true,
        reason: 'Trop de précipitations',
      );
    }

    if (weather.current.condition.isGood
        && temp >= (rule.minTemp ?? 10)) {
      return const _WeatherEval(
        urgency: TaskUrgency.now,
      );
    }

    return const _WeatherEval(
      urgency: TaskUrgency.soon,
    );
  }

  static bool _isSowing(
    PlanningActionType type,
  ) {
    return type ==
            PlanningActionType.sowingUnderCover
        || type ==
            PlanningActionType.sowingOpenGround;
  }

  static String _buildMessage(
    PlanningActionType action,
    String plantName,
    TaskUrgency urgency,
  ) {
    final label = action.label.toLowerCase();
    return switch (urgency) {
      TaskUrgency.now =>
        'Il est temps : $label',
      TaskUrgency.soon =>
        'Bientôt : $label',
      TaskUrgency.upcoming =>
        '${action.label} possible ce mois',
      TaskUrgency.blocked =>
        'Attendre pour $label',
      TaskUrgency.waiting =>
        action.label,
    };
  }
}

class _WeatherEval {
  final bool blocked;
  final String? reason;
  final TaskUrgency urgency;

  const _WeatherEval({
    this.blocked = false,
    this.reason,
    this.urgency = TaskUrgency.upcoming,
  });
}
