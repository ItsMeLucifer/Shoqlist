import 'package:shoqlist/models/shopping_list_item.dart';
import 'package:hive_ce/hive.dart';
import 'package:shoqlist/models/user.dart';
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
  final String ownerName;
  @HiveField(7)
  List<User> usersWithAccess;
  // Per-field timestamps + schema marker. Null traktowany jak 0 przy merge.
  @HiveField(8)
  int? nameUpdatedAt;
  @HiveField(9)
  int? importanceUpdatedAt;
  @HiveField(10)
  int? usersWithAccessUpdatedAt;
  @HiveField(11)
  int? createdAt;
  @HiveField(12)
  int? updatedAt;
  @HiveField(13)
  int? schemaVersion;

  ShoppingList(
    this.name,
    this.list,
    this.importance,
    this.documentId,
    this.ownerId,
    this.ownerName, [
    List<User>? usersWithAccess,
    this.nameUpdatedAt,
    this.importanceUpdatedAt,
    this.usersWithAccessUpdatedAt,
    this.createdAt,
    this.updatedAt,
    this.schemaVersion,
  ]) : usersWithAccess = usersWithAccess ?? <User>[];

  void bumpUpdatedAt() {
    updatedAt = DateTime.now().millisecondsSinceEpoch;
  }
}
