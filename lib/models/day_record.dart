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

  @HiveField(4)
  final int? totalMlDirect; // ml efectivos totales del dia

  @HiveField(5)
  final int? goalMlDirect; // meta en ml

  DayRecord({
    required this.dateKey,
    required this.glasses,
    required this.goalGlasses,
    required this.glassSizeMl,
    this.totalMlDirect,
    this.goalMlDirect,
  });

  int get totalMl => totalMlDirect ?? (glasses * glassSizeMl);
  int get goalMl => goalMlDirect ?? (goalGlasses * glassSizeMl);
  double get progress => goalMl > 0 ? (totalMl / goalMl).clamp(0.0, 1.0) : 0.0;
  bool get goalMet => totalMl >= goalMl;
}
