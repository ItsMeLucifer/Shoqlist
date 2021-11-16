import 'package:shoqlist/models/shopping_list_item.dart';

enum Importance { low, normal, important, urgent }

///An object that holds information about a single list.
class ShoppingList {
  final String name;
  final List<ShoppingListItem> list;
  final Importance importance;
  final String documentId;
  ShoppingList(this.name, this.list, this.importance, this.documentId);
}
