/// SharedPreferences keys — shared between Flutter and Kotlin widget.
/// IMPORTANT: Any change here must be mirrored in WaterWidgetProvider.kt.
class SPKeys {
  SPKeys._();

  static const String currentCount = 'water_current_count';
  static const String dailyGoal = 'water_daily_goal';
  static const String glassSizeMl = 'water_glass_size_ml';
  static const String lastResetDate = 'water_last_reset_date';
  static const String isPremium = 'water_is_premium';
  static const String reminderStartHour = 'water_reminder_start_hour';
  static const String reminderEndHour = 'water_reminder_end_hour';
  static const String reminderIntervalMin = 'water_reminder_interval_min';
  static const String remindersEnabled = 'water_reminders_enabled';
  static const String onboardingComplete = 'water_onboarding_complete';
  static const String darkMode = 'water_dark_mode';
  static const String streakFreezes = 'water_streak_freezes';
  static const String lastFreezeResetWeek = 'water_last_freeze_reset_week';
  static const String effectiveHydrationMl = 'water_effective_hydration_ml';
  static const String selectedBeverageId = 'water_selected_beverage_id';
  static const String userWeightKg = 'water_user_weight_kg';
  static const String activityLevel = 'water_activity_level'; // 0=sedentary, 1=moderate, 2=active
  static const String goalSuggestionDismissedAt = 'water_goal_suggestion_dismissed';
  static const String accentColorIndex = 'water_accent_color_index';
  static const String soundEnabled = 'water_sound_enabled';
  static const String healthConnectEnabled = 'water_health_connect_enabled';
  static const String todayEntries = 'water_today_entries'; // JSON list
  static const String dailyGoalMl = 'water_daily_goal_ml'; // int
}

class Defaults {
  Defaults._();

  static const int dailyGoal = 8;
  static const int glassSizeMl = 250;
  static const int reminderStartHour = 8;
  static const int reminderEndHour = 22;
  static const int reminderIntervalMin = 60;
}

class HiveBoxes {
  HiveBoxes._();

  static const String history = 'history';
  static const String achievements = 'achievements';
}
