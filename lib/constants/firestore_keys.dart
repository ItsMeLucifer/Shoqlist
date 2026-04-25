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
  static const String usersWithAccess = 'usersWithAccess';

  // v1 arrays (deprecated — only read for backwards-compat parsing of
  // unmigrated documents; new writes use the `items` map below).
  static const String listContent = 'listContent';
  static const String listState = 'listState';
  static const String listFavorite = 'listFavorite';

  // v2 schema (id-keyed items map + per-field timestamps).
  static const String schemaVersion = 'schemaVersion';
  static const int currentSchemaVersion = 2;
  static const String items = 'items';
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';
  static const String nameUpdatedAt = 'nameUpdatedAt';
  static const String importanceUpdatedAt = 'importanceUpdatedAt';
  static const String usersWithAccessUpdatedAt = 'usersWithAccessUpdatedAt';

  // Per-item fields (inside items.<itemId>).
  static const String itemState = 'state';
  static const String itemFavorite = 'favorite';
  static const String itemStateUpdatedAt = 'stateUpdatedAt';
  static const String itemFavoriteUpdatedAt = 'favoriteUpdatedAt';
  static const String deletedAt = 'deletedAt';

  // usersWithAccess map entries (when in v2 form).
  static const String grantedAt = 'grantedAt';
  static const String revokedAt = 'revokedAt';

  // Shared list reference
  static const String documentId = 'documentId';

  // Loyalty card document
  static const String barCode = 'barCode';
  static const String color = 'color';
  static const String isFavorite = 'isFavorite';
}
