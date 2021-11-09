import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoqlist/pages/home_screen.dart';

class Wrapper extends ConsumerWidget {
  @override
  Widget build(BuildContext context, ScopedReader watch) {
    //switch
    return HomeScreen();
  }
}
