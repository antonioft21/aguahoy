import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:aguahoy/models/day_record.dart';
import 'package:aguahoy/services/history_service.dart';
import 'dart:io';

void main() {
  late HistoryService historyService;
  late Directory tempDir;

  setUpAll(() {
    Hive.registerAdapter(DayRecordAdapter());
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
    historyService = HistoryService();
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('saveDay and getDay round-trip', () async {
    final record = DayRecord(
      dateKey: '2026-02-25',
      glasses: 6,
      goalGlasses: 8,
      glassSizeMl: 250,
    );

    await historyService.saveDay(record);
    final retrieved = await historyService.getDay('2026-02-25');

    expect(retrieved, isNotNull);
    expect(retrieved!.glasses, 6);
    expect(retrieved.goalGlasses, 8);
    expect(retrieved.goalMet, false);
  });

  test('getRecentDays returns records in order', () async {
    final now = DateTime.now();
    for (var i = 0; i < 5; i++) {
      final d = now.subtract(Duration(days: i));
      final key =
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      await historyService.saveDay(DayRecord(
        dateKey: key,
        glasses: i + 1,
        goalGlasses: 8,
        glassSizeMl: 250,
      ));
    }

    final recent = await historyService.getRecentDays(5);
    expect(recent.length, 5);
    expect(recent.first.glasses, 1);
  });

  test('calculateStreak counts consecutive goal-met days', () async {
    final now = DateTime.now();
    for (var i = 1; i <= 3; i++) {
      final d = now.subtract(Duration(days: i));
      final key =
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      await historyService.saveDay(DayRecord(
        dateKey: key,
        glasses: 8,
        goalGlasses: 8,
        glassSizeMl: 250,
      ));
    }

    final streak = await historyService.calculateStreak();
    expect(streak, 3);
  });

  test('averageMl computes correctly', () async {
    final now = DateTime.now();
    for (var i = 0; i < 3; i++) {
      final d = now.subtract(Duration(days: i));
      final key =
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      await historyService.saveDay(DayRecord(
        dateKey: key,
        glasses: 6,
        goalGlasses: 8,
        glassSizeMl: 250,
      ));
    }

    final avg = await historyService.averageMl(7);
    expect(avg, 1500.0); // 6 glasses * 250ml = 1500ml
  });

  test('prune removes old records', () async {
    final old = DateTime.now().subtract(const Duration(days: 100));
    final key =
        '${old.year.toString().padLeft(4, '0')}-${old.month.toString().padLeft(2, '0')}-${old.day.toString().padLeft(2, '0')}';
    await historyService.saveDay(DayRecord(
      dateKey: key,
      glasses: 5,
      goalGlasses: 8,
      glassSizeMl: 250,
    ));

    await historyService.prune(30);
    final record = await historyService.getDay(key);
    expect(record, isNull);
  });
}
