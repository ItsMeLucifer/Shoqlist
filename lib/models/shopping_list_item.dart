import 'package:hive_ce/hive.dart';
import 'package:nanoid/nanoid.dart';
part 'shopping_list_item.g.dart';

@HiveType(typeId: 1)
class ShoppingListItem extends HiveObject {
  @HiveField(0)
  String itemName;
  @HiveField(1)
  bool gotItem;
  @HiveField(2)
  bool isFavorite;
  @HiveField(3)
  String? id;
  @HiveField(4)
  int? createdAt;
  // Per-field timestamps używane przy merge konfliktów między lokalnym stanem
  // a snapshotem z serwera. Null traktowany jak 0 (remote zawsze wygra przy
  // pierwszym snapshocie po migracji starych Hive cachów).
  @HiveField(5)
  int? nameUpdatedAt;
  @HiveField(6)
  int? stateUpdatedAt;
  @HiveField(7)
  int? favoriteUpdatedAt;
  @HiveField(8)
  int? deletedAt;

  ShoppingListItem(
    this.itemName,
    this.gotItem,
    this.isFavorite, {
    String? id,
    int? createdAt,
    int? nameUpdatedAt,
    int? stateUpdatedAt,
    int? favoriteUpdatedAt,
    this.deletedAt,
  })  : id = id ?? nanoid(),
        createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch,
        nameUpdatedAt = nameUpdatedAt ??
            createdAt ??
            DateTime.now().millisecondsSinceEpoch,
        stateUpdatedAt = stateUpdatedAt ??
            createdAt ??
            DateTime.now().millisecondsSinceEpoch,
        favoriteUpdatedAt = favoriteUpdatedAt ??
            createdAt ??
            DateTime.now().millisecondsSinceEpoch;

  void toggleIsFavorite() {
    isFavorite = !isFavorite;
    favoriteUpdatedAt = DateTime.now().millisecondsSinceEpoch;
  }

  void toggleGotItem() {
    gotItem = !gotItem;
    stateUpdatedAt = DateTime.now().millisecondsSinceEpoch;
  }

  void setName(String newName) {
    itemName = newName;
    nameUpdatedAt = DateTime.now().millisecondsSinceEpoch;
  }

  void markDeleted() {
    deletedAt = DateTime.now().millisecondsSinceEpoch;
  }
}
