/// Agrégat d'affichage pour une plante donnée dans l'onglet Récoltes.
///
/// Une seule entrée par couple (plantId, unit). Si l'utilisateur a saisi
/// la même plante en `g` puis en `kg`, on les normalise ; les unités
/// incompatibles (pieces vs g) restent séparées.
class HarvestSummary {
  final int plantId;
  final String plantName;
  final String? plantCategoryCode;
  final double totalQuantity;
  final String unit;
  final int harvestCount;
  final DateTime lastHarvestedAt;

  const HarvestSummary({
    required this.plantId,
    required this.plantName,
    required this.plantCategoryCode,
    required this.totalQuantity,
    required this.unit,
    required this.harvestCount,
    required this.lastHarvestedAt,
  });
}

/// Unités supportées. Le code (stocké en DB) est intentionnellement court
/// et stable ; le label affiché passe par l'ARB.
enum HarvestUnit {
  grams('g'),
  kilos('kg'),
  pieces('piece'),
  bunches('bunch');

  final String code;
  const HarvestUnit(this.code);

  static HarvestUnit fromCode(String code) {
    return HarvestUnit.values.firstWhere(
      (u) => u.code == code,
      orElse: () => HarvestUnit.pieces,
    );
  }
}
