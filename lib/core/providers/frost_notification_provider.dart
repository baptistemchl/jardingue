import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/crash_reporting/crash_reporting_service.dart';
import '../services/notifications/notification_service.dart';
import '../services/weather/weather_models.dart';
import 'weather_providers.dart';

/// Seuil de temperature (en degres Celsius) en dessous duquel on previent
/// l'utilisateur d'un risque de gel nocturne.
const double frostAlertThresholdCelsius = 4.0;

/// Fenetre horaire consideree comme "nuit" pour l'alerte de gel.
/// On retient les heures ou le flag isDay est faux ainsi qu'un filet de
/// securite 21h-8h au cas ou la meteo renverrait un isDay incoherent.
bool _isNightHour(HourlyForecast h) {
  if (!h.isDay) return true;
  final hour = h.time.hour;
  return hour >= 21 || hour <= 8;
}

/// Planifie (ou affiche) une alerte de gel en fonction de la meteo courante.
///
/// On parcourt les 36 prochaines heures, on isole les heures de nuit dont la
/// temperature est inferieure au seuil et on programme une notification pour
/// ~18h le jour precedant le gel (ou immediatement si cette heure est passee).
final frostNotificationSchedulerProvider =
    FutureProvider<void>((ref) async {
  try {
    final weather = await ref.watch(weatherDataProvider.future);
    final service = NotificationService();

    final now = DateTime.now();
    HourlyForecast? coldest;

    for (final h in weather.hourlyForecast) {
      if (!h.time.isAfter(now)) continue;
      if (h.time.difference(now).inHours > 36) break;
      if (!_isNightHour(h)) continue;
      if (h.temperature > frostAlertThresholdCelsius) continue;
      if (coldest == null || h.temperature < coldest.temperature) {
        coldest = h;
      }
    }

    if (coldest == null) {
      await service.cancelFrostAlert();
      return;
    }

    // Determine quand reveiller l'utilisateur : le jour ou le gel commence,
    // a 18h. Si le gel est prevu tot le matin (ex: 3h), on alerte la veille.
    final frostTime = coldest.time;
    final frostDay = DateTime(frostTime.year, frostTime.month, frostTime.day);
    final alertDay =
        frostTime.hour < 12 ? frostDay.subtract(const Duration(days: 1)) : frostDay;
    final alertAt = DateTime(alertDay.year, alertDay.month, alertDay.day, 18);

    await service.requestPermission();
    await service.scheduleFrostAlert(
      minTemp: coldest.temperature,
      frostHour: frostTime,
      alertAt: alertAt,
    );
  } catch (e, st) {
    CrashReportingService.recordError(e, st,
      reason: 'frostNotificationSchedulerProvider',
    );
  }
});
