import 'package:hive/hive.dart';
part 'shopping_list_item.g.dart';

@HiveType(typeId: 1)
class ShoppingListItem extends HiveObject {
  @HiveField(0)
  String itemName;
  @HiveField(1)
  bool gotItem = false;
  @HiveField(2)
  bool isFavorite = false;

  ShoppingListItem(this.itemName, this.gotItem, this.isFavorite);

  void toggleIsFavorite() {
    isFavorite = !isFavorite;
  }

  void toggleGotItem() {
    gotItem = !gotItem;
  }
}
