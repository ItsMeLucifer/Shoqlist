import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_ce/hive.dart';
import 'package:shoqlist/models/shopping_list.dart';
import 'package:shoqlist/models/user.dart' as model;

enum Status { authenticated, unauthenticated, duringAuthorization }

class FirebaseAuthViewModel extends ChangeNotifier {
  FirebaseAuthViewModel() : _auth = FirebaseAuth.instance {
    _authSubscription = _auth.authStateChanges().listen(_onAuthStateChanged);
  }
  //AUTHENTICATION
  final FirebaseAuth _auth;
  late final StreamSubscription<User?> _authSubscription;
  FirebaseAuth get auth => _auth;
  UserCredential? userCredential;
  Status _status = Status.unauthenticated;
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

  model.User currentUser = model.User('Nickname', 'Email', 'UserId');
  void setCurrentUserCredentials() async {
    if (_auth.currentUser != null && status == Status.authenticated) {
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
        debugPrint('Couldn\'t fetch current user\'s credentials, error: $err');
      }
    }
  }

  Future<void> signIn(String email, String password) async {
    status = Status.duringAuthorization;
    try {
      userCredential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      debugPrint('SIGNED IN');
    } on FirebaseAuthException catch (e) {
      status = Status.unauthenticated;
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
      debugPrint(e.toString());
    }
    if (email == "" || password == "") {
      _exceptionMessageIndex = 5;
    }
    checkIfUserDocumentWasCreated();
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) return;
    status = Status.authenticated;
    setCurrentUserCredentials();
  }

  Future<void> register(String email, String password) async {
    status = Status.duringAuthorization;
    try {
      userCredential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
    } on FirebaseAuthException catch (e) {
      status = Status.unauthenticated;
      _exceptionMessageIndex = 0;
      if (e.code == 'weak-password') {
        _exceptionMessageIndex = 6;
      } else if (e.code == 'email-already-in-use') {
        _exceptionMessageIndex = 7;
      }
    } catch (e) {
      debugPrint(e.toString());
    }
    if (email == "" || password == "") {
      _exceptionMessageIndex = 5;
    }
    checkIfUserDocumentWasCreated();
  }

  Future<void> signInWithGoogle() async {
    status = Status.duringAuthorization;
    final googleSignIn = GoogleSignIn.instance;
    await googleSignIn.initialize();
    
    final GoogleSignInAccount? googleUser;
    if (googleSignIn.supportsAuthenticate()) {
      googleUser = await googleSignIn.authenticate();
    } else {
      throw UnsupportedError('Platform not supported for authentication');
    }
    
    final GoogleSignInAuthentication googleAuth =
        googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );
    try {
      userCredential = await _auth.signInWithCredential(credential);
    } catch (e) {
      status = Status.unauthenticated;
      _exceptionMessageIndex = 8;
      debugPrint(e.toString());
    }
    checkIfUserDocumentWasCreated();
  }

  Future<void> signInAnonymously() async {
    status = Status.duringAuthorization;
    try {
      userCredential = await _auth.signInAnonymously();
    } catch (e) {
      status = Status.unauthenticated;
      _exceptionMessageIndex = 9;
      debugPrint(e.toString());
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
    status = Status.authenticated;
    setCurrentUserCredentials();
  }

  Future<void> signOut() async {
    _status = Status.unauthenticated;
    _exceptionMessageIndex = 10;
    Hive.box<ShoppingList>('shopping_lists').clear();
    Hive.box<int>('data_variables').clear();
    notifyListeners();
    await _auth.signOut();
  }

  Future<void> deleteAccount() async {
    _status = Status.unauthenticated;
    _exceptionMessageIndex = 10;
    notifyListeners();
    await _auth.currentUser!.delete();
  }

  Future<void> changeNickname(String newNickname) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({'nickname': newNickname});
    currentUser =
        model.User(newNickname, currentUser.email, currentUser.userId);
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }
}
