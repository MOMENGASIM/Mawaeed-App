import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'localization.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// يجب استدعاؤها مرة واحدة في main() قبل runApp
  Future<void> init() async {
    try {
      tz.initializeTimeZones();
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      try {
        tz.setLocalLocation(tz.getLocation(timeZoneName));
      } catch (e) {
        debugPrint(
          "Could not set local location to $timeZoneName, falling back to UTC: $e",
        );
        tz.setLocalLocation(tz.getLocation('UTC'));
      }

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

      await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          debugPrint("Notification clicked: ${details.payload}");
        },
      );

      // إنشاء القناة برمجياً لنظام أندرويد لضمان عملها
      const androidChannel = AndroidNotificationChannel(
        'appointment_channel',
        'تذكيرات المواعيد',
        description: 'إشعارات تذكير بمواعيدك الطبية',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(androidChannel);

      // طلب الإذن على Android 13+
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();

      debugPrint("Notification Service Initialized Successfully");
      
      // إعداد رسائل Firebase للعمل في الخلفية
      await setupFirebaseMessaging();

      // طلب أذونات إضافية لضمان العمل في الخلفية
      await requestPermissions();
    } catch (e) {
      debugPrint("Error initializing Notification Service: $e");
    }
  }

  /// طلب الأذونات اللازمة لعمل الإشعارات في وضع الخمول
  Future<void> requestPermissions() async {
    // إذن الإشعارات العادي
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    // إذن الجدولة الدقيقة (مهم جداً لـ Android 13+)
    if (await Permission.scheduleExactAlarm.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }

    // إذن تجاهل تحسين البطارية (يسمح للتطبيق بالعمل حتى لو الجهاز "خامل")
    // هذا الإذن يفتح إعدادات النظام للمستخدم ليوافق
    if (await Permission.ignoreBatteryOptimizations.isDenied) {
      await Permission.ignoreBatteryOptimizations.request();
    }
  }

  /// إعداد Firebase Messaging لاستقبال الإشعارات والتعامل معها
  Future<void> setupFirebaseMessaging() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // طلب الإذن (لنظام iOS و Android 13+)
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // الحصول على التوكن (مفيد لو عاوز ترسل إشعار لمستخدم معين من السيرفر)
    String? token = await messaging.getToken();
    debugPrint("Firebase Messaging Token: $token");

    // التعامل مع الرسائل والبرنامج مفتوح (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("Received a message while in foreground: ${message.messageId}");
      if (message.notification != null) {
        showInstantNotification(
          message.notification!.title ?? tr("إشعار جديد"),
          message.notification!.body ?? "",
        );
      }
    });

    // التعامل مع الضغط على الإشعار والتطبيق مقفول تماماً
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("Notification clicked to open app: ${message.data}");
    });
  }

  /// إرسال إشعار فوري (للاختبار)
  Future<void> showInstantNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'appointment_channel',
      'تذكيرات المواعيد',
      channelDescription: 'إشعارات تذكير بمواعيدك الطبية',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.show(0, title, body, details);
  }

  /// جدولة إشعار قبل الموعد بـ ساعة واحدة
  Future<void> scheduleAppointmentReminder({
    required String appointmentId,
    required DateTime appointmentDateTime,
    required String doctorName,
  }) async {
    var notifyTime = appointmentDateTime.subtract(const Duration(hours: 1));

    // لو وقت الإشعار فات (لأن الموعد قريب جداً - أقل من ساعة)
    if (notifyTime.isBefore(DateTime.now())) {
      // لو الموعد لسه ما جاش، نرسل الإشعار بعد 5 ثواني من الآن كنوع من التنبيه العاجل
      if (appointmentDateTime.isAfter(DateTime.now())) {
        notifyTime = DateTime.now().add(const Duration(seconds: 5));
        debugPrint(
          "Appointment is soon. Scheduling urgent reminder for 5 seconds from now.",
        );
      } else {
        debugPrint(
          "Skipping schedule: Appointment is in the past for $appointmentId",
        );
        return;
      }
    }

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
      interruptionLevel: InterruptionLevel.critical, // يجعل الإشعار يظهر حتى في وضع عدم الإزعاج أحياناً
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final notifId = appointmentId.hashCode.abs() % 2147483647;

    try {
      await _plugin.zonedSchedule(
        notifId,
        tr('تذكير بموعدك الطبي 🏥'),
        tr('موعدك مع دكتور ') + doctorName + tr(' بعد ساعة لا تنسَ'),
        tzTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint("Scheduled notification for $appointmentId at $tzTime");
    } catch (e) {
      debugPrint("Error scheduling notification: $e");
      // محاولة الجدولة بشكل غير دقيق إذا فشلت الدقيقة (بسبب أذونات أندرويد 14+)
      try {
        await _plugin.zonedSchedule(
          notifId,
          tr('تذكير بموعدك الطبي 🏥'),
          tr('موعدك مع دكتور ') + doctorName + tr(' بعد ساعة لا تنسَ'),
          tzTime,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        debugPrint(
          "Scheduled (inexact) notification for $appointmentId at $tzTime",
        );
      } catch (e2) {
        debugPrint("Failed to schedule even with inexact mode: $e2");
      }
    }
  }

  /// إلغاء إشعار موعد معين
  Future<void> cancelAppointmentReminder(String appointmentId) async {
    final notifId = appointmentId.hashCode.abs() % 2147483647;
    await _plugin.cancel(notifId);
    debugPrint("Cancelled notification for $appointmentId");
  }

  /// إلغاء جميع الإشعارات
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
    debugPrint("Cancelled all notifications");
  }
}
