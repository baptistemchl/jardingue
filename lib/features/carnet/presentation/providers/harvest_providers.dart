import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../core/services/database/app_database.dart';
import '../../domain/models/harvest_summary.dart';

/// Année courante du carnet — par défaut l'année système, l'UI peut la
/// modifier plus tard si on ajoute un sélecteur d'années.
class HarvestYearNotifier extends Notifier<int> {
  @override
  int build() => DateTime.now().year;
  void set(int year) => state = year;
}

final harvestYearProvider =
    NotifierProvider<HarvestYearNotifier, int>(HarvestYearNotifier.new);

/// Stream brut des récoltes pour l'année sélectionnée. Recharge auto
/// quand on change harvestYearProvider.
final harvestsForYearProvider = StreamProvider<List<Harvest>>((ref) {
  final db = ref.watch(databaseProvider);
  final year = ref.watch(harvestYearProvider);
  return db.watchHarvestsForYear(year);
});

/// Liste des plantes (catalogue) — chargé une fois pour résoudre les
/// plantName/category quand on construit l'agrégat. Les ids catalogue
/// sont stables sur la durée de vie d'une session.
final harvestPlantsLookupProvider = FutureProvider<Map<int, Plant>>((ref) async {
  final db = ref.watch(databaseProvider);
  final list = await db.getAllPlants();
  return {for (final p in list) p.id: p};
});

/// Agrégat par plante × unité affiché dans l'onglet Récoltes. Trié par
/// dernière date de récolte décroissante (plus récent en haut).
final harvestSummariesProvider = Provider<List<HarvestSummary>>((ref) {
  final harvestsAsync = ref.watch(harvestsForYearProvider);
  final plantsAsync = ref.watch(harvestPlantsLookupProvider);

  // Synchrone (ref.watch avant tout await) — Riverpod async rule.
  final harvests = harvestsAsync.value;
  final plants = plantsAsync.value;
  if (harvests == null || plants == null) return const [];

  // Agrégation in-memory. Le volume reste faible (qq centaines de lignes
  // par année max) donc pas la peine de faire un GROUP BY SQL.
  final byKey = <String, _Acc>{};
  for (final h in harvests) {
    final key = '${h.plantId}|${h.unit}';
    final acc = byKey.putIfAbsent(key, () => _Acc(h.plantId, h.unit));
    acc.total += h.quantity;
    acc.count += 1;
    if (acc.lastDate == null || h.harvestedAt.isAfter(acc.lastDate!)) {
      acc.lastDate = h.harvestedAt;
    }
  }

  final summaries = <HarvestSummary>[];
  for (final acc in byKey.values) {
    final plant = plants[acc.plantId];
    if (plant == null) continue;
    summaries.add(HarvestSummary(
      plantId: acc.plantId,
      plantName: plant.commonName,
      plantCategoryCode: plant.categoryCode,
      totalQuantity: acc.total,
      unit: acc.unit,
      harvestCount: acc.count,
      lastHarvestedAt: acc.lastDate!,
    ));
  }
  summaries.sort((a, b) => b.lastHarvestedAt.compareTo(a.lastHarvestedAt));
  return summaries;
});

class _Acc {
  final int plantId;
  final String unit;
  double total = 0;
  int count = 0;
  DateTime? lastDate;
  _Acc(this.plantId, this.unit);
}
