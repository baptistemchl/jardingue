import '../../../../core/services/database/app_database.dart';
import '../../domain/models/user_fruit_tree_with_details.dart';

/// Abstract interface for fruit-tree-related data operations.
abstract interface class FruitTreeRepository {
  Future<List<FruitTree>> getAllFruitTreesSorted();
  Future<List<FruitTree>> searchFruitTrees(String query);
  Future<FruitTree?> getFruitTreeById(int id);
  Future<int> countFruitTrees();
  Future<List<FruitTree>> getAllFruitTrees();
  Future<List<UserFruitTreeWithDetails>> getAllUserFruitTreesWithDetails();
  Future<UserFruitTreeWithDetails?> getUserFruitTreeWithDetailsById(int id);
  Future<int> addUserFruitTree(UserFruitTreesCompanion tree);
  Future<bool> updateUserFruitTree(UserFruitTree tree);
  Future<void> updateUserFruitTreePartial({
    required int id,
    String? nickname,
    String? variety,
    DateTime? plantingDate,
    String? location,
    String? notes,
    String? healthStatus,
    DateTime? lastPruningDate,
    DateTime? lastHarvestDate,
    double? lastYieldKg,
  });
  Future<int> deleteUserFruitTree(int id);
  Future<int> countUserFruitTrees();
}

/// Drift-backed implementation of [FruitTreeRepository].
class DriftFruitTreeRepository implements FruitTreeRepository {
  final AppDatabase _db;

  DriftFruitTreeRepository(this._db);

  @override
  Future<List<FruitTree>> getAllFruitTreesSorted() =>
      _db.getAllFruitTreesSorted();

  @override
  Future<List<FruitTree>> searchFruitTrees(String query) =>
      _db.searchFruitTrees(query);

  @override
  Future<FruitTree?> getFruitTreeById(int id) => _db.getFruitTreeById(id);

  @override
  Future<int> countFruitTrees() => _db.countFruitTrees();

  @override
  Future<List<FruitTree>> getAllFruitTrees() => _db.getAllFruitTrees();

  @override
  Future<List<UserFruitTreeWithDetails>>
      getAllUserFruitTreesWithDetails() async {
    final results = await _db.getAllUserFruitTreesWithDetails();
    return results.map((row) {
      return UserFruitTreeWithDetails(
        userTree: row.readTable(_db.userFruitTrees),
        fruitTree: row.readTable(_db.fruitTrees),
      );
    }).toList();
  }

  @override
  Future<UserFruitTreeWithDetails?> getUserFruitTreeWithDetailsById(
      int id) async {
    final result = await _db.getUserFruitTreeWithDetailsById(id);
    if (result == null) return null;
    return UserFruitTreeWithDetails(
      userTree: result.readTable(_db.userFruitTrees),
      fruitTree: result.readTable(_db.fruitTrees),
    );
  }

  @override
  Future<int> addUserFruitTree(UserFruitTreesCompanion tree) =>
      _db.addUserFruitTree(tree);

  @override
  Future<bool> updateUserFruitTree(UserFruitTree tree) =>
      _db.updateUserFruitTree(tree);

  @override
  Future<void> updateUserFruitTreePartial({
    required int id,
    String? nickname,
    String? variety,
    DateTime? plantingDate,
    String? location,
    String? notes,
    String? healthStatus,
    DateTime? lastPruningDate,
    DateTime? lastHarvestDate,
    double? lastYieldKg,
  }) =>
      _db.updateUserFruitTreePartial(
        id: id,
        nickname: nickname,
        variety: variety,
        plantingDate: plantingDate,
        location: location,
        notes: notes,
        healthStatus: healthStatus,
        lastPruningDate: lastPruningDate,
        lastHarvestDate: lastHarvestDate,
        lastYieldKg: lastYieldKg,
      );

  @override
  Future<int> deleteUserFruitTree(int id) => _db.deleteUserFruitTree(id);

  @override
  Future<int> countUserFruitTrees() => _db.countUserFruitTrees();
}
