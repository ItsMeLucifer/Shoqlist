import 'package:shoqlist/models/shopping_list.dart';

class ShoppingListItem {
  String itemName;
  bool gotItem = false;
  Importance importance = Importance.normal;
  ShoppingListItem(this.itemName, this.gotItem, this.importance);
}
