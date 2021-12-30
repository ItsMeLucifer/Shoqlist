import 'package:shoqlist/models/shopping_list_item.dart';
import 'package:hive/hive.dart';
part 'shopping_list.g.dart';

@HiveType(typeId: 2)
enum Importance {
  @HiveField(0)
  low,
  @HiveField(1)
  normal,
  @HiveField(2)
  important,
  @HiveField(3)
  urgent
}

///An object that holds information about a single list.

@HiveType(typeId: 0)
class ShoppingList extends HiveObject {
  @HiveField(0)
  String name;
  @HiveField(1)
  final List<ShoppingListItem> list;
  @HiveField(2)
  Importance importance;
  @HiveField(3)
  final String documentId;
  @HiveField(5)
  final String ownerId;
  @HiveField(6)
  List<String> usersWithAccess = [];

  ShoppingList(
      this.name, this.list, this.importance, this.documentId, this.ownerId,
      [this.usersWithAccess]);
}
