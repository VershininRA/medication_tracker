// lib/services/notification_service.dart
// Сервис для работы с локальными уведомлениями

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // 🔹 Инициализация (вызывать один раз при старте приложения)
  Future<void> init() async {
    // Инициализация timezone
    tz.initializeTimeZones();

    // Настройки для Android
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Настройки для iOS
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        // Обработка нажатия на уведомление
        print('🔔 Notification tapped: ${response.payload}');
      },
    );

    // Запрос разрешений для Android 13+
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // 🔹 Показать простое уведомление (для теста)
  Future<void> showSimpleNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'medication_channel', // ID канала
      'Напоминания о лекарствах', // Название канала
      channelDescription: 'Уведомления о времени приёма препаратов',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iosDetails =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }

  // 🔹 Запланировать уведомление на конкретное время
  Future<void> scheduleMedicationReminder({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required List<int> daysOfWeek, // 1=Пн, 7=Вс
    String? payload,
  }) async {
    // Создаём расписание для каждого дня недели
    for (int day in daysOfWeek) {
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // Если время уже прошло сегодня — планируем на следующий раз в этом дне недели
      if (scheduledDate.isBefore(now)) {
        // Вычисляем, сколько дней до следующего нужного дня недели
        int daysUntil = (day - now.weekday + 7) % 7;
        if (daysUntil == 0) daysUntil = 7; // если сегодня — то на следующей неделе
        scheduledDate = scheduledDate.add(Duration(days: daysUntil));
      }

      await _notificationsPlugin.zonedSchedule(
        id + day, // Уникальный ID для каждого дня
        title,
        body,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'medication_channel',
            'Напоминания о лекарствах',
            channelDescription: 'Уведомления о времени приёма препаратов',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
      );
    }
  }

  // 🔹 Отменить уведомление по ID
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  // 🔹 Отменить все уведомления
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}