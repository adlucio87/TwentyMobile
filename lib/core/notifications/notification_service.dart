import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../../domain/models/task.dart';
import '../router/router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';

String? _initialRoute;
String? get initialNotificationRoute => _initialRoute;
void clearInitialNotificationRoute() {
  _initialRoute = null;
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // Canali notifica
  static const String _taskChannelId = 'task_reminders';
  static const String _taskChannelName = 'Task Reminders';
  static const String _overdueChannelId = 'overdue_tasks';
  static const String _overdueChannelName = 'Overdue';

  Future<void> initialize() async {
    tz_data.initializeTimeZones();

    try {
      // Imposta timezone locale del device
      String timezoneName = await _getLocalTimezone();
      
      // La timezone locale restituita da Dart su Android può essere "GMT+2" o "CEST", 
      // che non sono nomi IANA validi. Il pacchetto timezone si aspetta nomi tipo "Europe/Rome".
      try {
        tz.setLocalLocation(tz.getLocation(timezoneName));
      } catch (e) {
        // Fallback a UTC se il nome non è riconosciuto
        tz.setLocalLocation(tz.getLocation('UTC'));
      }
    } catch (e) {
      // Qualsiasi altro errore durante l'inizializzazione timezone non deve bloccare l'app
      try {
        tz.setLocalLocation(tz.getLocation('UTC'));
      } catch (_) {}
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: false, // chiediamo noi il permesso
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: iosSettings,
    );

    try {
      await _plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
        onDidReceiveBackgroundNotificationResponse: _onNotificationTappedBackground,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Notification plugin initialization failed: $e');
    }

    // Controlla se l'app è stata aperta da una notifica
    final NotificationAppLaunchDetails? notificationAppLaunchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
      _handlePayload(notificationAppLaunchDetails!.notificationResponse?.payload);
    }

    // Crea canali Android
    await _createAndroidChannels();
  }

  Future<void> _createAndroidChannels() async {
    const AndroidNotificationChannel taskChannel = AndroidNotificationChannel(
      _taskChannelId,
      _taskChannelName,
      description: 'Reminders for your tasks',
      importance: Importance.high,
      playSound: true,
    );

    const AndroidNotificationChannel overdueChannel = AndroidNotificationChannel(
      _overdueChannelId,
      _overdueChannelName,
      description: 'Overdue tasks that require attention',
      importance: Importance.max,
      playSound: true,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(taskChannel);

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(overdueChannel);
  }

  // Richiesta permesso notifiche (chiamare durante onboarding)
  Future<bool> requestPermission() async {
    // iOS / macOS
    final bool? iosGranted = await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    // Android 13+
    final bool? androidGranted = await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    return iosGranted ?? androidGranted ?? false;
  }

  // Schedula notifica per un task
  Future<void> scheduleTaskReminder(Task task) async {
    try {
      if (task.dueAt == null) return;
      if (task.dueAt!.hour == 0 && task.dueAt!.minute == 0) return; // solo data, nessuna notifica
      if (task.dueAt!.isBefore(DateTime.now())) return; // non schedula passati
      if (task.completed == true) return;

      final prefs = await SharedPreferences.getInstance();
      final notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      if (!notificationsEnabled) return;

      final advanceMinutes = prefs.getInt('reminder_advance_minutes') ?? 30;

      // Notifica anticipata
      final reminderTime = task.dueAt!.subtract(Duration(minutes: advanceMinutes));
      if (reminderTime.isAfter(DateTime.now())) {
        final tzReminderTime = tz.TZDateTime.from(reminderTime, tz.local);

        await _plugin.zonedSchedule(
          id: _taskToNotificationId(task.id),
          title: '⏰ Task expiring in $advanceMinutes min',
          body: task.title,
          scheduledDate: tzReminderTime,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              _taskChannelId,
              _taskChannelName,
              importance: Importance.high,
              priority: Priority.high,
              styleInformation: BigTextStyleInformation(
                task.title,
              ),
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
            macOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: task.id, // usato per navigare al task al tap
        );
      }

      // Schedula anche notifica esatta all'ora del task
      await _plugin.zonedSchedule(
        id: _taskToNotificationId(task.id) + 1,
        title: '🔔 Task overdue now',
        body: task.title,
        scheduledDate: tz.TZDateTime.from(task.dueAt!, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _taskChannelId,
            _taskChannelName,
            importance: Importance.max,
            priority: Priority.max,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
          macOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: task.id,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Notification scheduleTaskReminder failed: $e');
    }
  }

  // Cancella notifica per un task (quando completato o eliminato)
  Future<void> cancelTaskReminder(String taskId) async {
    try {
      await _plugin.cancel(id: _taskToNotificationId(taskId));
      await _plugin.cancel(id: _taskToNotificationId(taskId) + 1);
    } catch (e) {
      if (kDebugMode) debugPrint('Notification cancelTaskReminder failed: $e');
    }
  }

  // Cancella tutte le notifiche
  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (e) {
      if (kDebugMode) debugPrint('Notification cancelAll failed: $e');
    }
  }

  // Sincronizza tutte le notifiche con i task attuali
  Future<void> syncTaskNotifications(List<Task> tasks) async {
    try {
      // Cancella tutte le notifiche esistenti
      await cancelAll();

      final prefs = await SharedPreferences.getInstance();

      // Reschedula solo i task futuri non completati
      for (final task in tasks) {
        if (task.dueAt != null &&
            task.dueAt!.isAfter(DateTime.now()) &&
            task.completed != true) {

          // Verifica se la notifica è attiva localmente per questo task (di base sì)
          final isNotifEnabled = prefs.getBool('task_notif_${task.id}') ?? true;
          if (isNotifEnabled) {
            await scheduleTaskReminder(task);
          }
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Notification syncTaskNotifications failed: $e');
    }
  }

  // Notifica overdue giornaliera (alle 9:00 se ci sono task scaduti)
  Future<void> scheduleOvernightSummary(int overdueCount) async {
    try {
      if (overdueCount == 0) {
        await _plugin.cancel(id: 999999); // cancella se non ci sono scaduti
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      if (!notificationsEnabled) return;

      final now = DateTime.now();
      var scheduledTime = DateTime(now.year, now.month, now.day, 9, 0);
      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }

      await _plugin.zonedSchedule(
        id: 999999,
        title: '📋 $overdueCount overdue task${overdueCount == 1 ? '' : 's'}',
        body: 'You have tasks that require your attention',
        scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _overdueChannelId,
            _overdueChannelName,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
          macOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time, // ripeti ogni giorno
        payload: 'overdue',
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Notification scheduleOvernightSummary failed: $e');
    }
  }

  // Converti task ID stringa in int per notifica
  int _taskToNotificationId(String taskId) =>
      taskId.hashCode.abs() % 2147483647;

  Future<String> _getLocalTimezone() async {
    try {
      // Su iOS/macOS usa il timezone del device
      return DateTime.now().timeZoneName;
    } catch (_) {
      return 'UTC'; // fallback sicuro
    }
  }
}

// Callback tap notifica — deve essere top-level function
@pragma('vm:entry-point')
void _onNotificationTappedBackground(NotificationResponse response) {
  // gestito da _onNotificationTapped quando l'app si riapre
}

void _onNotificationTapped(NotificationResponse response) {
  _handlePayload(response.payload);
}

void _handlePayload(String? payload) {
  if (payload == null) return;

  if (payload == 'overdue') {
    _initialRoute = '/tasks';
  } else {
    _initialRoute = '/tasks/$payload';
  }

  if (navigatorKey.currentContext != null) {
    navigatorKey.currentContext!.go(_initialRoute!);
    clearInitialNotificationRoute();
  }
}
