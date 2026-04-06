import '../../../../core/services/database/app_database.dart';

/// Modele combinant un arbre utilisateur avec ses details.
class UserFruitTreeWithDetails {
  final UserFruitTree userTree;
  final FruitTree fruitTree;

  const UserFruitTreeWithDetails({
    required this.userTree,
    required this.fruitTree,
  });

  int get id => userTree.id;
  String get name => userTree.nickname ?? fruitTree.commonName;
  String get emoji => fruitTree.emoji;
  String? get variety => userTree.variety;
  DateTime? get plantingDate => userTree.plantingDate;
  String? get location => userTree.location;
  String? get notes => userTree.notes;
  String get healthStatus => userTree.healthStatus;
  DateTime? get lastPruningDate => userTree.lastPruningDate;
  DateTime? get lastHarvestDate => userTree.lastHarvestDate;
  double? get lastYieldKg => userTree.lastYieldKg;
}
