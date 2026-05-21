import 'dart:math' as math;

import '../../../core/services/database/app_database.dart';
import '../../../core/services/database/plant_import_service.dart';
import 'models/garden_plant_with_details.dart';

/// Conflit détecté entre la plante en cours de placement et une voisine
/// déjà présente dans le potager.
class AntagonistConflict {
  /// Nom commun de la plante voisine (pour le message du dialog).
  final String neighborPlantName;

  /// Motif extrait depuis l'intersection des `main_destroyers` (maladies +
  /// ravageurs) des deux plantes. `null` si aucune intersection trouvée :
  /// on tombera sur un message générique côté UI.
  final String? reason;

  const AntagonistConflict({
    required this.neighborPlantName,
    this.reason,
  });
}

/// Suggestion de plante compagne (utilisée par la bottom sheet
/// CompanionSuggestionsSheet).
class CompanionSuggestion {
  final int plantId;
  final String commonName;
  final String? categoryCode;

  const CompanionSuggestion({
    required this.plantId,
    required this.commonName,
    this.categoryCode,
  });
}

/// Service pur (stateless, sans IO) qui calcule la guidance de
/// compagnonnage : conflits d'antagonistes voisins et suggestions de
/// plantes compagnes.
///
/// Décorrélé de Riverpod / Drift : les call sites lui passent les données
/// déjà chargées via les providers. Testable unitairement.
class CompanionGuidanceService {
  const CompanionGuidanceService();

  /// Détecte les voisins antagonistes dont la distance avec la cible est
  /// inférieure à la moyenne des spacings (= recouvrement de la zone
  /// nominale d'espacement).
  ///
  /// La distance est calculée entre les centres géométriques des cellules
  /// occupées (en cm). Pour une plante de [width × height] cellules à
  /// (gridX, gridY), le centre est (gridX + width/2, gridY + height/2).
  ///
  /// [excludeGardenPlantId] sert à ignorer la position actuelle de la
  /// plante quand on la déplace (elle ne déclenche pas un conflit avec
  /// elle-même).
  List<AntagonistConflict> findConflictsAt({
    required Plant sourcePlant,
    required int sourceGridX,
    required int sourceGridY,
    required int sourceWidthCells,
    required int sourceHeightCells,
    required Iterable<GardenPlantWithDetails> existingPlants,
    required Set<int> antagonistsOfSource,
    required int cellSizeCm,
    int? excludeGardenPlantId,
  }) {
    if (antagonistsOfSource.isEmpty) return const [];

    final sourceSpacing = sourcePlant.spacingBetweenPlants ?? 0;
    final sourceCxCm =
        (sourceGridX + sourceWidthCells / 2.0) * cellSizeCm;
    final sourceCyCm =
        (sourceGridY + sourceHeightCells / 2.0) * cellSizeCm;

    final conflicts = <AntagonistConflict>[];

    for (final neighbor in existingPlants) {
      if (neighbor.isZone) continue;
      if (neighbor.isPendingPlacement) continue;
      if (excludeGardenPlantId != null && neighbor.id == excludeGardenPlantId) {
        continue;
      }
      final neighborPlant = neighbor.plant;
      if (neighborPlant == null) continue;

      if (!antagonistsOfSource.contains(neighbor.gardenPlant.plantId)) continue;

      final neighborSpacing = neighborPlant.spacingBetweenPlants ?? 0;
      // Moyenne des spacings × 1.5 = marge horticole (les antagonismes
      // type mildiou se propagent au-delà du strict espacement nominal).
      // Plancher à 50 cm pour rester utile même avec des grosses
      // cellules : sans ce min, deux petites plantes posées côte à côte
      // sur une grille à cellSize=100cm ne déclenchent jamais (distance
      // centres > spacing combiné).
      final averageSpacing = (sourceSpacing + neighborSpacing) / 2.0;
      final requiredCm = math.max(averageSpacing * 1.5, 50.0);
      final neighborCxCm =
          (neighbor.gridX + neighbor.widthCells / 2.0) * cellSizeCm;
      final neighborCyCm =
          (neighbor.gridY + neighbor.heightCells / 2.0) * cellSizeCm;

      final dxCm = sourceCxCm - neighborCxCm;
      final dyCm = sourceCyCm - neighborCyCm;
      final distanceCm = math.sqrt(dxCm * dxCm + dyCm * dyCm);

      if (distanceCm < requiredCm) {
        conflicts.add(
          AntagonistConflict(
            neighborPlantName: neighborPlant.commonName,
            reason: _commonProblem(sourcePlant, neighborPlant),
          ),
        );
      }
    }

    return conflicts;
  }

  /// Filtre les compagnons déjà présents dans le potager. Garde l'ordre
  /// du catalogue (JSON / DB) : on ne tri pas par pertinence en V1.
  List<CompanionSuggestion> companionsToSuggest({
    required List<Plant> companions,
    required Set<int> alreadyInGardenPlantIds,
  }) {
    if (companions.isEmpty) return const [];
    return companions
        .where((p) => !alreadyInGardenPlantIds.contains(p.id))
        .map(
          (p) => CompanionSuggestion(
            plantId: p.id,
            commonName: p.commonName,
            categoryCode: p.categoryCode,
          ),
        )
        .toList();
  }

  /// Cherche un problème partagé entre deux plantes via l'intersection
  /// de leurs `main_destroyers` (maladies + ravageurs combinés). Retourne
  /// le premier matchant pour ne pas surcharger le message, ou `null` si
  /// aucune intersection.
  String? _commonProblem(Plant a, Plant b) {
    final aDestroyers = a.destroyersList.map(_normalize).toSet();
    final bDestroyers = b.destroyersList.map(_normalize).toSet();
    final intersection = aDestroyers.intersection(bDestroyers);
    if (intersection.isEmpty) return null;
    // On reprend le libellé d'origine (non normalisé) côté A pour garder
    // les accents et la casse.
    for (final raw in a.destroyersList) {
      if (intersection.contains(_normalize(raw))) {
        return raw;
      }
    }
    return null;
  }

  /// Normalise pour comparer les destroyers entre deux plantes : lowercase
  /// + retrait des parenthèses descriptives (« mildiou (champignon) » →
  /// « mildiou »).
  String _normalize(String raw) {
    final lower = raw.toLowerCase().trim();
    final parenIdx = lower.indexOf('(');
    if (parenIdx > 0) {
      return lower.substring(0, parenIdx).trim();
    }
    return lower;
  }
}
