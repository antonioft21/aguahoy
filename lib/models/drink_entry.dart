class DrinkEntry {
  final String id; // timestamp microseconds
  final String beverageId; // 'water', 'coffee', etc.
  final int volumeMl; // ml reales consumidos
  final int effectiveMl; // volumeMl * hydrationRatio (snapshot al crear)
  final DateTime timestamp;

  const DrinkEntry({
    required this.id,
    required this.beverageId,
    required this.volumeMl,
    required this.effectiveMl,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'beverageId': beverageId,
        'volumeMl': volumeMl,
        'effectiveMl': effectiveMl,
        'timestamp': timestamp.toIso8601String(),
      };

  factory DrinkEntry.fromJson(Map<String, dynamic> json) => DrinkEntry(
        id: json['id'] as String,
        beverageId: json['beverageId'] as String,
        volumeMl: (json['volumeMl'] as num).toInt(),
        effectiveMl: (json['effectiveMl'] as num).toInt(),
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}
