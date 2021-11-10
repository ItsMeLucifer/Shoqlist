enum Importance { small, normal, important, urgent }

///An object that holds information about a single list.
class ShoppingList {
  final String name;
  final List<Item> list;
  final Importance importance;
  ShoppingList(this.name, this.list, this.importance);
}

class Item {
  String itemName;
  bool gotItem = false;
  Importance importance = Importance.normal;
  Item(this.itemName, this.gotItem, this.importance);
}
