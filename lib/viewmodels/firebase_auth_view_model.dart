import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_sign_in/google_sign_in.dart';

enum Status { Authenticated, Unauthenticated, DuringAuthorization }

class FirebaseAuthViewModel extends ChangeNotifier {
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
    print('SIGN OUT');
    await _auth.signOut();
  }
}
