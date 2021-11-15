import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shoqlist/models/shopping_list.dart';
import 'package:shoqlist/models/shopping_list_item.dart';
import 'package:shoqlist/viewmodels/loyalty_cards_view_model.dart';
import 'package:shoqlist/viewmodels/shopping_lists_view_model.dart';
import 'package:shoqlist/viewmodels/tools.dart';

enum Status { Authenticated, Unauthenticated, DuringAuthorization }

class FirebaseViewModel extends ChangeNotifier {
  ShoppingListsViewModel _shoppingListsVM;
  LoyaltyCardsViewModel _loyaltyCardsVM;
  Tools _toolsVM;
  FirebaseViewModel(this._shoppingListsVM, this._loyaltyCardsVM, this._toolsVM);

  //AUTHENTICATION
  FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseAuth get auth => _auth;
  UserCredential userCredential;
  Status _status = Status.Unauthenticated;
  Status get status => _status;
  set status(Status value) {
    _status = value;
    notifyListeners();
  }

  String _exceptionMessage = "";
  String get exceptionMessage => _exceptionMessage;
  void resetExceptionMessage() {
    _exceptionMessage = "";
    notifyListeners();
  }

  void addListenerToFirebaseAuth() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  //User _user;
  Future<void> signIn(String email, String password) async {
    status = Status.DuringAuthorization;
    try {
      userCredential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
    } on FirebaseAuthException catch (e) {
      status = Status.Unauthenticated;
      _exceptionMessage = "An undefined Error happened.";
      if (e.code == 'user-not-found') {
        _exceptionMessage = "No user found for that email.";
      } else if (e.code == 'wrong-password') {
        _exceptionMessage = "Wrong password provided for that user.";
      } else if (e.code == 'invalid-email') {
        _exceptionMessage = "Invalid email";
      } else if (e.code == 'user-disabled') {
        _exceptionMessage = "User disabled";
      }
    } catch (e) {
      print(e);
    }
    if (email == "" || password == "") {
      _exceptionMessage = "At least one of the fields is empty.";
    }
  }

  Future<void> _onAuthStateChanged(User firebaseUser) async {
    if (firebaseUser != null) status = Status.Authenticated;
  }

  Future<void> register(String email, String password) async {
    status = Status.DuringAuthorization;
    try {
      userCredential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
    } on FirebaseAuthException catch (e) {
      status = Status.Unauthenticated;
      _exceptionMessage = "An undefined Error happened.";
      if (e.code == 'weak-password') {
        _exceptionMessage = "The password provided is too weak.";
      } else if (e.code == 'email-already-in-use') {
        _exceptionMessage = "The account already exists for that email.";
      }
    } catch (e) {
      print(e);
    }
    if (email == "" || password == "") {
      _exceptionMessage = "At least one of the fields is empty.";
    }
    checkIfUserDocumentWasCreated();
  }

  Future<void> signInWithGoogle() async {
    status = Status.DuringAuthorization;
    final GoogleSignInAccount googleUser = await GoogleSignIn().signIn();
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);
    try {
      userCredential = await _auth.signInWithCredential(credential);
    } catch (e) {
      status = Status.Unauthenticated;
      _exceptionMessage = "Error with Google sign-in";
      print(e);
    }
    checkIfUserDocumentWasCreated();
  }

  Future<void> signInAnonymously() async {
    status = Status.DuringAuthorization;
    try {
      userCredential = await _auth.signInAnonymously();
    } catch (e) {
      status = Status.Unauthenticated;
      _exceptionMessage = "Error with anonymously sign-in";
      print(e);
    }
    checkIfUserDocumentWasCreated();
  }

  Future<void> checkIfUserDocumentWasCreated() async {
    CollectionReference users = FirebaseFirestore.instance.collection('users');
    if (_auth.currentUser == null) return;
    var doc = await users.doc(_auth.currentUser.uid).get();
    if (!doc.exists) {
      users.doc(_auth.currentUser.uid).set(
          {'email': auth.currentUser.email, 'userID': auth.currentUser.uid});
    }
  }

  Future<void> signOut() async {
    status = Status.Unauthenticated;
    _exceptionMessage = "";
    await _auth.signOut();
  }

  //SYNCHRONIZATION
  CollectionReference users = FirebaseFirestore.instance.collection('users');

  List<QueryDocumentSnapshot> _shoppingListsFromFetchedFirebase =
      List<QueryDocumentSnapshot>();
  void getShoppingListsFromFirebase() async {
    if (_auth.currentUser == null) return;
    await users
        .doc(_auth.currentUser.uid)
        .collection('lists')
        .get()
        .then((QuerySnapshot querySnapshot) => {
              if (querySnapshot.size > 0)
                {
                  querySnapshot.docs.forEach((doc) {
                    _shoppingListsFromFetchedFirebase.add(doc);
                  })
                }
            });
    print("Fetched shopping lists: " +
        _shoppingListsFromFetchedFirebase.length.toString());
    addFetchedDataToLocalList();
  }

  void addFetchedDataToLocalList() {
    List<ShoppingList> temp = [];
    for (int i = 0; i < _shoppingListsFromFetchedFirebase.length; i++) {
      List<ShoppingListItem> items = [];
      for (int j = 0;
          j < _shoppingListsFromFetchedFirebase[i].get('listContent').length;
          j++) {
        items.add(
          ShoppingListItem(
              _shoppingListsFromFetchedFirebase[i].get('listContent')[j],
              _shoppingListsFromFetchedFirebase[i].get('listState')[j],
              _toolsVM.getImportanceValueFromLabel(
                  _shoppingListsFromFetchedFirebase[i]
                      .get('listImportance')[j])),
        );
      }
      temp.add(ShoppingList(
          _shoppingListsFromFetchedFirebase[i].get('name'),
          items,
          _toolsVM.getImportanceValueFromLabel(
              _shoppingListsFromFetchedFirebase[i].get('importance'))));
    }
    _shoppingListsVM.addNewShoppingList(temp[0]);
  }

  void saveNewShoppingList(String name, Importance importance) async {
    if (_auth.currentUser == null) return;
    users.doc(_auth.currentUser.uid).collection('lists').add({
      'name': name,
      'importance': _toolsVM.getImportanceLabel(importance),
      'listContent': ['Pierwszy Item'],
      'listState': [false],
    });
  }
}
