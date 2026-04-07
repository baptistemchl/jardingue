import 'backup_metadata.dart';

/// Full backup payload for cloud storage.
class BackupData {
  final BackupMetadata metadata;
  final List<Map<String, dynamic>> gardens;
  final List<Map<String, dynamic>> gardenPlants;
  final List<Map<String, dynamic>> gardenEvents;
  final List<Map<String, dynamic>> userFruitTrees;

  const BackupData({
    required this.metadata,
    required this.gardens,
    required this.gardenPlants,
    required this.gardenEvents,
    required this.userFruitTrees,
  });
}
