import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../crash_reporting/crash_reporting_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const _channelId = 'watering_reminders';
  static const _channelName = 'Rappels d\'arrosage';
  static const _channelDesc = 'Notifications pour arroser vos plantes';

  static const _frostChannelId = 'frost_alerts';
  static const _frostChannelName = 'Alertes de gel';
  static const _frostChannelDesc =
      'Avertissements lorsque du gel est prevu la nuit';
  static const _frostNotifId = 2;

  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings: initSettings);
    _initialized = true;
  }

  /// Demande la permission de notifications (iOS + Android 13+)
  Future<bool> requestPermission() async {
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final granted =
          await androidPlugin.requestNotificationsPermission();
      return granted ?? false;
    }

    final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      final granted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return true;
  }

  /// Planifie une notification quotidienne d'arrosage a 8h
  Future<void> scheduleDailyWateringReminder({
    required List<String> plantNames,
  }) async {
    if (!_initialized) await init();

    // Annuler les anciennes notifications d'arrosage
    await _plugin.cancel(id: 0);

    if (plantNames.isEmpty) return;

    final count = plantNames.length;
    final title = '$count plante${count > 1 ? 's' : ''} a arroser';
    final body = plantNames.take(3).join(', ') +
        (count > 3 ? ' et ${count - 3} autres' : '');

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    // Planifier pour demain 8h
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      8,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    try {
      await _plugin.zonedSchedule(
        id: 0,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      debugPrint('Notification d\'arrosage planifiee pour $scheduledDate');
    } catch (e, st) {
      CrashReportingService.recordError(e, st,
        reason: 'NotificationService.scheduleDailyWateringReminder',
        extra: {'plantCount': plantNames.length},
      );
    }
  }

  /// Affiche une notification immediate
  Future<void> showWateringReminder({
    required String title,
    required String body,
  }) async {
    if (!_initialized) await init();

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.show(
      id: 1,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
    );
  }

  /// Planifie (ou affiche) une alerte de gel pour la nuit a venir.
  /// [minTemp] est la temperature minimale prevue, [frostHour] l'heure
  /// a laquelle elle est atteinte, et [alertAt] le moment ou l'utilisateur
  /// doit etre averti (generalement en fin d'apres-midi, avant le gel).
  Future<void> scheduleFrostAlert({
    required double minTemp,
    required DateTime frostHour,
    required DateTime alertAt,
  }) async {
    if (!_initialized) await init();

    final tempDisplay = minTemp.round();
    final hourDisplay = frostHour.hour.toString().padLeft(2, '0');
    final title = '\u2744\uFE0F Risque de gel cette nuit';
    final body =
        'Jusqu\'a ${tempDisplay}\u00B0C vers ${hourDisplay}h. '
        'Pensez a proteger vos plants sensibles (voile, paillage).';

    const androidDetails = AndroidNotificationDetails(
      _frostChannelId,
      _frostChannelName,
      channelDescription: _frostChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    try {
      final now = tz.TZDateTime.now(tz.local);
      final scheduled = tz.TZDateTime.from(alertAt, tz.local);

      if (scheduled.isBefore(now.add(const Duration(minutes: 1)))) {
        await _plugin.show(
          id: _frostNotifId,
          title: title,
          body: body,
          notificationDetails: details,
        );
      } else {
        await _plugin.zonedSchedule(
          id: _frostNotifId,
          title: title,
          body: body,
          scheduledDate: scheduled,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
      debugPrint(
        'Alerte gel planifiee pour $scheduled (min ${tempDisplay}\u00B0C)',
      );
    } catch (e, st) {
      CrashReportingService.recordError(e, st,
        reason: 'NotificationService.scheduleFrostAlert',
        extra: {
          'minTemp': minTemp,
          'frostHour': frostHour.toIso8601String(),
        },
      );
    }
  }

  Future<void> cancelFrostAlert() async {
    await _plugin.cancel(id: _frostNotifId);
  }

  /// Annule toutes les notifications planifiees
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
