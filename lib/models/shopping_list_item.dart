class ShoppingListItem {
  String itemName;
  bool gotItem = false;
  bool isFavorite = false;
  ShoppingListItem(this.itemName, this.gotItem, this.isFavorite);
  void toggleIsFavorite() {
    isFavorite = !isFavorite;
  }

  void toggleGotItem() {
    gotItem = !gotItem;
  }
}
