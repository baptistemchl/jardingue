import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'app_database.dart';

/// Service pour importer les données JSON dans la base de données
class PlantImportService {
  final AppDatabase _db;

  PlantImportService(this._db);

  /// Importe les plantes depuis le fichier JSON des assets
  /// Retourne le nombre de plantes importées
  Future<int> importFromAssets({bool forceReimport = false}) async {
    // Vérifie si les données existent déjà
    final existingCount = await _db.countPlants();
    if (existingCount > 0 && !forceReimport) {
      print('📦 Base de données déjà peuplée ($existingCount plantes)');
      return existingCount;
    }

    print('🌱 Début de l\'import des plantes...');

    // Charge le fichier JSON
    final jsonString = await rootBundle.loadString('assets/data/plants.json');
    final jsonData = json.decode(jsonString) as Map<String, dynamic>;
    final plantsJson = jsonData['plants'] as List<dynamic>;

    // Nettoie les tables si réimport forcé
    if (forceReimport) {
      await _db.deleteAllAntagonists();
      await _db.deleteAllCompanions();
      await _db.deleteAllPlants();
      print('🗑️ Tables nettoyées');
    }

    int importedCount = 0;

    // Importe chaque plante
    for (final plantJson in plantsJson) {
      try {
        await _importPlant(plantJson as Map<String, dynamic>);
        importedCount++;
      } catch (e) {
        print('❌ Erreur import plante ${plantJson['common_name']}: $e');
      }
    }

    // Importe les relations (compagnons et antagonistes)
    for (final plantJson in plantsJson) {
      try {
        await _importRelations(plantJson as Map<String, dynamic>);
      } catch (e) {
        print('❌ Erreur import relations ${plantJson['common_name']}: $e');
      }
    }

    print('✅ Import terminé: $importedCount plantes');
    return importedCount;
  }

  /// Importe une plante depuis le JSON
  Future<void> _importPlant(Map<String, dynamic> json) async {
    final plant = PlantsCompanion(
      id: Value(json['id'] as int),
      commonName: Value(json['common_name'] as String),
      latinName: Value(json['latin_name'] as String?),

      // Catégorie
      categoryCode: Value(json['category_code'] as String?),
      categoryLabel: Value(json['category_label'] as String?),

      // Espacements
      spacingBetweenPlants: Value(json['spacing_cm_between_plants'] as int?),
      spacingBetweenRows: Value(json['spacing_cm_between_rows'] as int?),
      plantingDepthCm: Value(json['planting_depth_cm'] as int?),

      // Conditions
      sunExposure: Value(json['sun_exposure'] as String?),
      soilMoisturePreference: Value(
        json['soil_moisture_preference'] as String?,
      ),
      soilTreatmentAdvice: Value(json['soil_treatment_advice'] as String?),
      soilType: Value(json['soil_type'] as String?),
      growingZone: Value(json['growing_zone'] as String?),
      watering: Value(json['watering'] as String?),

      // Température
      plantingMinTempC: Value(json['planting_min_temp_c'] as int?),
      plantingWeatherConditions: Value(
        json['planting_weather_conditions'] as String?,
      ),

      // Périodes
      sowingUnderCoverPeriod: Value(
        json['sowing_under_cover_period'] as String?,
      ),
      sowingOpenGroundPeriod: Value(
        json['sowing_open_ground_period'] as String?,
      ),
      transplantingPeriod: Value(json['transplanting_period'] as String?),
      harvestPeriod: Value(json['harvest_period'] as String?),

      // Conseils
      sowingRecommendation: Value(json['sowing_recommendation'] as String?),
      cultivationGreenhouse: Value(json['cultivation_greenhouse'] as String?),
      plantingAdvice: Value(json['planting_advice'] as String?),
      careAdvice: Value(json['care_advice'] as String?),
      redFlags: Value(json['red_flags'] as String?),

      // Nuisibles (JSON encodé)
      mainDestroyers: Value(_encodeList(json['main_destroyers'])),

      // Calendriers (JSON encodé)
      sowingCalendar: Value(_encodeMap(json['sowing_calendar'])),
      plantingCalendar: Value(_encodeMap(json['planting_calendar'])),
      harvestCalendar: Value(_encodeMap(json['harvest_calendar'])),
    );

    await _db.insertPlant(plant);
  }

  /// Importe les relations compagnons/antagonistes
  Future<void> _importRelations(Map<String, dynamic> json) async {
    final plantId = json['id'] as int;

    // Compagnons
    final companionIds = json['companion_plant_ids'] as List<dynamic>?;
    if (companionIds != null) {
      for (final companionId in companionIds) {
        if (companionId != null) {
          await _db.insertCompanion(plantId, companionId as int);
        }
      }
    }

    // Antagonistes
    final antagonistIds = json['antagonistic_plant_ids'] as List<dynamic>?;
    if (antagonistIds != null) {
      for (final antagonistId in antagonistIds) {
        if (antagonistId != null) {
          await _db.insertAntagonist(plantId, antagonistId as int);
        }
      }
    }
  }

  /// Encode une liste en JSON string
  String? _encodeList(dynamic list) {
    if (list == null) return null;
    return json.encode(list);
  }

  /// Encode une map en JSON string
  String? _encodeMap(dynamic map) {
    if (map == null) return null;
    return json.encode(map);
  }
}

/// Extension pour décoder les champs JSON des plantes
extension PlantJsonExtension on Plant {
  /// Décode la liste des nuisibles
  List<String> get destroyersList {
    if (mainDestroyers == null) return [];
    try {
      final decoded = json.decode(mainDestroyers!) as List<dynamic>;
      return decoded.cast<String>();
    } catch (_) {
      return [];
    }
  }

  /// Décode le calendrier de semis
  Map<String, dynamic>? get sowingCalendarMap {
    if (sowingCalendar == null) return null;
    try {
      return json.decode(sowingCalendar!) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Décode le calendrier de plantation
  Map<String, dynamic>? get plantingCalendarMap {
    if (plantingCalendar == null) return null;
    try {
      return json.decode(plantingCalendar!) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Décode le calendrier de récolte
  Map<String, dynamic>? get harvestCalendarMap {
    if (harvestCalendar == null) return null;
    try {
      return json.decode(harvestCalendar!) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Retourne les mois de semis
  List<String> get sowingMonths {
    final calendar = sowingCalendarMap;
    if (calendar == null) return [];
    final monthly = calendar['monthly_period'] as Map<String, dynamic>?;
    if (monthly == null) return [];
    return monthly.entries
        .where((e) => e.value.toString().startsWith('Oui'))
        .map((e) => e.key)
        .toList();
  }

  /// Retourne les mois de plantation
  List<String> get plantingMonths {
    final calendar = plantingCalendarMap;
    if (calendar == null) return [];
    final monthly = calendar['monthly_period'] as Map<String, dynamic>?;
    if (monthly == null) return [];
    return monthly.entries
        .where((e) => e.value.toString().startsWith('Oui'))
        .map((e) => e.key)
        .toList();
  }

  /// Retourne les mois de récolte
  List<String> get harvestMonths {
    final calendar = harvestCalendarMap;
    if (calendar == null) return [];
    final monthly = calendar['monthly_period'] as Map<String, dynamic>?;
    if (monthly == null) return [];
    return monthly.entries
        .where((e) => e.value.toString().startsWith('Oui'))
        .map((e) => e.key)
        .toList();
  }
}
