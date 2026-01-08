import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'app_database.dart';

/// Service pour importer les données JSON des arbres fruitiers
class FruitTreeImportService {
  final AppDatabase _db;

  FruitTreeImportService(this._db);

  /// Importe les arbres fruitiers depuis le fichier JSON des assets
  /// Retourne le nombre d'arbres importés
  Future<int> importFromAssets({bool forceReimport = false}) async {
    // Vérifie si les données existent déjà
    final existingCount = await _db.countFruitTrees();
    if (existingCount > 0 && !forceReimport) {
      print('🌳 Base arbres fruitiers déjà peuplée ($existingCount arbres)');
      return existingCount;
    }

    print('🌳 Début de l\'import des arbres fruitiers...');

    try {
      // Charge le fichier JSON
      final jsonString = await rootBundle.loadString(
        'assets/data/fruit_trees.json',
      );
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      final treesJson = jsonData['fruit_trees'] as List<dynamic>;

      // Nettoie la table si réimport forcé
      if (forceReimport) {
        await _db.deleteAllFruitTrees();
        print('🗑️ Table arbres fruitiers nettoyée');
      }

      int importedCount = 0;

      // Importe chaque arbre
      for (final treeJson in treesJson) {
        try {
          await _importTree(treeJson as Map<String, dynamic>);
          importedCount++;
        } catch (e) {
          print('❌ Erreur import arbre ${treeJson['common_name']}: $e');
        }
      }

      print('✅ Import arbres fruitiers terminé: $importedCount arbres');
      return importedCount;
    } catch (e) {
      print('❌ Erreur lors du chargement du JSON: $e');
      return 0;
    }
  }

  /// Importe un arbre fruitier depuis le JSON
  Future<void> _importTree(Map<String, dynamic> json) async {
    final tree = FruitTreesCompanion(
      id: Value(json['id'] as int),
      commonName: Value(json['common_name'] as String),
      latinName: Value(json['latin_name'] as String?),
      category: Value(json['category'] as String?),
      subcategory: Value(json['subcategory'] as String?),
      emoji: Value(json['emoji'] as String? ?? '🌳'),
      description: Value(json['description'] as String?),

      // Dimensions
      heightAdultM: Value((json['height_adult_m'] as num?)?.toDouble()),
      spreadAdultM: Value((json['spread_adult_m'] as num?)?.toDouble()),
      growthRate: Value(json['growth_rate'] as String?),
      lifespanYears: Value(json['lifespan_years'] as int?),

      // Rusticité
      hardinessZone: Value(json['hardiness_zone'] as String?),
      coldResistanceCelsius: Value(json['cold_resistance_celsius'] as int?),

      // Conditions
      sunExposure: Value(json['sun_exposure'] as String?),
      soilType: Value(json['soil_type'] as String?),
      soilPh: Value(json['soil_ph'] as String?),
      waterNeeds: Value(json['water_needs'] as String?),
      droughtTolerance: Value(json['drought_tolerance'] as bool? ?? false),

      // Pollinisation
      selfFertile: Value(json['self_fertile'] as bool? ?? false),
      pollinationDetails: Value(json['pollination_details'] as String?),

      // Périodes
      floweringPeriod: Value(json['flowering_period'] as String?),
      harvestPeriod: Value(json['harvest_period'] as String?),
      yearsToFirstFruit: Value(json['years_to_first_fruit'] as int?),
      yieldKgPerTree: Value((json['yield_kg_per_tree'] as num?)?.toDouble()),

      // Plantation
      plantingPeriod: Value(json['planting_period'] as String?),
      plantingDistanceM: Value(
        (json['planting_distance_m'] as num?)?.toDouble(),
      ),

      // Tailles
      pruningTrainingPeriod: Value(json['pruning_training_period'] as String?),
      pruningMaintenancePeriod: Value(
        json['pruning_maintenance_period'] as String?,
      ),

      // Problèmes (stockés en JSON)
      diseases: Value(_encodeList(json['diseases'] as List<dynamic>?)),
      pests: Value(_encodeList(json['pests'] as List<dynamic>?)),

      // Culture en pot
      containerSuitable: Value(json['container_suitable'] as bool? ?? false),
      containerMinSizeL: Value(json['container_min_size_l'] as int?),

      // Variétés
      popularVarieties: Value(
        _encodeList(json['popular_varieties'] as List<dynamic>?),
      ),
    );

    await _db.insertFruitTree(tree);
  }

  /// Encode une liste en JSON string
  String? _encodeList(List<dynamic>? list) {
    if (list == null || list.isEmpty) return null;
    return jsonEncode(list);
  }
}

/// Extension pour décoder les champs JSON des arbres fruitiers
extension FruitTreeJsonExtension on FruitTree {
  /// Décode la liste des maladies
  List<String> get diseasesList {
    if (diseases == null || diseases!.isEmpty) return [];
    try {
      return List<String>.from(jsonDecode(diseases!));
    } catch (_) {
      return [];
    }
  }

  /// Décode la liste des ravageurs
  List<String> get pestsList {
    if (pests == null || pests!.isEmpty) return [];
    try {
      return List<String>.from(jsonDecode(pests!));
    } catch (_) {
      return [];
    }
  }

  /// Décode la liste des variétés populaires
  List<String> get varietiesList {
    if (popularVarieties == null || popularVarieties!.isEmpty) return [];
    try {
      return List<String>.from(jsonDecode(popularVarieties!));
    } catch (_) {
      return [];
    }
  }
}
