import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database/database.dart';
import '../../features/orchard/domain/models/fruit_trees_filter_state.dart';
import '../../features/orchard/domain/models/user_fruit_tree_with_details.dart';
import '../../features/orchard/data/repositories/fruit_tree_repository.dart';
import 'database_providers.dart';

// Re-export des modeles pour retrocompatibilite
export '../../features/orchard/domain/models/fruit_trees_filter_state.dart';
export '../../features/orchard/domain/models/user_fruit_tree_with_details.dart';

// ============================================
// REPOSITORY PROVIDER
// ============================================

/// Provider pour le repository des arbres fruitiers.
final fruitTreeRepositoryProvider = Provider<FruitTreeRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return DriftFruitTreeRepository(db);
});

// ============================================
// FRUIT TREE IMPORT SERVICE
// ============================================

final fruitTreeImportServiceProvider =
    Provider<FruitTreeImportService>((ref) {
  final db = ref.watch(databaseProvider);
  return FruitTreeImportService(db);
});

final fruitTreesInitProvider =
    FutureProvider<int>((ref) async {
  final importService =
      ref.watch(fruitTreeImportServiceProvider);
  return importService.importFromAssets();
});

// ============================================
// FILTRES
// ============================================

final fruitTreesFilterProvider = StateNotifierProvider<
    FruitTreesFilterNotifier, FruitTreesFilterState>((ref) {
  return FruitTreesFilterNotifier();
});

class FruitTreesFilterNotifier
    extends StateNotifier<FruitTreesFilterState> {
  FruitTreesFilterNotifier()
      : super(const FruitTreesFilterState());

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setCategory(FruitTreeCategory category) {
    state = state.copyWith(category: category);
  }

  void setSelfFertileOnly(bool? value) {
    state = state.copyWith(selfFertileOnly: value);
  }

  void setContainerSuitableOnly(bool? value) {
    state = state.copyWith(containerSuitableOnly: value);
  }

  void clearFilters() {
    state = const FruitTreesFilterState();
  }
}

// ============================================
// FRUIT TREES LIST PROVIDERS
// ============================================

final allFruitTreesProvider =
    FutureProvider<List<FruitTree>>((ref) async {
  await ref.watch(fruitTreesInitProvider.future);
  final repo = ref.watch(fruitTreeRepositoryProvider);
  return repo.getAllFruitTrees();
});

final filteredFruitTreesProvider =
    FutureProvider<List<FruitTree>>((ref) async {
  await ref.watch(fruitTreesInitProvider.future);

  final repo = ref.watch(fruitTreeRepositoryProvider);
  final filters = ref.watch(fruitTreesFilterProvider);

  List<FruitTree> trees;
  if (filters.searchQuery.isEmpty) {
    trees = await repo.getAllFruitTreesSorted();
  } else {
    trees = await repo.searchFruitTrees(filters.searchQuery);
  }

  if (filters.category != FruitTreeCategory.all &&
      filters.category.code != null) {
    trees = trees
        .where(
          (t) => t.category == filters.category.code,
        )
        .toList();
  }

  if (filters.selfFertileOnly == true) {
    trees = trees.where((t) => t.selfFertile).toList();
  }

  if (filters.containerSuitableOnly == true) {
    trees =
        trees.where((t) => t.containerSuitable).toList();
  }

  return trees;
});

final fruitTreeByIdProvider =
    FutureProvider.family<FruitTree?, int>((ref, id) async {
  await ref.watch(fruitTreesInitProvider.future);
  final repo = ref.watch(fruitTreeRepositoryProvider);
  return repo.getFruitTreeById(id);
});

final fruitTreesCountProvider =
    FutureProvider<int>((ref) async {
  await ref.watch(fruitTreesInitProvider.future);
  final repo = ref.watch(fruitTreeRepositoryProvider);
  return repo.countFruitTrees();
});

// ============================================
// USER FRUIT TREES (ORCHARD) PROVIDERS
// ============================================

final userFruitTreesProvider =
    FutureProvider<List<UserFruitTreeWithDetails>>(
        (ref) async {
  final repo = ref.watch(fruitTreeRepositoryProvider);
  return repo.getAllUserFruitTreesWithDetails();
});

final userFruitTreeByIdProvider = FutureProvider.family<
    UserFruitTreeWithDetails?, int>((ref, id) async {
  final repo = ref.watch(fruitTreeRepositoryProvider);
  return repo.getUserFruitTreeWithDetailsById(id);
});

class UserFruitTreesNotifier extends StateNotifier<
    AsyncValue<List<UserFruitTreeWithDetails>>> {
  final FruitTreeRepository _repo;
  final Ref _ref;

  UserFruitTreesNotifier(this._repo, this._ref)
      : super(const AsyncValue.loading()) {
    _loadData();
  }

  Future<void> _loadData() async {
    state = const AsyncValue.loading();
    try {
      final trees = await _repo.getAllUserFruitTreesWithDetails();
      state = AsyncValue.data(trees);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async => _loadData();

  Future<int> addTree({
    required int fruitTreeId,
    String? nickname,
    String? variety,
    DateTime? plantingDate,
    String? location,
    String? notes,
  }) async {
    final companion = UserFruitTreesCompanion(
      fruitTreeId: Value(fruitTreeId),
      nickname: Value(nickname),
      variety: Value(variety),
      plantingDate: Value(plantingDate),
      location: Value(location),
      notes: Value(notes),
    );

    final id = await _repo.addUserFruitTree(companion);
    await _loadData();
    _ref.invalidate(userFruitTreesProvider);
    return id;
  }

  Future<void> updateTree({
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
  }) async {
    await _repo.updateUserFruitTreePartial(
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
    await _loadData();
    _ref.invalidate(userFruitTreesProvider);
    _ref.invalidate(userFruitTreeByIdProvider(id));
  }

  Future<void> deleteTree(int id) async {
    await _repo.deleteUserFruitTree(id);
    await _loadData();
    _ref.invalidate(userFruitTreesProvider);
  }
}

final userFruitTreesNotifierProvider = StateNotifierProvider<
    UserFruitTreesNotifier,
    AsyncValue<List<UserFruitTreeWithDetails>>>((ref) {
  final repo = ref.watch(fruitTreeRepositoryProvider);
  return UserFruitTreesNotifier(repo, ref);
});

final userFruitTreesCountProvider =
    FutureProvider<int>((ref) async {
  final repo = ref.watch(fruitTreeRepositoryProvider);
  return repo.countUserFruitTrees();
});

// ============================================
// HELPERS
// ============================================

extension FruitTreeHelpers on FruitTree {
  FruitTreeCategory get categoryEnum {
    return FruitTreeCategory.fromCode(category);
  }

  String get subcategoryLabel {
    return switch (subcategory) {
      'pepins' => 'Pépins',
      'noyaux' => 'Noyaux',
      'mediterraneen' => 'Méditerranéen',
      'fruits_a_coque' => 'Fruits à coque',
      'ronces' => 'Ronces',
      'groseilles' => 'Groseilles',
      'bruyeres' => 'Bruyères',
      'lianes' => 'Lianes',
      'vigne' => 'Vigne',
      'superfruit' => 'Superfruit',
      'sauvage' => 'Sauvage',
      'exotique' => 'Exotique',
      _ => subcategory ?? 'Autre',
    };
  }
}
