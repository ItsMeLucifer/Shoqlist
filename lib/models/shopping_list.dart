enum Importance { small, normal, important, urgent }

class ShoppingList {
  final String name;
  final List<String> list;
  final Importance importance;

  ShoppingList(this.name, this.list, this.importance);
}
