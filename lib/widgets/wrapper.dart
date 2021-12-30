import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoqlist/main.dart';
import 'package:shoqlist/pages/authentication.dart';
import 'package:shoqlist/pages/home_screen.dart';
import 'package:shoqlist/viewmodels/firebase_auth_view_model.dart';

class Wrapper extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firebaseAuthVM = ref.watch(firebaseAuthProvider);
    firebaseAuthVM.addListenerToFirebaseAuth();
    switch (firebaseAuthVM.status) {
      case Status.Authenticated:
        return HomeScreen(ref);
        break;
      default:
        return Authentication();
        break;
    }
  }
}
