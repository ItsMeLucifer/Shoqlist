import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FriendsSearchDisplay extends ConsumerWidget {
  Widget build(BuildContext context, ScopedReader watch) {
    return Scaffold(body: Text('Search for friends'));
  }
}
