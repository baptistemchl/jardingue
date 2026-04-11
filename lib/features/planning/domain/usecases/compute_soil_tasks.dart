import '../../../../core/services/weather/weather_models.dart';
import '../models/soil_task.dart';
import '../models/task_urgency.dart';

/// Calcule les taches de preparation du sol
/// selon le mois et la meteo.
class ComputeSoilTasks {
  const ComputeSoilTasks._();

  static List<SoilTask> execute({
    required int month,
    WeatherData? weather,
  }) {
    final tasks = <SoilTask>[];
    final temp = weather?.current.temperature;
    final precip =
        weather?.current.precipitation;

    _addFertilizing(tasks, month, temp);
    _addTurning(tasks, month, precip);
    _addAmendment(tasks, month, temp);
    _addMulching(tasks, month, temp);
    _addComposting(tasks, month);

    return tasks;
  }

  /// Fumure : octobre-novembre
  static void _addFertilizing(
    List<SoilTask> tasks,
    int month,
    double? temp,
  ) {
    if (month < 10 || month > 11) return;

    final ok = temp == null || temp > 5;
    tasks.add(SoilTask(
      type: SoilTaskType.fertilizing,
      message: ok
          ? 'Période idéale pour fumer '
              'le terrain'
          : 'Attendre un redoux pour '
              'la fumure',
      urgency: ok
          ? TaskUrgency.now
          : TaskUrgency.blocked,
      month: month,
      weatherReason:
          ok ? null : 'Sol trop froid',
    ));
  }

  /// Retournement : fevrier-mars
  static void _addTurning(
    List<SoilTask> tasks,
    int month,
    double? precip,
  ) {
    if (month < 2 || month > 3) return;

    final tooWet =
        precip != null && precip > 5;
    tasks.add(SoilTask(
      type: SoilTaskType.turning,
      message: tooWet
          ? 'Sol trop humide pour retourner'
          : 'Retourner le terrain '
              'en profondeur',
      urgency: tooWet
          ? TaskUrgency.blocked
          : TaskUrgency.now,
      month: month,
      weatherReason: tooWet
          ? 'Trop de précipitations'
          : null,
    ));
  }

  /// Amendement : mars-avril
  static void _addAmendment(
    List<SoilTask> tasks,
    int month,
    double? temp,
  ) {
    if (month < 3 || month > 4) return;

    final ok = temp == null || temp > 8;
    tasks.add(SoilTask(
      type: SoilTaskType.amendment,
      message: ok
          ? 'Amender le sol avant les semis'
          : 'Attendre que le sol '
              'se réchauffe',
      urgency: ok
          ? TaskUrgency.now
          : TaskUrgency.soon,
      month: month,
    ));
  }

  /// Paillage : avril-octobre si temp > 15
  static void _addMulching(
    List<SoilTask> tasks,
    int month,
    double? temp,
  ) {
    if (month < 4 || month > 10) return;

    final hot = temp != null && temp > 15;
    if (!hot) return;

    tasks.add(SoilTask(
      type: SoilTaskType.mulching,
      message:
          'Pailler pour conserver l\'humidité',
      urgency: TaskUrgency.soon,
      month: month,
    ));
  }

  /// Compostage : mars et septembre
  static void _addComposting(
    List<SoilTask> tasks,
    int month,
  ) {
    if (month != 3 && month != 9) return;

    tasks.add(SoilTask(
      type: SoilTaskType.composting,
      message: month == 3
          ? 'Épandre le compost mûr '
              'de l\'hiver'
          : 'Préparer le compost '
              'pour l\'hiver',
      urgency: TaskUrgency.upcoming,
      month: month,
    ));
  }
}
