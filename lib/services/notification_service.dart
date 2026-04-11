import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String channelId = 'student_pal_alerts';
  static const String channelName = 'Student Pal Reminders';

  Future<void> init() async {
    // 1. Timezone Initialization
    tz_data.initializeTimeZones();
    try {
      var tzName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzName.toString()));
    } catch (e) {
      // Default to Manila if lookup fails
      tz.setLocalLocation(tz.getLocation('Asia/Manila'));
    }

    // 2. Local Notification Settings
    const config = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _notifications.initialize(
      settings: config,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        debugPrint("Notification tapped: ${details.payload}");
      },
    );

    // 3. Create Android Channel
    if (Platform.isAndroid) {
      await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              channelId,
              channelName,
              importance: Importance.max,
              playSound: true,
              enableVibration: true,
            ),
          );
    }
  }

  // REPLACED: Removed Firebase _setupFirebase and showNotification(RemoteMessage)
  // Local notifications are now purely handled via _schedule

  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      final android = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      // Requesting permissions for Android 13+ stability
      await android?.requestNotificationsPermission();
      await android?.requestExactAlarmsPermission();
    } else if (Platform.isIOS) {
      await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  // --- CLASS SCHEDULE METHODS ---

  Future<void> scheduleClassAlerts({
    required int id,
    required String subject,
    required DateTime startTime,
  }) async {
    final now = DateTime.now();

    // 10 Minutes Before
    await _schedule(
      id: id + 1000,
      title: 'Class Reminder',
      body: '$subject starts in 10 minutes!',
      time: startTime.subtract(const Duration(minutes: 10)),
      now: now,
    );

    // 1 Minute Before
    await _schedule(
      id: id + 1001,
      title: 'Class Starting Soon',
      body: '$subject starts in 1 minute. Get ready!',
      time: startTime.subtract(const Duration(minutes: 1)),
      now: now,
    );
  }

  Future<void> cancelClassAlerts(int id) async {
    await _notifications.cancel(id: id + 1000);
    await _notifications.cancel(id: id + 1001);
  }

  Future<void> cancelNotification(int id) async {
    await cancelClassAlerts(id);
  }

  Future<void> sendTestNotification() async {
    await _schedule(
      id: 9999,
      title: "Test Alert",
      body: "If you see this, local notifications are working!",
      time: DateTime.now().add(const Duration(seconds: 5)),
      now: DateTime.now(),
    );
  }

  Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required DateTime time,
    required DateTime now,
  }) async {
    if (time.isBefore(now)) {
      debugPrint("Skipping Notification $id: Time $time is in the past.");
      return;
    }

    debugPrint("Scheduling Notification $id for $time");

    await _notifications.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(time, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}
