import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Service for managing local push notifications and bill reminders.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  /// Initializes the local notification plugin and configures Android channels & timezones.
  Future<void> initialize() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        if (kDebugMode) {
          print('Notification tapped: ${details.payload}');
        }
      },
    );

    _isInitialized = true;
  }

  /// Explicitly requests notification permissions on Android 13+ (API level 33+).
  Future<bool> requestPermissions() async {
    await initialize();

    final androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      final granted = await androidImplementation.requestNotificationsPermission();
      return granted ?? false;
    }

    return true;
  }

  /// Checks if notification permissions have been granted on Android.
  Future<bool> arePermissionsGranted() async {
    await initialize();

    final androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      final granted = await androidImplementation.areNotificationsEnabled();
      return granted ?? false;
    }

    return true;
  }

  /// Schedules a local notification for an upcoming recurring bill.
  Future<void> scheduleBillReminder({
    required String billId,
    required String billName,
    required double amount,
    required DateTime dueDate,
    required int reminderDaysBefore,
    required bool isReminderEnabled,
  }) async {
    await initialize();

    final notificationId = billId.hashCode;
    await cancelBillReminder(billId); // Clear any existing reminder for this bill

    if (!isReminderEnabled) return;

    // Calculate target reminder date (9:00 AM on the calculated reminder date)
    final reminderDate = dueDate.subtract(Duration(days: reminderDaysBefore));
    final scheduledDateTime = DateTime(
      reminderDate.year,
      reminderDate.month,
      reminderDate.day,
      9, // 9:00 AM
      0,
    );

    // If scheduled time has already passed for this cycle, do not schedule
    if (scheduledDateTime.isBefore(DateTime.now())) return;

    const androidDetails = AndroidNotificationDetails(
      'bill_reminders_channel',
      'Bill Reminders',
      channelDescription: 'Notifications for upcoming recurring bill due dates',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    final scheduledTZ = tz.TZDateTime.from(scheduledDateTime, tz.local);

    final daysText = reminderDaysBefore == 0
        ? 'due today'
        : 'due in $reminderDaysBefore day${reminderDaysBefore > 1 ? 's' : ''}';

    await _notificationsPlugin.zonedSchedule(
      notificationId,
      'Bill Due Reminder: $billName',
      '$billName (₱${amount.toStringAsFixed(2)}) is $daysText.',
      scheduledTZ,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: billId,
    );
  }

  /// Cancels a previously scheduled notification for a given bill ID.
  Future<void> cancelBillReminder(String billId) async {
    await initialize();
    await _notificationsPlugin.cancel(billId.hashCode);
  }
}
