import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoqlist/main.dart';
import 'package:shoqlist/pages/authentication.dart';
import 'package:shoqlist/pages/main_scaffold.dart';

class Wrapper extends ConsumerWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // FirebaseAuthViewModel is watched so the widget rebuilds on status
    // changes; its auth listener is wired once in the constructor.
    ref.watch(firebaseAuthProvider);
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (BuildContext context, snapshot) {
        if (snapshot.hasData) {
          return const MainScaffold();
        }
        return const Authentication();
      },
    );
  }
}
