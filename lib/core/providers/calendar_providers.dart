import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/planning/domain/models/planning_task.dart';
import '../../features/planning/domain/models/soil_task.dart';
import '../services/crash_reporting/crash_reporting_service.dart';
import '../services/database/database.dart';
import 'database_providers.dart';

// ============================================
// CALENDAR TYPES
// ============================================

/// Types d'activités au jardin
enum GardenActivityType {
  sowingUnderCover('Semis sous abri', '🏠', Color(0xFFFF9800)),
  sowingOpenGround('Semis pleine terre', '🌱', Color(0xFF4CAF50)),
  planting('Plantation', '🌿', Color(0xFF2196F3)),
  harvest('Récolte', '🧺', Color(0xFFE91E63));

  final String label;
  final String emoji;
  final Color color;

  const GardenActivityType(this.label, this.emoji, this.color);
}

/// Une activité de jardinage pour une plante
class PlantActivity {
  final Plant plant;
  final GardenActivityType activityType;
  final String? detail; // ex: "sous abri", "pleine terre"

  const PlantActivity({
    required this.plant,
    required this.activityType,
    this.detail,
  });
}

/// Activités groupées par type pour un mois donné
class MonthActivities {
  final int month;
  final int year;
  final List<PlantActivity> sowingUnderCover;
  final List<PlantActivity> sowingOpenGround;
  final List<PlantActivity> planting;
  final List<PlantActivity> harvest;

  const MonthActivities({
    required this.month,
    required this.year,
    required this.sowingUnderCover,
    required this.sowingOpenGround,
    required this.planting,
    required this.harvest,
  });

  int get totalActivities =>
      sowingUnderCover.length +
      sowingOpenGround.length +
      planting.length +
      harvest.length;

  bool get isEmpty => totalActivities == 0;

  List<PlantActivity> getActivitiesByType(
    GardenActivityType type,
  ) => switch (type) {
    GardenActivityType.sowingUnderCover => sowingUnderCover,
    GardenActivityType.sowingOpenGround => sowingOpenGround,
    GardenActivityType.planting => planting,
    GardenActivityType.harvest => harvest,
  };
}

// ============================================
// PROVIDERS
// ============================================

/// Mois actuellement sélectionné
final selectedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

/// Filtre d'activité (null = toutes)
final activityFilterProvider = StateProvider<GardenActivityType?>(
  (ref) => null,
);

/// Provider pour les activités d'un mois donné
final monthActivitiesProvider =
    FutureProvider.family<MonthActivities, DateTime>((ref, month) async {
      await ref.watch(databaseInitProvider.future);
      final db = ref.watch(databaseProvider);
      final plants = await db.getAllPlantsSorted();

      final monthName = _getEnglishMonthName(month.month);

      final sowingUnderCover = <PlantActivity>[];
      final sowingOpenGround = <PlantActivity>[];
      final planting = <PlantActivity>[];
      final harvest = <PlantActivity>[];

      for (final plant in plants) {
        // Semis
        final sowingData = _parseCalendar(plant.sowingCalendar);
        if (sowingData != null) {
          final value = sowingData[monthName];
          if (value != null && value.toString().startsWith('Oui')) {
            if (value.toString().contains('sous abri')) {
              sowingUnderCover.add(
                PlantActivity(
                  plant: plant,
                  activityType: GardenActivityType.sowingUnderCover,
                  detail: 'sous abri',
                ),
              );
            } else if (value.toString().contains('pleine terre')) {
              sowingOpenGround.add(
                PlantActivity(
                  plant: plant,
                  activityType: GardenActivityType.sowingOpenGround,
                  detail: 'pleine terre',
                ),
              );
            } else {
              // Par défaut, on considère que c'est pleine terre
              sowingOpenGround.add(
                PlantActivity(
                  plant: plant,
                  activityType: GardenActivityType.sowingOpenGround,
                ),
              );
            }
          }
        }

        // Plantation
        final plantingData = _parseCalendar(plant.plantingCalendar);
        if (plantingData != null) {
          final value = plantingData[monthName];
          if (value != null && value.toString().startsWith('Oui')) {
            planting.add(
              PlantActivity(
                plant: plant,
                activityType: GardenActivityType.planting,
                detail: _extractDetail(value.toString()),
              ),
            );
          }
        }

        // Récolte
        final harvestData = _parseCalendar(plant.harvestCalendar);
        if (harvestData != null) {
          final value = harvestData[monthName];
          if (value != null && value.toString().startsWith('Oui')) {
            harvest.add(
              PlantActivity(
                plant: plant,
                activityType: GardenActivityType.harvest,
                detail: _extractDetail(value.toString()),
              ),
            );
          }
        }
      }

      return MonthActivities(
        month: month.month,
        year: month.year,
        sowingUnderCover: sowingUnderCover,
        sowingOpenGround: sowingOpenGround,
        planting: planting,
        harvest: harvest,
      );
    });

/// Provider pour les activités filtrées du mois sélectionné
final filteredActivitiesProvider = Provider<AsyncValue<List<PlantActivity>>>((
  ref,
) {
  final selectedMonth = ref.watch(selectedMonthProvider);
  final filter = ref.watch(activityFilterProvider);
  final activitiesAsync = ref.watch(monthActivitiesProvider(selectedMonth));

  return activitiesAsync.whenData((activities) {
    if (filter == null) {
      // Toutes les activités
      return [
        ...activities.sowingUnderCover,
        ...activities.sowingOpenGround,
        ...activities.planting,
        ...activities.harvest,
      ];
    }
    return activities.getActivitiesByType(filter);
  });
});

/// Provider pour le résumé de l'année (nombre d'activités par mois)
final yearSummaryProvider = FutureProvider.family<Map<int, int>, int>((
  ref,
  year,
) async {
  final summary = <int, int>{};

  for (var month = 1; month <= 12; month++) {
    final activities = await ref.watch(
      monthActivitiesProvider(DateTime(year, month)).future,
    );
    summary[month] = activities.totalActivities;
  }

  return summary;
});

// ============================================
// HELPERS
// ============================================

Map<String, dynamic>? _parseCalendar(String? calendarJson) {
  if (calendarJson == null) return null;
  try {
    final data = json.decode(calendarJson) as Map<String, dynamic>;
    return data['monthly_period'] as Map<String, dynamic>?;
  } catch (e, st) {
    CrashReportingService.recordError(e, st,
      reason: '_parseCalendar',
      extra: {'calendarJson_length': calendarJson.length},
    );
    return null;
  }
}

String _getEnglishMonthName(int month) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return months[month - 1];
}

String _getFrenchMonthName(int month) {
  const months = [
    'Janvier',
    'Février',
    'Mars',
    'Avril',
    'Mai',
    'Juin',
    'Juillet',
    'Août',
    'Septembre',
    'Octobre',
    'Novembre',
    'Décembre',
  ];
  return months[month - 1];
}

String? _extractDetail(String value) {
  // Extrait le détail entre parenthèses : "Oui (plantation en place)" -> "plantation en place"
  final match = RegExp(r'\(([^)]+)\)').firstMatch(value);
  return match?.group(1);
}

/// Extension pour obtenir le nom du mois en français
extension DateTimeCalendarExtension on DateTime {
  String get frenchMonthName =>
      _getFrenchMonthName(month);

  String get frenchMonthYear =>
      '${_getFrenchMonthName(month)} $year';
}

// ============================================
// CALENDAR ITEM UNIFIE (planification + events)
// ============================================

enum CalendarItemType {
  planningTask(
    'Planification',
    '🌱',
    Color(0xFF4CAF50),
  ),
  userEvent(
    'Mes activités',
    '📝',
    Color(0xFF2196F3),
  ),
  weatherAlert(
    'Météo',
    '⛈️',
    Color(0xFFFF9800),
  ),
  soilPreparation(
    'Sol',
    '🪴',
    Color(0xFF795548),
  ),
  reminder(
    'Rappel',
    '🔔',
    Color(0xFF9C27B0),
  );

  final String label;
  final String emoji;
  final Color color;

  const CalendarItemType(
    this.label,
    this.emoji,
    this.color,
  );
}

class CalendarItem {
  final CalendarItemType type;
  final String title;
  final String? subtitle;
  final DateTime date;
  final int? plantId;
  final String? plantName;
  final Color color;
  final String emoji;

  const CalendarItem({
    required this.type,
    required this.title,
    this.subtitle,
    required this.date,
    this.plantId,
    this.plantName,
    required this.color,
    required this.emoji,
  });
}

class CalendarFilter {
  final Set<CalendarItemType> activeTypes;

  const CalendarFilter({
    this.activeTypes = const {},
  });

  bool get showAll => activeTypes.isEmpty;

  bool accepts(CalendarItemType type) {
    return showAll || activeTypes.contains(type);
  }

  CalendarFilter toggle(CalendarItemType type) {
    final next = Set<CalendarItemType>.from(
      activeTypes,
    );
    if (next.contains(type)) {
      next.remove(type);
    } else {
      next.add(type);
    }
    return CalendarFilter(activeTypes: next);
  }
}

final calendarFilterProvider =
    StateProvider<CalendarFilter>(
  (ref) => const CalendarFilter(),
);

/// Filtre par plant dans le calendrier (null = tous).
final calendarPlantFilterProvider =
    StateProvider<int?>((ref) => null);

// ============================================
// MAPPING PLANNING -> CALENDAR ITEMS
// ============================================

List<CalendarItem> mapPlanningToCalendar({
  required List<PlanningTask> tasks,
  required List<SoilTask> soilTasks,
  required DateTime month,
}) {
  final items = <CalendarItem>[];

  for (final task in tasks) {
    items.add(CalendarItem(
      type: CalendarItemType.planningTask,
      title: task.message,
      subtitle: task.plantName,
      date: DateTime(month.year, month.month),
      plantId: task.plantId,
      plantName: task.plantName,
      color: task.actionType.color,
      emoji: task.plantEmoji,
    ));
  }

  for (final soil in soilTasks) {
    items.add(CalendarItem(
      type: CalendarItemType.soilPreparation,
      title: soil.message,
      date: DateTime(month.year, month.month),
      color: const Color(0xFF795548),
      emoji: soil.type.emoji,
    ));
  }

  return items;
}
