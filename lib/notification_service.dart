import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// يجب استدعاؤها مرة واحدة في main() قبل runApp
  Future<void> init() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(initSettings);

    // طلب الإذن على Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  /// جدولة إشعار قبل الموعد بـ 24 ساعة
  /// [appointmentId] يُستخدم كـ ID فريد للإشعار حتى نتمكن من إلغائه لاحقاً
  /// [appointmentDateTime] وقت الموعد الكامل
  /// [doctorName] اسم الطبيب لعرضه في الإشعار
  Future<void> scheduleAppointmentReminder({
    required String appointmentId,
    required DateTime appointmentDateTime,
    required String doctorName,
  }) async {
    // وقت الإشعار = وقت الموعد - 24 ساعة
    final notifyTime = appointmentDateTime.subtract(const Duration(hours: 24));

    // لو الوقت فات (أقل من الآن)، لا تجدول
    if (notifyTime.isBefore(DateTime.now())) return;

    final tzTime = tz.TZDateTime.from(notifyTime, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'appointment_channel',
      'تذكيرات المواعيد',
      channelDescription: 'إشعارات تذكير بمواعيدك الطبية',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // نحول appointmentId (String) لـ int hash للاستخدام كـ ID
    final notifId = appointmentId.hashCode.abs() % 2147483647;

    await _plugin.zonedSchedule(
      notifId,
      'تذكير بموعدك الطبي 🏥',
      'موعدك مع $doctorName باقي له 24 ساعة. لا تنسَ!',
      tzTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// إلغاء إشعار موعد معين (عند الإلغاء)
  Future<void> cancelAppointmentReminder(String appointmentId) async {
    final notifId = appointmentId.hashCode.abs() % 2147483647;
    await _plugin.cancel(notifId);
  }

  /// إلغاء جميع الإشعارات
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
