import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../core/services/database/app_database.dart';
import '../../domain/models/carnet_stats.dart';
import 'harvest_providers.dart';
import 'journal_providers.dart';
import 'seedling_providers.dart';

/// Mode de tri courant du classement TOP DES PLANTES.
class TopPlantsSortNotifier extends Notifier<TopPlantsSortMode> {
  @override
  TopPlantsSortMode build() => TopPlantsSortMode.weight;
  void set(TopPlantsSortMode mode) => state = mode;
}

final topPlantsSortProvider =
    NotifierProvider<TopPlantsSortNotifier, TopPlantsSortMode>(
  TopPlantsSortNotifier.new,
);

/// Stream brut des GardenEvents — utilisé par le carnetStatsProvider
/// pour agréger les arrosages, fertilisations, etc.
final allGardenEventsProvider =
    StreamProvider<List<GardenEvent>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.gardenEvents)).watch();
});

/// Stats agrégées de l'année courante (synchrones, basées sur les
/// streams Riverpod déjà en place).
final carnetStatsProvider = Provider<CarnetStats>((ref) {
  final year = ref.watch(harvestYearProvider);
  final harvestsAsync = ref.watch(harvestsForYearProvider);
  final plantsAsync = ref.watch(harvestPlantsLookupProvider);
  final seedlingsAsync = ref.watch(allSeedlingsProvider);
  final journalAsync = ref.watch(allJournalEntriesProvider);
  final gardenEventsAsync = ref.watch(allGardenEventsProvider);

  // ref.watch synchrone avant tout await — Riverpod async rule.
  final harvests = harvestsAsync.value ?? const <Harvest>[];
  final plants = plantsAsync.value ?? const <int, Plant>{};
  final seedlings = seedlingsAsync.value ?? const <Seedling>[];
  final journal = journalAsync.value ?? const <JournalEntry>[];
  final gardenEvents = gardenEventsAsync.value ?? const <GardenEvent>[];

  // Poids cumulé en kg-équivalent + autres unités.
  double totalKg = 0;
  int totalPieces = 0;
  int totalBunches = 0;
  final monthly = List<int>.filled(12, 0);
  // Agrégat par plante : count + totaux par unité, pour pouvoir trier
  // selon le mode choisi par l'UI sans relire la DB.
  final byPlant = <int, _PlantAgg>{};
  for (final h in harvests) {
    switch (h.unit) {
      case 'g':
        totalKg += h.quantity / 1000.0;
      case 'kg':
        totalKg += h.quantity;
      case 'piece':
        totalPieces += h.quantity.round();
      case 'bunch':
        totalBunches += h.quantity.round();
    }
    monthly[h.harvestedAt.month - 1] += 1;
    final agg = byPlant.putIfAbsent(h.plantId, () => _PlantAgg());
    agg.count += 1;
    switch (h.unit) {
      case 'g':
        agg.kg += h.quantity / 1000.0;
      case 'kg':
        agg.kg += h.quantity;
      case 'piece':
        agg.pieces += h.quantity.round();
      case 'bunch':
        agg.bunches += h.quantity.round();
    }
  }

  // Mode de tri lu en sync (Riverpod rule). Tri appliqué sur l'agrégat
  // par plante. Le top 5 est calculé après tri pour servir la carte.
  final sortMode = ref.watch(topPlantsSortProvider);
  final topEntries = byPlant.entries.toList();
  int compareDesc(num a, num b) => b.compareTo(a);
  switch (sortMode) {
    case TopPlantsSortMode.count:
      topEntries.sort((a, b) => compareDesc(a.value.count, b.value.count));
    case TopPlantsSortMode.weight:
      topEntries.sort((a, b) => compareDesc(a.value.kg, b.value.kg));
    case TopPlantsSortMode.pieces:
      topEntries.sort((a, b) => compareDesc(a.value.pieces, b.value.pieces));
    case TopPlantsSortMode.bunches:
      topEntries
          .sort((a, b) => compareDesc(a.value.bunches, b.value.bunches));
  }
  final topPlants = <TopPlant>[];
  for (final entry in topEntries.take(5)) {
    final plant = plants[entry.key];
    if (plant == null) continue;
    topPlants.add(TopPlant(
      plantId: entry.key,
      plantName: plant.commonName,
      plantCategoryCode: plant.categoryCode,
      harvestCount: entry.value.count,
      totalKg: entry.value.kg,
      totalPieces: entry.value.pieces,
      totalBunches: entry.value.bunches,
    ));
  }

  // Semis : on filtre par année de createdAt pour rester cohérent avec
  // l'année visible (la saisie déclare l'année du semis).
  final yearSeedlings =
      seedlings.where((s) => s.sowedAt.year == year).toList();
  final transplanted = yearSeedlings
      .where((s) => s.status == 'transplanted')
      .length;
  final failed =
      yearSeedlings.where((s) => s.status == 'failed').length;

  final yearJournal =
      journal.where((j) => j.entryDate.year == year).length;

  int? bestMonth;
  int bestMonthCount = 0;
  for (var i = 0; i < 12; i++) {
    if (monthly[i] > bestMonthCount) {
      bestMonthCount = monthly[i];
      bestMonth = i + 1;
    }
  }

  // Activités jardin (GardenEvents) — agrégat par eventType, filtré sur
  // l'année courante. Les eventType inconnus tombent dans otherCare.
  var watering = 0,
      wateringSeedling = 0,
      fertilizing = 0,
      sowingEv = 0,
      plantingEv = 0,
      mulching = 0,
      other = 0;
  for (final ev in gardenEvents) {
    if (ev.eventDate.year != year) continue;
    switch (ev.eventType) {
      case 'watering':
        watering++;
      case 'watering_seedling':
        wateringSeedling++;
      case 'fertilizing':
        fertilizing++;
      case 'sowing':
        sowingEv++;
      case 'planting':
        plantingEv++;
      case 'mulching':
        mulching++;
      default:
        other++;
    }
  }

  return CarnetStats(
    year: year,
    totalWeightKg: totalKg,
    totalPieces: totalPieces,
    totalBunches: totalBunches,
    totalHarvestCount: harvests.length,
    harvestsByMonth: monthly,
    topPlants: topPlants,
    seedlingsTotal: yearSeedlings.length,
    seedlingsTransplanted: transplanted,
    seedlingsFailed: failed,
    journalEntriesCount: yearJournal,
    bestMonth: bestMonth,
    plantOfTheYear: topPlants.isNotEmpty ? topPlants.first : null,
    wateringCount: watering,
    wateringSeedlingCount: wateringSeedling,
    fertilizingCount: fertilizing,
    sowingEventsCount: sowingEv,
    plantingEventsCount: plantingEv,
    mulchingCount: mulching,
    otherCareCount: other,
  );
});

class _PlantAgg {
  int count = 0;
  double kg = 0;
  int pieces = 0;
  int bunches = 0;
}
