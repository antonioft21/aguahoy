class AppDateUtils {
  AppDateUtils._();

  /// Returns today's date as 'yyyy-MM-dd'.
  static String todayKey() {
    final now = DateTime.now();
    return _format(now);
  }

  /// Formats a DateTime as 'yyyy-MM-dd'.
  static String _format(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  /// Parses a 'yyyy-MM-dd' key back to DateTime.
  static DateTime parseKey(String key) {
    return DateTime.parse(key);
  }

  /// Returns a formatted label like "26 Feb".
  static String shortLabel(String key) {
    final d = parseKey(key);
    const months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
    ];
    return '${d.day} ${months[d.month - 1]}';
  }

  /// Returns the key for N days ago.
  static String daysAgoKey(int daysAgo) {
    final d = DateTime.now().subtract(Duration(days: daysAgo));
    return _format(d);
  }
}
