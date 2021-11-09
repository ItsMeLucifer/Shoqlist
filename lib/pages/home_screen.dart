import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shoqlist/widgets/homeScreen/home_screen_main_view.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreen createState() => _HomeScreen();
}

class _HomeScreen extends State<HomeScreen> {
  @override
  initState() {
    super.initState();
  }

  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Colors.black, body: HomeScreenMainView());
  }
}
