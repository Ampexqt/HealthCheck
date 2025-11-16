// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HealthEntryAdapter extends TypeAdapter<HealthEntry> {
  @override
  final int typeId = 0;

  @override
  HealthEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HealthEntry(
      id: fields[0] as String,
      heartRate: fields[1] as int?,
      systolicBP: fields[2] as int?,
      diastolicBP: fields[3] as int?,
      symptoms: fields[4] as String?,
      timestamp: fields[5] as DateTime,
      isSynced: fields[6] as bool,
      lastSyncedAt: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, HealthEntry obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.heartRate)
      ..writeByte(2)
      ..write(obj.systolicBP)
      ..writeByte(3)
      ..write(obj.diastolicBP)
      ..writeByte(4)
      ..write(obj.symptoms)
      ..writeByte(5)
      ..write(obj.timestamp)
      ..writeByte(6)
      ..write(obj.isSynced)
      ..writeByte(7)
      ..write(obj.lastSyncedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HealthEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
