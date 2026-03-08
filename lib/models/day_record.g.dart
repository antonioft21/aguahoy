// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'day_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DayRecordAdapter extends TypeAdapter<DayRecord> {
  @override
  final typeId = 0;

  @override
  DayRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DayRecord(
      dateKey: fields[0] as String,
      glasses: (fields[1] as num).toInt(),
      goalGlasses: (fields[2] as num).toInt(),
      glassSizeMl: (fields[3] as num).toInt(),
      totalMlDirect: fields[4] == null ? null : (fields[4] as num).toInt(),
      goalMlDirect: fields[5] == null ? null : (fields[5] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, DayRecord obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.dateKey)
      ..writeByte(1)
      ..write(obj.glasses)
      ..writeByte(2)
      ..write(obj.goalGlasses)
      ..writeByte(3)
      ..write(obj.glassSizeMl)
      ..writeByte(4)
      ..write(obj.totalMlDirect)
      ..writeByte(5)
      ..write(obj.goalMlDirect);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DayRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
