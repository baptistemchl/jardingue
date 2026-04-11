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

  /// Annule toutes les notifications planifiees
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
