import 'backup_metadata.dart';

/// Full backup payload for cloud storage.
///
/// Les listes `userPlants` / `userPlantCompanions` / `userPlantAntagonists`
/// ont été ajoutées pour préserver les plantes créées par l'utilisateur
/// au travers d'un cycle export/restore : sans ces listes, un
/// `gardenPlants` qui référence une plante user produit une FK orpheline
/// après restore (la table Plants n'est pas reconstituée par le restore,
/// seul le catalogue est repeuplé via le seed JSON).
class BackupData {
  final BackupMetadata metadata;
  final List<Map<String, dynamic>> gardens;
  final List<Map<String, dynamic>> gardenPlants;
  final List<Map<String, dynamic>> gardenEvents;
  final List<Map<String, dynamic>> userFruitTrees;
  final List<Map<String, dynamic>> userPlants;
  final List<Map<String, dynamic>> userPlantCompanions;
  final List<Map<String, dynamic>> userPlantAntagonists;
  // Carnet de bord (v1.7.4+). Absent des backups antérieurs → listes vides
  // par défaut, l'import devient un no-op rétrocompatible.
  final List<Map<String, dynamic>> harvests;
  final List<Map<String, dynamic>> seedlings;
  final List<Map<String, dynamic>> journalEntries;

  const BackupData({
    required this.metadata,
    required this.gardens,
    required this.gardenPlants,
    required this.gardenEvents,
    required this.userFruitTrees,
    this.userPlants = const [],
    this.userPlantCompanions = const [],
    this.userPlantAntagonists = const [],
    this.harvests = const [],
    this.seedlings = const [],
    this.journalEntries = const [],
  });
}
