import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

const String noteChannelId = 'student_pal_note_reminders';
const String noteChannelName = 'Study Note Reminders';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String channelId = 'studentpal_channel';
  static const String channelName = 'StudentPal Alerts';

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    
    tz_data.initializeTimeZones();
    try {
      final tzName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzName.toString()));
    } catch (e) {
      tz.setLocalLocation(tz.getLocation('Asia/Manila'));
    }

    final InitializationSettings initSettings = _buildInitializationSettings();

    await _notifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        debugPrint("Notification tapped: ${details.payload}");
      },
    );

    _isInitialized = true;
    
    await _setupPlatformChannels();
  }

  InitializationSettings _buildInitializationSettings() {
    if (Platform.isAndroid) {
      return const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      );
    } else if (Platform.isIOS || Platform.isMacOS) {
      return const InitializationSettings(
        iOS: DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        ),
        macOS: DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        ),
      );
    } else if (Platform.isLinux) {
      return const InitializationSettings(
        linux: LinuxInitializationSettings(defaultActionName: 'Open'),
      );
    }
    return const InitializationSettings();
  }

  Future<void> _setupPlatformChannels() async {
    if (Platform.isAndroid) {
      await _setupAndroidChannel();
    }
    
    if (Platform.isIOS || Platform.isMacOS) {
      await _requestDarwinPermissions();
    }
  }

  Future<void> _setupAndroidChannel() async {
    try {
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            channelId,
            channelName,
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        );
      
        await androidPlugin.requestExactAlarmsPermission();
      }
    } catch (e) {
      debugPrint("Error setting up Android channel: $e");
    }
  }

  Future<void> _requestDarwinPermissions() async {
    try {
      if (Platform.isIOS) {
        await _notifications
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true);
      }
      if (Platform.isMacOS) {
        await _notifications
            .resolvePlatformSpecificImplementation<
                MacOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true);
      }
    } catch (e) {
      debugPrint("Error requesting Darwin permissions: $e");
    }
  }

  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      await _requestAndroidPermissions();
    } else if (Platform.isIOS || Platform.isMacOS) {
      await _requestDarwinPermissions();
    }
  }

  Future<void> _requestAndroidPermissions() async {
    try {
      final android = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
      await android?.requestExactAlarmsPermission();
    } catch (e) {
      debugPrint("Error requesting Android permissions: $e");
    }
  }

  Future<void> scheduleClassAlerts({
    required int id,
    required String subject,
    required DateTime startTime,
  }) async {
    if (!_isInitialized) {
      await init();
    }
    
    await _cancelClassNotifications(id);

    final now = DateTime.now();

    final tenMinBefore = startTime.subtract(const Duration(minutes: 10));
    if (tenMinBefore.isAfter(now)) {
      await _scheduleNotification(
        id: id * 10,
        title: 'Class Starting Soon',
        body: '$subject starts in 10 minutes',
        scheduledTime: tenMinBefore,
        payload: 'class:$id',
      );
    }

    final fiveMinBefore = startTime.subtract(const Duration(minutes: 5));
    if (fiveMinBefore.isAfter(now)) {
      await _scheduleNotification(
        id: id * 10 + 1,
        title: 'Class Starting in 5 Minutes',
        body: '$subject starts in 5 minutes',
        scheduledTime: fiveMinBefore,
        payload: 'class:$id',
      );
    }

    final oneMinBefore = startTime.subtract(const Duration(minutes: 1));
    if (oneMinBefore.isAfter(now)) {
      await _scheduleNotification(
        id: id * 10 + 2,
        title: 'Class Starting Now',
        body: '$subject starts in 1 minute',
        scheduledTime: oneMinBefore,
        payload: 'class:$id',
      );
    }
  }

  Future<void> _cancelClassNotifications(int id) async {
    await _notifications.cancel(id: id * 10);
    await _notifications.cancel(id: id * 10 + 1);
    await _notifications.cancel(id: id * 10 + 2);
  }

  Future<void> scheduleAssignmentAlerts({
    required int id,
    required String title,
    required DateTime deadline,
  }) async {
    if (!_isInitialized) {
      await init();
    }
    
    final baseId = 1000 + id * 4;
    await _cancelAssignmentNotifications(baseId);

    final now = DateTime.now();

    final threeDaysBefore = deadline.subtract(const Duration(days: 3));
    if (threeDaysBefore.isAfter(now)) {
      await _scheduleNotification(
        id: baseId,
        title: 'Assignment Due in 3 Days',
        body: '$title is due in 3 days',
        scheduledTime: threeDaysBefore,
        payload: 'assignment:$id',
      );
    }

    final tenHoursBefore = deadline.subtract(const Duration(hours: 10));
    if (tenHoursBefore.isAfter(now)) {
      await _scheduleNotification(
        id: baseId + 1,
        title: 'Assignment Due in 10 Hours',
        body: '$title is due in 10 hours',
        scheduledTime: tenHoursBefore,
        payload: 'assignment:$id',
      );
    }

    final threeHoursBefore = deadline.subtract(const Duration(hours: 3));
    if (threeHoursBefore.isAfter(now)) {
      await _scheduleNotification(
        id: baseId + 2,
        title: 'Assignment Due in 3 Hours',
        body: '$title is due in 3 hours',
        scheduledTime: threeHoursBefore,
        payload: 'assignment:$id',
      );
    }

    final oneHourBefore = deadline.subtract(const Duration(hours: 1));
    if (oneHourBefore.isAfter(now)) {
      await _scheduleNotification(
        id: baseId + 3,
        title: 'Assignment Due in 1 Hour',
        body: '$title is due in 1 hour',
        scheduledTime: oneHourBefore,
        payload: 'assignment:$id',
      );
    }
  }

  Future<void> _cancelAssignmentNotifications(int baseId) async {
    await _notifications.cancel(id: baseId);
    await _notifications.cancel(id: baseId + 1);
    await _notifications.cancel(id: baseId + 2);
    await _notifications.cancel(id: baseId + 3);
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    debugPrint("Scheduling Notification $id for $scheduledTime: $title");

    try {
      await _notifications.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            importance: Importance.max,
            priority: Priority.max,
            showWhen: true,
          ),
          iOS: DarwinNotificationDetails(),
          macOS: DarwinNotificationDetails(),
        ),
      );
    } catch (e) {
      debugPrint("Error scheduling notification $id: $e");
    }
  }

  Future<void> cancelNotification(int id) async {
    await _cancelClassNotifications(id);
  }

  Future<void> cancelAssignmentNotifications(int id) async {
    final baseId = 1000 + id * 4;
    await _cancelAssignmentNotifications(baseId);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<void> sendTestNotification() async {
    if (!_isInitialized) {
      await init();
    }
    
    await _scheduleNotification(
      id: 9999,
      title: "Test Alert",
      body: "If you see this, local notifications are working!",
      scheduledTime: DateTime.now().add(const Duration(seconds: 5)),
    );
  }

  Future<void> scheduleNoteReminders({
    required int noteId,
    required String noteTitle,
    required DateTime reminderTime,
  }) async {
    if (!_isInitialized) {
      await init();
    }
    
    final now = DateTime.now();
    final id = noteId + 2000;

    if (reminderTime.isAfter(now)) {
      await _scheduleNotification(
        id: id,
        title: 'Study Reminder',
        body: 'Time to review: $noteTitle',
        scheduledTime: reminderTime,
        payload: 'note:$noteId',
      );
    }
  }

  Future<void> cancelNoteReminder(int noteId) async {
    final id = noteId + 2000;
    await _notifications.cancel(id: id);
  }

  Future<void> cancelAllNoteReminders() async {
    for (int i = 0; i < 1000; i++) {
      await _notifications.cancel(id: 2000 + i);
    }
  }

  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) {
      await init();
    }

    try {
      await _notifications.show(
        id: id,
        title: title,
        body: body,
        payload: payload,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            importance: Importance.max,
            priority: Priority.max,
          ),
          iOS: DarwinNotificationDetails(),
          macOS: DarwinNotificationDetails(),
        ),
      );
    } catch (e) {
      debugPrint("Error showing instant notification: $e");
    }
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
}