import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/database/app_database.dart';
import '../../domain/models/carnet_stats.dart';
import 'harvest_providers.dart';
import 'journal_providers.dart';
import 'seedling_providers.dart';

/// Stats agrégées de l'année courante (synchrones, basées sur les
/// streams Riverpod déjà en place).
final carnetStatsProvider = Provider<CarnetStats>((ref) {
  final year = ref.watch(harvestYearProvider);
  final harvestsAsync = ref.watch(harvestsForYearProvider);
  final plantsAsync = ref.watch(harvestPlantsLookupProvider);
  final seedlingsAsync = ref.watch(allSeedlingsProvider);
  final journalAsync = ref.watch(allJournalEntriesProvider);

  // ref.watch synchrone avant tout await — Riverpod async rule.
  final harvests = harvestsAsync.value ?? const <Harvest>[];
  final plants = plantsAsync.value ?? const <int, Plant>{};
  final seedlings = seedlingsAsync.value ?? const <Seedling>[];
  final journal = journalAsync.value ?? const <JournalEntry>[];

  // Poids cumulé en kg-équivalent + autres unités.
  double totalKg = 0;
  int totalPieces = 0;
  int totalBunches = 0;
  final monthly = List<int>.filled(12, 0);
  final byPlant = <int, int>{}; // plantId → count
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
    byPlant[h.plantId] = (byPlant[h.plantId] ?? 0) + 1;
  }

  // Top 5 plantes par nombre de récoltes.
  final topEntries = byPlant.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final topPlants = <TopPlant>[];
  for (final entry in topEntries.take(5)) {
    final plant = plants[entry.key];
    if (plant == null) continue;
    topPlants.add(TopPlant(
      plantId: entry.key,
      plantName: plant.commonName,
      plantCategoryCode: plant.categoryCode,
      harvestCount: entry.value,
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
  );
});
