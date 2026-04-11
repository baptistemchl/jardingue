import 'task_urgency.dart';

enum SoilTaskType {
  fertilizing('Fumure', '💩'),
  turning('Retournement', '⛏️'),
  amendment('Amendement', '🧪'),
  preSowing('Préparation semis', '🌱'),
  prePlanting('Préparation plantation', '🌿'),
  mulching('Paillage', '🍂'),
  composting('Compostage', '♻️');

  final String label;
  final String emoji;

  const SoilTaskType(this.label, this.emoji);
}

class SoilTask {
  final SoilTaskType type;
  final String message;
  final TaskUrgency urgency;
  final int month;
  final String? weatherReason;

  const SoilTask({
    required this.type,
    required this.message,
    required this.urgency,
    required this.month,
    this.weatherReason,
  });
}
