import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../core/services/database/app_database.dart';
import '../../domain/models/seedling_status.dart';

/// Tous les semis (live).
final allSeedlingsProvider = StreamProvider<List<Seedling>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllSeedlings();
});

/// Lookup plante → emoji/name. Réutilise le provider d'harvest si dispo
/// mais ici on en refait un pour rester indépendant.
final seedlingPlantsLookupProvider =
    FutureProvider<Map<int, Plant>>((ref) async {
  final db = ref.watch(databaseProvider);
  final list = await db.getAllPlants();
  return {for (final p in list) p.id: p};
});

/// Semis regroupés par statut. Les listes vides ne sont pas retirées
/// (ça permet de toujours afficher les sections dans l'UI dans le même
/// ordre).
final seedlingsByStatusProvider =
    Provider<Map<SeedlingStatus, List<Seedling>>>((ref) {
  final async = ref.watch(allSeedlingsProvider);
  final list = async.value ?? const <Seedling>[];
  final grouped = {for (final s in SeedlingStatus.values) s: <Seedling>[]};
  for (final s in list) {
    final status = SeedlingStatus.fromCode(s.status);
    grouped[status]!.add(s);
  }
  return grouped;
});
