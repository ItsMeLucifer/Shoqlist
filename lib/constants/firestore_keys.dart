/// Firestore collection names.
class FirestoreCollections {
  FirestoreCollections._();

  static const String users = 'users';
  static const String lists = 'lists';
  static const String sharedLists = 'sharedLists';
  static const String loyaltyCards = 'loyaltyCards';
  static const String friends = 'friends';
  static const String friendRequests = 'friendRequests';
}

/// Firestore document field keys.
class FirestoreFields {
  FirestoreFields._();

  // User document
  static const String email = 'email';
  static const String userId = 'userId';
  static const String nickname = 'nickname';
  static const String timestamp = 'timestamp';

  // Shopping list document
  static const String name = 'name';
  static const String id = 'id';
  static const String ownerId = 'ownerId';
  static const String importance = 'importance';
  static const String listContent = 'listContent';
  static const String listState = 'listState';
  static const String listFavorite = 'listFavorite';
  static const String usersWithAccess = 'usersWithAccess';

  // Shared list reference
  static const String documentId = 'documentId';

  // Loyalty card document
  static const String barCode = 'barCode';
  static const String color = 'color';
  static const String isFavorite = 'isFavorite';
}
