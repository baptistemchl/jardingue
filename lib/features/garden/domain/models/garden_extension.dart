import '../../../../core/services/database/app_database.dart';

/// Extensions utilitaires pour le modele Garden de Drift.
extension GardenExtension on Garden {
  double get widthMeters => widthCells * cellSizeCm / 100;
  double get heightMeters => heightCells * cellSizeCm / 100;
  double get surfaceM2 => widthMeters * heightMeters;
}
