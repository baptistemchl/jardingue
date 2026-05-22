/// Agrégats statistiques pour l'onglet Stats du Carnet de bord.
class CarnetStats {
  /// Année des stats.
  final int year;

  /// Total cumulé en équivalent kg (g/1000 + kg). Approximatif —
  /// agrège uniquement les unités de poids (g + kg), pas les pièces.
  final double totalWeightKg;

  /// Total en pièces (unit='piece').
  final int totalPieces;

  /// Total en bottes (unit='bunch').
  final int totalBunches;

  /// Nombre total de récoltes (toutes unités confondues).
  final int totalHarvestCount;

  /// 12 valeurs : nombre de récoltes par mois (jan=index 0 → déc=index 11).
  final List<int> harvestsByMonth;

  /// Top 5 plantes par nombre de récoltes.
  final List<TopPlant> topPlants;

  /// Nombre de semis créés cette année.
  final int seedlingsTotal;

  /// Nombre de semis repiqués avec succès.
  final int seedlingsTransplanted;

  /// Nombre de semis échoués.
  final int seedlingsFailed;

  /// Nombre de notes journal cette année.
  final int journalEntriesCount;

  /// Mois avec le plus de récoltes (1-12) ou null si rien.
  final int? bestMonth;

  /// Plante la plus récoltée (top 1) ou null.
  final TopPlant? plantOfTheYear;

  /// Activités du jardin (GardenEvents) — agrégats par eventType pour
  /// l'année en cours : arrosages, fertilisations, semis, plantations,
  /// paillages, traitements, etc.
  final int wateringCount;
  final int fertilizingCount;
  final int sowingEventsCount;
  final int plantingEventsCount;
  final int mulchingCount;
  final int otherCareCount;

  const CarnetStats({
    required this.year,
    required this.totalWeightKg,
    required this.totalPieces,
    required this.totalBunches,
    required this.totalHarvestCount,
    required this.harvestsByMonth,
    required this.topPlants,
    required this.seedlingsTotal,
    required this.seedlingsTransplanted,
    required this.seedlingsFailed,
    required this.journalEntriesCount,
    required this.bestMonth,
    required this.plantOfTheYear,
    this.wateringCount = 0,
    this.fertilizingCount = 0,
    this.sowingEventsCount = 0,
    this.plantingEventsCount = 0,
    this.mulchingCount = 0,
    this.otherCareCount = 0,
  });

  /// Total activités jardin (toutes catégories confondues).
  int get totalGardenActivities =>
      wateringCount +
      fertilizingCount +
      sowingEventsCount +
      plantingEventsCount +
      mulchingCount +
      otherCareCount;

  /// Taux de succès des semis (0.0 à 1.0). 1.0 si pas de semis.
  double get seedlingSuccessRate {
    final terminal = seedlingsTransplanted + seedlingsFailed;
    if (terminal == 0) return 0;
    return seedlingsTransplanted / terminal;
  }

  bool get isEmpty =>
      totalHarvestCount == 0 &&
      seedlingsTotal == 0 &&
      journalEntriesCount == 0 &&
      totalGardenActivities == 0;
}

class TopPlant {
  final int plantId;
  final String plantName;
  final String? plantCategoryCode;
  final int harvestCount;

  const TopPlant({
    required this.plantId,
    required this.plantName,
    required this.plantCategoryCode,
    required this.harvestCount,
  });
}
