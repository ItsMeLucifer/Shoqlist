import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseRepository {
  static final FirebaseRepository _singleton = FirebaseRepository._internal();

  factory FirebaseRepository() {
    return _singleton;
  }

  FirebaseRepository._internal();

  CollectionReference get users =>
      FirebaseFirestore.instance.collection("users");

  Future<DocumentSnapshot> getUserData({
    required String userId,
  }) async {
    return await users.doc(userId).get();
  }

  Future<QuerySnapshot> getCollectionDocuments({
    required String userId,
    required String collectionId,
  }) async {
    return await users.doc(userId).collection(collectionId).get();
  }

  Future<DocumentSnapshot> getCollectionDocument({
    required String userId,
    required String collectionId,
    required String documentId,
  }) async {
    return await users
        .doc(userId)
        .collection(collectionId)
        .doc(documentId)
        .get();
  }
}
