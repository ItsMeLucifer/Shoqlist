// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shopping_list_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ShoppingListItemAdapter extends TypeAdapter<ShoppingListItem> {
  @override
  final typeId = 1;

  @override
  ShoppingListItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ShoppingListItem(
      fields[0] as String,
      fields[1] as bool,
      fields[2] as bool,
      id: fields[3] as String?,
      createdAt: (fields[4] as num?)?.toInt(),
      nameUpdatedAt: (fields[5] as num?)?.toInt(),
      stateUpdatedAt: (fields[6] as num?)?.toInt(),
      favoriteUpdatedAt: (fields[7] as num?)?.toInt(),
      deletedAt: (fields[8] as num?)?.toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, ShoppingListItem obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.itemName)
      ..writeByte(1)
      ..write(obj.gotItem)
      ..writeByte(2)
      ..write(obj.isFavorite)
      ..writeByte(3)
      ..write(obj.id)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.nameUpdatedAt)
      ..writeByte(6)
      ..write(obj.stateUpdatedAt)
      ..writeByte(7)
      ..write(obj.favoriteUpdatedAt)
      ..writeByte(8)
      ..write(obj.deletedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShoppingListItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
