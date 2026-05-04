import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/crash_reporting/crash_reporting_service.dart';
import '../services/database/app_database.dart';
import '../services/notifications/notification_service.dart';
import '../../features/garden/data/repositories/garden_event_repository.dart';
import '../../features/garden/domain/models/care_helpers.dart';
import '../../features/garden/domain/models/care_reminder.dart';
import '../../features/garden/domain/models/garden_event.dart';
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

/// Stream réactif des événements d'une plante.
final gardenPlantEventsProvider =
    StreamProvider.family<List<GardenEvent>, int>((ref, gardenPlantId) async* {
  final db = ref.watch(databaseProvider);
  yield* db.watchEventsForGardenPlant(gardenPlantId);
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

  Future<Garden?> resolveGarden(int gardenId) async {
    if (!gardenCache.containsKey(gardenId)) {
      gardenCache[gardenId] = await gardenRepo.getGardenById(gardenId);
    }
    return gardenCache[gardenId];
  }

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
        garden = await resolveGarden(gp.gardenId);
      }
    } else if (event.plantId != null) {
      if (!plantCache.containsKey(event.plantId!)) {
        plantCache[event.plantId!] =
            await plantRepo.getPlantById(event.plantId!);
      }
      plant = plantCache[event.plantId!];
    }

    // Resolution du garden direct (events d'entretien sans plante).
    if (garden == null && event.gardenId != null) {
      garden = await resolveGarden(event.gardenId!);
    }

    final type = GardenEventType.fromString(event.eventType);
    // On garde l'event si :
    // - une plante existe (events classiques semis/arrosage/recolte)
    // - ou c'est un evenement d'entretien (avec ou sans potager)
    final keep = plant != null || gp != null || type.isMaintenance;
    if (!keep) continue;

    result.add(GardenEventWithDetails(
      event: event,
      gardenPlant: gp,
      plant: plant,
      garden: garden,
    ));
  }

  return result;
}

/// Stream réactif des plantes actuellement suivies (distinct via events).
final trackedPlantsProvider = StreamProvider<List<Plant>>((ref) async* {
  final db = ref.watch(databaseProvider);
  final plantRepo = ref.watch(plantRepositoryProvider);
  await for (final ids in db.watchTrackedPlantIds()) {
    yield await plantRepo.getPlantsByIds(ids);
  }
});

/// Stream du dernier arrosage d'une plante.
final lastWateringProvider =
    StreamProvider.family<DateTime?, int>((ref, gardenPlantId) async* {
  final db = ref.watch(databaseProvider);
  yield* db
      .watchLastEventOfType(gardenPlantId, GardenEventType.watering.name)
      .map((e) => e?.eventDate);
});

/// Stream des derniers arrosages pour toutes les plantes.
/// Émet à chaque ajout/suppression d'événement d'arrosage.
final lastWateringDatesProvider =
    StreamProvider<Map<int, DateTime>>((ref) async* {
  final initFuture = ref.read(databaseInitProvider.future);
  final db = ref.watch(databaseProvider);
  await initFuture;
  yield* db.watchLastWateringDates();
});

// ============================================
// CARE REMINDERS (generic : watering, fertilizing, ...)
// ============================================

/// Rappels generiques pour un type de soin recurrent.
///
/// Famille parametree par [CareKind] : on partage la totalite de la logique
/// (subscription DB, calcul d'echeance, tri) entre arrosage et fertilisation.
/// Seuls trois points divergent : la frequence par defaut, la requete des
/// dernieres dates, et l'eventuel hint meteo (uniquement pour l'arrosage).
///
/// Optimise : 2-3 requetes bulk au lieu de N+1.
final careRemindersProvider =
    FutureProvider.family<List<CareReminder>, CareKind>((ref, kind) async {
  // Toutes les souscriptions DOIVENT être déclarées synchroniquement
  // avant tout `await`. Sans ça, lors d'un changement de TickerMode
  // (navigation entre onglets, ouverture du clavier…), Riverpod
  // tente de pause/resume des subscriptions dans un état où le
  // bookkeeping n'est pas encore complet → assertion
  // "pausedActiveSubscriptionCount" qui crash en debug.
  final initFuture = ref.read(databaseInitProvider.future);
  final db = ref.watch(databaseProvider);
  // La meteo n'a de sens que pour l'arrosage. On ne s'y abonne pas pour
  // les autres kinds, ce qui evite des invalidations inutiles.
  final weatherFuture = kind == CareKind.watering
      ? ref.watch(weatherDataProvider.future)
      : null;

  await initFuture;

  // Hint meteo (arrosage uniquement)
  CareHint? weatherHint;
  bool weatherAvailable = false;
  double precipNext24h = 0;
  int maxPrecipProb = 0;
  if (weatherFuture != null) {
    try {
      final weather = await weatherFuture;
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
  }

  // 1 requete : tous les gardenPlants + plant + garden via JOINs
  final allRows = await db.getAllGardenPlantsWithPlantAndGarden();
  // 1 requete : dernieres dates pour le type d'event correspondant
  final lastDates = await switch (kind) {
    CareKind.watering => db.getLastWateringDates(),
    CareKind.fertilizing => db.getLastFertilizingDates(),
  };

  final List<CareReminder> reminders = [];
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  for (final row in allRows) {
    final gp = row.readTable(db.gardenPlants);
    final garden = row.readTable(db.gardens);

    // Ignorer les zones (plantId == 0)
    if (gp.plantId == 0) continue;

    final plant = row.readTableOrNull(db.plants);

    // Frequence : override utilisateur > catalogue > defaut par categorie
    final freq = switch (kind) {
      CareKind.watering => gp.wateringFrequencyDays ??
          defaultWateringFrequencyDays(plant?.watering),
      CareKind.fertilizing => gp.fertilizingFrequencyDays ??
          plant?.fertilizationFrequencyDays ??
          defaultFertilizationFrequencyDays(plant?.categoryCode),
    };

    final lastDate = lastDates[gp.id];

    // Calcul de la prochaine echeance.
    // - Si on a une derniere date : last + freq.
    // - Sinon, on utilise plantedAt comme reference (fertiliser au moment
    //   de la plantation est rare — on aligne sur today pour ne pas
    //   spammer les plantes recemment posees, sauf pour l'arrosage qui
    //   garde l'ancien comportement par compat).
    DateTime nextDue;
    if (lastDate != null) {
      final lastDay = DateTime(lastDate.year, lastDate.month, lastDate.day);
      nextDue = lastDay.add(Duration(days: freq));
    } else if (kind == CareKind.watering && gp.plantedAt != null) {
      nextDue = DateTime(
          gp.plantedAt!.year, gp.plantedAt!.month, gp.plantedAt!.day);
    } else if (kind == CareKind.fertilizing && gp.plantedAt != null) {
      // Premiere fertilisation : ~freq jours apres la plantation.
      final pAt = DateTime(
          gp.plantedAt!.year, gp.plantedAt!.month, gp.plantedAt!.day);
      nextDue = pAt.add(Duration(days: freq));
    } else {
      nextDue = today;
    }

    final isOverdue =
        nextDue.isBefore(today) || nextDue.isAtSameMomentAs(today);

    // Hint meteo pour l'arrosage uniquement
    if (kind == CareKind.watering && weatherAvailable) {
      if (precipNext24h > 5) {
        weatherHint = const CareHint(
            skip: true, message: 'Pluie suffisante prévue, reportez');
      } else if (maxPrecipProb > 60) {
        weatherHint = const CareHint(
            skip: true, message: 'Forte probabilité de pluie, reportez');
      } else if (precipNext24h > 0) {
        weatherHint = const CareHint(
            skip: false, message: 'Pluie légère prévue, arrosez si nécessaire');
      } else {
        weatherHint = null;
      }
    }

    // N'ajouter que les plantes a soigner bientot (today ou demain)
    final daysUntil = nextDue.difference(today).inDays;
    if (daysUntil <= 1) {
      reminders.add(CareReminder(
        kind: kind,
        gardenPlant: GardenPlantWithDetails(gardenPlant: gp, plant: plant),
        garden: garden,
        lastDate: lastDate,
        frequencyDays: freq,
        nextDue: nextDue,
        isOverdue: isOverdue,
        hint: weatherHint,
      ));
    }
  }

  // Trier : en retard d'abord, puis par urgence
  reminders.sort((a, b) {
    if (a.isOverdue != b.isOverdue) return a.isOverdue ? -1 : 1;
    return a.nextDue.compareTo(b.nextDue);
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
  // Sync watch avant l'await (cf. careRemindersProvider).
  final remindersFuture =
      ref.watch(careRemindersProvider(CareKind.watering).future);
  try {
    final reminders = await remindersFuture;
    final plantNames = reminders
        .where((r) => !r.shouldSkip && r.isOverdue)
        .map((r) => r.gardenPlant.name)
        .toList();

    if (plantNames.isNotEmpty) {
      final notifService = NotificationService();
      await notifService.requestPermission();
      await notifService.scheduleDailyWateringReminder(
        plantNames: plantNames,
      );
    }
  } catch (e, st) {
    CrashReportingService.recordError(e, st,
      reason: 'wateringNotificationSchedulerProvider',
    );
  }
});

// ============================================
// EVENT NOTIFIER
// ============================================

final gardenEventNotifierProvider =
    NotifierProvider<GardenEventNotifier, AsyncValue<void>>(GardenEventNotifier.new);

class GardenEventNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  GardenEventRepository get _repo => ref.read(gardenEventRepositoryProvider);

  Future<void> logEvent({
    int? gardenPlantId,
    int? plantId,
    int? gardenId,
    required GardenEventType eventType,
    required DateTime date,
    String? notes,
  }) async {
    // Pour les events d'entretien, l'utilisateur peut choisir "Sans potager" —
    // l'event n'est alors lie a rien et reste un simple log dans le calendrier.
    // Pour les autres types (semis, arrosage, recolte), au moins un lien
    // (plante ou potager) est attendu — sinon l'event est inutilisable.
    assert(eventType.isMaintenance ||
            gardenPlantId != null ||
            plantId != null ||
            gardenId != null,
        'non-maintenance events require gardenPlantId, plantId or gardenId');
    state = const AsyncLoading();
    try {
      await _repo.addEvent(GardenEventsCompanion.insert(
        gardenPlantId: Value(gardenPlantId),
        plantId: Value(plantId),
        gardenId: Value(gardenId),
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
      CrashReportingService.recordError(e, st,
        reason: 'GardenEventNotifier.logEvent',
        extra: {
          'eventType': eventType.name,
          'gardenPlantId': gardenPlantId ?? -1,
          'plantId': plantId ?? -1,
          'gardenId': gardenId ?? -1,
        },
      );
      state = AsyncError(e, st);
    }
  }

  /// Logge un soin recurrent ([CareKind]) sur une plante a la date courante.
  ///
  /// Generique pour eviter d'avoir un quickX par type. Le mapping vers
  /// [GardenEventType] est porte par [CareKind.eventType].
  Future<void> quickLogCare(CareKind kind, int gardenPlantId) async {
    await logEvent(
      gardenPlantId: gardenPlantId,
      eventType: kind.eventType,
      date: DateTime.now(),
    );
  }

  /// Raccourci historique. Conserve pour ne pas casser les usages existants.
  Future<void> quickWater(int gardenPlantId) =>
      quickLogCare(CareKind.watering, gardenPlantId);

  Future<void> quickHarvest(int gardenPlantId) async {
    await logEvent(
      gardenPlantId: gardenPlantId,
      eventType: GardenEventType.harvest,
      date: DateTime.now(),
    );
  }

  void _invalidateMonth() {
    ref.invalidate(allUserEventsProvider);
    ref.invalidate(monthUserEventsProvider(DateTime(
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
      CrashReportingService.recordError(e, st,
        reason: 'GardenEventNotifier.deleteEvent',
        extra: {'eventId': eventId, 'gardenPlantId': gardenPlantId},
      );
      state = AsyncError(e, st);
    }
  }

  /// Seuls les providers encore en FutureProvider sont invalidés ici.
  /// Les streams (gardenPlantEventsProvider, lastWateringProvider,
  /// lastWateringDatesProvider) se rafraîchissent automatiquement via
  /// Drift `.watch()`.
  void _invalidateAll(int gardenPlantId) {
    // Invalide TOUTE la famille careRemindersProvider : un meme event
    // (watering, fertilizer...) peut impacter les rappels de son kind.
    ref.invalidate(careRemindersProvider);
    ref.invalidate(allUserEventsProvider);
    ref.invalidate(monthUserEventsProvider(DateTime(
      DateTime.now().year,
      DateTime.now().month,
    )));
  }
}
