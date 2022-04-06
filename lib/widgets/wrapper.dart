import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoqlist/main.dart';
import 'package:shoqlist/pages/authentication.dart';
import 'package:shoqlist/pages/home_screen.dart';

class Wrapper extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firebaseAuthVM = ref.watch(firebaseAuthProvider);
    final _auth = FirebaseAuth.instance;
    firebaseAuthVM.addListenerToFirebaseAuth();
    return StreamBuilder<User>(
      stream: _auth.authStateChanges(),
      builder: (BuildContext context, snapshot) {
        if (snapshot.hasData && (!snapshot.data.isAnonymous)) {
          return HomeScreen(ref);
        }
        return Authentication();
      },
    );
  }
}
