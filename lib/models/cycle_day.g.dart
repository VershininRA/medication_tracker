// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cycle_day.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CycleDayAdapter extends TypeAdapter<CycleDay> {
  @override
  final int typeId = 3;

  @override
  CycleDay read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CycleDay(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      cycleDayNumber: fields[2] as int,
      phase: fields[3] as String?,
      symptoms: (fields[4] as List).cast<String>(),
      notes: fields[5] as String?,
      createdAt: fields[6] as DateTime,
      moodScore: fields[7] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, CycleDay obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.cycleDayNumber)
      ..writeByte(3)
      ..write(obj.phase)
      ..writeByte(4)
      ..write(obj.symptoms)
      ..writeByte(5)
      ..write(obj.notes)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.moodScore);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CycleDayAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
