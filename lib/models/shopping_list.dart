enum Importance { small, normal, important, urgent }

///An object that holds information about a single list.
class ShoppingList {
  final String name;
  final List<Item> list;
  final Importance importance;
  ShoppingList(this.name, this.list, this.importance);
}

class Item {
  final String itemName;
  final bool gotItem;

  Item(this.itemName, this.gotItem);
}
