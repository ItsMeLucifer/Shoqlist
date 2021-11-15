import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoqlist/main.dart';
import 'package:shoqlist/pages/authentication.dart';
import 'package:shoqlist/pages/home_screen.dart';
import 'package:shoqlist/viewmodels/firebase_view_model.dart';

class Wrapper extends ConsumerWidget {
  @override
  Widget build(BuildContext context, ScopedReader watch) {
    final firebaseVM = watch(firebaseProvider);
    firebaseVM.addListenerToFirebaseAuth();
    switch (firebaseVM.status) {
      case Status.Authenticated:
        return HomeScreen();
        break;
      case Status.Unauthenticated:
        return Authentication();
        break;
      default:
        return Authentication();
    }
  }
}
