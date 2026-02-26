package com.aguahoy.aguahoy

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class WaterWidgetProvider : HomeWidgetProvider() {

    companion object {
        // Must match SPKeys in constants.dart
        private const val KEY_CURRENT_COUNT = "water_current_count"
        private const val KEY_DAILY_GOAL = "water_daily_goal"
        private const val KEY_GLASS_SIZE_ML = "water_glass_size_ml"
        private const val KEY_LAST_RESET_DATE = "water_last_reset_date"
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        // Check daily reset
        val todayKey = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
        val lastReset = widgetData.getString(KEY_LAST_RESET_DATE, null)

        var currentCount: Int
        val dailyGoal: Int
        val glassSizeMl: Int

        if (lastReset != todayKey) {
            // New day — reset counter natively
            currentCount = 0
            widgetData.edit()
                .putInt(KEY_CURRENT_COUNT, 0)
                .putString(KEY_LAST_RESET_DATE, todayKey)
                .apply()
        } else {
            currentCount = widgetData.getInt(KEY_CURRENT_COUNT, 0)
        }

        dailyGoal = widgetData.getInt(KEY_DAILY_GOAL, 8)
        glassSizeMl = widgetData.getInt(KEY_GLASS_SIZE_ML, 250)

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.water_widget).apply {
                // Update counter text
                setTextViewText(R.id.widget_counter, "$currentCount / $dailyGoal")

                // Update progress bar
                val progressPercent = if (dailyGoal > 0) {
                    ((currentCount.toFloat() / dailyGoal) * 100).toInt().coerceIn(0, 100)
                } else 0
                setProgressBar(R.id.widget_progress, 100, progressPercent, false)

                // Update ml label
                val currentMl = currentCount * glassSizeMl
                val goalMl = dailyGoal * glassSizeMl
                setTextViewText(R.id.widget_ml, "$currentMl / $goalMl ml")

                // Open app on widget tap (not on button)
                val launchIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java
                )
                setOnClickPendingIntent(R.id.widget_title, launchIntent)

                // Add glass button — triggers background Dart callback
                val addWaterIntent = HomeWidgetBackgroundIntent.getBroadcast(
                    context,
                    Uri.parse("aguahoy://addWater")
                )
                setOnClickPendingIntent(R.id.widget_add_btn, addWaterIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
