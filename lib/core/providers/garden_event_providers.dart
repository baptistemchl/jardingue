import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database/app_database.dart';
import '../services/notifications/notification_service.dart';
import '../../features/garden/data/repositories/garden_event_repository.dart';
import '../../features/garden/domain/models/garden_event.dart';
import '../../features/garden/domain/models/watering_helpers.dart';
import '../../features/garden/domain/models/watering_reminder.dart';
import 'database_providers.dart';
import 'garden_providers.dart';
import 'weather_providers.dart';

// ============================================
// REPOSITORY
// ============================================

final gardenEventRepositoryProvider = Provider<GardenEventRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return DriftGardenEventRepository(db);
});

// ============================================
// EVENT QUERIES
// ============================================

/// Événements pour une plante dans un jardin
final gardenPlantEventsProvider =
    FutureProvider.family<List<GardenEvent>, int>((ref, gardenPlantId) async {
  final repo = ref.watch(gardenEventRepositoryProvider);
  return repo.getEventsForGardenPlant(gardenPlantId);
});

/// Événements utilisateur pour un mois donné (avec détails)
final monthUserEventsProvider =
    FutureProvider.family<List<GardenEventWithDetails>, DateTime>((
  ref,
  month,
) async {
  final eventRepo = ref.watch(gardenEventRepositoryProvider);
  final events = await eventRepo.getEventsForMonth(month.year, month.month);
  if (events.isEmpty) return [];
  return _enrichEvents(ref, events);
});

/// Tous les événements utilisateur (avec détails)
final allUserEventsProvider =
    FutureProvider<List<GardenEventWithDetails>>((ref) async {
  final eventRepo = ref.watch(gardenEventRepositoryProvider);
  final events = await eventRepo.getAllEvents();
  if (events.isEmpty) return [];
  return _enrichEvents(ref, events);
});

/// Enrichit une liste d'événements bruts avec les détails plante/jardin
Future<List<GardenEventWithDetails>> _enrichEvents(
  Ref ref,
  List<GardenEvent> events,
) async {
  final gardenRepo = ref.read(gardenRepositoryProvider);
  final plantRepo = ref.read(plantRepositoryProvider);

  final List<GardenEventWithDetails> result = [];
  final gardenPlantCache = <int, GardenPlant>{};
  final plantCache = <int, Plant?>{};
  final gardenCache = <int, Garden?>{};

  for (final event in events) {
    GardenPlant? gp;
    Plant? plant;
    Garden? garden;

    if (event.gardenPlantId != null) {
      gp = gardenPlantCache[event.gardenPlantId!];
      if (gp == null) {
        final db = ref.read(databaseProvider);
        final gpList = await (db.select(db.gardenPlants)
              ..where((t) => t.id.equals(event.gardenPlantId!)))
            .get();
        if (gpList.isNotEmpty) {
          gp = gpList.first;
          gardenPlantCache[event.gardenPlantId!] = gp;
        }
      }
      if (gp != null) {
        if (!plantCache.containsKey(gp.plantId)) {
          plantCache[gp.plantId] =
              gp.plantId > 0 ? await plantRepo.getPlantById(gp.plantId) : null;
        }
        plant = plantCache[gp.plantId];
        if (!gardenCache.containsKey(gp.gardenId)) {
          gardenCache[gp.gardenId] =
              await gardenRepo.getGardenById(gp.gardenId);
        }
        garden = gardenCache[gp.gardenId];
      }
    } else if (event.plantId != null) {
      if (!plantCache.containsKey(event.plantId!)) {
        plantCache[event.plantId!] =
            await plantRepo.getPlantById(event.plantId!);
      }
      plant = plantCache[event.plantId!];
    }

    if (plant == null && gp == null) continue;

    result.add(GardenEventWithDetails(
      event: event,
      gardenPlant: gp,
      plant: plant,
      garden: garden,
    ));
  }

  return result;
}

/// Plantes suivies (avec événements hors potager) pour le picker arrosage/récolte
final trackedPlantsProvider = FutureProvider<List<Plant>>((ref) async {
  final db = ref.watch(databaseProvider);
  final plantRepo = ref.watch(plantRepositoryProvider);
  final trackedIds = await db.getTrackedPlantIds();
  final List<Plant> plants = [];
  for (final id in trackedIds) {
    final plant = await plantRepo.getPlantById(id);
    if (plant != null) plants.add(plant);
  }
  return plants;
});

/// Dernier arrosage d'une plante
final lastWateringProvider =
    FutureProvider.family<DateTime?, int>((ref, gardenPlantId) async {
  final repo = ref.watch(gardenEventRepositoryProvider);
  final event =
      await repo.getLastEventOfType(gardenPlantId, GardenEventType.watering.name);
  return event?.eventDate;
});

// ============================================
// WATERING REMINDERS
// ============================================

/// Rappels d'arrosage pour toutes les plantes de tous les jardins
final wateringRemindersProvider =
    FutureProvider<List<WateringReminder>>((ref) async {
  await ref.watch(databaseInitProvider.future);
  final gardenRepo = ref.watch(gardenRepositoryProvider);
  final plantRepo = ref.watch(plantRepositoryProvider);
  final eventRepo = ref.watch(gardenEventRepositoryProvider);

  // Données météo (peut échouer si pas de localisation)
  double precipNext24h = 0;
  int maxPrecipProb = 0;
  bool weatherAvailable = false;
  try {
    final weather = await ref.watch(weatherDataProvider.future);
    weatherAvailable = true;
    for (int i = 0; i < weather.hourlyForecast.length && i < 24; i++) {
      precipNext24h += weather.hourlyForecast[i].precipitation;
      if (weather.hourlyForecast[i].precipitationProbability > maxPrecipProb) {
        maxPrecipProb = weather.hourlyForecast[i].precipitationProbability;
      }
    }
  } catch (_) {
    // Pas de données météo, on continue sans
  }

  final gardens = await gardenRepo.getAllGardens();
  final List<WateringReminder> reminders = [];
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  for (final garden in gardens) {
    final gardenPlants = await gardenRepo.getGardenPlants(garden.id);

    for (final gp in gardenPlants) {
      // Ignorer les zones (plantId == 0)
      if (gp.plantId == 0) continue;

      final plant = await plantRepo.getPlantById(gp.plantId);

      // Fréquence d'arrosage
      final freq =
          gp.wateringFrequencyDays ?? defaultWateringFrequencyDays(plant?.watering);

      // Dernier arrosage
      final lastWateringEvent =
          await eventRepo.getLastEventOfType(gp.id, GardenEventType.watering.name);
      final lastWatered = lastWateringEvent?.eventDate;

      // Calcul du prochain arrosage
      DateTime nextDue;
      if (lastWatered != null) {
        final lastDay =
            DateTime(lastWatered.year, lastWatered.month, lastWatered.day);
        nextDue = lastDay.add(Duration(days: freq));
      } else if (gp.plantedAt != null) {
        // Si jamais arrosé, baser sur la date de plantation
        nextDue = DateTime(
            gp.plantedAt!.year, gp.plantedAt!.month, gp.plantedAt!.day);
      } else {
        // Pas de données, considérer comme dû aujourd'hui
        nextDue = today;
      }

      final isOverdue = nextDue.isBefore(today) || nextDue.isAtSameMomentAs(today);

      // Conseil météo
      bool weatherSkip = false;
      String weatherAdvice = '';
      if (weatherAvailable) {
        if (precipNext24h > 5) {
          weatherSkip = true;
          weatherAdvice = 'Pluie suffisante prévue, reportez';
        } else if (maxPrecipProb > 60) {
          weatherSkip = true;
          weatherAdvice = 'Forte probabilité de pluie, reportez';
        } else if (precipNext24h > 0) {
          weatherAdvice = 'Pluie légère prévue, arrosez si nécessaire';
        }
      }

      // N'ajouter que les plantes à arroser bientôt (aujourd'hui, en retard, ou dans 1 jour)
      final daysUntil = nextDue.difference(today).inDays;
      if (daysUntil <= 1) {
        reminders.add(WateringReminder(
          gardenPlant: GardenPlantWithDetails(gardenPlant: gp, plant: plant),
          garden: garden,
          lastWatered: lastWatered,
          frequencyDays: freq,
          nextWateringDue: nextDue,
          isOverdue: isOverdue,
          weatherSaysSkip: weatherSkip,
          weatherAdvice: weatherAdvice,
        ));
      }
    }
  }

  // Trier : en retard d'abord, puis par urgence
  reminders.sort((a, b) {
    if (a.isOverdue != b.isOverdue) return a.isOverdue ? -1 : 1;
    return a.nextWateringDue.compareTo(b.nextWateringDue);
  });

  return reminders;
});

// ============================================
// NOTIFICATION SCHEDULING
// ============================================

/// Provider qui planifie les notifications d'arrosage
/// basées sur les rappels actuels.
final wateringNotificationSchedulerProvider =
    FutureProvider<void>((ref) async {
  try {
    final reminders = await ref.watch(wateringRemindersProvider.future);
    final plantNames = reminders
        .where((r) => !r.weatherSaysSkip && r.isOverdue)
        .map((r) => r.gardenPlant.name)
        .toList();

    if (plantNames.isNotEmpty) {
      final notifService = NotificationService();
      await notifService.requestPermission();
      await notifService.scheduleDailyWateringReminder(
        plantNames: plantNames,
      );
    }
  } catch (e) {
    debugPrint('Erreur scheduling notifications: $e');
  }
});

// ============================================
// EVENT NOTIFIER
// ============================================

final gardenEventNotifierProvider =
    StateNotifierProvider<GardenEventNotifier, AsyncValue<void>>((ref) {
  final repo = ref.watch(gardenEventRepositoryProvider);
  return GardenEventNotifier(repo, ref);
});

class GardenEventNotifier extends StateNotifier<AsyncValue<void>> {
  final GardenEventRepository _repo;
  final Ref _ref;

  GardenEventNotifier(this._repo, this._ref)
      : super(const AsyncData(null));

  Future<void> logEvent({
    int? gardenPlantId,
    int? plantId,
    required GardenEventType eventType,
    required DateTime date,
    String? notes,
  }) async {
    assert(gardenPlantId != null || plantId != null);
    state = const AsyncLoading();
    try {
      await _repo.addEvent(GardenEventsCompanion.insert(
        gardenPlantId: Value(gardenPlantId),
        plantId: Value(plantId),
        eventType: eventType.name,
        eventDate: date,
        notes: Value(notes),
      ));
      if (gardenPlantId != null) {
        _invalidateAll(gardenPlantId);
      } else {
        _invalidateMonth();
      }
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> quickWater(int gardenPlantId) async {
    await logEvent(
      gardenPlantId: gardenPlantId,
      eventType: GardenEventType.watering,
      date: DateTime.now(),
    );
  }

  Future<void> quickHarvest(int gardenPlantId) async {
    await logEvent(
      gardenPlantId: gardenPlantId,
      eventType: GardenEventType.harvest,
      date: DateTime.now(),
    );
  }

  void _invalidateMonth() {
    _ref.invalidate(allUserEventsProvider);
    _ref.invalidate(monthUserEventsProvider(DateTime(
      DateTime.now().year,
      DateTime.now().month,
    )));
  }

  Future<void> deleteEvent(int eventId, int gardenPlantId) async {
    state = const AsyncLoading();
    try {
      await _repo.deleteEvent(eventId);
      _invalidateAll(gardenPlantId);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void _invalidateAll(int gardenPlantId) {
    _ref.invalidate(gardenPlantEventsProvider(gardenPlantId));
    _ref.invalidate(lastWateringProvider(gardenPlantId));
    _ref.invalidate(wateringRemindersProvider);
    _ref.invalidate(allUserEventsProvider);
    _ref.invalidate(monthUserEventsProvider(DateTime(
      DateTime.now().year,
      DateTime.now().month,
    )));
  }
}
