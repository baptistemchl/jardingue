import 'package:drift/drift.dart';
import '../../../../core/services/database/app_database.dart';
import '../../domain/models/pheromone_trap_type.dart';

/// Repository CRUD des pieges a pheromones.
///
/// Fine wrapper sur les queries Drift de [AppDatabase] : expose une API
/// orientee metier (avec [PheromoneTrapType] plutot que les strings) tout
/// en gardant la persistance dans la DB.
class PheromoneTrapRepository {
  final AppDatabase _db;

  PheromoneTrapRepository(this._db);

  Future<int> addTrap({
    required int userFruitTreeId,
    required PheromoneTrapType type,
    required DateTime installedAt,
    int? lifetimeDays,
    String? notes,
  }) {
    return _db.insertPheromoneTrap(PheromoneTrapsCompanion.insert(
      userFruitTreeId: userFruitTreeId,
      trapType: type.name,
      installedAt: installedAt,
      lifetimeDays: lifetimeDays ?? type.defaultLifetimeDays,
      notes: Value(notes),
    ));
  }

  /// Renouvelle un piege en place : nouvelle date de pose, on conserve le
  /// type. La duree de vie peut etre ajustee si l'utilisateur change de
  /// reference de capsule.
  Future<void> renewTrap({
    required int id,
    DateTime? installedAt,
    int? lifetimeDays,
  }) {
    return _db.renewPheromoneTrap(
      id: id,
      installedAt: installedAt ?? DateTime.now(),
      lifetimeDays: lifetimeDays,
    );
  }

  Future<void> updateTrap({
    required int id,
    PheromoneTrapType? type,
    DateTime? installedAt,
    int? lifetimeDays,
    String? notes,
  }) {
    return _db.updatePheromoneTrap(
      id: id,
      trapType: type?.name,
      installedAt: installedAt,
      lifetimeDays: lifetimeDays,
      notes: notes != null ? Value(notes) : const Value.absent(),
    );
  }

  Future<int> deleteTrap(int id) => _db.deletePheromoneTrap(id);

  Future<List<PheromoneTrap>> getTrapsForTree(int userFruitTreeId) =>
      _db.getTrapsForUserFruitTree(userFruitTreeId);

  Future<List<PheromoneTrap>> getAllTraps() => _db.getAllPheromoneTraps();
}
