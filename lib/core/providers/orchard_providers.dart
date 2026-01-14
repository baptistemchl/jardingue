import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database/database.dart';
import 'database_providers.dart';

// ============================================
// FRUIT TREE IMPORT SERVICE
// ============================================

/// Provider pour le service d'import des arbres fruitiers
final fruitTreeImportServiceProvider = Provider<FruitTreeImportService>((ref) {
  final db = ref.watch(databaseProvider);
  return FruitTreeImportService(db);
});

/// Provider pour l'initialisation des arbres fruitiers
final fruitTreesInitProvider = FutureProvider<int>((ref) async {
  final importService = ref.watch(fruitTreeImportServiceProvider);
  return importService.importFromAssets();
});

// ============================================
// FILTRES
// ============================================

/// Catégories d'arbres fruitiers
enum FruitTreeCategory {
  all('Tous', '🌳', null),
  arbreFruitier('Arbres', '🌳', 'arbre_fruitier'),
  arbusteFruitier('Arbustes', '🌿', 'arbuste_fruitier'),
  petitFruit('Petits fruits', '🍓', 'petit_fruit'),
  lianeFruitiere('Lianes', '🍇', 'liane_fruitiere');

  final String label;
  final String emoji;
  final String? code;

  const FruitTreeCategory(this.label, this.emoji, this.code);

  String get displayLabel => '$emoji $label';

  static FruitTreeCategory fromCode(String? code) {
    if (code == null) return all;
    return FruitTreeCategory.values.firstWhere(
      (c) => c.code == code,
      orElse: () => all,
    );
  }
}

/// État des filtres pour arbres fruitiers
class FruitTreesFilterState {
  final String searchQuery;
  final FruitTreeCategory category;
  final bool? selfFertileOnly;
  final bool? containerSuitableOnly;

  const FruitTreesFilterState({
    this.searchQuery = '',
    this.category = FruitTreeCategory.all,
    this.selfFertileOnly,
    this.containerSuitableOnly,
  });

  FruitTreesFilterState copyWith({
    String? searchQuery,
    FruitTreeCategory? category,
    bool? selfFertileOnly,
    bool? containerSuitableOnly,
  }) {
    return FruitTreesFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      category: category ?? this.category,
      selfFertileOnly: selfFertileOnly ?? this.selfFertileOnly,
      containerSuitableOnly:
          containerSuitableOnly ?? this.containerSuitableOnly,
    );
  }

  bool get hasActiveFilters =>
      searchQuery.isNotEmpty ||
      category != FruitTreeCategory.all ||
      selfFertileOnly == true ||
      containerSuitableOnly == true;
}

/// Provider pour l'état des filtres
final fruitTreesFilterProvider =
    StateNotifierProvider<FruitTreesFilterNotifier, FruitTreesFilterState>((
      ref,
    ) {
      return FruitTreesFilterNotifier();
    });

class FruitTreesFilterNotifier extends StateNotifier<FruitTreesFilterState> {
  FruitTreesFilterNotifier() : super(const FruitTreesFilterState());

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

/// Provider pour la liste complète des arbres fruitiers
final allFruitTreesProvider = FutureProvider<List<FruitTree>>((ref) async {
  await ref.watch(fruitTreesInitProvider.future);
  final db = ref.watch(databaseProvider);
  return db.getAllFruitTrees();
});

/// Provider pour la liste filtrée des arbres fruitiers
final filteredFruitTreesProvider = FutureProvider<List<FruitTree>>((ref) async {
  await ref.watch(fruitTreesInitProvider.future);

  final db = ref.watch(databaseProvider);
  final filters = ref.watch(fruitTreesFilterProvider);

  // Récupère tous les arbres ou recherche
  List<FruitTree> trees;
  if (filters.searchQuery.isEmpty) {
    trees = await db.getAllFruitTreesSorted();
  } else {
    trees = await db.searchFruitTrees(filters.searchQuery);
  }

  // Filtre par catégorie
  if (filters.category != FruitTreeCategory.all &&
      filters.category.code != null) {
    trees = trees.where((t) => t.category == filters.category.code).toList();
  }

  // Filtre autofertile
  if (filters.selfFertileOnly == true) {
    trees = trees.where((t) => t.selfFertile).toList();
  }

  // Filtre pot
  if (filters.containerSuitableOnly == true) {
    trees = trees.where((t) => t.containerSuitable).toList();
  }

  return trees;
});

/// Provider pour un arbre fruitier par ID
final fruitTreeByIdProvider = FutureProvider.family<FruitTree?, int>((
  ref,
  id,
) async {
  await ref.watch(fruitTreesInitProvider.future);
  final db = ref.watch(databaseProvider);
  return db.getFruitTreeById(id);
});

/// Provider pour le nombre total d'arbres fruitiers
final fruitTreesCountProvider = FutureProvider<int>((ref) async {
  await ref.watch(fruitTreesInitProvider.future);
  final db = ref.watch(databaseProvider);
  return db.countFruitTrees();
});

// ============================================
// USER FRUIT TREES (ORCHARD) PROVIDERS
// ============================================

/// Classe pour un arbre utilisateur avec ses détails
class UserFruitTreeWithDetails {
  final UserFruitTree userTree;
  final FruitTree fruitTree;

  UserFruitTreeWithDetails({required this.userTree, required this.fruitTree});

  // Raccourcis pratiques
  int get id => userTree.id;

  String get name => userTree.nickname ?? fruitTree.commonName;

  String get emoji => fruitTree.emoji;

  String? get variety => userTree.variety;

  DateTime? get plantingDate => userTree.plantingDate;

  String? get location => userTree.location;

  String? get notes => userTree.notes;

  String get healthStatus => userTree.healthStatus;

  DateTime? get lastPruningDate => userTree.lastPruningDate;

  DateTime? get lastHarvestDate => userTree.lastHarvestDate;

  double? get lastYieldKg => userTree.lastYieldKg;
}

/// Provider pour la liste des arbres de l'utilisateur avec détails
final userFruitTreesProvider = FutureProvider<List<UserFruitTreeWithDetails>>((
  ref,
) async {
  final db = ref.watch(databaseProvider);
  final results = await db.getAllUserFruitTreesWithDetails();

  return results.map((row) {
    return UserFruitTreeWithDetails(
      userTree: row.readTable(db.userFruitTrees),
      fruitTree: row.readTable(db.fruitTrees),
    );
  }).toList();
});

/// Provider pour un arbre utilisateur par ID
final userFruitTreeByIdProvider =
    FutureProvider.family<UserFruitTreeWithDetails?, int>((ref, id) async {
      final db = ref.watch(databaseProvider);
      final result = await db.getUserFruitTreeWithDetailsById(id);

      if (result == null) return null;

      return UserFruitTreeWithDetails(
        userTree: result.readTable(db.userFruitTrees),
        fruitTree: result.readTable(db.fruitTrees),
      );
    });

/// Notifier pour gérer les arbres fruitiers de l'utilisateur
class UserFruitTreesNotifier
    extends StateNotifier<AsyncValue<List<UserFruitTreeWithDetails>>> {
  final AppDatabase _db;
  final Ref _ref;

  UserFruitTreesNotifier(this._db, this._ref)
    : super(const AsyncValue.loading()) {
    _loadData();
  }

  Future<void> _loadData() async {
    state = const AsyncValue.loading();
    try {
      final results = await _db.getAllUserFruitTreesWithDetails();
      final trees = results.map((row) {
        return UserFruitTreeWithDetails(
          userTree: row.readTable(_db.userFruitTrees),
          fruitTree: row.readTable(_db.fruitTrees),
        );
      }).toList();
      state = AsyncValue.data(trees);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    await _loadData();
  }

  /// Ajoute un arbre au verger
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

    final id = await _db.addUserFruitTree(companion);
    await _loadData();
    _ref.invalidate(userFruitTreesProvider);
    return id;
  }

  /// Met à jour un arbre du verger
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
    await _db.updateUserFruitTreePartial(
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

  /// Supprime un arbre du verger
  Future<void> deleteTree(int id) async {
    await _db.deleteUserFruitTree(id);
    await _loadData();
    _ref.invalidate(userFruitTreesProvider);
  }
}

/// Provider pour le notifier des arbres utilisateur
final userFruitTreesNotifierProvider =
    StateNotifierProvider<
      UserFruitTreesNotifier,
      AsyncValue<List<UserFruitTreeWithDetails>>
    >((ref) {
      final db = ref.watch(databaseProvider);
      return UserFruitTreesNotifier(db, ref);
    });

/// Provider pour le nombre d'arbres de l'utilisateur
final userFruitTreesCountProvider = FutureProvider<int>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.countUserFruitTrees();
});

// ============================================
// HELPERS
// ============================================

/// Extension pour les helpers de FruitTree (catégorie, etc.)
extension FruitTreeHelpers on FruitTree {
  /// Catégorie formatée
  FruitTreeCategory get categoryEnum => FruitTreeCategory.fromCode(category);

  /// Label de sous-catégorie formaté
  String get subcategoryLabel {
    switch (subcategory) {
      case 'pepins':
        return 'Pépins';
      case 'noyaux':
        return 'Noyaux';
      case 'mediterraneen':
        return 'Méditerranéen';
      case 'fruits_a_coque':
        return 'Fruits à coque';
      case 'ronces':
        return 'Ronces';
      case 'groseilles':
        return 'Groseilles';
      case 'bruyeres':
        return 'Bruyères';
      case 'lianes':
        return 'Lianes';
      case 'vigne':
        return 'Vigne';
      case 'superfruit':
        return 'Superfruit';
      case 'sauvage':
        return 'Sauvage';
      case 'exotique':
        return 'Exotique';
      default:
        return subcategory ?? 'Autre';
    }
  }
}
