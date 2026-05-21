/// Metadata about a cloud backup.
class BackupMetadata {
  final DateTime createdAt;
  final int gardenCount;
  final int plantCount;
  final int eventCount;
  final int treeCount;
  final int userPlantCount;
  // Carnet de bord (v1.7.4+). Absents des backups antérieurs → 0.
  final int harvestCount;
  final int seedlingCount;
  final int journalEntryCount;

  const BackupMetadata({
    required this.createdAt,
    required this.gardenCount,
    required this.plantCount,
    required this.eventCount,
    required this.treeCount,
    this.userPlantCount = 0,
    this.harvestCount = 0,
    this.seedlingCount = 0,
    this.journalEntryCount = 0,
  });

  int get totalItems =>
      gardenCount +
      plantCount +
      eventCount +
      treeCount +
      userPlantCount +
      harvestCount +
      seedlingCount +
      journalEntryCount;
}
