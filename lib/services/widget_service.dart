import 'package:home_widget/home_widget.dart';
import '../core/constants.dart';
import '../core/date_utils.dart';

/// Bidirectional sync between Flutter app and native Android widget.
class WidgetService {
  static const String _androidWidgetName = 'WaterWidgetProvider';

  /// Initialize background callback for widget interactions.
  static Future<void> initialize() async {
    await HomeWidget.registerInteractivityCallback(backgroundCallback);
  }

  /// Push current state to the native widget.
  static Future<void> syncToWidget({
    required int currentCount,
    required int dailyGoal,
    required int glassSizeMl,
  }) async {
    await Future.wait([
      HomeWidget.saveWidgetData<int>(SPKeys.currentCount, currentCount),
      HomeWidget.saveWidgetData<int>(SPKeys.dailyGoal, dailyGoal),
      HomeWidget.saveWidgetData<int>(SPKeys.glassSizeMl, glassSizeMl),
      HomeWidget.saveWidgetData<String>(
          SPKeys.lastResetDate, AppDateUtils.todayKey()),
    ]);
    await HomeWidget.updateWidget(
      androidName: _androidWidgetName,
    );
  }

  /// Read count from SharedPreferences (written by native widget).
  static Future<int> readWidgetCount() async {
    final count = await HomeWidget.getWidgetData<int>(SPKeys.currentCount);
    return count ?? 0;
  }
}

/// Top-level function — called by the OS when widget button is tapped.
@pragma('vm:entry-point')
Future<void> backgroundCallback(Uri? uri) async {
  if (uri?.host == 'addWater') {
    // Read current count, increment, write back
    final currentCount =
        await HomeWidget.getWidgetData<int>(SPKeys.currentCount) ?? 0;
    final newCount = currentCount + 1;
    await HomeWidget.saveWidgetData<int>(SPKeys.currentCount, newCount);

    // Also update the widget UI
    await HomeWidget.updateWidget(androidName: 'WaterWidgetProvider');
  }
}
