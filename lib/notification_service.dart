import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:url_launcher/url_launcher.dart';
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

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) async {
        await _openNotificationUrl(response.payload);
      },
    );

    await _initializeFirebaseMessaging();
  }

  static Future<void> _initializeFirebaseMessaging() async {
    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus ==
            AuthorizationStatus.authorized ||
        settings.authorizationStatus ==
            AuthorizationStatus.provisional) {
      await messaging.subscribeToTopic('twiix_live');
    }

    FirebaseMessaging.onMessageOpenedApp.listen((message) async {
      await _openNotificationUrl(message.data['url']);
    });

    final initialMessage = await messaging.getInitialMessage();

    if (initialMessage != null) {
      await _openNotificationUrl(initialMessage.data['url']);
    }

    FirebaseMessaging.onMessage.listen((message) async {
      final notification = message.notification;

      if (notification == null) {
        return;
      }

      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'twiix_live_now',
          'Lives Les Twiix',
          channelDescription:
              'Notifications lorsque Les Twiix sont en live',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _notifications.show(
        message.hashCode,
        notification.title ?? 'Les Twiix sont en LIVE !',
        notification.body ?? 'Rejoins le live maintenant.',
        details,
        payload: message.data['url'] as String?,
      );
    });
  }

  static Future<void> _openNotificationUrl(
    String? url,
  ) async {
    if (url == null || url.trim().isEmpty) {
      return;
    }

    final uri = Uri.tryParse(url.trim());

    if (uri == null ||
        (uri.scheme != 'https' && uri.scheme != 'http')) {
      return;
    }

    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
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
