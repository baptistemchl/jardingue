import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/garden_template.dart';

const _kTemplatesAsset = 'assets/data/garden_templates.json';

/// Charge les templates de potagers depuis le JSON d'assets. La liste est
/// statique et ne change qu'avec une mise à jour de l'app, donc on la
/// cache via Riverpod pour ne pas re-parser à chaque navigation.
final gardenTemplatesProvider =
    FutureProvider<List<GardenTemplate>>((ref) async {
  final raw = await rootBundle.loadString(_kTemplatesAsset);
  final json = jsonDecode(raw) as Map<String, dynamic>;
  final list = (json['templates'] as List<dynamic>);
  return list
      .map((t) => GardenTemplate.fromJson(t as Map<String, dynamic>))
      .toList(growable: false);
});
