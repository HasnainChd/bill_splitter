// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GroupAdapter extends TypeAdapter<Group> {
  @override
  final int typeId = 0;

  @override
  Group read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Group(
      groupId: fields[0] as String,
      name: fields[1] as String,
      members: (fields[2] as List).cast<String>(),
      currency: fields[3] as String,
      createdAt: fields[4] as DateTime,
      iconCodePoint: fields[5] as int?,
      iconFontFamily: fields[6] as String?,
      createdBy: fields[7] as String?,
      inviteCode: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Group obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.groupId)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.members)
      ..writeByte(3)
      ..write(obj.currency)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.iconCodePoint)
      ..writeByte(6)
      ..write(obj.iconFontFamily)
      ..writeByte(7)
      ..write(obj.createdBy)
      ..writeByte(8)
      ..write(obj.inviteCode);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
