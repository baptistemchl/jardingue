import 'planning_action_type.dart';
import 'task_urgency.dart';

class PlanningTask {
  final int plantId;
  final String plantName;
  final String plantEmoji;
  final PlanningActionType actionType;
  final TaskUrgency urgency;
  final String message;
  final String? detail;
  final bool blockedByWeather;
  final String? weatherReason;

  const PlanningTask({
    required this.plantId,
    required this.plantName,
    required this.plantEmoji,
    required this.actionType,
    required this.urgency,
    required this.message,
    this.detail,
    this.blockedByWeather = false,
    this.weatherReason,
  });
}
