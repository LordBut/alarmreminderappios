// lib/services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;

import '../models/schedule_model.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class NotificationService {
  /// Initialize once at app start (call from main)
  static Future<void> init() async {
    // Initialize timezone database (only once)
    tzdata.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();

    const initSettings =
        InitializationSettings(android: androidInit, iOS: iosInit);

    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        // Handle taps on notifications here.
        // response.payload will contain the payload you set when scheduling (e.g., schedule doc id)
      },
    );
  }

  /// Schedule a daily repeating notification at given hour/minute (local timezone)
  /// - `id` must be unique per scheduled notification (use ScheduleModel.intId or similar).
  /// - If `repeats` is true, the notification will repeat daily at the specified local time.
  static Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    bool repeats = true,
    String? payload,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    // If time already passed today, schedule for tomorrow
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'genevolut_channel',
        'Scheduled Reminders',
        channelDescription: 'User scheduled reminders',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    // zonedSchedule from plugin v17:
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      details,
      // If repeats is true then repeat daily at same time; otherwise schedule once.
      matchDateTimeComponents:
          repeats ? DateTimeComponents.time : null,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  /// Schedule using a ScheduleModel
  static Future<void> scheduleFromModel(ScheduleModel model) async {
    if (!model.enabled) return;
    await scheduleDaily(
      id: model.intId,
      title: model.title,
      body: model.body,
      hour: model.hour,
      minute: model.minute,
      repeats: model.repeats,
      payload: model.id,
    );
  }

  /// Cancel a scheduled notification by id
  static Future<void> cancel(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  /// Cancel all scheduled notifications on this device
  static Future<void> cancelAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
