// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shopping_list.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ImportanceAdapter extends TypeAdapter<Importance> {
  @override
  final int typeId = 2;

  @override
  Importance read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return Importance.low;
      case 1:
        return Importance.normal;
      case 2:
        return Importance.important;
      case 3:
        return Importance.urgent;
      default:
        return null;
    }
  }

  @override
  void write(BinaryWriter writer, Importance obj) {
    switch (obj) {
      case Importance.low:
        writer.writeByte(0);
        break;
      case Importance.normal:
        writer.writeByte(1);
        break;
      case Importance.important:
        writer.writeByte(2);
        break;
      case Importance.urgent:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImportanceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ShoppingListAdapter extends TypeAdapter<ShoppingList> {
  @override
  final int typeId = 0;

  @override
  ShoppingList read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ShoppingList(
      fields[0] as String,
      (fields[1] as List)?.cast<ShoppingListItem>(),
      fields[2] as Importance,
      fields[3] as String,
      fields[5] as String,
      fields[6] as String,
      (fields[7] as List)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, ShoppingList obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.list)
      ..writeByte(2)
      ..write(obj.importance)
      ..writeByte(3)
      ..write(obj.documentId)
      ..writeByte(5)
      ..write(obj.ownerId)
      ..writeByte(6)
      ..write(obj.ownerName)
      ..writeByte(7)
      ..write(obj.usersWithAccess);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShoppingListAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
