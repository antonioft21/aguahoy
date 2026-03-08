import 'package:health/health.dart';

class HealthService {
  static final Health _health = Health();
  static bool _authorized = false;

  /// Request Health Connect permissions. Returns true if granted.
  static Future<bool> requestPermissions() async {
    try {
      final types = [HealthDataType.WATER];
      final permissions = [HealthDataAccess.READ_WRITE];

      _authorized = await _health.requestAuthorization(
        types,
        permissions: permissions,
      );
      return _authorized;
    } catch (_) {
      return false;
    }
  }

  /// Check if we have permissions without requesting.
  static Future<bool> hasPermissions() async {
    try {
      final types = [HealthDataType.WATER];
      final permissions = [HealthDataAccess.READ_WRITE];
      final result = await _health.hasPermissions(
        types,
        permissions: permissions,
      );
      _authorized = result ?? false;
      return _authorized;
    } catch (_) {
      return false;
    }
  }

  /// Write water intake to Health Connect.
  /// [ml] is the amount in milliliters.
  static Future<bool> writeWaterIntake(int ml) async {
    if (!_authorized) return false;
    try {
      final now = DateTime.now();
      return await _health.writeHealthData(
        value: ml.toDouble(),
        type: HealthDataType.WATER,
        startTime: now.subtract(const Duration(minutes: 1)),
        endTime: now,
        unit: HealthDataUnit.MILLILITER,
      );
    } catch (_) {
      return false;
    }
  }

  /// Read today's water intake from Health Connect.
  static Future<double> readTodayWaterMl() async {
    if (!_authorized) return 0;
    try {
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);
      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.WATER],
        startTime: midnight,
        endTime: now,
      );

      var totalMl = 0.0;
      for (final point in data) {
        if (point.value is NumericHealthValue) {
          totalMl += (point.value as NumericHealthValue).numericValue;
        }
      }
      return totalMl;
    } catch (_) {
      return 0;
    }
  }
}
