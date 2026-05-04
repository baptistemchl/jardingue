import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/crash_reporting/crash_reporting_service.dart';
import '../services/database/database.dart';
import '../../features/orchard/data/repositories/fruit_tree_repository.dart';
import '../../features/orchard/data/repositories/pheromone_trap_repository.dart';
import '../../features/orchard/domain/models/fruit_trees_filter_state.dart';
import '../../features/orchard/domain/models/pheromone_trap_reminder.dart';
import '../../features/orchard/domain/models/pheromone_trap_type.dart';
import '../../features/orchard/domain/models/user_fruit_tree_with_details.dart';
import 'database_providers.dart';

// Re-export des modeles pour retrocompatibilite
export '../../features/orchard/domain/models/fruit_trees_filter_state.dart';
export '../../features/orchard/domain/models/pheromone_trap_reminder.dart';
export '../../features/orchard/domain/models/pheromone_trap_type.dart';
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

final fruitTreesFilterProvider = NotifierProvider<
    FruitTreesFilterNotifier, FruitTreesFilterState>(FruitTreesFilterNotifier.new);

class FruitTreesFilterNotifier extends Notifier<FruitTreesFilterState> {
  @override
  FruitTreesFilterState build() => const FruitTreesFilterState();

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
  // Toutes les `ref.watch` doivent être déclarées synchroniquement
  // avant tout `await` (cf. règle Riverpod 3.x sur le bookkeeping
  // pause/resume).
  final initFuture = ref.watch(fruitTreesInitProvider.future);
  final repo = ref.watch(fruitTreeRepositoryProvider);
  await initFuture;
  return repo.getAllFruitTrees();
});

final filteredFruitTreesProvider =
    FutureProvider<List<FruitTree>>((ref) async {
  final initFuture = ref.watch(fruitTreesInitProvider.future);
  final repo = ref.watch(fruitTreeRepositoryProvider);
  final filters = ref.watch(fruitTreesFilterProvider);
  await initFuture;

  return repo.getFilteredFruitTrees(
    searchQuery: filters.searchQuery.isNotEmpty
        ? filters.searchQuery
        : null,
    categoryCode: filters.category != FruitTreeCategory.all
        ? filters.category.code
        : null,
    selfFertileOnly: filters.selfFertileOnly,
    containerSuitableOnly: filters.containerSuitableOnly,
  );
});

final fruitTreeByIdProvider =
    FutureProvider.family<FruitTree?, int>((ref, id) async {
  final initFuture = ref.watch(fruitTreesInitProvider.future);
  final repo = ref.watch(fruitTreeRepositoryProvider);
  await initFuture;
  return repo.getFruitTreeById(id);
});

final fruitTreesCountProvider =
    FutureProvider<int>((ref) async {
  final initFuture = ref.watch(fruitTreesInitProvider.future);
  final repo = ref.watch(fruitTreeRepositoryProvider);
  await initFuture;
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

class UserFruitTreesNotifier extends Notifier<
    AsyncValue<List<UserFruitTreeWithDetails>>> {
  @override
  AsyncValue<List<UserFruitTreeWithDetails>> build() {
    _loadData();
    return const AsyncValue.loading();
  }

  FruitTreeRepository get _repo => ref.read(fruitTreeRepositoryProvider);

  Future<void> _loadData() async {
    state = const AsyncValue.loading();
    try {
      final trees = await _repo.getAllUserFruitTreesWithDetails();
      state = AsyncValue.data(trees);
    } catch (e, st) {
      CrashReportingService.recordError(e, st,
        reason: 'UserFruitTreesNotifier._loadData',
      );
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
  }

  Future<void> deleteTree(int id) async {
    await _repo.deleteUserFruitTree(id);
    await _loadData();
  }
}

final userFruitTreesNotifierProvider = NotifierProvider<
    UserFruitTreesNotifier,
    AsyncValue<List<UserFruitTreeWithDetails>>>(UserFruitTreesNotifier.new);

final userFruitTreesCountProvider =
    FutureProvider<int>((ref) async {
  final repo = ref.watch(fruitTreeRepositoryProvider);
  return repo.countUserFruitTrees();
});

// ============================================
// PHEROMONE TRAPS PROVIDERS (v15)
// ============================================

final pheromoneTrapRepositoryProvider =
    Provider<PheromoneTrapRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return PheromoneTrapRepository(db);
});

/// Tous les pieges joints aux details d'arbre.
/// Tri : echeance la plus proche en premier (urgence visuelle).
final pheromoneTrapRemindersProvider =
    FutureProvider<List<PheromoneTrapReminder>>((ref) async {
  // Sync watch avant tout await
  final initFuture = ref.read(databaseInitProvider.future);
  final db = ref.watch(databaseProvider);
  await initFuture;

  final rows = await db.getAllPheromoneTrapsWithTreeDetails();

  final reminders = rows.map((row) {
    final trap = row.readTable(db.pheromoneTraps);
    final user = row.readTable(db.userFruitTrees);
    final tree = row.readTable(db.fruitTrees);
    return PheromoneTrapReminder(
      trap: trap,
      userFruitTree: user,
      fruitTree: tree,
    );
  }).toList();

  // En retard / due soon en premier, puis par date d'echeance
  final now = DateTime.now();
  reminders.sort((a, b) {
    final aOver = a.isOverdueAt(now);
    final bOver = b.isOverdueAt(now);
    if (aOver != bOver) return aOver ? -1 : 1;
    return a.nextRenewalDue.compareTo(b.nextRenewalDue);
  });

  return reminders;
});

/// Notifier metier pour CRUD pieges. Refresh automatiquement les rappels
/// (un meme provider famille n'existant pas ici, on invalide directement).
class PheromoneTrapsNotifier
    extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  PheromoneTrapRepository get _repo =>
      ref.read(pheromoneTrapRepositoryProvider);

  Future<int> addTrap({
    required int userFruitTreeId,
    required PheromoneTrapType type,
    required DateTime installedAt,
    int? lifetimeDays,
    String? notes,
  }) async {
    state = const AsyncLoading();
    try {
      final id = await _repo.addTrap(
        userFruitTreeId: userFruitTreeId,
        type: type,
        installedAt: installedAt,
        lifetimeDays: lifetimeDays,
        notes: notes,
      );
      _invalidate();
      state = const AsyncData(null);
      return id;
    } catch (e, st) {
      CrashReportingService.recordError(e, st,
          reason: 'PheromoneTrapsNotifier.addTrap');
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> renewTrap(int id, {DateTime? installedAt, int? lifetimeDays}) async {
    state = const AsyncLoading();
    try {
      await _repo.renewTrap(
        id: id,
        installedAt: installedAt,
        lifetimeDays: lifetimeDays,
      );
      _invalidate();
      state = const AsyncData(null);
    } catch (e, st) {
      CrashReportingService.recordError(e, st,
          reason: 'PheromoneTrapsNotifier.renewTrap');
      state = AsyncError(e, st);
    }
  }

  Future<void> updateTrap({
    required int id,
    PheromoneTrapType? type,
    DateTime? installedAt,
    int? lifetimeDays,
    String? notes,
  }) async {
    state = const AsyncLoading();
    try {
      await _repo.updateTrap(
        id: id,
        type: type,
        installedAt: installedAt,
        lifetimeDays: lifetimeDays,
        notes: notes,
      );
      _invalidate();
      state = const AsyncData(null);
    } catch (e, st) {
      CrashReportingService.recordError(e, st,
          reason: 'PheromoneTrapsNotifier.updateTrap');
      state = AsyncError(e, st);
    }
  }

  Future<void> deleteTrap(int id) async {
    state = const AsyncLoading();
    try {
      await _repo.deleteTrap(id);
      _invalidate();
      state = const AsyncData(null);
    } catch (e, st) {
      CrashReportingService.recordError(e, st,
          reason: 'PheromoneTrapsNotifier.deleteTrap');
      state = AsyncError(e, st);
    }
  }

  void _invalidate() {
    ref.invalidate(pheromoneTrapRemindersProvider);
  }
}

final pheromoneTrapsNotifierProvider =
    NotifierProvider<PheromoneTrapsNotifier, AsyncValue<void>>(
        PheromoneTrapsNotifier.new);

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
