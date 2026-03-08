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
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getInt(SPKeys.currentCount) ?? 0;
      await prefs.setInt(SPKeys.currentCount, current + 1);
    }
  }

  /// Smart message based on current progress.
  static Future<({String title, String body, Importance importance})>
      _smartMessage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final count = prefs.getInt(SPKeys.currentCount) ?? 0;
      final goal = prefs.getInt(SPKeys.dailyGoal) ?? Defaults.dailyGoal;
      final hour = DateTime.now().hour;

      final progress = goal > 0 ? count / goal : 0.0;
      final remaining = goal - count;

      if (progress >= 1.0) {
        return (
          title: 'Objetivo cumplido!',
          body: 'Ya has bebido $count vasos. Sigue asi!',
          importance: Importance.low,
        );
      }

      // Afternoon and behind schedule
      if (hour >= 15 && progress < 0.5) {
        return (
          title: 'Vas un poco atrasado!',
          body: 'Te faltan $remaining vasos. Ponte al dia!',
          importance: Importance.high,
        );
      }

      // Evening push
      if (hour >= 19 && progress < 0.75) {
        return (
          title: 'Ultimo esfuerzo!',
          body: 'Solo $remaining vasos mas para tu objetivo.',
          importance: Importance.high,
        );
      }

      // Morning encouragement
      if (hour < 12 && count == 0) {
        return (
          title: 'Buenos dias!',
          body: 'Empieza el dia con un vaso de agua.',
          importance: Importance.defaultImportance,
        );
      }

      // Default
      return (
        title: 'Hora de hidratarse!',
        body: 'Llevas $count/$goal vasos. Sigue asi!',
        importance: Importance.defaultImportance,
      );
    } catch (_) {
      return (
        title: 'Hora de hidratarse!',
        body: 'No olvides tomar un vaso de agua.',
        importance: Importance.defaultImportance,
      );
    }
  }

  /// Schedule repeating reminders between [startHour] and [endHour]
  /// every [intervalMin] minutes.
  static Future<void> scheduleReminders({
    required int startHour,
    required int endHour,
    required int intervalMin,
  }) async {
    await cancelAll();

    final now = tz.TZDateTime.now(tz.local);
    final msg = await _smartMessage();
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

        if (scheduledDate.isBefore(now)) {
          scheduledDate = scheduledDate.add(const Duration(days: 1));
        }

        await _plugin.zonedSchedule(
          id++,
          msg.title,
          msg.body,
          scheduledDate,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'water_reminders',
              'Recordatorios de agua',
              channelDescription: 'Recordatorios para beber agua',
              importance: msg.importance,
              priority: msg.importance == Importance.high
                  ? Priority.high
                  : Priority.defaultPriority,
              actions: const [
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
