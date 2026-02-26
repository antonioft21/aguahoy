import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import '../core/constants.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _addGlassActionId = 'add_glass';

  static Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );
  }

  /// Called when user taps a notification or an action button.
  static void _onNotificationResponse(NotificationResponse response) async {
    if (response.actionId == _addGlassActionId) {
      // Quick-add a glass directly from the notification
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getInt(SPKeys.currentCount) ?? 0;
      await prefs.setInt(SPKeys.currentCount, current + 1);
    }
  }

  /// Schedule repeating reminders between [startHour] and [endHour]
  /// every [intervalMin] minutes.
  static Future<void> scheduleReminders({
    required int startHour,
    required int endHour,
    required int intervalMin,
  }) async {
    // Cancel existing reminders first
    await cancelAll();

    final now = tz.TZDateTime.now(tz.local);
    var id = 0;

    for (var hour = startHour; hour < endHour; hour++) {
      for (var min = 0; min < 60; min += intervalMin) {
        var scheduledDate = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
          hour,
          min,
        );

        // If the time has passed today, schedule for tomorrow
        if (scheduledDate.isBefore(now)) {
          scheduledDate = scheduledDate.add(const Duration(days: 1));
        }

        await _plugin.zonedSchedule(
          id++,
          'Hora de hidratarse!',
          'No olvides tomar un vaso de agua',
          scheduledDate,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'water_reminders',
              'Recordatorios de agua',
              channelDescription: 'Recordatorios para beber agua',
              importance: Importance.defaultImportance,
              priority: Priority.defaultPriority,
              actions: [
                AndroidNotificationAction(
                  _addGlassActionId,
                  '+ Vaso',
                  showsUserInterface: false,
                ),
              ],
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      }
    }
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
