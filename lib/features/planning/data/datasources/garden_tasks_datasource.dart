import 'dart:convert';

import 'package:flutter/services.dart';

import '../../domain/models/garden_task_data.dart';

/// Charge les tâches potagères depuis le JSON.
class GardenTasksDatasource {
  List<GardenTaskData>? _cache;

  Future<List<GardenTaskData>> loadAll() async {
    if (_cache != null) return _cache!;

    final raw = await rootBundle.loadString(
      'assets/data/garden_tasks.json',
    );
    final json =
        jsonDecode(raw) as Map<String, dynamic>;
    final list =
        json['tasks'] as List<dynamic>;

    _cache = list
        .map(
          (e) => GardenTaskData.fromJson(
            e as Map<String, dynamic>,
          ),
        )
        .toList();

    return _cache!;
  }

  /// Tâches filtrées par mois.
  Future<Map<int, List<GardenTaskData>>>
      loadByMonth() async {
    final tasks = await loadAll();
    final result = <int, List<GardenTaskData>>{};

    for (final task in tasks) {
      for (final month in task.months) {
        result.putIfAbsent(month, () => []);
        result[month]!.add(task);
      }
    }

    return result;
  }
}
