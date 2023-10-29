import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive/hive.dart';
import 'package:shoqlist/models/shopping_list.dart';
import 'package:shoqlist/models/user.dart' as model;

enum Status { Authenticated, Unauthenticated, DuringAuthorization }

class FirebaseAuthViewModel extends ChangeNotifier {
  // FirebaseAuthViewModel.instance() : _auth = FirebaseAuth.instance {
  //   _auth.authStateChanges().listen(_onAuthStateChanged);
  // }
  FirebaseAuthViewModel() : _auth = FirebaseAuth.instance;
  //AUTHENTICATION
  final FirebaseAuth _auth;
  FirebaseAuth get auth => _auth;
  UserCredential? userCredential;
  Status _status = Status.Unauthenticated;
  Status get status => _status;
  set status(Status value) {
    _status = value;
    notifyListeners();
  }

  int _exceptionMessageIndex = 10;
  int get exceptionMessageIndex => _exceptionMessageIndex;
  void resetExceptionMessage() {
    _exceptionMessageIndex = 10;
    notifyListeners();
  }

  void addListenerToFirebaseAuth() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  model.User currentUser = model.User('Nickname', 'Email', 'UserId');
  void setCurrentUserCredentials() async {
    if (_auth.currentUser != null && status == Status.Authenticated) {
      DocumentSnapshot? document;
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(auth.currentUser!.uid)
            .get()
            .then((DocumentSnapshot doc) {
          if (doc.exists) {
            document = doc;
          }
        });
        if (document == null) return;
        currentUser = model.User(
          document?.get('nickname'),
          document?.get('email'),
          document?.get('userId'),
        );
        notifyListeners();
      } catch (err) {
        print('Couldn\'t fetch current user\'s credentials, error: $err');
      }
    }
  }

  void setExceptionMessagesTranslations(BuildContext context) {}

  Future<void> signIn(String email, String password) async {
    status = Status.DuringAuthorization;
    try {
      userCredential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
    } on FirebaseAuthException catch (e) {
      status = Status.Unauthenticated;
      _exceptionMessageIndex = 0;
      if (e.code == 'user-not-found') {
        _exceptionMessageIndex = 1;
      } else if (e.code == 'wrong-password') {
        _exceptionMessageIndex = 2;
      } else if (e.code == 'invalid-email') {
        _exceptionMessageIndex = 3;
      } else if (e.code == 'user-disabled') {
        _exceptionMessageIndex = 4;
      }
    } catch (e) {
      print(e);
    }
    if (email == "" || password == "") {
      _exceptionMessageIndex = 5;
    }
    checkIfUserDocumentWasCreated();
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) return;
    status = Status.Authenticated;
    setCurrentUserCredentials();
  }

  Future<void> register(String email, String password) async {
    status = Status.DuringAuthorization;
    try {
      userCredential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
    } on FirebaseAuthException catch (e) {
      status = Status.Unauthenticated;
      _exceptionMessageIndex = 0;
      if (e.code == 'weak-password') {
        _exceptionMessageIndex = 6;
      } else if (e.code == 'email-already-in-use') {
        _exceptionMessageIndex = 7;
      }
    } catch (e) {
      print(e);
    }
    if (email == "" || password == "") {
      _exceptionMessageIndex = 5;
    }
    checkIfUserDocumentWasCreated();
  }

  Future<void> signInWithGoogle() async {
    status = Status.DuringAuthorization;
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      status = Status.Unauthenticated;
      print('Google user is null');
      return;
    }
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    try {
      userCredential = await _auth.signInWithCredential(credential);
    } catch (e) {
      status = Status.Unauthenticated;
      _exceptionMessageIndex = 8;
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
      _exceptionMessageIndex = 9;
      print(e);
    }
    checkIfUserDocumentWasCreated();
  }

  Future<void> checkIfUserDocumentWasCreated() async {
    CollectionReference users = FirebaseFirestore.instance.collection('users');
    if (_auth.currentUser == null) return;
    var doc = await users.doc(_auth.currentUser!.uid).get();
    if (!doc.exists) {
      String nickname = auth.currentUser!.email!.split("@")[0];
      users.doc(_auth.currentUser!.uid).set({
        'email': !_auth.currentUser!.isAnonymous
            ? auth.currentUser!.email
            : 'anonymous',
        'userId': !_auth.currentUser!.isAnonymous
            ? auth.currentUser!.uid
            : 'anonymous',
        'nickname': nickname[0].toUpperCase() + nickname.substring(1),
        'timestamp': 0
      });
    }
    status = Status.Authenticated;
    setCurrentUserCredentials();
  }

  Future<void> signOut() async {
    _status = Status.Unauthenticated;
    _exceptionMessageIndex = 10;
    Hive.box<ShoppingList>('shopping_lists').clear();
    Hive.box<int>('data_variables').clear();
    notifyListeners();
    await _auth.signOut();
  }

  Future<void> deleteAccount() async {
    _status = Status.Unauthenticated;
    _exceptionMessageIndex = 10;
    notifyListeners();
    await _auth.currentUser!.delete();
  }

  void changeNickname(String newNickname) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(auth.currentUser!.uid)
        .update({'nickname': newNickname});
    currentUser =
        model.User(newNickname, currentUser.email, currentUser.userId);
    notifyListeners();
  }
}
