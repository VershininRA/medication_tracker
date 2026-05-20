// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cycle_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CycleSettingsAdapter extends TypeAdapter<CycleSettings> {
  @override
  final int typeId = 4;

  @override
  CycleSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CycleSettings(
      lastPeriodStart: fields[0] as DateTime,
      cycleLength: fields[1] as int,
      periodLength: fields[2] as int,
    );
  }

  @override
  void write(BinaryWriter writer, CycleSettings obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.lastPeriodStart)
      ..writeByte(1)
      ..write(obj.cycleLength)
      ..writeByte(2)
      ..write(obj.periodLength);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CycleSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
