import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:io' show Platform;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidImplementation?.requestNotificationsPermission();
    } else if (Platform.isIOS) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  // --- 1. RUTINA DIARIA (MAÑANA Y NOCHE) ---
  Future<void> scheduleDailyRoutine() async {
    // Notificación de la MAÑANA (9:00 AM) - Motivación / Recordatorio
    await _scheduleDaily(
        id: 888,
        title: '🌞 Buenos días, Financiero',
        body: '¿Tienes gastos planeados para hoy? Revisa tu presupuesto.',
        hour: 9,
        minute: 0);

    // Notificación de la NOCHE (8:00 PM) - Registro (Racha)
    await _scheduleDaily(
        id: 999,
        title: '¡No rompas tu racha! 🔥',
        body: 'Tómate 1 minuto para registrar tus gastos del día.',
        hour: 20,
        minute: 0);
  }

  Future<void> _scheduleDaily(
      {required int id,
      required String title,
      required String body,
      required int hour,
      required int minute}) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_routine',
          'Rutina Diaria',
          channelDescription: 'Avisos de mañana y noche',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Se repite diariamente
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  // --- 2. PAGOS FIJOS (RECORDATORIOS) ---
  // Programa una notificación para una fecha específica
  Future<void> schedulePaymentReminder(
      {required int id, required String title, required DateTime date}) async {
    // Convertimos DateTime a TZDateTime
    final tz.TZDateTime scheduledDate = tz.TZDateTime.from(date, tz.local);

    // Si la fecha ya pasó, no programamos nada
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      '📅 Pago Cercano: $title',
      'Recuerda que tienes un pago pendiente mañana.',
      scheduledDate.subtract(const Duration(days: 1)), // Avisar 1 día antes
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'payments_channel',
          'Pagos Fijos',
          channelDescription: 'Recordatorios de suscripciones y servicios',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // Cancelar todas las notificaciones (útil para limpiar al actualizar)
  Future<void> cancelAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
