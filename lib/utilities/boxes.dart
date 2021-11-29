import 'package:hive/hive.dart';
import 'package:shoqlist/models/shopping_list.dart';

class Boxes {
  static Box<ShoppingList> getShoppingLists() =>
      Hive.box<ShoppingList>('shopping_lists');
}
