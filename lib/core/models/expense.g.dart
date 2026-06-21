// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExpenseAdapter extends TypeAdapter<Expense> {
  @override
  final int typeId = 1;

  @override
  Expense read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Expense(
      expenseId: fields[0] as String,
      title: fields[1] as String,
      amount: fields[2] as double,
      currency: fields[3] as String,
      paidBy: fields[4] as String,
      splitAmong: (fields[5] as Map).cast<String, double>(),
      date: fields[6] as DateTime,
      notes: fields[7] as String?,
      groupId: fields[8] as String,
      categoryIconCodePoint: fields[9] as int,
      splitType: fields[10] as String? ?? 'Equal',
      receiptUrl: fields[11] as String?,
      createdAt: fields[12] as DateTime?,
      updatedAt: fields[13] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Expense obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.expenseId)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.currency)
      ..writeByte(4)
      ..write(obj.paidBy)
      ..writeByte(5)
      ..write(obj.splitAmong)
      ..writeByte(6)
      ..write(obj.date)
      ..writeByte(7)
      ..write(obj.notes)
      ..writeByte(8)
      ..write(obj.groupId)
      ..writeByte(9)
      ..write(obj.categoryIconCodePoint)
      ..writeByte(10)
      ..write(obj.splitType)
      ..writeByte(11)
      ..write(obj.receiptUrl)
      ..writeByte(12)
      ..write(obj.createdAt)
      ..writeByte(13)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
