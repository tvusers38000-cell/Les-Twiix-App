import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    tz.initializeTimeZones();

    final localTimezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(
      tz.getLocation(localTimezone.identifier),
    );

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initializationSettings);
  }

  static Future<void> scheduleLiveReminder({
    required DateTime liveAt,
    required String liveTitle,
  }) async {
    final androidPlugin =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    final androidPermissionGranted =
        await androidPlugin?.requestNotificationsPermission();

    if (androidPermissionGranted == false) {
      throw Exception('Notifications refusées');
    }

    final iosPlugin =
        _notifications.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    final iosPermissionGranted = await iosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    if (iosPermissionGranted == false) {
      throw Exception('Notifications refusées');
    }

    final reminderAt =
        liveAt.subtract(const Duration(minutes: 15));

    if (!reminderAt.isAfter(DateTime.now())) {
      throw Exception('Le rappel est déjà passé.');
    }

    final scheduledDate =
        tz.TZDateTime.from(reminderAt, tz.local);

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'twiix_live_reminders',
        'Rappels des lives',
        channelDescription:
            'Notifications avant le début des lives Les Twiix',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    final id =
        liveAt.millisecondsSinceEpoch.remainder(2147483647);

    await _notifications.zonedSchedule(
      id,
      'Les Twiix bientôt en live !',
      '$liveTitle commence dans 15 minutes.',
      scheduledDate,
      details,
      androidScheduleMode:
          AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }
}
