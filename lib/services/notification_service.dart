import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  NotificationService._init();

  Future<void> init() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(settings: initSettings);

    if (!kIsWeb) {
      final androidImplementation = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidImplementation?.requestNotificationsPermission();
      await androidImplementation?.requestExactAlarmsPermission();

      await scheduleAllReminders();
    }
  }

  Future<void> scheduleAllReminders() async {
    // 1. تذكير ليلة الجمعة بدعاء كميل (مساء كل خميس الساعة 8:30 مساءً)
    await _notifications.zonedSchedule(
      id: 101,
      title: 'ليلة الجمعة المباركة - دعاء كميل',
      body:
          'حان وقت قراءة دعاء كميل، نسألكم الدعاء وإهداء ثوابه لروح والدي وروح المرحومة زوجتي تحرير جابر (أم علي)',
      scheduledDate: _nextInstanceOfThursdayNight(),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'duas_channel',
          'تذكير الأدعية والزيارات',
          channelDescription: 'تنبيهات أسبوعية ليلة الجمعة',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );

    // 2. تذكير يومي بمتابعة قضاء الفروض (الساعة 9:30 مساءً)
    await _notifications.zonedSchedule(
      id: 102,
      title: 'متابعة قضاء الفروض اليومية',
      body: 'لا تنسَ تسجيل ما قضيته اليوم من صلوات أو صيام في التطبيق',
      scheduledDate: _nextInstanceOfTime(21, 30),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_qadaa_channel',
          'تذكير قضاء الفروض',
          channelDescription: 'تنبيه يومي لمتابعة الصلوات والصيام',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextInstanceOfThursdayNight() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      20,
      30,
    );
    while (scheduledDate.weekday != DateTime.thursday ||
        scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
