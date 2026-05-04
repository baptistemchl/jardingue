// Script one-shot pour seeder les blocs `fertilization` dans plants.json
// et `recommended_pheromone_traps` dans fruit_trees.json (v15).
//
// Idempotent : detecte les entrees deja seedees et les laisse intactes.
// Lance via : `fvm dart run tool/seed_fertilization.dart`
//
// La frequence est inferee de :
// 1. Mots-cles dans `soil_treatment_advice` + `care_advice` :
//    - "riche", "gourmand", "compost regulier", "fumure" → ~21j
//    - "moyen", "modere", "standard"                    → ~30j
//    - "sobre", "pauvre", "peu d'apports"               → ~45j
// 2. Fallback par `category_code` :
//    - fruit_vegetable                                  → 21j
//    - leafy_green                                      → 30j
//    - root, tuber, allium, herb                        → 45j
//    - legume                                           → 60j
//    - fruit                                            → 90j
//    - autre / null                                     → 30j

import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final root = Directory.current.path;
  _seedPlants('$root/assets/data/plants.json');
  _seedFruitTrees('$root/assets/data/fruit_trees.json');
}

void _seedPlants(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('plants.json introuvable: $path');
    exit(1);
  }
  final data = json.decode(file.readAsStringSync()) as Map<String, dynamic>;
  final plants = data['plants'] as List<dynamic>;

  int seeded = 0;
  int skipped = 0;

  for (final raw in plants) {
    final plant = raw as Map<String, dynamic>;
    if (plant.containsKey('fertilization')) {
      skipped++;
      continue;
    }
    final freq = _inferFrequency(plant);
    plant['fertilization'] = {
      'frequency_days': freq,
      'type': _inferType(plant, freq),
      'notes': _inferNotes(plant, freq),
    };
    seeded++;
  }

  // Re-serialize en preservant l'indentation 2 espaces.
  const encoder = JsonEncoder.withIndent('  ');
  file.writeAsStringSync(encoder.convert(data));
  stdout.writeln(
      'plants.json: $seeded plantes seedees, $skipped deja a jour.');
}

void _seedFruitTrees(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('fruit_trees.json introuvable: $path');
    exit(1);
  }
  final data = json.decode(file.readAsStringSync());
  // Le JSON peut etre soit { "fruit_trees": [...] } soit directement [...]
  final trees = data is Map<String, dynamic>
      ? data['fruit_trees'] as List<dynamic>
      : data as List<dynamic>;

  int seeded = 0;
  int skipped = 0;

  for (final raw in trees) {
    final tree = raw as Map<String, dynamic>;
    if (tree.containsKey('recommended_pheromone_traps')) {
      skipped++;
      continue;
    }
    final recommended = _inferTrapTypes(tree);
    tree['recommended_pheromone_traps'] = recommended;
    seeded++;
  }

  const encoder = JsonEncoder.withIndent('  ');
  file.writeAsStringSync(encoder.convert(data));
  stdout.writeln(
      'fruit_trees.json: $seeded arbres seedes, $skipped deja a jour.');
}

int _inferFrequency(Map<String, dynamic> plant) {
  final advice = (plant['soil_treatment_advice'] as String?) ?? '';
  final care = (plant['care_advice'] as String?) ?? '';
  final soil = (plant['soil_type'] as String?) ?? '';
  final text = '$advice $care $soil';
  final lower = text.toLowerCase();

  // Hot signals : plantes gourmandes
  if (lower.contains('gourmand') ||
      lower.contains('riche') ||
      lower.contains('compost regulier') ||
      lower.contains('compost régulier') ||
      lower.contains('fumure') ||
      lower.contains('apport regulier') ||
      lower.contains('apport régulier') ||
      lower.contains('apports reguliers') ||
      lower.contains('apports réguliers')) {
    return 21;
  }
  // Cold signals : plantes sobres
  if (lower.contains('sobre') ||
      lower.contains('pauvre') ||
      lower.contains('peu d\'apport') ||
      lower.contains('rustique') ||
      lower.contains('aride')) {
    return 45;
  }
  // Categorie comme fallback
  return _categoryDefault(plant['category_code'] as String?);
}

int _categoryDefault(String? code) {
  switch (code) {
    case 'fruit_vegetable':
      return 21;
    case 'leafy_green':
      return 30;
    case 'root':
    case 'tuber':
    case 'allium':
    case 'herb':
      return 45;
    case 'legume':
      return 60;
    case 'fruit':
      return 90;
    default:
      return 30;
  }
}

String _inferType(Map<String, dynamic> plant, int freq) {
  if (freq <= 21) return 'compost mûr / engrais organique';
  if (freq <= 45) return 'compost mûr ou purin d\'ortie dilué';
  return 'compost de fond, peu d\'apports';
}

String _inferNotes(Map<String, dynamic> plant, int freq) {
  if (freq <= 21) {
    return 'Plante gourmande : apporter du compost ou un engrais organique '
        'régulièrement, surtout pendant la phase de fructification.';
  }
  if (freq <= 45) {
    return 'Apport modéré : compost mûr en début de saison, complément '
        'au besoin selon l\'aspect des feuilles.';
  }
  return 'Faibles besoins : un apport de fond suffit en général. Eviter '
      'les apports azotés trop fréquents.';
}

/// Infere les types de pieges a pheromones recommandes a partir du nom
/// commun de l'arbre fruitier. La liste des types est synchronisee avec
/// `lib/features/orchard/domain/models/pheromone_trap_type.dart`.
List<String> _inferTrapTypes(Map<String, dynamic> tree) {
  final name = ((tree['common_name'] as String?) ?? '').toLowerCase();
  final pests = ((tree['pests'] as List?)?.cast<dynamic>() ?? const [])
      .map((p) => p.toString().toLowerCase())
      .toList();

  final result = <String>{};
  // Carpocapse : pommier, poirier, noyer, cognassier
  if (name.contains('pomm') ||
      name.contains('poir') ||
      name.contains('noy') ||
      name.contains('cogn') ||
      pests.any((p) => p.contains('carpocapse'))) {
    result.add('codlingMoth');
  }
  // Mouche cerise : cerisier
  if (name.contains('ceris') || pests.any((p) => p.contains('mouche'))) {
    if (name.contains('ceris')) result.add('cherryFruitFly');
  }
  // Tordeuse orientale : pecher, prunier, abricotier
  if (name.contains('pêch') ||
      name.contains('pech') ||
      name.contains('prun') ||
      name.contains('abric')) {
    result.add('orientalFruitMoth');
  }
  // Mouche olive : olivier
  if (name.contains('oliv')) {
    result.add('oliveFly');
  }
  // Mouche du brou : noyer
  if (name.contains('noy')) {
    result.add('walnutHuskFly');
  }
  return result.toList();
}
