import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Verifie que le seeding du bloc `fertilization` (script v15) a bien ete
/// applique sur tous les fichiers JSON. Garde-fou contre :
/// - une plante ajoutee au catalogue sans fertilisation
/// - un fruitier sans `recommended_pheromone_traps`
/// - une frequence absurde (negative, > 1 an, etc.)
void main() {
  group('plants.json fertilization seeding', () {
    late List<Map<String, dynamic>> plants;

    setUpAll(() async {
      final file = File('assets/data/plants.json');
      expect(file.existsSync(), isTrue,
          reason: 'plants.json doit exister a la racine du projet');
      final data =
          json.decode(await file.readAsString()) as Map<String, dynamic>;
      plants = (data['plants'] as List).cast<Map<String, dynamic>>();
    });

    test('toutes les plantes ont un bloc fertilization', () {
      final missing = plants
          .where((p) => p['fertilization'] is! Map)
          .map((p) => '${p['id']} (${p['common_name']})')
          .toList();
      expect(missing, isEmpty,
          reason: 'Plantes sans bloc fertilization : $missing');
    });

    test('frequency_days est un entier dans une plage realiste (7-365)', () {
      final invalid = <String>[];
      for (final p in plants) {
        final block = p['fertilization'] as Map<String, dynamic>;
        final freq = block['frequency_days'];
        if (freq is! int) {
          invalid.add('${p['common_name']}: type ${freq.runtimeType}');
        } else if (freq < 7 || freq > 365) {
          invalid.add('${p['common_name']}: freq=$freq (hors plage 7-365)');
        }
      }
      expect(invalid, isEmpty, reason: 'Frequences invalides : $invalid');
    });

    test('type et notes sont des strings non vides', () {
      final invalid = <String>[];
      for (final p in plants) {
        final block = p['fertilization'] as Map<String, dynamic>;
        final type = block['type'];
        final notes = block['notes'];
        if (type is! String || type.isEmpty) {
          invalid.add('${p['common_name']}: type vide');
        }
        if (notes is! String || notes.isEmpty) {
          invalid.add('${p['common_name']}: notes vides');
        }
      }
      expect(invalid, isEmpty, reason: 'Champs vides : $invalid');
    });

    test('plantes gourmandes (fruit_vegetable) ont une freq <= 30j', () {
      // Verifie l'inference categorielle : tomate, courgette, etc. doivent
      // avoir une frequence courte (apports rapproches en pleine production).
      final outliers = plants.where((p) {
        if (p['category_code'] != 'fruit_vegetable') return false;
        final freq = (p['fertilization'] as Map)['frequency_days'] as int;
        return freq > 30;
      }).toList();
      expect(outliers, isEmpty,
          reason:
              'Les fruit_vegetable doivent etre fertilises au moins tous les 30j');
    });
  });

  group('fruit_trees.json pheromone traps seeding', () {
    late List<Map<String, dynamic>> trees;

    /// Liste des `name` valides de PheromoneTrapType (synchronisee avec
    /// `lib/features/orchard/domain/models/pheromone_trap_type.dart`).
    /// Si on ajoute un type, il faut l'ajouter ici aussi.
    const validTrapTypes = {
      'codlingMoth',
      'cherryFruitFly',
      'orientalFruitMoth',
      'oliveFly',
      'walnutHuskFly',
    };

    setUpAll(() async {
      final file = File('assets/data/fruit_trees.json');
      expect(file.existsSync(), isTrue);
      final data = json.decode(await file.readAsString());
      // Le JSON peut etre soit un objet wrappe soit un array direct
      trees = (data is Map<String, dynamic>
              ? data['fruit_trees'] as List
              : data as List)
          .cast<Map<String, dynamic>>();
    });

    test('tous les fruitiers ont un champ recommended_pheromone_traps', () {
      final missing = trees
          .where((t) => t['recommended_pheromone_traps'] is! List)
          .map((t) => t['common_name'])
          .toList();
      expect(missing, isEmpty,
          reason: 'Arbres sans recommended_pheromone_traps : $missing');
    });

    test('les types recommandes correspondent a l\'enum PheromoneTrapType',
        () {
      final invalid = <String>[];
      for (final t in trees) {
        final list = (t['recommended_pheromone_traps'] as List).cast<String>();
        for (final type in list) {
          if (!validTrapTypes.contains(type)) {
            invalid.add('${t['common_name']}: type "$type" inconnu');
          }
        }
      }
      expect(invalid, isEmpty, reason: 'Types invalides : $invalid');
    });

    test('le pommier recommande au moins le piege carpocapse', () {
      // Test de coherence metier : le ravageur principal du pommier est le
      // carpocapse. Si l'inference cassait sur le pommier (l'arbre le plus
      // commun), c'est probablement un signal d'alerte plus large.
      final apple = trees.firstWhere(
        (t) => (t['common_name'] as String).toLowerCase().contains('pommier'),
        orElse: () => <String, dynamic>{},
      );
      expect(apple, isNotEmpty,
          reason: 'fruit_trees.json doit contenir un pommier');
      final recommended =
          (apple['recommended_pheromone_traps'] as List).cast<String>();
      expect(recommended, contains('codlingMoth'),
          reason: 'Le pommier doit recommander le piege carpocapse');
    });

    test('le cerisier recommande le piege mouche de la cerise', () {
      final cherry = trees.firstWhere(
        (t) =>
            (t['common_name'] as String).toLowerCase().contains('cerisier'),
        orElse: () => <String, dynamic>{},
      );
      if (cherry.isEmpty) return; // pas grave si le catalogue n'en a pas
      final recommended =
          (cherry['recommended_pheromone_traps'] as List).cast<String>();
      expect(recommended, contains('cherryFruitFly'));
    });
  });
}
