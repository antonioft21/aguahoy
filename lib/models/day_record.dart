import 'package:hive_ce/hive.dart';

part 'day_record.g.dart';

@HiveType(typeId: 0)
class DayRecord extends HiveObject {
  @HiveField(0)
  final String dateKey; // yyyy-MM-dd

  @HiveField(1)
  final int glasses;

  @HiveField(2)
  final int goalGlasses;

  @HiveField(3)
  final int glassSizeMl;

  DayRecord({
    required this.dateKey,
    required this.glasses,
    required this.goalGlasses,
    required this.glassSizeMl,
  });

  int get totalMl => glasses * glassSizeMl;
  int get goalMl => goalGlasses * glassSizeMl;
  double get progress => goalGlasses > 0 ? (glasses / goalGlasses).clamp(0.0, 1.0) : 0.0;
  bool get goalMet => glasses >= goalGlasses;
}
