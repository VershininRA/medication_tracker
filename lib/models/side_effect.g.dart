// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'side_effect.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SideEffectAdapter extends TypeAdapter<SideEffect> {
  @override
  final int typeId = 2;

  @override
  SideEffect read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SideEffect(
      id: fields[0] as String,
      medicineId: fields[1] as String?,
      description: fields[2] as String,
      severity: fields[3] as int,
      timestamp: fields[4] as DateTime,
      notes: fields[5] as String?,
      cycleDay: fields[6] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, SideEffect obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.medicineId)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.severity)
      ..writeByte(4)
      ..write(obj.timestamp)
      ..writeByte(5)
      ..write(obj.notes)
      ..writeByte(6)
      ..write(obj.cycleDay);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SideEffectAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
