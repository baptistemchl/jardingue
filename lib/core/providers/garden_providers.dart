import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../services/database/app_database.dart';
import 'database_providers.dart';

// ============================================
// GARDEN PROVIDERS
// ============================================

/// Provider pour la liste des potagers
final gardensListProvider = FutureProvider<List<Garden>>((ref) async {
  await ref.watch(databaseInitProvider.future);
  final db = ref.watch(databaseProvider);
  return db.getAllGardens();
});

/// Provider pour un potager par ID
final gardenByIdProvider = FutureProvider.family<Garden?, int>((ref, id) async {
  await ref.watch(databaseInitProvider.future);
  final db = ref.watch(databaseProvider);
  return db.getGardenById(id);
});

/// Provider pour les plantes d'un potager avec détails
final gardenPlantsProvider =
    FutureProvider.family<List<GardenPlantWithDetails>, int>((
      ref,
      gardenId,
    ) async {
      await ref.watch(databaseInitProvider.future);
      final db = ref.watch(databaseProvider);
      final gardenPlants = await db.getGardenPlants(gardenId);

      final List<GardenPlantWithDetails> result = [];
      for (final gp in gardenPlants) {
        final plant = gp.plantId > 0 ? await db.getPlantById(gp.plantId) : null;
        result.add(GardenPlantWithDetails(gardenPlant: gp, plant: plant));
      }
      return result;
    });

/// Provider pour le mode édition
final gardenEditModeProvider = StateProvider<bool>((ref) => false);

// ============================================
// GARDEN NOTIFIER
// ============================================

final gardenNotifierProvider =
    StateNotifierProvider<GardenNotifier, AsyncValue<void>>((ref) {
      final db = ref.watch(databaseProvider);
      return GardenNotifier(db, ref);
    });

class GardenNotifier extends StateNotifier<AsyncValue<void>> {
  final AppDatabase _db;
  final Ref _ref;

  GardenNotifier(this._db, this._ref) : super(const AsyncData(null));

  /// Crée un nouveau potager (dimensions en mètres)
  Future<int> createGarden({
    required String name,
    required double widthMeters,
    required double heightMeters,
    int cellSizeCm = 10, // Résolution de la grille interne
  }) async {
    state = const AsyncLoading();
    try {
      // Convertit mètres en cellules (1 cellule = cellSizeCm)
      final widthCells = (widthMeters * 100 / cellSizeCm).ceil();
      final heightCells = (heightMeters * 100 / cellSizeCm).ceil();

      final id = await _db.createGarden(
        GardensCompanion.insert(
          name: name,
          widthCells: Value(widthCells),
          heightCells: Value(heightCells),
          cellSizeCm: Value(cellSizeCm),
        ),
      );
      _ref.invalidate(gardensListProvider);
      state = const AsyncData(null);
      return id;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Met à jour un potager
  Future<void> updateGarden({
    required int id,
    required String name,
    required double widthMeters,
    required double heightMeters,
    int cellSizeCm = 10,
  }) async {
    state = const AsyncLoading();
    try {
      final widthCells = (widthMeters * 100 / cellSizeCm).ceil();
      final heightCells = (heightMeters * 100 / cellSizeCm).ceil();

      await _db.updateGarden(
        Garden(
          id: id,
          name: name,
          widthCells: widthCells,
          heightCells: heightCells,
          cellSizeCm: cellSizeCm,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      _ref.invalidate(gardensListProvider);
      _ref.invalidate(gardenByIdProvider(id));
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Supprime un potager
  Future<void> deleteGarden(int id) async {
    state = const AsyncLoading();
    try {
      await _db.deleteGarden(id);
      _ref.invalidate(gardensListProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Ajoute une plante au potager (position et taille en mètres)
  Future<int> addPlantToGarden({
    required int gardenId,
    required int plantId,
    required double xMeters,
    required double yMeters,
    required double widthMeters,
    required double heightMeters,
    String? notes,
  }) async {
    state = const AsyncLoading();
    try {
      final garden = await _db.getGardenById(gardenId);
      if (garden == null) throw Exception('Potager non trouvé');

      final cellSize = garden.cellSizeCm;
      final gridX = (xMeters * 100 / cellSize).round();
      final gridY = (yMeters * 100 / cellSize).round();
      final widthCells = (widthMeters * 100 / cellSize).ceil();
      final heightCells = (heightMeters * 100 / cellSize).ceil();

      final id = await _db.addPlantToGarden(
        GardenPlantsCompanion.insert(
          gardenId: gardenId,
          plantId: plantId,
          gridX: gridX,
          gridY: gridY,
          widthCells: Value(widthCells.clamp(1, 100)),
          heightCells: Value(heightCells.clamp(1, 100)),
          plantedAt: Value(DateTime.now()),
          notes: Value(notes),
        ),
      );
      _ref.invalidate(gardenPlantsProvider(gardenId));
      state = const AsyncData(null);
      return id;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Ajoute une zone au potager (serre, compost, allée, etc.)
  Future<int> addZoneToGarden({
    required int gardenId,
    required double xMeters,
    required double yMeters,
    required double widthMeters,
    required double heightMeters,
    required String zoneType,
    String? notes,
  }) async {
    state = const AsyncLoading();
    try {
      final garden = await _db.getGardenById(gardenId);
      if (garden == null) throw Exception('Potager non trouvé');

      final cellSize = garden.cellSizeCm;
      final gridX = (xMeters * 100 / cellSize).round();
      final gridY = (yMeters * 100 / cellSize).round();
      final widthCells = (widthMeters * 100 / cellSize).ceil();
      final heightCells = (heightMeters * 100 / cellSize).ceil();

      final id = await _db.addPlantToGarden(
        GardenPlantsCompanion.insert(
          gardenId: gardenId,
          plantId: 0,
          // 0 = zone spéciale
          gridX: gridX,
          gridY: gridY,
          widthCells: Value(widthCells.clamp(1, 100)),
          heightCells: Value(heightCells.clamp(1, 100)),
          notes: Value(zoneType + (notes != null ? '|$notes' : '')),
        ),
      );
      _ref.invalidate(gardenPlantsProvider(gardenId));
      state = const AsyncData(null);
      return id;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Déplace un élément (en mètres)
  Future<void> moveElement(
    int gardenPlantId,
    double xMeters,
    double yMeters,
    int gardenId,
  ) async {
    state = const AsyncLoading();
    try {
      final garden = await _db.getGardenById(gardenId);
      if (garden == null) throw Exception('Potager non trouvé');

      final cellSize = garden.cellSizeCm;
      final gridX = (xMeters * 100 / cellSize).round();
      final gridY = (yMeters * 100 / cellSize).round();

      await _db.updateGardenPlantPosition(gardenPlantId, gridX, gridY);
      _ref.invalidate(gardenPlantsProvider(gardenId));
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Supprime un élément
  Future<void> removeElement(int gardenPlantId, int gardenId) async {
    state = const AsyncLoading();
    try {
      await _db.removePlantFromGarden(gardenPlantId);
      _ref.invalidate(gardenPlantsProvider(gardenId));
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Met à jour la taille d'un élément (en mètres)
  Future<void> updateElementSize(
    int gardenPlantId,
    double widthMeters,
    double heightMeters,
    int gardenId,
  ) async {
    state = const AsyncLoading();
    try {
      final garden = await _db.getGardenById(gardenId);
      if (garden == null) throw Exception('Potager non trouvé');

      final cellSize = garden.cellSizeCm;
      final widthCells = (widthMeters * 100 / cellSize).ceil();
      final heightCells = (heightMeters * 100 / cellSize).ceil();

      await _db.updateGardenPlantSize(gardenPlantId, widthCells, heightCells);
      _ref.invalidate(gardenPlantsProvider(gardenId));
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

// ============================================
// MODELS
// ============================================

/// Types de zones spéciales
enum ZoneType {
  greenhouse('Serre', '🏠', 0xFFFF9800),
  path('Allée', '🚶', 0xFF607D8B),
  water('Point d\'eau', '💧', 0xFF03A9F4),
  compost('Compost', '♻️', 0xFF795548),
  storage('Rangement', '📦', 0xFF9E9E9E);

  final String label;
  final String emoji;
  final int color;

  const ZoneType(this.label, this.emoji, this.color);

  static ZoneType? fromName(String? name) {
    if (name == null) return null;
    try {
      return ZoneType.values.firstWhere((t) => t.name == name);
    } catch (_) {
      return null;
    }
  }
}

/// Modèle combiné
class GardenPlantWithDetails {
  final GardenPlant gardenPlant;
  final Plant? plant;

  GardenPlantWithDetails({required this.gardenPlant, this.plant});

  int get id => gardenPlant.id;

  int get gridX => gardenPlant.gridX;

  int get gridY => gardenPlant.gridY;

  int get widthCells => gardenPlant.widthCells;

  int get heightCells => gardenPlant.heightCells;

  String? get notes => gardenPlant.notes;

  DateTime? get plantedAt => gardenPlant.plantedAt;

  bool get isZone => gardenPlant.plantId == 0;

  ZoneType? get zoneType {
    if (!isZone || notes == null) return null;
    final typeName = notes!.split('|').first;
    return ZoneType.fromName(typeName);
  }

  String get emoji {
    if (isZone) return zoneType?.emoji ?? '⬛';
    if (plant == null) return '🌱';

    final name = plant!.commonName.toLowerCase();
    const map = {
      'tomate': '🍅',
      'carotte': '🥕',
      'salade': '🥬',
      'laitue': '🥬',
      'poivron': '🫑',
      'aubergine': '🍆',
      'courgette': '🥒',
      'concombre': '🥒',
      'haricot': '🫘',
      'petit pois': '🫛',
      'pois': '🫛',
      'radis': '🔴',
      'betterave': '🔴',
      'oignon': '🧅',
      'ail': '🧄',
      'pomme de terre': '🥔',
      'chou': '🥬',
      'brocoli': '🥦',
      'épinard': '🥬',
      'fraise': '🍓',
      'basilic': '🌿',
      'persil': '🌿',
      'menthe': '🌿',
      'maïs': '🌽',
      'citrouille': '\u{1F383}',
      'courge': '\u{1F383}',
      'potiron': '\u{1F383}',
      'potimarron': '\u{1F383}',
      'butternut': '\u{1F383}',
      'patisson': '\u{1F383}',
    };
    for (final entry in map.entries) {
      if (name.contains(entry.key)) return entry.value;
    }
    return '🌱';
  }

  String get name {
    if (isZone) return zoneType?.label ?? 'Zone';
    return plant?.commonName ?? 'Plante';
  }

  int get color {
    if (isZone) return zoneType?.color ?? 0xFF9E9E9E;

    final categoryCode = plant?.categoryCode ?? '';
    switch (categoryCode) {
      case 'leafy_green':
        return 0xFF4CAF50;
      case 'root':
        return 0xFFFF9800;
      case 'fruit_vegetable':
        return 0xFFF44336;
      case 'legume':
        return 0xFF8BC34A;
      case 'herb':
        return 0xFF009688;
      case 'allium':
        return 0xFF9C27B0;
      case 'tuber':
        return 0xFF795548;
      case 'fruit':
        return 0xFFE91E63;
      default:
        return 0xFF4CAF50;
    }
  }

  /// Convertit en mètres
  double xMeters(int cellSizeCm) => gridX * cellSizeCm / 100;

  double yMeters(int cellSizeCm) => gridY * cellSizeCm / 100;

  double widthMeters(int cellSizeCm) => widthCells * cellSizeCm / 100;

  double heightMeters(int cellSizeCm) => heightCells * cellSizeCm / 100;
}

/// Extension pour Garden
extension GardenExtension on Garden {
  double get widthMeters => widthCells * cellSizeCm / 100;

  double get heightMeters => heightCells * cellSizeCm / 100;

  double get surfaceM2 => widthMeters * heightMeters;
}
