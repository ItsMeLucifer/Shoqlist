import 'package:shoqlist/models/shopping_list_item.dart';
import 'package:hive/hive.dart';
part 'shopping_list.g.dart';

enum Importance { low, normal, important, urgent }

///An object that holds information about a single list.

@HiveType(typeId: 0)
class ShoppingList extends HiveObject {
  @HiveField(0)
  final String name;
  @HiveField(1)
  final List<ShoppingListItem> list;
  @HiveField(2)
  final Importance importance;
  @HiveField(3)
  final String documentId;

  ShoppingList(this.name, this.list, this.importance, this.documentId);
}
