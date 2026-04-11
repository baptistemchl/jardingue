class SelectedPlant {
  final int plantId;
  final String commonName;
  final String? categoryCode;
  final DateTime addedAt;

  const SelectedPlant({
    required this.plantId,
    required this.commonName,
    this.categoryCode,
    required this.addedAt,
  });
}
