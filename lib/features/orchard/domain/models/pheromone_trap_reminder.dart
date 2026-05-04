import '../../../../core/services/database/app_database.dart';
import '../../../garden/domain/models/care_helpers.dart';
import 'pheromone_trap_type.dart';

/// Rappel de renouvellement d'un piege a pheromones.
///
/// Calcule sa propre echeance (`installedAt + lifetimeDays`) et reutilise
/// [computeCareStatus] pour deduire le statut, ce qui evite de redupliquer
/// la logique commune avec arrosage/fertilisation.
class PheromoneTrapReminder {
  final PheromoneTrap trap;
  final UserFruitTree userFruitTree;
  final FruitTree fruitTree;

  const PheromoneTrapReminder({
    required this.trap,
    required this.userFruitTree,
    required this.fruitTree,
  });

  PheromoneTrapType get type => PheromoneTrapType.fromString(trap.trapType);

  /// Date a laquelle le diffuseur arrive en fin de vie.
  DateTime get nextRenewalDue =>
      trap.installedAt.add(Duration(days: trap.lifetimeDays));

  /// Statut a l'instant present, normalise sur l'echelle CareStatus.
  CareStatus statusAt(DateTime now) => computeCareStatus(
        lastDate: trap.installedAt,
        frequencyDays: trap.lifetimeDays,
        now: now,
      );

  bool isOverdueAt(DateTime now) {
    final s = statusAt(now);
    return s == CareStatus.overdue || s == CareStatus.dueSoon;
  }

  int get daysSinceInstalled =>
      DateTime.now().difference(trap.installedAt).inDays;

  /// Nom user-friendly de l'arbre (nickname si defini, sinon nom commun).
  String get treeName => userFruitTree.nickname ?? fruitTree.commonName;
}
